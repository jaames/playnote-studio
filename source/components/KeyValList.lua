local gfx <const> = playdate.graphics

local HR_PATTERN <const> = {0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC}

KeyValList = {}
class('KeyValList').extends(ComponentBase)

function KeyValList:init(x, y, w) self.padding = 16
  self.textAdv = 5
  self.columnGap = 12
  self.lineAdv = 16
  self.lineMargin = -6
  self.rows = {}
  self.valueOffsets = {}
  KeyValList.super.init(self, x, y, w, self.padding * 2)
  self.bg = gfx.nineSlice.new('./gfx/shape_box', 5, 5, 2, 2)
end

function KeyValList:addRow(label, value)
  if value == nil then return end
  gfx.setFontTracking(1)
  local i = #self.rows + 1
  local textW = self.width - self.padding * 2
  local labelW, labelH = gfx.getTextSizeForMaxWidth(label, textW)
  local valueW, valueH = gfx.getTextSizeForMaxWidth(value, textW)
  if i > 1 then
    self.height += self.textAdv
  end
  if labelW + valueW + self.columnGap > textW then
    self.valueOffsets[i] = labelH
    self.height += labelH
  end
  self.rows[i] = {label, value}
  self.height += valueH
  self:setSize(self.width, self.height)
  self:markDirty()
end

function KeyValList:clear()
  self.rows = {}
  self.valueOffsets = {}
  self.height = self.padding * 2
  self:setSize(self.width, self.height)
end

function KeyValList:addBreak()
  local i = #self.rows + 1
  self.rows[i] = '-'
  self.height += self.lineAdv
  self:setSize(self.width, self.height)
end

function KeyValList:draw()
  local w = self.width
  local h = self.height
  local padd = self.padding
  local textW = w - self.padding * 2
  local textH = h - self.padding * 2
  local textAdv = self.textAdv
  local textRect = playdate.geometry.rect.new(padd, padd, textW, textH)
  local valueOffsets = self.valueOffsets
  local lineX = textRect.x + self.lineMargin
  local lineW = textW - self.lineMargin * 2
  local lineAdv = self.lineAdv
  self.bg:drawInRect(0, 0, self.width, self.height)
  gfx.setColor(gfx.kColorBlack)
  gfx.setPattern(HR_PATTERN)
  gfx.setFontTracking(1)
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
      gfx.fillRect(lineX, textRect.y + (lineAdv / 2) - 3, lineW, 1)
      textRect.y += lineAdv
    end
  end
end
