local component = component or require("component")
local computer = computer or require("computer")

local args = {...}
local pkg = args[1]

if not pkg then
  print("Usage: eliot remove <package>")
  return
end

if pkg:find("/", 1, true) or pkg:find("\\", 1, true) or pkg:find("..", 1, true) then
  print("Invalid package name: " .. pkg)
  return
end

local base = "/./bin/packages/"
local path = base .. pkg

local fs = component.proxy(computer.getBootAddress())

if not fs.exists(path) then
  print("Package not installed: " .. pkg)
  return
end

if fs.remove(path) then
  print("Removed " .. pkg)
else
  print("Could not remove " .. pkg)
end
