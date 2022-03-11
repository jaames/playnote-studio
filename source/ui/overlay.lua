overlay = spritelib.new()

overlay:setSize(PLAYDATE_W, PLAYDATE_H)
overlay:add()
overlay:setZIndex(900)
overlay:setIgnoresDrawOffset(true)
overlay:setCollisionsEnabled(false)
overlay:setCenter(0, 0)

overlay.whiteLevel = 0
overlay.blackLevel = 0

function overlay:setWhiteFade(white)
  self.whiteLevel = white
  self.blackLevel = 0
  self:markDirty()
end

function overlay:setBlackFade(black)
  self.blackLevel = black
  self.whiteLevel = 0
  self:markDirty()
end

function overlay:draw(x, y, w, h)
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