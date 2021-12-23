dialog = {}

local gfx <const> = playdate.graphics
local PLAYDATE_W <const> = 400
local PLAYDATE_H <const> = 240
local TRANSITION_DUR <const> = 250

local dialogGfx = gfx.nineSlice.new('./gfx/shape_dialog', 8, 8, 2, 2)
local buttonAIcon = gfx.image.new('./gfx/icon_button_a')
local buttonBIcon = gfx.image.new('./gfx/icon_button_b')

local okButton = nil
local cancelButton = nil
local confirmButton = nil

local y = PLAYDATE_H
local bgFade = 0.5
local currentText = nil
local currentType = nil
local currentTextHeight = 0

local isVisible = false
local isTransitionActive = false
local transitionTimer = nil

local inputHandlers = {
  alert = {
    AButtonDown = function ()
      okButton:click()
      dialog:hide('ok')
    end,
    BButtonDown = function ()
      okButton:click()
      dialog:hide('ok')
    end
  },
  confirm = {
    AButtonDown = function ()
      confirmButton:click()
      dialog:hide('ok')
    end,
    BButtonDown = function ()
      cancelButton:click()
      dialog:hide('cancel')
    end
  }
}

dialog.handleClose = function (status) end
dialog.handleCloseEnd = function (status) end

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
  if isVisible or isTransitionActive then return end
  -- setup state
  currentType = type or 'alert'
  currentText = text
  _, currentTextHeight = gfx.getTextSizeForMaxWidth(text, PLAYDATE_W - 64, nil, font)
  isVisible = true
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

function dialog:hide(status)
  if not isVisible or isTransitionActive then return end
  -- close callback
  dialog.handleClose(status)
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
    isVisible = false
    dialog.handleCloseEnd(status)
    dialog.handleClose = function () end
    dialog.handleCloseEnd = function () end
    -- restore controls
    playdate.inputHandlers.pop()
  end
end

function dialog:sequence(seq, fn)
  local i = 1
  local function doItem(item)
    if item == nil then
      if fn ~= nil then fn() end
      return
    end
    self.handleCloseEnd = function (status)
      if status == 'ok' then
        utils:nextTick(function ()
          i = i + 1
          if item.callback ~= nil then item.callback() end
          playdate.timer.performAfterDelay(200, function () doItem(seq[i]) end)
        end)
      end
    end
    if item.type == 'alert' then
      self:alert(item.message)
    elseif item.type == 'confirm' then
      self:confirm(item.message)
    end
  end
  doItem(seq[i])
end

function dialog:update()
  if isVisible then
    local offsetX, offsetY = gfx.getDrawOffset()
    local textY = PLAYDATE_H / 2 - (currentTextHeight + 28 + 8) / 2
    local buttonY = textY + currentTextHeight + 16
    -- fade over background
    gfxUtils:drawBlackFade(bgFade)
    -- transform based on transition progress
    gfx.setDrawOffset(0, y)
    -- panel bg
    dialogGfx:drawInRect(24, 24, PLAYDATE_W - 48, PLAYDATE_H - 48)
    -- text
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
    -- reset offset
    gfx.setDrawOffset(offsetX, offsetY)
  end
end