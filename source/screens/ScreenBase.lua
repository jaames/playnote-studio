import 'CoreLibs/object'

ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.inputHandlers = {}
end

function ScreenBase:beforeEnter()
end

function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:afterLeave()
end

function ScreenBase:update()
end
