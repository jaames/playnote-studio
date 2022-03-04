local counterFont <const> = gfx.font.new('./fonts/WhalesharkCounter')

Counter = {}
class('Counter').extends(ComponentBase)

function Counter:init(x, y)
  Counter.super.init(self, x, y, 1, 24)
  self.padding = 9
  self.centerPad = 6
  self.value = 0
  self.total = 0
  self:setWidthForNumDigits(2)
end

function Counter:setWidthForNumDigits(numDigits)
  local measureStr = string.rep('0', numDigits) .. '/' .. string.rep('0', numDigits)
  local w = gfx.getTextSize(measureStr) + self.padding * 2 + 12
  self:setSize(w, self.height)
end

function Counter:setValue(value)
  self.value = value
  self:markDirty()
end

function Counter:setTotal(total)
  self.total = total
  local totalStr = tostring(total)
  self:setWidthForNumDigits(#totalStr)
  self:markDirty()
end

function Counter:draw()
  local w = self.width
  local h = self.height
  local mid = w / 2
  local pad = self.padding
  local labelSpace = (mid - pad + self.centerPad) / 2
  local valueX = mid - labelSpace
  local totalX = mid + labelSpace
  local textY = (h / 2) - 9
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(0, 0, w, h, 4)
  gfx.setFontTracking(2)
  counterFont:drawTextAligned('/', mid, textY, kTextAlignment.center)
  counterFont:drawTextAligned(self.value, valueX, textY, kTextAlignment.center)
  counterFont:drawTextAligned(self.total, totalX, textY, kTextAlignment.center)
end
