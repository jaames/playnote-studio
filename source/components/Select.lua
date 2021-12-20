import './Button.lua'

local gfx <const> = playdate.graphics

local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local OPTION_GAP <const> = 12
local OPTION_WIDTH <const> = 304
local OPTION_HEIGHT <const> = 40
local MENU_X <const> = (PLAYDATE_W / 2) - (OPTION_WIDTH / 2)
local MENU_Y <const> = (PLAYDATE_H / 2) - (OPTION_HEIGHT / 2)
local MENU_OPEN_DUR = 250
local MENU_SCROLL_DUR = 100

Select = {}
class('Select').extends(Button)

function Select:init(x, y, w, h)
  Select.super.init(self, x, y, w, h)
  self.isOpen = false
  self.openTransitionActive = false
  self.numOptions = 0
  self.optionLabels = {} -- string label per option
  self.optionShortLabels = {} -- shortened string lables to show on select button
  self.optionValues = {} -- values for each option
  self.activeOptionIndex = 0
  self.activeOptionValue = nil
  self.bgFade = 0.5
  self.menuScroll = 0
  self.menuHeight = 0
  self.menuOpenShift = 0
  self.menuScrollTransitionActive = false
end

-- override this to be notified of a selection change
function Select:onChange(value, index)
end

-- override this to be notified of a menu close
function Select:onClose(value, index)
end

-- override this to be notified of a menu close, after the transition
function Select:onCloseEnded(value, index)
end

function Select:addOption(value, label, shortLabel)
  table.insert(self.optionLabels, label)
  table.insert(self.optionShortLabels, shortLabel or label)
  table.insert(self.optionValues, value)
  self.numOptions = self.numOptions + 1
  -- adjust menu height to accomodate the new option
  if self.numOptions > 1 then
    self.menuHeight = self.menuHeight + OPTION_GAP + OPTION_HEIGHT
  -- (first option doesn't need a gap above it)
  else
    self.menuHeight = self.menuHeight + OPTION_HEIGHT
  end
end

function Select:setValue(value, animate)
  local index = 0
  local vals = self.optionValues
  -- indexOfElement apparently won't work for bools and other types  here...
  for i = 1,self.numOptions do
    if vals[i] == value then
      index = i
      break
    end
  end
  if index ~= nil then
    self:setValueByIndex(index, animate)
  end
end

function Select:getValue()
  return self.activeOptionValue
end

function Select:setValueByIndex(index, animate)
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
    end
    timer.timerEndedCallback = function ()
      self.menuScroll = nextScroll
      self.menuScrollTransitionActive = false
    end
  -- or not
  else
    self.menuScroll = nextScroll
  end
  -- update state
  self.activeOptionIndex = index
  self.activeOptionValue = self.optionValues[index]
  -- do onChange callback
  self:onChange(self.activeOptionValue, index)
end

function Select:selectNext()
  self:setValueByIndex(self.activeOptionIndex + 1, true)
end

function Select:selectPrev()
  self:setValueByIndex(self.activeOptionIndex - 1, true)
end

function Select:drawAt(x, y)
  Select.super.drawAt(self, x, y)

  local currValueLabel = self.optionShortLabels[self.activeOptionIndex]
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextInRect(currValueLabel, x, y + self.textY, self.w - 16, self.h, nil, '...', kTextAlignment.right)
  gfx.setImageDrawMode(0)

  if self.isOpen then
    self:drawMenu()
  end
end

function Select:drawMenu()
  -- use crank to scroll through options
  local crankChange = playdate.getCrankTicks(6)
  if crankChange ~= 0 then
    self:setValueByIndex(self.activeOptionIndex + crankChange, true)
  end
  -- draw select menu ui over everything
  utils:deferDraw(function ()
    local oX, oY = gfx.getDrawOffset()
    gfxUtils:drawBlackFade(self.bgFade)
    gfx.setDrawOffset(0, self.menuOpenShift)
    -- draw selection bg
    local menuX = MENU_X
    local menuY = MENU_Y - self.menuScroll
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
    gfx.setDrawOffset(oX, oY)
  end)
end

function Select:openMenu()
  if self.isOpen or self.openTransitionActive then return end

  local timer = playdate.timer.new(MENU_OPEN_DUR, 0, 1)
  local startPos = PLAYDATE_H

  self.openTransitionActive = true
  self.isOpen = true
  self.menuOpenShift = startPos

  timer.updateCallback = function ()
    self.bgFade = 0.5 - timer.value * 0.25
    self.menuOpenShift = startPos - playdate.easingFunctions.outBack(timer.value, 0, startPos, 1)
  end

  timer.timerEndedCallback = function ()
    self.bgFade = 0.25
    self.menuOpenShift = 0
    self.openTransitionActive = false
  end

  local keyTimer = nil

  playdate.inputHandlers.push({
    AButtonDown = function()
      self:closeMenu()
    end,
    BButtonDown = function()
      self:closeMenu()
    end,
    upButtonDown = function ()
      if keyTimer then
        keyTimer:remove()
        keyTimer = nil
      end
      keyTimer = playdate.timer.keyRepeatTimerWithDelay(350, 50, function ()
        self:selectPrev()
      end)
    end,
    upButtonUp = function()
      if keyTimer then
        keyTimer:remove()
        keyTimer = nil
      end
    end,
    downButtonDown = function ()
      if keyTimer then
        keyTimer:remove()
        keyTimer = nil
      end
      keyTimer = playdate.timer.keyRepeatTimerWithDelay(350, 50, function ()
        self:selectNext()
      end)
    end,
    downButtonUp = function()
      if keyTimer then
        keyTimer:remove()
        keyTimer = nil
      end
    end,
  }, true)
end

function Select:closeMenu()
  if (not self.isOpen) or self.openTransitionActive then return end

  self:onClose(self.activeOptionValue, self.activeOptionIndex)

  self.openTransitionActive = true
  self.menuOpenShift = 0

  local timer = playdate.timer.new(MENU_OPEN_DUR, 0, 1)

  timer.updateCallback = function ()
    self.bgFade = 0.5 - (1 - timer.value) * 0.25
    self.menuOpenShift = playdate.easingFunctions.inBack(timer.value, 0, PLAYDATE_H, 1)
  end

  timer.timerEndedCallback = function ()
    self.bgFade = 0.5
    self.menuOpenShift = PLAYDATE_H
    self:onCloseEnded(self.activeOptionValue, self.activeOptionIndex)
    utils:nextTick(function ()
      self.isOpen = false
      self.openTransitionActive = false
      playdate.inputHandlers.pop()
    end)
  end
end