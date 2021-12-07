screens = {}

local SCREENS = {}

local prevScreen = nil
local activeScreen = nil

local isTransitionActive = false

function screens:register(id, screenInst)
  SCREENS[id] = screenInst
  screenInst.id = id
end

function screens:setScreen(id, Transition)
  if isTransitionActive then
    print('Page transition already active!!!')
    return
  end

  isTransitionActive = true

  local hasPrevScreen = activeScreen ~= nil
  prevScreen = activeScreen
  activeScreen = SCREENS[id]
  
  if hasPrevScreen then prevScreen:beforeLeave() end
  activeScreen:beforeEnter()

  Transition(prevScreen, activeScreen, function()
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