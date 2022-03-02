debugOverlay = {}

debugOverlay.active = false

debugOverlay.showFPS = true

debugOverlay.showPaintFlashing = true
debugOverlay.paintFlashLineWidth = 2
debugOverlay.paintFlashFrameDelay = 15

local rectlib <const> = playdate.geometry.rect

local origDbgDraw = playdate.debugDraw
local origSpriteBg = playdate.debugDraw

local paintRects = {}
local paintRectFrames = {}

function debugOverlay:start()
  origDbgDraw = playdate.debugDraw
  debugOverlay.active = true

  playdate.setDebugDrawColor(255, 0, 40, 0.75)
  playdate.debugDraw = function()
    gfx.setDrawOffset(0,0)
    gfx.setColor(gfx.kColorWhite)
    if self.showFPS then
      playdate.drawFPS(8, PLAYDATE_H - 20)
    end
    if self.showPaintFlashing then
      gfx.setLineWidth(self.paintFlashLineWidth)
      local delay = self.paintFlashFrameDelay
      for i, frame in ipairs(paintRectFrames) do
        if frame < delay then
          gfx.drawRect(paintRects[i])
          paintRectFrames[i] = frame + 1
        else
          table.remove(paintRects, i)
          table.remove(paintRectFrames, i)
        end
      end
    end
  end
end

function debugOverlay:stop()
  playdate.debugDraw = origDbgDraw
  debugOverlay.active = false
end

function debugOverlay:updatePaintRect(x, y, w, h)
  local rect = rectlib.new(x, y, w, h)
  local i = #paintRects + 1
  paintRects[i] = rect
  paintRectFrames[i] = 0
end


