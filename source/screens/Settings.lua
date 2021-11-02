import 'CoreLibs/object'
import 'CoreLibs/graphics'
import 'CoreLibs/ui'

import './ScreenBase'
import '../screenManager.lua'
import '../configManager.lua'
import '../dialogManager.lua'
import '../gfxUtils.lua'

local gfx <const> = playdate.graphics

class('SettingsScreen').extends(ScreenBase)

function SettingsScreen:init()
  SettingsScreen.super.init(self)
  -- init config file, makes self.config available
  configManager:init()
  
  -- TODO: calculate
  self.scrollY = 0
  self.pageHeight = 400
  self.inputHandlers = {
    upButtonDown = function ()
      self.settingsUiView:selectPreviousRow(false, true)
    end,
    downButtonDown = function ()
      self.settingsUiView:selectNextRow(false, true)
    end,
    AButtonDown = function()
      local row = self.settingsUiView:getSelectedRow()
      local item = self.settingsItems[row]
      item:onSelect(item)
    end,
    BButtonDown = function()
      screenManager:setScreen('home')
    end,
    cranked = function(change, acceleratedChange)
      self.scrollY = utils:clampScroll(self.scrollY + change, 0, self.pageHeight)
    end,
  }
end

function SettingsScreen:beforeEnter()
  SettingsScreen.super.beforeEnter(self)
  -- set up setting items
  local settingsItems <const> = {
    {
      type = 'button',
      label = 'About',
      onSelect = function (item)
        local aboutText = '\n'
          .. '*Playnote Studio*\n'
          .. 'https://playnote.studio\n'
          .. '\n'
          .. 'Version ' .. playdate.metadata.version .. '\n'
          .. 'Built by James Daniel'
        dialogManager:show(aboutText)
      end
    },
    {
      type = 'button',
      label = 'Credits',
      onSelect = function (item)
        screenManager:setScreen('credits')
      end
    },
    {
      type = 'button',
      label = configManager.enableSoundEffects and 'Sound Effects: On' or 'Sound Effects: Off',
      onSelect = function (item)
        configManager.enableSoundEffects = not configManager.enableSoundEffects
        item.label = configManager.enableSoundEffects and 'Sound Effects: On' or 'Sound Effects: Off'
      end
    },
    {
      type = 'button',
      label = configManager.lang == 'jp' and 'Lang: Japanese' or 'Lang: English',
      onSelect = function (item)
        configManager.lang = configManager.lang == 'en' and 'jp' or 'en'
        item.label = configManager.lang == 'jp' and 'Lang: Japanese' or 'Lang: English'
      end
    },
    {
      type = 'button',
      label = 'Reset Settings',
      onSelect = function (item)
        dialogManager.handleClose = function ()
          configManager:reset()
          self:beforeEnter()
        end
        dialogManager:show('Settings will be reset, press A to be confirm')
      end
    }
  }
  -- set up settings ui view
  local settingsUiView <const> = playdate.ui.gridview.new(336, 48)
  settingsUiView:setNumberOfColumns(1)
  settingsUiView:setNumberOfRows(#settingsItems)
  settingsUiView:setContentInset(28, 28, 0, 0)
  settingsUiView:setCellPadding(4, 4, 4, 4)
  -- settingsUiView.scrollCellsToCenter = false
  
  self.settingsItems = settingsItems
  self.settingsUiView = settingsUiView

  local o = settingsUiView.setScrollPosition
  local s = self

  function settingsUiView:setScrollPosition(x, y, animated)
    s.scrollY = -y
    print(x, y, animated)
  end

  settingsUiView:setSelectedRow(1)

  function settingsUiView:drawCell(section, row, column, selected, x, y, width, height)
    local item <const> = settingsItems[row]

    if item.type == 'button' then
      gfxUtils:drawButtonWithText(item.label, x, y, width, height, selected)
    end
  end
end

-- autosave on leave
function SettingsScreen:afterLeave()
  SettingsScreen.super.afterLeave(self)
  configManager:save()
end

function SettingsScreen:update()
  gfx.setDrawOffset(0, self.scrollY)
  gfxUtils:drawBgGrid()
  self.settingsUiView:drawInRect(0, 0, 400, 240)
end