utils = {}

function table.combine(...)
  local tbl = {}
  local i = 1
  for _, b in pairs({...}) do
    for _, v in pairs(b) do
      tbl[i] = v
      i = i + 1
    end
  end
  return tbl
end

-- execute callback function on next frame
function utils:nextTick(callback)
  playdate.frameTimer.new(1, callback)
end

function utils:markScreenDirty()
  local x, y = gfx.getDrawOffset()
  spritelib.addDirtyRect(x, y, PLAYDATE_W, PLAYDATE_H)
end

-- create a removable button repeater
function utils:createRepeater(delayAfterInitialFiring, delayAfterSecondFiring, callback)
  local repeatTimer = nil
  local isRepeat = false

  local function remove()
    if repeatTimer ~= nil then
      repeatTimer:remove()
      repeatTimer = nil
    end
  end

  local function buttonDown()
    repeatTimer = playdate.timer.keyRepeatTimerWithDelay(delayAfterInitialFiring, delayAfterSecondFiring, function ()
      callback(isRepeat)
    end)
    isRepeat = true
  end

  local function buttonUp()
    remove()
    isRepeat = false
  end
  return buttonDown, buttonUp, remove
end

function utils:hookFn(origFn, hookFn)
  if type(origFn) == 'function' then
    return function (...)
      origFn(...)
      hookFn(...)
    end
  else
    return hookFn
  end
end

-- clamp value between lower and upper
function utils:clamp(val, lower, upper)
  return math.max(lower, math.min(upper, val))
end

-- set all the elements in a table to nil
function utils:clearArray(t)
  for k in pairs(t) do
    t[k] = nil
  end
end