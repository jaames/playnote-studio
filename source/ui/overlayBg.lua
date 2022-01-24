overlayBg = spritelib.new()

overlayBg:setSize(PLAYDATE_W, PLAYDATE_H)
overlayBg:add()
overlayBg:setZIndex(900)
overlayBg:setIgnoresDrawOffset(true)
overlayBg:setCenter(0, 0)

overlayBg.fadeWhite = 1
overlayBg.fadeBlack = 1

function overlayBg:setWhiteFade(white)
  self.fadeWhite = white
  self.fadeBlack = 1
  self:markDirty()
end

function overlayBg:setBlackFade(black)
  self.fadeBlack = black
  self.fadeWhite = 1
  self:markDirty()
end

function overlayBg:draw(x, y, w, h)
  -- if self.fadeWhite ~= 1 then
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(self.fadeWhite, gfx.image.kDitherTypeBayer8x8)
    gfx.fillRect(x, y, w, h)
  -- elseif self.fadeBlack ~= 1 then
  --   gfx.setColor(gfx.kColorBlack)
  --   gfx.setDitherPattern(self.fadeBlack, gfx.image.kDitherTypeBayer8x8)
  --   gfx.fillRect(x, y, w, h)
  -- end
end