local function get(name)
  local g = _G and _G[name]
  if g then return g end
  if type(require) == "function" then
    local ok, m = pcall(require, name)
    if ok and m then return m end
  end
  if package and package.loaded and package.loaded[name] then
    return package.loaded[name]
  end
end

local component = get("component")
local computer = get("computer")

if not component or not computer then
  error("component/computer API not available")
end

local gpuAddr = component.list("gpu")()
local screenAddr = component.list("screen")()
local netAddr = component.list("internet")()

local gpu = gpuAddr and component.proxy(gpuAddr)
if gpu and screenAddr and not gpu.getScreen() then
  gpu.bind(screenAddr, false)
end

local w, h = 50, 16
if gpu then
  w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

local y = 0
local function out(text)
  if not gpu then return end
  y = y + 1
  if y > h then
    gpu.copy(1, 2, w, h - 1, 0, -1)
    gpu.fill(1, h, w, 1, " ")
    y = h
  end
  gpu.set(1, y, text)
end

local function waitKey()
  while computer.pullSignal(0) do end
  while true do
    local e = computer.pullSignal()
    if e == "key_down" then return end
  end
end

local function fail(msg)
  out(msg)
  out("Press any key...")
  waitKey()
end

if not netAddr then
  return fail("No internet card found")
end

local net = component.proxy(netAddr)
local url = "https://api.github.com/repos/remy-eliot/eliot-packages/git/trees/main"

local okReq, handle = pcall(net.request, url, nil, {["User-Agent"] = "OpenComputers"})
if not okReq or not handle then
  return fail("Request failed: " .. tostring(handle))
end

while true do
  local ok, connected = pcall(handle.finishConnect)
  if not ok then
    return fail("Connection failed: " .. tostring(connected))
  end
  if connected then break end
  computer.pullSignal(0.05)
end

local chunks = {}
while true do
  local ok, chunk = pcall(handle.read, math.huge)
  if not ok then
    return fail("Read failed: " .. tostring(chunk))
  end
  if chunk == nil then break end
  if chunk ~= "" then
    chunks[#chunks + 1] = chunk
  else
    computer.pullSignal(0.05)
  end
end
pcall(handle.close)

local body = table.concat(chunks)

local dirs = {}
for name, kind in body:gmatch('"path"%s*:%s*"([^"]*)".-"type"%s*:%s*"(%a+)"') do
  if kind == "tree" and not name:find("/", 1, true) then
    dirs[#dirs + 1] = name
  end
end

table.sort(dirs)

out("packages:")
if #dirs == 0 then
  out("     (none found)")
  out(body:sub(1, 200))
else
  for _, d in ipairs(dirs) do
    out("     " .. d)
  end
end

out("")
out("Press any key...")
waitKey()