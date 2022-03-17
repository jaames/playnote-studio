local THUMB_IMG_W <const> = 64
local THUMB_IMG_H <const> = 48
local THUMB_IMG_PADX <const> = 4
local THUMB_IMG_PADY <const> = 4
local THUMB_W <const> = THUMB_IMG_W + (THUMB_IMG_PADX * 2)
local THUMB_H <const> = THUMB_IMG_H + (THUMB_IMG_PADY * 2)

Thumbnail = {}
class('Thumbnail').extends(ComponentBase)

function Thumbnail:init(x, y, tmb)
  Thumbnail.super.init(self, x - THUMB_IMG_PADX, y - THUMB_IMG_PADY, THUMB_W, THUMB_H)
  self.selectable = true
  self.tmb = tmb
end

function Thumbnail:moveToX(x)
  self:moveTo(x, self.y)
end

function Thumbnail:moveToY(y)
  self:moveTo(self.x, y)
end

function Thumbnail:click()
  if self.tmb then
    noteFs:setCurrentNote(self.tmb.path)
    sceneManager:push('player', sceneManager.kTransitionFade)
  end
end

function Thumbnail:getPath()
  return self.tmb.path
end

-- TEMPFIX: i don't totally understand why, but the notelist bg wasn't being redraw correctly when thumbnail selection changed...
-- this seems to fix for now...
function Thumbnail:markDirty()
  local ox, oy = gfx.getDrawOffset()
  local bx, by = self:getBounds()
  spritelib.addDirtyRect(bx + ox - 4, by + oy - 4, THUMB_W + 8, THUMB_H + 8)
end

function Thumbnail:draw(clipX, clipY, clipW, clipH)
  if self.tmb then
    if self.isSelected then
      -- selection outline
      gfx.setColor(gfx.kColorWhite)
      gfx.fillRect(0, 0, THUMB_W, THUMB_H)
      gfx.setColor(gfx.kColorBlack)
      gfx.setLineWidth(2)
      gfx.drawRoundRect(1, 1, THUMB_W - 2, THUMB_H - 2, 4)
    else
      -- shadow
      gfx.setLineWidth(1)
      gfx.setColor(gfx.kColorBlack)
      gfx.fillRect(6, 6, THUMB_W - 7, THUMB_H - 7)
       -- black outer border
      gfx.drawRect(2, 2, THUMB_W - 4, THUMB_H - 4)
      -- white inner boarder
      gfx.setColor(gfx.kColorWhite)
      gfx.drawRect(3, 3, THUMB_W - 6, THUMB_H - 6)
    end
    self.tmb.bitmap:draw(THUMB_IMG_PADX, THUMB_IMG_PADY)
  end
end

function Thumbnail:removedFromScreen()
  self.tmb = nil
end