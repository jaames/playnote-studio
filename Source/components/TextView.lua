TextView = {}
class('TextView').extends(ComponentBase)

function TextView:init(x, y, w)
  TextView.super.init(self, x, y, w, 1)
  self.text = ''
  self.cache = nil
  self.padding = 10
end

function TextView:addedToScreen()
  self:updateCacheBitmap()
end

function TextView:removedFromScreen()
  self.cache = nil
end

function TextView:setText(text)
  self.cache = nil
  self.text = text
  self:updateCacheBitmap()
end

function TextView:updateCacheBitmap()
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = MAIN_FONT,
    [gfx.font.kVariantBold] = gfx.font.new('./fonts/Asheville-Rounded-24-px'),
    [gfx.font.kVariantItalic] = gfx.getSystemFont(gfx.font.kVariantNormal)
  })
  local text = self.text
  local w = self.width
  local pad = self.padding
  local _, h = gfx.getTextSizeForMaxWidth(text, w - pad * 2)
  self:setSize(w, h)
  local cache = gfx.image.new(w, h, gfx.kColorClear)
  local rect = playdate.geometry.rect.new(pad, pad, w - pad * 2, h - pad * 2)
  gfx.pushContext(cache)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(text, rect, nil, nil, kTextAlignment.center)
  gfx.setImageDrawMode(0)
  gfx.popContext()
  gfx.setFontFamily({
    [gfx.font.kVariantNormal] = MAIN_FONT,
    [gfx.font.kVariantBold] = MAIN_FONT,
    [gfx.font.kVariantItalic] = MAIN_FONT
  })
  self.cache = cache
  self:markDirty()
end

function TextView:draw()
  if self.cache then
    self.cache:draw(0, 0)
  end
end
