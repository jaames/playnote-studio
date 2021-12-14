screens = {}

local SCREENS = {}

local prevScreen = nil
local activeScreen = nil

local isTransitionActive = false

local screenHistory = {}
local transitionHistory = {}

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
    -- can't go back
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

function screens:update()
  if not isTransitionActive then
    activeScreen:update()
  end
end