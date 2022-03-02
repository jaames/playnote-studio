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
local SWATCH_SIZE <const> = 46
-- mask size needs to be multiple of 32 to avoid graphical glitches
-- https://devforum.play.date/t/graphical-glitch-with-setstencilimage/2097
local MASK_SIZE <const> = 64
local MASK_OFFSET <const> = (MASK_SIZE - SWATCH_SIZE) / 2

DitherSwatch = {}
class('DitherSwatch').extends(ComponentBase)

function DitherSwatch:init(x, y)
  DitherSwatch.super.init(self, x, y, SWATCH_SIZE, SWATCH_SIZE)
  self.selectable = true

  self.pattern = 3
  self.isSelected = false
  self.isTransitionActive = false
  self.bitmap = gfx.image.new(MASK_SIZE, MASK_SIZE, gfx.kColorClear)
  self.mask = gfx.image.new(MASK_SIZE, MASK_SIZE, gfx.kColorBlack)
  gfx.pushContext(self.mask)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillCircleInRect(MASK_OFFSET, MASK_OFFSET, SWATCH_SIZE, SWATCH_SIZE)
  gfx.popContext()

  self:setCenter(0.5, 0.5)
end

function DitherSwatch:click()
  self:switchPattern()
  self.clickCallback(self)
end

function DitherSwatch:draw()
  local w = self.width
  local h = self.height
  self.bitmap:draw(-MASK_OFFSET, -MASK_OFFSET)
  if self.isSelected then
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(2)
    gfx.drawCircleInRect(4, 4, w - 8, h - 8)
    gfx.setLineWidth(3)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleInRect(1, 1, w - 2, h - 2)
  else
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(2)
    gfx.drawCircleInRect(3, 3, w - 6, h - 6)
    gfx.setLineWidth(2)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleInRect(1, 1, w - 2, h - 2)
  end
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
  local transitionTimer = playdate.timer.new(200, 0, self.height, playdate.easingFunctions.outCubic)

  transitionTimer.updateCallback = function (timer)
    self:updateBitmap(nextPattern, lastPattern, timer.value)
  end
  transitionTimer.timerEndedCallback = function ()
    self:updateBitmap(nextPattern, lastPattern, self.height)
    self.isTransitionActive = false
  end
end

function DitherSwatch:updateBitmap(newPattern, lastPattern, y)
  local w = self.width
  local h = self.height
  gfx.pushContext(self.bitmap)
  gfx.clear(gfx.kColorClear)
  gfx.setStencilImage(self.mask)
  if lastPattern == nil then
    gfx.setPattern(PATTERNS[newPattern])
    gfx.fillCircleInRect(MASK_OFFSET, MASK_OFFSET, w, h)
  else
    gfx.setPattern(PATTERNS[lastPattern])
    gfx.fillCircleInRect(MASK_OFFSET, MASK_OFFSET, w, h)
    gfx.setPattern(PATTERNS[newPattern])
    gfx.fillCircleInRect(MASK_OFFSET, MASK_OFFSET + h-y, w, h)
  end
  gfx.popContext()
  self:markDirty()
end