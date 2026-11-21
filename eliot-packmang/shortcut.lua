local component = component or require("component")
local computer = computer or require("computer")

local args = {...}
local action = args[1]
local pkg = args[2]

if action ~= "add" and action ~= "remove" or not pkg then
  print("Usage: eliot shortcut add <package>")
  print("       eliot shortcut remove <package>")
  return
end

if pkg:find("/", 1, true) or pkg:find("\\", 1, true) or pkg:find("..", 1, true) then
  print("Invalid package name: " .. pkg)
  return
end

local base = "/./bin/packages/"
local target = "/./bin/"
local main = base .. pkg .. "/main.lua"
local link = target .. pkg .. ".lua"

local fs = component.proxy(computer.getBootAddress())

local function readAll(path)
  local h = fs.open(path, "r")
  if not h then return nil end
  local chunks = {}
  while true do
    local chunk = fs.read(h, math.huge)
    if not chunk then break end
    chunks[#chunks + 1] = chunk
  end
  fs.close(h)
  return table.concat(chunks)
end

if action == "add" then
  if not fs.exists(main) then
    print("Package not installed: " .. pkg)
    return
  end
  if fs.exists(link) then
    print("A file named " .. pkg .. ".lua already exists in /bin")
    return
  end
  local code = 'local fn, err = loadfile("' .. main .. '")\n'
    .. 'if not fn then\n'
    .. '  print("Could not load " .. "' .. main .. '")\n'
    .. '  print(tostring(err))\n'
    .. '  return\n'
    .. 'end\n'
    .. 'fn(...)\n'
  local h = fs.open(link, "w")
  if not h then
    print("Could not write " .. link)
    return
  end
  fs.write(h, code)
  fs.close(h)
  print("Shortcut created: " .. pkg)
else
  if not fs.exists(link) then
    print("No shortcut for: " .. pkg)
    return
  end
  local data = readAll(link)
  if not data or not data:find(main, 1, true) then
    print(link .. " is not an eliot shortcut")
    return
  end
  if fs.remove(link) then
    print("Shortcut removed: " .. pkg)
  else
    print("Could not remove " .. link)
  end
end
