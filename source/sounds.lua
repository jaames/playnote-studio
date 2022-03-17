local fs = playdate.file
local snd = playdate.sound

local SOUND_ROOT <const> = '/sounds/'

local sfx = {}
local sfxGroups = {}
local refCounts = {}
local lastSampleName = nil
local currMusic = nil

sounds = {}

-- prepare a list of sound effects for use
-- sound effect data will be loaded if it hasn't already been prepared
function sounds:prepareSfx(sampleNames)
  for _, sampleName in pairs(sampleNames) do
    if sfx[sampleName] == nil then
      local path = SOUND_ROOT .. sampleName
      local pathWithExt = path .. '.pda'
      assert(fs.exists(pathWithExt), 'Missing sfx file ' .. pathWithExt)
      -- print('Loading SFX: ' .. sampleName)
      sfx[sampleName] = snd.sampleplayer.new(path)
      refCounts[sampleName] = 1
    else
      refCounts[sampleName] += 1
    end
  end
end

-- unreference a list of sound effects
-- sound effect data will only be unloaded if there's nothing else holding them
function sounds:releaseSfx(sampleNames)
  for _, sampleName in pairs(sampleNames) do
    refCounts[sampleName] -= 1
    -- free sounds effect once there's nothing else using it
    if refCounts[sampleName] == 0 then
      -- print('Freeing SFX: ' .. sampleName)
      sfx[sampleName] = nil
    end
  end
end

-- prepare a list of sound effects, and group them together to they can be released at once later on
function sounds:prepareSfxGroup(groupId, sampleNames)
  -- print('preping sfx group', groupId)
  sfxGroups[groupId] = sampleNames
  self:prepareSfx(sampleNames)
end

-- release a whole group of sound effects
function sounds:releaseSfxGroup(groupId)
  local sampleNames = sfxGroups[groupId]
  if sampleNames ~= nil then
    self:releaseSfx(sampleNames)
    sfxGroups[groupId] = nil
  end
end

-- play a sound effect
function sounds:playSfx(sampleName, callbackFn)
  if config.enableSoundEffects and sfx[sampleName] ~= nil then
    lastSampleName = sampleName
    local sample = sfx[sampleName]
    -- print('playing ' .. sampleName)
    sample:play(1)
    sample:setFinishCallback(callbackFn)
  end
end

-- play a sound effect then discard it once finished
function sounds:playSfxThenRelease(sampleName, callbackFn)
  self:playSfx(sampleName, function ()
    self:releaseSfx({sampleName})
    if type(callbackFn) == 'function' then callbackFn() end
  end)
end

-- play a sound effect, but only once, until a new sound effect is played
function sounds:playSfxOnce(sampleName, callbackFn)
  if sampleName ~= lastSampleName then
    self:playSfx(sampleName, callbackFn)
  end
end

-- stop the currently playing sound effect
function sounds:stopSfx(sampleName)
  if sfx[sampleName] ~= nil then
    sfx[sampleName]:stop()
  end
end

-- begin playing a looping music track
function sounds:playMusic(trackName)
  if currMusic ~= nil then
    self:stopMusic()
  end
  local path = SOUND_ROOT .. trackName
  -- assert(fs.exists(path), 'Missing music file ' .. path)
  currMusic = snd.fileplayer.new(path)
  local success = currMusic:play(1)
  if not success then
    print('ERROR: music could not be added to channel')
  end
  return success
end

-- stop the current music track
function sounds:stopMusic()
  if currMusic ~= nil then
    currMusic:stop()
    currMusic = nil
  end
end

function sounds:debug()
  print('---sfx loaded---')
  printTable(sfx)
  print('---sfx groups loaded---')
  printTable(sfxGroups)
  print('---sfx ref counts---')
  printTable(refCounts)
end