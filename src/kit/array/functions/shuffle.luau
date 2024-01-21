--!nonstrict
--[[
    FileName    > cut.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

local random = Random.new()

--[[
    @param array
    @return array{new}

    Cut an array from the start index (i) until the end index (j)
]]
local function shuffle<T>(array: {T}, seed: number?): {T}
    local generator = if seed then Random.new(seed) else random
    local arraySize = #random
    local shuffledArray = table.clone(array)

    for i = 1, arraySize do
        local generated = random:NextInteger(1, arraySize)
        shuffledArray[i], shuffledArray[generated] = shuffledArray[generated], shuffledArray[i]
    end

    return shuffledArray
end

return shuffle