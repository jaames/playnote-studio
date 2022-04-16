local TRANSITION_DUR <const> = 350
local DIALOG_W <const> = PLAYDATE_W - 48
local DIALOG_H <const> = PLAYDATE_H - 48
local DIALOG_X <const> = (PLAYDATE_W - DIALOG_W) / 2
local DIALOG_Y <const> = (PLAYDATE_H - DIALOG_H) / 2

local dialogGfx = gfx.nineSlice.new('./gfx/shape_dialog', 8, 8, 2, 2)

dialog = spritelib.new()

dialog.kTypeAlert = 1
dialog.kTypeConfirm = 2
dialog.kTypeError = 3

dialog.kResultOk = 1
dialog.kResultCancel = 2

dialog:setSize(PLAYDATE_W, PLAYDATE_H)
dialog:add()
dialog:setZIndex(1200)
dialog:setVisible(false)
dialog:setIgnoresDrawOffset(true)
dialog:setCollisionsEnabled(false)
dialog:moveTo(DIALOG_X, DIALOG_Y)
dialog:setSize(DIALOG_W, DIALOG_H)
dialog:setCenter(0, 0)

dialog.text = nil
dialog.textY = 0
dialog.type = nil
dialog.textHeight = 0
dialog.hasNext = false
dialog.wasAlreadyOpened = false

dialog.isTransitionActive = false
dialog.transitionTimer = nil

dialog.handleClose = function (status) end
dialog.handleCloseEnd = function (status) end

function dialog:init()
  sounds:prepareSfxGroup('dialog', {
    'dialogOpen',
  })

  local okButton = Button(PLAYDATE_W / 2, 0, 100, 38, '%DIALOG_OK%')
  -- okButton.autoWidth = true
  okButton.textAlign = kTextAlignment.center
  okButton:setIcon('./gfx/icon_button_a')
  okButton:setIgnoresDrawOffset(true)
  okButton:setAnchor('center', 'top')
  okButton:setZIndex(1300)
  okButton:setVisible(false)
  okButton:onClick(function()
    self:hide(dialog.kResultOk)
  end)

  local confirmButton = Button(PLAYDATE_W / 2 + 8, 0, 120, 38, '%DIALOG_CONFIRM%')
  confirmButton:setPaddingStyle('narrow')
  confirmButton:setIcon('./gfx/icon_button_a')
  confirmButton.textAlign = kTextAlignment.center
  confirmButton:setIgnoresDrawOffset(true)
  confirmButton:setAnchor('left', 'top')
  confirmButton:setZIndex(1300)
  confirmButton:setVisible(false)
  confirmButton:onClick(function()
    self:hide(dialog.kResultOk)
  end)

  local cancelButton = Button(PLAYDATE_W / 2 - 8, 0, 120, 38, '%DIALOG_CANCEL%')
  cancelButton:setPaddingStyle('narrow')
  cancelButton:setIcon('./gfx/icon_button_b')
  cancelButton.textAlign = kTextAlignment.center
  cancelButton:setIgnoresDrawOffset(true)
  cancelButton:setAnchor('right', 'top')
  cancelButton:setZIndex(1300)
  cancelButton:setVisible(false)
  cancelButton:onClick(function()
    self:hide(dialog.kResultCancel)
  end)

  self.okButton = okButton
  self.confirmButton = confirmButton
  self.cancelButton = cancelButton
  self.ox = self.x
  self.oy = self.y
  self.buttons = {okButton, confirmButton, cancelButton}
end

function dialog:alert(text, delay)
  if delay ~= nil then
    playdate.timer.performAfterDelay(delay, function ()
      dialog:show(text, dialog.kTypeAlert)
    end)
  else
    dialog:show(text, dialog.kTypeAlert)
  end
end

function dialog:confirm(text, delay)
  if delay ~= nil then
    playdate.timer.performAfterDelay(delay, function ()
      dialog:show(text, dialog.kTypeConfirm)
    end)
  else
    dialog:show(text, dialog.kTypeConfirm)
  end
end

function dialog:error(text, delay)
  if delay ~= nil then
    playdate.timer.performAfterDelay(delay, function ()
      dialog:show(text, dialog.kTypeError)
    end)
  else
    dialog:show(text, dialog.kTypeError)
  end
end

function dialog:offsetBy(y)
  self:moveTo(self.ox, self.oy + y)
  for _, c in pairs(self.buttons) do
    c:offsetBy(0, y)
  end
end

function dialog:show(text, type)
  if self.isTransitionActive then return end

  if not self.wasAlreadyOpened then
    sounds:playSfx('dialogOpen')
    sounds:prepareSfxGroup('dialog:close', {
      'dialogDismissPositive',
      'dialogDismissNegative',
      'dialogDismissPositiveToOpen',
    })
  end
  self.wasAlreadyOpened = false

  self.hasNext = false
  self.type = type
  self.text = text
  -- calc text position
  gfx.setFontTracking(1)
  local _, textH = gfx.getTextSizeForMaxWidth(text, self.width - 16, nil)
  local textSpace = DIALOG_H
  if type ~= dialog.kTypeError then
    textSpace -= 40
  end
  self.textY = (textSpace / 2) - (textH / 2)
  -- mark dialog as visible
  self:setVisible(true)
  -- add button components to spritelib, set position, mark visible
  for _, c in pairs(self.buttons) do
    c:add()
    c:moveToY(self.textY + textH + 36)
  end
  if type == dialog.kTypeConfirm then
    self.confirmButton:setVisible(true)
    self.cancelButton:setVisible(true)
  elseif self.type == dialog.kTypeAlert then
    self.okButton:setVisible(true)
  end
  -- disable ipnut
  playdate.inputHandlers.push({}, true)
  -- setup transition
  spritelib.setAlwaysRedraw(true)
  self.isTransitionActive = true
  local transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  self:offsetBy(PLAYDATE_H)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self:offsetBy(PLAYDATE_H - playdate.easingFunctions.outBack(timer.value, 0, PLAYDATE_H, 1))
    overlay:setBlackFade(timer.value * 0.5)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self:offsetBy(0)
    self.isTransitionActive = false
    overlay:setBlackFade(0.5)
    playdate.inputHandlers.pop()
    utils:nextTick(function()
      spritelib.setAlwaysRedraw(false)
    end)
    if self.type == dialog.kTypeAlert then
      playdate.inputHandlers.push({
        AButtonDown = function ()
          self.okButton:click()
        end,
        BButtonDown = function ()
          self.okButton:click()
        end
      }, true)
    elseif self.type == dialog.kTypeConfirm then
      playdate.inputHandlers.push({
        AButtonDown = function ()
          self.confirmButton:click()
        end,
        BButtonDown = function ()
          self.cancelButton:click()
        end
      }, true)
    elseif self.type == dialog.kTypeError then
      playdate.inputHandlers.push({}, true)
    end
  end
end

function dialog:hide(result)
  if self.isTransitionActive then return end
  -- close callback
  dialog.handleClose(result)
  if self.hasNext and result == dialog.kResultOk then
    sounds:playSfx('dialogDismissPositiveToOpen')
  elseif result == dialog.kResultOk then
    sounds:playSfx('dialogDismissPositive')
    sounds:releaseSfxGroup('dialog:close')
  elseif result == dialog.kResultCancel then
    sounds:playSfx('dialogDismissNegative')
    sounds:releaseSfxGroup('dialog:close')
  end
  -- setup transition
  self.isTransitionActive = true
  local transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self:offsetBy(playdate.easingFunctions.inBack(timer.value, 0, PLAYDATE_H, 1))
    overlay:setBlackFade((1 - timer.value) * 0.5)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    overlay:setBlackFade(0)
    -- set final dialog position and mark invisible
    self:offsetBy(PLAYDATE_H)
    self:setVisible(false)
    -- remove and hide button components
    for _, c in pairs(self.buttons) do
      c:remove()
      c:setVisible(false)
    end
    self.handleCloseEnd(result)
    self.handleClose = function () end
    self.handleCloseEnd = function () end
    -- restore controls
    playdate.inputHandlers.pop()
    self.isTransitionActive = false
  end
end

function dialog:sequence(seq, fn)
  local i = 1
  local function doItem(item)
    if item == nil then
      if fn ~= nil then fn() end
      return
    end
    self.handleClose = function ()
      self.hasNext = i < #seq
    end
    self.handleCloseEnd = function (status)
      if status == dialog.kResultOk then
        i = i + 1
        if item.callback ~= nil then
          item.callback()
        end
        playdate.timer.performAfterDelay(200, function ()
          doItem(seq[i])
        end)
      end
    end
    self.wasAlreadyOpened = i > 1
    self:show(locales:replaceKeysInText(item.message), item.type)
  end
  doItem(seq[i])
end

function dialog:draw()
  local w, h = self.width, self.height
  dialogGfx:drawInRect(0, 0, w, h)
  gfx.setFontTracking(1)
  gfx.drawTextInRect(self.text, 8, self.textY, w - 16, h - 16, nil, nil, kTextAlignment.center)
end