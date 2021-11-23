import 'CoreLibs/object'

ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.inputHandlers = nil
end

function ScreenBase:getTransitionProps(id)
  local props <const> = {
    duration = 250,
    easing = playdate.easingFunctions.linear
  }
  return props
end

function ScreenBase:beforeEnter()
end

function ScreenBase:transitionEnter(t, prevId)
  if t >= 0.5 then
    self:update()
    gfxUtils:drawWhiteFade((t - 0.5) * 2)
  end
end

function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:transitionLeave(t, newId)
  if t < 0.5 then
    self:update()
    gfxUtils:drawWhiteFade(1 - t * 2)
  end
end

function ScreenBase:afterLeave()
end

function ScreenBase:update()
  
end
