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
  self.isTransitionActive = false
  self.bitmap = gfx.image.new(w, h, gfx.kColorClear)
  self.mask = gfx.image.new(w, h, gfx.kColorBlack)
  gfx.pushContext(self.mask)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillCircleInRect(0, 0, w, h)
  gfx.popContext()
end

function DitherSwatch:draw()
  local x = self.x
  local y = self.y
  local w = self.w
  local h = self.h
  local offsetX, offsetY = gfx.getDrawOffset()
  gfx.setDrawOffset(x, y)
  if self.isSelected then
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleInRect(-3, -3, w + 6, h + 6)
  else
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleInRect(-2, -2, w + 4, h + 4)
  end
  self.bitmap:draw(0, 0)
  gfx.setColor(gfx.kColorWhite)
  gfx.setLineWidth(2)
  gfx.drawCircleInRect(1, 1, w - 2, h - 2)
  gfx.setDrawOffset(offsetX, offsetY)
end

function DitherSwatch:setPattern(pattern)
  self.pattern = math.max(1, math.min(pattern, #PATTERNS))
  self:updateBitmap(self.pattern)
end

function DitherSwatch:switchPattern()
  if self.isTransitionActive then return end

  local lastPattern = self.pattern
  local n = (self.pattern - 1) % #PATTERNS
  local nextPattern = n == 0 and #PATTERNS or n
  
  self.pattern = nextPattern
  self.isTransitionActive = true
  local transitionTimer = playdate.timer.new(200, 0, self.h, playdate.easingFunctions.outCubic)

  transitionTimer.updateCallback = function (timer)
    self:updateBitmap(nextPattern, lastPattern, timer.value)
  end
  transitionTimer.timerEndedCallback = function ()
    self:updateBitmap(nextPattern, lastPattern, self.h)
    self.isTransitionActive = false
  end
end

function DitherSwatch:updateBitmap(newPattern, lastPattern, y)
  local w = self.w
  local h = self.h
  gfx.pushContext(self.bitmap)
  gfx.clear(gfx.kColorClear)
  gfx.setStencilImage(self.mask)
  if lastPattern == nil then
    gfx.setPattern(PATTERNS[newPattern])
    gfx.fillCircleInRect(0, 0, w, h)
  else
    gfx.setPattern(PATTERNS[lastPattern])
    gfx.fillCircleInRect(0, 0, w, h)
    gfx.setPattern(PATTERNS[newPattern])
    gfx.fillCircleInRect(0, h-y, w, h)
  end
  gfx.popContext()
end