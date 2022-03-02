ScrollController = {}
class('ScrollController').extends()

ScrollController.kModeKeepOnScreen = 1
ScrollController.kModeKeepCenter = 2

function ScrollController:init(screen)
  self.screen = screen

  self.start = 0
  self.offset = 0
  self.height = 0
  self.range = 0
  self.progress = 0

  self.autoScroll = false
  self.autoScrollStep = -1
  self.controlDrawOffset = true
  self.scrollBar = nil

  self.selectionMode = ScrollController.kModeKeepOnScreen
  self.selectionAnimation = true
  self.selectionAnimationDuration = 200
  self.selectionAnimationEasing = playdate.easingFunctions.inCubic

  self.scrollAnimationActive = false

  self.updateCallback = function(scroll) end

  if screen ~= nil then
    self:connectScreen(screen)
  end
end

function ScrollController:setStart(s)
  self.start = s
  -- self:setOffset(s)
end

function ScrollController:setHeight(h)
  self.height = h
  self.range = h - PLAYDATE_H
end

function ScrollController:setOffset(o)
  self.offset = self:clampOffset(o)
  self.progress = -self.offset / self.range
  self.updateCallback(self)
  if self.controlDrawOffset then
    self.screen:setDrawOffset(0, self.offset)
  end
  if self.scrollBar ~= nil then
    self.scrollBar:setProgress(self.progress)
  end
end

function ScrollController:animateToOffset(offset, duration, easing)
  -- if self.scrollAnimationActive then return end
  self.scrollAnimationActive = true
  local endOffset = self:clampOffset(offset)
  local timer = playdate.timer.new(duration, self.offset, endOffset, easing)
  timer.updateCallback = function ()
    self:setOffset(timer.value)
  end
  timer.timerEndedCallback = function ()
    self:setOffset(endOffset)
    self.scrollAnimationActive = false
  end
end

function ScrollController:scrollToSelection(rect)
  local newOffset

  if self.selectionMode == ScrollController.kModeKeepOnScreen then
    if rect.top + self.offset < 0 then
      newOffset = -rect.top
    elseif rect.bottom + self.offset > PLAYDATE_H then
      newOffset = -(rect.bottom - PLAYDATE_H)
    end

  elseif self.selectionMode == ScrollController.kModeKeepCenter then
    newOffset = -(rect.top - (PLAYDATE_H / 2) + (rect.height / 2))
  end

  if newOffset ~= nil then
    if self.selectionAnimation then
      self:animateToOffset(newOffset, self.selectionAnimationDuration, self.selectionAnimationEasing)
    else
      self:setOffset(newOffset)
    end
  end
end

function ScrollController:resetOffset()
  self.offset = self.start
  self.progress = -self.offset / self.range
  self.screen.offsetY = self.offset
  if self.scrollBar ~= nil then
    self.scrollBar:setProgress(self.progress)
  end
end

function ScrollController:clampOffset(o)
  if o <= -self.range then
    return -self.range
  elseif o >= self.start then
    return self.start
  end
  return o
end

function ScrollController:update()
  if self.autoScroll then
    self:setOffset(self.offset + self.autoScrollStep)
  end
end

function ScrollController:crankHandler(change, acceleratedChange)
  self:setOffset(self.offset + math.floor(change)) -- math.floor important for avoiding rounding issues when drawing bg grid
  self.autoScroll = false
end

function ScrollController:connectScreen(screen)
  assert(type(screen.inputHandlers) == 'table', 'input handlers not a table')

  screen:addHook('select:change', function (sprite, rect)
    self:scrollToSelection(rect)
  end)

  local inputHandlers = screen.inputHandlers
  inputHandlers.cranked = utils:hookFn(inputHandlers.cranked, function (c, ac)
    self:crankHandler(c, ac)
  end)

  self.screen = screen
  screen.inputHandlers = inputHandlers
end

function ScrollController:connectScrollBar(scrollBar)
  self.scrollBar = scrollBar
  scrollBar:setProgress(self.progress)
end