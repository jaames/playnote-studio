local img <const> = gfx.image.new('./gfx/icon_page_next')

PageArrow = {}
class('PageArrow').extends(ComponentBase)

PageArrow.kTypeNext = 1
PageArrow.kTypePrev = 2

function PageArrow:init(x, y, type)
  local w, h = img:getSize()
  PageArrow.super.init(self, x, y, w, h)
  self:setAnchor('center', 'center')
  self:setZIndex(200)
  self:setImage(img)
  if type == PageArrow.kTypePrev then
    self:setImageFlip(gfx.kImageFlippedX)
  end
end