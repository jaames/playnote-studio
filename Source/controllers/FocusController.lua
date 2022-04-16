-- ported from: https://github.com/luke-chang/js-spatial-navigation/blob/master/spatial_navigation.js

FocusController = {}
class('FocusController').extends()

FocusController.kDirectionUp = 1
FocusController.kDirectionDown = 2
FocusController.kDirectionLeft = 3
FocusController.kDirectionRight = 4

local kPartitionNorthWest <const> = 1
local kPartitionNorth <const> = 2
local kPartitionNorthEast <const> = 3
local kPartitionWest <const> = 4
local kPartitionInternal <const> = 5
local kPartitionEast <const> = 6
local kPartitionSouthWest <const> = 7
local kPartitionSouth <const> = 8
local kPartitionSouthEast <const> = 9

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

  self.blockNavigationInDirection = {
    [FocusController.kDirectionUp] = false,
    [FocusController.kDirectionDown] = false,
    [FocusController.kDirectionLeft] = false,
    [FocusController.kDirectionRight] = false,
  }
  self.allowNavigation = true
  self.silenceNotAllowedSfx = false

  self.focusMoveCallback = function(sprite) end
  self.cantMoveCallback = function(dir) end
  self.clickCallback = function(selectedEl) end

  sounds:prepareSfxGroup('selection', {
    'selectionChange',
    'selectionNotAllowed',
  })
end

function FocusController:setFocus(sprite, muteSfx)
  if sprite == self.selection then return end
  if self.selection then
    self.selection:unfocus()
  end
  if sprite == nil then return end
  sprite:focus()
  local rect = sprite:getBoundsRect()
  local center = rect:centerPoint()
  self.selection = sprite
  self.selectionRect = rect
  self.selectionCenter = center
  self.selectionCenterRect = playdate.geometry.rect.new(center.x, center.y, 0, 0)
  self:emitScreenHook('select:change', sprite, rect)
  if not muteSfx then
    sounds:playSfx('selectionChange')
  end
  self.focusMoveCallback(sprite)
end

function FocusController:setFocusPure(sprite)
  if sprite == self.selection then return end
  if self.selection then
    self.selection:unfocus()
  end
  if sprite == nil then return end
  sprite:focus()
  local rect = sprite:getBoundsRect()
  local center = rect:centerPoint()
  self.selection = sprite
  self.selectionRect = rect
  self.selectionCenter = center
  self.selectionCenterRect = playdate.geometry.rect.new(center.x, center.y, 0, 0)
end

function FocusController:cantMove(direction)
  local override = self.cantMoveCallback(direction)
  if (not override == true) and (not self.silenceNotAllowedSfx) then
    if direction == FocusController.kDirectionLeft then
      sceneManager:bounceLeft()
    elseif direction == FocusController.kDirectionRight then
      sceneManager:bounceRight()
    elseif direction == FocusController.kDirectionUp then
      sceneManager:bounceUp()
    elseif direction == FocusController.kDirectionDown then
      sceneManager:bounceDown()
    end
    sounds:playSfx('selectionNotAllowed')
  end
end

function FocusController:clickSelection()
  local selectedEl = self.selection
  if selectedEl and type(selectedEl.click) == 'function' then
    selectedEl:click()
  end
  self.clickCallback(selectedEl)
end

function FocusController:add(element)
  if element.selectable == true then
    table.insert(self.elements, element)
  end
end

function FocusController:remove(element)
  table.remove(self.elements, table.indexOfElement(self.elements, element))
end

function FocusController:removeAll()
  local elements = self.elements
  for i = 1, #elements do
    elements[i] = nil
  end
  self.elements = {}
  self.selection = nil
  self.selectionRect = nil
  self.selectionCenter = nil
  self.selectionCenterRect = nil
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

    if groupId == kPartitionNorthWest or groupId == kPartitionNorthEast or groupId == kPartitionSouthWest or groupId == kPartitionSouthEast then

      if rect.left <= targetRect.right - targetRect.width * threshold then
        if groupId == kPartitionNorthEast then
          table.insert(groups[kPartitionNorth], rect)
        elseif groupId == kPartitionSouthEast then
          table.insert(groups[kPartitionSouth], rect)
        end
      end

      if rect.right >= targetRect.left + targetRect.width * threshold then
        if groupId == kPartitionNorthWest then
          table.insert(groups[kPartitionNorth], rect)
        elseif groupId == kPartitionSouthWest then
          table.insert(groups[kPartitionSouth], rect)
        end
      end

      if rect.top <= targetRect.bottom - targetRect.height * threshold then
        if groupId == kPartitionSouthWest then
          table.insert(groups[kPartitionWest], rect)
        elseif groupId == kPartitionSouthEast then
          table.insert(groups[kPartitionEast], rect)
        end
      end

      if rect.bottom >= targetRect.top + targetRect.height * threshold then
        if groupId == kPartitionNorthWest then
          table.insert(groups[kPartitionWest], rect)
        elseif groupId == kPartitionNorthEast then
          table.insert(groups[kPartitionEast], rect)
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

function FocusController:preventNavigationInDirections(...)
  for _, direction in pairs({...}) do
    self.blockNavigationInDirection[direction] = true
  end
end

function FocusController:allowNavigationInDirections(...)
  for _, direction in pairs({...}) do
    self.blockNavigationInDirection[direction] = false
  end
end

function FocusController:navigate(direction)
  assert(direction)

  if self.blockNavigationInDirection[direction] then
    return
  end

  if not self.allowNavigation then
    return
  end

  if #self.elements == 0 then
    self:cantMove(direction)
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
  local internalGroups = self:partition(groups[kPartitionInternal], self.selectionCenterRect)

  local priorities
  if direction == FocusController.kDirectionLeft then
    priorities = {
      {
        group = table.combine(internalGroups[kPartitionNorthWest], internalGroups[kPartitionWest], internalGroups[kPartitionSouthWest]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = groups[kPartitionWest],
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = table.combine(groups[kPartitionNorthWest], groups[kPartitionSouthWest]),
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
        group = table.combine(internalGroups[kPartitionNorthEast], internalGroups[kPartitionEast], internalGroups[kPartitionSouthEast]),
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = groups[kPartitionEast],
        distance = {
          distanceFn.nearPlumbLineIsBetter,
          distanceFn.topIsBetter
        }
      },
      {
        group = table.combine(groups[kPartitionNorthEast], groups[kPartitionSouthEast]),
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
        group = table.combine(internalGroups[kPartitionNorthWest], internalGroups[kPartitionNorth], internalGroups[kPartitionNorthEast]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = groups[kPartitionNorth],
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = table.combine(groups[kPartitionNorthWest], groups[kPartitionNorthEast]),
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
        group = table.combine(internalGroups[kPartitionSouthWest], internalGroups[kPartitionSouth], internalGroups[kPartitionSouthEast]),
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = groups[kPartitionSouth],
        distance = {
          distanceFn.nearHorizonIsBetter,
          distanceFn.leftIsBetter
        }
      },
      {
        group = table.combine(groups[kPartitionSouthWest], groups[kPartitionSouthEast]),
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
    self:cantMove(direction)
  end
end

function FocusController:connectScreen(screen)
  assert(type(screen.inputHandlers) == 'table', 'input handlers not a table')

  local inputHandlers = screen.inputHandlers

  local delay = 400
  local delayRepeat = 200

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

  screen:addHook('sprite:add', function (sprite)
    self:add(sprite)
  end)

  screen:addHook('sprite:remove', function (sprite)
    self:remove(sprite)
  end)

  screen:addHook('sprites:destroy', function (sprite)
    self:removeAll()
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