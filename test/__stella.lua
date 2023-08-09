local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actions = {
    TestAction = 1,
    TestAction2 = 2,
}

return {
    Whitelisted = {
        { Type = "UserId", Id = 540209459 }
    },
    DataTemplate = {
        a = 1,
        b = "test",
        c = false,
    },
    DataScope = "FrameworkTest",
    DebugEnabled = true,
    NetworkDebugEnabled = false,
    ModuleLoadAnalysisReport = true,
    UIDevelopmentResolution = Vector2.new(1280, 720),

    ControlActions = actions,
    ControlMap = {
        ["pc"] = {
            {
                kind = "KeyCode",
                state = Enum.UserInputState.Begin,
                value = Enum.KeyCode.Q,
                action = actions.TestAction
            },
        },
        ["xbox"] = {},
        ["mobile"] = {},
    },

    TestMode = true,
}