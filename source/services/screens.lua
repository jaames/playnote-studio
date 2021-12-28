screens = {}

local SCREENS = {}

local prevScreen = nil
local activeScreen = nil

local isTransitionActive = false

local screenHistory = {}
local transitionHistory = {}

local isShakeActive = false
local moveX = 0
local moveY = 0

function screens:register(id, screenInst)
  SCREENS[id] = screenInst
  screenInst.id = id
end

function screens:push(id, transitionFn, backTransitionFn)
  if not isTransitionActive then
    self:setScreen(id, transitionFn)
    table.insert(screenHistory, activeScreen)
    table.insert(transitionHistory, backTransitionFn or transitionFn)
  end
end

function screens:goBack()
  if not isTransitionActive and #screenHistory > 1 then
    table.remove(screenHistory)
    table.remove(transitionHistory)
    local lastSreen = screenHistory[#screenHistory]
    local lastTransition = transitionHistory[#transitionHistory]
    self:setScreen(lastSreen.id, lastTransition)
  else
    self:shakeX()
  end
end

function screens:setScreen(id, transitionFn)
  isTransitionActive = true

  local hasPrevScreen = activeScreen ~= nil
  prevScreen = activeScreen
  activeScreen = SCREENS[id]

  if hasPrevScreen then prevScreen:beforeLeave() end
  activeScreen:beforeEnter()

  transitionFn(prevScreen, activeScreen, function()
    if hasPrevScreen then prevScreen:afterLeave() end
    activeScreen:afterEnter()
    isTransitionActive = false
  end)
end

function screens:reloadCurrent(transitionFn)
  isTransitionActive = true

  activeScreen:afterLeave()
  activeScreen:beforeEnter()

  transitionFn(activeScreen, activeScreen, function()
    isTransitionActive = false
  end)
end

function screens:shakeX()
  if isShakeActive then return end

  local timer = playdate.timer.new(200, 0, 1)
  isShakeActive = true
  moveX = 0
  moveY = 0

  timer.updateCallback = function (t)
    moveX = (playdate.graphics.perlin(t.value, 0, 0, 0) - 0.5) * 40
  end
  timer.timerEndedCallback = function ()
    moveX = 0
    utils:nextTick(function ()
      isShakeActive = false
    end)
  end
end

function screens:update()
  if not isTransitionActive then
    if isShakeActive then
      playdate.graphics.setDrawOffset(moveX, moveY)
    end
    activeScreen:update()
  end
end