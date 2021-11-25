import 'CoreLibs/object'
import 'CoreLibs/frameTimer'

utils = {}

-- execute callback function on next frame
function utils:nextTick(callback)
  playdate.frameTimer.new(1, callback)
end

-- read a text file line by line and return it as a single string
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

-- returns true if a given folder is internal
function utils:isInternalFolder(name)
  return (
    name == 'data/' or
    name == 'fonts/' or
    name == 'img/' or
    name == 'components/' or
    name == 'screens/' or
    name == 'services/'
  )
end

function utils:clamp(val, lower, upper)
  return math.max(lower, math.min(upper, val))
end

-- clamp scroll position pos between start (usually 0) and height (usually page height)
function utils:clampScroll(pos, start, height)
  if pos <= -(height - 240) then
    return -(height - 240)
  elseif pos >= start then
    return start
  end
  return pos
end

-- set all the elements in a table to nil
function utils:clearArray(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

-- ugly as shit draw deferring

local deferredDraws = {}

function utils:deferDraw(callback)
  table.insert(deferredDraws, callback)
end

function utils:doDeferredDraws()
  for _, fn in pairs(deferredDraws) do
    fn()
  end
  deferredDraws = {}
end