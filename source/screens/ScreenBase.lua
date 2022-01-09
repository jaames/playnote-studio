ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.id = nil
  self.inputHandlers = {}
end

function ScreenBase:beforeEnter(...)
end

function ScreenBase:afterEnter()
  local inputHandlers = self.inputHandlers
  if inputHandlers.BButtonDown == nil then
    inputHandlers.BButtonDown = function ()
      screens:pop()
    end
  end
  playdate.inputHandlers.push(inputHandlers, true)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:afterLeave()
end

function ScreenBase:setupMenuItems(systemMenu)
  return {}
end

function ScreenBase:update()
end
