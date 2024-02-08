--!nonstrict
local SoundService = game:GetService("SoundService")
--[[
    FileName    > sound.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 06/02/2024
--]]

local sound = {}

local modifiers = {
    Volume = 0.5,
    Speed = 1,
    StartPosition = 0,
    RollOffMaxDistance = 10000,
    RollOffMinDistance = 10,
    RollOffMode = Enum.RollOffMode.InverseTapered,
    Looped = false,
    SoundEffects = {}
}

local chorus = Instance.new("ChorusSoundEffect")
local distortion = Instance.new("DistortionSoundEffect")
local echo = Instance.new("EchoSoundEffect")
local equalizer = Instance.new("EqualizerSoundEffect")
local pitch = Instance.new("PitchShiftSoundEffect")
local reverb = Instance.new("ReverbSoundEffect")

local soundEffects = {
    Chorus = function(depth: number?, mix: number?, rate: number?, priority: number?)
        local soundEffect = chorus:Clone()
        soundEffect.Depth = depth or soundEffect.Depth
        soundEffect.Mix = mix or soundEffect.Mix
        soundEffect.Rate = rate or soundEffect.Rate
        soundEffect.Priority = priority or soundEffect.Priority
        return soundEffect
    end,
    Distortion = function(level: number?, priority: number?)
        local soundEffect = distortion:Clone()
        soundEffect.Level = level or soundEffect.Level
        soundEffect.Priority = priority or soundEffect.Priority
        return soundEffect
    end,
    Echo = function(delay: number?, dryLevel: number?, wetLevel: number?, feedback: number?, priority: number?)
        local soundEffect = echo:Clone()
        soundEffect.Delay = delay or soundEffect.Delay
        soundEffect.DryLevel = dryLevel or soundEffect.DryLevel
        soundEffect.Feedback = feedback or soundEffect.Feedback
        soundEffect.WetLevel = wetLevel or soundEffect.WetLevel
        soundEffect.Priority = priority or soundEffect.Priority
        return soundEffect
    end,
    Equalizer = function(highGain: number?, lowGain: number?, midGain: number?, priority: number?)
        local soundEffect = equalizer:Clone()
        soundEffect.HighGain = highGain or soundEffect.HighGain
        soundEffect.LowGain = lowGain or soundEffect.LowGain
        soundEffect.MidGain = midGain or soundEffect.MidGain
        soundEffect.Priority = priority or soundEffect.Priority        
        return soundEffect
    end,
    Pitch = function(octave: number?, priority: number?)
        local soundEffect = pitch:Clone()
        soundEffect.Octave = octave or soundEffect.Octave
        soundEffect.Priority = priority or soundEffect.Priority
        return soundEffect
    end,
    Reverb = function(decayTime: number?, density: number?, diffusion: number?, dryLevel: number?, wetLevel: number?, priority: number?)
        local soundEffect = reverb:Clone()
        soundEffect.Delay = decayTime or soundEffect.DecayTime
        soundEffect.DryLevel = dryLevel or soundEffect.DryLevel
        soundEffect.Density = density or soundEffect.Density
        soundEffect.Diffusion = diffusion or soundEffect.Diffusion
        soundEffect.WetLevel = wetLevel or soundEffect.WetLevel
        soundEffect.Priority = priority or soundEffect.Priority
        return soundEffect
    end
}

type soundEffects = {SoundEffect?}
type modifiers = {
    Volume: number?,
    Speed: number?,
    StartPosition: number?,
    RollOffMaxDistance: number?,
    RollOffMinDistance: number?,
    RollOffMode: Enum.RollOffMode?,
    Looped: boolean?,
    SoundEffects: soundEffects?
}

local function applyModifiers(sound: Sound, modifiers: modifiers)
    local looped = modifiers.Looped
    if looped ~= nil then
        sound.Loaded = looped
    end
    local rollOffMax = modifiers.RollOffMaxDistance
    if rollOffMax ~= nil then
        sound.RollOffMaxDistance = rollOffMax
    end
    local rollOffMin = modifiers.RollOffMinDistance
    if rollOffMin ~= nil then
        sound.RollOffMinDistance = rollOffMin
    end
    local rollOffMode = modifiers.RollOffMode
    if rollOffMode ~= nil then
        sound.RollOffMode = rollOffMode
    end
    local speed = modifiers.Speed
    if speed ~= nil then
        sound.PlaybackSpeed = speed 
    end
    local startPosition = modifiers.StartPosition
    if startPosition ~= nil then
        sound.TimePosition = startPosition
    end
    local volume = modifiers.Volume
    if volume ~= nil then
        sound.Volume = volume
    end
    if modifiers.SoundEffects then
        for _, soundEffect in modifiers.SoundEffects do
            if not soundEffect:IsA("SoundEffect") then
                continue
            end
            soundEffect.Parent = sound
        end 
    end
    return sound
end

function sound.PlayOnce(instance: Sound, modifier: modifiers?)
    if modifier then
        applyModifiers(instance, modifier) 
    end
    local sound = instance:Clone()
    sound.Parent = SoundService
    sound.Ended:Once(function()
        instance:Destroy()
    end)
    sound:Play()
    return instance
end

local hostPartTemplate = Instance.new("Part")
hostPartTemplate.Name = "soundHostPart"
hostPartTemplate.Size = Vector3.one
hostPartTemplate.Transparency = 1

function sound.PlayOnceAtCFrame(instance: Sound, cframe: CFrame, modifier: modifiers?)
    if modifier then
        applyModifiers(instance, modifier) 
    end
    local hostPart = hostPartTemplate:Clone()
    hostPart.Parent = workspace.Terrain
    hostPart.Name = instance.Name .. "soundHostPart"
    hostPart.CFrame = cframe

    local sound = instance:Clone()
    sound.Parent = hostPart
    sound.Ended:Once(function()
        instance:Destroy()
    end)
    sound:Play()
    return sound
end

function sound.PlayOnceAtPart(instance: Sound, part: BasePart, modifier: modifiers?)
    if modifier then
        applyModifiers(instance, modifier) 
    end
    
    local sound = instance:Clone()
    sound.Parent = instance
    sound.Ended:Once(function()
        instance:Destroy()
    end)
    sound:Play()
    
    return sound
end

sound.SoundEffects = soundEffects

sound.PlayOnce(Instance.new("Sound"), {
    Volume = 2,
    SoundEffects = {
        sound.SoundEffects.Pitch(1)
    }
})

return sound