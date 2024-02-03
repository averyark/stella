--!nonstrict
--[[
    FileName    > cut.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

type array = { [number]: any }

--[[
    @param array
    @return array{new}

    Merge arrays
]]
local function merge(...: array)
	local mergedArray = {}

	for i = 1, select("#", ...) do
		for k, v in select(i, ...) do
			mergedArray[k] = v
		end
	end

	return mergedArray
end

return merge :: <K0, V0, K1, V1>({ [K0]: V0 }, { [K1]: V1 }, ...any) -> { [K0 | K1]: { V0 | V1 } }
