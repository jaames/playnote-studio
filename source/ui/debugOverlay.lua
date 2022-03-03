pdbug = {}

pdbug.active = false

pdbug.showFPS = true

pdbug.showPaintFlashing = true
pdbug.paintFlashLineWidth = 2
pdbug.paintFlashFrameDelay = 15

local rectlib <const> = playdate.geometry.rect
local isSim = playdate.isSimulator

local origDbgDraw = playdate.debugDraw

local paintRects = {}
local paintRectFrames = {}

function pdbug:start()
  if not isSim then return end
  origDbgDraw = playdate.debugDraw
  pdbug.active = true

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
  origDbgDraw()
end

function pdbug:stop()
  playdate.debugDraw = origDbgDraw
  pdbug.active = false
end

function pdbug:updatePaintRect(x, y, w, h)
  if isSim then
    local rect = rectlib.new(x, y, w, h)
    local i = #paintRects + 1
    paintRects[i] = rect
    paintRectFrames[i] = 0
  end
end


