ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.id = nil
  self.active = false
  self.inputHandlers = {}
  self.components = nil
  self.componentsVisible = true
end

function ScreenBase:beforeEnter(...)
  if self.components == nil then
    self.components = self:setupComponents()
    self:setComponentsVisible(false)
  end
  self:addComponents()
  self:update()
end

function ScreenBase:enter()
  self.active = true
  gfx.setDrawOffset(0, 0)
  self:setComponentsVisible(true)
end

function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers, true)
end

function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
end

function ScreenBase:leave()
  self.active = false
  self:setComponentsVisible(false)
end

function ScreenBase:afterLeave()
  self:removeComponents()
end

function ScreenBase:setupMenuItems(systemMenu)
  return {}
end

function ScreenBase:setupComponents()
  return {}
end

function ScreenBase:addComponents()
  for _, component in pairs(self.components) do
    component:add()
  end
end

function ScreenBase:removeComponents()
  for _, component in pairs(self.components) do
    component:remove()
  end
end

function ScreenBase:setComponentsVisible(visible)
  for _, component in pairs(self.components) do
    component:setVisible(visible)
  end
  self.componentsVisible = visible
end

function ScreenBase:forceComponentUpdate()
  for _, component in pairs(self.components) do
    component:markDirty()
    component:update()
  end
end

function ScreenBase:drawBg(x, y, w, h)
end

function ScreenBase:update()
end