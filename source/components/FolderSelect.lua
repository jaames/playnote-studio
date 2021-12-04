import './Select.lua'

local gfx <const> = playdate.graphics
local fontBold <const> = gfx.font.new('./fonts/WhalesharkSans')

FolderSelect = {}
class('FolderSelect').extends(Select)

function FolderSelect:init(x, y, w, h)
  FolderSelect.super.init(self, x, y, w, h)
end

function FolderSelect:drawAt(x, y)
  Select.super.drawAt(self, x, y)
  if self.isOpen then
    self:drawMenu()
  end
end

function FolderSelect:onChange(value, index)
  self:setText(self.optionLabels[index])
end


