ScreenBase = {}
class('ScreenBase').extends()

function ScreenBase:init()
  ScreenBase.super.init(self)
  self.id = nil
  self.active = false
  self.inputHandlers = {}
  self.sprites = {}
  self.selectableSprites = {}
  self.areSpritesSetup = false
  self.areSpritesInDisplayList = false
  self.areSpritesVisible = false
  self.drawOffsetX = 0
  self.drawOffsetY = 0
  self.hooks = {}
end

-- (internal) add this screen's sprites to the sprite library scenegraph
function ScreenBase:_addToDisplayList()
  if not self.areSpritesInDisplayList then
    local sprites = self.sprites
    for i = 1, #sprites do
      sprites[i]:add()
    end
    self.areSpritesInDisplayList = true
  end
  self:emitHook('sprites:display:add')
end

-- (internal) remove this screen's sprites from the sprite library scenegraph
function ScreenBase:_removeFromDisplayList()
  if self.areSpritesInDisplayList then
    local sprites = self.sprites
    for i = 1, #sprites do
      sprites[i]:remove()
    end
    self.areSpritesInDisplayList = false
  end
  self:emitHook('sprites:display:remove')
end

-- override to do something on every frame for this screen while it is active
function ScreenBase:update()
end

-- override to do something on every frame for this screen while it is being transitioned in
-- t is the transition progress from 0 to 1
function ScreenBase:updateTransitionIn(t)
end

-- override to do something on every frame for this screen while it is being transitioned out
-- t is the transition progress from 0 to 1
function ScreenBase:updateTransitionOut(t)
end

-- override to draw a custom background for this screen
function ScreenBase:drawBg(x, y, w, h)
end

-- override to register a table of sprites to be used on this screen
function ScreenBase:setupSprites()
  return {}
end

-- override to register a table of menu items to pass to the system menu
function ScreenBase:setupMenuItems(systemMenu)
  return {}
end

-- called at the very beginning of a transition, where this screen is being transitioned to
function ScreenBase:beforeEnter(...)
end

-- called somewhere during a transition, on the first frame that this screen has become visible
function ScreenBase:enter()
end

-- called at the very end of a transition, where this screen is being transitioned to
function ScreenBase:afterEnter()
end

-- called at the very beginning of a transition, where this screen is being transitioned from
function ScreenBase:beforeLeave()
end

-- called somewhere during a transition, on the first frame that this screen has become invisible
function ScreenBase:leave()
end

-- called at the very end of a transition, where this screen is being transitioned from
function ScreenBase:afterLeave()
end

-- set draw offset for this scene
function ScreenBase:setDrawOffset(x, y)
  local hasChanged = x ~= self.drawOffsetX or y ~= self.drawOffsetY
  if hasChanged then
    self.drawOffsetX = x
    self.drawOffsetY = y
    if self.active then
      gfx.setDrawOffset(x, y)
      spritelib.redrawBackground()
    end
  end
end

-- get draw offset for this scene
function ScreenBase:getDrawOffset()
  return self.drawOffsetX, self.drawOffsetY
end

function ScreenBase:forceDrawOffset()
  gfx.setDrawOffset(self.drawOffsetX, self.drawOffsetY)
  spritelib.redrawBackground()
end

-- add a sprite to this scene
function ScreenBase:addSprite(sprite)
  table.insert(self.sprites, sprite)
  if sprite.selectable then
    table.insert(self.selectableSprites, sprite)
  end
  if self.areSpritesInDisplayList then
    sprite:add()
  end
  sprite:setVisible(self.areSpritesVisible)
  self:emitHook('sprite:add', sprite)
end

-- remove a sprite from this scene
function ScreenBase:removeSprite(sprite)
  table.remove(self.sprites, table.indexOfElement(self.sprites, sprite))
  if sprite.selectable then
    table.remove(self.selectableSprites, table.indexOfElement(self.selectableSprites, sprite))
  end
  if self.areSpritesInDisplayList then
    sprite:remove()
  end
  self:emitHook('sprite:remove', sprite)
end

-- hide/unhide all of this screen's sprites at once
function ScreenBase:setSpritesVisible(visible)
  local sprites = self.sprites
  for i = 1, #sprites do
    sprites[i]:setVisible(visible)
  end
  self.areSpritesVisible = visible
  self:emitHook('sprites:setvisible', visible)
end

-- force all of this screen's sprites to be updated
function ScreenBase:forceSpriteUpdate()
  local sprites = self.sprites
  if self.areSpritesInDisplayList then
    for i = 1, #sprites do
      sprites[i]:markDirty()
      sprites[i]:update()
    end
  end
  self:emitHook('sprites:update')
end

-- reload all the sprites in the screen
function ScreenBase:reloadSprites()
  local sprites = self.sprites
  if self.areSpritesInDisplayList then
    for i = 1, #sprites do
      sprites[i]:remove()
      sprites[i]:add()
    end
  end
  self:emitHook('sprites:reload')
end
-- returns the number of sprites in this screen
-- equiv to playdate.graphics.sprite.spriteCount()
function ScreenBase:spriteCount()
  return #self.sprites
end

-- performs the function fn on all sprites in the screen. fn should take one argument, which will be a sprite
-- equiv to playdate.graphics.sprite.performOnAllSprites()
function ScreenBase:performOnAllSprites(fn)
  local sprites = self.sprites
  for i = 1, #sprites do
    fn(sprites[i])
  end
end

-- destroy sprites
function ScreenBase:destroySprites()
  local sprites = self.sprites
  for i = 1, #self.sprites do
    sprites[i]:remove()
    sprites[i] = nil
  end
  local sprites = self.selectableSprites
  for i = 1, #self.sprites do
    sprites[i] = nil
  end
  self.sprites = {}
  self.selectableSprites = {}
  self.areSpritesInDisplayList = false
  self.areSpritesSetup = false
  self.areSpritesVisible = false
  self:emitHook('sprites:destroy')
end

function ScreenBase:addHook(hook, fn)
  assert(type(hook) == 'string')
  assert(type(fn) == 'function')
  local hooks = self.hooks
  if hooks[hook] == nil then
    hooks[hook] = {}
  end
  table.insert(hooks[hook], fn)
end

function ScreenBase:emitHook(hook, ...)
  local hookFns = self.hooks[hook]
  if type(hookFns) == 'table' then
    for i = 1, #hookFns do
      hookFns[i](...)
    end
  end
end