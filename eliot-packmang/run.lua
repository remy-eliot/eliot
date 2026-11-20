local args = {...}
local pkg = args[1]

if not pkg then
  print("Usage: eliot run <package> [arguments]")
  return
end

if pkg:find("/", 1, true) or pkg:find("\\", 1, true) or pkg:find("..", 1, true) then
  print("Invalid package name: " .. pkg)
  return
end

local base = "/./bin/packages/"
local path = base .. pkg .. "/main.lua"

local fn, err = loadfile(path)
if not fn then
  print("Could not load " .. path)
  print(tostring(err))
  return
end

fn(table.unpack(args, 2))
