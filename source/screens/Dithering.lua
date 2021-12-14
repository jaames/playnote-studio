local gfx <const> = playdate.graphics

DitheringScreen = {}
class('DitheringScreen').extends(ScreenBase)

function DitheringScreen:init()
  DitheringScreen.super.init(self)
  self.inputHandlers = {
    leftButtonDown = function()
      self:setSelected(self.selectedLayer, self.selectedColour - 1)
    end,
    rightButtonDown = function()
      self:setSelected(self.selectedLayer, self.selectedColour + 1)
    end,
    upButtonDown = function()
      self:setSelected(self.selectedLayer - 1, self.selectedColour)
    end,
    downButtonDown = function()
      self:setSelected(self.selectedLayer + 1, self.selectedColour)
    end,
    AButtonDown = function()
      local layer = self.selectedLayer
      local colour = self.selectedColour
      local selectedSwatch = self.swatches[layer][colour]
      selectedSwatch:switchPattern()
      config.dithering[layer][colour] = selectedSwatch.pattern
    end,
  }
  self.swatches = {
    {
      DitherSwatch(32, 32, 48, 48),
      DitherSwatch(96, 32, 48, 48),
      DitherSwatch(160, 32, 48, 48),
    },
    {
      DitherSwatch(32, 96, 48, 48),
      DitherSwatch(96, 96, 48, 48),
      DitherSwatch(160, 96, 48, 48),
    }
  }
  self:setSelected(1, 1)
end

function DitheringScreen:beforeEnter()
  DitheringScreen.super.beforeEnter(self)
  for i, row in ipairs(self.swatches) do
    for j, swatch in ipairs(row) do
      swatch.pattern = config.dithering[i][j]
    end
  end
end

function DitheringScreen:setSelected(layer, colour)
  if self.selectedLayer ~= nil then
    self.swatches[self.selectedLayer][self.selectedColour].isSelected = false
  end
  layer = math.max(1, math.min(2, layer))
  colour = math.max(1, math.min(3, colour))
  self.swatches[layer][colour].isSelected = true
  self.selectedLayer = layer
  self.selectedColour = colour
end

function DitheringScreen:update()
  gfxUtils:drawBgGrid()
  for _, row in ipairs(self.swatches) do
    for _, swatch in ipairs(row) do
      swatch:draw()
    end
  end
end