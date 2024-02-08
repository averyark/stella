--!nonstrict
--[[
	FileName    > encodeNew.luau
	Author      > AveryArk
	Contact     > Twitter: https://twitter.com/averyark_
	Created     > 07/02/2024
--]]

local RunService = game:GetService("RunService")
local Encode
do
	local key = game.JobId .. ";" .. game.PlaceVersion
	local keyByte = string.byte(key)
	Encode = function(str)
		if str == "" then
			return ""
		end

		local newString = ""

		for i = 1, #str do
			local shiftedChar = string.char((string.byte(str[i]) + keyByte)%255)
			
			newString = newString .. shiftedChar
		end
		
		return newString
	end
end

return Encode
