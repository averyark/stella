--!nonstrict
--[[
    FileName    > tags.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 18/01/2024
--]]

local root = script.Parent.Parent
local dependencies = root.dependencies

local clock = require(root.kit.clock)
local Janitor = require(dependencies.Janitor)
local Signal = require(dependencies.Signal)

local tag = {}
tag.__index = tag

local numberValue = Instance.new("NumberValue")

local tags = {}

local function new(identifier: string)
    assert(not tags[identifier], "a tag with this name already exist")
    local self = setmetatable({}, tag)

    -- Properties
    self.Identifier = identifier
    self.Tagged = {} :: {IntValue}

    -- Signals
    self.OnTagged = Signal.new()
    self.OnTagRemoved = Signal.new()
    self.OnInstanceTagged = Signal.new()

    -- Private
    self._tagCount = 0
    self._maid = Janitor.new()
    
    -- Initialization
    tags[identifier] = self

    return self
end

type tag = typeof(new(...))

function tag.Remove(self: tag, instance: Instance, id: string)
    if self.Tagged[id] then
        self.Tagged[id]:Destroy()
        self.Tagged[id] = nil
        self.OnTagRemoved:Fire(instance, id)

        -- Make sure there's no other tags anymore
        local isTagged = instance:FindFirstChild(self.Identifier)

        if not isTagged then
            self.OnInstanceTagged:Fire(instance, false)
        end
    end
end

function tag.Add(self: tag, instance: Instance, interval: number?)
    self._tagCount += 1
    local id = self.Identifier .. tostring(self._tagCount)

    local wasTagged = instance:FindFirstChild(self.Identifier)

    local valueObject = numberValue:Clone()
    valueObject.Name = self.Identifier
    valueObject.Value = interval or -1
    valueObject.Parent = instance

    self.Tagged[id] = valueObject

    -- Make sure it wasn't already tagged
    self.OnTagged:Fire(instance, id, interval)

    if not wasTagged then
        self.OnInstanceTagged:Fire(instance, true)
    end

    return id
end

function tag.IsTagged(self: tag, instance: Instance)
    if instance:FindFirstChild(self.Identifier) then
        return true
    end
    return false
end

function tag.ListenToInstance(self: tag, instance: Instance, callback: (state: boolean) -> ())
    local isTagged = self:IsTagged(instance)
    
    if isTagged then
        callback(true)
    else
        callback(false)
    end

    local count = 0

    local connections = {}

    table.insert(connections, instance.ChildAdded:Connect(function(object)
        if object:IsA("NumberValue") and object.Name == self.Identifier then
            count += 1
            if count == 1 then
                callback(true)
            end
        end
    end))

    table.insert(connections, instance.ChildRemoved:Connect(function(object)
        if object:IsA("NumberValue") and object.Name == self.Identifier then
            count -= 1
            if count == 0 then
                callback(false)
            end
        end
    end))

    return {
        Disconnect = function()
            for _, connection in connections do
                if connection.Disconnect then
                    connection:Disconnect()
                end
            end
            table.clear(connections)
        end
    }
end

function tag.Destroy(self: tag)
    tags[self.Identifier] = nil
end

local function get(identifier: string)
    if not tags[identifier] then
        return new(identifier)
    end
    return tags[identifier]
end

--[[
    Only the tags created locally are handled.
    However, ListenToInstance and GetTagged will still account for
    replicated tags
    EXCLUDING
        self.OnTagged
        self.OnTagRemoved
        self.OnInstanceTagged
]]
local function start()
    clock.new(1/60, function(dt) 
        for _, self in tags do
            local skip = {}
            for id, valueObject in self.Tagged do
                if valueObject.Value == -1 then
                    continue
                end
                if table.find(skip, valueObject.Parent) then
                    continue
                end
                table.insert(skip, valueObject.Parent)
                valueObject.Value = valueObject.Value - dt
                if valueObject.Value <= 0 then
                    self:Remove(valueObject.Parent, id)
                end
            end
        end
    end)
end

return {
    start = start,
    new = new,
    Get = get
}