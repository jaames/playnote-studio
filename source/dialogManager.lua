import 'CoreLibs/graphics'
import 'CoreLibs/timer'

dialogManager = {}

local gfx <const> = playdate.graphics
local PLAYDATE_H <const> = 240
local TRANSITION_DUR <const> = 200

local font = gfx.font.new('./fonts/Asheville-Sans-14-Bold')
local fontFamily <const> = gfx.font.newFamily({
  [gfx.font.kVariantBold]   = './fonts/Asheville-Sans-14-Bold',
  [gfx.font.kVariantNormal] = './fonts/Asheville-Sans-14-Light'
})

local y = PLAYDATE_H
local bgFade = 0
local currentText = nil
local currentTextHeight = 0

local isTransitionActive = false
local transitionTimer = nil

local inputHandlers = {
  AButtonUp = function ()
    dialogManager:hide()
  end
}

dialogManager.handleClose = function () end

function dialogManager:show(text)
  if dialogManager.isVisible or isTransitionActive then return end
  -- setup state
  currentText = text
  _, currentTextHeight = gfx.getTextSizeForMaxWidth(text, 400 - 64, nil, font)
  dialogManager.isVisible = true
  -- disable input
  playdate.inputHandlers.push({}, true)
  -- setup transition
  isTransitionActive = true
  transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    y = 240 - playdate.easingFunctions.outBack(timer.value, 0, 240, 1)
    bgFade = math.max(0, timer.value - 0.5)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    y = 0
    bgFade = 0.5
    isTransitionActive = false
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(inputHandlers, true)
  end
end

function dialogManager:hide()
  if not dialogManager.isVisible or isTransitionActive then return end
  -- setup transition
  isTransitionActive = true
  transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    y = playdate.easingFunctions.inBack(timer.value, 0, 240, 1)
    bgFade = math.max(0, 0.5 - timer.value)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    y = 240
    bgFade = 0
    isTransitionActive = false
    dialogManager.isVisible = false
    dialogManager.handleClose()
    dialogManager.handleClose = function () end
    -- restore controls
    playdate.inputHandlers.pop()
  end
end

function dialogManager:update()
  if dialogManager.isVisible then
    -- fade over background
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(1 - bgFade, gfx.image.kDitherTypeBayer8x8)
    -- panel bg
    gfx.fillRect(0, 0, 400, 240)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(24, 24 + y, 400 - 48, 240 - 48, 8)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(28, 28 + y, 400 - 56, 240 - 56, 4)
    -- text
    gfx.setFontFamily(fontFamily)
    gfx.drawTextInRect(currentText, 32, (100 - (currentTextHeight / 2)) + y, 400 - 64, 240 - 64, nil, nil, kTextAlignment.center)
    -- button (TODO)
    -- gfx.fillRoundRect(200 - 64, 240 - 64 + y, 128, 24, 4)
  end
end