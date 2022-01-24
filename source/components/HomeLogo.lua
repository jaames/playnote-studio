local logoGfx <const> = gfx.imagetable.new('./gfx/gfx_logo_anim')

HomeLogo = {}
class('HomeLogo').extends(playdate.graphics.sprite)

function HomeLogo:init(x, y)
  local img = logoGfx:getImage(1)
  local w, h = img:getSize()
  self:moveTo(x, y)
  self:setSize(w, h)
  self:setCenter(0, 0)
  self:setZIndex(100)
  self.framerate = 1000 / 4
  self.anim = gfx.animation.loop.new(self.framerate, logoGfx)
  self:tick()
end

function HomeLogo:tick()
  self:markDirty()
  playdate.timer.performAfterDelay(self.framerate, self.tick, self)
end

function HomeLogo:draw()
  self.anim:draw(0, 0)
end