dialogManager = {}

local gfx <const> = playdate.graphics
local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local TRANSITION_DUR <const> = 250

local font = gfx.font.new('./fonts/Asheville-Sans-14-Bold')
local fontFamily = {
  [gfx.font.kVariantBold]   = gfx.font.new('./fonts/WhalesharkSans'),
  [gfx.font.kVariantNormal] = gfx.getSystemFont(gfx.font.kVariantNormal)
}

local buttonAIcon = gfx.image.new('./img/button_a')
local buttonBIcon = gfx.image.new('./img/button_b')

local y = PLAYDATE_H
local bgFade = 0
local currentText = nil
local currentType = nil
local currentTextHeight = 0

local isTransitionActive = false
local transitionTimer = nil

local inputHandlers = {
  alert = {
    AButtonDown = function ()
      dialogManager.handleClose()
      dialogManager:hide()
    end,
    BButtonDown = function ()
      dialogManager.handleClose()
      dialogManager:hide()
    end
  },
  confirm = {
    AButtonDown = function ()
      dialogManager.handleClose()
      dialogManager:hide()
    end,
    BButtonDown = function ()
      dialogManager:hide()
    end
  }
}

dialogManager.handleClose = function () end

function dialogManager:alert(text)
  dialogManager:show(text, 'alert')
end

function dialogManager:confirm(text)
  dialogManager:show(text, 'confirm')
end

function dialogManager:show(text, type)
  if dialogManager.isVisible or isTransitionActive then return end
  -- setup state
  currentType = type or 'alert'
  currentText = text
  _, currentTextHeight = gfx.getTextSizeForMaxWidth(text, PLAYDATE_W - 64, nil, font)
  dialogManager.isVisible = true
  -- disable input
  playdate.inputHandlers.push({}, true)
  -- setup transition
  isTransitionActive = true
  transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  y = PLAYDATE_H
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    y = PLAYDATE_H - playdate.easingFunctions.outBack(timer.value, 0, PLAYDATE_H, 1)
    bgFade = 0.5 - timer.value * 0.25
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    y = 0
    bgFade = 0.25
    isTransitionActive = false
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(inputHandlers[currentType], true)
  end
end

function dialogManager:hide()
  if not dialogManager.isVisible or isTransitionActive then return end
  -- setup transition
  isTransitionActive = true
  transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    y = playdate.easingFunctions.inBack(timer.value, 0, PLAYDATE_H, 1)
    bgFade = 0.5 - (1 - timer.value) * 0.25
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    y = PLAYDATE_H
    bgFade = 0.5
    isTransitionActive = false
    dialogManager.isVisible = false
    dialogManager.handleClose = function () end
    -- restore controls
    playdate.inputHandlers.pop()
  end
end

function dialogManager:update()
  if dialogManager.isVisible then
    local offsetX, offsetY = gfx.getDrawOffset()
    local textY = PLAYDATE_H / 2 - (currentTextHeight + 28 + 8) / 2
    local buttonY = textY + currentTextHeight + 16
    -- fade over background
    gfxUtils:drawWhiteFade(bgFade)
    -- gfx.setDrawOffset(0, 0)
    -- gfx.setColor(gfx.kColorBlack)
    -- gfx.setDitherPattern(1 - bgFade, gfx.image.kDitherTypeBayer8x8)
    -- panel bg
    gfx.setDrawOffset(0, y)
    gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(24, 24, PLAYDATE_W - 48, PLAYDATE_H - 48, 8)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(28, 28, PLAYDATE_W - 56, PLAYDATE_H - 56, 4)
    -- text
    gfx.setFontFamily(fontFamily)
    gfx.drawTextInRect(currentText, 32, textY, PLAYDATE_W - 64, PLAYDATE_H - 64, nil, nil, kTextAlignment.center)
    -- buttons
    -- if currentType == 'alert' then
    --   gfxUtils:drawButtonWithTextAndIcon('OK',      buttonAIcon, PLAYDATE_W / 2 - 60,  buttonY, 120, 32, false)
    -- elseif currentType == 'confirm' then
    --   gfxUtils:drawButtonWithTextAndIcon('Cancel',  buttonBIcon, PLAYDATE_W / 2 - 124, buttonY, 120, 32, false)
    --   gfxUtils:drawButtonWithTextAndIcon('Confirm', buttonAIcon, PLAYDATE_W / 2 + 4,   buttonY, 120, 32, false)
    -- end

    gfx.setDrawOffset(offsetX, offsetY)
  end
end