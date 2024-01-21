--!nonstrict
--[[
    FileName    > actions.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local t = require(script.Parent.Parent.dependencies.t)
local Signal = require(script.Parent.Parent.dependencies.Signal)

local isClient = RunService:IsClient()

local class = {}
class.__index = class

local actions = {}
local categories = {}

local DEFAULT_CATEGORY = "Default"

type input = Enum.UserInputType | Enum.KeyCode

local assertInput = t.union(t.Enum(Enum.UserInputType), t.Enum(Enum.KeyCode))

--[[
    "a 
]]
local function new(category: string)
    local self = setmetatable({}, class)
    
    -- Properties
    self.PrimitiveInput = nil :: {input}?
    self.Input = nil :: {input}?
    self.Category = category or DEFAULT_CATEGORY
    self.Loaded = false
    self.Enabled = true

    -- Signals
    self.OnInputChanged = Signal.new()
    self.OnLoaded = Signal.new()
    self.OnAction = Signal.new()

    -- Initialization

    if not categories[self.Category] then
        categories[self.Category] = true
    end

    table.insert(actions, self)

    return self
end

type action = typeof(new(...))

function class.ConnectFiltered(self: action, callback: (inputObject: InputObject, processed: boolean) -> (), stateFilter: Enum.UserInputState?, shouldFilterProcessed: boolean?)
    return self.OnAction:Connect(function(inputObject: InputObject, processed: boolean)
        if stateFilter and inputObject.UserInputState ~= stateFilter then
            return
        end
        if shouldFilterProcessed and processed then
            return
        end

        callback(inputObject, processed)
    end)
end

--[[
    @param identifier
    @param newInput
    @return self 
    @chainable true
]]
function class.ChangeInput(self: action, identifier: string, newInput: input)
    assertInput(newInput)

    local oldInput = self.Input[identifier]
    self.Input[identifier] = newInput
    self.InputChanged:Fire(identifier, oldInput, newInput)

    return self
end

--[[
    @param identifier
    @param primitiveInput
    @return self
    @chainable true

    Changes the primitive input. .OnLoaded is fired if no primitive input is already loaded
]]
function class.SetPrimitiveInput(self: action, identifier: string,  primitiveInput: input)
    self.PrimitiveInput[identifier] = primitiveInput

    if not self.Loaded then
       self.Loaded = true
       self.OnLoaded:Fire()
    end

    return self
end

--[[
    @param identifier?
    @return self
    @chainable true

    Resets the input for one id if specified or all if not
]]
function class.Reset(self: action, identifier: string?)
    if identifier then
        self.Input[identifier] = self.PrimitiveInput[identifier]
    else
        for id, input in self.PrimitiveInput do
            self.Input[id] = input
        end
    end
    return self
end

local function GetCategoriesFromSpecialString(specialString: string)
    return specialString:split("&&")
end

--[[
    @param category
    @return void
    
    Change the state of a category
]]
local function ChangeCategoryEnabled(category: string, state: boolean)
    categories[category] = state
end

local function start()
    if isClient then
        local function processInput(inputObject: InputObject, processed)
            debug.profilebegin("Processing Input")
            for _, action in actions do
                if not action.Loaded then continue end
                if not action.Enabled then continue end
                
                -- Filter category
                local actionCategories = GetCategoriesFromSpecialString(action.Category)
    
                local categoryMatched = true
    
                for _, category in actionCategories do
                    if not categories[category] then
                        categoryMatched = false
                        break
                    end
                end
    
                if not categoryMatched then
                    continue
                end
    
                local triggered = false
                
                for _, input in action.Input do
                    if 
                        (input.EnumType == Enum.UserInputType and input == inputObject.UserInputType)
                        or (input.EnumType == Enum.KeyCode and input == inputObject.KeyCode)
                    then
                        triggered = true
                        break
                    end
                end
    
                if triggered then
                    action.OnAction:Fire(inputObject, processed)
                end
            end
            debug.profileend()
        end
        UserInputService.InputBegan:Connect(processInput)
        UserInputService.InputEnded:Connect(processInput)
        UserInputService.InputChanged:Connect(processInput)
    end 
end

return {
    start = start,
    new = new,
    ChangeCategoryEnabled = ChangeCategoryEnabled
}