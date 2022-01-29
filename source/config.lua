local gfx <const> = playdate.graphics

config = {}

local CONFIG_VERSION <const> = 1
local DATASTORE_KEY <const> = 'config'
local DEFAULT_CONFIG <const> = {
  configVersion = CONFIG_VERSION,
  initialPdxVersion = playdate.metadata.version,
  initialPdxBuild = playdate.metadata.buildNumber,
  initialApiVersion = playdate.apiVersion(),

  -- settings configurable from settings screen
  lang = ({
    [gfx.font.kLanguageEnglish] = 'en',
    [gfx.font.kLanguageJapanese] = 'jp'
  })[playdate.getSystemLanguage()],
  enableSoundEffects = true,
  -- dithering settings, per layer (top, bottom)
  dithering = {
    -- dither patterns per layer colour (black, red, blue)
    {1, 3, 4},
    {1, 3, 4}
  },

  -- state tracking
  lastFolder = 'samplememo/',
}

function saveConfigFile(config)
  config.lastSavePdxVersion = playdate.metadata.version
  config.lastSavePdxBuild = playdate.metadata.buildNumber
  config.lastSaveApiVersion = playdate.apiVersion()
  playdate.datastore.write(config, DATASTORE_KEY, true)
end

function readConfigFile()
  return playdate.datastore.read(DATASTORE_KEY)
end

function config:init()
  local configFile = readConfigFile()
  -- write default config to file if it doesn't yet exist
  if configFile == nil then
    configFile = DEFAULT_CONFIG
  -- fill in any missing keys with default values in case the user mucked around with the config too much
  else
    for k in pairs(DEFAULT_CONFIG) do
      if configFile[k] == nil then
        configFile[k] = DEFAULT_CONFIG[k]
      end
    end
  end
  -- upgrade config if the version has been updated
  if configFile.configVersion < CONFIG_VERSION then
    config:upgrade()
  end
  -- save changes to config file
  saveConfigFile(configFile)
  -- make config values available on config
  for k in pairs(configFile) do
    config[k] = configFile[k]
  end
end

function config:save()
  local configFile = {}
  for k in pairs(config) do
    if type(config[k]) ~= 'function' then
      configFile[k] = config[k]
    end
  end
  saveConfigFile(configFile)
end

function config:reset()
  for k in pairs(config) do
    if type(config[k]) ~= 'function' then
      config[k] = nil
    end
  end
  for k in pairs(DEFAULT_CONFIG) do
    config[k] = DEFAULT_CONFIG[k]
  end
  config:save()
end

function config:upgrade()
  local configFile = {}
  for k in pairs(DEFAULT_CONFIG) do
    if configFile[k] == nil then
      configFile[k] = DEFAULT_CONFIG[k]
    end
  end
  configFile.configVersion = CONFIG_VERSION
  saveConfigFile(configFile)
end

-- autosave everything if the game is about to be closed
function playdate.gameWillTerminate()
  config:save()
end
-- and when the device is about to be locked
function playdate.deviceWillLock()
  config:save()
end