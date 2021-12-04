local gfx <const> = playdate.graphics

Timeline = {}
class('Timeline').extends()

function Timeline:init(x, y, w, h)
  Timeline.super.init(self)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.trackX = x + 8
  self.trackY = y + (h / 2) - 1
  self.trackW = w - 16
  self.trackH = 4
  self.progress = 0
end

function Timeline:draw()
  local x = self.x
  local y = self.y
  local w = self.w
  local h = self.h
  local trackX = self.trackX
  local trackY = self.trackY
  local trackW = self.trackW
  local trackH = self.trackH
  local pos = self.progress * trackW
  -- rail
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(x, y, w, h, 4)
  gfx.setColor(gfx.kColorBlack)
  gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
  gfx.setLineWidth(2)
  gfx.drawRoundRect(trackX, trackY, trackW, trackH, 3)
  -- handle
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect((trackX + pos) - 2, trackY - 3, 5, trackH + 6, 3)
  gfx.setColor(gfx.kColorBlack)
  gfx.drawRoundRect((trackX + pos) - 2, trackY - 3, 5, trackH + 6, 3)
end
