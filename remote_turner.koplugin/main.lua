local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local C_ = _.pgettext
local T = require("ffi/util").template
local ws = require("websocket")

local RemoteTurner = WidgetContainer:extend {
    name = "remote_turner",
    is_doc_only = false,
    ws_client = nil,
}

local function create_ws_client()
    local json = require("json")
    local sha = require("ffi/sha2")

    return {
        socket = nil,
        host = nil,
        port = nil,
        password = nil,
        connected = false,

        connect = function(self, host, port, password)
            local url = string.format("ws://%s:%d", host, port)
            local ok, client = pcall(ws.client.connect, url)
            if not ok or not client then
                return false, "connection failed"
            end
            self.socket = client
            self.host = host
            self.port = port
            self.password = password
            self.connected = true

            if password and password ~= "" then
                client:send(json.encode({ type = "auth" }))
                local _, msg = client:recv()
                if not msg then
                    client:close()
                    self.connected = false
                    return false, "no response from server"
                end
                local ok2, data = pcall(json.decode, msg.data)
                if not ok2 or data.type ~= "auth_challenge" then
                    client:close()
                    self.connected = false
                    return false, "unexpected response"
                end
                local hash = sha.sha256(password .. data.challenge)
                client:send(json.encode({
                    type = "auth_response",
                    hash = hash,
                    device_name = "KOReader",
                }))
                local _, msg2 = client:recv()
                if msg2 then
                    local ok3, result = pcall(json.decode, msg2.data)
                    if ok3 and result.success then
                        return true
                    elseif ok3 and not result.success then
                        client:close()
                        self.connected = false
                        return false, "invalid password"
                    end
                end
                client:close()
                self.connected = false
                return false, "auth failed"
            else
                client:send(json.encode({
                    type = "hello",
                    device_name = "KOReader",
                }))
            end
            return true
        end,

        disconnect = function(self)
            if self.socket then
                self.socket:close()
                self.socket = nil
            end
            self.connected = false
        end,

        is_connected = function(self)
            return self.connected
        end,
    }
end

function RemoteTurner.onDispatcherRegisterActions()
    Dispatcher:registerAction("remote_turner_next_page", {
        category = "none",
        event = "RemoteTurnerNextPage",
        title = _("Remote: next page"),
        general = true,
    })
    Dispatcher:registerAction("remote_turner_prev_page", {
        category = "none",
        event = "RemoteTurnerPrevPage",
        title = _("Remote: previous page"),
        general = true,
    })
    Dispatcher:registerAction("remote_turner_sleep", {
        category = "none",
        event = "RemoteTurnerSleep",
        title = _("Remote: sleep"),
        general = true,
    })
end

function RemoteTurner:init()
    self.ws_client = create_ws_client()
    self.onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function RemoteTurner:addToMainMenu(menu_items)
    menu_items.remote_turner = {
        text = _("Remote Turner"),
        sub_item_table = {
            {
                text_func = function()
                    if self.ws_client and self.ws_client:is_connected() then
                        return _("Disconnect")
                    else
                        return _("Connect")
                    end
                end,
                callback = function()
                    if self.ws_client and self.ws_client:is_connected() then
                        self:disconnect()
                    else
                        self:connect()
                    end
                end,
            },
            {
                text = _("Wireless settings"),
                keep_menu_open = true,
                sub_item_table = self:getWirelessMenuTable(),
            },
        }
    }
end

function RemoteTurner:connect()
    if not self.ws_client then
        self.ws_client = create_ws_client()
    end

    local calibre_url = G_reader_settings:readSetting("remote_turner_url")
    local host, port
    if calibre_url then
        host = calibre_url["address"]
        port = calibre_url["port"]
    else
        -- try to discover the server via broadcast
        local ok, discovered_host, discovered_port = self.discoverServer()
        if not ok then
            UIManager:show(InfoMessage:new {
                text = _("Could not find Remote Turner server. Please configure the address manually."),
            })
            return
        end
        host = discovered_host
        port = discovered_port
    end

    local password = G_reader_settings:readSetting("remote_turner_password")

    local ok, err = self.ws_client:connect(host, port, password)
    if ok then
        self:startMessageLoop()
        UIManager:show(InfoMessage:new {
            text = T(_("Connected to Remote Turner at %1:%2"), host, port),
            timeout = 2,
        })
    else
        UIManager:show(InfoMessage:new {
            text = T(_("Cannot connect to Remote Turner at %1:%2 (%3)"), host, port, err or "unknown error"),
            timeout = 3,
        })
    end
end

function RemoteTurner:disconnect()
    if self._check_cb then
        UIManager:unregisterCheckCallback(self._check_cb)
        self._check_cb = nil
    end
    self._poll_cb = nil
    if self.ws_client then
        self.ws_client:disconnect()
    end
end

function RemoteTurner.discoverServer()
    local socket = require("socket")
    local udp = socket.udp4()
    udp:setoption("broadcast", true)
    udp:setsockname("*", 0)
    udp:settimeout(2)

    local ok, _ = udp:sendto("remote_turner_discover", "255.255.255.255", 9090)
    if not ok then
        udp:close()
        return false
    end

    local dgram, host = udp:receivefrom()
    udp:close()

    if dgram and host then
        local _, _, port_str = dgram:match("remote_turner:(.-):(.-)$")
        local port = port_str and tonumber(port_str) or 9090
        return true, host, port
    end
    return false
end

function RemoteTurner:getWirelessMenuTable()
    local function isEnabled()
        return not (self.ws_client and self.ws_client:is_connected())
    end

    return {
        {
            text = _("Server address"),
            enabled_func = isEnabled,
            sub_item_table = {
                {
                    text = C_("Configuration type", "Automatic"),
                    checked_func = function()
                        return G_reader_settings:hasNot("remote_turner_url")
                    end,
                    radio = true,
                    callback = function()
                        G_reader_settings:delSetting("remote_turner_url")
                    end,
                },
                {
                    text = C_("Configuration type", "Manual"),
                    checked_func = function()
                        return G_reader_settings:has("remote_turner_url")
                    end,
                    radio = true,
                    callback = function(touchmenu_instance)
                        local MultiInputDialog = require("ui/widget/multiinputdialog")
                        local url_dialog
                        local url = G_reader_settings:readSetting("remote_turner_url")
                        local address, port
                        if url then
                            address = url["address"]
                            port = url["port"]
                        end
                        url_dialog = MultiInputDialog:new {
                            title = _("Set Remote Turner server address"),
                            fields = {
                                {
                                    text = address,
                                    input_type = "string",
                                    hint = _("IP Address"),
                                },
                                {
                                    text = port and tostring(port),
                                    input_type = "number",
                                    hint = _("Port"),
                                },
                            },
                            buttons = {
                                {
                                    {
                                        text = _("Cancel"),
                                        id = "close",
                                        callback = function()
                                            UIManager:close(url_dialog)
                                        end,
                                    },
                                    {
                                        text = _("OK"),
                                        callback = function()
                                            local fields = url_dialog:getFields()
                                            if fields[1] ~= "" then
                                                local p = tonumber(fields[2])
                                                if not p or p < 1 or p > 65535 then
                                                    p = 9090
                                                end
                                                G_reader_settings:saveSetting("remote_turner_url",
                                                    { address = fields[1], port = p })
                                            end
                                            UIManager:close(url_dialog)
                                            if touchmenu_instance then
                                                touchmenu_instance:updateItems()
                                            end
                                        end,
                                    },
                                },
                            },
                        }
                        UIManager:show(url_dialog)
                        url_dialog:onShowKeyboard()
                    end,
                },
            },
        },
        {
            text = _("Set password"),
            enabled_func = isEnabled,
            callback = function()
                local InputDialog = require("ui/widget/inputdialog")
                local password_dialog
                password_dialog = InputDialog:new {
                    title = _("Set connection password"),
                    input = G_reader_settings:readSetting("remote_turner_password") or "",
                    buttons = { {
                        {
                            text = _("Cancel"),
                            id = "close",
                            callback = function()
                                UIManager:close(password_dialog)
                            end,
                        },
                        {
                            text = _("Set password"),
                            callback = function()
                                local pass = password_dialog:getInputText()
                                if pass and pass ~= "" then
                                    G_reader_settings:saveSetting("remote_turner_password", pass)
                                else
                                    G_reader_settings:delSetting("remote_turner_password")
                                end
                                UIManager:close(password_dialog)
                            end,
                        },
                    } },
                }
                UIManager:show(password_dialog)
                password_dialog:onShowKeyboard()
            end,
        },
    }
end

function RemoteTurner:_handleMessage(msg)
    if not msg or not msg.data or msg.data == "" then return end
    local ok, data = pcall(require("json").decode, msg.data)
    if not ok or not data.action then return end
    if data.action == "next_page" then
        self.onRemoteTurnerNextPage()
    elseif data.action == "prev_page" then
        self.onRemoteTurnerPrevPage()
    elseif data.action == "sleep" then
        self.onRemoteTurnerSleep()
    end
end

function RemoteTurner:startMessageLoop()
    if self._poll_cb then return end
    local sock = self.ws_client and self.ws_client.socket
    if not sock then return end
    sock:settimeout(0)

    local raw_sock = sock._sock
    local socket = require("socket")
    local function poll()
        if not self.ws_client or not self.ws_client.connected or not self.ws_client.socket then
            self._poll_cb = nil
            self.ws_client = nil
            return
        end
        local can_read = socket.select({ raw_sock }, nil, 0)
        if can_read and #can_read > 0 then
            local _, msg = self.ws_client.socket:recv()
            self:_handleMessage(msg)
        end
        self._poll_cb = UIManager:scheduleIn(0.1, poll)
    end
    if UIManager.registerCheckCallback then
        self._check_cb = function()
            if not self.ws_client or not self.ws_client.connected or not self.ws_client.socket then
                UIManager:unregisterCheckCallback(self._check_cb)
                self._check_cb = nil
                self.ws_client = nil
                return
            end
            local can_read = socket.select({ raw_sock }, nil, 0)
            if can_read and #can_read > 0 then
                local _, msg = self.ws_client.socket:recv()
                self:_handleMessage(msg)
            end
        end
        UIManager:registerCheckCallback(self._check_cb)
    else
        UIManager:scheduleIn(0, poll)
    end
end

function RemoteTurner.onRemoteTurnerNextPage()
    UIManager:broadcastEvent(Event:new("GotoViewRel", 1))
end

function RemoteTurner.onRemoteTurnerPrevPage()
    UIManager:broadcastEvent(Event:new("GotoViewRel", -1))
end

function RemoteTurner.onRemoteTurnerSleep()
    UIManager:broadcastEvent(Event:new("RequestSuspend"))
end

return RemoteTurner
