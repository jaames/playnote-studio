import 'CoreLibs/object'

utils = {}

function utils:readTextFile(path)
  local f = playdate.file.open(path, playdate.file.kFileRead)
  local text = ''
  while true do
    local line = f:readline()
    if (line == nil) then break end
    text = text .. line .. '\n'
  end
  f:close()
  return text
end

function utils:clampScroll(pos, start, height)
  if pos <= -(height - 240) then
    return -(height - 240)
  elseif pos >= start then
    return start
  end
  return pos
end

function utils:clearArray(t)
  for k in pairs(t) do
    t[k] = nil
  end
end