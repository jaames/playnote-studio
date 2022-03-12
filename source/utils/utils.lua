utils = {}

function table.combine(...)
  local tbl = {}
  local i = 1
  for _, b in pairs({...}) do
    for _, v in pairs(b) do
      tbl[i] = v
      i = i + 1
    end
  end
  return tbl
end

-- execute callback function on next frame
function utils:nextTick(callback)
  playdate.frameTimer.new(1, callback)
end

function utils:markScreenDirty()
  local x, y = gfx.getDrawOffset()
  spritelib.addDirtyRect(x, y, PLAYDATE_W, PLAYDATE_H)
end

-- create a removable button repeater
function utils:createRepeater(delayAfterInitialFiring, delayAfterSecondFiring, callback)
  local repeatTimer = nil
  local isRepeat = false

  local function remove()
    if repeatTimer ~= nil then
      repeatTimer:remove()
      repeatTimer = nil
    end
  end

  local function buttonDown()
    repeatTimer = playdate.timer.keyRepeatTimerWithDelay(delayAfterInitialFiring, delayAfterSecondFiring, function ()
      callback(isRepeat)
    end)
    isRepeat = true
  end

  local function buttonUp()
    remove()
    isRepeat = false
  end
  return buttonDown, buttonUp, remove
end

function utils:hookFn(origFn, hookFn)
  if type(origFn) == 'function' then
    return function (...)
      origFn(...)
      hookFn(...)
    end
  else
    return hookFn
  end
end

-- clamp value between lower and upper
function utils:clamp(val, lower, upper)
  return math.max(lower, math.min(upper, val))
end

-- set all the elements in a table to nil
function utils:clearArray(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

function utils:imageTableSizeAtPath(path)
  local pdtPath = path .. '.pdt'
  local f, err = playdate.file.open(pdtPath, playdate.file.kFileRead)
  assert(f ~= nil, err)
  local headerData = f:read(0x10)
  local header, flags = string.unpack('<c12 I4', headerData)
  -- if the compression flag is set, there is an image header:
  -- 0x0 - int32 size of decompressed image data
  -- 0x4 - int32 image width
  -- 0x8 - int32 image height
  -- 0xC - int32 number of cells
  if (flags & 0x80000000) > 0 then
    local imgHeader = f:read(0x10)
    local _, width, height, numFrames = string.unpack('<I4 I4 I4 I4', imgHeader)
    f:close()
    return width, height
  --
  --  0x0 - uint16 number of cells
  --  0x2 - uint16 number of cells again?
  -- table
  --  int32 end offset for each cell
  -- cell entries
  --  header
  --    0x0	- uint16 cell width
  --    0x2	- uint16 cell height
  --    0x4	- uint16 cell stride (bytes per image row)
  --    0x6 - uint16 cell clip left
  --    0x8 - uint16 cell clip right
  --    0xA - uint16 cell clip top
  --    0xC - uint16 cell clip bottom
  --    0xE - uint16 bitflags
  else
    local imgHeader = f:read(0x4)
    local numCells, _ = string.unpack('H H', imgHeader)
    local cellOffset = f:tell() + numCells * 4
    f:seek(cellOffset)
    local cellHeader = f:read(0xE)
    local clipW, clipH, _, clipL, clipR, clipT, clipB = string.unpack('<H H H H H H H', cellHeader)
    f:close()
    return clipL + clipW + clipR, clipT + clipH + clipB
  end
end