local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local COL_ICON <const> = 92
local COL_BLACK <const> = 136
local COL_RED <const> = 218
local COL_BLUE <const> = 300

local ROW_LABELS <const> = 42
local ROW_LAYER1 <const> = 100
local ROW_LAYER2 <const> = 164

local RECT_LABELS <const> = playdate.geometry.rect.new(
  COL_BLACK - 38,
  ROW_LABELS - 4, 
  (COL_BLUE - COL_BLACK) + (38 * 2),
  27
)

local RECT_LAYER1 <const> = playdate.geometry.rect.new(
  COL_ICON - 44,
  ROW_LAYER1 - 28, 
  (COL_BLUE - COL_ICON) + (44 * 2),
  56
)

local RECT_LAYER2 <const> = playdate.geometry.rect.new(
  COL_ICON - 44,
  ROW_LAYER2 - 28, 
  (COL_BLUE - COL_ICON) + (44 * 2),
  56
)

local layer1Icon <const> = gfx.image.new('/gfx/icon_layer1')
local layer2Icon <const> = gfx.image.new('/gfx/icon_layer2')

DitheringScreen = {}
class('DitheringScreen').extends(ScreenBase)

function DitheringScreen:init()
  DitheringScreen.super.init(self)
  self.ditherConf = config.dithering
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
      self.ditherConf[layer][colour] = selectedSwatch.pattern
    end,
  }
  self.swatches = {
    {
      DitherSwatch(COL_BLACK, ROW_LAYER1),
      DitherSwatch(COL_RED,   ROW_LAYER1),
      DitherSwatch(COL_BLUE,  ROW_LAYER1),
    },
    {
      DitherSwatch(COL_BLACK, ROW_LAYER2),
      DitherSwatch(COL_RED,   ROW_LAYER2),
      DitherSwatch(COL_BLUE,  ROW_LAYER2),
    }
  }
  self:setSelected(1, 1)
end

function DitheringScreen:beforeEnter(ditherConf, callback)
  DitheringScreen.super.beforeEnter(self)
  assert(ditherConf ~= nil, 'No dither config, uh oh')
  for i, row in ipairs(self.swatches) do
    for j, swatch in ipairs(row) do
      swatch:setPattern(ditherConf[i][j])
    end
  end
  self.ditherConf = ditherConf
  self.callback = callback
end

function DitheringScreen:beforeLeave()
  if self.callback then
    self.callback(self.ditherConf)
  end
  self.ditherConf = nil
  self.callback = nil
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

function DitheringScreen:update()
  gfxUtils:drawBgGrid()

  gfx.setColor(gfx.kColorBlack)
  gfx.fillRoundRect(RECT_LABELS, 6)

  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextAligned(locales:getText('DITHER_COLOUR_BLACK'), COL_BLACK, ROW_LABELS, kTextAlignment.center)
  gfx.drawTextAligned(locales:getText('DITHER_COLOUR_RED'),   COL_RED,   ROW_LABELS, kTextAlignment.center)
  gfx.drawTextAligned(locales:getText('DITHER_COLOUR_BLUE'),  COL_BLUE,  ROW_LABELS, kTextAlignment.center)
  gfx.setImageDrawMode(0)

  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(RECT_LAYER1, 8)
  gfx.fillRoundRect(RECT_LAYER2, 8)

  layer1Icon:drawAnchored(COL_ICON, ROW_LAYER1, 0.80, 0.5)
  layer2Icon:drawAnchored(COL_ICON, ROW_LAYER2, 0.80, 0.5)

  for _, row in pairs(self.swatches) do
    for _, swatch in pairs(row) do
      swatch:draw()
    end
  end
end