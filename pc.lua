--[[
    ╔══════════════════════════════════════════════════════════╗
    ║       DEV MASTER ULTIMATE V2 (AGGRESSIVE GRAPHICS)       ║
    ║       - Aggressive Client-Side Graphics Optimization     ║
    ║       - Extended Sliders & Numeric Inputs (Max 1000)     ║
    ║       - Non-destructive Cache & Auto-reversion           ║
    ║       - Dynamic DescendantAdded Hooking                  ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ==========================================================
-- 1. UNLOAD PREVIOUS SESSION
-- ==========================================================
if _G.DevMasterUnload then
    pcall(_G.DevMasterUnload)
end
_G.stopScript = false

-- ==========================================================
-- 2. COMPATIBILITY LAYER
-- ==========================================================
local function missing(typeCheck, func, fallback)
    if type(func) == typeCheck then return func end
    return fallback
end

local _writefile = writefile
local _readfile = readfile

writefile = missing("function", _writefile) and function(file, data, safe)
    if safe == true then return pcall(_writefile, file, data) end
    _writefile(file, data)
end

readfile = missing("function", _readfile) and function(file, safe)
    if safe == true then return pcall(_readfile, file) end
    return _readfile(file)
end

isfile = missing("function", isfile, readfile and function(file)
    local success, result = pcall(function() return readfile(file) end)
    return success and result ~= nil and result ~= ""
end)

makefolder = missing("function", makefolder)
isfolder = missing("function", isfolder)
listfiles = missing("function", listfiles)

httprequest = missing("function", request or http_request or
    (syn and syn.request) or
    (http and http.request) or
    (fluxus and fluxus.request)
)

queueteleport = missing("function", queue_on_teleport or
    (syn and syn.queue_on_teleport) or
    (fluxus and fluxus.queue_on_teleport)
)

everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or
    (Clipboard and Clipboard.set)
)

firetouchinterest = missing("function", firetouchinterest)
hookfunction = missing("function", hookfunction)
hookmetamethod = missing("function", hookmetamethod)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
checkcaller = missing("function", checkcaller, function() return false end)
newcclosure = missing("function", newcclosure, function(f, ...) return f(...) end)
getgc = missing("function", getgc or get_gc_objects)

setthreadidentity = missing("function", setthreadidentity or
    (syn and syn.set_thread_identity) or
    syn_context_set or setthreadcontext
)

getconnections = missing("function", getconnections or get_signal_cons)
cloneref = missing("function", cloneref, function(...) return ... end)
get_hidden_gui = get_hidden_gui or gethui or function() return game:GetService("CoreGui") end

local syn = syn or {}
syn.protect_gui = syn.protect_gui or function(gui) return gui end

local function hasWriteFile() return type(writefile) == "function" end
local function hasReadFile() return type(readfile) == "function" end
local function hasHttpRequest() return type(httprequest) == "function" end

-- ==========================================================
-- 3. SERVICES & VARIABLES
-- ==========================================================
local Services = {
    UserInput   = game:GetService("UserInputService"),
    RunService  = game:GetService("RunService"),
    Players     = game:GetService("Players"),
    Stats       = game:GetService("Stats"),
    Teleport    = game:GetService("TeleportService"),
    Http        = game:GetService("HttpService"),
    Lighting    = game:GetService("Lighting"),
    Tween       = game:GetService("TweenService"),
    CoreGui     = game:GetService("CoreGui"),
    VirtualUser = game:GetService("VirtualUser"),
    Workspace   = game:GetService("Workspace"),
}

local player = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local camera = Services.Workspace.CurrentCamera
local mouse  = player:GetMouse()

local Connections = {}
local function addConn(conn)
    table.insert(Connections, conn)
    return conn
end

local targetGuiParent = (pcall(get_hidden_gui) and get_hidden_gui()) or Services.CoreGui or player:WaitForChild("PlayerGui")

-- ==========================================================
-- 4. CONFIG & PALETTE
-- ==========================================================
local CONFIG = {
    ESP_UPDATE_INTERVAL   = 0.5,
    STATS_UPDATE_INTERVAL = 0.5,
}

local COLORS = {
    BG_MAIN      = Color3.fromRGB(13, 13, 20),
    BG_TOPBAR    = Color3.fromRGB(17, 17, 32),
    BG_SIDEBAR   = Color3.fromRGB(11, 11, 18),
    BG_SECTION   = Color3.fromRGB(17, 17, 32),
    BG_ROW       = Color3.fromRGB(13, 13, 20),
    BG_INPUT     = Color3.fromRGB(13, 22, 36),
    ACCENT       = Color3.fromRGB(0, 200, 255),
    ACCENT_DIM   = Color3.fromRGB(0, 80, 100),
    TEXT_PRIMARY = Color3.fromRGB(224, 224, 240),
    TEXT_MUTED   = Color3.fromRGB(100, 120, 160),
    TEXT_LABEL   = Color3.fromRGB(154, 170, 187),
    TOG_OFF      = Color3.fromRGB(30, 42, 58),
    TOG_ON       = Color3.fromRGB(0, 85, 102),
    TOG_KNOB_OFF = Color3.fromRGB(51, 68, 85),
    TOG_KNOB_ON  = Color3.fromRGB(0, 200, 255),
    BORDER       = Color3.fromRGB(30, 40, 56),
    GLOW         = Color3.fromRGB(0, 140, 200),
    RED          = Color3.fromRGB(200, 50, 70),
    GREEN        = Color3.fromRGB(0, 180, 120),
    YELLOW       = Color3.fromRGB(200, 160, 0),
    PURPLE       = Color3.fromRGB(160, 80, 220),
}

local originalLighting = {
    Brightness    = Services.Lighting.Brightness,
    ClockTime     = Services.Lighting.ClockTime,
    GlobalShadows = Services.Lighting.GlobalShadows,
    FogEnd        = Services.Lighting.FogEnd,
    Quality       = settings().Rendering.QualityLevel,
}

-- ==========================================================
-- 5. FEATURE STATES
-- ==========================================================
local featureStates = {
    aimbotEnabled       = false,
    triggerbotEnabled   = false,
    fovCircleEnabled    = false,
    wallCheckEnabled    = false,
    noRecoilEnabled     = false,
    infiniteAmmoEnabled = false,
    rapidFireEnabled    = false,
    hitboxEnabled       = false,
    godmodeEnabled      = false,
    clickTpEnabled      = false,
    infJumpEnabled      = false,
    noclipEnabled       = false,
    walkSpeedEnabled    = false,
    jumpPowerEnabled    = false,
    flyEnabled          = false,
    autoJumpEnabled     = false,
    autoSprintEnabled   = false,
    espEnabled          = false,
    fullbrightEnabled   = false,
    antiAfkEnabled      = false,
    freecamEnabled      = false,
    invisibilityEnabled = false,
    autoTpEnabled       = false,
    aggressiveFpsEnabled = false,
}

local aimTarget              = "Head"
local aimSmoothness          = 0.2
local fovRadius              = 120
local hitboxSize             = 5
local customWalkSpeed        = 50
local customJumpPower        = 100
local flySpeed               = 50
local freecamSpeedMultiplier = 1
local autoTpInterval         = 3

local lastTriggerTime        = 0
local lastRapidFireTime      = 0

-- ==========================================================
-- 6. STATUS BADGES
-- ==========================================================
local statusBadges = {}

local function updateStatusBadge(key, state)
    if statusBadges[key] then
        statusBadges[key].Text             = state and "ON" or "OFF"
        statusBadges[key].BackgroundColor3 = state and Color3.fromRGB(0, 51, 34) or Color3.fromRGB(34, 10, 10)
        statusBadges[key].TextColor3       = state and COLORS.GREEN or COLORS.RED
    end
end

-- ==========================================================
-- 7. FILE OPERATIONS
-- ==========================================================
local function saveFile(fileName, data)
    if not hasWriteFile() then return false end
    local success = pcall(function() writefile(fileName, data, true) end)
    return success
end

local function loadFile(fileName)
    if not hasReadFile() or not isfile(fileName) then return nil end
    local success, data = pcall(function() return readfile(fileName, true) end)
    return success and data or nil
end

-- ==========================================================
-- 8. UI HELPERS
-- ==========================================================
local function makeDraggable(gui)
    local dragging = false
    local dragStart, startPos

    addConn(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = gui.Position
        end
    end))

    addConn(Services.UserInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    addConn(Services.UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function createToggle(parent, labelText, featureKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 40)
    frame.BackgroundColor3 = COLORS.BG_SECTION
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = COLORS.BORDER
    stroke.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TEXT_LABEL
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 38, 0, 20)
    track.Position = UDim2.new(1, -50, 0.5, -10)
    track.BackgroundColor3 = COLORS.TOG_OFF
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = COLORS.TOG_KNOB_OFF
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = false
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

    local function setState(val, silent)
        state = val
        if featureKey then
            featureStates[featureKey] = val
            updateStatusBadge(featureKey, val)
        end
        Services.Tween:Create(track, tweenInfo, {
            BackgroundColor3 = val and COLORS.TOG_ON or COLORS.TOG_OFF
        }):Play()
        Services.Tween:Create(knob, tweenInfo, {
            Position = val and UDim2.new(0, 21, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = val and COLORS.TOG_KNOB_ON or COLORS.TOG_KNOB_OFF
        }):Play()
        if not silent and callback then callback(val) end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return {
        frame = frame,
        getState = function() return state end,
        setState = setState,
        btn = btn,
    }
end

-- Slider cho phep nhap so vuot nguong va keo den maxVal
local function createSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 40)
    frame.BackgroundColor3 = COLORS.BG_SECTION
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = COLORS.BORDER
    stroke.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.38, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TEXT_LABEL
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0.3, 0, 0, 4)
    track.Position = UDim2.new(0.40, 0, 0.5, -2)
    track.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / math.max(maxVal - minVal, 1), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((defaultVal - minVal) / math.max(maxVal - minVal, 1), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local valueBox = Instance.new("TextBox")
    valueBox.Size = UDim2.new(0.18, 0, 0.7, 0)
    valueBox.Position = UDim2.new(0.80, 0, 0.15, 0)
    valueBox.BackgroundColor3 = COLORS.BG_INPUT
    valueBox.Text = tostring(defaultVal)
    valueBox.TextColor3 = COLORS.ACCENT
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 12
    valueBox.ClearTextOnFocus = false
    valueBox.Parent = frame
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 5)

    local currentVal = defaultVal
    local dragging = false

    local function updateSlider(val, skipBox)
        currentVal = math.max(val, minVal)
        local clampedForBar = math.clamp(currentVal, minVal, maxVal)
        local percent = (clampedForBar - minVal) / math.max(maxVal - minVal, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -6, 0.5, -6)
        if not skipBox then
            valueBox.Text = tostring(math.round(currentVal * 100) / 100)
        end
        if callback then callback(currentVal) end
    end

    local function updateFromInput(input)
        local relX = input.Position.X - track.AbsolutePosition.X
        local percent = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
        local calculated = math.round((minVal + (maxVal - minVal) * percent) * 100) / 100
        updateSlider(calculated)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    addConn(Services.UserInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end))
    addConn(Services.UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    valueBox.FocusLost:Connect(function()
        local num = tonumber(valueBox.Text)
        if num then
            updateSlider(num)
        else
            valueBox.Text = tostring(math.round(currentVal * 100) / 100)
        end
    end)

    return { frame = frame, update = updateSlider }
end

local function createDropdown(parent, labelText, options, defaultIndex, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 40)
    frame.BackgroundColor3 = COLORS.BG_SECTION
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = COLORS.BORDER
    stroke.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TEXT_LABEL
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.42, 0, 0.7, 0)
    btn.Position = UDim2.new(0.54, 0, 0.15, 0)
    btn.BackgroundColor3 = COLORS.BG_INPUT
    btn.Text = options[defaultIndex or 1]
    btn.TextColor3 = COLORS.ACCENT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local currentIndex = defaultIndex or 1
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        btn.Text = options[currentIndex]
        if callback then callback(options[currentIndex], currentIndex) end
    end)
end

local function createActionButton(parent, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 38)
    btn.BackgroundColor3 = color or COLORS.ACCENT_DIM
    btn.Text = text
    btn.TextColor3 = COLORS.TEXT_PRIMARY
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function createSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(68, 102, 170)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- ==========================================================
-- 9. MAIN GUI CONTAINER
-- ==========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevMasterV2"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetGuiParent
syn.protect_gui(screenGui)

local logoBtn = Instance.new("TextButton")
logoBtn.Size = UDim2.new(0, 46, 0, 46)
logoBtn.Position = UDim2.new(0, 14, 0.42, 0)
logoBtn.BackgroundColor3 = COLORS.BG_TOPBAR
logoBtn.Text = "⚡"
logoBtn.TextColor3 = COLORS.ACCENT
logoBtn.TextSize = 22
logoBtn.Font = Enum.Font.GothamBold
logoBtn.BorderSizePixel = 0
logoBtn.Parent = screenGui
Instance.new("UICorner", logoBtn).CornerRadius = UDim.new(1, 0)
makeDraggable(logoBtn)
local logoStroke = Instance.new("UIStroke", logoBtn)
logoStroke.Color = COLORS.GLOW
logoStroke.Thickness = 1.5

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 660, 0, 480)
mainFrame.Position = UDim2.new(0.5, -330, 0.5, -240)
mainFrame.BackgroundColor3 = COLORS.BG_MAIN
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
makeDraggable(mainFrame)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = COLORS.GLOW
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 46)
topBar.BackgroundColor3 = COLORS.BG_TOPBAR
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local accentDot = Instance.new("Frame")
accentDot.Size = UDim2.new(0, 8, 0, 8)
accentDot.Position = UDim2.new(0, 14, 0.5, -4)
accentDot.BackgroundColor3 = COLORS.ACCENT
accentDot.BorderSizePixel = 0
accentDot.Parent = topBar
Instance.new("UICorner", accentDot).CornerRadius = UDim.new(1, 0)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -120, 1, 0)
titleLbl.Position = UDim2.new(0, 28, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DEV MASTER ULTIMATE V2"
titleLbl.TextColor3 = COLORS.TEXT_PRIMARY
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -72, 0.5, -14)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 42, 58)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = COLORS.TEXT_MUTED
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = topBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 7)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(58, 26, 31)
closeBtn.Text = "×"
closeBtn.TextColor3 = COLORS.RED
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 148, 1, -50)
sidebar.Position = UDim2.new(0, 6, 0, 48)
sidebar.BackgroundColor3 = COLORS.BG_SIDEBAR
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.Padding = UDim.new(0, 4)
local sidebarPad = Instance.new("UIPadding", sidebar)
sidebarPad.PaddingTop = UDim.new(0, 8)
sidebarPad.PaddingLeft = UDim.new(0, 6)
sidebarPad.PaddingRight = UDim.new(0, 6)

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -164, 1, -50)
contentArea.Position = UDim2.new(0, 158, 0, 48)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame

-- ==========================================================
-- 10. TAB SYSTEM
-- ==========================================================
local pages = {}

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = COLORS.TEXT_MUTED
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local btnPad = Instance.new("UIPadding", btn)
    btnPad.PaddingLeft = UDim.new(0, 10)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 2, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = COLORS.ACCENT
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.ACCENT_DIM
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = contentArea

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local pagePad = Instance.new("UIPadding", page)
    pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.PaddingBottom = UDim.new(0, 10)

    pages[name] = { Button = btn, Page = page, Indicator = indicator }

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do
            p.Page.Visible = false
            p.Button.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
            p.Button.TextColor3 = COLORS.TEXT_MUTED
            p.Indicator.Visible = false
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
        btn.TextColor3 = COLORS.ACCENT
        indicator.Visible = true
    end)

    return page
end

local tabStatus   = createTab("Status", "📊")
local tabCombat   = createTab("Combat", "⚔")
local tabMove     = createTab("Movement", "🏃")
local tabWaypoint = createTab("Waypoints", "📍")
local tabVisual   = createTab("Visuals & ESP", "👁")
local tabFps      = createTab("FPS Booster", "🚀")
local tabKeys     = createTab("Keybinds", "⌨")

pages["Status"].Page.Visible = true
pages["Status"].Button.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
pages["Status"].Button.TextColor3 = COLORS.ACCENT
pages["Status"].Indicator.Visible = true

-- ==========================================================
-- 11. STATUS TAB
-- ==========================================================
local statGrid = Instance.new("Frame")
statGrid.Size = UDim2.new(1, -6, 0, 110)
statGrid.BackgroundTransparency = 1
statGrid.LayoutOrder = 1
statGrid.Parent = tabStatus

local statGridLayout = Instance.new("UIGridLayout", statGrid)
statGridLayout.CellSize = UDim2.new(0.48, 0, 0, 48)
statGridLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)

local function createStatCard(title, default, colorVal)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.BG_SECTION
    card.BorderSizePixel = 0
    card.Parent = statGrid
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = COLORS.BORDER
    stroke.Thickness = 0.5

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0.4, 0)
    lbl.Position = UDim2.new(0, 0, 0.06, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(68, 85, 102)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.Parent = card

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, 0, 0.5, 0)
    val.Position = UDim2.new(0, 0, 0.44, 0)
    val.BackgroundTransparency = 1
    val.Text = default
    val.TextColor3 = colorVal or COLORS.GREEN
    val.Font = Enum.Font.GothamBold
    val.TextSize = 17
    val.Parent = card

    return val
end

local fpsLabel     = createStatCard("FPS", "60", COLORS.ACCENT)
local pingLabel    = createStatCard("PING", "0 ms", COLORS.GREEN)
local playersLabel = createStatCard("PLAYERS", "0/" .. tostring(Services.Players.MaxPlayers), COLORS.TEXT_PRIMARY)
local timeLabel    = createStatCard("PLAYTIME", "00:00:00", COLORS.TEXT_MUTED)

local badgeSection = Instance.new("Frame")
badgeSection.Size = UDim2.new(1, -6, 0, 180)
badgeSection.BackgroundColor3 = COLORS.BG_SECTION
badgeSection.BorderSizePixel = 0
badgeSection.LayoutOrder = 2
badgeSection.Parent = tabStatus
Instance.new("UICorner", badgeSection).CornerRadius = UDim.new(0, 10)
local badgeStroke = Instance.new("UIStroke", badgeSection)
badgeStroke.Color = COLORS.BORDER
badgeStroke.Thickness = 0.5

local badgeLayout = Instance.new("UIListLayout", badgeSection)
local badgePad = Instance.new("UIPadding", badgeSection)
badgePad.PaddingLeft = UDim.new(0, 12)
badgePad.PaddingRight = UDim.new(0, 12)
badgePad.PaddingTop = UDim.new(0, 8)

local sectionTitleLbl = Instance.new("TextLabel")
sectionTitleLbl.Size = UDim2.new(1, 0, 0, 22)
sectionTitleLbl.BackgroundTransparency = 1
sectionTitleLbl.Text = "FEATURE STATUS"
sectionTitleLbl.TextColor3 = Color3.fromRGB(68, 102, 170)
sectionTitleLbl.Font = Enum.Font.GothamBold
sectionTitleLbl.TextSize = 10
sectionTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
sectionTitleLbl.Parent = badgeSection

local function createBadgeRow(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.TEXT_LABEL
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 44, 0, 18)
    badge.Position = UDim2.new(1, -44, 0.5, -9)
    badge.BackgroundColor3 = Color3.fromRGB(34, 10, 10)
    badge.Text = "OFF"
    badge.TextColor3 = COLORS.RED
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10
    badge.Parent = row
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

    if key then statusBadges[key] = badge end
    return badge
end

createBadgeRow(badgeSection, "Godmode", "godmodeEnabled")
createBadgeRow(badgeSection, "Aimbot", "aimbotEnabled")
createBadgeRow(badgeSection, "Player ESP", "espEnabled")
createBadgeRow(badgeSection, "Fly", "flyEnabled")
createBadgeRow(badgeSection, "Noclip", "noclipEnabled")

-- ==========================================================
-- 12. COMBAT LOGIC & TAB
-- ==========================================================
local originalHitboxes = {}

local function resetHitboxes()
    for rootPart, data in pairs(originalHitboxes) do
        if rootPart and rootPart.Parent then
            pcall(function()
                rootPart.Size = data.Size
                rootPart.Transparency = data.Transparency
                rootPart.CanCollide = data.CanCollide
                rootPart.Color = data.Color
                rootPart.Material = data.Material
            end)
        end
    end
    table.clear(originalHitboxes)
end

createSectionLabel(tabCombat, "  AIM ASSIST & TARGETING")

local togAimbot = createToggle(tabCombat, "Aimbot (Hold RMB)", "aimbotEnabled")
local togTriggerbot = createToggle(tabCombat, "Triggerbot (Auto Fire)", "triggerbotEnabled")
local togFovCircle = createToggle(tabCombat, "Show FOV Circle", "fovCircleEnabled")
local togWallCheck = createToggle(tabCombat, "Wall Check", "wallCheckEnabled")
local togHitbox = createToggle(tabCombat, "Hitbox Expander", "hitboxEnabled", function(on)
    if not on then resetHitboxes() end
end)

createDropdown(tabCombat, "Target Part", {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm"}, 1, function(val) aimTarget = val end)
createSlider(tabCombat, "FOV Radius", 20, 300, 120, function(v) fovRadius = v end)
createSlider(tabCombat, "Smoothness", 0.01, 1, 0.2, function(v) aimSmoothness = v end)
createSlider(tabCombat, "Hitbox Size", 1, 50, 5, function(v) hitboxSize = v end)

createSectionLabel(tabCombat, "  WEAPON MODIFICATIONS")
local togNoRecoil = createToggle(tabCombat, "No Recoil", "noRecoilEnabled")
local togInfAmmo = createToggle(tabCombat, "Infinite Ammo", "infiniteAmmoEnabled")
local togRapidFire = createToggle(tabCombat, "Rapid Fire", "rapidFireEnabled")

-- ==========================================================
-- 13. MOVEMENT LOGIC & TAB
-- ==========================================================
local Clip = true
local Noclipping = nil
local NoclipParts = {}

local function toggleNoclip(state)
    if state then
        if Noclipping then Noclipping:Disconnect(); Noclipping = nil end
        Clip = false
        table.clear(NoclipParts)
        Noclipping = Services.RunService.Stepped:Connect(function()
            if not Clip and player.Character then
                for _, child in ipairs(player.Character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                        NoclipParts[child] = true
                    end
                end
            end
        end)
    else
        Clip = true
        if Noclipping then Noclipping:Disconnect(); Noclipping = nil end
        if player.Character then
            for _, child in ipairs(player.Character:GetDescendants()) do
                if child:IsA("BasePart") and NoclipParts[child] then
                    child.CanCollide = true
                end
            end
        end
        table.clear(NoclipParts)
    end
end

local flyActive = false
local flyVel, flyGyro, flyConn

local function toggleFly(state)
    if state then
        if flyActive then return end
        flyActive = true
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        flyVel = Instance.new("BodyVelocity")
        flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyVel.Velocity = Vector3.zero
        flyVel.Parent   = root

        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyGyro.CFrame    = root.CFrame
        flyGyro.Parent    = root

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        flyConn = Services.RunService.RenderStepped:Connect(function()
            if not flyActive or not root or not root.Parent then
                toggleFly(false)
                return
            end
            local camCF = camera.CFrame
            local mv = Vector3.zero
            if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then mv += camCF.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then mv -= camCF.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then mv -= camCF.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then mv += camCF.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.Space)     then mv += Vector3.new(0, 1, 0) end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0, 1, 0) end

            if mv.Magnitude > 0 then mv = mv.Unit end
            flyVel.Velocity = mv * flySpeed
            flyGyro.CFrame  = camCF
        end)
    else
        flyActive = false
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                if flyVel  then flyVel:Destroy();  flyVel  = nil end
                if flyGyro then flyGyro:Destroy(); flyGyro = nil end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end
end

createSectionLabel(tabMove, "  MOVEMENT MODS")
local togGodmode = createToggle(tabMove, "Godmode", "godmodeEnabled", function(on)
    if not on then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
end)

local togFly = createToggle(tabMove, "Fly", "flyEnabled", function(on)
    toggleFly(on)
end)

local togNoclip = createToggle(tabMove, "Noclip", "noclipEnabled", function(on)
    toggleNoclip(on)
end)

local togClickTp = createToggle(tabMove, "Click TP (Ctrl+Click)", "clickTpEnabled")
local togInfJump = createToggle(tabMove, "Infinite Jump", "infJumpEnabled")
local togAutoJump = createToggle(tabMove, "Auto Jump", "autoJumpEnabled")
local togAutoSprint = createToggle(tabMove, "Auto Sprint", "autoSprintEnabled")

createSectionLabel(tabMove, "  SPEED & PHYSICS (1 - 1000)")

-- Cả thanh trượt lẫn ô nhập số đều hỗ trợ từ 1 đến 1000+
local togWalkSpeed = createToggle(tabMove, "Speed Hack (WalkSpeed)", "walkSpeedEnabled", function(on)
    if not on then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
createSlider(tabMove, "Walk Speed", 16, 1000, 50, function(v) customWalkSpeed = v end)

local togJumpPower = createToggle(tabMove, "JumpPower Hack", "jumpPowerEnabled", function(on)
    if not on then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
    end
end)
createSlider(tabMove, "Jump Power", 50, 1000, 100, function(v) customJumpPower = v end)
createSlider(tabMove, "Fly Speed", 10, 1000, 50, function(v) flySpeed = v end)
createSlider(tabMove, "Freecam Speed", 0.1, 10, 1, function(v) freecamSpeedMultiplier = v end)

-- ==========================================================
-- 14. VISUAL & TELEPORT TAB
-- ==========================================================
local freecamState = { enabled = false, cframe = CFrame.new(), yaw = 0, pitch = 0, connection = nil }

local function toggleFreecam()
    freecamState.enabled = not freecamState.enabled
    featureStates.freecamEnabled = freecamState.enabled
    updateStatusBadge("freecamEnabled", freecamState.enabled)

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if freecamState.enabled then
        camera.CameraType = Enum.CameraType.Scriptable
        freecamState.cframe = camera.CFrame
        local rx, ry, _ = freecamState.cframe:ToOrientation()
        freecamState.yaw   = ry
        freecamState.pitch = rx
        if hrp then hrp.Anchored = true end
        if freecamState.connection then freecamState.connection:Disconnect() end
        freecamState.connection = Services.RunService.RenderStepped:Connect(function(dt)
            if _G.stopScript then toggleFreecam() return end
            if Services.UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local delta = Services.UserInput:GetMouseDelta()
                freecamState.yaw   = freecamState.yaw - delta.X * 0.004
                freecamState.pitch = math.clamp(freecamState.pitch - delta.Y * 0.004, -math.rad(89), math.rad(89))
            end
            local rotCF = CFrame.Angles(0, freecamState.yaw, 0) * CFrame.Angles(freecamState.pitch, 0, 0)
            local moveVec = Vector3.zero
            if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then moveVec += rotCF.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then moveVec -= rotCF.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then moveVec -= rotCF.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then moveVec += rotCF.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.E) then moveVec += Vector3.new(0, 1, 0) end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.Q) then moveVec -= Vector3.new(0, 1, 0) end
            if moveVec.Magnitude > 0 then moveVec = moveVec.Unit end
            freecamState.cframe = CFrame.new(freecamState.cframe.Position + moveVec * 50 * freecamSpeedMultiplier * dt) * rotCF
            camera.CFrame = freecamState.cframe
        end)
    else
        if freecamState.connection then freecamState.connection:Disconnect(); freecamState.connection = nil end
        if hrp then hrp.Anchored = false end
        camera.CameraType = Enum.CameraType.Custom
        if hum then camera.CameraSubject = hum end
    end
end

local function setInvisibility(state)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 1 or 0
            part.CanCollide = not state
        end
        if (part:IsA("Accessory") or part:IsA("Hat")) and part:FindFirstChild("Handle") then
            part.Handle.Transparency = state and 1 or 0
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.HealthDisplayDistance = state and 0 or 100 end
end

createSectionLabel(tabVisual, "  VISUALS & MISC")
local togEsp = createToggle(tabVisual, "Player ESP", "espEnabled")
local togFullbright = createToggle(tabVisual, "Fullbright", "fullbrightEnabled", function(on)
    if not on then
        Services.Lighting.Brightness = originalLighting.Brightness
        Services.Lighting.ClockTime  = originalLighting.ClockTime
    end
end)
local togAntiAfk = createToggle(tabVisual, "Anti-AFK", "antiAfkEnabled")
local togFreecam = createToggle(tabVisual, "Freecam", "freecamEnabled", function()
    toggleFreecam()
end)
local togInvis = createToggle(tabVisual, "Invisibility", "invisibilityEnabled", function(on)
    setInvisibility(on)
end)

createSectionLabel(tabVisual, "  PLAYER TELEPORT")
local tpFrame = Instance.new("Frame")
tpFrame.Size = UDim2.new(1, -6, 0, 40)
tpFrame.BackgroundColor3 = COLORS.BG_SECTION
tpFrame.BorderSizePixel = 0
tpFrame.Parent = tabVisual
Instance.new("UICorner", tpFrame).CornerRadius = UDim.new(0, 8)
local tpStroke = Instance.new("UIStroke", tpFrame)
tpStroke.Color = COLORS.BORDER
tpStroke.Thickness = 0.5

local tpBox = Instance.new("TextBox")
tpBox.Size = UDim2.new(0.5, 0, 0.7, 0)
tpBox.Position = UDim2.new(0.02, 0, 0.15, 0)
tpBox.BackgroundColor3 = COLORS.BG_INPUT
tpBox.PlaceholderText = "Player name..."
tpBox.Text = ""
tpBox.TextColor3 = COLORS.TEXT_PRIMARY
tpBox.Font = Enum.Font.GothamMedium
tpBox.TextSize = 12
tpBox.Parent = tpFrame
Instance.new("UICorner", tpBox).CornerRadius = UDim.new(0, 5)

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
tpBtn.Position = UDim2.new(0.54, 0, 0.15, 0)
tpBtn.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
tpBtn.Text = "TP"
tpBtn.TextColor3 = COLORS.ACCENT
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 12
tpBtn.BorderSizePixel = 0
tpBtn.Parent = tpFrame
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)

local spectateBtn = Instance.new("TextButton")
spectateBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
spectateBtn.Position = UDim2.new(0.78, 0, 0.15, 0)
spectateBtn.BackgroundColor3 = Color3.fromRGB(26, 10, 32)
spectateBtn.Text = "Watch"
spectateBtn.TextColor3 = COLORS.PURPLE
spectateBtn.Font = Enum.Font.GothamBold
spectateBtn.TextSize = 12
spectateBtn.BorderSizePixel = 0
spectateBtn.Parent = tpFrame
Instance.new("UICorner", spectateBtn).CornerRadius = UDim.new(0, 5)

local isSpectating = false
local spectateConn = nil

local function stopSpectate()
    isSpectating = false
    if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
    spectateBtn.Text = "Watch"
    spectateBtn.TextColor3 = COLORS.PURPLE
    local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if myHum then camera.CameraSubject = myHum end
end

tpBtn.MouseButton1Click:Connect(function()
    local search = string.lower(tpBox.Text)
    if search == "" then return end
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and (string.lower(p.Name):find(search) or string.lower(p.DisplayName):find(search)) then
            local targetHrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp and myHrp then
                myHrp.CFrame = targetHrp.CFrame + Vector3.new(2, 0, 0)
                myHrp.AssemblyLinearVelocity = Vector3.zero
                tpBtn.Text = "OK!"
                task.wait(1)
                tpBtn.Text = "TP"
            end
            return
        end
    end
    tpBtn.Text = "???"
    task.wait(1)
    tpBtn.Text = "TP"
end)

spectateBtn.MouseButton1Click:Connect(function()
    if isSpectating then stopSpectate() return end
    local search = string.lower(tpBox.Text)
    if search == "" then return end
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= player and (string.lower(p.Name):find(search) or string.lower(p.DisplayName):find(search)) then
            local targetHum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if targetHum then
                camera.CameraSubject = targetHum
                isSpectating = true
                spectateBtn.Text = "Stop"
                spectateBtn.TextColor3 = COLORS.GREEN
                spectateConn = targetHum.Died:Connect(stopSpectate)
                break
            end
        end
    end
end)

createSectionLabel(tabVisual, "  SERVER UTILITIES")
local serverFrame = Instance.new("Frame")
serverFrame.Size = UDim2.new(1, -6, 0, 40)
serverFrame.BackgroundColor3 = COLORS.BG_SECTION
serverFrame.BorderSizePixel = 0
serverFrame.Parent = tabVisual
Instance.new("UICorner", serverFrame).CornerRadius = UDim.new(0, 8)
local sfStroke = Instance.new("UIStroke", serverFrame)
sfStroke.Color = COLORS.BORDER
sfStroke.Thickness = 0.5

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(0.48, 0, 0.7, 0)
rejoinBtn.Position = UDim2.new(0.01, 0, 0.15, 0)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
rejoinBtn.Text = "↻ Rejoin"
rejoinBtn.TextColor3 = COLORS.PURPLE
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 12
rejoinBtn.BorderSizePixel = 0
rejoinBtn.Parent = serverFrame
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 5)

local serverHopBtn = Instance.new("TextButton")
serverHopBtn.Size = UDim2.new(0.48, 0, 0.7, 0)
serverHopBtn.Position = UDim2.new(0.51, 0, 0.15, 0)
serverHopBtn.BackgroundColor3 = Color3.fromRGB(26, 17, 0)
serverHopBtn.Text = "Server Hop"
serverHopBtn.TextColor3 = COLORS.YELLOW
serverHopBtn.Font = Enum.Font.GothamBold
serverHopBtn.TextSize = 12
serverHopBtn.BorderSizePixel = 0
serverHopBtn.Parent = serverFrame
Instance.new("UICorner", serverHopBtn).CornerRadius = UDim.new(0, 5)

rejoinBtn.MouseButton1Click:Connect(function()
    Services.Teleport:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

serverHopBtn.MouseButton1Click:Connect(function()
    if not hasHttpRequest() then
        serverHopBtn.Text = "Unsupported"
        task.wait(1.5)
        serverHopBtn.Text = "Server Hop"
        return
    end
    serverHopBtn.Text = "Searching..."
    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, result = pcall(function()
            return Services.Http:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    Services.Teleport:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
        serverHopBtn.Text = "Retry"
        task.wait(2)
        serverHopBtn.Text = "Server Hop"
    end)
end)

-- ==========================================================
-- 15. ESP SUBSYSTEM
-- ==========================================================
local espCache = {}

local function cleanupPlayerESP(p)
    if espCache[p] then
        if espCache[p].hl then pcall(function() espCache[p].hl:Destroy() end) end
        if espCache[p].bb then pcall(function() espCache[p].bb:Destroy() end) end
        espCache[p] = nil
    end
end

local function updateESP()
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p == player then continue end
        local char = p.Character
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not head or not hum or hum.Health <= 0 then
            cleanupPlayerESP(p)
            continue
        end

        if not espCache[p] then espCache[p] = {} end
        local data = espCache[p]

        if featureStates.espEnabled then
            if not data.hl or data.hl.Parent ~= char then
                if data.hl then data.hl:Destroy() end
                data.hl = Instance.new("Highlight")
                data.hl.Adornee = char
                data.hl.FillColor = Color3.fromRGB(0, 200, 255)
                data.hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                data.hl.Parent = char
            end
            data.hl.Enabled = true

            if not data.bb or data.bb.Parent ~= char then
                if data.bb then data.bb:Destroy() end
                data.bb = Instance.new("BillboardGui")
                data.bb.Size = UDim2.new(0, 200, 0, 60)
                data.bb.StudsOffset = Vector3.new(0, 2.8, 0)
                data.bb.AlwaysOnTop = true
                data.bb.Adornee = head

                local nameLabel = Instance.new("TextLabel", data.bb)
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = COLORS.GREEN
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 13

                local healthBg = Instance.new("Frame", data.bb)
                healthBg.Name = "HealthBg"
                healthBg.Size = UDim2.new(0.85, 0, 0.25, 0)
                healthBg.Position = UDim2.new(0.075, 0, 0.6, 0)
                healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                healthBg.BorderSizePixel = 0
                Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 3)

                local healthBar = Instance.new("Frame", healthBg)
                healthBar.Name = "HealthBar"
                healthBar.Size = UDim2.new(1, 0, 1, 0)
                healthBar.BackgroundColor3 = COLORS.GREEN
                healthBar.BorderSizePixel = 0
                Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 3)

                data.bb.Parent = char
            end

            local nl = data.bb:FindFirstChild("NameLabel")
            local hbg = data.bb:FindFirstChild("HealthBg")
            local hbar = hbg and hbg:FindFirstChild("HealthBar")
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local tHrp = char:FindFirstChild("HumanoidRootPart")

            if nl then
                local dist = (myHrp and tHrp) and math.floor((myHrp.Position - tHrp.Position).Magnitude) or 0
                nl.Text = p.DisplayName .. " [" .. dist .. "m]"
            end
            if hbar then
                local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                hbar.Size = UDim2.new(hp, 0, 1, 0)
                hbar.BackgroundColor3 = hp > 0.5 and COLORS.GREEN or hp > 0.25 and COLORS.YELLOW or COLORS.RED
            end
        else
            if data.hl then data.hl.Enabled = false end
            if data.bb then data.bb:Destroy(); data.bb = nil end
        end
    end
end

addConn(Services.Players.PlayerRemoving:Connect(cleanupPlayerESP))

-- ==========================================================
-- 16. WAYPOINT TAB
-- ==========================================================
local fileName = "DevWaypoints_" .. tostring(game.PlaceId) .. ".json"
local waypointsList = {}
local autoTpThread = nil

createSectionLabel(tabWaypoint, "  SAVE CURRENT POSITION")

local wpInputFrame = Instance.new("Frame")
wpInputFrame.Size = UDim2.new(1, -6, 0, 40)
wpInputFrame.BackgroundColor3 = COLORS.BG_SECTION
wpInputFrame.BorderSizePixel = 0
wpInputFrame.Parent = tabWaypoint
Instance.new("UICorner", wpInputFrame).CornerRadius = UDim.new(0, 8)
local wpIfStroke = Instance.new("UIStroke", wpInputFrame)
wpIfStroke.Color = COLORS.BORDER
wpIfStroke.Thickness = 0.5

local wpNameBox = Instance.new("TextBox")
wpNameBox.Size = UDim2.new(0.6, 0, 0.7, 0)
wpNameBox.Position = UDim2.new(0.02, 0, 0.15, 0)
wpNameBox.BackgroundColor3 = COLORS.BG_INPUT
wpNameBox.PlaceholderText = "Point name..."
wpNameBox.Text = ""
wpNameBox.TextColor3 = COLORS.TEXT_PRIMARY
wpNameBox.Font = Enum.Font.GothamMedium
wpNameBox.TextSize = 12
wpNameBox.Parent = wpInputFrame
Instance.new("UICorner", wpNameBox).CornerRadius = UDim.new(0, 5)

local wpSaveBtn = Instance.new("TextButton")
wpSaveBtn.Size = UDim2.new(0.34, 0, 0.7, 0)
wpSaveBtn.Position = UDim2.new(0.64, 0, 0.15, 0)
wpSaveBtn.BackgroundColor3 = Color3.fromRGB(0, 51, 34)
wpSaveBtn.Text = "+ Save"
wpSaveBtn.TextColor3 = COLORS.GREEN
wpSaveBtn.Font = Enum.Font.GothamBold
wpSaveBtn.TextSize = 12
wpSaveBtn.BorderSizePixel = 0
wpSaveBtn.Parent = wpInputFrame
Instance.new("UICorner", wpSaveBtn).CornerRadius = UDim.new(0, 5)

local fileFrame = Instance.new("Frame")
fileFrame.Size = UDim2.new(1, -6, 0, 40)
fileFrame.BackgroundColor3 = COLORS.BG_SECTION
fileFrame.BorderSizePixel = 0
fileFrame.Parent = tabWaypoint
Instance.new("UICorner", fileFrame).CornerRadius = UDim.new(0, 8)
local ffStroke = Instance.new("UIStroke", fileFrame)
ffStroke.Color = COLORS.BORDER
ffStroke.Thickness = 0.5

local saveFileBtn = Instance.new("TextButton")
saveFileBtn.Size = UDim2.new(0.48, 0, 0.7, 0)
saveFileBtn.Position = UDim2.new(0.01, 0, 0.15, 0)
saveFileBtn.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
saveFileBtn.Text = "💾 Save File"
saveFileBtn.TextColor3 = COLORS.ACCENT
saveFileBtn.Font = Enum.Font.GothamBold
saveFileBtn.TextSize = 12
saveFileBtn.BorderSizePixel = 0
saveFileBtn.Parent = fileFrame
Instance.new("UICorner", saveFileBtn).CornerRadius = UDim.new(0, 5)

local loadFileBtn = Instance.new("TextButton")
loadFileBtn.Size = UDim2.new(0.48, 0, 0.7, 0)
loadFileBtn.Position = UDim2.new(0.51, 0, 0.15, 0)
loadFileBtn.BackgroundColor3 = Color3.fromRGB(26, 17, 0)
loadFileBtn.Text = "📂 Load File"
loadFileBtn.TextColor3 = COLORS.YELLOW
loadFileBtn.Font = Enum.Font.GothamBold
loadFileBtn.TextSize = 12
loadFileBtn.BorderSizePixel = 0
loadFileBtn.Parent = fileFrame
Instance.new("UICorner", loadFileBtn).CornerRadius = UDim.new(0, 5)

local togAutoTp = createToggle(tabWaypoint, "Auto TP Loop", "autoTpEnabled")
createSlider(tabWaypoint, "Interval (s)", 1, 30, 3, function(v) autoTpInterval = v end)

createSectionLabel(tabWaypoint, "  WAYPOINT LIST")

local wpListContainer = Instance.new("Frame")
wpListContainer.Size = UDim2.new(1, -6, 0, 10)
wpListContainer.AutomaticSize = Enum.AutomaticSize.Y
wpListContainer.BackgroundTransparency = 1
wpListContainer.Parent = tabWaypoint

local wpListLayout = Instance.new("UIListLayout", wpListContainer)
wpListLayout.Padding = UDim.new(0, 4)

local function addWaypointUI(name, cframe)
    local itemData = { Name = name, CFrame = cframe }
    table.insert(waypointsList, itemData)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = COLORS.BG_SECTION
    frame.BorderSizePixel = 0
    frame.Parent = wpListContainer
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = COLORS.BORDER
    fStroke.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = COLORS.TEXT_PRIMARY
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local tpWpBtn = Instance.new("TextButton")
    tpWpBtn.Size = UDim2.new(0, 52, 0.65, 0)
    tpWpBtn.Position = UDim2.new(0.52, 0, 0.175, 0)
    tpWpBtn.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
    tpWpBtn.Text = "Goto"
    tpWpBtn.TextColor3 = COLORS.ACCENT
    tpWpBtn.Font = Enum.Font.GothamBold
    tpWpBtn.TextSize = 11
    tpWpBtn.BorderSizePixel = 0
    tpWpBtn.Parent = frame
    Instance.new("UICorner", tpWpBtn).CornerRadius = UDim.new(0, 5)

    local delWpBtn = Instance.new("TextButton")
    delWpBtn.Size = UDim2.new(0, 52, 0.65, 0)
    delWpBtn.Position = UDim2.new(0.76, 0, 0.175, 0)
    delWpBtn.BackgroundColor3 = Color3.fromRGB(34, 10, 10)
    delWpBtn.Text = "Delete"
    delWpBtn.TextColor3 = COLORS.RED
    delWpBtn.Font = Enum.Font.GothamBold
    delWpBtn.TextSize = 11
    delWpBtn.BorderSizePixel = 0
    delWpBtn.Parent = frame
    Instance.new("UICorner", delWpBtn).CornerRadius = UDim.new(0, 5)

    tpWpBtn.MouseButton1Click:Connect(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = cframe
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    delWpBtn.MouseButton1Click:Connect(function()
        for i, v in ipairs(waypointsList) do
            if v == itemData then
                table.remove(waypointsList, i)
                break
            end
        end
        frame:Destroy()
    end)
end

wpSaveBtn.MouseButton1Click:Connect(function()
    local name = wpNameBox.Text
    if name == "" then name = "Point " .. tostring(#waypointsList + 1) end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        addWaypointUI(name, hrp.CFrame)
        wpNameBox.Text = ""
    end
end)

saveFileBtn.MouseButton1Click:Connect(function()
    if not hasWriteFile() then
        saveFileBtn.Text = "Unsupported"
        task.wait(1.5)
        saveFileBtn.Text = "💾 Save File"
        return
    end
    local exportData = {}
    for _, wp in ipairs(waypointsList) do
        table.insert(exportData, { Name = wp.Name, Pos = { wp.CFrame.X, wp.CFrame.Y, wp.CFrame.Z } })
    end
    local ok = saveFile(fileName, Services.Http:JSONEncode(exportData))
    saveFileBtn.Text = ok and "✓ Saved!" or "Error!"
    task.wait(1.5)
    saveFileBtn.Text = "💾 Save File"
end)

loadFileBtn.MouseButton1Click:Connect(function()
    if not hasReadFile() then
        loadFileBtn.Text = "Unsupported"
        task.wait(1.5)
        loadFileBtn.Text = "📂 Load File"
        return
    end
    local data = loadFile(fileName)
    if data then
        local success, decoded = pcall(function() return Services.Http:JSONDecode(data) end)
        if success and decoded then
            for _, item in ipairs(wpListContainer:GetChildren()) do
                if item:IsA("Frame") then item:Destroy() end
            end
            table.clear(waypointsList)
            for _, wpData in ipairs(decoded) do
                addWaypointUI(wpData.Name, CFrame.new(wpData.Pos[1], wpData.Pos[2], wpData.Pos[3]))
            end
            loadFileBtn.Text = "✓ Loaded!"
        else
            loadFileBtn.Text = "Data Error"
        end
    else
        loadFileBtn.Text = "Not Found"
    end
    task.wait(1.5)
    loadFileBtn.Text = "📂 Load File"
end)

togAutoTp.btn.MouseButton1Click:Connect(function()
    local state = togAutoTp.getState()
    if state then
        autoTpThread = task.spawn(function()
            local idx = 1
            while featureStates.autoTpEnabled and not _G.stopScript do
                if #waypointsList > 0 then
                    if idx > #waypointsList then idx = 1 end
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and waypointsList[idx] then
                        hrp.CFrame = waypointsList[idx].CFrame
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end
                    idx += 1
                end
                task.wait(autoTpInterval)
            end
        end)
    else
        if autoTpThread then task.cancel(autoTpThread); autoTpThread = nil end
    end
end)

-- ==========================================================
-- 17. AGGRESSIVE CLIENT-SIDE GRAPHICS REDUCTION SUBSYSTEM
-- ==========================================================
local savedLighting = {}
local savedEffects  = {}
local savedParts    = {}
local savedDecals   = {}
local fixLagConnections = {}

-- Protection filter: exclude NPCs, player characters, tools, accessories, hitboxes, and UI
local function isProtectedInstance(inst)
    if not inst or not inst.Parent then return true end
    if inst:IsA("Terrain") then return true end
    if inst:FindFirstAncestorOfClass("Tool") or inst:FindFirstAncestorOfClass("Accessory") then return true end

    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return true end

    if inst:FindFirstAncestorOfClass("LayerCollector") or inst:IsA("GuiBase2d") then return true end
    local nameLower = inst.Name:lower()
    if nameLower:find("hitbox") or nameLower:find("root") or nameLower:find("handle") then return true end

    return false
end

local function applyOptimizationToInstance(inst)
    if not inst or not inst.Parent then return end

    -- Particle & Trail & Beam & Smoke & Fire & Sparkles
    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or
       inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
        if not isProtectedInstance(inst) then
            if savedEffects[inst] == nil then
                savedEffects[inst] = { Prop = "Enabled", Value = inst.Enabled }
            end
            inst.Enabled = false
        end

    -- PointLight, SpotLight, SurfaceLight
    elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        if not isProtectedInstance(inst) then
            if savedEffects[inst] == nil then
                savedEffects[inst] = { Prop = "Enabled", Value = inst.Enabled }
            end
            inst.Enabled = false
        end

    -- Lighting Post-processing Effects
    elseif inst:IsA("BloomEffect") or inst:IsA("BlurEffect") or inst:IsA("SunRaysEffect") or
           inst:IsA("ColorCorrectionEffect") or inst:IsA("DepthOfFieldEffect") then
        if savedEffects[inst] == nil then
            savedEffects[inst] = { Prop = "Enabled", Value = inst.Enabled }
        end
        inst.Enabled = false

    -- Atmosphere
    elseif inst:IsA("Atmosphere") then
        if savedEffects[inst] == nil then
            savedEffects[inst] = { Prop = "Density", Value = inst.Density }
        end
        inst.Density = 0

    -- Textures & Decals (Simplify without deleting)
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        if not isProtectedInstance(inst) then
            if savedDecals[inst] == nil then
                savedDecals[inst] = inst.Transparency
            end
            inst.Transparency = 1
        end

    -- BaseParts: Simplify material and disable shadows where supported
    elseif inst:IsA("BasePart") and not inst:IsA("MeshPart") then
        if not isProtectedInstance(inst) then
            if not savedParts[inst] then
                savedParts[inst] = {
                    Material   = inst.Material,
                    CastShadow = inst.CastShadow,
                }
            end
            inst.Material   = Enum.Material.SmoothPlastic
            inst.CastShadow = false
        end
    end
end

local function enableAggressiveFixLag()
    -- 1. Lighting Optimization & Shadows
    savedLighting = {
        GlobalShadows = Services.Lighting.GlobalShadows,
        FogEnd        = Services.Lighting.FogEnd,
        Brightness    = Services.Lighting.Brightness,
        ClockTime     = Services.Lighting.ClockTime,
        QualityLevel  = settings().Rendering.QualityLevel,
    }

    Services.Lighting.GlobalShadows = false
    Services.Lighting.FogEnd = 9e9
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    -- 2. Process all current instances in Workspace & Lighting
    for _, inst in ipairs(Services.Lighting:GetDescendants()) do
        applyOptimizationToInstance(inst)
    end
    for _, inst in ipairs(Services.Workspace:GetDescendants()) do
        applyOptimizationToInstance(inst)
    end

    -- 3. Dynamic Listener for runtime-spawned effects & instances
    table.insert(fixLagConnections, Services.Workspace.DescendantAdded:Connect(function(inst)
        if featureStates.aggressiveFpsEnabled then
            applyOptimizationToInstance(inst)
        end
    end))

    table.insert(fixLagConnections, Services.Lighting.DescendantAdded:Connect(function(inst)
        if featureStates.aggressiveFpsEnabled then
            applyOptimizationToInstance(inst)
        end
    end))
end

local function restoreAggressiveFixLag()
    -- Disconnect runtime hooks
    for _, conn in ipairs(fixLagConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(fixLagConnections)

    -- Restore Lighting & Post-Processing
    if savedLighting.GlobalShadows ~= nil then
        Services.Lighting.GlobalShadows = savedLighting.GlobalShadows
        Services.Lighting.FogEnd        = savedLighting.FogEnd
        Services.Lighting.Brightness    = savedLighting.Brightness
        Services.Lighting.ClockTime     = savedLighting.ClockTime
        pcall(function()
            settings().Rendering.QualityLevel = savedLighting.QualityLevel
        end)
    end

    -- Restore Effects & Lights
    for inst, data in pairs(savedEffects) do
        if inst and inst.Parent then
            pcall(function()
                inst[data.Prop] = data.Value
            end)
        end
    end
    table.clear(savedEffects)

    -- Restore Parts (Material & CastShadow)
    for inst, data in pairs(savedParts) do
        if inst and inst.Parent then
            pcall(function()
                inst.Material   = data.Material
                inst.CastShadow = data.CastShadow
            end)
        end
    end
    table.clear(savedParts)

    -- Restore Decals & Textures
    for inst, origTrans in pairs(savedDecals) do
        if inst and inst.Parent then
            pcall(function()
                inst.Transparency = origTrans
            end)
        end
    end
    table.clear(savedDecals)
end

-- ==========================================================
-- 18. FPS BOOSTER TAB
-- ==========================================================
createSectionLabel(tabFps, "  AGGRESSIVE CLIENT-SIDE OPTIMIZATION")

local togAggressiveFps = createToggle(tabFps, "Aggressive Fix Lag (Potato Mode)", "aggressiveFpsEnabled", function(on)
    if on then
        enableAggressiveFixLag()
    else
        restoreAggressiveFixLag()
    end
end)

local boostBtn = createActionButton(tabFps, "🚀 One-Click Fast Boost", Color3.fromRGB(0, 51, 34))
boostBtn.TextColor3 = COLORS.GREEN

local resetBtn = createActionButton(tabFps, "🔄 Restore All Graphics & Effects", Color3.fromRGB(51, 10, 10))
resetBtn.TextColor3 = COLORS.RED

boostBtn.MouseButton1Click:Connect(function()
    togAggressiveFps.setState(true)
    boostBtn.Text = "✓ Boosted!"
    task.wait(1.5)
    boostBtn.Text = "🚀 One-Click Fast Boost"
end)

resetBtn.MouseButton1Click:Connect(function()
    togAggressiveFps.setState(false)
    resetBtn.Text = "✓ Restored!"
    task.wait(1.5)
    resetBtn.Text = "🔄 Restore All Graphics & Effects"
end)

-- ==========================================================
-- 19. KEYBINDS TAB
-- ==========================================================
local keybinds = {
    Freecam = Enum.KeyCode.P,
    Fly     = Enum.KeyCode.F,
    Noclip  = Enum.KeyCode.N,
    ClickTP = Enum.KeyCode.T,
    InfJump = Enum.KeyCode.J,
    ESP     = Enum.KeyCode.E,
    Aimbot  = Enum.KeyCode.R,
}

createSectionLabel(tabKeys, "  KEYBINDS - Click to rebind")

local function createKeybindRow(parent, labelText, actionKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 38)
    frame.BackgroundColor3 = COLORS.BG_SECTION
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local fStr = Instance.new("UIStroke", frame)
    fStr.Color = COLORS.BORDER
    fStr.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TEXT_LABEL
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.28, 0, 0.65, 0)
    btn.Position = UDim2.new(0.68, 0, 0.175, 0)
    btn.BackgroundColor3 = COLORS.BG_INPUT
    btn.Text = keybinds[actionKey].Name
    btn.TextColor3 = COLORS.ACCENT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local binding = false
    btn.MouseButton1Click:Connect(function()
        binding = true
        btn.Text = "..."
        btn.TextColor3 = COLORS.YELLOW
    end)
    addConn(Services.UserInput.InputBegan:Connect(function(input, gpe)
        if binding and input.UserInputType == Enum.UserInputType.Keyboard then
            keybinds[actionKey] = input.KeyCode
            btn.Text = input.KeyCode.Name
            btn.TextColor3 = COLORS.ACCENT
            binding = false
        end
    end))
end

createKeybindRow(tabKeys, "Freecam", "Freecam")
createKeybindRow(tabKeys, "Fly", "Fly")
createKeybindRow(tabKeys, "Noclip", "Noclip")
createKeybindRow(tabKeys, "Click TP", "ClickTP")
createKeybindRow(tabKeys, "Infinite Jump", "InfJump")
createKeybindRow(tabKeys, "Player ESP", "ESP")
createKeybindRow(tabKeys, "Aimbot", "Aimbot")

local kbMenuRow = Instance.new("Frame")
kbMenuRow.Size = UDim2.new(1, -6, 0, 38)
kbMenuRow.BackgroundColor3 = COLORS.BG_SECTION
kbMenuRow.BorderSizePixel = 0
kbMenuRow.Parent = tabKeys
Instance.new("UICorner", kbMenuRow).CornerRadius = UDim.new(0, 8)
local kbStr = Instance.new("UIStroke", kbMenuRow)
kbStr.Color = COLORS.BORDER
kbStr.Thickness = 0.5

local kbLbl = Instance.new("TextLabel")
kbLbl.Size = UDim2.new(0.6, 0, 1, 0)
kbLbl.Position = UDim2.new(0, 12, 0, 0)
kbLbl.BackgroundTransparency = 1
kbLbl.Text = "Toggle Menu"
kbLbl.TextColor3 = COLORS.TEXT_LABEL
kbLbl.Font = Enum.Font.GothamMedium
kbLbl.TextSize = 12
kbLbl.TextXAlignment = Enum.TextXAlignment.Left
kbLbl.Parent = kbMenuRow

local kbVal = Instance.new("TextLabel")
kbVal.Size = UDim2.new(0.28, 0, 0.65, 0)
kbVal.Position = UDim2.new(0.68, 0, 0.175, 0)
kbVal.BackgroundColor3 = COLORS.BG_INPUT
kbVal.Text = "K"
kbVal.TextColor3 = COLORS.ACCENT
kbVal.Font = Enum.Font.GothamBold
kbVal.TextSize = 11
kbVal.BackgroundTransparency = 0
kbVal.Parent = kbMenuRow
Instance.new("UICorner", kbVal).CornerRadius = UDim.new(0, 5)

-- ==========================================================
-- 20. RUNTIME PIPELINES (COMBAT / MOVEMENT / RENDER)
-- ==========================================================
local fovCircle
if Drawing ~= nil then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.Color = COLORS.ACCENT
        fovCircle.Filled = false
        fovCircle.Transparency = 1
        fovCircle.Visible = false
    end)
end

local function isPartVisible(part)
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { player.Character, part.Parent }
    params.FilterType = Enum.RaycastFilterType.Exclude
    return Services.Workspace:Raycast(origin, direction, params) == nil
end

local function getClosestPlayer()
    local closestPart, shortestDist = nil, fovRadius
    local mouseLoc = Services.UserInput:GetMouseLocation()

    for _, tp in ipairs(Services.Players:GetPlayers()) do
        if tp ~= player and tp.Character then
            local hum  = tp.Character:FindFirstChildOfClass("Humanoid")
            local part = tp.Character:FindFirstChild(aimTarget) or tp.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and part then
                local sp, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - mouseLoc).Magnitude
                    if dist < shortestDist then
                        if not featureStates.wallCheckEnabled or isPartVisible(part) then
                            shortestDist = dist
                            closestPart  = part
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

local lastSafeCFrame = nil

-- RenderStepped
addConn(Services.RunService.RenderStepped:Connect(function()
    if _G.stopScript then return end
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    if featureStates.fullbrightEnabled then
        Services.Lighting.Brightness = 2
        Services.Lighting.ClockTime  = 14
    end

    if featureStates.hitboxEnabled then
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= player and p.Character then
                local ph = p.Character:FindFirstChildOfClass("Humanoid")
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if ph and ph.Health > 0 and pr and pr:IsA("BasePart") then
                    if not originalHitboxes[pr] then
                        originalHitboxes[pr] = {
                            Size         = pr.Size,
                            Transparency = pr.Transparency,
                            CanCollide   = pr.CanCollide,
                            Color        = pr.Color,
                            Material     = pr.Material,
                        }
                    end
                    pr.Size         = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    pr.Transparency = 0.7
                    pr.Color        = Color3.fromRGB(255, 0, 0)
                    pr.Material     = Enum.Material.SmoothPlastic
                    pr.CanCollide   = false
                end
            end
        end
    end

    if fovCircle then
        fovCircle.Visible  = featureStates.fovCircleEnabled
        fovCircle.Position = Services.UserInput:GetMouseLocation()
        fovCircle.Radius   = fovRadius
    end

    if featureStates.aimbotEnabled and Services.UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPart = getClosestPlayer()
        if targetPart then
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPart.Position), aimSmoothness)
        end
    end

    if featureStates.triggerbotEnabled and (tick() - lastTriggerTime >= 0.1) then
        local targetPart = getClosestPlayer()
        if targetPart then
            lastTriggerTime = tick()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton1(Vector2.new())
        end
    end
end))

-- Stepped
addConn(Services.RunService.Stepped:Connect(function()
    if _G.stopScript then return end
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hum then return end

    if featureStates.godmodeEnabled then
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if hrp and hrp.Position.Y > Services.Workspace.FallenPartsDestroyHeight + 20 then
            if hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                lastSafeCFrame = hrp.CFrame
            end
        end
        if hrp and lastSafeCFrame and hrp.Position.Y <= Services.Workspace.FallenPartsDestroyHeight + 10 then
            hrp.CFrame = lastSafeCFrame + Vector3.new(0, 5, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if featureStates.walkSpeedEnabled or featureStates.autoSprintEnabled then
        hum.WalkSpeed = customWalkSpeed
    end
    if featureStates.jumpPowerEnabled then
        hum.UseJumpPower = true
        hum.JumpPower    = customJumpPower
    end

    if featureStates.autoJumpEnabled and hum:GetState() == Enum.HumanoidStateType.Running then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        if featureStates.noRecoilEnabled then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") and (v.Name:lower():find("recoil") or v.Name:lower():find("spread")) then
                    v.Value = 0
                end
            end
        end
        if featureStates.infiniteAmmoEnabled then
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo") or tool:FindFirstChild("AmmoCount")
            if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
        end
        if featureStates.rapidFireEnabled and Services.UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if tick() - lastRapidFireTime >= 0.05 then
                lastRapidFireTime = tick()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton1(Vector2.new())
            end
        end
    end
end))

-- Background ESP loop
task.spawn(function()
    while not _G.stopScript and screenGui.Parent do
        if featureStates.espEnabled then updateESP() end
        task.wait(CONFIG.ESP_UPDATE_INTERVAL)
    end
end)

-- Performance monitor
local startTime = os.time()
local frameCount, fpsTimer = 0, 0

addConn(Services.RunService.RenderStepped:Connect(function(dt)
    if _G.stopScript then return end
    frameCount += 1
    fpsTimer   += dt
    if fpsTimer >= 1 then
        local fps = math.floor(frameCount / fpsTimer)
        fpsLabel.Text = tostring(fps) .. " FPS"
        fpsLabel.TextColor3 = fps >= 50 and COLORS.ACCENT or fps >= 30 and COLORS.YELLOW or COLORS.RED
        frameCount = 0
        fpsTimer   = 0
    end
end))

task.spawn(function()
    while not _G.stopScript and screenGui.Parent do
        local ping = 0
        local ok, res = pcall(function()
            return math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and res then ping = res end
        pingLabel.Text = tostring(ping) .. " ms"
        pingLabel.TextColor3 = ping < 60 and COLORS.GREEN or ping < 120 and COLORS.YELLOW or COLORS.RED
        playersLabel.Text = tostring(#Services.Players:GetPlayers()) .. "/" .. tostring(Services.Players.MaxPlayers)
        local elapsed = os.time() - startTime
        timeLabel.Text = string.format("%02d:%02d:%02d", math.floor(elapsed/3600), math.floor((elapsed%3600)/60), elapsed%60)
        task.wait(CONFIG.STATS_UPDATE_INTERVAL)
    end
end)

-- ==========================================================
-- 21. INPUT HANDLERS & WAYPOINT HOTKEYS
-- ==========================================================
local numKeyMap = {
    [Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]   = 2, [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four]  = 4, [Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]   = 6,
    [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine]  = 9,
}

addConn(Services.UserInput.InputBegan:Connect(function(input, gpe)
    if _G.stopScript or gpe then return end
    local key = input.KeyCode

    if key == Enum.KeyCode.K then
        mainFrame.Visible = not mainFrame.Visible
    elseif key == keybinds.Freecam then
        togFreecam.setState(not featureStates.freecamEnabled)
    elseif key == keybinds.Fly then
        togFly.setState(not featureStates.flyEnabled)
    elseif key == keybinds.Noclip then
        togNoclip.setState(not featureStates.noclipEnabled)
    elseif key == keybinds.ClickTP then
        togClickTp.setState(not featureStates.clickTpEnabled)
    elseif key == keybinds.InfJump then
        togInfJump.setState(not featureStates.infJumpEnabled)
    elseif key == keybinds.ESP then
        togEsp.setState(not featureStates.espEnabled)
        updateESP()
    elseif key == keybinds.Aimbot then
        togAimbot.setState(not featureStates.aimbotEnabled)
    end

    local wpIdx = numKeyMap[key]
    if wpIdx and #waypointsList >= wpIdx then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = waypointsList[wpIdx].CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end))

addConn(Services.UserInput.InputBegan:Connect(function(input, gpe)
    if _G.stopScript or gpe then return end
    if featureStates.clickTpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or Services.UserInput:IsKeyDown(Enum.KeyCode.RightControl) then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and mouse.Hit then
                local currentRot = hrp.CFrame - hrp.CFrame.Position
                hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) * currentRot
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

addConn(Services.UserInput.JumpRequest:Connect(function()
    if _G.stopScript then return end
    if featureStates.infJumpEnabled then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

addConn(player.Idled:Connect(function()
    if _G.stopScript then return end
    if featureStates.antiAfkEnabled then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- ==========================================================
-- 22. WINDOW CONTROLS & CLEANUP ROUTINE
-- ==========================================================
local isMinimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 300, 0, 46)
        sidebar.Visible = false
        contentArea.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 660, 0, 480)
        sidebar.Visible = true
        contentArea.Visible = true
        minimizeBtn.Text = "−"
    end
end)

logoBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local function unloadAllFeatures()
    _G.stopScript = true

    if autoTpThread then task.cancel(autoTpThread); autoTpThread = nil end
    if flyActive then toggleFly(false) end
    if not Clip then toggleNoclip(false) end
    if freecamState.enabled then toggleFreecam() end

    setInvisibility(false)
    resetHitboxes()
    stopSpectate()
    restoreAggressiveFixLag()

    if fovCircle then pcall(function() fovCircle:Remove() end) end

    Services.Lighting.Brightness    = originalLighting.Brightness
    Services.Lighting.ClockTime     = originalLighting.ClockTime
    Services.Lighting.GlobalShadows = originalLighting.GlobalShadows
    Services.Lighting.FogEnd        = originalLighting.FogEnd
    settings().Rendering.QualityLevel = originalLighting.Quality

    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed     = 16
        hum.UseJumpPower  = true
        hum.JumpPower     = 50
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end

    for p, _ in pairs(espCache) do
        cleanupPlayerESP(p)
    end
    table.clear(espCache)

    for _, conn in ipairs(Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(Connections)

    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end

    print("✅ DEV MASTER V2 (AGGRESSIVE GRAPHICS) unloaded cleanly.")
end

_G.DevMasterUnload = unloadAllFeatures
closeBtn.MouseButton1Click:Connect(unloadAllFeatures)

print("✅ DEV MASTER ULTIMATE V2 (AGGRESSIVE GRAPHICS) LOADED")
print("📌 Aggressive Fix Lag & Dynamic Hooking ready")
print("📌 Sliders & InputBoxes unlocked up to 1000")