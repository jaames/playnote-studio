local gfx <const> = playdate.graphics
local shape_scrollBar <const> = gfx.nineSlice.new('./gfx/shape_scrollbar', 6, 6, 2, 2)
local ui_scrollHandle <const> = gfx.image.new('./gfx/gfx_scrollhandle')

local BAR_W <const> = 14
local HANDLE_W <const> = 16
local HANDLE_R <const> = HANDLE_W / 2
local HANDLE_PAD <const> = 6

Scrollbar = {}
class('Scrollbar').extends()

function Scrollbar:init(x, y, h)
  Scrollbar.super.init(self)
  self.x = x
  self.y = y
  self.w = BAR_W
  self.h = h
  self.trackX = x + (BAR_W / 2)
  self.trackY = y + HANDLE_PAD
  self.trackH = h - HANDLE_PAD * 2
  self.progress = 0
end

function Scrollbar:draw()
  shape_scrollBar:drawInRect(self.x, self.y, self.w, self.h)
  ui_scrollHandle:draw(self.trackX - HANDLE_R, (self.trackY + self.progress * self.trackH) - HANDLE_R)
end
