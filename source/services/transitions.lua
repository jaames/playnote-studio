transitions = {}

local function newTransition(duration, easing, onBegin, onUpdate)
  return function(a, b, completedCallback)
    local timer = playdate.timer.new(duration, 0, 1, easing)

    if type(onBegin) == 'function' then
      onBegin()
    end

    timer.updateCallback = function ()
      onUpdate(timer.value, a, b)
    end

    timer.timerEndedCallback = function ()
      onUpdate(1, a, b)
      completedCallback()
    end
  end
end

transitions.kTransitionNone = newTransition(0, playdate.easingFunctions.linear, nil, function (t, a, b) end)

transitions.kTransitionCrossfade = newTransition(250, playdate.easingFunctions.linear, nil, function (t, a, b)
  if t < 0.5 and a ~= nil then
    a:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
  if t >= 0.5 and b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end)

transitions.kTransitionStartup = newTransition(320, playdate.easingFunctions.linear, nil, function (t, a, b)
  if b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade(t)
  end
end)