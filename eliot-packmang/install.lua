local component = component or require("component")
local computer = computer or require("computer")

local args = {...}
local pkg = args[1]

if not pkg then
  print("Usage: eliot install <package>")
  return
end

local repo = "remy-eliot/eliot-packages"
local branch = "main"
local base = "/home/packages/"

local netAddr = component.list("internet")()
if not netAddr then
  print("No internet card found")
  return
end

local net = component.proxy(netAddr)
local fs = component.proxy(computer.getBootAddress())

local function get(url)
  local ok, h = pcall(net.request, url, nil, {["User-Agent"] = "OpenComputers"})
  if not ok or not h then return nil, tostring(h) end
  while true do
    local ok2, c = pcall(h.finishConnect)
    if not ok2 then return nil, tostring(c) end
    if c then break end
    computer.pullSignal(0.05)
  end
  local chunks = {}
  while true do
    local ok3, chunk = pcall(h.read, math.huge)
    if not ok3 then return nil, tostring(chunk) end
    if chunk == nil then break end
    if chunk ~= "" then
      chunks[#chunks + 1] = chunk
    else
      computer.pullSignal(0.05)
    end
  end
  pcall(h.close)
  return table.concat(chunks)
end

local function mkdirs(path)
  local cur = ""
  for part in path:gmatch("[^/]+") do
    cur = cur .. "/" .. part
    if not fs.exists(cur) then fs.makeDirectory(cur) end
  end
end

local function save(path, data)
  local dir = path:match("^(.*)/[^/]*$")
  if dir and dir ~= "" then mkdirs(dir) end
  local h = fs.open(path, "w")
  if not h then return false end
  fs.write(h, data)
  fs.close(h)
  return true
end

local tree, err = get("https://api.github.com/repos/" .. repo .. "/git/trees/" .. branch .. "?recursive=1")
if not tree then
  print("Failed to get package list: " .. tostring(err))
  return
end

local files = {}
local prefix = pkg .. "/"
for path, kind in tree:gmatch('"path"%s*:%s*"([^"]*)".-"type"%s*:%s*"(%a+)"') do
  if kind == "blob" and path:sub(1, #prefix) == prefix then
    files[#files + 1] = path
  end
end

if #files == 0 then
  print("Package not found: " .. pkg)
  return
end

for _, path in ipairs(files) do
  local data, e = get("https://raw.githubusercontent.com/" .. repo .. "/" .. branch .. "/" .. path)
  if not data then
    print("Failed: " .. path .. " (" .. tostring(e) .. ")")
    return
  end
  if save(base .. path, data) then
    print("Installed " .. base .. path)
  else
    print("Could not write " .. base .. path)
    return
  end
end

print("Done: " .. pkg)