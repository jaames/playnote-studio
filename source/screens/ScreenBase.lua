ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.id = nil
  self.inputHandlers = {}
end

function ScreenBase:beforeEnter()
end

function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers, true)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:afterLeave()
end

function ScreenBase:reload()
  self:afterLeave()
  self:beforeEnter()
end

function ScreenBase:update()
end
