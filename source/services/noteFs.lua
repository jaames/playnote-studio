import 'CoreLibs/object'
import './utils.lua'

local fs <const> = playdate.file

noteFs = {}

noteFs.folderList = {}
noteFs.currentFolder = ''
noteFs.notesPerPage = 12
noteFs.currentNote = nil

local noteList = {}
local notesPerPage <const> = noteFs.notesPerPage

function noteFs:initFs()
  -- create initial note folder with instructions if it doesn't exist yet
  if not fs.isdir('001') then
    fs.mkdir('001')
    local readme = fs.open('001/help.txt', fs.kFileWrite)
    readme:write('Drop all of your Flipnote .ppm files into this folder!\nYou can also organise your Flipnotes by creating more folders next to this one')
    readme:close()
  end
  -- build list of root folders
  local list = fs.listFiles('/')
  for i = 1, #list, 1 do
    local name = list[i]
    if (string.sub(name, -1) == '/') and not utils:isInternalFolder(name) then
      self.folderList[name] = self:getFolderName(name)
    end
  end
  -- set samplememo as initial folder
  assert(fs.isdir('samplememo'), 'Sample Flipnote folder is missing?')
  self:setDirectory('samplememo/')
  self:getArtistCredits()
end

function noteFs:getFolderMeta(folder)
  local jsonPath = folder .. 'playnote.json'
  if fs.exists(jsonPath) then
    return json.decodeFile(jsonPath)
  end
  return nil
end

function noteFs:getFolderName(folder)
  local meta = self:getFolderMeta(folder)
  if meta ~= nil and meta.folderTitle	~= nil then
    return utils:escapeText(meta.folderTitle)
  end
  return utils:escapeText(utils:fixFolderName(folder))
end

function noteFs:getArtistCredits()
  local creditList = {}
  for folder, _ in pairs(self.folderList) do
    local meta = self:getFolderMeta(folder)
    if meta ~= nil and meta.credits	~= nil then
      for _, item in ipairs(meta.credits) do
        local id = item.id
        -- artist id should be unique
        if creditList[id] == nil then
          creditList[id] = item
        end
      end
    end
  end
  return creditList
end

function noteFs:setDirectory(folder)
  assert(self.folderList[folder] ~= nil, 'Folder does not exist')
  self.currentFolder = folder
  noteList = {}
  local list = fs.listFiles(folder)
  for i = 1, #list do
    local name = list[i]
    if string.sub(name, -3) == 'ppm' then
      table.insert(noteList, folder .. name)
    end
  end
  numNotes, _ = table.getsize(noteList)
  self.hasNotes = numNotes > 1
  self.numPages = math.ceil(numNotes / notesPerPage)
end

function noteFs:setCurrentNote(path)
  self.currentNote = path
end

function noteFs:getPage(pageIndex)
  local page = table.create(0, notesPerPage)
  local startIndex = ((pageIndex - 1) * notesPerPage) + 1 -- thanks lua, great programming language
  local endIndex = math.min(startIndex + notesPerPage - 1, numNotes)
  for i = startIndex, endIndex do
    local path = noteList[i]
    page[path] = TmbParser.new(path)
  end
  return page
end

function noteFs:releasePage(pageTable)
  utils:clearArray(pageTable)
end