Image = {}
class('Image').extends(ComponentBase)

function Image:init(x, y, path)
  local w, h = gfx.imageSizeAtPath(path)
  Image.super.init(self, x, y, w, h)
  self.path = path
  self.image = nil
end

function Image:addedToScreen()
  self.image = gfx.image.new(self.path)
end

function Image:removedFromScreen()
  self.image = nil
end

function Image:draw()
  if self.image then
    self.image:draw(0, 0)
  end
end
