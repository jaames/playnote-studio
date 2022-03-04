pdbug = {}

pdbug.active = false

-- settings can be tweaked
pdbug.showFPS = true
pdbug.showPaintFlashing = true
pdbug.overlayColor = {255, 0, 40, 0.75}
pdbug.paintFlashLineWidth = 2
pdbug.paintFlashFrameDelay = 15

local gfx <const> = playdate.graphics
local rectlib <const> = playdate.geometry.rect
local isSim <const> = playdate.isSimulator
local debugDraw = playdate.debugDraw
local setBackgroundDrawingCallback = playdate.graphics.sprite.setBackgroundDrawingCallback

local paintRects = {}
local paintRectFrames = {}

function pdbug:setEnabled(enabled)
  assert(isSim, 'pdbug can only be used in the Playdate Simulator')
  if enabled and (not pdbug.active) then
    pdbug.active = true
    playdate.setDebugDrawColor(table.unpack(self.overlayColor))
    debugDraw = playdate.debugDraw
    playdate.debugDraw = self:_patchFn(playdate.debugDraw, self._debugDraw)
  elseif (not enabled) and pdbug.active then
    pdbug.active = false
    playdate.debugDraw = debugDraw
  end
end

function pdbug:setOverlayColor(r, g, b, a)
  self.overlayColor = {r, g, b, a}
  playdate.setDebugDrawColor(r, g, b, a)
end

function pdbug:addPaintRect(x, y, w, h)
  if isSim then
    local rect = rectlib.new(x, y, w, h)
    local i = #paintRects + 1
    paintRects[i] = rect
    paintRectFrames[i] = 0
  end
end

function pdbug:_patchFn(baseFn, patchFn)
  if type(baseFn) == 'function' then
    return function (...)
      baseFn(...)
      patchFn(...)
    end
  else
    return patchFn
  end
end

function pdbug._backgroundDrawingCallback(x, y, w, h)
  if isSim and pdbug.active then
    pdbug:addPaintRect(x, y, w, h)
  end
end

function pdbug._debugDraw()
  gfx.setDrawOffset(0,0)
  gfx.setColor(gfx.kColorWhite)

  if pdbug.showFPS then
    playdate.drawFPS(8, PLAYDATE_H - 20)
  end

  if pdbug.showPaintFlashing then
    gfx.setLineWidth(pdbug.paintFlashLineWidth)
    local delay = pdbug.paintFlashFrameDelay
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

if isSim then
  playdate.graphics.sprite.setBackgroundDrawingCallback(pdbug._backgroundDrawingCallback)
  -- prevent user removing pdbug's background drawing callback by calling setBackgroundDrawingCallback themselves
  playdate.graphics.sprite.setBackgroundDrawingCallback = function (fn)
    local patchedFn = pdbug:_patchFn(fn, pdbug._backgroundDrawingCallback)
    setBackgroundDrawingCallback(patchedFn)
  end
end