FolderSelect = {}
class('FolderSelect').extends(Select)

function FolderSelect:init(x, y, w, h)
  FolderSelect.super.init(self, x, y, w, h)
  self.textAlign = kTextAlignment.center
  self:setIcon('./gfx/icon_folder')
end

function FolderSelect:addOption(value, label, shortLabel)
  table.insert(self.optionLabels, label)
  table.insert(self.optionShortLabels, shortLabel or label)
  table.insert(self.optionValues, value)
  if #self.optionLabels == 1 then
    self:setValue(value)
  end
end

function FolderSelect:addedToScreen()
  sounds:prepareSfxGroup('select', {
    'optionMenuOpen',
  })
end

function FolderSelect:draw(clipX, clipY, clipW, clipH)
  self:setText(self.optionLabels[self.activeOptionIndex])
  Button.draw(self, clipX, clipY, clipW, clipH)
end