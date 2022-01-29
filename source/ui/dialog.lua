local TRANSITION_DUR <const> = 250
local DIALOG_W <const> = PLAYDATE_W - 48
local DIALOG_H <const> = PLAYDATE_H - 48
local DIALOG_X <const> = (PLAYDATE_W - DIALOG_W) / 2
local DIALOG_Y <const> = (PLAYDATE_H - DIALOG_H) / 2

local dialogGfx = gfx.nineSlice.new('./gfx/shape_dialog', 8, 8, 2, 2)

dialog = spritelib.new()

dialog.kTypeAlert = 1
dialog.kTypeConfirm = 2

dialog.kResultOk = 1
dialog.kResultCancel = 2

dialog:setSize(PLAYDATE_W, PLAYDATE_H)
dialog:add()
dialog:setZIndex(1200)
dialog:setVisible(false)
dialog:setIgnoresDrawOffset(true)
dialog:moveTo(DIALOG_X, DIALOG_Y)
dialog:setSize(DIALOG_W, DIALOG_H)
dialog:setCenter(0, 0)

dialog.bgFade = 0
dialog.text = nil
dialog.textY = 0
dialog.type = nil
dialog.textHeight = 0

dialog.isTransitionActive = false
dialog.transitionTimer = nil

dialog.handleClose = function (status) end
dialog.handleCloseEnd = function (status) end

function dialog:init()
  local okButton = Button(PLAYDATE_W / 2, 0, 120, 38, locales:getText('DIALOG_OK'))
  okButton.autoWidth = true
  okButton:setIcon('./gfx/icon_button_a')
  okButton:setIgnoresDrawOffset(true)
  okButton:setAnchor('center', 'top')
  okButton:setZIndex(1300)
  okButton:setVisible(false)
  okButton:onClick(function()
    self:hide(dialog.kResultOk)
  end)

  local confirmButton = Button(PLAYDATE_W / 2 + 8, 0, 130, 38, locales:getText('DIALOG_CANCEL'))
  confirmButton:setIcon('./gfx/icon_button_a')
  confirmButton:setIgnoresDrawOffset(true)
  confirmButton:setAnchor('left', 'top')
  confirmButton:setZIndex(1300)
  confirmButton:setVisible(false)
  confirmButton:onClick(function()
    self:hide(dialog.kResultOk)
  end)

  local cancelButton = Button(PLAYDATE_W / 2 - 8, 0, 130, 38, locales:getText('DIALOG_CONFIRM'))
  cancelButton:setIcon('./gfx/icon_button_b')
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

function dialog:alert(text)
  dialog:show(text, dialog.kTypeAlert)
end

function dialog:confirm(text)
  dialog:show(text, dialog.kTypeConfirm)
end

function dialog:offsetBy(y)
  self:moveTo(self.ox, self.oy + y)
  for _, c in pairs(self.buttons) do
    c:offsetBy(0, y)
  end
end

function dialog:show(text, type)
  if self.isTransitionActive then return end
  self.type = type
  self.text = text
  -- calc text position
  local _, textH = gfx.getTextSizeForMaxWidth(text, self.width - 16, nil)
  local textSpace = DIALOG_H - 40
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
  else
    self.okButton:setVisible(true)
  end
  -- disable ipnut
  playdate.inputHandlers.push({}, true)
  -- setup transition
  self.isTransitionActive = true
  local transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  self:offsetBy(PLAYDATE_H)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self:offsetBy(PLAYDATE_H - playdate.easingFunctions.outBack(timer.value, 0, PLAYDATE_H, 1))
    overlayBg:setBlackFade(timer.value * 0.75)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    self:offsetBy(0)
    self.isTransitionActive = false
    overlayBg:setBlackFade(0.75)
    playdate.inputHandlers.pop()
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
    end
  end
end

function dialog:hide(result)
  if self.isTransitionActive then return end
  -- close callback
  dialog.handleClose(result)
  -- setup transition
  self.isTransitionActive = true
  local transitionTimer = playdate.timer.new(TRANSITION_DUR, 0, 1)
  -- on timer update
  transitionTimer.updateCallback = function (timer)
    self:offsetBy(playdate.easingFunctions.inBack(timer.value, 0, PLAYDATE_H, 1))
    overlayBg:setBlackFade((1 - timer.value) * 0.75)
  end
  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    overlayBg:setBlackFade(0)
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
    self:show(item.message, item.type)
  end
  doItem(seq[i])
end

function dialog:draw()
  local w, h = self.width, self.height
  dialogGfx:drawInRect(0, 0, w, h)
  gfx.drawTextInRect(self.text, 8, self.textY, w - 16, h - 16, nil, nil, kTextAlignment.center)
end