local socket = require("socket")
local mime = require("mime")
local bor, band, bxor, rshift = bit.bor, bit.band, bit.bxor, bit.rshift

math.randomseed(socket.gettime() * 10000)

local function parse_url(url)
  local _, _, host, port, path =
    url:find("^ws://([^:/]+):?(%d*)(.*)")
  if not host then
    return nil, "invalid URL: " .. tostring(url)
  end
  if port == "" then port = "80" end
  if path == "" then path = "/" end
  return host, tonumber(port), path
end

local function generate_key()
  local t = {}
  for i = 1, 16 do
    t[i] = string.char(math.random(0, 255))
  end
  return mime.b64(table.concat(t))
end

local function encode_frame(data)
  local payload = tostring(data)
  local len = #payload
  local opcode = 0x81

  local header
  if len < 126 then
    header = string.char(opcode, bor(0x80, len))
  elseif len < 65536 then
    header = string.char(
      opcode, bor(0x80, 126),
      band(rshift(len, 8), 0xFF),
      band(len, 0xFF)
    )
  else
    header = string.char(opcode, bor(0x80, 127))
    for i = 7, 0, -1 do
      header = header .. string.char(band(rshift(len, i * 8), 0xFF))
    end
  end

  local mk = string.char(
    math.random(0, 255), math.random(0, 255),
    math.random(0, 255), math.random(0, 255)
  )
  header = header .. mk

  local masked = {}
  for i = 1, len do
    local ki = ((i - 1) % 4) + 1
    masked[i] = string.char(
      bxor(string.byte(payload, i), string.byte(mk, ki))
    )
  end
  return header .. table.concat(masked)
end

local client = {}
client.__index = client

function client:send(data)
  local frame = encode_frame(data)
  local ok, err = self._sock:send(frame)
  if ok then return true end
  return nil, err
end

function client:recv()
  local readable = socket.select({self._sock}, nil, 0)
  if #readable == 0 then return end

  local data

  data = self._sock:receive(2)
  if not data then return end

  local hdr = data
  local b2 = string.byte(hdr, 2)
  local len = band(b2, 0x7F)
  local masked = band(b2, 0x80) ~= 0

  if len == 126 then
    data = self._sock:receive(2)
    if not data then return end
    hdr = hdr .. data
    len = string.byte(data, 1) * 256 + string.byte(data, 2)
  elseif len == 127 then
    data = self._sock:receive(8)
    if not data then return end
    hdr = hdr .. data
    len = 0
    for i = 0, 7 do
      len = len * 256 + string.byte(data, i + 1)
    end
  end

  local mask_key
  if masked then
    data = self._sock:receive(4)
    if not data then return end
    mask_key = data
    hdr = hdr .. mask_key
  end

  local payload = ""
  if len > 0 then
    data = self._sock:receive(len)
    if not data then return end
    payload = data
  end

  if masked and mask_key then
    local unmasked = {}
    for i = 1, len do
      local ki = ((i - 1) % 4) + 1
      unmasked[i] = string.char(
        bxor(string.byte(payload, i), string.byte(mask_key, ki))
      )
    end
    payload = table.concat(unmasked)
  end

  local opcode = band(string.byte(hdr, 1), 0x0F)

  if opcode == 0x08 then
    self:close()
    return
  end

  if opcode == 0x09 then
    self._sock:send(string.char(0x8A, 0x00))
    return self:recv()
  end

  return nil, { data = payload }
end

function client:settimeout(seconds)
  if self._sock then
    self._sock:settimeout(seconds)
  end
end

function client:close()
  if self._sock then
    pcall(self._sock.send, self._sock, string.char(0x88, 0x00))
    self._sock:close()
    self._sock = nil
  end
end

local function connect(url)
  local host, port, path = parse_url(url)
  if not host then return nil, url end

  local tcp = socket.tcp()
  tcp:settimeout(10)

  local ok, err = tcp:connect(host, port)
  if not ok then
    tcp:close()
    return nil, err
  end

  local key = generate_key()
  local req = string.format(
    "GET %s HTTP/1.1\r\nHost: %s:%d\r\nUpgrade: websocket\r\n" ..
      "Connection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n",
    path, host, port, key
  )

  ok, err = tcp:send(req)
  if not ok then tcp:close() return nil, err end

  local resp
  resp = tcp:receive("*l")
  if not resp then tcp:close() return nil, "no response" end
  if not resp:find("101") then
    tcp:close()
    return nil, "handshake failed: " .. (resp or "unknown")
  end

  while true do
    resp = tcp:receive("*l")
    if not resp then tcp:close() return nil, "incomplete headers" end
    if resp == "" then break end
  end
  return setmetatable({ _sock = tcp }, client)
end

return {
  client = {
    connect = connect,
  },
}
