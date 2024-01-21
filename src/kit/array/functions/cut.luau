--!nonstrict
--[[
    FileName    > cut.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]


type array = {[number]: any}

--[[
    @param array
    @return array{new}

    Cut an array from the start index (i) until the end index (j)
]]
local function cut(array: array, i: number, j: number)
    local arraySize = #array

    local diff = j - i
    local range = math.abs(diff)

    if (range == arraySize - 1) then
        return array
    end

    local cutArray = table.create(arraySize)

    if diff > 0 then
        -- Faster, but table.move doesn't support iterating backwards over a range
        return table.move(array, i, j, 1, {})
    end

    local result = table.create(range)
    local currentIndex = 1

    for index = i, j, -1 do
        result[currentIndex] = array[index]
        currentIndex += 1
    end

    return result
end

return cut