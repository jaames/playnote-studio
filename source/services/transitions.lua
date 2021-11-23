import 'CoreLibs/object'

-- BASE TRANSITION

TransitionBase = {}
class('TransitionBase').extends()

function TransitionBase:init(a, b, completedCallback)
  TransitionBase.super.init(self)
  local duration, easing = self:getProps()
  local timer = playdate.timer.new(duration, 0, 1, easing)

  timer.updateCallback = function ()
    self:onUpdate(timer.value, a, b)
  end

  timer.timerEndedCallback = function ()
    self:onUpdate(1)
    completedCallback()
  end
end

function TransitionBase:getProps()
  return 250, playdate.easingFunctions.linear
end

function TransitionBase:onUpdate(t, a, b)
end

function TransitionBase:onCompleted()
end

-- CROSSFADE TRANSITION

CrossfadeTransition = {}
class('CrossfadeTransition').extends(TransitionBase)

function CrossfadeTransition:onUpdate(t, a, b)
  if t < 0.5 and a ~= nil then
    a:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
  if t >= 0.5 and b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

-- BOOTUP TRANSITION

BootupTransition = {}
class('BootupTransition').extends(TransitionBase)

function BootupTransition:getProps()
  return 400, playdate.easingFunctions.linear
end

function BootupTransition:onUpdate(t, a, b)
  if b ~= nil then
    b:update()
    gfxUtils:drawWhiteFade(t)
  end
end