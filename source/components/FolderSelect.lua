FolderSelect = {}
class('FolderSelect').extends(Select)

function FolderSelect:init(x, y, w, h)
  FolderSelect.super.init(self, x, y, w, h)
  self:setIcon('./gfx/icon_folder')
end

function FolderSelect:draw(clipX, clipY, clipW, clipH)
  self:setText(self.optionLabels[self.activeOptionIndex])
  Button.draw(self, clipX, clipY, clipW, clipH)
end