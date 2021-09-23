import 'CoreLibs/object'
import 'CoreLibs/graphics'

-- Flipnote Studio (DSiWare version) animation parser
-- Format reference:
-- https://github.com/Flipnote-Collective/flipnote-studio-docs/wiki/PPM-format

PpmParser = {}

class("PpmParser").extends()

local gfx <const> = playdate.graphics
local drawPixel <const> = gfx.drawPixel

function PpmParser:init(path)
	PpmParser.super.init()
  if path then
    self:open(path)
  end
  self.layerImages = {
    gfx.image.new(256, 192),
    gfx.image.new(256, 192),
  }
end

function PpmParser:open(path)
  if self.file then self:close() end
  self.file = playdate.file.open(path, playdate.file.kFileRead)
	self:parseHeader()
	self:parseMeta()
  self:parseFrameTable()
end

function PpmParser:close()
  self.file:close()
  self.file = nil
end

function PpmParser:parseHeader()
  self.file:seek(0)
  local header = self.file:read(16)
  self.magic,
  self.animSize,
  self.soundSize,
  self.frameCount,
  self.version = string.unpack('<c4 I4 I4 H H', header)
  self.frameCount = self.frameCount + 1
  assert(self.magic == 'PARA', 'Flipnote Studio PPM file magic not found')
end

function PpmParser:parseMeta()
  self.file:seek(0x10)
  local meta = self.file:read(144)
  local lock, 
    thumbIndex, 
    rootAuthorName, 
    parentAuthorName, 
    currentAuthorName,
    parentAuthorId,
    currentAuthorId,
    parentFilename,
    currentFilename,
    rootAuthorId,
    rootFragment,
    timestamp,
    unused = string.unpack('<H H c22 c22 c22 c8 c8 c18 c18 c8 c8 I4 H', meta)
  self.lock = lock == 1
  self.thumb_index = thumbIndex
  self.root_author_id = unpack_fsid(rootAuthorId)
  self.root_author_name = unpack_username(rootAuthorName)
  self.parent_author_id = unpack_fsid(parentAuthorId)
  self.parent_author_name = unpack_username(parentAuthorName)
  self.current_author_id = unpack_fsid(currentAuthorId)
  self.current_author_name = unpack_username(currentAuthorName)
  self.timestamp = playdate.timeFromEpoch(timestamp, 0) -- playdate conveniently uses the same timestamp epoch as nintendo!
end

function PpmParser:parseFrameTable()
  self.file:seek(0x06A0)
  -- unpack frame table header
  local header = self.file:read(6)
  local tableSize, unknown, anim_flags = string.unpack('<H H H', header)
  local frameOffsetBase <const> = 0x06A8 + self.frameCount * 4
  local numFrames <const> = self.frameCount
  assert(tableSize / 4 == numFrames, 'Frame table size does not match frame count')
  -- unpack frame offset table
  self.file:seek(0x06A8)
  local frameOffsets = table.create(numFrames, 0)
  local buf
  for i = 1, numFrames, 1 do
    buf = self.file:read(4)
    frameOffsets[i] = frameOffsetBase + string.unpack('<I', buf)
  end
  self.frameOffsets = frameOffsets
end

function PpmParser:parseFrame(frame_index)
  assert(frame_index > 0 and frame_index <= self.frameCount)
  local offset = self.frameOffsets[frame_index]
  local f <const> = self.file
  f:seek(offset)
  local b = f:read(1)
  local header = string.byte(b)
  local translateX, translateY

  local isNewFrame = (header >> 7) & 0x1
  local isTranslated = (header >> 5) & 0x3

  if isTranslated > 0 then
    b = f:read(2)
    translateX, translateY = string.unpack('<bb', b)
  end

  local layerEncodingFlags <const> = {f:read(48), f:read(48)}

  local b
  local encodingByte
  local lineType
  local lineHeader
  local chunk
  local pixel = 0

  for layerIndex = 1, 2, 1 do

    gfx.lockFocus(self.layerImages[layerIndex])
    gfx.clear(gfx.kColorClear)

    local layerEncoding <const> = layerEncodingFlags[layerIndex]
    local x = 0
    local y = 0

    -- work through the line encoding bytes for the layer
    for layerEncodingPtr = 1, 48, 1 do
      encodingByte = string.byte(layerEncoding, layerEncodingPtr)
      -- work through a single line encoding byte, which contains the encoding type for 4 lines
      for _ = 1, 4, 1 do
        lineType = encodingByte & 0x3
        x = 0

        -- line type 0; empty, can skip

        -- line type 1; compressed line
        if lineType == 1 then
          b = f:read(4)
          lineHeader = string.unpack('>I4', b)
          -- check each bit in the line header
          -- if the bit is set, the corresponding 8-pixel chunk along the line will be stored as a byte
          for _ = 1, 32, 1 do
            pixel = 0
            if (lineHeader & 0x80000000) == -2147483648 then
              b = f:read(1)
              chunk = string.byte(b)
              -- unpack chunk pixels
              while not (chunk == 0) do
                if (chunk & 0x1) == 1 then drawPixel(x + pixel, y) end
                pixel = pixel + 1
                chunk = chunk >> 1
              end
            end
            lineHeader = lineHeader << 1
            x = x + 8
          end

        -- line type 2; compressed line, begins with inverted pixels
        elseif lineType == 2 then
          b = f:read(4)
          lineHeader = string.unpack('>I4', b)
          for _ = 1, 32, 1 do
            pixel = 0
            if (lineHeader & 0x80000000) == -2147483648 then
              b = f:read(1)
              chunk = string.byte(b)
              -- unpack chunk pixels
              while not (chunk == 0) do
                if (chunk & 0x1) == 1 then drawPixel(x + pixel, y) end
                pixel = pixel + 1
                chunk = chunk >> 1
              end
            else
              while (pixel < 8) do
                drawPixel(x + pixel, y)
                pixel = pixel + 1
              end
            end
            lineHeader = lineHeader << 1
            x = x + 8
          end

        -- line type 3; raw 1 bit per pixel line
        elseif lineType == 3 then
          local chunks = f:read(32)
          for chunkPtr = 1, 32, 1 do
            chunk = string.byte(chunks, chunkPtr)
            pixel = 0
            -- unpack chunk pixels
            while not (chunk == 0) do
              if (chunk & 0x1) == 1 then drawPixel(x + pixel, y) end
              pixel = pixel + 1
              chunk = chunk >> 1
            end
            x = x + 8
          end
        end

        encodingByte = encodingByte >> 2
        y = y + 1
      end

    end

    gfx.unlockFocus()

  end
end

function PpmParser:drawFrame(frameIndex, x, y)
  self:parseFrame(frameIndex)
  gfx.clear()
  self.layerImages[2]:draw(x, y)
  self.layerImages[1]:draw(x, y)
end

function unpack_username(buf)
  local name = {}
  local chr
  local bufptr = 1
  local chrptr = 1
  while bufptr <= #buf do
    chr = string.unpack('<H', buf, bufptr)
    if chr == 0 then break end
    name[chrptr] = utf8.char(chr)
    bufptr = bufptr + 2
    chrptr = chrptr + 1
  end
  return table.concat(name)
end

function unpack_fsid(buf)
  -- playdate only supports ints up to 4 bytes long, so we unpack the id as two ints and format them both as hex
  local bytes = {string.unpack('>I4 I4', string.reverse(buf))}
  return string.format("%08X%08X", table.unpack(bytes))
end