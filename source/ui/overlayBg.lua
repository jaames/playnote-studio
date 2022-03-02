overlayBg = spritelib.new()

overlayBg:setSize(PLAYDATE_W, PLAYDATE_H)
overlayBg:add()
overlayBg:setZIndex(900)
overlayBg:setIgnoresDrawOffset(true)
overlayBg:setCollisionsEnabled(false)
overlayBg:setCenter(0, 0)

overlayBg.whiteLevel = 0
overlayBg.blackLevel = 0

function overlayBg:setWhiteFade(white)
  self.whiteLevel = white
  self.blackLevel = 0
  self:markDirty()
end

function overlayBg:setBlackFade(black)
  self.blackLevel = black
  self.whiteLevel = 0
  self:markDirty()
end

function overlayBg:draw(x, y, w, h)
  if self.whiteLevel ~= 0 then
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(1- self.whiteLevel, gfx.image.kDitherTypeBayer8x8)
    gfx.fillRect(x, y, w, h)
  elseif self.blackLevel ~= 0 then
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(1- self.blackLevel, gfx.image.kDitherTypeBayer8x8)
    gfx.fillRect(x, y, w, h)
  end
end