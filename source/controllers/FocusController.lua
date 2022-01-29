-- ported from: https://github.com/luke-chang/js-spatial-navigation/blob/master/spatial_navigation.js

FocusController = {}
class('FocusController').extends()

FocusController.kDirectionUp = 1
FocusController.kDirectionDown = 2
FocusController.kDirectionLeft = 3
FocusController.kDirectionRight = 4

function FocusController:init(screen)
  if screen ~= nil then
    self:connectScreen(screen)
  end
  self.straightOverlapThreshold = 0.5
  self.elements = {}
  self.selection = nil
  self.selectionRect = nil
  self.selectionCenter = nil
  self.selectionCenterRect = nil
  self.distanceFn = self:generateDistanceFunction()

  self.silenceNotAllowedSfx = false

  self.focusMoveCallback = function(sprite) end
  self.cantMoveCallback = function(dir) end
  self.clickCallback = function(selectedEl) end
end

function FocusController:setFocus(sprite)
  if sprite == self.selection then return end
  if self.selection then
    self.selection:unfocus()
  end
  sprite:focus()
  local rect = sprite:getBoundsRect()
  local center = rect:centerPoint()
  self.selection = sprite
  self.selectionRect = rect
  self.selectionCenter = center
  self.selectionCenterRect = playdate.geometry.rect.new(center.x, center.y, 0, 0)
  self:emitScreenHook('select:change', sprite, rect)
  sounds:playSfx('selectionChange')
  self.focusMoveCallback(sprite)
end

function FocusController:cantMove(direction)
  if not self.silenceNotAllowedSfx then
    sounds:playSfx('selectionNotAllowed')
  end
  self.cantMoveCallback(direction)
end

function FocusController:clickSelection()
  local selectedEl = self.selection
  if selectedEl and type(selectedEl.click) == 'function' then
    selectedEl:click()
  end
  self.clickCallback(selectedEl)
end

function FocusController:debugModeEnabled(enabled)
  if enabled then
    function playdate.debugDraw()
      if self.selectionRect then
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(3)
        gfx.drawRect(self.selectionRect)
      end
    end
  else
    function playdate.debugDraw() end
  end
end

function FocusController:partition(rects, targetRect)
  local threshold = self.straightOverlapThreshold
  local groups = {
    {}, {}, {},
    {}, {}, {},
    {}, {}, {}
  }
  for _, rect in pairs(rects) do

    local centerPoint = rect:centerPoint()
    local centerX, centerY = centerPoint:unpack()
    local x, y, groupId

    if centerX < targetRect.left then
      x = 0
    elseif centerX <= targetRect.right then
      x = 1
    else
      x = 2
    end

    if centerY < targetRect.top then
      y = 0
    elseif centerY <= targetRect.bottom then
      y = 1
    else
      y = 2
    end

    groupId = (y * 3 + x) + 1
    table.insert(groups[groupId], rect)

    if groupId == 1 or groupId == 3 or groupId == 7 or groupId == 9 then

      if rect.left <= targetRect.right - targetRect.width * threshold then
        if groupId == 3 then
          table.insert(groups[2], rect)
        elseif groupId == 9 then
          table.insert(groups[8], rect)
        end
      end

      if rect.right >= targetRect.left + targetRect.width * threshold then
        if groupId == 1 then
          table.insert(groups[2], rect)
        elseif groupId == 7 then
          table.insert(groups[8], rect)
        end
      end

      if rect.top <= targetRect.bottom - targetRect.height * threshold then
        if groupId == 7 then
          table.insert(groups[4], rect)
        elseif groupId == 9 then
          table.insert(groups[6], rect)
        end
      end

      if rect.bottom >= targetRect.top + targetRect.height * threshold then
        if groupId == 1 then
          table.insert(groups[4], rect)
        elseif groupId == 3 then
          table.insert(groups[6], rect)
        end
      end
    end
  end

  return groups
end

function FocusController:generateDistanceFunction()
  return {
    nearPlumbLineIsBetter = function(rect)
      local d
      local rectCenter = rect:centerPoint()
      local targetCenter = self.selectionCenter
      if rectCenter.x < targetCenter.x then
        d = targetCenter.x - rect.right
      else
        d = rect.left - targetCenter.x
      end
      return d < 0 and 0 or d
    end,
    nearHorizonIsBetter = function(rect)
      local d
      local rectCenter = rect:centerPoint()
      local targetCenter = self.selectionCenter
      if rectCenter.y < targetCenter.y then
        d = targetCenter.y - rect.bottom
      else
        d = rect.top - targetCenter.y
      end
      return d < 0 and 0 or d
    end,
    nearTargetLeftIsBetter = function(rect)
      local d
      local rectCenter = rect:centerPoint()
      local targetCenter = self.selectionCenter
      local targetRect = self.selectionRect
      if rectCenter.x < targetCenter.x then
        d = targetRect.left - rect.right
      else
        d = rect.left - targetRect.left
      end
      return d < 0 and 0 or d
    end,
    nearTargetTopIsBetter = function(rect)
      local d
      local rectCenter = rect:centerPoint()
      local targetCenter = self.selectionCenter
      local targetRect = self.selectionRect
      if rectCenter.y < targetCenter.y then
        d = targetRect.top - rect.bottom
      else
        d = rect.top - targetRect.top
      end
      return d < 0 and 0 or d
    end,
    topIsBetter = function(rect)
      return rect.top
    end,
    bottomIsBetter = function(rect)
      return -1 * rect.bottom
    end,
    leftIsBetter = function(rect)
      return rect.left
    end,
    rightIsBetter = function(rect)
      return -1 * rect.right
    end
  }
end

function FocusController:getPrioritizedRect(priorities)
  local destPriority = nil
  for _, prio in pairs(priorities) do
    if #prio.group > 0 then
      destPriority = prio
      break
    end
  end

  if destPriority == nil then
    return
  end

  local destDistance = destPriority.distance

  table.sort(destPriority.group, function(a, b)
    for _, distFn in pairs(destDistance) do
      local dist = distFn(a) - distFn(b)
      if dist ~= 0 then
        if dist < 0 then
          return true
        else
          return false
        end
      end
    end
    return false
  end)

  return destPriority.group[1]
end

function FocusController:navigate(direction)
  assert(direction)

  if #self.elements == 0 then
    self:cantMove()
    return
  end

  local rects = {}
  local rectMap = {}
  for _, element in pairs(self.elements) do
    local rect = element:getBoundsRect()
    table.insert(rects, rect)
    rectMap[rect] = element
  end

  local distanceFn = self.distanceFn
  local groups = self:partition(rects, self.selectionRect)
  local internalGroups = self:partition(groups[5], self.selectionCenterRect)

  local priorities
  if direction == FocusController.kDirectionLeft then
    priorities = {
      {
        group = table.combine(internalGroups[1], internalGroups[4], internalGroups[7]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = groups[4],
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = table.combine(groups[1], groups[7]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.rightIsBetter,
          distanceFn.nearTargetTopIsBetter
        }
      }
    }
  elseif direction == FocusController.kDirectionRight then
    priorities = {
      {
        group = table.combine(internalGroups[3], internalGroups[6], internalGroups[9]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = groups[6],
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = table.combine(groups[3], groups[9]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter,
          distanceFn.nearTargetTopIsBetter
        }
      }
    }
  elseif direction == FocusController.kDirectionUp then
    priorities = {
      {
        group = table.combine(internalGroups[1], internalGroups[2], internalGroups[3]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = groups[2],
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = table.combine(groups[1], groups[3]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.bottomIsBetter,
          distanceFn.nearTargetLeftIsBetter
        }
      }
    }
  elseif direction == FocusController.kDirectionDown then
    priorities = {
      {
        group = table.combine(internalGroups[7], internalGroups[8], internalGroups[9]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = groups[8],
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = table.combine(groups[7], groups[9]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter,
          distanceFn.nearTargetLeftIsBetter
        }
      }
    }
  end

  local nextRect = self:getPrioritizedRect(priorities)

  if nextRect then
    self:setFocus(rectMap[nextRect])
  else
    self:cantMove()
  end
end

function FocusController:connectScreen(screen)
  assert(type(screen.inputHandlers) == 'table', 'input handlers not a table')

  local inputHandlers = screen.inputHandlers

  local delay = 400
  local delayRepeat = 250

  local downButtonDown, downButtonUp, rmvRepeat1 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
    self.silenceNotAllowedSfx = isRepeat
    self:navigate(FocusController.kDirectionDown)
  end)
  local upButtonDown, upButtonUp, rmvRepeat2 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
    self.silenceNotAllowedSfx = isRepeat
    self:navigate(FocusController.kDirectionUp)
  end)
  local leftButtonDown, leftButtonUp, rmvRepeat3 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
    self.silenceNotAllowedSfx = isRepeat
    self:navigate(FocusController.kDirectionLeft)
  end)
  local rightButtonDown, rightButtonUp, rmvRepeat4 = utils:createRepeater(delay, delayRepeat, function (isRepeat)
    self.silenceNotAllowedSfx = isRepeat
    self:navigate(FocusController.kDirectionRight)
  end)

  inputHandlers.AButtonDown = utils:hookFn(inputHandlers.AButtonDown, function ()
    self:clickSelection()
  end)

  inputHandlers.downButtonDown = utils:hookFn(inputHandlers.downButtonDown, downButtonDown)
  inputHandlers.downButtonUp = utils:hookFn(inputHandlers.downButtonUp, downButtonUp)

  inputHandlers.upButtonDown = utils:hookFn(inputHandlers.upButtonDown, upButtonDown)
  inputHandlers.upButtonUp = utils:hookFn(inputHandlers.upButtonUp, upButtonUp)

  inputHandlers.leftButtonDown = utils:hookFn(inputHandlers.leftButtonDown, leftButtonDown)
  inputHandlers.leftButtonUp = utils:hookFn(inputHandlers.leftButtonUp, leftButtonUp)

  inputHandlers.rightButtonDown = utils:hookFn(inputHandlers.rightButtonDown, rightButtonDown)
  inputHandlers.rightButtonUp = utils:hookFn(inputHandlers.rightButtonUp, rightButtonUp)

  screen:addHook('sprites:setup', function ()
    self.elements = screen.selectableSprites
  end)

  screen:addHook('leave:before', function ()
    rmvRepeat1()
    rmvRepeat2()
    rmvRepeat3()
    rmvRepeat4()
  end)

  self.screen = screen
  screen.inputHandlers = inputHandlers
end

function FocusController:emitScreenHook(hook, ...)
  if self.screen then
    self.screen:emitHook(hook, ...)
  end
end