ScrollController = {}
class('ScrollController').extends()

function ScrollController:init(screen)
  self.start = 0
  self.offset = 0
  self.height = 0
  self.range = 0
  self.progress = 0

  self.autoScroll = false
  self.autoScrollStep = -1
  self.controlDrawOffset = true
  self.scrollBar = nil

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
  local oldOffset = self.offset
  self.offset = self:clampOffset(o)
  self.progress = -self.offset / self.range
  if not (self.offset == oldOffset) then
    self.updateCallback(self)
    if self.controlDrawOffset then
      gfx.setDrawOffset(0, self.offset)
      spritelib.redrawBackground()
    end
    if self.scrollBar ~= nil then
      self.scrollBar:setProgress(self.progress)
    end
  end
end

function ScrollController:animateToOffset(offset, duration, easing)
  if self.scrollAnimationActive then return end
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

function ScrollController:resetOffset()
  self:setOffset(self.start)
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
  self:setOffset(self.offset + math.floor(change))
  self.autoScroll = false
end

function ScrollController:connectScreen(screen)
  assert(type(screen.inputHandlers) == 'table', 'input handlers not a table')
  local inputHandlers = screen.inputHandlers
  local origCrankCallback = inputHandlers.cranked
  local hasOrigCrankCallback = type(origCrankCallback) == 'function'
  inputHandlers.cranked = function(c, ac)
    if hasOrigCrankCallback then
      origCrankCallback(c, ac)
    end
    self:crankHandler(c, ac)
  end
  screen.inputHandlers = inputHandlers
end


function ScrollController:connectScrollBar(scrollBar)
  self.scrollBar = scrollBar
  scrollBar:setProgress(self.progress)
end