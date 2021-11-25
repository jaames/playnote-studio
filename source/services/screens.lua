import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'transitions.lua'

screenManager = {}

local SCREENS = {}

local prevScreen = nil
local activeScreen = nil

local isTransitionActive = false

screenManager.CROSSFADE = CrossfadeTransition
screenManager.BOOTUP = BootupTransition

function screenManager:registerScreen(id, screen)
  SCREENS[id] = screen
end

function screenManager:setScreen(id, Transition)
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

function screenManager:update()
  if not isTransitionActive then
    activeScreen:update()
  end
end