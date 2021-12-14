local gfx <const> = playdate.graphics

local PATTERNS <const> = {
  -- none
  {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
  -- inverted polka
  {0xFF, 0x55, 0xFF, 0x55, 0xFF, 0x55, 0xFF, 0x55},
  -- checker
  {0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55},
  -- polka
  {0xAA, 0x00, 0xAA, 0x00, 0xAA, 0x00, 0xAA, 0x00},
}

DitherSwatch = {}
class('DitherSwatch').extends()

function DitherSwatch:init(x, y, w, h)
  DitherSwatch.super.init(self)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.pattern = 3
  self.isSelected = false
end

function DitherSwatch:draw()
  local x = self.x
  local y = self.y
  local w = self.w
  local h = self.h
  if self.isSelected then
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleInRect(x - 4, y - 4, w + 8, h + 8)
  else
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleInRect(x - 2, y - 2, w + 4, h + 4)
  end
  gfx.setColor(gfx.kColorWhite)
  gfx.fillCircleInRect(x, y, w, h)
  gfx.setColor(gfx.kColorBlack)
  gfx.setPattern(PATTERNS[self.pattern])
  gfx.fillCircleInRect(x + 2, y + 2, w - 4, h - 4)
end

function DitherSwatch:switchPattern()
  self.pattern = (self.pattern % #PATTERNS) + 1
end