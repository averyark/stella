--!nonstrict
--[[
    FileName    > actions.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local root = script.Parent.Parent
local dependencies = root.dependencies

local Janitor = require(ReplicatedStorage.Packages.stella.dependencies.Janitor)
local t = require(dependencies.t)
local Signal = require(dependencies.Signal)

local isClient = RunService:IsClient()

local class = {}
class.__index = class

local actions = {}
local categories = {}

local categoryChanged = Signal.new()

local IMAGE_RECT_OFFSET_END = Vector2.new(1, 146)
local IMAGE_RECT_OFFSET_BEGAN = Vector2.new(146, 146)
local IMAGE_RECT_SIZE = Vector2.new(144, 144)
local IMAGE_DEFAULT_ID = "rbxassetid://16147465077"
local IMAGE_LABEL_COLOR_BEGAN = Color3.fromRGB(55, 55, 55)
local IMAGE_LABEL_COLOR_END = Color3.fromRGB(200, 200, 200)

local buttonsScreenGui
local buttonsFrame
local buttonTemplate
local buttonLabelTemplate

if Players.LocalPlayer then
    buttonsScreenGui = Instance.new("ScreenGui")
    buttonsScreenGui.Name = "buttons"
    buttonsScreenGui.DisplayOrder = 999
    buttonsScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    buttonsFrame = Instance.new("Frame")
    buttonsFrame.Transparency = 1
    buttonsFrame.BorderSizePixel = 0
    buttonsFrame.Parent = buttonsScreenGui
    buttonsFrame.Size = UDim2.fromScale(1, 1)

    buttonTemplate = Instance.new("ImageButton")
    buttonTemplate.Name = "__button"
    buttonTemplate.Size = UDim2.fromOffset(70, 70)
    buttonTemplate.ImageRectSize = IMAGE_RECT_SIZE
    buttonTemplate.ImageRectOffset = IMAGE_RECT_OFFSET_END
    buttonTemplate.ScaleType = Enum.ScaleType.Slice
    buttonTemplate.Transparency = 1
    buttonTemplate.Active = false

    buttonLabelTemplate = Instance.new("TextLabel")
    buttonLabelTemplate.BackgroundTransparency = 1
    buttonLabelTemplate.TextTransparency = 0.3
    buttonLabelTemplate.TextColor3 = IMAGE_LABEL_COLOR_END
    buttonLabelTemplate.TextSize = 16
    buttonLabelTemplate.Text = ""
    buttonLabelTemplate.Size = UDim2.fromScale(1, 1)
    buttonLabelTemplate.AnchorPoint = Vector2.new(.5, .5) 
    buttonLabelTemplate.Position = UDim2.fromScale(.5, .5)
end

type input = Enum.UserInputType | Enum.KeyCode | {Enum.KeyCode} | ImageButton

local assertInput = t.strict(t.union(t.enum(Enum.UserInputType), t.enum(Enum.KeyCode)), t.instanceIsA("ImageButton"))

local function GetCategoriesFromSpecialString(specialString: string)
    return specialString:split("&&"), specialString:sub(1, 1) == "$"
end

local function IsCategoryActive(category: string)
    -- Filter category
    local actionCategories, disclude = GetCategoriesFromSpecialString(category)

    for _, category in actionCategories do
        if disclude then
            if categories[category] then
                return false
            end
        else
            if not categories[category] then
                return false
            end     
        end
    end

    return true
end

local function AreKeycodesDown(keycodes: {Enum.KeyCode})
    for _, keycode in keycodes do
        if not UserInputService:IsKeyDown(keycode) then
            return false
        end
    end
    return true
end

--[[
    @param category: string
    @param state: boolean
    @return void
    
    Change the state of a category
]]
local function ChangeCategoryEnabled(category: string, state: boolean)
    if categories[category] ~= state then
        local cache = categories[category]
        categories[category] = state
        categoryChanged:Fire(category, state, cache)
    end
end

--[[
    Action class
    
]]
local function new(category: string?)
    local self = setmetatable({}, class)
    
    -- Properties
    self.PrimitiveInput = {} :: {input}?
    self.Input = {} :: {{value: input, category: string?}}?
    self.Category = category
    self.Loaded = false
    self.Enabled = true
    self.IsActivated = false
    self.Id = HttpService:GenerateGUID(false)

    -- Signals
    self.OnInputChanged = Signal.new()
    self.OnLoaded = Signal.new()
    self.OnAction = Signal.new()

    -- Private
    self._maid = Janitor.new()

    -- Initialization

    if self.Category and not categories[self.Category] then
        categories[self.Category] = true
    end

    table.insert(actions, self)

    self._maid:Add(categoryChanged:Connect(function() 
        for _, activeInput in self.Input do
            if type(activeInput.value) ~= "userdata" then continue end

            if not self.Loaded then continue end
            if not self.Enabled then continue end

            if activeInput.category and not IsCategoryActive(activeInput.category) then
                activeInput.value.Visible = false
                continue
            end
            if self.Category and not IsCategoryActive(self.Category) then
                activeInput.value.Visible = false
                continue
            end
            
            activeInput.value.Visible = true
        end
    end))

    for _, signal in self do
        if Signal.Is(signal) then
            self._maid:Add(signal)
        end
    end

    return self
end

type action = typeof(new(...))

-- function class.Call(self: action,)
    
-- end

--[[
    @class Action
    @param callback: (inputObject: InputObject, processed: boolean)
    @param processed: boolean
    @return Signal<Connection>
]]
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
    @class Action
    @param identifier
    @param newInput
    @return self
    @chainable true
]]
function class.ChangeInput(self: action, identifier: string, newInput: input & any, categoryAppend: string?)
    assertInput(newInput)

    local oldInput = self.Input[identifier]
    self.Input[identifier] = {
        value = newInput,
        category = categoryAppend,
        
    }
    self.InputChanged:Fire(identifier, oldInput, newInput)

    if type(newInput) == "userdata" then
        newInput.InputBegan:Connect(function(inputObject, processed) 
            if not self.Loaded then return end
            if not self.Enabled then return end

            if inputObject.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if categoryAppend and not IsCategoryActive(categoryAppend) then
                return
            end

            if self.Category and not IsCategoryActive(self.Category) then
                return
            end

            if not self.IsActivated then
                self.IsActivated = true
                self.OnAction:Fire(inputObject, processed) 
            end

            local label = newInput:FindFirstChildOfClass("TextLabel")

            if label then
                label.TextColor3 = IMAGE_LABEL_COLOR_BEGAN 
            end

            newInput.ImageRectOffset = IMAGE_RECT_OFFSET_BEGAN
        end)
        UserInputService.InputEnded:Connect(function(inputObject, processed)
            if inputObject.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if self.IsActivated then
                self.IsActivated = false
                self.OnAction:Fire(inputObject, processed)
            end
        
            local label = newInput:FindFirstChildOfClass("TextLabel")

            if label then
                label.TextColor3 = IMAGE_LABEL_COLOR_END 
            end

            newInput.ImageRectOffset = IMAGE_RECT_OFFSET_END
        end)
        
        if self.Enabled and self.Loaded then
            newInput.Visible = true
        else
            newInput.Visible = false        
        end
    end

    return self
end

--[[
    @class Action
    @param identifier
    @param primitiveInput
    @return self
    @chainable true

    Changes the primitive input. .OnLoaded is fired if no primitive input is already loaded
]]
function class.SetPrimitiveInput(self: action, identifier: string,  primitiveInput: input, categoryAppend: string?)
    self.PrimitiveInput[identifier] = {
        value = primitiveInput,
        cateogry = categoryAppend
    }

    if not self.Loaded then
       self.Loaded = true
       self.OnLoaded:Fire()
    end

    if not self.Input[identifier] then
        self:Reset(identifier) 
    end

    return self
end

--[[
    @class Action
    @param identifier: string?
    @return self
    @chainable true

    Resets the input for one id if specified or all if not
]]
function class.Reset(self: action, identifier: string?)
    if identifier then
        self.Input[identifier] = self.PrimitiveInput[identifier]
        self:ChangeInput(identifier, self.PrimitiveInput[identifier])
    else
        for id, input in self.PrimitiveInput do
            self:ChangeInput(id, input)
        end
    end
    return self
end

local function start()
    if isClient then
        local processedActions = {}
        local function processInput(inputObject: InputObject, processed)
            debug.profilebegin("Processing Input")
            for _, action in actions do
                if not action.Loaded then continue end
                if not action.Enabled then continue end
                if table.find(processedActions, action.Id) then continue end
                
                -- Filter category
                if action.Category and not IsCategoryActive(action.Category) then
                    continue
                end
    
                local triggered = false
                
                for _, input in action.Input do
                    if input.category and not IsCategoryActive(input.category) then
                        continue
                    end
                    if type(input.value) == "table" then
                        if not AreKeycodesDown(input.value) then
                            triggered = false
                        else
                            triggered = true
                            break
                        end
                    elseif type(input.value) == "userdata" then
                        continue
                    elseif input.value.EnumType == Enum.KeyCode then
                        if input.value ~= inputObject.KeyCode then
                            triggered = false
                        else
                            triggered = true
                            break                        
                        end
                    elseif input.value.EnumType == Enum.UserInputType then
                        if input.value ~= inputObject.UserInputType then
                            triggered = false
                        else
                            triggered = true
                            break
                        end
                    end
                end
    
                if triggered then
                    if inputObject.UserInputState == Enum.UserInputState.Begin then
                        if not action.IsActivated then
                            action.IsActivated = true
                            action.OnAction:Fire(inputObject, processed) 
                        end
                    elseif inputObject.UserInputState ~= Enum.UserInputState.Change then
                        if action.IsActivated then
                            action.IsActivated = false
                            action.OnAction:Fire(inputObject, processed) 
                        end
                    else
                        action.OnAction:Fire(inputObject, processed)
                    end 
                    
                    action.IsActivated = true
                end
            end
            debug.profileend()
        end
        UserInputService.InputBegan:Connect(processInput)
        UserInputService.InputEnded:Connect(processInput)
        UserInputService.InputChanged:Connect(processInput)
        RunService.Heartbeat:Connect(function() 
            table.clear(processedActions)
        end)
    end 
end

local function newButton(position: UDim2, image: string, text: string?)
    local button = buttonTemplate:Clone()
    button.Parent = buttonsFrame
    button.Visible = false
    button.Position = position

    if text and not image then
        local label = buttonLabelTemplate:Clone()
        label.Parent = button
        label.Text = text
    end

    return button
end

return {
    start = start,
    new = new,
    Button = newButton,
    ChangeCategoryEnabled = ChangeCategoryEnabled,
}
