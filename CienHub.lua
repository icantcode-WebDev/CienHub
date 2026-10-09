--[[
    CIENHUB | Roblox-native animated UI shell
    Version: 2.0.0

    INSTALLATION
      - Add this file as a LocalScript under StarterPlayer > StarterPlayerScripts
        in an experience you own or are authorized to develop.
      - It creates a ScreenGui under the local player's PlayerGui.
      - No HTTP requests, loadstring, remote-event abuse, anti-cheat bypass, ESP,
        arbitrary-game teleportation, or unauthorized gameplay modification is used.

    INCLUDED
      - Responsive desktop/mobile floating panel, touch dragging and scrolling
      - Animated purple gradients, beveled shadow, hover/press feedback, page transitions
      - Profile thumbnail, notification toasts, animated minimized C bubble
      - Dark/light themes, working UI toggles, scale slider, visual presets
      - Demo waypoint selection and read-only local character status

    The player/world/waypoint controls intentionally demonstrate UI state only.
    Connect them to documented, server-authorized APIs in your own experience.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[CienHub] This must run from a LocalScript on the client.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = PlayerGui:FindFirstChild("CienHubUI")
if oldGui then oldGui:Destroy() end

local function new(className, props, parent)
    local instance = Instance.new(className)
    for key, value in pairs(props or {}) do
        local ok, err = pcall(function() instance[key] = value end)
        if not ok then warn("[CienHub] Property " .. key .. " was not applied: " .. tostring(err)) end
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function addStroke(parent, role, thickness, transparency)
    local s = new("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
    s:SetAttribute("CHThemeRole", role or "Border")
    return s
end

local function addGradient(parent, role, rotation)
    local g = new("UIGradient", {Rotation = rotation or 25}, parent)
    g:SetAttribute("CHThemeRole", role or "PanelGradient")
    return g
end

local function applyRole(instance, role, palette)
    local isText = instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
    if role == "Background" or role == "Surface" or role == "Surface2" or role == "Button" then
        if instance:IsA("GuiObject") then
            if role == "Background" then instance.BackgroundColor3 = palette.Background end
            if role == "Surface" then instance.BackgroundColor3 = palette.Surface end
            if role == "Surface2" then instance.BackgroundColor3 = palette.Surface2 end
            if role == "Button" then instance.BackgroundColor3 = palette.Button end
        end
    elseif role == "Text" and isText then
        instance.TextColor3 = palette.Text
    elseif role == "Muted" and isText then
        instance.TextColor3 = palette.Muted
    elseif role == "Accent" then
        if instance:IsA("GuiObject") then instance.BackgroundColor3 = palette.Accent end
        if instance:IsA("UIStroke") then instance.Color = palette.Accent end
        if isText then instance.TextColor3 = palette.Accent end
    elseif role == "Border" and instance:IsA("UIStroke") then
        instance.Color = palette.Border
    elseif role == "Good" then
        if instance:IsA("GuiObject") then instance.BackgroundColor3 = palette.Good end
        if instance:IsA("UIStroke") then instance.Color = palette.Good end
        if isText then instance.TextColor3 = palette.Good end
    elseif role == "PanelGradient" and instance:IsA("UIGradient") then
        instance.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, palette.GradientA),
            ColorSequenceKeypoint.new(0.52, palette.GradientMid),
            ColorSequenceKeypoint.new(1, palette.GradientB),
        })
    elseif role == "AccentGradient" and instance:IsA("UIGradient") then
        instance.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, palette.AccentLight),
            ColorSequenceKeypoint.new(1, palette.Accent),
        })
    elseif role == "AccentBar" and instance:IsA("GuiObject") then
        instance.BackgroundColor3 = palette.Accent
    end
end

local PALETTES = {
    Dark = {
        Background = Color3.fromRGB(15, 10, 24),
        Surface = Color3.fromRGB(27, 19, 40),
        Surface2 = Color3.fromRGB(42, 29, 61),
        Button = Color3.fromRGB(54, 35, 78),
        Text = Color3.fromRGB(248, 242, 255),
        Muted = Color3.fromRGB(173, 158, 194),
        Border = Color3.fromRGB(115, 78, 155),
        Good = Color3.fromRGB(103, 226, 172),
        Accent = Color3.fromRGB(166, 96, 255),
        AccentLight = Color3.fromRGB(220, 190, 255),
        GradientA = Color3.fromRGB(55, 28, 83),
        GradientMid = Color3.fromRGB(30, 18, 46),
        GradientB = Color3.fromRGB(14, 10, 23),
    },
    Light = {
        Background = Color3.fromRGB(246, 239, 255),
        Surface = Color3.fromRGB(238, 226, 250),
        Surface2 = Color3.fromRGB(224, 205, 244),
        Button = Color3.fromRGB(220, 195, 247),
        Text = Color3.fromRGB(48, 25, 71),
        Muted = Color3.fromRGB(111, 87, 132),
        Border = Color3.fromRGB(184, 145, 220),
        Good = Color3.fromRGB(37, 145, 99),
        Accent = Color3.fromRGB(132, 62, 218),
        AccentLight = Color3.fromRGB(194, 145, 249),
        GradientA = Color3.fromRGB(230, 208, 251),
        GradientMid = Color3.fromRGB(247, 239, 255),
        GradientB = Color3.fromRGB(226, 208, 247),
    },
}

local state = {
    Theme = "Dark",
    Preset = 1,
    Scale = 1,
    Ambient = true,
    Glow = true,
    Notifications = true,
    ReducedMotion = false,
    CompactSidebar = false,
    SelectedWaypoint = nil,
}

local PRESETS = {
    {Name = "PRIME", Description = "Signature purple glass", Accent = Color3.fromRGB(166, 96, 255), Light = Color3.fromRGB(222, 190, 255), A = Color3.fromRGB(85, 37, 139), B = Color3.fromRGB(37, 17, 61)},
    {Name = "SELECT", Description = "Cool contrast, electric violet", Accent = Color3.fromRGB(113, 185, 255), Light = Color3.fromRGB(204, 235, 255), A = Color3.fromRGB(42, 78, 140), B = Color3.fromRGB(31, 22, 67)},
    {Name = "ULTRA", Description = "Aggressive neon magenta", Accent = Color3.fromRGB(255, 103, 211), Light = Color3.fromRGB(255, 203, 244), A = Color3.fromRGB(137, 38, 126), B = Color3.fromRGB(47, 17, 70)},
}

local function palette()
    local base = table.clone(PALETTES[state.Theme])
    local preset = PRESETS[state.Preset]
    base.Accent = preset.Accent
    base.AccentLight = preset.Light
    if state.Theme == "Dark" then
        base.GradientA = preset.A
        base.GradientB = preset.B
        base.GradientMid = PALETTES.Dark.GradientMid
    else
        base.GradientA = Color3.fromRGB(239, 223, 255)
        base.GradientMid = Color3.fromRGB(248, 243, 255)
        base.GradientB = Color3.fromRGB(225, 205, 247)
    end
    return base
end

local function themed(instance, role)
    instance:SetAttribute("CHThemeRole", role)
    applyRole(instance, role, palette())
    return instance
end

local gui = new("ScreenGui", {
    Name = "CienHubUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 80,
}, PlayerGui)

local shadow = new("Frame", {
    Name = "PanelShadow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52) + UDim2.fromOffset(0, 9),
    Size = UDim2.fromOffset(660, 464),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.48,
    BorderSizePixel = 0,
}, gui)
corner(shadow, 22)

local panel = new("Frame", {
    Name = "MainPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.51),
    Size = UDim2.fromOffset(660, 464),
    BackgroundColor3 = palette().Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
corner(panel, 20)
themed(panel, "Background")
local panelStroke = addStroke(panel, "Border", 1.4, 0.16)
local panelGradient = addGradient(panel, "PanelGradient", 20)

local accentEdge = new("Frame", {
    Name = "TopAccentEdge",
    Size = UDim2.new(1, -38, 0, 3),
    Position = UDim2.new(0, 19, 0, 0),
    BorderSizePixel = 0,
}, panel)
corner(accentEdge, 3)
accentEdge:SetAttribute("CHAccentElement", true)
addGradient(accentEdge, "AccentGradient", 0)

local header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = palette().Surface,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, panel)
themed(header, "Surface")
local headerGradient = addGradient(header, "PanelGradient", 0)

local logoTile = new("Frame", {
    Name = "LogoTile",
    Position = UDim2.new(0, 15, 0, 12),
    Size = UDim2.fromOffset(43, 43),
    BorderSizePixel = 0,
    BackgroundColor3 = palette().Accent,
}, header)
corner(logoTile, 13)
logoTile:SetAttribute("CHAccentElement", true)
addStroke(logoTile, "Accent", 1.2, 0.08)
addGradient(logoTile, "AccentGradient", 35)

local logoText = new("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "C",
    Font = Enum.Font.GothamBlack,
    TextSize = 31,
    TextColor3 = Color3.new(1, 1, 1),
    TextStrokeTransparency = 0.7,
    Rotation = -7,
}, logoTile)
local logoSlash = new("Frame", {
    Name = "LogoSlash",
    Position = UDim2.new(0, 28, 0, 9),
    Size = UDim2.fromOffset(3, 26),
    Rotation = 35,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    ZIndex = 5,
}, logoTile)
corner(logoSlash, 2)

local brandTitle = new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 68, 0, 12),
    Size = UDim2.new(0, 180, 0, 25),
    Font = Enum.Font.GothamBlack,
    Text = "CIENHUB",
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
themed(brandTitle, "Text")

local brandSubtitle = new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 69, 0, 37),
    Size = UDim2.new(0, 275, 0, 17),
    Font = Enum.Font.GothamMedium,
    Text = "MOTION CONTROL / UI SHELL  •  v2.0",
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
themed(brandSubtitle, "Muted")

local statusDot = new("Frame", {
    Position = UDim2.new(1, -114, 0, 29),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = palette().Good,
    BorderSizePixel = 0,
}, header)
corner(statusDot, 10)
themed(statusDot, "Good")
local statusText = new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -102, 0, 21),
    Size = UDim2.fromOffset(64, 22),
    Font = Enum.Font.GothamBold,
    Text = "READY",
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
themed(statusText, "Good")

local function makeText(parent, text, size, role, font, props)
    props = props or {}
    props.BackgroundTransparency = props.BackgroundTransparency == nil and 1 or props.BackgroundTransparency
    props.Text = text
    props.TextSize = size or 12
    props.Font = font or Enum.Font.Gotham
    props.TextWrapped = props.TextWrapped == nil and true or props.TextWrapped
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    local obj = new("TextLabel", props, parent)
    if role then themed(obj, role) end
    return obj
end

local function makeButton(parent, text, props)
    props = props or {}
    local isAccentButton = props.AccentButton == true
    local buttonRadius = props.CornerRadius or 10
    props.AccentButton = nil
    props.CornerRadius = nil
    props.Text = text
    props.Font = props.Font or Enum.Font.GothamBold
    props.TextSize = props.TextSize or 11
    props.AutoButtonColor = false
    props.BorderSizePixel = 0
    props.BackgroundColor3 = props.BackgroundColor3 or palette().Button
    props.TextColor3 = props.TextColor3 or (isAccentButton and Color3.new(1, 1, 1) or palette().Text)
    local b = new("TextButton", props, parent)
    corner(b, buttonRadius)
    local s = addStroke(b, "Border", 1, 0.42)
    local g = addGradient(b, "AccentGradient", 0)
    g.Enabled = isAccentButton
    if isAccentButton then
        b.BackgroundColor3 = palette().Accent
        b:SetAttribute("CHAccentElement", true)
        s.Transparency = 0.28
    else
        themed(b, "Button")
    end
    local baseSize = b.Size
    b.MouseEnter:Connect(function()
        if not state.ReducedMotion then
            TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = isAccentButton and 0.02 or 0.03,
                Size = baseSize + UDim2.fromOffset(0, 1),
            }):Play()
        end
        if state.Glow then s.Transparency = 0.12 end
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = baseSize,
        }):Play()
        s.Transparency = isAccentButton and 0.28 or 0.42
    end)
    b.Activated:Connect(function()
        if not state.ReducedMotion then
            local down = TweenService:Create(b, TweenInfo.new(0.07), {Size = baseSize - UDim2.fromOffset(2, 2)})
            down:Play()
            down.Completed:Connect(function()
                if b.Parent then TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = baseSize}):Play() end
            end)
        end
    end)
    return b
end

local closeButton = makeButton(header, "−", {
    Name = "MinimizeButton",
    Position = UDim2.new(1, -31, 0, 19),
    Size = UDim2.fromOffset(22, 28),
    TextSize = 20,
})
closeButton.BackgroundTransparency = 0.1

local sidebar = new("Frame", {
    Name = "Sidebar",
    Position = UDim2.new(0, 12, 0, 80),
    Size = UDim2.new(0, 158, 1, -92),
    BackgroundColor3 = palette().Surface,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, panel)
corner(sidebar, 15)
themed(sidebar, "Surface")
addStroke(sidebar, "Border", 1, 0.55)

local avatarFrame = new("Frame", {
    Position = UDim2.new(0, 9, 0, 10),
    Size = UDim2.new(1, -18, 0, 62),
    BackgroundColor3 = palette().Surface2,
    BorderSizePixel = 0,
}, sidebar)
corner(avatarFrame, 12)
themed(avatarFrame, "Surface2")

local avatar = new("ImageLabel", {
    Name = "PlayerAvatar",
    Position = UDim2.new(0, 8, 0.5, -18),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = palette().Accent,
    BackgroundTransparency = 0.1,
    Image = "",
    ScaleType = Enum.ScaleType.Crop,
}, avatarFrame)
corner(avatar, 18)
addStroke(avatar, "Accent", 1.4, 0.05)

local profileName = makeText(avatarFrame, LocalPlayer.DisplayName or LocalPlayer.Name, 10, "Text", Enum.Font.GothamBold, {
    Position = UDim2.new(0, 51, 0, 14),
    Size = UDim2.new(1, -56, 0, 17),
    TextTruncate = Enum.TextTruncate.AtEnd,
})
local profileStatus = makeText(avatarFrame, "●  LOCAL PROFILE", 7, "Muted", Enum.Font.GothamMedium, {
    Position = UDim2.new(0, 51, 0, 33),
    Size = UDim2.new(1, -54, 0, 14),
})

local avatarImage
-- Fetch the player's headshot asynchronously so the panel appears without waiting on thumbnails.
task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and avatar and avatar.Parent then
        avatarImage = image
        avatar.Image = image
    end
end)

makeText(sidebar, "WORKSPACE", 8, "Muted", Enum.Font.GothamBlack, {
    Name = "WorkspaceLabel",
    Position = UDim2.new(0, 13, 0, 82),
    Size = UDim2.new(1, -20, 0, 17),
})

local navFrame = new("Frame", {
    Position = UDim2.new(0, 7, 0, 104),
    Size = UDim2.new(1, -14, 1, -143),
    BackgroundTransparency = 1,
}, sidebar)
new("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, navFrame)

local sideFooter = makeText(sidebar, "●  INTERFACE ONLINE", 7, "Good", Enum.Font.GothamBold, {
    Position = UDim2.new(0, 11, 1, -27),
    Size = UDim2.new(1, -18, 0, 17),
})

local content = new("Frame", {
    Name = "ContentArea",
    Position = UDim2.new(0, 182, 0, 81),
    Size = UDim2.new(1, -194, 1, -93),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, panel)

local pageTitle = makeText(content, "Overview", 19, "Text", Enum.Font.GothamBlack, {
    Name = "PageTitle",
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, -4, 0, 29),
})
local pageSubtitle = makeText(content, "A sharp, animated interface for your own experience.", 10, "Muted", Enum.Font.Gotham, {
    Name = "PageSubtitle",
    Position = UDim2.new(0, 0, 0, 29),
    Size = UDim2.new(1, -4, 0, 22),
})

local pageBody = new("ScrollingFrame", {
    Name = "PageBody",
    Position = UDim2.new(0, 0, 0, 56),
    Size = UDim2.new(1, 0, 1, -56),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = palette().Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, content)

local pageMeta = {
    Overview = {"Overview", "A sharp, animated interface for your own experience."},
    Player = {"Player Panel", "Profile and read-only local character diagnostics."},
    Waypoints = {"Waypoints", "Select a demo destination; no teleport is performed."},
    ["World Tools"] = {"World Tools", "Interface-side utilities for an authorized experience."},
    ["Visual Profiles"] = {"Visual Profiles", "Change the CienHub interface atmosphere."},
    Settings = {"Settings", "Theme, motion, notifications, and layout preferences."},
}
local currentPage = "Overview"
local navButtons = {}
local updatePanelSize
local makeWorkspaceLabelCompact
local activeSliderUpdater = nil
local navItems = nil
local renderPage
local toastHolder = new("Frame", {
    Name = "ToastHolder",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 12),
    Size = UDim2.new(0, 245, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 100,
}, gui)
new("UIListLayout", {Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, toastHolder)

local function notify(message, kind)
    if not state.Notifications then return end
    kind = kind or "info"
    local p = palette()
    local tint = p.Accent
    if kind == "success" then tint = p.Good end
    if kind == "warning" then tint = Color3.fromRGB(255, 187, 93) end
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = p.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, toastHolder)
    corner(card, 12)
    addStroke(card, "Border", 1.2, 0.12).Color = tint
    local bar = new("Frame", {Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, 3, 1, -16), BackgroundColor3 = tint, BorderSizePixel = 0, ZIndex = 102}, card)
    corner(bar, 3)
    local labelObj = new("TextLabel", {
        Position = UDim2.new(0, 19, 0, 4),
        Size = UDim2.new(1, -26, 1, -8),
        BackgroundTransparency = 1,
        Text = "✦  " .. tostring(message),
        TextColor3 = p.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
    }, card)
    card.Position = UDim2.new(0, 18, 0, 0)
    TweenService:Create(card, TweenInfo.new(state.ReducedMotion and 0 or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    task.delay(2.7, function()
        if card and card.Parent then
            if not state.ReducedMotion then
                local t = TweenService:Create(card, TweenInfo.new(0.18), {Position = UDim2.new(0, 24, 0, 0), BackgroundTransparency = 1})
                t:Play()
                t.Completed:Wait()
            end
            if card and card.Parent then card:Destroy() end
        end
    end)
end

local function card(parent, title, height)
    local f = new("Frame", {
        Name = "Card_" .. title:gsub("%W", ""),
        Size = UDim2.new(1, -3, 0, height or 90),
        BackgroundColor3 = palette().Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    }, parent)
    corner(f, 13)
    themed(f, "Surface")
    local st = addStroke(f, "Border", 1, 0.52)
    local bar = new("Frame", {Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = palette().Accent, BorderSizePixel = 0}, f)
    bar:SetAttribute("CHAccentElement", true)
    corner(bar, 2)
    st:SetAttribute("CHCardStroke", true)
    local h = makeText(f, title, 12, "Text", Enum.Font.GothamBold, {
        Position = UDim2.new(0, 13, 0, 8),
        Size = UDim2.new(1, -25, 0, 22),
    })
    if state.Glow then st.Transparency = 0.3 end
    f.MouseEnter:Connect(function()
        if state.Glow then st.Transparency = 0.15 end
        if not state.ReducedMotion then TweenService:Create(f, TweenInfo.new(0.15), {BackgroundTransparency = 0.01}):Play() end
    end)
    f.MouseLeave:Connect(function()
        st.Transparency = state.Glow and 0.3 or 0.65
        TweenService:Create(f, TweenInfo.new(0.18), {BackgroundTransparency = 0.08}):Play()
    end)
    return f, h
end

local function description(parent, text, pos, size)
    return makeText(parent, text, 10, "Muted", Enum.Font.Gotham, {
        Position = pos,
        Size = size,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
end

local function toggleRow(parent, key, title, desc, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, -22, 0, 49),
        BackgroundTransparency = 1,
    }, parent)
    local titleLabel = makeText(row, title, 10, "Text", Enum.Font.GothamBold, {
        Position = UDim2.new(0, 0, 0, 3),
        Size = UDim2.new(1, -61, 0, 18),
    })
    description(row, desc, UDim2.new(0, 0, 0, 21), UDim2.new(1, -61, 0, 24))
    local track = new("TextButton", {
        Name = "Toggle_" .. key,
        Position = UDim2.new(1, -48, 0, 11),
        Size = UDim2.fromOffset(43, 24),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = state[key] and palette().Accent or palette().Surface2,
    }, row)
    corner(track, 14)
    local knob = new("Frame", {
        Position = state[key] and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    corner(knob, 12)
    addStroke(knob, "Border", 0.7, 0.8)
    local function redraw(animate)
        local on = state[key]
        local targetColor = on and palette().Accent or palette().Surface2
        local targetPosition = on and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
        if animate and not state.ReducedMotion then
            TweenService:Create(track, TweenInfo.new(0.16), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPosition}):Play()
        else
            track.BackgroundColor3 = targetColor
            knob.Position = targetPosition
        end
    end
    track.Activated:Connect(function()
        state[key] = not state[key]
        redraw(true)
        if callback then callback(state[key]) end
    end)
    track:SetAttribute("CHToggleKey", key)
    return redraw
end

local function buttonRow(parent, title, desc, actionText, callback)
    local row = new("Frame", {Size = UDim2.new(1, -22, 0, 54), BackgroundTransparency = 1}, parent)
    makeText(row, title, 10, "Text", Enum.Font.GothamBold, {Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, -98, 0, 18)})
    description(row, desc, UDim2.new(0, 0, 0, 22), UDim2.new(1, -100, 0, 27))
    local b = makeButton(row, actionText, {
        Position = UDim2.new(1, -91, 0.5, -15),
        Size = UDim2.fromOffset(91, 30),
        TextSize = 9,
        AccentButton = false,
    })
    b.Activated:Connect(callback)
    return row
end

local function addPrimaryButton(parent, text, callback, y)
    local b = makeButton(parent, text, {
        Position = UDim2.new(0, 0, 0, y or 0),
        Size = UDim2.new(1, 0, 0, 32),
        TextSize = 10,
        AccentButton = true,
    })
    b.Activated:Connect(callback)
    return b
end

local function updateAllTheme()
    local p = palette()
    for _, inst in ipairs(gui:GetDescendants()) do
        local role = inst:GetAttribute("CHThemeRole")
        if role then applyRole(inst, role, p) end
        local toggleKey = inst:GetAttribute("CHToggleKey")
        if toggleKey then
            inst.BackgroundColor3 = state[toggleKey] and p.Accent or p.Surface2
            local knob = inst:FindFirstChildWhichIsA("Frame")
            if knob then knob.Position = state[toggleKey] and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3) end
        end
    end
    pageBody.ScrollBarImageColor3 = p.Accent
    if state.Glow then panelStroke.Transparency = 0.12 else panelStroke.Transparency = 0.62 end
    -- Accent-bearing bars and controls update with the selected preset.
    for _, inst in ipairs(gui:GetDescendants()) do
        if inst:GetAttribute("CHAccentElement") then
            if inst:IsA("GuiObject") then inst.BackgroundColor3 = p.Accent end
            if inst:IsA("UIStroke") then inst.Color = p.Accent end
        end
        if inst:GetAttribute("CHCardStroke") and inst:IsA("UIStroke") then
            inst.Transparency = state.Glow and 0.3 or 0.65
        end
    end
    for name, nav in pairs(navButtons) do
        local active = name == currentPage
        nav.BackgroundColor3 = active and p.Accent or p.Surface2
        nav.BackgroundTransparency = active and 0.02 or 0.55
        nav.TextColor3 = active and Color3.new(1, 1, 1) or p.Muted
        local activeBar = nav:FindFirstChild("ActiveBar")
        if activeBar then activeBar.Visible = active end
    end
end

local function setTheme(name)
    state.Theme = name
    updateAllTheme()
    notify(name == "Dark" and "Dark theme activated" or "Light theme activated", "success")
end

local function setPreset(index)
    state.Preset = ((index - 1) % #PRESETS) + 1
    updateAllTheme()
    notify("Visual preset: " .. PRESETS[state.Preset].Name, "success")
end

local function clearPage()
    for _, child in ipairs(pageBody:GetChildren()) do
        if child:GetAttribute("CHPageContent") then child:Destroy() end
    end
end

local function pageRoot()
    local root = new("Frame", {
        Name = "PageContent",
        Size = UDim2.new(1, -8, 0, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, pageBody)
    root:SetAttribute("CHPageContent", true)
    local list = new("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, root)
    TweenService:Create(root, TweenInfo.new(state.ReducedMotion and 0 or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    return root
end

local function heroCard(parent)
    local f = new("Frame", {
        Size = UDim2.new(1, -3, 0, 126),
        BackgroundColor3 = palette().Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    corner(f, 15)
    themed(f, "Surface")
    addStroke(f, "Border", 1.2, 0.18)
    addGradient(f, "PanelGradient", 0)
    local badge = makeText(f, "✦  CIENHUB / CONTROL DECK", 8, "Accent", Enum.Font.GothamBlack, {
        Position = UDim2.new(0, 14, 0, 12), Size = UDim2.new(1, -94, 0, 16),
    })
    local title = makeText(f, "Own your interface.", 21, "Text", Enum.Font.GothamBlack, {
        Position = UDim2.new(0, 14, 0, 34), Size = UDim2.new(1, -93, 0, 29),
    })
    local subtitle = makeText(f, "Responsive by design. Built for your own experience.", 9, "Muted", Enum.Font.Gotham, {
        Position = UDim2.new(0, 14, 0, 67), Size = UDim2.new(1, -103, 0, 31),
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    local mark = new("Frame", {
        Position = UDim2.new(1, -81, 0.5, -29),
        Size = UDim2.fromOffset(58, 58),
        BackgroundColor3 = palette().Accent,
        BorderSizePixel = 0,
        Rotation = -7,
    }, f)
    corner(mark, 17)
    mark:SetAttribute("CHAccentElement", true)
    addStroke(mark, "Accent", 1.5, 0.08)
    addGradient(mark, "AccentGradient", 35)
    local c = makeText(mark, "C", 37, nil, Enum.Font.GothamBlack, {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center})
    c.TextColor3 = Color3.new(1, 1, 1)
    local ring = new("Frame", {
        Position = UDim2.new(1, -87, 0.5, -35),
        Size = UDim2.fromOffset(70, 70),
        BackgroundTransparency = 1,
        Rotation = 21,
    }, f)
    corner(ring, 22)
    addStroke(ring, "Accent", 1, 0.4)
    if not state.ReducedMotion then
        task.spawn(function()
            while ring.Parent and not state.ReducedMotion do
                local t = TweenService:Create(ring, TweenInfo.new(8, Enum.EasingStyle.Linear), {Rotation = ring.Rotation + 360})
                t:Play(); t.Completed:Wait()
            end
        end)
    end
end

local function smallStat(parent, labelText, valueText, subText, order)
    local f = new("Frame", {
        LayoutOrder = order or 1,
        Size = UDim2.new(0.333, -5, 0, 70),
        BackgroundColor3 = palette().Surface,
        BorderSizePixel = 0,
    }, parent)
    corner(f, 11)
    themed(f, "Surface")
    addStroke(f, "Border", 1, 0.52)
    makeText(f, labelText, 8, "Muted", Enum.Font.GothamBlack, {Position = UDim2.new(0, 9, 0, 8), Size = UDim2.new(1, -15, 0, 15)})
    makeText(f, valueText, 16, "Text", Enum.Font.GothamBlack, {Position = UDim2.new(0, 9, 0, 25), Size = UDim2.new(1, -15, 0, 21)})
    makeText(f, subText, 7, "Good", Enum.Font.GothamMedium, {Position = UDim2.new(0, 9, 0, 49), Size = UDim2.new(1, -15, 0, 13)})
    return f
end

local function toggleCard(parent, titleText, descText, keys)
    local f = card(parent, titleText, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    local body = new("Frame", {Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y}, f)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    for _, key in ipairs(keys) do
        if key == "Ambient" then
            toggleRow(body, "Ambient", "Animated gradient", "Moving purple atmosphere", function(v)
                if not v then notify("Ambient motion paused", "info") else notify("Ambient motion enabled", "success") end
            end)
        elseif key == "Glow" then
            toggleRow(body, "Glow", "3D edge lighting", "Reactive card outlines", function(v)
                updateAllTheme()
                notify("Edge lighting " .. (v and "enabled" or "reduced"), "info")
            end)
        elseif key == "Notifications" then
            toggleRow(body, "Notifications", "Notifications", "Toast feedback for actions", function(v)
                if v then notify("Notifications enabled", "success") end
            end)
        elseif key == "ReducedMotion" then
            toggleRow(body, "ReducedMotion", "Reduced motion", "Use simpler transitions", function(v)
                notify("Reduced motion " .. (v and "enabled" or "disabled"), "info")
            end)
        elseif key == "CompactSidebar" then
            toggleRow(body, "CompactSidebar", "Compact sidebar", "Use an icon-first navigation rail", function(v)
                updatePanelSize()
                notify("Sidebar density changed", "success")
                -- The actual viewport-responsive sidebar logic also chooses compact mode automatically.
            end)
        end
    end
    f.Size = UDim2.new(1, -3, 0, 34 + (#keys * 51) + 10)
    f.AutomaticSize = Enum.AutomaticSize.None
    return f
end

local function sliderCard(parent)
    local f = card(parent, "Interface scale", 94)
    local value = makeText(f, tostring(math.floor(state.Scale * 100 + 0.5)) .. "%", 10, "Accent", Enum.Font.GothamBlack, {
        Position = UDim2.new(1, -61, 0, 10), Size = UDim2.fromOffset(48, 20), TextXAlignment = Enum.TextXAlignment.Right,
    })
    local rail = new("TextButton", {
        Name = "ScaleSliderTrack",
        Position = UDim2.new(0, 13, 0, 49),
        Size = UDim2.new(1, -26, 0, 8),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        BackgroundColor3 = palette().Surface2,
    }, f)
    corner(rail, 5)
    themed(rail, "Surface2")
    local fill = new("Frame", {Size = UDim2.new((state.Scale - 0.8) / 0.35, 0, 1, 0), BackgroundColor3 = palette().Accent, BorderSizePixel = 0}, rail)
    fill:SetAttribute("CHAccentElement", true)
    corner(fill, 5)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((state.Scale - 0.8) / 0.35, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, rail)
    corner(knob, 9)
    addStroke(knob, "Accent", 2, 0.02)
    makeText(f, "COMPACT", 7, "Muted", Enum.Font.GothamBold, {Position = UDim2.new(0, 13, 0, 64), Size = UDim2.new(0, 65, 0, 13)})
    makeText(f, "LARGE", 7, "Muted", Enum.Font.GothamBold, {Position = UDim2.new(1, -66, 0, 64), Size = UDim2.new(0, 53, 0, 13), TextXAlignment = Enum.TextXAlignment.Right})
    local draggingSlider = false
    local function setScaleFromX(x)
        local width = math.max(1, rail.AbsoluteSize.X)
        local alpha = math.clamp((x - rail.AbsolutePosition.X) / width, 0, 1)
        state.Scale = 0.8 + alpha * 0.35
        state.Scale = math.floor(state.Scale * 20 + 0.5) / 20
        local normalized = (state.Scale - 0.8) / 0.35
        fill.Size = UDim2.new(normalized, 0, 1, 0)
        knob.Position = UDim2.new(normalized, 0, 0.5, 0)
        value.Text = tostring(math.floor(state.Scale * 100 + 0.5)) .. "%"
    end
    rail.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            activeSliderUpdater = setScaleFromX
            setScaleFromX(input.Position.X)
        end
    end)
    rail.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
            activeSliderUpdater = nil
            if updatePanelSize then updatePanelSize() end
        end
    end)
    return f
end

local function infoCard(parent, heading, bodyText, height)
    local f = card(parent, heading, height or 76)
    description(f, bodyText, UDim2.new(0, 13, 0, 34), UDim2.new(1, -26, 1, -39))
    return f
end

local function pageOverview(root)
    heroCard(root)
    local stats = new("Frame", {Size = UDim2.new(1, -3, 0, 70), BackgroundTransparency = 1}, root)
    local layout = new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, stats)
    smallStat(stats, "UI STATUS", "READY", "Client interface", 1)
    smallStat(stats, "THEME", state.Theme:upper(), "Instant switch", 2)
    smallStat(stats, "PRESET", PRESETS[state.Preset].Name, "Visual identity", 3)
    local f = card(root, "Quick controls", 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    local body = new("Frame", {Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y}, f)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    toggleRow(body, "Ambient", "Animated purple background", "Subtle moving gradient", function(v) notify("Ambient background " .. (v and "enabled" or "paused"), "info") end)
    toggleRow(body, "Glow", "3D reactive glow", "Card edges and raised surfaces", function(v) updateAllTheme(); notify("3D edge glow updated", "info") end)
    toggleRow(body, "Notifications", "Notifications", "Show action feedback", function(v) if v then notify("Notifications enabled", "success") end end)
    f.Size = UDim2.new(1, -3, 0, 34 + 3 * 51 + 10)
    f.AutomaticSize = Enum.AutomaticSize.None
    local q = card(root, "Fast actions", 79)
    local b1 = makeButton(q, "TEST TOAST", {Position = UDim2.new(0, 12, 0, 38), Size = UDim2.new(0.48, -5, 0, 29), TextSize = 9, AccentButton = true})
    b1.Activated:Connect(function() notify("CienHub is ready", "success") end)
    local b2 = makeButton(q, "SETTINGS", {Position = UDim2.new(0.52, 0, 0, 38), Size = UDim2.new(0.48, -12, 0, 29), TextSize = 9})
    b2.Activated:Connect(function() renderPage("Settings") end)
end

local function pagePlayer(root)
    local f = card(root, "Local profile", 96)
    local bigAvatar = new("ImageLabel", {Position = UDim2.new(0, 13, 0, 39), Size = UDim2.fromOffset(43, 43), BackgroundColor3 = palette().Accent, Image = avatar.Image, ScaleType = Enum.ScaleType.Crop}, f)
    corner(bigAvatar, 22); addStroke(bigAvatar, "Accent", 1.5, 0.05)
    makeText(f, LocalPlayer.DisplayName or LocalPlayer.Name, 12, "Text", Enum.Font.GothamBlack, {Position = UDim2.new(0, 66, 0, 39), Size = UDim2.new(1, -78, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd})
    makeText(f, "@" .. LocalPlayer.Name .. "  ·  ID " .. tostring(LocalPlayer.UserId), 8, "Muted", Enum.Font.Gotham, {Position = UDim2.new(0, 66, 0, 60), Size = UDim2.new(1, -78, 0, 17), TextTruncate = Enum.TextTruncate.AtEnd})
    local stats = card(root, "Character diagnostics (read-only)", 103)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local health = hum and string.format("%d / %d", math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5)) or "Unavailable"
    local walkspeed = hum and tostring(math.floor(hum.WalkSpeed + 0.5)) or "Unavailable"
    local stateLabel = hum and hum:GetState().Name or "No character"
    makeText(stats, "Health", 9, "Muted", Enum.Font.GothamBold, {Position = UDim2.new(0, 13, 0, 38), Size = UDim2.new(0.34, 0, 0, 18)})
    makeText(stats, health, 10, "Text", Enum.Font.GothamBold, {Position = UDim2.new(0.34, 0, 0, 38), Size = UDim2.new(0.28, 0, 0, 18)})
    makeText(stats, "WalkSpeed", 9, "Muted", Enum.Font.GothamBold, {Position = UDim2.new(0, 13, 0, 64), Size = UDim2.new(0.34, 0, 0, 18)})
    makeText(stats, walkspeed, 10, "Text", Enum.Font.GothamBold, {Position = UDim2.new(0.34, 0, 0, 64), Size = UDim2.new(0.28, 0, 0, 18)})
    makeText(stats, stateLabel, 8, "Accent", Enum.Font.GothamMedium, {Position = UDim2.new(0.64, 0, 0, 51), Size = UDim2.new(0.32, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Right})
    buttonRow(root, "Refresh profile", "Refresh the avatar and current read-only status.", "REFRESH", function()
        avatarOk, avatarImage = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if avatarOk then avatar.Image = avatarImage end
        renderPage("Player")
        notify("Profile refreshed", "success")
    end)
    infoCard(root, "Gameplay boundary", "This panel does not change movement, health, flight, or other gameplay values. Wire approved controls through your own experience's documented API.", 75)
end

local function pageWaypoints(root)
    infoCard(root, "Demo destination selector", "Choose a card to update the selected label. This is a UI interaction only; no character teleport occurs.", 70)
    local destinations = {
        {Name = "STAR DECK", Desc = "Featured test destination", Icon = "✦"},
        {Name = "VIOLET LAB", Desc = "Layout and lighting room", Icon = "◇"},
        {Name = "CORE ROOM", Desc = "Main hub preview", Icon = "⌘"},
    }
    for _, destination in ipairs(destinations) do
        local selected = state.SelectedWaypoint == destination.Name
        local b = makeButton(root, destination.Icon .. "   " .. destination.Name .. "     ›", {
            Size = UDim2.new(1, -3, 0, 48),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 11,
            BackgroundColor3 = selected and palette().Accent or palette().Surface,
            AccentButton = selected,
        })
        local s = addStroke(b, selected and "Accent" or "Border", selected and 1.5 or 1, selected and 0.08 or 0.45)
        b.Activated:Connect(function()
            state.SelectedWaypoint = destination.Name
            renderPage("Waypoints")
            notify(destination.Name .. " selected", "success")
        end)
        description(b, destination.Desc, UDim2.new(0, 42, 0, 25), UDim2.new(1, -50, 0, 15))
        b.TextYAlignment = Enum.TextYAlignment.Top
        b.Text = "    " .. destination.Icon .. "   " .. destination.Name
    end
    local selectedCard = card(root, "Current selection", 68)
    makeText(selectedCard, state.SelectedWaypoint or "No destination selected", 12, "Accent", Enum.Font.GothamBlack, {
        Position = UDim2.new(0, 13, 0, 36), Size = UDim2.new(1, -26, 0, 22),
    })
    if state.SelectedWaypoint then
        local confirm = makeButton(selectedCard, "CONFIRM UI SELECTION", {
            Position = UDim2.new(0, 12, 1, -35), Size = UDim2.new(1, -24, 0, 25), TextSize = 8, AccentButton = true,
        })
        confirm.Activated:Connect(function() notify("Selection confirmed", state.SelectedWaypoint .. " (preview only)") end)
        selectedCard.Size = UDim2.new(1, -3, 0, 91)
    end
end

local function pageWorld(root)
    infoCard(root, "Developer utilities", "Sample actions update this interface only. Add real actions only for documented systems in an experience you own or are allowed to test.", 83)
    buttonRow(root, "Mark test point", "Record a local UI event.", "MARK", function()
        statusText.Text = "TEST MARKED"
        notify("Test point marked", "success")
    end)
    buttonRow(root, "Refresh status", "Refresh the UI status indicator.", "REFRESH", function()
        statusText.Text = "READY"
        notify("Interface status refreshed", "success")
    end)
    buttonRow(root, "Copy profile label", "Display your local profile label in a notification.", "SHOW", function()
        notify("Profile label", LocalPlayer.DisplayName .. "  ·  @" .. LocalPlayer.Name, "info")
    end)
end

local function pageVisuals(root)
    local f = card(root, "Preset wheel", 154)
    makeText(f, "TAP TO CYCLE", 8, "Muted", Enum.Font.GothamBlack, {Position = UDim2.new(0, 13, 0, 35), Size = UDim2.new(1, -26, 0, 14), TextXAlignment = Enum.TextXAlignment.Center})
    local presetLabel = makeText(f, PRESETS[state.Preset].Name, 28, "Accent", Enum.Font.GothamBlack, {Position = UDim2.new(0, 10, 0, 51), Size = UDim2.new(1, -20, 0, 37), TextXAlignment = Enum.TextXAlignment.Center})
    local desc = makeText(f, PRESETS[state.Preset].Description, 9, "Muted", Enum.Font.Gotham, {Position = UDim2.new(0, 10, 0, 88), Size = UDim2.new(1, -20, 0, 17), TextXAlignment = Enum.TextXAlignment.Center})
    local prev = makeButton(f, "‹", {Position = UDim2.new(0.5, -69, 0, 112), Size = UDim2.fromOffset(32, 28), TextSize = 17})
    local nextB = makeButton(f, "›", {Position = UDim2.new(0.5, 37, 0, 112), Size = UDim2.fromOffset(32, 28), TextSize = 17})
    local dots = makeText(f, "●  ○  ○", 9, "Accent", Enum.Font.GothamBlack, {Position = UDim2.new(0.5, -32, 0, 117), Size = UDim2.fromOffset(64, 18), TextXAlignment = Enum.TextXAlignment.Center})
    local function redrawPreset()
        presetLabel.Text = PRESETS[state.Preset].Name
        presetLabel.TextColor3 = PRESETS[state.Preset].Accent
        desc.Text = PRESETS[state.Preset].Description
        dots.Text = (state.Preset == 1 and "●  ○  ○") or (state.Preset == 2 and "○  ●  ○") or "○  ○  ●"
        dots.TextColor3 = PRESETS[state.Preset].Accent
    end
    prev.Activated:Connect(function() setPreset(state.Preset - 1); redrawPreset() end)
    nextB.Activated:Connect(function() setPreset(state.Preset + 1); redrawPreset() end)
    local apply = makeButton(f, "APPLY VISUAL PROFILE", {Position = UDim2.new(0, 12, 1, -34), Size = UDim2.new(1, -24, 0, 25), TextSize = 8, AccentButton = true})
    apply.Activated:Connect(function() updateAllTheme(); notify(PRESETS[state.Preset].Name .. " visual profile applied", "success") end)
    toggleCard(root, "Visual behavior", "Interface-only rendering options", {"Ambient", "Glow", "ReducedMotion"})
end

local function pageSettings(root)
    local f = card(root, "Day / night engine", 92)
    makeText(f, "ANIMATED THEME SWITCH", 8, "Muted", Enum.Font.GothamBlack, {Position = UDim2.new(0, 13, 0, 36), Size = UDim2.new(1, -125, 0, 18)})
    description(f, "Daylight ↔ cosmic night", UDim2.new(0, 13, 0, 55), UDim2.new(1, -125, 0, 24))
    local themeTrack = new("Frame", {
        Position = UDim2.new(1, -112, 0, 40),
        Size = UDim2.fromOffset(100, 34),
        BackgroundColor3 = state.Theme == "Dark" and Color3.fromRGB(42, 35, 77) or Color3.fromRGB(93, 177, 219),
        BorderSizePixel = 0,
    }, f)
    corner(themeTrack, 18)
    addStroke(themeTrack, "Border", 1, 0.2)
    local themeLabel = makeText(themeTrack, state.Theme == "Dark" and "NIGHT" or "DAY", 8, nil, Enum.Font.GothamBlack, {
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = state.Theme == "Dark" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
    })
    local themeKnob = new("Frame", {
        Name = "ThemeOrb",
        Position = state.Theme == "Dark" and UDim2.new(1, -30, 0, 4) or UDim2.new(0, 4, 0, 4),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, themeTrack)
    corner(themeKnob, 15)
    addStroke(themeKnob, "Border", 1, 0.5)
    local themeIcon = makeText(themeKnob, state.Theme == "Dark" and "☾" or "☀", 15, nil, Enum.Font.GothamBlack, {
        Size = UDim2.fromScale(1, 1),
        TextColor3 = state.Theme == "Dark" and Color3.fromRGB(76, 55, 119) or Color3.fromRGB(214, 135, 36),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    local themeHit = new("TextButton", {
        Name = "ThemeSwitchButton",
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, themeTrack)
    themeHit.Activated:Connect(function()
        local nextTheme = state.Theme == "Dark" and "Light" or "Dark"
        state.Theme = nextTheme
        updateAllTheme()
        local dark = nextTheme == "Dark"
        themeLabel.Text = dark and "NIGHT" or "DAY"
        themeLabel.TextXAlignment = dark and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
        themeIcon.Text = dark and "☾" or "☀"
        themeIcon.TextColor3 = dark and Color3.fromRGB(76, 55, 119) or Color3.fromRGB(214, 135, 36)
        themeTrack.BackgroundColor3 = dark and Color3.fromRGB(42, 35, 77) or Color3.fromRGB(93, 177, 219)
        local targetPosition = dark and UDim2.new(1, -30, 0, 4) or UDim2.new(0, 4, 0, 4)
        TweenService:Create(themeKnob, TweenInfo.new(state.ReducedMotion and 0 or 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = targetPosition,
            Rotation = dark and -12 or 8,
        }):Play()
        notify(dark and "Dark theme activated" or "Light theme activated", "success")
    end)
    sliderCard(root)
    toggleCard(root, "Preferences", "Changes are local to this interface.", {"Ambient", "Glow", "Notifications", "ReducedMotion", "CompactSidebar"})
    buttonRow(root, "Test notifications", "Check the toast animation.", "TEST", function() notify("Notification system operational", "success") end)
    buttonRow(root, "Reset preferences", "Restore CienHub default appearance.", "RESET", function()
        state.Theme = "Dark"; state.Preset = 1; state.Scale = 1; state.Ambient = true; state.Glow = true; state.Notifications = true; state.ReducedMotion = false; state.CompactSidebar = false; state.SelectedWaypoint = nil
        updatePanelSize(); updateAllTheme(); renderPage("Settings"); notify("Preferences reset", "success")
    end)
    infoCard(root, "Version 2.0.0", "Roblox-native UI shell · responsive input · no external requests", 58)
end

renderPage = function(name)
    if not pageMeta[name] then name = "Overview" end
    currentPage = name
    pageTitle.Text = pageMeta[name][1]
    pageSubtitle.Text = pageMeta[name][2]
    for pageName, nav in pairs(navButtons) do
        local active = pageName == name
        nav.BackgroundTransparency = active and 0.02 or 0.55
        nav.BackgroundColor3 = active and palette().Accent or palette().Surface2
        nav.TextColor3 = active and Color3.new(1, 1, 1) or palette().Muted
        local bar = nav:FindFirstChild("ActiveBar")
        if bar then bar.Visible = active end
    end
    clearPage()
    local root = pageRoot()
    if name == "Overview" then pageOverview(root)
    elseif name == "Player" then pagePlayer(root)
    elseif name == "Waypoints" then pageWaypoints(root)
    elseif name == "World Tools" then pageWorld(root)
    elseif name == "Visual Profiles" then pageVisuals(root)
    elseif name == "Settings" then pageSettings(root) end
    updateAllTheme()
    if not state.ReducedMotion then
        pageBody.CanvasPosition = Vector2.new(0, 0)
    end
end

navItems = {
    {Name = "Overview", Icon = "⌂"},
    {Name = "Player", Icon = "♙"},
    {Name = "Waypoints", Icon = "⌖"},
    {Name = "World Tools", Icon = "▦"},
    {Name = "Visual Profiles", Icon = "◉"},
    {Name = "Settings", Icon = "⚙"},
}

for index, item in ipairs(navItems) do
    local b = makeButton(navFrame, "   " .. item.Icon .. "     " .. item.Name, {
        Name = "Nav_" .. item.Name:gsub("%W", ""),
        Size = UDim2.new(1, 0, 0, 37),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 10,
        LayoutOrder = index,
    })
    b.BackgroundTransparency = item.Name == "Overview" and 0.02 or 0.55
    local bar = new("Frame", {Name = "ActiveBar", Position = UDim2.new(0, 0, 0, 7), Size = UDim2.new(0, 3, 1, -14), BackgroundColor3 = palette().Accent, BorderSizePixel = 0, Visible = item.Name == "Overview"}, b)
    corner(bar, 3); bar:SetAttribute("CHAccentElement", true)
    navButtons[item.Name] = b
    b.Activated:Connect(function() renderPage(item.Name) end)
end

-- The minimised floating C orb can be restored and dragged on touch or desktop.
local bubble = new("TextButton", {
    Name = "CienHubFloatingBubble",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -20, 0.58, 0),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = palette().Accent,
    Text = "C",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 35,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    Visible = false,
    BorderSizePixel = 0,
    Rotation = -5,
    ZIndex = 30,
}, gui)
corner(bubble, 19)
bubble:SetAttribute("CHAccentElement", true)
addStroke(bubble, "Accent", 1.7, 0.02)
addGradient(bubble, "AccentGradient", 35)
local bubbleSlash = new("Frame", {
    Name = "LogoSlash",
    Position = UDim2.new(0.62, 0, 0.18, 0),
    Size = UDim2.fromOffset(3, 26),
    Rotation = 35,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    ZIndex = 31,
}, bubble)
corner(bubbleSlash, 2)
local bubbleShadow = new("Frame", {
    Name = "BubbleDepth",
    AnchorPoint = bubble.AnchorPoint,
    Position = bubble.Position + UDim2.fromOffset(0, 5),
    Size = bubble.Size,
    BackgroundColor3 = Color3.fromRGB(44, 17, 77),
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 29,
}, gui)
corner(bubbleShadow, 19)

local bubbleDragging, bubbleDragStart, bubbleStartPos, bubbleDragInput = false, nil, nil, nil
bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bubbleDragging = true
        bubbleDragStart = input.Position
        bubbleStartPos = bubble.Position
        bubbleDragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then bubbleDragging = false; bubbleDragInput = nil end
        end)
    end
end)

updatePanelSize = function()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local maxW = math.max(288, viewport.X - 20)
    local maxH = math.max(290, viewport.Y - 30)
    local baseW = math.min(660, maxW)
    local baseH = math.min(464, maxH)
    local w = math.floor(baseW * state.Scale)
    local h = math.floor(baseH * state.Scale)
    w = math.min(w, maxW); h = math.min(h, maxH)
    panel.Size = UDim2.fromOffset(w, h)
    shadow.Size = UDim2.fromOffset(w, h)
    local compact = viewport.X < 590 or w < 500 or state.CompactSidebar
    local sideW = compact and 75 or 158
    sidebar.Size = UDim2.new(0, sideW, 1, -92)
    content.Position = UDim2.new(0, compact and 89 or 182, 0, 81)
    content.Size = UDim2.new(1, -(compact and 101 or 194), 1, -93)
    for pageName, nav in pairs(navButtons) do
        local itemIcon = ""
        for _, entry in ipairs(navItems) do if entry.Name == pageName then itemIcon = entry.Icon end end
        nav.Text = compact and (" " .. itemIcon) or ("   " .. itemIcon .. "     " .. pageName)
        nav.TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        nav.TextSize = compact and 17 or 10
    end
    profileName.Visible = not compact
    profileStatus.Visible = not compact
    avatarFrame.Size = compact and UDim2.new(1, -12, 0, 48) or UDim2.new(1, -18, 0, 62)
    avatar.Position = compact and UDim2.new(0.5, -18, 0.5, -18) or UDim2.new(0, 8, 0.5, -18)
    makeWorkspaceLabelCompact(compact)
    if viewport.X < 380 then
        brandTitle.Visible = false
        brandSubtitle.Visible = false
        statusDot.Visible = false
        statusText.Visible = false
        logoTile.Position = UDim2.new(0, 10, 0, 12)
    else
        brandTitle.Visible = true
        brandSubtitle.Visible = true
        statusDot.Visible = true
        statusText.Visible = true
        logoTile.Position = UDim2.new(0, 15, 0, 12)
    end
    shadow.Position = panel.Position + UDim2.fromOffset(0, 7)
    bubbleShadow.Position = bubble.Position + UDim2.fromOffset(0, 5)
end

makeWorkspaceLabelCompact = function(compact)
    local label = sidebar:FindFirstChild("WorkspaceLabel")
    if label then label.Visible = not compact end
    if sideFooter then sideFooter.Text = compact and "●" or "●  INTERFACE ONLINE" end
    local navY = compact and 70 or 104
    navFrame.Position = UDim2.new(0, 7, 0, navY)
    navFrame.Size = UDim2.new(1, -14, 1, -(navY + 39))
end

local function hidePanel()
    if state.ReducedMotion then
        panel.Visible = false; shadow.Visible = false; bubble.Visible = true; bubbleShadow.Visible = true
    else
        local target = panel.Size - UDim2.fromOffset(30, 30)
        local tween = TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = target, BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function()
            panel.Visible = false; shadow.Visible = false; panel.BackgroundTransparency = 0
            bubble.Visible = true; bubbleShadow.Visible = true
            bubble.Size = UDim2.fromOffset(20, 20); bubble.TextTransparency = 1
            TweenService:Create(bubble, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(58, 58), TextTransparency = 0}):Play()
        end)
    end
    notify("CienHub minimized · tap C to restore", "success")
end

local function showPanel()
    bubble.Visible = false; bubbleShadow.Visible = false
    panel.Visible = true; shadow.Visible = true
    updatePanelSize()
    if not state.ReducedMotion then
        panel.Size = panel.Size - UDim2.fromOffset(22, 22)
        panel.BackgroundTransparency = 1
        TweenService:Create(panel, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(math.min(panel.AbsoluteSize.X + 22, panel.Size.X.Offset + 22), math.min(panel.AbsoluteSize.Y + 22, panel.Size.Y.Offset + 22)),
            BackgroundTransparency = 0,
        }):Play()
        task.delay(0.26, updatePanelSize)
    end
end

closeButton.Activated:Connect(hidePanel)
bubble.Activated:Connect(function()
    if bubbleDragging then return end
    showPanel()
end)

-- Header dragging works with mouse and touch. The dedicated buttons retain their own click actions.
local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local localX = input.Position.X - header.AbsolutePosition.X
        if localX > header.AbsoluteSize.X - 47 then return end
        dragging = true; dragStart = input.Position; startPosition = panel.Position; dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if activeSliderUpdater and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        activeSliderUpdater(input.Position.X)
    end
    if dragging and dragStart and startPosition and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        shadow.Position = panel.Position + UDim2.fromOffset(0, 7)
    end
    if bubbleDragging and bubbleDragStart and bubbleStartPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - bubbleDragStart
        bubble.Position = UDim2.new(bubbleStartPos.X.Scale, bubbleStartPos.X.Offset + delta.X, bubbleStartPos.Y.Scale, bubbleStartPos.Y.Offset + delta.Y)
        bubbleShadow.Position = bubble.Position + UDim2.fromOffset(0, 5)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSliderUpdater = nil
    end
end)

local viewportConnection
local function attachCamera()
    if viewportConnection then viewportConnection:Disconnect(); viewportConnection = nil end
    local camera = workspace.CurrentCamera
    if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePanelSize) end
    updatePanelSize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(attachCamera)
attachCamera()

-- Animate background gradient subtly. Reduced-motion and Ambient switches halt the loop.
task.spawn(function()
    while gui.Parent do
        if state.Ambient and not state.ReducedMotion then
            panelGradient.Rotation = (panelGradient.Rotation + 0.35) % 360
            headerGradient.Rotation = (headerGradient.Rotation + 0.45) % 360
            RunService.Heartbeat:Wait()
        else
            task.wait(0.15)
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        if bubble.Visible and not state.ReducedMotion then
            local a = TweenService:Create(bubble, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = 5, Size = UDim2.fromOffset(61, 61)})
            a:Play(); a.Completed:Wait()
            if bubble.Parent and bubble.Visible then
                local b = TweenService:Create(bubble, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = -5, Size = UDim2.fromOffset(58, 58)})
                b:Play(); b.Completed:Wait()
            end
        else
            task.wait(0.2)
        end
    end
end)

renderPage("Overview")
updateAllTheme()
notify("CienHub UI shell initialized", "success")
print("[CienHub] v2.0.0 initialized for " .. LocalPlayer.Name)
