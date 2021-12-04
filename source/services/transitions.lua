-- BASE TRANSITION

local function makeTransition(duration, easing, onUpdate)
  return function(a, b, completedCallback)
    local timer = playdate.timer.new(duration, 0, 1, easing)

    timer.updateCallback = function ()
      onUpdate(timer.value, a, b)
    end

    timer.timerEndedCallback = function ()
      onUpdate(1, a, b)
      completedCallback()
    end
  end
end

-- CROSSFADE TRANSITION

CrossfadeTransition = makeTransition(250, playdate.easingFunctions.linear, function (t, a, b)
  if t < 0.5 and a ~= nil then
    a:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
  if t >= 0.5 and b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end)

-- BOOTUP TRANSITION

BootupTransition = makeTransition(320, playdate.easingFunctions.linear, function (t, a, b)
  if b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade(t)
  end
end)