local shape_scrollBar <const> = gfx.nineSlice.new('./gfx/shape_timeline', 8, 8, 2, 2)
local ui_scrollHandle <const> = gfx.image.new('./gfx/gfx_timelinehandle')

local BAR_H <const> = 18
local HANDLE_W <const> = 8
local HANDLE_H <const> = 14
local HANDLE_PAD <const> = 5

Timeline = {}
class('Timeline').extends(ComponentBase)

function Timeline:init(x, y, w, h)
  Timeline.super.init(self, x, y, w, BAR_H)
  self.trackX = HANDLE_PAD
  self.trackY = (BAR_H / 2)
  self.trackW = w - HANDLE_PAD * 2
  self.progress = 0
end

function Timeline:setProgress(progress)
  self.progress = progress
  self:markDirty()
end

function Timeline:draw()
  shape_scrollBar:drawInRect(0, 0, self.width, self.height)
  ui_scrollHandle:draw((self.trackX + self.progress * self.trackW) - HANDLE_W / 2, self.trackY - HANDLE_H / 2)
end
