local OPTION_GAP <const> = 12
local OPTION_WIDTH <const> = 314
local OPTION_HEIGHT <const> = 40
local MENU_X <const> = (PLAYDATE_W / 2) - (OPTION_WIDTH / 2)
local MENU_Y <const> = (PLAYDATE_H / 2) - (OPTION_HEIGHT / 2)
local MENU_OPEN_DUR = 250
local MENU_SCROLL_DUR = 100

Select = {}
class('Select').extends(Button)

function Select:init(x, y, w, h, text)
  Select.super.init(self, x, y, w, h, text)
  self.selectable = true

  self.menu = SelectMenu(self)

  self.prelocaleOptionLabels = {}
  self.optionLabels = {} -- string label per option
  self.prelocaleOptionShortLabels = {}
  self.optionShortLabels = {} -- shortened string lables to show on select button
  self.optionValues = {} -- values for each option
  self.activeOptionValue = ''
  self.activeOptionIndex = 1

  self.changeCallback = function (val, idx) end
  self.closeCallback = function (val, idx) end
  self.closeEndCallback = function (val, idx) end
end

function Select:addedToScreen()
  sounds:prepareSfxGroup('select', {
    'optionMenuOpen',
  })
  -- update labels and text when added to screen
  local optionLabels = self.optionLabels
  local optionShortLabels = self.optionShortLabels
  local prelocaleOptionLabels = self.prelocaleOptionLabels
  local prelocaleOptionShortLabels = self.prelocaleOptionShortLabels
  for i = 1, #prelocaleOptionLabels do
    optionLabels[i] = locales:replaceKeysInText(prelocaleOptionLabels[i])
    optionShortLabels[i] = locales:replaceKeysInText(prelocaleOptionShortLabels[i])
  end
  self:setText(self.prelocaleText)
end

function Select:removedFromScreen()
  sounds:releaseSfxGroup('select')
end

function Select:onChange(fn)
  assert(type(fn) == 'function', 'callback must be a function')
  self.changeCallback = fn
end

function Select:onClose(fn)
  assert(type(fn) == 'function', 'callback must be a function')
  self.closeCallback = fn
end

function Select:onCloseEnded(fn)
  assert(type(fn) == 'function', 'callback must be a function')
  self.closeEndCallback = fn
end

function Select:menuChangeCallback(value, index)
  self:setValue(value)
  self.changeCallback(value, index)
end

function Select:menuCloseCallback()
  self.closeCallback(self.activeOptionValue, self.activeOptionIndex)
end

function Select:menuCloseEndCallback()
  self.closeEndCallback(self.activeOptionValue, self.activeOptionIndex)
end

function Select:click()
  local menu = self.menu
  menu.optionLabels = self.optionLabels
  menu.optionValues = self.optionValues
  menu.activeOptionValue = self.activeOptionValue
  menu.activeOptionIndex = self.activeOptionIndex
  menu:open()
end

function Select:clearOptions()
  self.prelocaleOptionLabels = {}
  self.prelocaleOptionShortLabels = {}
  self.optionLabels = {}
  self.optionShortLabels = {}
  self.optionValues = {}
  self.activeOptionValue = ''
  self.activeOptionIndex = 1
  self:markDirty()
end

function Select:addOption(value, label, shortLabel)
  table.insert(self.prelocaleOptionLabels, label)
  table.insert(self.prelocaleOptionShortLabels, shortLabel or label)
  table.insert(self.optionValues, value)
  if #self.optionLabels == 1 then
    self:setValue(value)
  end
end

function Select:setValue(value)
  local index = 0
  local vals = self.optionValues
  local n = #vals
  -- indexOfElement apparently won't work for bools and other types here...
  for i = 1,n do
    if vals[i] == value then
      index = i
      break
    end
  end
  if index ~= nil then
    self.activeOptionValue = value
    self.activeOptionIndex = index
    self:markDirty()
  end
end

function Select:getValue()
  return self.activeOptionValue
end

function Select:draw(clipX, clipY, clipW, clipH)
  Select.super.draw(self, clipX, clipY, clipW, clipH)
  local w, h = self.width, self.height
  gfx.setFontTracking(1)
  local currValueLabel = self.optionShortLabels[self.activeOptionIndex]
  local labelW, labelH = gfx.getTextSize(currValueLabel)
  local boxPad = 10
  local boxW = labelW + boxPad * 2
  local boxH = labelH + 4
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(w - self.padRight - boxW, self.textY - 2, boxW, boxH, boxH / 2)
  -- gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(currValueLabel, 0, self.textY, w - self.padRight - boxPad, h, nil, '...', kTextAlignment.right)
  -- gfx.setImageDrawMode(0)
end

SelectMenu = {}
class('SelectMenu').extends(ComponentBase)

function SelectMenu:init(selectComponent)
  SelectMenu.super.init(self, 0, 0, PLAYDATE_W, PLAYDATE_H)
  self:setZIndex(1200)
  self:setIgnoresDrawOffset(true)

  self.select = selectComponent

  self.isOpen = false
  self.openTransitionActive = false
  self.numOptions = 0
  self.optionLabels = {} -- string label per option
  self.optionValues = {} -- values for each option
  self.activeOptionIndex = 0
  self.activeOptionValue = nil
  self.menuHeight = 0
  self.menuScroll = 0
  self.menuScrollTransitionActive = false
  self.silenceNotAllowedSfx = false
  self.bounceEffectActive = false
end

function SelectMenu:open()
  if self.isOpen or self.openTransitionActive then return end
  -- prep and play sfx
  sounds:prepareSfxGroup('select:menu', {
    'selectionNotAllowed',
    'optionMenuClose',
    'optionMenuChangeSelectionUp',
    'optionMenuChangeSelectionDown',
  })
  sounds:playSfx('optionMenuOpen')
  -- add self to display list and freeze input during transition
  self:add()
  playdate.inputHandlers.push({}, true)
  -- calculate layout variables
  local numLabels = #self.optionLabels
  self.numOptions = numLabels
  self.menuHeight = (numLabels * OPTION_HEIGHT) + (numLabels -1 * OPTION_GAP)
  self.menuScroll = (self.activeOptionIndex - 1) * (OPTION_HEIGHT + OPTION_GAP)
  -- transition setup
  local timer = playdate.timer.new(MENU_OPEN_DUR, 0, 1)
  local startPos = PLAYDATE_H
  self.openTransitionActive = true
  self.isOpen = true
  self:offsetByY(startPos)

  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function ()
    overlayBg:setBlackFade(timer.value * 0.5)
    self:offsetByY(startPos - playdate.easingFunctions.outBack(timer.value, 0, startPos, 1))
  end

  timer.timerEndedCallback = function ()
    self.openTransitionActive = false
    overlayBg:setBlackFade(0.5)
    self:offsetByY(0)

    utils:nextTick(function ()
      spritelib.setAlwaysRedraw(false)
    end)

    local delay = 400
    local delayRepeat = 200

    local upButtonDown, upButtonUp, rmvRepeat1 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
      self.silenceNotAllowedSfx = isRepeat
      self:selectPrev()
    end)
    local downButtonDown, downButtonUp, rmvRepeat2 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
      self.silenceNotAllowedSfx = isRepeat
      self:selectNext()
    end)

    self.removeRepeaters = function()
      rmvRepeat1()
      rmvRepeat2()
    end

    playdate.inputHandlers.pop()
    playdate.inputHandlers.push({
      AButtonDown = function()
        self:close()
      end,
      BButtonDown = function()
        self:close()
      end,
      upButtonDown = upButtonDown,
      upButtonUp = upButtonUp,
      downButtonDown = downButtonDown,
      downButtonUp = downButtonUp
    }, true)
  end
end

function SelectMenu:close()
  if (not self.isOpen) or self.openTransitionActive then return end
  sounds:playSfx('optionMenuClose')
  self.select:menuCloseCallback()

  self.openTransitionActive = true
  self:offsetByY(0)

  local timer = playdate.timer.new(MENU_OPEN_DUR, 0, 1)

  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function ()
    overlayBg:setBlackFade((1 - timer.value) * 0.5)
    self:offsetByY(playdate.easingFunctions.inBack(timer.value, 0, PLAYDATE_H, 1))
  end

  timer.timerEndedCallback = function ()
    overlayBg:setBlackFade(0)
    self:offsetByY(PLAYDATE_H)
    self.select:menuCloseEndCallback()

    utils:nextTick(function ()
      spritelib.setAlwaysRedraw(false)
    end)

    utils:nextTick(function ()
      sounds:releaseSfxGroup('select:menu')
      -- remove from display list, sttop transition and reinstate prev input
      self:remove()
      self.isOpen = false
      self.openTransitionActive = false
      self.removeRepeaters()
      playdate.inputHandlers.pop()
    end)
  end
end

function SelectMenu:setValueByIndex(index, animate)
  -- don't update if menu is transitioning to another item
  if self.menuScrollTransitionActive then return end
  -- ignore out of bounds option indecies
  if index > self.numOptions or index < 1 then
    -- TODO: play 'not allowed' sound effect here
    index = utils:clamp(index, 1, self.numOptions)
  end
  -- figure out how far to scroll for the selected option
  local currScroll = self.menuScroll
  local nextScroll = (index - 1) * (OPTION_HEIGHT + OPTION_GAP)
  -- scroll with animation
  if animate == true then
    self.menuScrollTransitionActive = true
    local timer = playdate.timer.new(MENU_SCROLL_DUR, currScroll, nextScroll, playdate.easingFunctions.outCubic)
    timer.updateCallback = function ()
      self.menuScroll = timer.value
      self:markDirty()
    end
    timer.timerEndedCallback = function ()
      self.menuScroll = nextScroll
      self.menuScrollTransitionActive = false
      self:markDirty()
    end
  -- or not
  else
    self.menuScroll = nextScroll
  end
  -- update state
  self.activeOptionIndex = index
  self.activeOptionValue = self.optionValues[index]
  -- do onChange callback
  self.select:menuChangeCallback(self.activeOptionValue, index)
end

function SelectMenu:selectNext()
  local activeOptionIndex = self.activeOptionIndex
  if activeOptionIndex < self.numOptions then
    self:setValueByIndex(activeOptionIndex + 1, true)
    sounds:playSfx('optionMenuChangeSelectionDown')
  else
    self:selectionNotAllowed(1)
  end
end

function SelectMenu:selectPrev()
  local activeOptionIndex = self.activeOptionIndex
  if activeOptionIndex > 1 then
    self:setValueByIndex(activeOptionIndex - 1, true)
    sounds:playSfx('optionMenuChangeSelectionUp')
  else
    self:selectionNotAllowed(-1)
  end
end

function SelectMenu:selectionNotAllowed(dir)
  if (not self.silenceNotAllowedSfx) and (not self.bounceEffectActive) then
    self.bounceEffectActive = true
    sounds:playSfx('selectionNotAllowed')
    local currScroll = self.ty
    local bumpScroll = self.ty - 8 * dir

    local timer = playdate.timer.new(90, currScroll, bumpScroll, playdate.easingFunctions.inOutSine)
    timer.reverses = true

    timer.updateCallback = function (t)
      self:offsetByY(t.value)
    end
    timer.timerEndedCallback = function (t)
      self:offsetByY(t.value)
      self.bounceEffectActive = false
    end
  end
end

function SelectMenu:update()
  -- use crank to scroll through options
  local crankChange = playdate.getCrankTicks(6)
  if crankChange ~= 0 then
    self:setValueByIndex(self.activeOptionIndex + crankChange, true)
  end
end

function SelectMenu:draw()
  -- draw selection focus
  local menuX = MENU_X
  local menuY = MENU_Y - self.menuScroll
  gfx.setFontTracking(1)
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(MENU_X - 8, MENU_Y - 8, OPTION_WIDTH + 16, OPTION_HEIGHT + 16, (OPTION_HEIGHT + 16) / 2)
  -- draw option items
  gfx.setColor(gfx.kColorWhite)
  for i = 1,self.numOptions do
    gfx.fillRoundRect(menuX, menuY, OPTION_WIDTH, OPTION_HEIGHT, OPTION_HEIGHT / 2)
    -- gfx.setFont(font)
    gfx.drawTextInRect(self.optionLabels[i], menuX + 8, menuY + 10, OPTION_WIDTH - 16, 24, nil, '...', kTextAlignment.center)
    menuY = menuY + OPTION_HEIGHT + OPTION_GAP
  end
  -- draw selection border
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(2)
  gfx.drawRoundRect(MENU_X - 4, MENU_Y - 4, OPTION_WIDTH + 8, OPTION_HEIGHT + 8, (OPTION_HEIGHT + 8) / 2)
end