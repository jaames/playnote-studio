local gfx <const> = playdate.graphics

local HR_PATTERN <const> = {0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC}

KeyValList = {}
class('KeyValList').extends()

function KeyValList:init(x, y, w)
  KeyValList.super.init(self)
  self.bg = gfx.nineSlice.new('./gfx/shape_box', 5, 5, 2, 2)
  self.padding = 16
  self.textAdv = 5
  self.columnGap = 12
  self.lineAdv = 16
  self.lineMargin = -6
  self.rows = {}
  self.valueOffsets = {}
  self.bitmap = nil
  self.isDirty = false
  self.x = x
  self.y = y
  self.w = w
  self.h = self.padding * 2
end

function KeyValList:addRow(label, value)
  local i = #self.rows + 1
  local textW = self.w - self.padding * 2
  local labelW, labelH = gfx.getTextSizeForMaxWidth(label, textW)
  local valueW, valueH = gfx.getTextSizeForMaxWidth(value, textW)
  if i > 1 then
    self.h += self.textAdv
  end
  if labelW + valueW + self.columnGap > textW then
    self.valueOffsets[i] = labelH
    self.h += labelH
  end
  self.rows[i] = {label, value}
  self.h += valueH
  self.isDirty = true
end

function KeyValList:clear()
  self.rows = {}
  self.valueOffsets = {}
  self.bitmap = nil
  self.isDirty = true
  self.h = self.padding * 2
end

function KeyValList:addBreak()
  local i = #self.rows + 1
  self.rows[i] = '-'
  self.h += self.lineAdv
  self.isDirty = true
end

function KeyValList:draw()
  self:drawAt(self.x, self.y)
end

function KeyValList:drawAt(x, y)
  if self.bitmap == nil or self.isDirty then
    local w = self.w
    local h = self.h
    local padd = self.padding
    local textW = w - self.padding * 2
    local textH = h - self.padding * 2
    local textAdv = self.textAdv
    local textRect = playdate.geometry.rect.new(padd, padd, textW, textH)
    local valueOffsets = self.valueOffsets
    local lineX = textRect.x + self.lineMargin
    local lineW = textW - self.lineMargin * 2
    local lineAdv = self.lineAdv
    self.bitmap = gfx.image.new(w, h)
    self.isDirty = false
    gfx.pushContext(self.bitmap)
    gfx.setColor(gfx.kColorBlack)
    gfx.setPattern(HR_PATTERN)
    for i, row in ipairs(self.rows) do
      -- draw label/value row
      if type(row) == 'table' then
        local label = row[1]
        local value = row[2]
        gfx.drawTextInRect(label, textRect, nil, nil, kTextAlignment.left)
        -- if there's not enough space for row label and value on same line, move value onto the next line
        if type(valueOffsets[i]) == 'number' then
          textRect.y += valueOffsets[i]
        end
        local _, valueH = gfx.drawTextInRect(value, textRect, nil, nil, kTextAlignment.right)
        textRect.y += valueH + textAdv
      -- or draw horizontal line rule
      elseif row == '-' then
        gfx.fillRect(lineX, textRect.y + lineAdv / 2, lineW, 1)
        textRect.y += lineAdv
      end
    end
    gfx.popContext()
  end
  self.bg:drawInRect(x, y, self.w, self.h)
  self.bitmap:draw(x, y)
end
