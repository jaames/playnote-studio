TextView = {}
class('TextView').extends(ComponentBase)

function TextView:init(x, y, w, h)
  TextView.super.init(self, x-1, y-1, w, h)
end

function TextView:addedToScreen()
  self.isRunning = true
  self:tick()
end

function TextView:removedFromScreen()
  self.isRunning = false
end

function TextView:draw()
  local w = self.width
  local h = self.height
  gfx.setFontTracking(1)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, w, h)
  font:drawText(self.dateString, 10, 10)
  clockGfx:draw(92, 8)
  font:drawText(self.timeString, 108, 10)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(1)
  gfx.drawRect(1, 1, w-1, h-1)
end
