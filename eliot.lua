local args = {...}
local cmd = args[1]
local dir = "/./bin/eliot-packmang/"

if not cmd then
  cmd = "help"
end

local fn, err = loadfile(dir .. cmd .. ".lua")
if not fn then
  print("Unknown command: " .. cmd)
  return
end

fn(table.unpack(args, 2))
