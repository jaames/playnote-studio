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
      DitherSwatch(32 + 48, 64, 48, 48),
      DitherSwatch(128 + 48, 64, 48, 48),
      DitherSwatch(224 + 48, 64, 48, 48),
    },
    {
      DitherSwatch(32 + 48, 128, 48, 48),
      DitherSwatch(128 + 48, 128, 48, 48),
      DitherSwatch(224 + 48, 128, 48, 48),
    }
  }
  self:setSelected(1, 1)
end

function DitheringScreen:beforeEnter()
  DitheringScreen.super.beforeEnter(self)
  for i, row in ipairs(self.swatches) do
    for j, swatch in ipairs(row) do
      swatch:setPattern(config.dithering[i][j])
    end
  end
end

function DitheringScreen:setSelected(layer, colour)
  if self.selectedLayer ~= nil then
    self.swatches[self.selectedLayer][self.selectedColour].isSelected = false
  end
  layer = math.max(1, math.min(layer, 2))
  colour = math.max(1, math.min(colour, 3))
  self.swatches[layer][colour].isSelected = true
  self.selectedLayer = layer
  self.selectedColour = colour
end

-- TODO: make pretty

function DitheringScreen:update()
  local layer = self.selectedLayer
  gfxUtils:drawBgGrid()
  gfx.setColor(gfx.kColorBlack)
  gfx.fillRoundRect(32 + 36, 32 - 3, 256 + 6, 24, 6)
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect("Black", 32 + 48, 32, 48, 20, nil, "...", kTextAlignment.center)
  gfx.drawTextInRect("Red", 128 + 48, 32, 48, 20, nil, "...", kTextAlignment.center)
  gfx.drawTextInRect("Blue", 224 + 48, 32, 48, 20, nil, "...", kTextAlignment.center)
  gfx.setImageDrawMode(0)

  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(32 + 36, 64 - 4, 256 + 8, 56, 6)

  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(32 + 36, 128 - 4, 256 + 8, 56, 6)

  for _, row in pairs(self.swatches) do
    for _, swatch in pairs(row) do
      swatch:draw()
    end
  end
end