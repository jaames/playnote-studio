local shape_scrollBar <const> = gfx.nineSlice.new('./gfx/shape_scrollbar', 6, 6, 2, 2)
local ui_scrollHandle <const> = gfx.image.new('./gfx/gfx_scrollhandle')

local BAR_W <const> = 14
local HANDLE_W <const> = 16
local HANDLE_R <const> = HANDLE_W / 2
local HANDLE_PAD <const> = 6

ScrollBar = {}
class('ScrollBar').extends(ComponentBase)

function ScrollBar:init(x, y, h)
  ScrollBar.super.init(self, x, y, HANDLE_W, h)
  self.progress = 0
  self.trackX = (BAR_W / 2)
  self.trackY = HANDLE_PAD + 2
  self.trackH = h - HANDLE_PAD * 2 - 4
  self:setIgnoresDrawOffset(true)
end

function ScrollBar:setProgress(p)
  self.progress = p
  self:markDirty()
end

function ScrollBar:draw()
  local w, h = self.width, self.height
  -- gfx.setClipRect(-4, -4, w + 8, h + 8)
  shape_scrollBar:drawInRect(1, 1, BAR_W, h - 2)
  ui_scrollHandle:draw(self.trackX - HANDLE_R + 1, (self.trackY + self.progress * self.trackH) - HANDLE_R)
end