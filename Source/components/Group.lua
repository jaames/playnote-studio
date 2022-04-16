Group = {}
class('Group').extends()

setmetatable(Group {
  __index = function (t, key)
    if type(t[key]) == 'function' and key ~= 'init' and key ~= 'addChild' and key ~= 'removeChild' then
      return function (...)
        for i = 1, #t.children do
          t.children[i][key](...)
        end
      end
    end
    return key
  end
})

function Group:init()
  self.children = {}
end

function Group:addChild(child)
  table.insert(self.children, child)
end

function Group:removeChild(child)
  table.remove(self.children, table.indexOfElement(child))
end

