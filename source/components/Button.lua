local gfx <const> = playdate.graphics
local newNineSlice = gfx.nineSlice.new

local buttonGfx = {
  default = {
    base =   gfx.nineSlice.new('./gfx/shape_button_default', 8, 8, 2, 2),
    select = gfx.nineSlice.new('./gfx/shape_button_default_selected', 8, 8, 2, 2),
    click =  gfx.nineSlice.new('./gfx/shape_button_default_clicked', 8, 8, 2, 2)
  },
  folderselect = {
    base =   gfx.nineSlice.new('./gfx/shape_button_folderselect', 8, 8, 2, 2),
    select = gfx.nineSlice.new('./gfx/shape_button_folderselect_selected', 8, 8, 2, 2),
    click =  gfx.nineSlice.new('./gfx/shape_button_folderselect_clicked', 8, 8, 2, 2)
  },
  -- settings = {
  --   base =   gfx.nineSlice.new('./gfx/shape_button_settings', 8, 8, 2, 2),
  --   select = gfx.nineSlice.new('./gfx/shape_button_settings_selected', 8, 8, 2, 2),
  --   click =  gfx.nineSlice.new('./gfx/shape_button_settings_clicked', 8, 8, 2, 2)
  -- },
}

Button = {}
class('Button').extends()

function Button:init(x, y, w, h)
  Button.super.init(self)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.variant = 'default'
  self.state = 'base'
  self.isSelected = false
  self.text = nil
  self.textY = nil
  self.icon = nil
  self.iconW = nil
  self:setText('')
end

function Button:setText(text)
  gfx.setFontTracking(2)
  local y = self.y
  local h = self.h
  local _, textH = gfx.getTextSize(text)
  local textY = (h / 2) - (textH / 2)
  self.text = text
  self.textY = textY
end

function Button:setIcon(icon)
  local iconW, _ = icon:getSize()
  self.icon = icon
  self.iconW = iconW
end

function Button:select()
  self.state = 'select'
  self.isSelected = true
end

function Button:deselect()
  self.state = 'base'
  self.isSelected = false
end

function Button:click()
  local s = self
  self.state = 'click'
  playdate.timer.performAfterDelay(150, function () s.state = 'base' end)
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
  buttonGfx[self.variant][self.state]:drawInRect(x - 3, y - 3, w + 6, h + 6)
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
