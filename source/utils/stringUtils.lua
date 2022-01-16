stringUtils = {}

function stringUtils:escape(text)
  text = string.gsub(text, '_', '__')
  text = string.gsub(text, '*', '**')
  return text
end

function stringUtils:replaceVars(text, vars)
  text = string.gsub(text, '${([%w_]+)}', vars)
  return text
end

function stringUtils:split(text, delim)
  local i = 1
  local ret = {}
  for w in string.gmatch(text .. delim, '(.-)' .. delim) do
    ret[i] = w
    i += 1
  end
  return table.unpack(ret)
end

function stringUtils:fromWideChars(bytes)
  local name = ''
  local chr = 0
  local ptr = 1
  while ptr <= #bytes do
    chr = string.unpack('<H', bytes, ptr)
    if chr == 0 then break end
    name = name .. utf8.char(chr)
    ptr += 2
  end
  return stringUtils:escape(name)
end

function stringUtils:hexFromBytes(bytes, reverse)
  local nBytes = #bytes
  local chars = {string.unpack(string.rep('B', nBytes), bytes)}
  if not reverse then
    return string.format(string.rep('%02X', nBytes), table.unpack(chars))
  else
    local hex = ''
    for i = nBytes, 1, -1 do
      hex = hex .. string.format('%02X', chars[i])
    end
    return hex
  end
end

function stringUtils:formatTime(time, format)
  return stringUtils:replaceVars(format, {
    YEAR =   string.format('%04d', time.year),
    MONTH =  string.format('%02d', time.month),
    DAY =    string.format('%02d', time.day),
    HOUR =   string.format('%02d', time.hour),
    MINUTE = string.format('%02d', time.minute),
    SECOND = string.format('%02d', time.second),
  })
end

function stringUtils:formatTimeMultiple(time, ...)
  local formatArgs = {
    YEAR =   string.format('%04d', time.year),
    MONTH =  string.format('%02d', time.month),
    DAY =    string.format('%02d', time.day),
    HOUR =   string.format('%02d', time.hour),
    MINUTE = string.format('%02d', time.minute),
    SECOND = string.format('%02d', time.second),
  }
  local i = 1
  local ret = {}
  for _, format in pairs({...}) do
    ret[i] = stringUtils:replaceVars(format, formatArgs)
    i += 1
  end
  return table.unpack(ret)
end

function stringUtils:formatTimestamp(timestamp, format)
  return stringUtils:formatTime(playdate.timeFromEpoch(timestamp, 0), format)
end

