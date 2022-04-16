sceneManager = {}

local registeredScenes = {}

local activeScene = nil

local isSceneTransitionActive = false
local transitionDrawFn = nil

local sceneHistory = {}
local transitionHistory = {}

local systemMenu = playdate.getSystemMenu()
local systemMenuItems = {}

local isScreenEffectActive = false
local screenEffectMoveX = 0
local screenEffectMoveY = 0

spritelib.setAlwaysRedraw(false)
spritelib.setBackgroundDrawingCallback(function (x, y, w, h)
  sceneManager:drawBg(x, y, w, h)
end)

sounds:prepareSfxGroup('screen', {
  'navigationForward',
  'navigationBackward',
  'navigationNotAllowed',
})

sceneManager.blockEffects = false

function sceneManager:register(scenes)
  for name, SceneClass in pairs(scenes) do
    self:registerScene(name, SceneClass)
  end
end

function sceneManager:registerScene(id, SceneClass)
  local sceneInst = SceneClass()
  registeredScenes[id] = sceneInst
  sceneInst.id = id
  -- B button should return to the previous screen, globally
  if sceneInst.inputHandlers.BButtonDown == nil then
    sceneInst.inputHandlers.BButtonDown = function ()
      sceneManager:pop()
    end
  end
end

function sceneManager:push(id, transitionFn, backTransitionFn, ...)
  if not isSceneTransitionActive then
    local nextScene = registeredScenes[id]
    self:_switchScene(nextScene, transitionFn, ...)
    if #sceneHistory > 0 then
      sounds:playSfx('navigationForward')
    end
    table.insert(sceneHistory, nextScene)
    table.insert(transitionHistory, backTransitionFn or transitionFn)
  end
end

function sceneManager:pop()
  if not isSceneTransitionActive and #sceneHistory > 1 then
    table.remove(sceneHistory)
    table.remove(transitionHistory)
    local lastScene = sceneHistory[#sceneHistory]
    local lastTransition = transitionHistory[#transitionHistory]
    self:_switchScene(lastScene, lastTransition)
    sounds:playSfx('navigationBackward')
  else
    self:shakeX()
    sounds:playSfx('navigationNotAllowed')
  end
end

function sceneManager:_switchScene(nextScene, transitionFn, ...)
  isSceneTransitionActive = true

  local prevScene = activeScene

  self:_sceneBeforeLeave(prevScene)
  self:_sceneBeforeEnter(nextScene, ...)

  transitionDrawFn = transitionFn(prevScene, nextScene, function()
    self:_sceneAfterLeave(prevScene)
    self:_sceneAfterEnter(nextScene)
    isSceneTransitionActive = false
  end)
end

function sceneManager:_sceneBeforeEnter(scene, ...)
  -- add sprites for the current scene
  if not scene.areSpritesSetup then
    scene.areSpritesSetup = true
    local sprites = scene:setupSprites()
    for i = 1, #sprites do
      scene:addSprite(sprites[i])
    end
  end
  systemMenuItems = scene:setupMenuItems(systemMenu)
  scene:_addToDisplayList()
  scene:beforeEnter(...)
  scene:emitHook('enter:before')
end

function sceneManager:_screenEnter(scene)
  activeScene = scene
  scene.active = true
  scene:setSpritesVisible(true)
  scene:forceDrawOffset()
  scene:enter()
  scene:emitHook('enter')
end

function sceneManager:_sceneAfterEnter(scene)
  playdate.inputHandlers.push(scene.inputHandlers, true)
  scene:afterEnter()
  scene:emitHook('enter:after')
end

function sceneManager:_sceneBeforeLeave(scene)
  if scene then
    playdate.inputHandlers.pop()
    scene:beforeLeave()
    if systemMenuItems then
      for _, item in pairs(systemMenuItems) do
        systemMenu:removeMenuItem(item)
      end
    end
    scene:emitHook('leave:before')
  end
end

function sceneManager:_screenLeave(scene)
  if scene then
    scene.active = false
    scene:setSpritesVisible(false)
    scene:leave()
    scene:emitHook('leave')
  end
end

function sceneManager:_sceneAfterLeave(scene)
  if scene then
    scene:_removeFromDisplayList()
    scene:afterLeave()
    scene:emitHook('leave:after')
  end
end

function sceneManager:reloadCurrent(transitionFn, callbackFn)
  isSceneTransitionActive = true

  self:_sceneAfterLeave(activeScene)
  self:_sceneBeforeEnter(activeScene)

  transitionDrawFn = transitionFn(activeScene, activeScene, function()
    isSceneTransitionActive = false
    callbackFn()
  end)
end

function sceneManager:shakeX()
  if isScreenEffectActive or self.blockEffects then return end

  local timer = playdate.timer.new(200, 0, 1)
  isScreenEffectActive = true
  screenEffectMoveX = 0
  screenEffectMoveY = 0
  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function (t)
    screenEffectMoveX = (playdate.graphics.perlin(t.value, 0, 0, 0) - 0.5) * 60
  end
  timer.timerEndedCallback = function ()
    screenEffectMoveX = 0
    utils:nextTick(function ()
      isScreenEffectActive = false
      spritelib.setAlwaysRedraw(false)
    end)
  end
end

function sceneManager:doBounce(updateCallback)
  if isScreenEffectActive or self.blockEffects then return end

  local timer = playdate.timer.new(80, 0, 1, playdate.easingFunctions.inOutSine)
  timer.reverses = true

  isScreenEffectActive = true
  screenEffectMoveX = 0
  screenEffectMoveY = 0
  spritelib.setAlwaysRedraw(true)

  timer.updateCallback = function (t)
    updateCallback(t.value)
  end
  timer.timerEndedCallback = function (t)
    screenEffectMoveX = 0
    screenEffectMoveY = 0
    utils:nextTick(function ()
      isScreenEffectActive = false
      spritelib.setAlwaysRedraw(false)
    end)
  end
end

function sceneManager:bounceLeft()
  self:doBounce(function (value) screenEffectMoveX = value * 5 end)
end

function sceneManager:bounceRight()
  self:doBounce(function (value) screenEffectMoveX = value * -5 end)
end

function sceneManager:bounceUp()
  self:doBounce(function (value) screenEffectMoveY = value * 5 end)
end

function sceneManager:bounceDown()
  self:doBounce(function (value) screenEffectMoveY = value * -5 end)
end

function sceneManager:drawBg(x, y, w, h)
  if activeScene then
    activeScene:drawBg(x, y, w, h)
  end
end

function sceneManager:update()
  if isSceneTransitionActive then
    transitionDrawFn()
  else
    if isScreenEffectActive then
      gfx.setDrawOffset(activeScene.drawOffsetX + screenEffectMoveX, activeScene.drawOffsetY + screenEffectMoveY)
    end
    activeScene:update()
  end
end

function sceneManager:_makeTransition(duration, initialState, transitionFn)

  return function(a, b, completedCallback)
    local timer = playdate.timer.new(duration, 0, 1)
    local value = 0
    local state = {}

    local function drawFn()
      transitionFn(value, a, b, state)
    end

    if type(initialState) == 'function' then
      state = initialState(drawFn)
    elseif type(initialState) == 'table' then
      state = table.deepcopy(initialState)
    end

    timer.updateCallback = function ()
      value = timer.value
      if a then a:updateTransitionOut(value, b) end
      b:updateTransitionIn(value, a)
    end

    timer.timerEndedCallback = function ()
      value = 1
      if a then a:updateTransitionOut(value, b) end
      b:updateTransitionIn(value, a)
      -- sometimes (depends on easing and frame timing) transition values don't reach 1 before isTransitionActive is set to false,
      -- calling drawFn once more seems to fix this
      drawFn()
      completedCallback()
    end

    return drawFn
  end
end

function sceneManager:_makeInOutTransition(duration, setup, inFn, outFn)
  return self:_makeTransition(duration, setup, function (t, a, b, state)
    if t < 0.5 then
      inFn(t * 2, a, b, state)
    else
      outFn((t - 0.5) * 2, a, b, state)
    end
  end)
end

sceneManager.kTransitionNone = sceneManager:_makeTransition(0, nil, function () end)

sceneManager.kTransitionStartup = sceneManager:_makeTransition(650, nil,
  function (t, a, b, state)
    if not b.active then
      sceneManager:_screenEnter(b)
    end
    overlay:setWhiteFade((0.8 - t))
  end
)

sceneManager.kTransitionFade = sceneManager:_makeInOutTransition(420, {nextIn = false},
  function (t, a, b, state)
    overlay:setWhiteFade(t)
  end,
  function (t, a, b, state)
    if not state.nextIn then
      sceneManager:_screenLeave(a)
      sceneManager:_screenEnter(b)
      state.nextIn = true
    end
    overlay:setWhiteFade(1 - t)
  end
)