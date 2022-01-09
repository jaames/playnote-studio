utils = {}

-- execute callback function on next frame
function utils:nextTick(callback)
  playdate.frameTimer.new(1, callback)
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

-- clamp value between lower and upper
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