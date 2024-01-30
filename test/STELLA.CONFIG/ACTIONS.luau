local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stella = require(ReplicatedStorage.Packages.stella)
local actions = stella.actions

--[[
    Categories
    noMovement
    noJump
    arrested
    uiFocused
]]

return {
    Forward = actions.new("$noMovement&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.W),
        --:SetPrimitiveInput("console", ),
    Leftward = actions.new("$noMovement")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.A),
    Downward = actions.new("$noMovement")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.S),
    Rightward = actions.new("$noMovement")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.D),
    Jump = actions.new("$noJump&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.Space)
        :SetPrimitiveInput("console", Enum.KeyCode.ButtonA, "$uiFocused")
}