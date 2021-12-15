local gfx <const> = playdate.graphics
local fontBold <const> = gfx.font.new('./fonts/WhalesharkSans')
local buttonGfx <const> = gfx.nineSlice.new('./img/button_new', 8, 8, 2, 2)
local buttonSelectedGfx <const> = gfx.nineSlice.new('./img/button_new_selected', 8, 8, 2, 2)

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
  self.iconW = nil
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
  local iconW, _ = icon:getSize()
  self.icon = icon
  self.iconW = iconW
end

function Button:draw()
  self:drawAt(self.x, self.y)
end

function Button:drawAt(x, y)
  local w = self.w
  local h = self.h
  local textX = x + 6
  local textW = w - 12
  -- draw background
  if self.isSelected then
    buttonSelectedGfx:drawInRect(x - 3, y - 3, w + 6, h + 6)
  else
    buttonGfx:drawInRect(x - 3, y - 3, w + 6, h + 6)
  end
  -- gfx.setColor(gfx.kColorBlack)
  -- if self.isSelected then
  --   gfx.fillRoundRect(x - 3, y - 3, w + 6, h + 6, 4)
  --   gfx.setColor(gfx.kColorWhite)
  --   gfx.setLineWidth(1)
  --   gfx.drawRoundRect(x - 1, y - 1, w + 2, h + 2, 3)
  -- else
  --   gfx.fillRoundRect(x, y, w, h, 3)
  -- end
  -- draw icon if present
  if self.icon then
    local pad = 12
    local gap = 16
    textX = textX + self.iconW + gap
    textW = textW - (self.iconW + gap + pad)
    self.icon:drawAnchored(x + pad, y + (h / 2), 0, 0.5)
  end
  -- draw text if present
  if self.text then
    gfx.setFont(fontBold)
    gfx.setFontTracking(2)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextInRect(self.text, textX, y + self.textY, textW, h, nil, '...', kTextAlignment.center)
    gfx.setImageDrawMode(0)
  end
end
