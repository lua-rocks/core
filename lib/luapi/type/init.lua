-- There is 4 general types: "class", "function", "table" and "simple".
-- Type "class" cannot be directly defined by user.
-- User must extend it from other type.


local Object = require 'lib.object'
local Type = Object:extend 'lib.luapi.type'


--[[ TODO: Create type from block.
> raw_block (string) []
]]
function Type:new(raw_block)
  local parsed_block = require 'lib.luapi.block' (raw_block)
end


return Type