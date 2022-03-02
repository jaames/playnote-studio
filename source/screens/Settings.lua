local bgGfx <const> = gfx.image.new('./gfx/gfx_bg_settings')

local ITEM_WIDTH <const> = 300
local ITEM_HEIGHT <const> = 54
local MENU_X <const> = (PLAYDATE_W / 2) - (ITEM_WIDTH / 2)
local MENU_GAP_TOP <const> = 24
local MENU_GAP_BOTTOM <const> = 24
local MENU_MID <const> = (PLAYDATE_H / 2) - ITEM_HEIGHT
local MENU_SCROLL_DUR = 200

SettingsScreen = {}
class('SettingsScreen').extends(ScreenBase)

function SettingsScreen:init()
  SettingsScreen.super.init(self)
  self.scroll = ScrollController(self)
  self.scroll.selectionMode = ScrollController.kModeKeepCenter
  self.focus = FocusController(self)
end

function SettingsScreen:setupSprites()
  local scrollBar = ScrollBar(PLAYDATE_W - 26, MENU_GAP_TOP, PLAYDATE_H - MENU_GAP_TOP - MENU_GAP_BOTTOM)
  self.scroll:connectScrollBar(scrollBar)

  local layout = AutoLayout(16, 0, AutoLayout.kDirectionColumn, ITEM_WIDTH)
  self.layout = layout

  -- about button
  local about = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_ABOUT%')
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
  credits:setIcon('./gfx/icon_credits')
  credits:onClick(function ()
    screens:push('credits', screens.kTransitionFade)
  end)
  layout:add(credits)

  -- language select
  local language = Select(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_LANGUAGE%')
  language:setIcon('./gfx/icon_lang')
  for _, lang in pairs(locales:getAvailableLanguages()) do
    language:addOption(lang.key, lang.name, string.upper(lang.key))
  end
  language:setValue(locales:getLanguage())
  language:onCloseEnded(function(value)
    locales:setLanguage(value)
    noteFs:refreshFolderNames()
    -- refresh sprites to force components to take new locale
    self:performOnAllSprites(function (sprite)
      sprite:remove()
      sprite:add()
    end)
  end)
  layout:add(language)
  self.languageSelect = language

  -- dithering button
  local dithering = Button(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_DITHERING%')
  dithering:setIcon('./gfx/icon_dither')
  dithering:onClick(function ()
    screens:push('dithering', screens.kTransitionFade, nil, config.dithering)
  end)
  layout:add(dithering)

  -- sound select
  local sound = Select(0, 0, ITEM_WIDTH, ITEM_HEIGHT, '%SETTINGS_SOUND%')
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
  reset:setIcon('./gfx/icon_reset')
  reset:onClick(function ()
    dialog:sequence({
      {type = dialog.kTypeConfirm, message = '%SETTINGS_RESET_CONFIRM%', callback = function ()
        -- s:scrollToItemByIndex(1, true)
        config:reset()
        locales:setLanguage(config.lang)
        screens:reloadCurrent(screens.kTransitionNone)
      end},
      {type = dialog.kTypeAlert, message = '%SETTINGS_RESET_DONE%'}
    })
  end)
  layout:add(reset)

  self.scroll:setHeight(layout.height)
  self.focus:setFocus(about)
  self.firstItem = about

  return { scrollBar, about, credits, language, dithering, sound, reset }
end

function SettingsScreen:beforeEnter()
  SettingsScreen.super.beforeEnter(self)
  self.languageSelect:setValue(locales:getLanguage())
  self.soundSelect:setValue(config.enableSoundEffects)
end

function SettingsScreen:afterLeave()
  SettingsScreen.super.afterLeave(self)
  config:save()
  self.focus:setFocusPure(self.firstItem)
  self.scroll:resetOffset()
end

function SettingsScreen:drawBg(x, y, w, h)
  grid:drawWithOffset(x, y, w, h, self.scroll.offset)
  bgGfx:draw(0, 0)
end

function SettingsScreen:update()
  -- local crankChange = playdate.getCrankTicks(6)
  -- if crankChange ~= 0 then
  --   self:scrollToItemByIndex(self.activeItemIndex - crankChange, true)
  -- end
end