local helpQrGfx <const> = gfx.image.new('./gfx/qr_filehelp')
local boxGfx <const> = gfx.nineSlice.new('./gfx/shape_box', 5, 5, 2, 2)

NoNoteDialog = {}
class('NoNoteDialog').extends(ComponentBase)

function NoNoteDialog:init(x, y, w, h)
  NoNoteDialog.super.init(self, x, y, w, h)
  self.show = false
end

function NoNoteDialog:draw()
  if self.show then
    local w, h = self.width, self.height
    boxGfx:drawInRect(0, 0, w, h)
    gfx.drawTextInRect(locales:getText('VIEW_NO_FLIPNOTES'), 20, 24, 360, 200, nil, nil)
    helpQrGfx:draw(246, 50)
    gfx.drawTextInRect(locales:getText('VIEW_NO_FLIPNOTES_INFO'), 20, 64, 232, 200, nil, nil)
  end
end