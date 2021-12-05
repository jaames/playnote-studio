stringUtils = {}

function stringUtils:escape(text)
  text = string.gsub(text, '_', '__')
  return string.gsub(text, '*', '**')
end

function stringUtils:replaceVars(text, vars)
  return string.gsub(text, '$([%w_]+)', vars)
end