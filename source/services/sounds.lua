local fs = playdate.file
local snd = playdate.sound

local SOUND_ROOT <const> = './sounds/'

local sfx = {}
local sfxGroups = {}
local refCounts = {}
local lastSfx = nil
local currMusic = nil

sounds = {}

function sounds:init()
end

-- prepare a list of sound effects for use
-- sound effect data will be loaded if it hasn't already been prepared
function sounds:prepareSfx(sampleNames)
  for _, sampleName in pairs(sampleNames) do
    if sfx[sampleName] == nil then
      local path = SOUND_ROOT .. sampleName
      assert(fs.exists(path), 'Missing sfx file ' .. path)
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
      sfx[sampleName] = nil
    end
  end
end

-- prepare a list of sound effects, and group them together to they can be released at once later one
function sounds:prepareSfxGroup(groupId, sampleNames)
  sfxGroups[groupId] = sampleNames
  self:prepare(sampleNames)
end

-- release a whole group of sound effects
function sounds:releaseSfxGroup(groupId)
  local sampleNames = sfxGroups[groupId]
  if sampleNames ~= nil then
    self:release(sampleNames)
    sfxGroups[groupId] = nil
  end
end

-- play a sound effect
function sounds:playSfx(sampleName)
  if config.enableSoundEffects and sfx[sampleName] ~= nil then
    lastSfx = sampleName
    sfx[sampleName]:play(1)
  end
end

-- play a sound effect, but only once, until a new sound effect is played
function sounds:playSfxOnce(sampleName)
  if sampleName ~= lastSfx then
    self:playSfx(sampleName)
  end
end

-- stop the currently playing sound effect
function sounds:stopSfx(sampleName)
  sfx[sampleName]:stop()
end

-- begin playing a looping music track
function sounds:playMusic(trackName)
  if currMusic ~= nil then
    self:stopMusic()
  end
  local path = SOUND_ROOT .. trackName
  assert(fs.exists(path), 'Missing music file ' .. path)
  currMusic = snd.fileplayer.new(path)
  currMusic:play(0)
end

-- stop the current music track
function sounds:stopMusic()
  currMusic:stop()
  currMusic = nil
end