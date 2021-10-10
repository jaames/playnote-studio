import 'CoreLibs/object'
import './noteManager'

class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.inputHandlers = nil
end

function ScreenBase:beforeEnter()
end

function ScreenBase:getTransitionProps(id)
  local props <const> = {
    duration = 250,
    easing = playdate.easingFunctions.linear
  }
  return props
end

function ScreenBase:transitionEnter(t, prevId)
  self:update()
end

function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:transitionLeave(t, newId)
  self:update()
end

function ScreenBase:afterLeave()
end

function ScreenBase:update()
end
