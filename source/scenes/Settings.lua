local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_settings')

local ITEM_WIDTH <const> = 304
local ITEM_HEIGHT <const> = 54
local MENU_GAP_TOP <const> = 24
local MENU_GAP_BOTTOM <const> = 24

SettingsScreen = {}
class('SettingsScreen').extends(ScreenBase)

function SettingsScreen:init()
  SettingsScreen.super.init(self)
  self.scroll = ScrollController(self)
  self.scroll.selectionMode = ScrollController.kModeKeepCenter
  self.focus = FocusController(self)
  self.focus:preventNavigationInDirections(FocusController.kDirectionLeft, FocusController.kDirectionRight)
  self.bgPos = 0
end

function SettingsScreen:setupSprites()
  local scrollBar = ScrollBar(PLAYDATE_W - 26, MENU_GAP_TOP, PLAYDATE_H - MENU_GAP_TOP - MENU_GAP_BOTTOM)
  self.scroll:connectScrollBar(scrollBar)

  local layout = AutoLayout(16, 0, AutoLayout.kDirectionColumn, ITEM_WIDTH)
  self.layout = layout

  -- about button
  local about = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_ABOUT%')
  about:setPaddingStyle('wide')
  about:setIcon('./gfx/icon_about')
  about:onClick(function ()
    dialog:alert(''
      .. '*Playnote Studio*\n'
      .. 'https://playnote.studio\n'
      .. '\n'
      .. locales:getTextFormatted('ABOUT_VERSION', playdate.metadata.version) .. '\n'
      .. locales:getTextFormatted('ABOUT_BUILT_BY', 'James Daniel')
    )
  end)
  layout:add(about)

  -- credits button
  local credits = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_CREDITS%')
  credits:setPaddingStyle('wide')
  credits:setIcon('./gfx/icon_credits')
  credits:onClick(function ()
    sceneManager:push('credits', sceneManager.kTransitionFade)
  end)
  layout:add(credits)

  -- language select
  local language = Select(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_LANGUAGE%')
  language:setPaddingStyle('wide')
  language:setIcon('./gfx/icon_lang')
  for _, lang in pairs(locales:getAvailableLanguages()) do
    language:addOption(lang.key, lang.name, lang.key)
  end
  language:setValue(locales:getLanguage())
  language:onCloseEnded(function(value)
    locales:setLanguage(value)
    noteFs:refreshFolderNames()
    self:reloadSprites()
  end)
  layout:add(language)
  self.languageSelect = language

  -- dithering button
  local dithering = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_DITHERING%')
  dithering:setPaddingStyle('wide')
  dithering:setIcon('./gfx/icon_dither')
  dithering:onClick(function ()
    sceneManager:push('dithering', sceneManager.kTransitionFade, nil, config.dithering)
  end)
  layout:add(dithering)

  -- sound select
  local sound = Select(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_SOUND%')
  sound:setPaddingStyle('wide')
  sound:setIcon('./gfx/icon_sound')
  sound:addOption(true,  '%SETTINGS_SOUND_ON%',  '%SETTINGS_ON%')
  sound:addOption(false, '%SETTINGS_SOUND_OFF%', '%SETTINGS_OFF%')
  sound:onChange(function(value)
    config.enableSoundEffects = value
  end)
  layout:add(sound)
  self.soundSelect = sound

  -- reset button
  local reset = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_RESET%')
  reset:setPaddingStyle('wide')
  reset:setIcon('./gfx/icon_reset')
  reset:onClick(function ()
    dialog:sequence({
      {type = dialog.kTypeConfirm, message = locales:getText('SETTINGS_RESET_CONFIRM'), callback = function ()
        config:reset()
        locales:setLanguage(config.lang)
        self:reloadSprites()
        self.languageSelect:setValue(locales:getLanguage())
        self.soundSelect:setValue(config.enableSoundEffects)
        self.focus:setFocus(about, true)
      end},
      {type = dialog.kTypeAlert, message = locales:getText('SETTINGS_RESET_DONE')}
    })
  end)
  layout:add(reset)

  self.scroll:setHeight(layout.height)
  self.focus:setFocus(about, true)
  self.firstItem = about

  self.buttons = { about, credits, language, dithering, sound, reset }
  return { scrollBar, about, credits, language, dithering, sound, reset }
end

function SettingsScreen:beforeEnter()
  self.languageSelect:setValue(locales:getLanguage())
  self.soundSelect:setValue(config.enableSoundEffects)
end

function SettingsScreen:afterLeave()
  config:save()
  -- self.focus:setFocusPure(self.firstItem)
  -- self.scroll:resetOffset()
end

function SettingsScreen:drawBg(x, y, w, h)
  grid:drawWithOffset(x, y, w, h, self.scroll.offset)
  bgGfx:draw(self.bgPos, 0)
end

function SettingsScreen:updateTransitionIn(t)
  self.bgPos = playdate.easingFunctions.outQuad(t, -200, 200, 1)
  local d = playdate.easingFunctions.outQuad(t, 50, -50, 1)
  for i, el in ipairs(self.buttons) do
    el:offsetByY((i - 1) * d)
  end
end

function SettingsScreen:updateTransitionOut(t)
  self.bgPos = playdate.easingFunctions.inQuad(t, 0, -200, 1)
  local d = playdate.easingFunctions.inQuad(t, 0, 50, 1)
  for i, el in ipairs(self.buttons) do
    el:offsetByY((i - 1) * d)
  end
end

return SettingsScreen