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
  end
  self:addComponents()
  self:setComponentsVisible(false) -- handle this in the transtition
  self:update()
end

function ScreenBase:enter()
  self.active = true
  gfx.setDrawOffset(0, 0)
  self:setComponentsVisible(true)
  spritelib.redrawBackground()
  
  -- I don't know why, and I don't care, but I've spend hours on a transition bug where the scroll offset on one page will affect another.
  -- Waiting for one frame here is literally the only way to make sure this doesn't happen. Yeah, I don't get it either. Just trust me.
  -- Bug: side effect of this is that components are invisible for one frame of the transition
  -- utils:nextTick(function ()
    -- gfx.setDrawOffset(0, 0)
    -- self:setComponentsVisible(true)
    -- spritelib.redrawBackground()
  -- end)
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