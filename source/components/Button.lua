local newNineSlice = gfx.nineSlice.new

local buttonGfx = {
  default = {
    base =   newNineSlice('./gfx/shape_button_default', 8, 8, 2, 2),
    select = newNineSlice('./gfx/shape_button_default_selected', 8, 8, 2, 2),
    click =  newNineSlice('./gfx/shape_button_default_clicked', 8, 8, 2, 2)
  },
  folderselect = {
    base =   newNineSlice('./gfx/shape_button_folderselect', 8, 8, 2, 2),
    select = newNineSlice('./gfx/shape_button_folderselect_selected', 8, 8, 2, 2),
    click =  newNineSlice('./gfx/shape_button_folderselect_clicked', 8, 8, 2, 2)
  },
  -- settings = {
  --   base =   gfx.nineSlice.new('./gfx/shape_button_settings', 8, 8, 2, 2),
  --   select = gfx.nineSlice.new('./gfx/shape_button_settings_selected', 8, 8, 2, 2),
  --   click =  gfx.nineSlice.new('./gfx/shape_button_settings_clicked', 8, 8, 2, 2)
  -- },
}

Button = {}
class('Button').extends(ComponentBase)

function Button:init(x, y, w, h, text)
  Button.super.init(self, x, y, w, h)
  self.selectable = true

  self.variant = 'default'
  self.state = 'base'

  self.padLeft = 16
  self.padRight = 16
  self.padTop = 6
  self.padBottom = 6
  self.autoWidth = false
  self.autoHeight = false

  self.prelocaleText = ''
  self.localisedText = nil
  self.textAlign = kTextAlignment.center
  self.textY = 0
  self.textW = 0
  self.textH = 0

  self.icon = nil
  self.iconY = 0
  self.iconW = 0
  self.iconH = 0
  self.iconPadRight = 12

  if text then
    self:setText(text)
  end
end

function Button:focus()
  self.state = 'select'
  Button.super.focus(self)
end

function Button:unfocus()
  self.state = 'base'
  Button.super.unfocus(self)
end

function Button:setText(prelocaleText)
  gfx.setFontTracking(2)
  local text = locales:replaceKeysInText(prelocaleText)
  local textW, textH = gfx.getTextSize(text)
  self.prelocaleText = prelocaleText
  self.localisedText = text
  self.textW = textW
  self.textH = textH
  self:updateLayout()
end

function Button:addedToScreen()
  -- update text when added to screen
  self:setText(self.prelocaleText)
end

function Button:setIcon(imgPath)
  if type(imgPath) ~= 'string' then
    print('tried to load button icon the old way')
    return
  end
  local icon = gfx.image.new(imgPath)
  local iconW, iconH = icon:getSize()
  self.icon = icon
  self.iconW = iconW
  self.iconH = iconH
  self:updateLayout()
end

function Button:updateLayout()
  local w = self.width
  local h = self.height
  if self.autoWidth and self.icon then
    w = self.padLeft + self.iconW + self.iconPadRight + self.textW + self.padRight
  elseif self.autoWidth then
    w = self.padLeft + self.textW + self.padRight
  end
  if self.autoHeight and self.icon then
    h = self.padTop + math.max(self.iconH, self.textH) + self.padBottom
  end
  self.textY = (h / 2) - (self.textH / 2)
  self.iconY = (h / 2) - (self.iconH / 2)
  self:setSize(w, h)
  self:markDirty()
end

function Button:draw(clipX, clipY, clipW, clipH)
  local w = self.width
  local h = self.height
  local textX = self.padLeft
  local textW = self.width - self.padLeft - self.padRight
  -- draw background
  buttonGfx[self.variant][self.state]:drawInRect(0, 0, w, h)
  -- draw icon if present
  if self.icon then
    local iconSpace = self.iconW + self.iconPadRight
    textX = textX + iconSpace
    textW = textW - iconSpace
    self.icon:draw(self.padLeft, self.iconY)
  end
  -- draw text if present
  if self.localisedText then
    -- gfx.setFont(fontBold)
    gfx.setFontTracking(2)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextInRect(self.localisedText, textX, self.textY, textW, self.textH, nil, '...', self.textAlign)
    gfx.setImageDrawMode(0)
  end
end