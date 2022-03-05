screens = {}

local SCREENS = {}

local prevScreen = nil
local activeScreen = nil

local isTransitionActive = false
local drawTransition = nil

local screenHistory = {}
local transitionHistory = {}

local menu = playdate.getSystemMenu()
local menuItems = {}

local isEffectActive = false
local drawOffset = {0,0}
local moveX = 0
local moveY = 0

spritelib.setAlwaysRedraw(false)
spritelib.setBackgroundDrawingCallback(function (x, y, w, h)
  screens:drawBg(x, y, w, h)
end)

sounds:prepareSfxGroup('screen', {
  'navigationForward',
  'navigationBackward',
  'navigationNotAllowed',
})

screens.blockEffects = false

function screens:register(id, screenInst)
  SCREENS[id] = screenInst
  screenInst.id = id
  -- B button should return to the previous screen, globally
  if screenInst.inputHandlers.BButtonDown == nil then
    screenInst.inputHandlers.BButtonDown = function ()
      screens:pop()
    end
  end
end

function screens:push(id, transitionFn, backTransitionFn, ...)
  if not isTransitionActive then
    self:setScreen(id, transitionFn, ...)
    if #screenHistory > 0 then
      sounds:playSfx('navigationForward')
    end
    table.insert(screenHistory, activeScreen)
    table.insert(transitionHistory, backTransitionFn or transitionFn)
  end
end

function screens:pop()
  if not isTransitionActive and #screenHistory > 1 then
    table.remove(screenHistory)
    table.remove(transitionHistory)
    local lastSreen = screenHistory[#screenHistory]
    local lastTransition = transitionHistory[#transitionHistory]
    self:setScreen(lastSreen.id, lastTransition)
    sounds:playSfx('navigationBackward')
  else
    self:shakeX()
    sounds:playSfx('navigationNotAllowed')
  end
end

function screens:setScreen(id, transitionFn, ...)
  isTransitionActive = true

  local hasPrevScreen = activeScreen ~= nil
  prevScreen = activeScreen
  activeScreen = SCREENS[id]

  if hasPrevScreen then
    prevScreen:beforeLeave()
    if menuItems then
      for _, item in pairs(menuItems) do
        menu:removeMenuItem(item)
      end
    end
  end
  activeScreen:beforeEnter(...)
  -- TODO: something is wrong with changing draw offset mid-transition, this is the best i could do,,,
  -- disable and file a bug with panic sometime
  activeScreen:forceDrawOffset()

  menuItems = activeScreen:setupMenuItems(menu)

  drawTransition = transitionFn(prevScreen, activeScreen, function()
    if hasPrevScreen then prevScreen:afterLeave() end
    activeScreen:afterEnter()
    isTransitionActive = false
  end)
end

function screens:reloadCurrent(transitionFn, callbackFn)
  isTransitionActive = true

  activeScreen:afterLeave()
  activeScreen:beforeEnter()

  drawTransition = transitionFn(activeScreen, activeScreen, function()
    isTransitionActive = false
    callbackFn()
  end)
end

function screens:shakeX()
  if isEffectActive or self.blockEffects then return end

  local timer = playdate.timer.new(200, 0, 1)
  drawOffset[1], drawOffset[2] = gfx.getDrawOffset()
  isEffectActive = true
  moveX = 0
  moveY = 0
  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function (t)
    moveX = (playdate.graphics.perlin(t.value, 0, 0, 0) - 0.5) * 60
  end
  timer.timerEndedCallback = function ()
    moveX = 0
    utils:nextTick(function ()
      isEffectActive = false
      spritelib.setAlwaysRedraw(false)
    end)
  end
end

function screens:doBounce(updateCallback)
  if isEffectActive or self.blockEffects then return end

  local timer = playdate.timer.new(80, 0, 1, playdate.easingFunctions.inOutSine)
  timer.reverses = true

  drawOffset[1], drawOffset[2] = gfx.getDrawOffset()
  isEffectActive = true
  moveX = 0
  moveY = 0
  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function (t)
    updateCallback(t.value)
  end
  timer.timerEndedCallback = function (t)
    moveX = 0
    moveY = 0
    utils:nextTick(function ()
      isEffectActive = false
      spritelib.setAlwaysRedraw(false)
    end)
  end
end

function screens:bounceLeft()
  self:doBounce(function (value) moveX = value * 5 end)
end

function screens:bounceRight()
  self:doBounce(function (value) moveX = value * -5 end)
end

function screens:bounceUp()
  self:doBounce(function (value) moveY = value * 5 end)
end

function screens:bounceDown()
  self:doBounce(function (value) moveY = value * -5 end)
end

function screens:drawBg(x, y, w, h)
  if isTransitionActive then
    drawTransition()
  else
    activeScreen:drawBg(x, y, w, h)
  end
end

function screens:update()
  if not isTransitionActive then
    if isEffectActive then
      gfx.setDrawOffset(drawOffset[1] + moveX, drawOffset[2] + moveY)
    end
    activeScreen:update()
  end
end

function screens:newTransition(duration, initialState, transitionFn, easing)
  easing = easing or playdate.easingFunctions.linear
  return function(a, b, completedCallback)
    local timer = playdate.timer.new(duration, 0, 1, easing)
    local value = 0
    local state = {}

    local function drawFn()
      transitionFn(value, a, b, state)
    end

    -- redraw sprites on every frame until the transition is done
    spritelib.setAlwaysRedraw(true)

    if type(initialState) == 'function' then
      state = initialState(drawFn)
    elseif type(initialState) == 'table' then
      state = table.deepcopy(initialState)
    end

    timer.updateCallback = function ()
      value = timer.value
    end

    timer.timerEndedCallback = function ()
      value = 1
      -- sometimes (depends on easing and frame timing) transition values don't reach 1 before isTransitionActive is set to false, 
      -- leaving thigns hanging on the last frame. doing tthe completed callback on the next frame seems to fix this
      utils:nextTick(function ()
        value = 1
        completedCallback()
        spritelib.setAlwaysRedraw(false)
      end)
    end

    return drawFn
  end
end

function screens:newInOutTransition(duration, setup, inFn, outFn, easing)
  return self:newTransition(duration, setup, function (t, a, b, state)
    if t < 0.5 then
      inFn(t * 2, a, b, state)
    else
      outFn((t - 0.5) * 2, a, b, state)
    end
  end, easing)
end

screens.kTransitionNone = screens:newTransition(0, nil, function () end)

screens.kTransitionStartup = screens:newTransition(320, nil,
  function (t, a, b, state)
    if b ~= nil then
      if not b.active then
        b:enter()
      end
      b:drawBg(0, 0, PLAYDATE_W, PLAYDATE_H)
      overlayBg:setWhiteFade(1 - t)
    end
  end
)

screens.kTransitionFade = screens:newInOutTransition(300, {nextIn = false},
  function (t, a, b, state)
    a:drawBg(0, 0, PLAYDATE_W, PLAYDATE_H)
    overlayBg:setWhiteFade(t)
  end,
  function (t, a, b, state)
    if not state.nextIn then
      a:leave()
      b:enter()
      state.nextIn = true
    end
    b:drawBg(0, 0, PLAYDATE_W, PLAYDATE_H)
    overlayBg:setWhiteFade(1 - t)
  end
)