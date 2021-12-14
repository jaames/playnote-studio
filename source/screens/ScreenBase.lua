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
  local inputHandlers = self.inputHandlers
  if inputHandlers.BButtonDown == nil then
    inputHandlers.BButtonDown = function ()
      screens:goBack()
    end
  end
  playdate.inputHandlers.push(inputHandlers, true)
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
