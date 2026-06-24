# Remote Turner — Connection Architecture

## Overview

```
┌─────────────────────────┐         WebSocket          ┌─────────────────────┐
│   Flutter App (Phone)   │ ◄─────────────────────────► │ KOReader (E-reader) │
│                         │    ws://<ip>:9090           │                     │
│  ┌───────────────────┐  │                             │  ┌─────────────────┐│
│  │ WebSocketServer   │──┤                             ├──│ websocket.lua   ││
│  │ (HTTP → WS        │  │                             │  │ (pure Lua       ││
│  │  upgrade)         │  │                             │  │  WebSocket      ││
│  └───────────────────┘  │                             │  │  client via     ││
│         │               │                             │  │  LuaSocket)     ││
│         ▼               │                             │  └────────┬────────┘│
│  ┌───────────────────┐  │                             │           │         │
│  │ State (ServerState)│  │                             │           ▼         │
│  │ + EventLogger      │  │                             │  ┌─────────────────┐│
│  └───────────────────┘  │                             │  │ main.lua        ││
│         │               │                             │  │ (plugin entry)  ││
│         ▼               │                             │  └────────┬────────┘│
│  ┌───────────────────┐  │                             │           │         │
│  │ KeyboardListener   │  │                             │           ▼         │
│  │ + PlatformService  │  │                             │  ┌─────────────────┐│
│  │ (volume key        │  │                             │  │ Dispatcher      ││
│  │  interception)     │  │                             │  │ → PageForward   ││
│  └───────────────────┘  │                             │  │ → PageBackward  ││
└─────────────────────────┘                             │  │ → Device:suspend││
                                                        │  └─────────────────┘│
                                                        └─────────────────────┘
```

## WebSocket Protocol

### Handshake

KOReader sends an HTTP upgrade request over the raw TCP connection:

```
GET / HTTP/1.1
Host: <flutter_ip>:9090
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: <base64(16 random bytes)>
Sec-WebSocket-Version: 13
```

Flutter's `WebSocketTransformer.upgrade()` (from `dart:io`) responds:

```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: <base64(sha1(key + magic_guid))>
```

The `Sec-WebSocket-Accept` is computed as:
```
base64(sha1(Sec-WebSocket-Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
```

KOReader's `websocket.lua:connect()` validates the handshake by checking that `"101"` appears in the status line. It does NOT validate `Sec-WebSocket-Accept` (simplified implementation; the magic GUID check is unnecessary for a controlled client-server pair).

### WebSocket Frame Format (RFC 6455)

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
┌───────┬───────┬───────────────┬───────────────────────────────┐
│FIN    │Opcode │MASK           │ Payload length                │
│1 bit  │4 bit  │1 bit          │ 7/16/64 bit                   │
├───────┴───────┴───────────────┴───────────────────────────────┤
│ Extended payload length (if len=126: 2 bytes; 127: 8 bytes)  │
├───────────────────────────────────────────────────────────────┤
│ Masking-key (4 bytes, ONLY when MASK=1)                       │
├───────────────────────────────────────────────────────────────┤
│ Payload Data                                                   │
└───────────────────────────────────────────────────────────────┘
```

**Byte 0 — FIN + Opcode:**
- Bit 0 (FIN): 1 = final frame (fragmentation not used)
- Bits 1-3 (RSV): 0 (no extensions)
- Bits 4-7 (opcode): 0x1 = text, 0x8 = close, 0x9 = ping

**Byte 1 — Mask + Length:**
- Bit 0 (MASK): 1 = masked (client→server), 0 = unmasked (server→client)
- Bits 1-7: payload length (0-125). If 126 → next 2 bytes are length. If 127 → next 8 bytes are length.

**Design constraints in `websocket.lua`:**
- All frames are unmasked when received from server (server→client never masks)
- All frames are masked when sent from client (RFC 6455 mandates client→server masking)
- No fragmentation (FIN=1 for all frames)
- Only text frames (opcode 0x1) carry application data; ping (0x9) and close (0x8) are handled internally

## websocket.lua — Detailed Walkthrough

### Module setup (lines 1-5)

```lua
local socket = require("socket")
local mime = require("mime")
local bor, band, bxor, rshift = bit.bor, bit.band, bit.bxor, bit.rshift

math.randomseed(socket.gettime() * 10000)
```

- **`socket`**: LuaSocket library — provides TCP, UDP, DNS, and timing (`socket.gettime`, `socket.select`)
- **`mime`**: Part of LuaSocket — provides `mime.b64()` for base64 encoding of the WebSocket key
- **`bit`**: LuaJIT built-in — provides bitwise operations. Aliased to short names for brevity. LuaJIT (Lua 5.1) does NOT have `|`, `&`, `~` operators.
- **`math.randomseed`**: Seeds the PRNG using `socket.gettime()` (returns seconds as a float with millisecond precision). This ensures the 16-byte WebSocket key and the 4-byte masking key are unpredictable.

**Why not `math.randomseed(os.time())`?** `os.time()` only has second granularity — two connections within the same second would get identical keys. `socket.gettime()` has sub-millisecond precision.

### URL parser (lines 7-16)

```lua
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
```

Pattern breakdown: `^ws://([^:/]+):?(%d*)(.*)`

| Part              | Matches                    |
|-------------------|----------------------------|
| `^ws://`          | Literal `ws://` prefix     |
| `([^:/]+)`        | Host (IP or hostname)      |
| `:?`              | Optional colon separator   |
| `(%d*)`           | Port digits (maybe empty)  |
| `(.*)`            | Path (maybe empty)         |

Edge cases:
- `ws://192.168.1.5:9090/path` → host=`192.168.1.5`, port=`9090`, path=`/path`
- `ws://192.168.1.5:9090` → host=`192.168.1.5`, port=`9090`, path=`` → normalized to `/`
- `ws://192.168.1.5` → host=`192.168.1.5`, port=`` → normalized to `80`, path=`` → `/`
- `ws://hostname:9090` → works (DNS resolution handled later by `tcp:connect`)

### WebSocket key generation (lines 18-24)

```lua
local function generate_key()
  local t = {}
  for i = 1, 16 do
    t[i] = string.char(math.random(0, 255))
  end
  return mime.b64(table.concat(t))
end
```

Generates 16 random bytes, base64-encodes them. This produces a 24-character key like `"aB3x...=="` that RFC 6455 requires for the `Sec-WebSocket-Key` header. The server computes `Sec-WebSocket-Accept` from this key.

### Frame encoding (lines 26-61)

```lua
local function encode_frame(data)
  local payload = tostring(data)
  local len = #payload
  local opcode = 0x81  -- FIN(1) + RSV(000) + opcode(0001) = 0x81
```

`tostring(data)`: Ensures the input is a string. If `data` is already a string (as with `json.encode()` output), this is a no-op. If somehow `nil` were passed, `tostring(nil)` would throw — but the caller always passes a string.

#### Length encoding

```lua
  if len < 126 then
    header = string.char(opcode, bor(0x80, len))
```

**Small frames (≤125 bytes payload):** The length fits in 7 bits. `bor(0x80, len)` sets MASK=1. Example: 15-byte payload → `0x80 | 0x0F = 0x8F`.

```
Byte 0: 0x81
Byte 1: 0x8F
Bytes 2-5: masking key
Bytes 6-20: masked payload (15 bytes)
Total: 21 bytes
```

```lua
  elseif len < 65536 then
    header = string.char(
      opcode, bor(0x80, 126),
      band(rshift(len, 8), 0xFF),
      band(len, 0xFF)
    )
```

**Medium frames (126-65535 bytes payload):** Length indicator `126` signals that the next 2 bytes carry the real length in big-endian order.

```
Byte 0: 0x81
Byte 1: 0xFE (0x80 | 126)
Byte 2: (len >> 8) & 0xFF  — high byte
Byte 3: len & 0xFF         — low byte
Bytes 4-7: masking key
Bytes 8+: masked payload
```

```lua
  else
    header = string.char(opcode, bor(0x80, 127))
    for i = 7, 0, -1 do
      header = header .. string.char(band(rshift(len, i * 8), 0xFF))
    end
  end
```

**Large frames (≥65536 bytes payload):** Length indicator `127` signals 8-byte extended length. The loop writes bytes from most significant (i=7) to least significant (i=0). This is a portable 64-bit big-endian encoding that works even on 32-bit LuaJIT (since the number fits in Lua's `double`).

#### Masking

```lua
  local mk = string.char(
    math.random(0, 255), math.random(0, 255),
    math.random(0, 255), math.random(0, 255)
  )
  header = header .. mk
```

The masking key is 4 random bytes. RFC 6455 requires all client-to-server frames to be masked to prevent cache-poisoning attacks in proxy servers. The key is prepended to the payload after the length fields.

```lua
  local masked = {}
  for i = 1, len do
    local ki = ((i - 1) % 4) + 1
    masked[i] = string.char(
      bxor(string.byte(payload, i), string.byte(mk, ki))
    )
  end
  return header .. table.concat(masked)
```

Each payload byte is XORed with the corresponding masking key byte (`k[0]`, `k[1]`, `k[2]`, `k[3]`, `k[0]`, ...). The mask repeats every 4 bytes.

`((i - 1) % 4) + 1`: converts linear index `i` to cyclic index 1-4.

**Example:** Masking `{"type":"auth"}` (15 bytes) with key `\x01\x02\x03\x04`:
```
'a' (0x61) ⊕ 0x01 = 0x60 → '`'
'u' (0x75) ⊕ 0x02 = 0x77 → 'w'
't' (0x74) ⊕ 0x03 = 0x77 → 'w'
'h' (0x68) ⊕ 0x04 = 0x6C → 'l'
'"' (0x22) ⊕ 0x01 = 0x23 → '#'
...continues cyclicly...
```

### Frame decoding (lines 73-137)

```lua
function client:recv()
  local readable = socket.select({self._sock}, nil, 0)
  if #readable == 0 then return end
```

**Non-blocking entry:** `socket.select({sock}, nil, 0)` checks if the socket has data available to read — with 0 timeout, it returns IMMEDIATELY. This is the key architectural decision that prevents UI blocking (see "Connection Maintenance" section below).

```lua
  local data, err
  data, err = self._sock:receive(2)
  if not data then return end

  local hdr = data
  local b2 = string.byte(hdr, 2)
  local len = band(b2, 0x7F)
  local masked = band(b2, 0x80) ~= 0
```

Reads the 2-byte frame header and parses:
- `b2`: second byte (MASK bit + payload length)
- `len`: masked with `0x7F` to extract the 7-bit length
- `masked`: `band(b2, 0x80)` checks the MASK bit; `~= 0` converts to boolean

**Important:** `socket.receive(n)` returns `data, err` (NOT `ok, err`). On success, `data` is the received string and `err` is `nil`. On failure, `data` is `nil` and `err` is the error message.

```lua
  if len == 126 then
    data, err = self._sock:receive(2)
    if not data then return end
    hdr = hdr .. data
    len = string.byte(data, 1) * 256 + string.byte(data, 2)
  elseif len == 127 then
    data, err = self._sock:receive(8)
    if not data then return end
    hdr = hdr .. data
    len = 0
    for i = 0, 7 do
      len = len * 256 + string.byte(data, i + 1)
    end
  end
```

Extended length parsing:
- **126:** Read 2 bytes, compute a 16-bit big-endian integer
- **127:** Read 8 bytes, compute a 64-bit big-endian integer by iterating each byte

For the 64-bit case, the loop accumulates the value using `len = len * 256 + byte`. This works for payloads up to 2^53 bytes (Lua's number precision limit), which is far beyond any practical WebSocket message.

```lua
  local mask_key
  if masked then
    data, err = self._sock:receive(4)
    if not data then return end
    mask_key = data
    hdr = hdr .. mask_key
  end
```

If MASK=1, reads the 4-byte masking key. Server-to-client frames are NEVER masked (per RFC 6455), but the code handles both cases for robustness.

```lua
  local payload = ""
  if len > 0 then
    data, err = self._sock:receive(len)
    if not data then return end
    payload = data
  end
```

Reads the exact number of payload bytes. `len` is 0 only for empty messages (like a close frame with no body).

```lua
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
```

Unmasking is the inverse of masking: XOR each payload byte with the mask key (cycling every 4 bytes). `table.concat` is used instead of string concatenation (`..`) because repeated `..` in a loop creates many intermediate strings and is O(n²). `table.concat` is O(n) and far more efficient for payloads of any size.

```lua
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
```

Opcode dispatch:
- **0x08 (Close):** Cleanly close the socket and return nil (caller sees disconnection)
- **0x09 (Ping):** Respond with a Pong frame (`0x8A` = FIN + opcode 0xA, `0x00` = unmasked zero-length payload). Then recurse to `recv()` to get the next frame. The ping/pong is transparent to the application layer.
- **0x01 (Text) / 0x02 (Binary):** Return `nil, { data = payload }`. The `nil` first return signals success (no error); the table with `data` key is the parsed result.

**Return convention:**
```lua
-- Success: no error, data table
return nil, { data = payload }

-- No data (timeout or select returned nothing):
return  -- returns nil, nil

-- Error: string message
return "error message here"

-- Connection closed:
self:close()
return
```

Caller pattern:
```lua
local _, msg = client:recv()
if msg then
    -- msg.data contains the JSON string
    local ok, decoded = pcall(json.decode, msg.data)
end
```

### Timeout control (lines 140-143)

```lua
function client:settimeout(seconds)
  if self._sock then
    self._sock:settimeout(seconds)
  end
end
```

Delegates to LuaSocket's `settimeout`. The timeout applies only to `receive()` and `send()` calls. With the `socket.select()` check at the top of `recv()`, the timeout is only hit in edge cases (fragmented TCP segments). Default: 5 seconds (set by `startMessageLoop`).

### Connection cleanup (lines 146-151)

```lua
function client:close()
  if self._sock then
    pcall(self._sock.send, self._sock, string.char(0x88, 0x00))
    self._sock:close()
    self._sock = nil
  end
end
```

Sends a Close frame (`0x88` = FIN + opcode 8, `0x00` = unmasked, length 0) before closing the TCP socket. The `pcall` wrapper ensures that `send` doesn't throw if the connection is already half-closed. After close, `_sock` is set to `nil` so that any subsequent calls fail gracefully.

### Connection function (lines 154-190)

```lua
local function connect(url)
  local host, port, path = parse_url(url)
  if not host then return nil, url end
```

Parses the URL. If parsing fails, returns `nil` with the original URL as the error message (allows callers to display the invalid URL).

```lua
  local tcp = socket.tcp()
  tcp:settimeout(10)

  local ok, err = tcp:connect(host, port)
  if not ok then
    tcp:close()
    return nil, err
  end
```

Creates a TCP socket with a 10-second connection timeout. `tcp:connect()` returns `1, nil` on success, `nil, err` on failure. Note: `tcp:connect()` follows LuaSocket's convention of returning `ok, err` (NOT `data, err`). This is different from `tcp:receive()`.

```lua
  local key = generate_key()
  local req = string.format(
    "GET %s HTTP/1.1\r\nHost: %s:%d\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n",
    path, host, port, key
  )

  ok, err = tcp:send(req)
  if not ok then tcp:close() return nil, err end
```

Sends the HTTP upgrade request. `\r\n\r\n` terminates the headers. The request must include exactly these headers for the Dart `WebSocketTransformer.isUpgradeRequest()` to recognize it:

| Header              | Required value            |
|---------------------|---------------------------|
| `Upgrade`           | `websocket`               |
| `Connection`        | `Upgrade`                 |
| `Sec-WebSocket-Key` | base64-encoded 16 bytes   |
| `Sec-WebSocket-Version` | `13`                  |

```lua
  local resp, err2
  resp, err2 = tcp:receive("*l")
  if not resp then tcp:close() return nil, "no response" end
  if not resp:find("101") then
    tcp:close()
    return nil, "handshake failed: " .. (resp or "unknown")
  end

  while true do
    resp, err2 = tcp:receive("*l")
    if not resp then tcp:close() return nil, "incomplete headers" end
    if resp == "" then break end
  end
  return setmetatable({ _sock = tcp }, client)
end
```

Reads the HTTP response:
1. First line: `receive("*l")` reads until `\n`. Checks for `"101"` in the status line.
2. Remaining headers: loop `receive("*l")` until the blank line (empty string after stripping `\r\n`).
3. Returns a metatable with `_sock` pointing to the TCP socket, and `__index` = `client` (the prototype table containing `send`, `recv`, `close`, `settimeout`).

**Note:** LuaSocket's `receive("*l")` returns the line WITHOUT the trailing `\r\n`. So the blank line becomes `""`, and headers are returned clean (e.g., `"Upgrade: websocket"` instead of `"Upgrade: websocket\r"`).

## Authentication Flow

### No Password

```
KOReader                         Flutter
   │                                │
   ├── WebSocket handshake ────────►│
   │◄── 101 Switching Protocols ───┤
   │                                │
   ├── {"type":"hello",             │
   │    "device_name":"KOReader"}──►│
   │                                ├── Log "connected" event
   │                                ├── Set deviceName in state
   │◄── (connection ready) ────────┤
```

- `KOReader → Flutter`: sends `hello` message
- `Flutter`: if `!auth.hasPassword`, logs the event, sets device name, and continues
- `KOReader`: returns `true` (no further response expected)
- **Total latency:** ~1 network round trip

### With Password

```
KOReader                         Flutter
   │                                │
   ├── WebSocket handshake ────────►│
   │◄── 101 ───────────────────────┤
   │                                │
   ├── {"type":"auth"} ────────────►│
   │                                ├── challenge = generateChallenge()
   │                                │   (32 random hex bytes)
   │◄── {"type":"auth_challenge",   │
   │     "challenge":"<hex>"}───────┤
   │                                │
   ├── {"type":"auth_response",     │
   │    "hash": sha256(pass+chal),  │
   │    "device_name":"KOReader"}──►│
   │                                ├── auth.verify(challenge, hash)
   │                                │   → sha256(password + challenge)
   │                                │     == received hash
   │◄── {"type":"auth_result",      │
   │     "success":true}────────────┤
   │                                │
   │        OR                      │
   │                                │
   │◄── {"type":"auth_result",      │
   │     "success":false}───────────┤
   │      (server closes socket)    │
```

**Password verification (Flutter side):**

```dart
// websocket_server.dart
if (auth.verify(challenge ?? '', hash ?? '')) {
  socket.add(json.encode({'type': 'auth_result', 'success': true}));
} else {
  socket.add(json.encode({'type': 'auth_result', 'success': false}));
  socket.close();
}
```

```dart
// password_auth.dart
bool verify(String challenge, String hash) {
  return sha256.convert(utf8.encode(password + challenge)).toString() == hash;
}
```

**Password response (KOReader side):**

```lua
local hash = sha.sha256(password .. data.challenge)
client:send(json.encode({
    type = "auth_response",
    hash = hash,
    device_name = "KOReader",
}))
```

**Why not bcrypt/argon2?** SHA-256 over a concatenated string is sufficient for a local WiFi connection. The challenge prevents replay attacks within the same session. A new challenge is generated for each connection attempt.

**Important:** The `challenge` variable in Flutter must be captured by the socket's listen closure, NOT passed as a parameter. See `websocket_server.dart:_handleWebSocket()` — `challenge` is declared as a local variable in the closure and modified directly.

### Error states

| Error                        | When                                  | KOReader sees          |
|------------------------------|---------------------------------------|------------------------|
| Handshake timeout            | No HTTP 101 within 10s                | `"connection failed"`  |
| Invalid URL                  | URL doesn't match `ws://...`          | `"connection failed"`  |
| TCP connection refused       | Wrong port or server not running      | `"connection failed"`  |
| No auth challenge            | Server doesn't respond after `auth`   | `"no response from server"` |
| Wrong password               | Server returns `success: false`       | `"invalid password"`   |
| Unexpected message           | Server sends non-challenge message    | `"unexpected response"`|

## Connection Maintenance

### The Problem

A naive polling loop blocks the UI:

```lua
-- BAD: blocks KOReader's UI for 0.5 seconds every iteration
local function poll()
    local _, msg = client:recv()  -- recv() calls receive(2) with 0.5s timeout
    -- UI is frozen during this 0.5s
    UIManager:scheduleIn(0.5, poll)
end
```

With 0.5s polling and 0.5s block per iteration, KOReader is unresponsive 50% of the time. Users perceive this as lag (`"đơ"`).

### The Solution: Non-blocking socket.select()

The Calibre plugin (KOReader's built-in) solves this using ZeroMQ's `zpoller_wait(poller, 0)` — a non-blocking poll with zero timeout. Remote Turner replicates this with LuaSocket's `socket.select()`:

```lua
function client:recv()
  local readable = socket.select({self._sock}, nil, 0)
  if #readable == 0 then return end  -- no data → return immediately
  -- data available → read frame (will not block)
  ...
end
```

**How `socket.select` works:**
- Takes three sets: read sockets, write sockets, and exceptional sockets
- Takes a timeout in seconds (0 = non-blocking)
- Returns sockets that have data ready to read/write
- Uses the OS's `poll()` or `select()` syscall under the hood
- With timeout 0, it returns immediately without blocking

**When there's no data:**
```
recv() called
  → socket.select({sock}, nil, 0) → {} (empty, no data)
  → return (nil, nil)
poll() sees nil, schedules next check in 2 seconds
```

**When data arrives:**
```
recv() called
  → socket.select({sock}, nil, 0) → {sock} (data available!)
  → receive(2) → reads frame header immediately
  → receive(len) → reads payload immediately
  → return nil, { data = payload }
poll() processes the action, schedules next check in 2 seconds
```

**Timer resolution:** `UIManager:scheduleIn(2, poll)` fires the poll every 2 seconds. This means max action latency is ~2 seconds (acceptable for page turning). The 2-second interval minimizes CPU wake-ups on e-ink devices (battery life).

### Comparison with Calibre approach

| Aspect           | Calibre Plugin            | Remote Turner                |
|------------------|---------------------------|------------------------------|
| Library          | CZMQ (ZeroMQ)             | LuaSocket (pure Lua)         |
| Non-blocking     | `zpoller_wait(poller, 0)` | `socket.select({sock},0,0)`  |
| UIManager hook   | `insertZMQ()` / `processZMQs()` | `UIManager:scheduleIn` |
| Poll interval    | ~50ms (configurable)      | 2000ms                       |
| Protocol         | ZMQ_STREAM (TCP)          | WebSocket (RFC 6455 framing) |
| Data reading     | `zframe_recv()`           | `tcp:receive(n)`             |
| UI integration   | Native via `_zeromqs`     | Coroutine via `scheduleIn`   |

## JSON Message Format

### KOReader → Flutter

```json
{"type":"hello", "device_name":"KOReader"}
{"type":"auth"}
{"type":"auth_response", "hash":"<sha256 hex>", "device_name":"KOReader"}
```

- `type: "hello"`: Sent when no password is configured. Tells Flutter the device name.
- `type: "auth"`: Requests an authentication challenge.
- `type: "auth_response"`: Responds to the challenge with the computed hash.

### Flutter → KOReader

```json
{"type":"auth_challenge", "challenge":"<32 hex bytes>"}
{"type":"auth_result", "success":true}
{"type":"action", "action":"next_page"}
{"type":"action", "action":"prev_page"}
{"type":"action", "action":"sleep"}
```

- `action` messages are sent by Flutter when the user presses volume keys, clicks buttons, or triggers any mapped key event.

## Action Processing (KOReader side)

Flow when an action message is received:

```
recv() returns { data = '{"type":"action","action":"next_page"}' }
    │
    ├── json.decode(msg.data)
    │   → { type = "action", action = "next_page" }
    │
    ├── Check data.action
    │   │
    │   ├── "next_page"
    │   │   └── Event:new("PageForward")
    │   │       → self.ui:handleEvent(event)
    │   │       → ReaderPaging:onPageForward()
    │   │         OR ReaderRolling:onPageForward()
    │   │
    │   ├── "prev_page"
    │   │   └── Event:new("PageBackward")
    │   │       → self.ui:handleEvent(event)
    │   │       → ReaderPaging:onPageBackward()
    │   │         OR ReaderRolling:onPageBackward()
    │   │
    │   └── "sleep"
    │       └── Device:suspend()
    │           → platform suspend (e-ink deep sleep)
    │
    └── (0.5s later) schedule next poll
```

**Event dispatching:** KOReader's `self.ui:handleEvent(Event:new("PageForward"))` is the canonical way to trigger page turns — it dispatches through KOReader's event system, which the active reader view module (ReaderPaging or ReaderRolling) handles based on the current document mode.

**Sleep handling:** `Device:suspend()` calls KOReader's platform abstraction layer, which triggers the device-specific suspend mechanism. On e-ink devices, this typically powers off the screen and CPU while keeping RAM alive.

## Volume Key Handling (Flutter side)

### Android

```
Volume key press
    │
    ├── BackgroundService.kt (Foreground Service)
    │   └── MediaSession.setCallback(...)
    │       → onVolumeKeyLongPress / onVolumeKeyDown
    │
    ├── MethodChannel("volume_key_channel")
    │   → kotlin: result.success("volume_up")
    │
    └── PlatformService.volumeEvents (Flutter)
        → app.dart: wsServer.sendAction(...)
```

The Android implementation uses a foreground service (to stay alive) with a `MediaSession` (to intercept volume keys). This is the only reliable way to capture hardware volume buttons on Android 10+ — standard `KeyEvent` listeners are consumed by the OS for volume control.

### iOS

```
System volume changes
    │
    ├── AVAudioSession.sharedInstance().outputVolume KVO
    │   → AppDelegate.swift observeValue()
    │
    ├── FlutterEventChannel("volume_event_channel")
    │   → Swift: eventSink?("volume_up")
    │
    └── PlatformService.volumeEvents (Flutter)
        → app.dart: wsServer.sendAction(...)
```

iOS does not allow intercepting hardware volume buttons directly. The workaround uses `AVAudioSession.outputVolume` KVO to detect when the volume changes (i.e., the user pressed a volume button). **Caveat:** This changes the system volume and shows the volume HUD. There is no known way to avoid this on iOS without jailbreaking.

### Desktop (Linux / Windows / macOS)

```
Volume key press
    │
    ├── Flutter KeyboardListener widget
    │   → onKeyEvent callback
    │
    ├── KeyboardListenerService.handleKeyEvent()
    │   → Compare LogicalKeyboardKey with user config
    │
    └── wsServer.sendAction(action)
```

Desktop platforms use Flutter's `KeyboardListener` widget, which receives all key events including volume/media keys. The key mapping is configurable via the Settings page.

## Key Mapping

### Default configuration

| Action    | Default Key              |
|-----------|--------------------------|
| Forward   | `LogicalKeyboardKey.audioVolumeUp`   |
| Backward  | `LogicalKeyboardKey.audioVolumeDown` |
| Sleep     | `LogicalKeyboardKey.audioVolumeMute` |

### Configuration storage

Saved to `SharedPreferences` as three key-value pairs:

```
settings_forward_key → audioVolumeUp
settings_backward_key → audioVolumeDown
settings_sleep_key → audioVolumeMute
```

### Lookup flow

```dart
// keyboard_listener.dart
KeyAction? actionForKey(LogicalKeyboardKey key) {
  if (key == config.forwardKey) return KeyAction.forward;
  if (key == config.backwardKey) return KeyAction.backward;
  if (key == config.sleepKey) return KeyAction.sleep;
  return null;
}
```

`LogicalKeyboardKey` uses Dart's value equality (`==`), so two key constants with the same keyId are equal. This allows comparison regardless of platform-specific key codes.

## Common Pitfalls

### 1. LuaSocket `receive()` returns `(data, err)`, NOT `(ok, err)`

This is the most common bug. Different LuaSocket functions use different return conventions:

| Function            | Return values            |
|---------------------|--------------------------|
| `tcp:receive(n)`    | `(data, err, partial)`   |
| `tcp:connect(...)`  | `(ok, err)`              |
| `tcp:send(...)`     | `(ok, err)`              |
| `tcp:settimeout(n)` | `(ok, err)`              |

**Incorrect:**
```lua
-- WRONG: captures data as "ok", err as "line"
local ok, line = tcp:receive("*l")
if not ok then ... end              -- ok is data, not a boolean
line:find("101")                    -- CRASH: line is nil (err is nil on success)
```

**Correct:**
```lua
-- RIGHT: captures data as "resp", err as "err2"
local resp, err2 = tcp:receive("*l")
if not resp then ... end            -- resp is nil on failure
resp:find("101")                    -- resp is the HTTP response line
```

### 2. Lua 5.1/LuaJIT lacks bitwise operators

LuaJIT (KOReader uses Lua 5.1) does NOT support `|`, `&`, `~` operators:

```lua
-- WRONG (Lua 5.3+ syntax, crashes on LuaJIT):
local masked = (b2 & 0x80) ~= 0
header = string.char(opcode, 0x80 | len)

-- RIGHT (LuaJIT compatible):
local masked = bit.band(b2, 0x80) ~= 0
header = string.char(opcode, bit.bor(0x80, len))
```

KOReader provides `bit` (LuaJIT built-in) which has:
- `bit.bor(a, b)` — bitwise OR
- `bit.band(a, b)` — bitwise AND
- `bit.bxor(a, b)` — bitwise XOR
- `bit.rshift(x, n)` — right shift
- `bit.lshift(x, n)` — left shift

Tip: alias these to short names at the top of the file:
```lua
local bor, band, bxor, rshift = bit.bor, bit.band, bit.bxor, bit.rshift
```

### 3. `math.randomseed` must be seeded once

Without seeding, `math.random()` returns the same sequence every time the module loads. This would produce identical WebSocket keys and masking keys across KOReader restarts.

```lua
-- Seed at module load time
math.randomseed(socket.gettime() * 10000)
```

`os.time()` has only second granularity — use `socket.gettime()` for sub-millisecond precision.

### 4. Flutter: `String?` pass-by-value in parameters

```dart
// WRONG: challenge is modified in a parameter copy
void _handleMessage(..., String? challenge) {
  challenge = value;  // only modifies local copy
}

// RIGHT: challenge captured by closure
String? challenge;
socket.listen((data) {
  challenge = value;  // modifies the actual variable
});
```

### 5. Frame fragmentation

Current `websocket.lua` assumes all frames have FIN=1 (no fragmentation). This is valid because Dart's `WebSocket` implementation sends unfragmented frames for small JSON messages. If fragmentation were needed, the code would need to buffer partial frames and reassemble based on FIN bits.

### 6. UTF-8 validation

The current implementation does NOT validate that text frame payloads are valid UTF-8. Dart's WebSocket implementation sends valid UTF-8, so this is safe for this use case.

## References

- [RFC 6455 — The WebSocket Protocol](https://datatracker.ietf.org/doc/html/rfc6455)
- [LuaSocket 3 Reference Manual](http://w3.impa.br/~diego/software/luasocket/)
- [KOReader UIManager](https://github.com/koreader/koreader/blob/master/frontend/ui/uimanager.lua)
- [KOReader Calibre plugin](https://github.com/koreader/koreader/tree/master/plugins/calibre.koplugin)
- [Dart WebSocket class](https://api.dart.dev/stable/dart-io/WebSocket-class.html)
