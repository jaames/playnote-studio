import 'CoreLibs/graphics'

configManager = {}

local CONFIG_VERSION <const> = 1
local DATASTORE_KEY <const> = 'config'
local DEFAULT_CONFIG <const> = {
  configVersion = CONFIG_VERSION,
  initialPdxVersion = playdate.metadata.version,
  initialPdxBuild = playdate.metadata.buildNumber,
  initialApiVersion = playdate.apiVersion(),
  lang = 'en',
  enableSoundEffects = true,
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

function configManager:init()
  local config = readConfigFile()
  -- write default config to file if it doesn't yet exist
  if config == nil then 
    config = DEFAULT_CONFIG
    saveConfigFile(config)
  -- upgrade config if the version has been updated
  elseif not config.configVersion or config.configVersion < CONFIG_VERSION then
    configManager:upgrade()
  end
  -- make config values available on configManager
  for k in pairs(config) do
    configManager[k] = config[k]
  end
end

function configManager:save()
  local config = {}
  for k in pairs(configManager) do
    if type(configManager[k]) ~= 'function' then
      config[k] = configManager[k]
    end
  end
  saveConfigFile(config)
end

function configManager:reset()
  for k in pairs(configManager) do
    if type(configManager[k]) ~= 'function' then
      configManager[k] = nil
    end
  end
  for k in pairs(DEFAULT_CONFIG) do
    configManager[k] = DEFAULT_CONFIG[k]
  end
  configManager:save()
end

function configManager:upgrade()
  local config = {}
  for k in pairs(DEFAULT_CONFIG) do
    if config[k] == nil then
      config[k] = DEFAULT_CONFIG[k]
    end
  end
  config.configVersion = CONFIG_VERSION
  saveConfigFile(config)
end

-- autosave everything if the game is about to be closed
function playdate.gameWillTerminate()
  configManager:save()
end
-- and when the device is about to be locked
function playdate.deviceWillLock()
  configManager:save()
end