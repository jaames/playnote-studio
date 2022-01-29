ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.id = nil
  self.active = false
  self.inputHandlers = {}
  self.sprites = {}
  self.spritesSetup = false
  self.spritesActive = false
  self.spritesVisible = true
  self.selectableSprites = {}
  self.hooks = {}
end

-- called at the very beginning of a transition, where this screen is being transitioned to
function ScreenBase:beforeEnter(...)
  if self.spritesSetup == false then
    local sprites = self:setupSprites()
    for i = 1, #sprites do
      self:addSprite(sprites[i])
    end
    self:setSpritesVisible(false)
    self.spritesSetup = true
    self:emitHook('sprites:setup')
  end
  self:registerSprites()
  -- self:update()
  self:emitHook('enter:before')
end

-- called somewhere during a transition, on the first frame that this screen has become visible
function ScreenBase:enter()
  self.active = true
  gfx.setDrawOffset(0, 0)
  self:setSpritesVisible(true)
  self:emitHook('enter')
end

-- called at the very end of a transition, where this screen is being transitioned to
function ScreenBase:afterEnter()
  playdate.inputHandlers.push(self.inputHandlers, true)
  self:emitHook('enter:after')
end

-- called at the very beginning of a transition, where this screen is being transitioned from
function ScreenBase:beforeLeave()
  playdate.inputHandlers.pop()
  self:emitHook('leave:before')
end

-- called somewhere during a transition, on the first frame that this screen has become invisible
function ScreenBase:leave()
  self.active = false
  self:setSpritesVisible(false)
  self:emitHook('leave')
end

-- called at the very end of a transition, where this screen is being transitioned from
function ScreenBase:afterLeave()
  self:unregisterSprites()
  self:emitHook('leave:after')
end

-- register a table of menu items to pass to the system menu
function ScreenBase:setupMenuItems(systemMenu)
  return {}
end

-- register a table of sprites to be used on this screen
function ScreenBase:setupSprites()
  return {}
end

-- add a sprite to this screen
function ScreenBase:addSprite(sprite)
  table.insert(self.sprites, sprite)
  if sprite.selectable then
    table.insert(self.selectableSprites, sprite)
  end
  if self.spritesActive then
    sprite:add()
  end
  self:emitHook('sprite:add')
end

-- remove a sprite from this screen
function ScreenBase:removeSprite(sprite)
  table.remove(self.sprites, table.indexOfElement(self.sprites, sprite))
  if sprite.selectable then
    table.remove(self.selectableSprites, table.indexOfElement(self.selectableSprites, sprite))
  end
  if self.spritesActive then
    sprite:remove()
  end
  self:emitHook('sprite:remove')
end

-- hide/unhide all of this screen's sprites at once
function ScreenBase:setSpritesVisible(visible)
  for i = 1, #self.sprites do
    self.sprites[i]:setVisible(visible)
  end
  self.spritesVisible = visible
  self:emitHook('sprites:setvisible')
end

-- force all of this screen's sprites to be updated
function ScreenBase:forceSpriteUpdate()
  for i = 1, #self.sprites do
    self.sprites[i]:markDirty()
    self.sprites[i]:update()
  end
end

-- override to draw a custom background for this screen
function ScreenBase:drawBg(x, y, w, h)
end

-- override to do something on every frame for this screen while it is active
function ScreenBase:update()
end

-- (internal) add this screen's sprites to the sprite library scenegraph
function ScreenBase:registerSprites()
  if self.spritesActive == false then
    for i = 1, #self.sprites do
      self.sprites[i]:add()
    end
  end
  self.spritesActive = true
  self:emitHook('sprites:registered')
end

-- (internal) remove this screen's sprites from the sprite library scenegraph
function ScreenBase:unregisterSprites()
  if self.spritesActive == true then
    for i = 1, #self.sprites do
      self.sprites[i]:remove()
    end
  end
  self.spritesActive = false
  self:emitHook('sprites:unregistered')
end

function ScreenBase:addHook(hook, fn)
  assert(type(hook) == 'string')
  assert(type(fn) == 'function')
  if self.hooks[hook] == nil then
    self.hooks[hook] = {}
  end
  table.insert(self.hooks[hook], fn)
end

function ScreenBase:emitHook(hook, ...)
  local hookFns = self.hooks[hook]
  if type(hookFns) == 'table' then
    for i = 1, #hookFns do
      hookFns[i](...)
    end
  end
end