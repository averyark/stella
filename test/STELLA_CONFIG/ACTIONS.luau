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

actions.Category("noMovement", false)
actions.Category("arrested", false)
actions.Category("noJump", false)

return {
    Forward = actions.new("moveForward", "$noMovement&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.W),
        --:SetPrimitiveInput("console", ),
    Leftward = actions.new("moveLeftward", "$noMovement&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.A),
    Downward = actions.new("moveDownward", "$noMovement&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.S),
    Rightward = actions.new("moveRightward", "$noMovement&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.D),
    Jump = actions.new("jump", "$noJump&&arrested")
        :SetPrimitiveInput("keyboard", Enum.KeyCode.Space)
        :SetPrimitiveInput("console", Enum.KeyCode.ButtonA, "$uiFocused")
}