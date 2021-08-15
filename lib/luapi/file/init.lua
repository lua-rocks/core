local asserts = require 'lib.asserts'
local Object  = require 'lib.object'
local Type    = require 'lib.luapi.type'


--[[ Single lua file
TODO: Separate internal types from external.
IDEA: Parse and write list of requires
IDEA: Links across document

= @ (lib.object)
> reqpath  (string)
> fullpath (string)
> module   ({string=lib.luapi.type...}) [] external types indexed by type names
> locals   ({string=lib.luapi.type...}) [] internal types indexed by type names
> content  (@#content) [] gets removed after File:write() attempt
> output   (@#output)  [] gets removed after File:write() attempt
]]
local File = Object:extend 'lib.luapi.file'


--[[ Content of this file plus some includes to the output
= @#content (table)
> full (string)    [] full content of this file
> code (string)    [] uncommented content of this file
> example (string) [] example.lua
> readme (string)  [] dirname.lua
]]


--[[ Output model
= @#output (table)
> head (@#output_field)
> body (@#output_field)
> foot (@#output_field)
]]


--[[ Element of output model
= @#output_field (table)
> text (string)
> add (@#output_field.add)
]]


--[[ Add text to output field
= @#output_field.add (function)
> self (@#output_field)
> text (string)
< self (@#output_field)
]]


--[[ Init file but don't read it
> reqpath (string)
> fullpath (string)
]]
function File:init(reqpath, fullpath)
  asserts(function(x) return type(x) == 'string' end, reqpath, fullpath)
  self.reqpath = reqpath
  self.fullpath = fullpath
  self.content = {
    ['full']    = nil,
    ['code']    = nil,
    ['example'] = nil,
    ['readme']  = nil,
  }
  local add = function(add, text) add.text = add.text .. text; return add end
  self.output = {}
  for _, key in ipairs { 'head', 'body', 'foot' } do
    self.output[key] = { text = '', add = add }
  end
end


--[[ Read file
< success (@|nil)
]]
function File:read()
  -- init.lua
  local file = io.open(self.fullpath .. '/init.lua', 'rb')
  if not file then return nil end
  self.content.full = file:read '*a'
  self.content.code = self.content.full
    :gsub('%-%-%[%[.-%]%]', '')
    :gsub('%-%-.-\n', '')
  file:close()
  -- modname.md
  local modname = self.fullpath:match '.+/(.+)'
  file = io.open(self.fullpath .. '/' .. modname .. '.md', 'rb')
  if file then
    self.content.readme = '\n' .. file:read '*a'
    file:close()
  end
  -- example.lua
  file = io.open(self.fullpath .. '/example.lua', 'rb')
  if file then
    self.content.example = file:read '*a'
    file:close()
  end
  return self
end


--[[ Parse file
+ XXX: self1 can be any type (not only a class)
+ IDEA: Escape whatever you want with `\` (partitially works)
+ IDEA: Support OOP: inheritance
< success (@|nil)
]]
function File:parse()
  -- Init
  self.module = {}
  self.locals = {}
  local escaped_reqpath = self.reqpath:gsub('%p', '%%%1')
  -- Parse blocks
  for block in self.content.full:gmatch '%-%-%[%[.-%]%].-\n' do
    local type = Type(block)
    if type then
      local short_type_name = type.line.name:gsub(escaped_reqpath, '@')
      if short_type_name == '@' then
        for _, ifield in ipairs(type.fields) do
          self.module[ifield.name] = ifield
        end
      else
        local s = short_type_name:sub(1, 2)
        local e = short_type_name:sub(3, -1)
        if s == '@:' then
          self.module[e] = type
        elseif s == '@#' then
          self.locals[e] = type
        end
      end
    end
  end
  -- Convert line fields to types
  for name, line in pairs(self.module) do
    local type = Type(line)
    if type then self.module[name] = type end
  end
  -- Clean up
  if next(self.module) == nil then self.module = nil end
  if next(self.locals) == nil then self.locals = nil end
  return self
end


--[[ It was terrible...
-- < success (@|nil)
function File:parse()
  local self1 = Block()
  local selfN = {}
  self1.codename = self.content.code:match 'return%s([%w_]+)\n?$'

  local function set_block_name(block)
    if block.line and block.line.name then
      block.name = block.line.name
      block.line.name = nil
    else
      block.name = block.codename
    end
  end

  local function return_self()
    -- Convert self1.fields in lines format to blocks format
    for field_i, field in ipairs(self1.fields or {}) do
      if tostring(field) ~= 'instance of lib.luapi.block' then
        self1.fields[field_i] = Block()
        for line_key, line in pairs(field) do
          self1.fields[field_i][line_key] = line
        end
      end
    end
    if self1.line then self1.extends = self1.line.parent end
    -- Insert types
    self[1] = self1
    for _, typeN in ipairs(selfN) do table.insert(self, typeN) end
    -- Replace __tostring
    local mt = getmetatable(self1)
    if mt then
      mt.__tostring = function()
        return 'instance of @#class'
      end
      setmetatable(self1, mt)
    end
    return self
  end

  if not self1.codename then
    -- If module codename not found in last return,
    -- lets try to take it from first described class.
    self1.codename = self.content.full:match
      '%-%-%[%[.-\n@%s.-]%].-\nlocal%s([%w_]+)'
  end
  if not self1.codename then
    -- Abstract module?
    local block = self.content.full:match '%-%-%[%[.-\n@%s.-%]%].-\n'
    self1 = Block(block)
    for _, value in pairs(self1) do
      if type(value) ~= 'function' then
        return return_self()
      end
    end
    return nil
  end

  -- Parse each commented block
  for block, last_line in
  self.content.full:gmatch '(%-%-%[%[.-%]%].-\n)(.-)\n' do
    local module_codename_found = ('\n' .. last_line)
      :find('%W' .. self1.codename .. '%W')
    if module_codename_found then
      -- Field
      if module_codename_found == 1 then
        local field = Block(block)
        field.codename = last_line
          :gsub('%s', '')
          :match(self1.codename .. '%.(.+)=')
        set_block_name(field)
        if field.line then
          for key, value in pairs(field.line) do field[key] = value end
          field.line = nil
        end
        if next(field) then
          self1.fields = self1.fields or {}
          table.insert(self1.fields, field)
        end
      -- Method
      elseif last_line:find 'function%s' == 1 then
        local method = Block(block)
        method.codename = last_line
          :sub(10)
          :gsub('%s', '')
          :match(self1.codename .. '[:%.](.+)%(')
        if next(method) then
          self1.methods = self1.methods or {}
          table.insert(self1.methods, method)
        end
        set_block_name(method)
        local codeargs = {}
        for comma_separated in last_line:gmatch '%((.-)%)' do
          for arg in comma_separated:gmatch '[%w_]+' do
            table.insert(codeargs, (arg:gsub('[,%s]', '')))
          end
        end
        if next(codeargs) then method.codeargs = codeargs end
      -- Module
      elseif last_line:match 'local%s([%w_]+)' == self1.codename then
        local codename = self1.codename
        self1 = Block(block) or self1
        if codename then self1.codename = codename end
      end
    elseif block:match '\n@.+' then -- Type
      local typeN = Block(block)
      -- Add type as field if it's not a function
      if typeN.line and typeN.line.name and
      typeN.line.parent ~= 'function' and
      not typeN.line.parent:find '%.' then
        local name = typeN.line.name
        local from, to = name:find(self.reqpath..".")
        if from == 1 then
          name = name:sub(to+1)
          typeN.name = name
          self1.fields = self1.fields or {}
          table.insert(self1.fields, typeN)
        else
          table.insert(selfN, typeN)
        end
      else
        table.insert(selfN, typeN)
      end
    end
  end

  if next(self1) then
    if not self1.fields and
      not self1.methods and
      not self.title and
      not self.description
    then return nil end
    return return_self()
  end
  return nil
end
]]


--[[ Write `@#output` to the file and clean up file cache
]]
function File:write()
  -- Touch file
  local file = io.open(self.fullpath .. '/readme.md', 'w+')
  if not file then
    print('error: failed to create "' .. self.fullpath .. '/readme.md' .. '"')
    return nil
  end

  -- Create output
  local self1 = self[1]
  if self1 then
    self1:output_main(self)
    for index = 2, #self do
      local selfi = self[index]
      assert(type(selfi.line) == 'table')
      assert(type(selfi.line.name) == 'string')
      assert(type(selfi.line.parent) == 'string')
      selfi:output_add(self)
    end
  end

  -- Write output
  local out = self.output
  if self.output then
    file:write(out.head.text .. out.body.text .. out.foot.text)
    file:close()
  end

  return self
end


--[[ It was horrible...
function File:write()
  -- Touch file
  local file = io.open(self.fullpath .. '/readme.md', 'w+')
  if not file then
    print('error: failed to create "' .. self.fullpath .. '/readme.md' .. '"')
    self.content = nil
    return nil
  end

  -- Create a table for preparations
  local self1 = self[1]
  local add = function(add, text) add.text = add.text .. text; return add end
  local out = {}
  for _, key in ipairs { 'head', 'body', 'foot' } do
    out[key] = { text = '', add = add }
  end

  out.foot:add '\n## 🖇️ Links\n\n[Go up](..)\n'

  -- See `lib.luapi.block:out()`
  if self1 then

    out.head:add('# `' .. self.reqpath .. '`\n')

    _out.module(self, out)
    _out.types(self, out)
  end

  -- Write everything
  file:write(out.head.text .. out.body.text .. out.foot.text)
  file:close()
  self.content = nil
  return self
end
]]


--[[ Try to get access to type in this file by path
> path (string)
< result (lib.luapi.type|string)
]]
function File:get_type(path)
  path = path:gsub('@', self.reqpath)
  local len = self.reqpath:len()
  if path:sub(1, len) == self.reqpath then
    local type_name = path:sub(len+2, -1)
    local divider = len+1
    divider = path:sub(divider, divider)
    if divider == ':' then
      return self.module[type_name]
    elseif divider == '#' then
      return self.locals[type_name]
    end
  end
  return path
end


function File:cleanup()
  self.output  = nil
  self.content = nil
end


return File
