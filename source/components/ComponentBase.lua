local ALIGN_COORDS <const> = {
  left = 0,
  top = 0,
  center = 0.5,
  right = 1,
  bottom = 1
}

ComponentBase = {}
class('ComponentBase').extends(playdate.graphics.sprite)

function ComponentBase:init(x, y, w, h)
  self.selectable = false
  self.isSelected = false

  self.tx = 0
  self.ty = 0

  self.clickCallback = function (comonent) end

  self:setCenter(0, 0)
  self:setZIndex(100)
  self:setCollisionsEnabled(false)

  if x ~= nil or y ~= nil then
    self:moveTo(x, y)
  end
  if w ~= nil or h ~= nil then
    self:setSize(w, h)
  end
end

function ComponentBase:addedToScreen()
end

function ComponentBase:removedFromScreen()
end

function ComponentBase:add()
  ComponentBase.super.add(self)
  self:addedToScreen()
end

function ComponentBase:remove()
  ComponentBase.super.remove(self)
  self:removedFromScreen()
end

function ComponentBase:setAnchor(x, y)
  if type(x) == 'string' then
    x = ALIGN_COORDS[x]
  end
  if type(y) == 'string' then
    y = ALIGN_COORDS[y]
  end
  self:setCenter(x, y)
end

function ComponentBase:moveTo(x, y)
  ComponentBase.super.moveTo(self, x + self.tx, y + self.ty)
  self.bx = x
  self.by = y
end

function ComponentBase:moveToX(x)
  self:moveTo(x, self.y)
end

function ComponentBase:moveToY(y)
  self:moveTo(self.x, y)
end

function ComponentBase:offsetBy(x, y)
  ComponentBase.super.moveTo(self, self.bx + x, self.by + y)
  self.tx = x
  self.ty = y
end

function ComponentBase:offsetByY(y)
  ComponentBase.super.moveTo(self, self.bx, self.by + y)
  self.ty = y
end

function ComponentBase:offsetByX(x)
  ComponentBase.super.moveTo(self, self.bx + x, self.by)
  self.tx = x
end

function ComponentBase:focus()
  if self.selectable then
    self.isSelected = true
    self:markDirty()
  end
end

function ComponentBase:unfocus()
  if self.selectable then
    self.isSelected = false
    self:markDirty()
  end
end

function ComponentBase:onClick(fn)
  assert(self.selectable, 'component is not selectable')
  assert(type(fn) == 'function', 'callback must be a function')
  self.clickCallback = fn
end

function ComponentBase:click()
  if self.selectable then
    self.clickCallback(self)
  end
end