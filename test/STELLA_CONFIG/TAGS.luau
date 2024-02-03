local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stella = require(ReplicatedStorage.Packages.stella)
local tag = stella.tag

return {
    Stun = tag.new("Stun")
}