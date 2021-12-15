dialog = {}

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

local okButton = nil
local cancelButton = nil
local confirmButton = nil

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
      dialog.handleClose()
      dialog:hide()
    end,
    BButtonDown = function ()
      dialog.handleClose()
      dialog:hide()
    end
  },
  confirm = {
    AButtonDown = function ()
      dialog.handleClose()
      dialog:hide()
    end,
    BButtonDown = function ()
      dialog:hide()
    end
  }
}

dialog.handleClose = function () end

function dialog:init()
  okButton = Button(PLAYDATE_W / 2 - 60, 0, 120, 32)
  okButton:setIcon(buttonAIcon)
  confirmButton = Button(PLAYDATE_W / 2 + 4, 0, 130, 32)
  confirmButton:setIcon(buttonAIcon)
  cancelButton = Button(PLAYDATE_W / 2 - 134, 0, 130, 32)
  cancelButton:setIcon(buttonBIcon)
end

function dialog:alert(text)
  dialog:show(text, 'alert')
end

function dialog:confirm(text)
  dialog:show(text, 'confirm')
end

function dialog:show(text, type)
  if dialog.isVisible or isTransitionActive then return end
  -- setup state
  currentType = type or 'alert'
  currentText = text
  _, currentTextHeight = gfx.getTextSizeForMaxWidth(text, PLAYDATE_W - 64, nil, font)
  dialog.isVisible = true
  -- setup buttons
  okButton:setText(locales:getText('DIALOG_OK'))
  cancelButton:setText(locales:getText('DIALOG_CANCEL'))
  confirmButton:setText(locales:getText('DIALOG_CONFIRM'))
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

function dialog:hide()
  if not dialog.isVisible or isTransitionActive then return end
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
    dialog.isVisible = false
    dialog.handleClose = function () end
    -- restore controls
    playdate.inputHandlers.pop()
  end
end

function dialog:update()
  if dialog.isVisible then
    local offsetX, offsetY = gfx.getDrawOffset()
    local textY = PLAYDATE_H / 2 - (currentTextHeight + 28 + 8) / 2
    local buttonY = textY + currentTextHeight + 16
    -- fade over background
    gfxUtils:drawBlackFade(bgFade)
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
    if currentType == 'alert' then
      okButton.y = buttonY
      okButton:draw()
    elseif currentType == 'confirm' then
      cancelButton.y = buttonY
      cancelButton:draw()
      confirmButton.y = buttonY
      confirmButton:draw()
    end

    gfx.setDrawOffset(offsetX, offsetY)
  end
end