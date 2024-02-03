local RunService = game:GetService("RunService")
local Encode
do
	local Key = game.JobId .. ";" .. game.PlaceVersion
	Encode = function(s)
		if s == "" then
			return ""
		end

		local newString = ""
		local currentKeyCharacter = 0
		for currentStringCharacter = 1, #s, 1 do
			currentKeyCharacter = (currentKeyCharacter % #Key) + 1
			newString = newString
				.. string.char(
					(
						string.byte(s:sub(currentStringCharacter, currentStringCharacter))
						+ string.byte(Key:sub(currentKeyCharacter, currentKeyCharacter))
					) % 255
				)
		end
		return newString
	end

	if RunService:IsStudio() then
		Encode = function(s)
			return s
		end
	end
end

return Encode
