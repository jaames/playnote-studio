local gfx <const> = playdate.graphics
local fontBold <const> = gfx.font.new('./fonts/WhalesharkSans')

Button = {}
class('Button').extends()

function Button:init(x, y, w, h)
  Button.super.init(self)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.isBold = true
  self.isSelected = false
  self.text = nil
  self.textY = nil
  self.icon = nil
  self:setText('')
end

function Button:setText(text)
  gfx.setFont(fontBold)
  gfx.setFontTracking(2)
  local y = self.y
  local h = self.h
  local _, textH = gfx.getTextSize(text)
  local textY = (h / 2) - (textH / 2)
  self.text = text
  self.textY = textY + 1
end

function Button:setIcon(icon)
  self.icon = icon
end

function Button:draw()
  self:drawAt(self.x, self.y)
end

function Button:drawAt(x, y)
  local w = self.w
  local h = self.h
  local textX = x
  local textW = w
  -- draw background
  gfx.setColor(gfx.kColorBlack)
  if self.isSelected then
    gfx.fillRoundRect(x - 3, y - 3, w + 6, h + 6, 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(1)
    gfx.drawRoundRect(x - 1, y - 1, w + 2, h + 2, 3)
  else
    gfx.fillRoundRect(x, y, w, h, 3)
  end
  -- draw icon if present
  if self.icon then
    local pad = 12
    local gap = 16
    local iconW, _ = self.icon:getSize()
    textX = textX + iconW + gap
    textW = textW - (iconW + gap + pad)
    self.icon:drawAnchored(x + pad, y + (h / 2), 0, 0.5)
  end
  -- draw text if present
  if self.text then
    gfx.setFont(fontBold)
    gfx.setFontTracking(2)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextInRect(self.text, textX, y + self.textY, textW, h, nil, nil, kTextAlignment.center)
    gfx.setImageDrawMode(0)
  end
end
