Image = {}
class('Image').extends(ComponentBase)

function Image:init(x, y, source, h)
  Image.super.init(self, x, y, 1, 1)
  -- source as file path
  if type(source) == 'string' then
    self:setPath(source)
  -- treat source as width and fourth param as height
  elseif type(source) == 'number' and type(h) == 'number' then
    self:makeBlankImage(source, h)
  -- source as image
  elseif getmetatable(source) == playdate.graphics.image then
    self:setImage(source)
  end
end

function Image:setPath(path)
  local w, h = gfx.imageSizeAtPath(path)
  local hasImage = self.image ~= nil
  self.path = path
  self.image = nil
  if hasImage then -- already loaded and onscreen
    self.image = gfx.image.new(path)
  end
  self:setSize(w, h)
end

function Image:setImage(img)
  self.image = nil
  local w, h = img:getSize()
  self.path = nil
  self.image = img
  self:setSize(w, h)
end

function Image:makeBlankImage(w, h)
  self.path = nil
  self.image = gfx.image.new(w, h)
  self:setSize(w, h)
end

function Image:addedToScreen()
  if self.path and not self.image then
    self.image = gfx.image.new(self.path)
  end
end

function Image:removedFromScreen()
  if self.path and self.image then
    self.image = nil
  end
end

function Image:draw()
  if self.image then
    self.image:draw(0, 0)
  end
end
