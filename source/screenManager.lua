import 'CoreLibs/graphics'
import 'CoreLibs/timer'

screenManager = {}

local SCREENS = {}

local activeScreenId = nil
local activeScreen = nil

local isTransitionActive = false
local prevScreenId = nil
local prevScreen = nil

local transitionTimer = nil

function screenManager:registerScreen(id, screen)
  SCREENS[id] = screen
end

function screenManager:setScreen(id)
  if isTransitionActive then
    print('page transition already active!!!')
    return
  end
  local hasPrevScreen = not (activeScreen == nil)
  prevScreenId = activeScreenId
  prevScreen = activeScreen
  activeScreenId = id
  activeScreen = SCREENS[id]

  isTransitionActive = true
  if hasPrevScreen then prevScreen:beforeLeave() end
  activeScreen:beforeEnter()

  -- create transition timer
  local props = activeScreen:getTransitionProps(prevScreenId)
  transitionTimer = playdate.timer.new(props['duration'], 0, 1, props['easing'])

  -- on timer update
  transitionTimer.updateCallback = function (timer)
    if hasPrevScreen then prevScreen:transitionLeave(timer.value, activeScreenId) end
    activeScreen:transitionEnter(timer.value, prevScreenId)
  end

  -- page transition is done
  transitionTimer.timerEndedCallback = function ()
    if hasPrevScreen then prevScreen:transitionLeave(1, activeScreenId) end
    activeScreen:transitionEnter(1, prevScreenId)
    if hasPrevScreen then prevScreen:afterLeave() end
    activeScreen:afterEnter()
    isTransitionActive = false
  end

end

function screenManager:update()
  if not isTransitionActive then
    activeScreen:update()
  end
end

-- -- allow current screen to save anything if the game is about to be closed
-- function playdate.gameWillTerminate()
--   activeScreen:beforeLeave()
--   activeScreen:afterLeave()
-- end
-- -- and when the device is about to be locked
-- function playdate.deviceWillLock()
--   activeScreen:beforeLeave()
--   activeScreen:afterLeave()
-- end