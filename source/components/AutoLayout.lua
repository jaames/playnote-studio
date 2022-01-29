AutoLayout = {}
class('AutoLayout').extends()

AutoLayout.kDirectionRow = 1
AutoLayout.kDirectionColumn = 2

function AutoLayout:init(x, y, direction, staticAxis)
  self.x = x
  self.y = y
  self.width = 0
  self.height = 0
  self.gap = 10
  self.padLeft = 24
  self.padRight = 24
  self.padTop = 24
  self.padBottom = 24
  self.direction = direction
  self.staticAxis = staticAxis
  self.layoutAxis = 0
  self.children = {}
end

function AutoLayout:updateSize()
  if self.direction == AutoLayout.kDirectionColumn then
    self.width = self.staticAxis
    self.height = self.padTop + self.layoutAxis + self.padBottom
  elseif self.direction == AutoLayout.kDirectionRow then
    self.width = self.padLeft + self.layoutAxis + self.padRight
    self.height = self.staticAxis
  end
end

function AutoLayout:setPadding(left, right, top, bottom)
  self.padLeft = left
  self.padRight = right
  self.padTop = top
  self.padBottom = bottom
  self:updateSize()
end

function AutoLayout:add(component)
  if #self.children > 0 then
    self.layoutAxis += self.gap
  end
  if self.direction == AutoLayout.kDirectionColumn then
    component:moveTo(self.x + self.padLeft, self.y + self.padTop + self.layoutAxis)
    self.layoutAxis += component.height
  elseif self.direction == AutoLayout.kDirectionRow then
    component:moveTo(self.x + self.padLeft + self.layoutAxis, self.y + self.padTop)
    self.layoutAxis += component.width
  end
  table.insert(self.children, component)
  self:updateSize()
end