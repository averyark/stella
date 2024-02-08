--!nonstrict
--[[
	FileName    > encodeNew.luau
	Author      > AveryArk
	Contact     > Twitter: https://twitter.com/averyark_
	Created     > 07/02/2024
--]]

-- randomise the text so client can't tell what's the purpose of the remote. just a fun side project

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local array = require(ReplicatedStorage.Packages.stella.kit.array)
local utility = require(ReplicatedStorage.Packages.stella.utility)
local Encode
local chars = {
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", 
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "}", "[", "]", "|", "\\", ":", ";", "\"", "'", "<", ",", ">", ".", "?", "/"
}
local size = #chars

if RunService:IsServer() then
	chars = array.shuffle(chars, math.randomseed(math.sin(os.time())))
	local value = Instance.new("StringValue")
	value.Value = table.concat(chars, "")
	value.Name = "rsc"
	value.Parent = ReplicatedStorage
else
	chars = ReplicatedStorage:WaitForChild("rsc").Value:split("")
end

do
	local key
	if not RunService:IsStudio() then
		key = game.JobId .. ";" .. game.PlaceVersion
	else
		if utility.settings.DEBUG_ENABLED then
			Encode = function(str)
				return str
			end
			return Encode
		end
		key = game.PlaceId
	end
	
	local keyByte = math.ceil(string.byte(key)/math.pi)
	
	Encode = function(str)
		if str == "" then
			return ""
		end

		local newString = ""
		local strArray = str:split("")
		local indexArray = {}
		local accumulate = 0
		local strSize = #strArray

		if strSize < 64 then
			for i = 1, 64 - strSize do
				table.insert(strArray, chars[i])
			end
		end

		for i, s in strArray do
			local index = table.find(chars, s)
			indexArray[i] = index
			accumulate += index
		end

		for i, s in strArray do
			newString = newString .. chars[(indexArray[i] + keyByte - accumulate + i)%size + 1]
		end
		
		return newString
	end
end

return Encode
