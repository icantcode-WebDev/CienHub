--[[
    CienHub - Standalone Mobile Lua UI Shell
    UI-only implementation for environments exposing Roblox-style Instance APIs.
    No game cheats, anti-cheat bypasses, remote abuse, or unauthorized game modifications.

    Usage:
      1. Run this script in a compatible Lua environment.
      2. Use the floating CienHub button to reopen the panel.
      3. Feature pages are UI placeholders until connected to an authorized game API.

    Note: Executor environments differ. This script checks a few optional capabilities,
    but does not attempt to bypass environment restrictions.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[CienHub] LocalPlayer is unavailable in this environment.")
    return
end

local function safeGetParent()
    local ok, parent = pcall(function()
        return CoreGui
    end)
    if ok and parent then return parent end

    local ok2, playerGui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui")
    end)
    if ok2 then return playerGui end
    return nil
end

local Parent = safeGetParent()
if not Parent then
    warn("[CienHub] Could not find a supported UI parent.")
    return
end

pcall(function()
    local old = Parent:FindFirstChild("CienHubUI")
    if old then old:Destroy() end
end)

local Theme = {
    Background = Color3.fromRGB(17, 13, 28),
    Panel = Color3.fromRGB(29, 21, 45),
    Panel2 = Color3.fromRGB(40, 29, 62),
    Purple = Color3.fromRGB(155, 96, 255),
    PurpleLight = Color3.fromRGB(196, 157, 255),
    Text = Color3.fromRGB(246, 240, 255),
    Muted = Color3.fromRGB(174, 160, 197),
    Border = Color3.fromRGB(112, 76, 160),
    Green = Color3.fromRGB(112, 225, 170),
    Red = Color3.fromRGB(255, 129, 150),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        pcall(function() obj[key] = value end)
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function label(parent, text, size, color, font, xAlignment)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = xAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function button(parent, text, height)
    local b = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel2,
        BackgroundTransparency = 0.12,
        Size = UDim2.new(1, 0, 0, height or 40),
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
    }, parent)
    corner(b, 10)
    stroke(b, Theme.Border, 0.48, 1)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(61, 41, 91)
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = Theme.Panel2
        }):Play()
    end)
    return b
end

local ScreenGui = make("ScreenGui", {
    Name = "CienHubUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
}, Parent)

local floatingButton = make("TextButton", {
    Name = "CienHubReopen",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -16, 0.58, 0),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = Theme.Purple,
    BackgroundTransparency = 0.08,
    Text = "C",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 25,
    Font = Enum.Font.GothamBold,
    Visible = false,
    ZIndex = 30,
}, ScreenGui)
corner(floatingButton, 18)
stroke(floatingButton, Theme.PurpleLight, 0.12, 1.5)

local panel = make("Frame", {
    Name = "MainPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.fromOffset(640, 430),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = 0.08,
    ClipsDescendants = true,
}, ScreenGui)
corner(panel, 18)
stroke(panel, Theme.Border, 0.18, 1.2)

local panelGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 22, 51)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 13, 27)),
    }),
    Rotation = 28,
}, panel)

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = 0.08,
}, panel)
corner(header, 18)
local headerMask = make("Frame", {
    Position = UDim2.new(0, 0, 1, -18),
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, header)

local accent = make("Frame", {
    Position = UDim2.new(0, 16, 0, 17),
    Size = UDim2.fromOffset(4, 32),
    BackgroundColor3 = Theme.Purple,
    BorderSizePixel = 0,
}, header)
corner(accent, 3)

local title = label(header, "CienHub", 22, Theme.Text, Enum.Font.GothamBold)
title.Position = UDim2.new(0, 30, 0, 9)
title.Size = UDim2.new(0, 200, 0, 28)

local subtitle = label(header, "MOBILE CONTROL CENTER  •  UI SHELL", 9, Theme.Muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.new(0, 31, 0, 37)
subtitle.Size = UDim2.new(0, 300, 0, 16)

local statusDot = make("Frame", {
    Position = UDim2.new(1, -104, 0, 27),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = Theme.Green,
    BorderSizePixel = 0,
}, header)
corner(statusDot, 5)
local statusLabel = label(header, "UI READY", 10, Theme.Green, Enum.Font.GothamMedium)
statusLabel.Position = UDim2.new(1, -91, 0, 20)
statusLabel.Size = UDim2.new(0, 64, 0, 20)

local closeButton = make("TextButton", {
    Position = UDim2.new(1, -39, 0, 17),
    Size = UDim2.fromOffset(25, 28),
    BackgroundColor3 = Theme.Panel2,
    Text = "×",
    TextColor3 = Theme.Text,
    TextSize = 22,
    Font = Enum.Font.Gotham,
    AutoButtonColor = false,
}, header)
corner(closeButton, 8)

local sidebar = make("Frame", {
    Position = UDim2.new(0, 12, 0, 78),
    Size = UDim2.new(0, 158, 1, -91),
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = 0.28,
}, panel)
corner(sidebar, 12)
padding(sidebar, 8, 8, 9, 8)

local sideList = make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local content = make("Frame", {
    Position = UDim2.new(0, 182, 0, 78),
    Size = UDim2.new(1, -194, 1, -91),
    BackgroundTransparency = 1,
}, panel)

local pageTitle = label(content, "Dashboard", 19, Theme.Text, Enum.Font.GothamBold)
pageTitle.Size = UDim2.new(1, -4, 0, 30)

local pageSubtitle = label(content, "Your tools, organized in one place.", 11, Theme.Muted)
pageSubtitle.Position = UDim2.new(0, 0, 0, 30)
pageSubtitle.Size = UDim2.new(1, -4, 0, 24)

local pageBody = make("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 60),
    Size = UDim2.new(1, 0, 1, -60),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Purple,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)
padding(pageBody, 1, 5, 2, 8)
local bodyLayout = make("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, pageBody)

local notificationHolder = make("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 16),
    Size = UDim2.new(0, 270, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 50,
}, ScreenGui)
make("UIListLayout", {
    Padding = UDim.new(0, 8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, notificationHolder)

local function notify(message, kind)
    local color = Theme.Purple
    if kind == "success" then color = Theme.Green end
    if kind == "warning" then color = Color3.fromRGB(255, 190, 96) end
    if kind == "error" then color = Theme.Red end

    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.04,
        ZIndex = 51,
    }, notificationHolder)
    corner(card, 12)
    stroke(card, color, 0.18, 1.2)

    local bar = make("Frame", {
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        ZIndex = 52,
    }, card)
    corner(bar, 3)

    local textLabel = label(card, tostring(message), 12, Theme.Text, Enum.Font.GothamMedium)
    textLabel.Position = UDim2.new(0, 22, 0, 6)
    textLabel.Size = UDim2.new(1, -30, 1, -12)
    textLabel.ZIndex = 52

    card.BackgroundTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 0.04}):Play()

    task.delay(3.2, function()
        if card and card.Parent then
            local tween = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            tween:Play()
            tween.Completed:Wait()
            if card then card:Destroy() end
        end
    end)
end

local function clearBody()
    for _, child in ipairs(pageBody:GetChildren()) do
        if child:IsA("GuiObject") and child ~= bodyLayout then
            child:Destroy()
        end
    end
end

local function sectionCard(titleText, descriptionText)
    local card = make("Frame", {
        Size = UDim2.new(1, -3, 0, 82),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.12,
    }, pageBody)
    corner(card, 12)
    stroke(card, Theme.Border, 0.6, 1)
    padding(card, 12, 12, 8, 8)

    local h = label(card, titleText, 13, Theme.Text, Enum.Font.GothamBold)
    h.Size = UDim2.new(1, 0, 0, 23)

    local d = label(card, descriptionText, 11, Theme.Muted, Enum.Font.Gotham)
    d.Position = UDim2.new(0, 0, 0, 25)
    d.Size = UDim2.new(1, 0, 0, 38)
    d.TextYAlignment = Enum.TextYAlignment.Top
    return card
end

local function actionCard(titleText, descriptionText, buttonText, callback)
    local card = make("Frame", {
        Size = UDim2.new(1, -3, 0, 106),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.1,
    }, pageBody)
    corner(card, 12)
    stroke(card, Theme.Border, 0.6, 1)
    padding(card, 12, 12, 7, 8)

    local h = label(card, titleText, 13, Theme.Text, Enum.Font.GothamBold)
    h.Size = UDim2.new(1, 0, 0, 22)
    local d = label(card, descriptionText, 10, Theme.Muted)
    d.Position = UDim2.new(0, 0, 0, 23)
    d.Size = UDim2.new(1, 0, 0, 29)
    d.TextYAlignment = Enum.TextYAlignment.Top

    local b = button(card, buttonText or "Open module", 30)
    b.Position = UDim2.new(0, 0, 1, -36)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.MouseButton1Click:Connect(callback or function()
        notify("This module is a UI placeholder.", "warning")
    end)
    return card
end

local function capabilityRows()
    local checks = {
        {"Roblox-style UI API", function() return typeof(Instance) == "table" or Instance ~= nil end},
        {"LocalPlayer", function() return LocalPlayer ~= nil end},
        {"Touch input API", function() return UserInputService.TouchEnabled end},
        {"CoreGui access", function() return Parent == CoreGui end},
        {"Executor-specific APIs", function()
            return type(getgenv) == "function" or type(gethui) == "function" or type(identifyexecutor) == "function"
        end},
    }
    for _, item in ipairs(checks) do
        local ok, result = pcall(item[2])
        local state = (ok and result) and "Detected" or "Unavailable"
        local kind = (ok and result) and "success" or "warning"
        sectionCard(item[1] .. "  ·  " .. state, "Compatibility probe only. No exploit or bypass is attempted.")
    end
end

local pages = {
    ["Home"] = {title = "Dashboard", subtitle = "CienHub interface status"},
    ["Player"] = {title = "Player Panel", subtitle = "Display-only controls; no unauthorized changes"},
    ["Teleport"] = {title = "Teleport Panel", subtitle = "Navigation UI for authorized experiences"},
    ["World Tools"] = {title = "World Tools", subtitle = "World inspection module placeholders"},
    ["Visuals"] = {title = "Visuals Panel", subtitle = "Visual settings interface; no ESP or tracking cheat"},
    ["Settings"] = {title = "Settings", subtitle = "Interface preferences and compatibility"},
}

local function renderPage(name)
    local data = pages[name] or pages.Home
    pageTitle.Text = data.title
    pageSubtitle.Text = data.subtitle
    clearBody()

    if name == "Home" then
        sectionCard("Welcome to CienHub", "A mobile-first floating interface with a purple glass theme. Feature pages are intentionally UI-only.")
        actionCard("Quick start", "Use the navigation on the left to open a module.", "Show notification", function()
            notify("CienHub is running. UI shell ready.", "success")
        end)
        actionCard("Compatibility", "Inspect available UI and input APIs.", "Run checks", function()
            renderPage("Settings")
            notify("Compatibility checks displayed.", "success")
        end)
    elseif name == "Player" then
        actionCard("Player options", "Reserved for controls supported by the current experience and explicitly authorized by its developer.", "View status", function()
            notify("No player modification handler is connected.", "warning")
        end)
        sectionCard("Movement", "Speed, jump, flight, and similar gameplay changes are not implemented in this standalone shell.")
        sectionCard("Character", "Character actions require a legitimate in-experience API and server-side authorization.")
    elseif name == "Teleport" then
        actionCard("Saved destinations", "Destination list UI placeholder. This shell does not teleport your character in arbitrary games.", "Manage destinations", function()
            notify("Destination manager is a placeholder.", "warning")
        end)
        sectionCard("Authorized navigation", "Connect this module only to documented teleport features in an experience you own or have permission to test.")
    elseif name == "World Tools" then
        actionCard("World inspection", "A placeholder for permitted world metadata and developer diagnostics.", "Inspect status", function()
            notify("No world-inspection adapter is connected.", "warning")
        end)
        sectionCard("World actions", "No remote firing, destructive actions, or server-side manipulation is included.")
    elseif name == "Visuals" then
        actionCard("Visual preferences", "UI theme and display options can be added here.", "Toggle demo notice", function()
            notify("Visual module is UI-only; no ESP or player tracking is active.", "warning")
        end)
        sectionCard("Overlay compatibility", "No wallhack, ESP, or hidden-object reveal behavior is implemented.")
    elseif name == "Settings" then
        capabilityRows()
        actionCard("Interface", "The panel can be hidden and reopened using the floating C button.", "Test notification", function()
            notify("Notification system works.", "success")
        end)
        actionCard("About", "CienHub standalone UI shell. Executor-specific APIs are optional and never required for the interface.", "Show version", function()
            notify("CienHub UI Shell · 1.0", "success")
        end)
    end
end

local navButtons = {}
local navNames = {"Home", "Player", "Teleport", "World Tools", "Visuals", "Settings"}
local currentPage = "Home"

local function setActive(name)
    currentPage = name
    for pageName, navButton in pairs(navButtons) do
        local active = pageName == name
        navButton.BackgroundColor3 = active and Color3.fromRGB(84, 53, 128) or Theme.Panel2
        navButton.TextColor3 = active and Theme.Text or Theme.Muted
    end
    renderPage(name)
end

for index, name in ipairs(navNames) do
    local nav = make("TextButton", {
        Name = name:gsub("%s+", "") .. "Nav",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = name == "Home" and Color3.fromRGB(84, 53, 128) or Theme.Panel2,
        BackgroundTransparency = 0.08,
        AutoButtonColor = false,
        Text = "   " .. name,
        TextColor3 = name == "Home" and Theme.Text or Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = index,
    }, sidebar)
    corner(nav, 9)
    navButtons[name] = nav
    nav.MouseButton1Click:Connect(function()
        setActive(name)
    end)
end

local sidebarFooter = label(sidebar, "CIENHUB  •  UI SHELL", 8, Theme.Muted, Enum.Font.GothamMedium)
sidebarFooter.Size = UDim2.new(1, 0, 0, 22)
sidebarFooter.LayoutOrder = 100
sidebarFooter.LayoutOrder = 100

closeButton.MouseButton1Click:Connect(function()
    panel.Visible = false
    floatingButton.Visible = true
    notify("CienHub minimized. Tap C to reopen.", "success")
end)

floatingButton.MouseButton1Click:Connect(function()
    panel.Visible = true
    floatingButton.Visible = false
end)

-- Dragging: header is the drag handle. Supports mouse and touch input.
local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart and startPosition then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end
end)

-- Keep the panel usable on narrow mobile screens.
local function resizeForViewport()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = math.min(640, math.max(300, viewport.X - 24))
    local height = math.min(430, math.max(300, viewport.Y - 40))
    panel.Size = UDim2.fromOffset(width, height)

    local compact = width < 470
    sidebar.Size = UDim2.new(0, compact and 112 or 158, 1, -91)
    content.Position = UDim2.new(0, compact and 132 or 182, 0, 78)
    content.Size = UDim2.new(1, -(compact and 144 or 194), 1, -91)
    if compact then
        subtitle.Text = "MOBILE UI SHELL"
    else
        subtitle.Text = "MOBILE CONTROL CENTER  •  UI SHELL"
    end
end

resizeForViewport()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeForViewport)
end

setActive("Home")
notify("CienHub loaded. UI shell ready.", "success")

print("[CienHub] UI shell loaded. No unauthorized gameplay actions are implemented.")
