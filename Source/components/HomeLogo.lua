local logoGfx <const> = gfx.imagetable.new('./gfx/gfx_logo_anim')

HomeLogo = {}
class('HomeLogo').extends(ComponentBase)

function HomeLogo:init(x, y)
  local img = logoGfx:getImage(1)
  local w, h = img:getSize()
  HomeLogo.super.init(self, x, y, w, h)
  self.framerate = 1000 / 4
  self.anim = gfx.animation.loop.new(self.framerate, logoGfx)
  self.isRunning = false
end

function HomeLogo:tick()
  if self.isRunning then
    self:markDirty()
    playdate.timer.performAfterDelay(self.framerate, self.tick, self)
  end
end

function HomeLogo:addedToScreen()
  self.isRunning = true
  self:tick()
end

function HomeLogo:removedFromScreen()
  self.isRunning = false
end

function HomeLogo:draw()
  self.anim:draw(0, 0)
end