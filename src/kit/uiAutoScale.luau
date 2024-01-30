--!nonstrict
--[[
    FileName    > UIScaler.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 05/01/2024
--]]

--[[
    Services
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

if not Players.LocalPlayer then
    error("no local client available")
end

--[[
    Variables
]]
local root = script.Parent.Parent
local dependencies = root.dependencies
local Signal = require(dependencies.Signal)
local utility = require(root.utility)
local gui = Players.LocalPlayer:WaitForChild("PlayerGui") :: typeof(StarterGui) & PlayerGui
local camera = workspace.CurrentCamera

local ScaleValueChanged = Signal.new()
local ScaleModeChanged = Signal.new()

local scaleMode = 0
local scale = 1
local autoScaleValue = 1

local uiAutoScale_RAW = {
    ScaleMode = 0,
    Scale = 1,
    AutoScaleValue = 0,

    ScaleValueChanged = ScaleValueChanged,
    ScaleModeChanged = ScaleModeChanged
}

local uiAutoScale = setmetatable(uiAutoScale_RAW, {
    __newIndex = function(_, index, value)
        if index ~= "ScaleMode" then
            error("Cannot overwrite " .. index)
        end
        local current = uiAutoScale_RAW[index]
    
        if value ~= current then
            uiAutoScale_RAW[index] = value
            ScaleModeChanged:Fire(value, current)
        end
        return
    end,
    __index = uiAutoScale_RAW
})

local scalerTemplate = Instance.new("UIScale")
scalerTemplate.Name = "Scaler"
scalerTemplate.Scale = 1

--[[
    Functions
]]

local function AddGuiObject(
    guiObject: GuiObject, scale: number
)
    local scaler = guiObject:FindFirstChild("Scaler") :: UIScale

    if not scaler then
        local newScaler = scalerTemplate:Clone()
        newScaler.Parent = guiObject

        scaler = newScaler
    end

    scaler.Scale = scale
end

local function UpdateScale(
    newScale: number
)
    local count = 0
    for _, guiObject in CollectionService:GetTagged(utility.settings.UI_SCALE_TAG) do
        if guiObject:IsA("GuiObject") then
            if utility.settings.DEBUG_ENABLED then
                warn("Debug [UIScaler] instance must be a GuiObject") 
            end
            continue 
        end

        --ScaleGuiObject(guiObject, newScale)
        local scaler = guiObject:FindFirstChild("Scaler") :: UIScale

        if not scale then
            if utility.settings.DEBUG_ENABLED then
                warn("Debug [UIScaler] instance does not have a Scaler") 
            end
            continue
        end

        scaler.Scale = scale

        count += 1
    end

    if utility.settings.DEBUG_ENABLED then
        print(`Scale mode updated, updated {count}/{#CollectionService:GetTagged(utility.settings.UI_SCALE_TAG)}`)
    end
end

local function GetScaleFromResolution(
    resolution: Vector2
)
    local index = 1

    for i, resolutionRequirement in utility.settings.UI_SCALE_THRESHOLD do
        if resolution.X < resolutionRequirement.X or resolution.Y < resolutionRequirement.Y then
            break
        end
        index = i
    end

    return utility.settings.UI_SCALE_MODES[index]
end

--[[
    Code
]]

function uiAutoScale.start()
    if not gui then
        -- How does this happen ??!
        warn("ABORT [UIScaler]: PlayerGui does not exist!")
        return
    end
    
    ScaleModeChanged:Connect(function(new)
        if new == 0 then
            UpdateScale(uiAutoScale_RAW.AutoScaleValue)
        else
            UpdateScale(utility.settings.UI_SCALE_MODES[new])
        end
    end)
    
    -- All GuiObject under the PlayerGui with the {AutoScaleTag} collection tag is picked up and auto scaled
    -- Default collection tag is "AutoScale"
    for _, instance in gui:GetDescendants() do
        if instance:IsA("GuiObject") and instance:HasTag(utility.settings.UI_SCALE_TAG) then
            local scaleMode = uiAutoScale_RAW.ScaleMode
            if scaleMode == 0 then
                AddGuiObject(instance, uiAutoScale_RAW.AutoScaleValue)
            else
                AddGuiObject(instance, utility.settings.UI_SCALE_MODES[scaleMode])
            end
        end
    end
    
    gui.DescendantAdded:Connect(function(instance) 
        if instance:IsA("GuiObject") and instance:HasTag(utility.settings.UI_SCALE_TAG) then
            local scaleMode = uiAutoScale_RAW.ScaleMode
            if scaleMode == 0 then
                AddGuiObject(instance, uiAutoScale_RAW.AutoScaleValue)
            else
                AddGuiObject(instance, utility.settings.UI_SCALE_MODES[scaleMode])
            end
        end
    end)
    
    -- Assign a scale factor based on viewport resolution
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() 
        uiAutoScale_RAW.AutoScaleValue = GetScaleFromResolution(camera.ViewportSize)
        if uiAutoScale_RAW.ScaleMode == 0 then
            UpdateScale(uiAutoScale_RAW.AutoScaleValue)
        end
    end)
    uiAutoScale_RAW.AutoScaleValue = GetScaleFromResolution(camera.ViewportSize)
end

return uiAutoScale