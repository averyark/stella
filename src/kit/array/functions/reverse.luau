--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(script.Parent.Parent.Parent.Parent.dependencies.t)
--[[
    FileName    > reverse.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

type array = {[number]: any}

--[[
    @param array
    @returns array{new}

    Reverse an array
]]
local function reverse(array: array)
    local arraySize = #array
    local reversedArray = table.create(arraySize)

    for i = 1, arraySize do
        reversedArray[i] = array[arraySize - i + 1]
    end

    return reversedArray
end

return reverse