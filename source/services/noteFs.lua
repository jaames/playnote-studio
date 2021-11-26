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
      self.folderList[name] = utils:fixFolderName(name)
    end
  end
  -- set samplememo as initial folder
  if fs.isdir('samplememo') then
    self:setDirectory('samplememo/')
  end
end

function noteFs:setCurrentNote(path)
  self.currentNote = path
end

function noteFs:setDirectory(dir)
  assert(self.folderList[dir] ~= nil, 'Folder does not exist')
  self.currentFolder = dir
  noteList = {}
  local list = fs.listFiles(dir)
  for i = 1, #list do
    local name = list[i]
    if string.sub(name, -3) == 'ppm' then
      table.insert(noteList, dir .. name)
    end
  end
  numNotes, _ = table.getsize(noteList)
  self.hasNotes = numNotes > 1
  self.numPages = math.ceil(numNotes / notesPerPage)
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