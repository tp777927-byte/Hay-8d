-- ╔══════════════════════════════════════════╗
-- ║           MaruLib v1.0                   ║
-- ║   Beautiful GUI Library for Roblox       ║
-- ║   Supports PC & Mobile                   ║
-- ╚══════════════════════════════════════════╝

local MaruLib = {}
MaruLib.__index = MaruLib

-- ════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════
local Theme = {
    Background     = Color3.fromRGB(13, 13, 18),
    Surface        = Color3.fromRGB(20, 20, 28),
    SurfaceHover   = Color3.fromRGB(28, 28, 40),
    Border         = Color3.fromRGB(45, 45, 65),
    Accent         = Color3.fromRGB(120, 90, 255),
    AccentGlow     = Color3.fromRGB(90, 60, 220),
    AccentDim      = Color3.fromRGB(60, 45, 130),
    TextPrimary    = Color3.fromRGB(240, 240, 255),
    TextSecondary  = Color3.fromRGB(140, 140, 170),
    TextDisabled   = Color3.fromRGB(70, 70, 90),
    Toggle_On      = Color3.fromRGB(100, 210, 140),
    Toggle_Off     = Color3.fromRGB(55, 55, 75),
    Slider_Track   = Color3.fromRGB(35, 35, 50),
    Slider_Fill    = Color3.fromRGB(120, 90, 255),
    TabActive      = Color3.fromRGB(120, 90, 255),
    TabInactive    = Color3.fromRGB(25, 25, 36),
    Notification   = Color3.fromRGB(18, 18, 26),
}

-- ════════════════════════════════════════════
--  UTILITIES
-- ════════════════════════════════════════════
local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function MakeCorner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function MakeStroke(color, thickness, parent)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- MakeGradient: pass two Color3 values OR a pre-built ColorSequence as c0 (c1 ignored)
local function MakeGradient(rot, c0, c1, parent)
    local g = Instance.new("UIGradient")
    g.Rotation = rot or 90
    if typeof(c0) == "ColorSequence" then
        g.Color = c0
    else
        g.Color = ColorSequence.new(c0, c1 or c0)
    end
    g.Parent = parent
    return g
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- ════════════════════════════════════════════
--  DRAGGING (PC & Mobile)
-- ════════════════════════════════════════════
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, mousePos, framePos

    local function update(input)
        local delta = input.Position - mousePos
        local newPos = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
        frame.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ════════════════════════════════════════════
local NotifHolder

local function InitNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end

    -- สร้าง ScreenGui แยกสำหรับ notification เพื่อป้องกัน memory leak
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MaruNotifGui"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 200
    notifGui.IgnoreGuiInset = true
    local ok = pcall(function() notifGui.Parent = game:GetService("CoreGui") end)
    if not ok then notifGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui end

    NotifHolder = Instance.new("Frame")
    NotifHolder.Name = "MaruNotifs"
    NotifHolder.Size = UDim2.new(0, 280, 1, 0)
    NotifHolder.Position = UDim2.new(1, -290, 0, 0)
    NotifHolder.BackgroundTransparency = 1
    NotifHolder.ZIndex = 200

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 8)
    layout.Parent = NotifHolder

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 0)
    padding.Parent = NotifHolder

    NotifHolder.Parent = notifGui
end

function MaruLib:Notify(title, desc, duration)
    InitNotifHolder()
    duration = duration or 4

    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Size = UDim2.new(1, 0, 0, 70)
    notif.BackgroundColor3 = Theme.Notification
    notif.BackgroundTransparency = 0
    notif.ClipsDescendants = true
    MakeCorner(10, notif)
    MakeStroke(Theme.Accent, 1, notif)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    MakeCorner(2, accent)
    accent.Parent = notif

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.new(0, 14, 0, 10)
    titleLbl.Size = UDim2.new(1, -18, 0, 20)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title or "MaruLib"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notif

    local descLbl = Instance.new("TextLabel")
    descLbl.Position = UDim2.new(0, 14, 0, 32)
    descLbl.Size = UDim2.new(1, -18, 0, 30)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc or ""
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextColor3 = Theme.TextSecondary
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextWrapped = true
    descLbl.Parent = notif

    -- Progress bar
    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(1, 0, 0, 2)
    prog.Position = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = Theme.Accent
    prog.BorderSizePixel = 0
    prog.Parent = notif

    notif.Parent = NotifHolder
    notif.Position = UDim2.new(1, 10, 0, 0)
    Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
    Tween(prog, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(1, 10, 0, 0)}, 0.3)
        task.wait(0.35)
        notif:Destroy()
    end)
end

-- ════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════
function MaruLib:CreateWindow(options)
    options = options or {}
    local title    = options.Title    or "MaruLib"
    local subtitle = options.Subtitle or "Script Hub"
    local size     = options.Size     or UDim2.new(0, 560, 0, 400)

    -- Adjust for mobile
    if IsMobile() then
        size = options.MobileSize or UDim2.new(0.92, 0, 0, 420)
    end

    -- ── ScreenGui ──────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MaruLib_" .. title
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 100
    ScreenGui.IgnoreGuiInset = true

    local ok = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok then ScreenGui.Parent = LocalPlayer.PlayerGui end

    -- ── Blur / Overlay ─────────────────────────
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.55
    overlay.ZIndex = 1
    overlay.Parent = ScreenGui

    -- ── Main Frame ─────────────────────────────
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = size
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Theme.Background
    Main.ClipsDescendants = true
    Main.ZIndex = 2
    MakeCorner(14, Main)
    MakeStroke(Theme.Border, 1.5, Main)
    Main.Parent = ScreenGui

    -- Subtle gradient on background
    MakeGradient(135,
        Color3.fromRGB(18, 15, 30),
        Color3.fromRGB(10, 10, 18),
        Main)

    -- Intro animation
    Main.Size = UDim2.new(0, 0, 0, 0)
    Tween(Main, {Size = size}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    MakeDraggable(Main)

    -- ── Top Bar ────────────────────────────────
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundColor3 = Theme.Surface
    TopBar.ZIndex = 3
    TopBar.Parent = Main

    local topGrad = Instance.new("UIGradient")
    topGrad.Rotation = 90
    topGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 25, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30)),
    })
    topGrad.Parent = TopBar

    -- Logo dot
    local logoDot = Instance.new("Frame")
    logoDot.Size = UDim2.new(0, 8, 0, 8)
    logoDot.Position = UDim2.new(0, 16, 0.5, -4)
    logoDot.BackgroundColor3 = Theme.Accent
    MakeCorner(4, logoDot)
    logoDot.ZIndex = 4
    logoDot.Parent = TopBar

    -- Pulse on logo (loop ปลอดภัย ไม่ stack overflow)
    local pulseAlive = true
    task.spawn(function()
        while pulseAlive and logoDot and logoDot.Parent do
            Tween(logoDot, {BackgroundColor3 = Color3.fromRGB(160, 130, 255)}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
            if not (pulseAlive and logoDot and logoDot.Parent) then break end
            Tween(logoDot, {BackgroundColor3 = Theme.Accent}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
        end
    end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Position = UDim2.new(0, 32, 0, 7)
    TitleLabel.Size = UDim2.new(0.5, 0, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextColor3 = Theme.TextPrimary
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 4
    TitleLabel.Parent = TopBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Position = UDim2.new(0, 32, 0, 26)
    SubLabel.Size = UDim2.new(0.5, 0, 0, 16)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = subtitle
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 10
    SubLabel.TextColor3 = Theme.Accent
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.ZIndex = 4
    SubLabel.Parent = TopBar

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.BackgroundTransparency = 0.4
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.ZIndex = 5
    MakeCorner(7, CloseBtn)
    CloseBtn.Parent = TopBar

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundTransparency = 0}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundTransparency = 0.4}, 0.15)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        pulseAlive = false
        Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.spawn(function()
            task.wait(0.32)
            ScreenGui:Destroy()
        end)
    end)

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
    MinBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
    MinBtn.BackgroundTransparency = 0.4
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 12
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.ZIndex = 5
    MakeCorner(7, MinBtn)
    MinBtn.Parent = TopBar

    local minimized = false
    local normalSize = size

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(Main, {Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 48)}, 0.3, Enum.EasingStyle.Quart)
        else
            Tween(Main, {Size = normalSize}, 0.3, Enum.EasingStyle.Quart)
        end
    end)

    -- ── Tab Bar ────────────────────────────────
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 36)
    TabBar.Position = UDim2.new(0, 0, 0, 48)
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.ZIndex = 3
    TabBar.Parent = Main

    local tabBarStroke = Instance.new("Frame")
    tabBarStroke.Size = UDim2.new(1, 0, 0, 1)
    tabBarStroke.Position = UDim2.new(0, 0, 1, -1)
    tabBarStroke.BackgroundColor3 = Theme.Border
    tabBarStroke.BorderSizePixel = 0
    tabBarStroke.ZIndex = 4
    tabBarStroke.Parent = TabBar

    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 4)
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Parent = TabBar

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 8)
    TabPadding.PaddingTop = UDim.new(0, 6)
    TabPadding.PaddingBottom = UDim.new(0, 6)
    TabPadding.Parent = TabBar

    -- ── Content Area ───────────────────────────
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, 0, 1, -84)
    ContentArea.Position = UDim2.new(0, 0, 0, 84)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = 2
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = Main

    -- ── Window Object ──────────────────────────
    local Window = {}
    local tabs = {}
    local activeTab = nil

    function Window:SetActiveTab(tab)
        if activeTab == tab then return end
        if activeTab then
            Tween(activeTab.Button, {BackgroundColor3 = Theme.TabInactive, BackgroundTransparency = 1}, 0.15)
            local prevLbl = activeTab.Button:FindFirstChild("TextLabel")
            if prevLbl then prevLbl.TextColor3 = Theme.TextSecondary end
            activeTab.Content.Visible = false
        end
        activeTab = tab
        Tween(tab.Button, {BackgroundColor3 = Theme.TabActive, BackgroundTransparency = 0}, 0.15)
        local curLbl = tab.Button:FindFirstChild("TextLabel")
        if curLbl then curLbl.TextColor3 = Theme.TextPrimary end
        tab.Content.Visible = true
    end

    -- ── Add Tab ────────────────────────────────
    function Window:AddTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = name .. "Tab"
        tabBtn.Size = UDim2.new(0, 0, 1, 0)
        tabBtn.AutomaticSize = Enum.AutomaticSize.X
        tabBtn.BackgroundColor3 = Theme.TabInactive
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.ZIndex = 4
        MakeCorner(6, tabBtn)

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft = UDim.new(0, 10)
        btnPad.PaddingRight = UDim.new(0, 10)
        btnPad.Parent = tabBtn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "TextLabel"
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Text = (icon and icon .. " " or "") .. name
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.TextSecondary
        lbl.ZIndex = 5
        lbl.Parent = tabBtn

        tabBtn.Parent = TabBar

        -- Content scroll frame
        local content = Instance.new("ScrollingFrame")
        content.Name = name .. "Content"
        content.Size = UDim2.new(1, 0, 1, 0)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 3
        content.ScrollBarImageColor3 = Theme.Accent
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.Visible = false
        content.ZIndex = 3
        content.BorderSizePixel = 0
        content.Parent = ContentArea

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.Parent = content

        local contentPad = Instance.new("UIPadding")
        contentPad.PaddingLeft = UDim.new(0, 12)
        contentPad.PaddingRight = UDim.new(0, 12)
        contentPad.PaddingTop = UDim.new(0, 10)
        contentPad.PaddingBottom = UDim.new(0, 10)
        contentPad.Parent = content

        local tabObj = {Button = tabBtn, Content = content}
        table.insert(tabs, tabObj)

        tabBtn.MouseButton1Click:Connect(function()
            Window:SetActiveTab(tabObj)
        end)

        if #tabs == 1 then
            Window:SetActiveTab(tabObj)
        end

        -- ── Tab Components ──────────────────────
        local Tab = {}

        -- SECTION LABEL
        function Tab:AddSection(text)
            local section = Instance.new("Frame")
            section.Size = UDim2.new(1, 0, 0, 26)
            section.BackgroundTransparency = 1
            section.Parent = content

            local line = Instance.new("Frame")
            line.Size = UDim2.new(0.5, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = Theme.Border
            line.BorderSizePixel = 0
            line.Parent = section

            local lbl2 = Instance.new("TextLabel")
            lbl2.Size = UDim2.new(1, 0, 1, 0)
            lbl2.BackgroundTransparency = 1
            lbl2.Text = text
            lbl2.Font = Enum.Font.GothamBold
            lbl2.TextSize = 10
            lbl2.TextColor3 = Theme.Accent
            lbl2.TextXAlignment = Enum.TextXAlignment.Left
            lbl2.Parent = section
        end

        -- BUTTON
        function Tab:AddButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 38)
            btn.BackgroundColor3 = Theme.Surface
            btn.Text = ""
            btn.ZIndex = 4
            MakeCorner(8, btn)
            MakeStroke(Theme.Border, 1, btn)
            btn.Parent = content

            local btnLabel = Instance.new("TextLabel")
            btnLabel.Size = UDim2.new(1, -16, 1, 0)
            btnLabel.Position = UDim2.new(0, 12, 0, 0)
            btnLabel.BackgroundTransparency = 1
            btnLabel.Text = text
            btnLabel.Font = Enum.Font.GothamSemibold
            btnLabel.TextSize = 13
            btnLabel.TextColor3 = Theme.TextPrimary
            btnLabel.TextXAlignment = Enum.TextXAlignment.Left
            btnLabel.ZIndex = 5
            btnLabel.Parent = btn

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -28, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "›"
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 18
            arrow.TextColor3 = Theme.Accent
            arrow.ZIndex = 5
            arrow.Parent = btn

            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Surface}, 0.15)
            end)
            btn.MouseButton1Click:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.AccentDim}, 0.05)
                task.wait(0.05)
                Tween(btn, {BackgroundColor3 = Theme.Surface}, 0.15)
                if callback then task.spawn(callback) end
            end)

            return btn
        end

        -- TOGGLE
        function Tab:AddToggle(text, default, callback)
            local state = default or false

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 38)
            row.BackgroundColor3 = Theme.Surface
            MakeCorner(8, row)
            MakeStroke(Theme.Border, 1, row)
            row.Parent = content

            local rowLabel = Instance.new("TextLabel")
            rowLabel.Size = UDim2.new(1, -60, 1, 0)
            rowLabel.Position = UDim2.new(0, 12, 0, 0)
            rowLabel.BackgroundTransparency = 1
            rowLabel.Text = text
            rowLabel.Font = Enum.Font.GothamSemibold
            rowLabel.TextSize = 13
            rowLabel.TextColor3 = Theme.TextPrimary
            rowLabel.TextXAlignment = Enum.TextXAlignment.Left
            rowLabel.Parent = row

            -- Toggle track
            local track = Instance.new("Frame")
            track.Size = UDim2.new(0, 40, 0, 22)
            track.Position = UDim2.new(1, -52, 0.5, -11)
            track.BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off
            MakeCorner(11, track)
            track.Parent = row

            local thumb = Instance.new("Frame")
            thumb.Size = UDim2.new(0, 16, 0, 16)
            thumb.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            MakeCorner(8, thumb)
            thumb.Parent = track

            local clickArea = Instance.new("TextButton")
            clickArea.Size = UDim2.new(1, 0, 1, 0)
            clickArea.BackgroundTransparency = 1
            clickArea.Text = ""
            clickArea.ZIndex = 5
            clickArea.Parent = row

            clickArea.MouseButton1Click:Connect(function()
                state = not state
                Tween(track, {BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off}, 0.2)
                Tween(thumb, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2)
                if callback then task.spawn(callback, state) end
            end)

            local ctrl = {}
            function ctrl:Set(v)
                state = v
                Tween(track, {BackgroundColor3 = state and Theme.Toggle_On or Theme.Toggle_Off}, 0.2)
                Tween(thumb, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2)
                if callback then task.spawn(callback, state) end
            end
            function ctrl:Get() return state end
            return ctrl
        end

        -- SLIDER
        function Tab:AddSlider(text, options, callback)
            options = options or {}
            local min   = options.Min   or 0
            local max   = options.Max   or 100
            local def   = options.Default or min
            local value = def

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 56)
            row.BackgroundColor3 = Theme.Surface
            MakeCorner(8, row)
            MakeStroke(Theme.Border, 1, row)
            row.Parent = content

            local rowLabel = Instance.new("TextLabel")
            rowLabel.Size = UDim2.new(1, -50, 0, 24)
            rowLabel.Position = UDim2.new(0, 12, 0, 6)
            rowLabel.BackgroundTransparency = 1
            rowLabel.Text = text
            rowLabel.Font = Enum.Font.GothamSemibold
            rowLabel.TextSize = 13
            rowLabel.TextColor3 = Theme.TextPrimary
            rowLabel.TextXAlignment = Enum.TextXAlignment.Left
            rowLabel.Parent = row

            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(0, 40, 0, 24)
            valLabel.Position = UDim2.new(1, -48, 0, 6)
            valLabel.BackgroundTransparency = 1
            valLabel.Text = tostring(value)
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextSize = 12
            valLabel.TextColor3 = Theme.Accent
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Parent = row

            local trackBg = Instance.new("Frame")
            trackBg.Size = UDim2.new(1, -24, 0, 6)
            trackBg.Position = UDim2.new(0, 12, 0, 38)
            trackBg.BackgroundColor3 = Theme.Slider_Track
            MakeCorner(3, trackBg)
            trackBg.Parent = row

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Slider_Fill
            MakeCorner(3, fill)
            fill.Parent = trackBg

            MakeGradient(0,
                Theme.Accent,
                Color3.fromRGB(160, 130, 255),
                fill)

            local thumb2 = Instance.new("Frame")
            thumb2.Size = UDim2.new(0, 14, 0, 14)
            thumb2.Position = UDim2.new((value - min)/(max-min), -7, 0.5, -7)
            thumb2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            MakeCorner(7, thumb2)
            thumb2.ZIndex = 5
            thumb2.Parent = trackBg

            local dragging2 = false
            local function update2(input)
                local rel = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(min + (max - min) * rel)
                if newVal ~= value then
                    value = newVal
                    valLabel.Text = tostring(value)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    thumb2.Position = UDim2.new(rel, -7, 0.5, -7)
                    if callback then task.spawn(callback, value) end
                end
            end

            trackBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = true
                    update2(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement
                               or input.UserInputType == Enum.UserInputType.Touch) then
                    update2(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = false
                end
            end)

            local ctrl = {}
            function ctrl:Set(v)
                value = math.clamp(v, min, max)
                local rel = (value - min) / (max - min)
                valLabel.Text = tostring(value)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                thumb2.Position = UDim2.new(rel, -7, 0.5, -7)
                if callback then task.spawn(callback, value) end
            end
            function ctrl:Get() return value end
            return ctrl
        end

        -- DROPDOWN
        function Tab:AddDropdown(text, items, callback)
            local selected = items[1] or "Select..."
            local open = false

            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 38)
            container.BackgroundTransparency = 1
            container.ClipsDescendants = false
            container.ZIndex = 10
            container.Parent = content

            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 38)
            row.BackgroundColor3 = Theme.Surface
            row.Text = ""
            row.ZIndex = 10
            MakeCorner(8, row)
            MakeStroke(Theme.Border, 1, row)
            row.Parent = container

            local rowLabel = Instance.new("TextLabel")
            rowLabel.Size = UDim2.new(1, -50, 1, 0)
            rowLabel.Position = UDim2.new(0, 12, 0, 0)
            rowLabel.BackgroundTransparency = 1
            rowLabel.Text = text
            rowLabel.Font = Enum.Font.GothamSemibold
            rowLabel.TextSize = 13
            rowLabel.TextColor3 = Theme.TextPrimary
            rowLabel.TextXAlignment = Enum.TextXAlignment.Left
            rowLabel.ZIndex = 11
            rowLabel.Parent = row

            local selLabel = Instance.new("TextLabel")
            selLabel.Size = UDim2.new(0, 110, 1, 0)
            selLabel.Position = UDim2.new(1, -120, 0, 0)
            selLabel.BackgroundTransparency = 1
            selLabel.Text = selected .. " ▾"
            selLabel.Font = Enum.Font.Gotham
            selLabel.TextSize = 12
            selLabel.TextColor3 = Theme.Accent
            selLabel.TextXAlignment = Enum.TextXAlignment.Right
            selLabel.ZIndex = 11
            selLabel.Parent = row

            -- Dropdown list
            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, 0, 0, 0)
            dropFrame.Position = UDim2.new(0, 0, 1, 4)
            dropFrame.BackgroundColor3 = Theme.Surface
            dropFrame.ZIndex = 20
            dropFrame.ClipsDescendants = true
            MakeCorner(8, dropFrame)
            MakeStroke(Theme.Border, 1, dropFrame)
            dropFrame.Parent = container

            local dropLayout = Instance.new("UIListLayout")
            dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            dropLayout.Padding = UDim.new(0, 2)
            dropLayout.Parent = dropFrame

            local dropPad = Instance.new("UIPadding")
            dropPad.PaddingTop = UDim.new(0, 4)
            dropPad.PaddingBottom = UDim.new(0, 4)
            dropPad.PaddingLeft = UDim.new(0, 4)
            dropPad.PaddingRight = UDim.new(0, 4)
            dropPad.Parent = dropFrame

            local itemHeight = 30
            local totalH = #items * (itemHeight + 2) + 8

            for _, item in ipairs(items) do
                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 0, itemHeight)
                itemBtn.BackgroundColor3 = Theme.SurfaceHover
                itemBtn.BackgroundTransparency = 1
                itemBtn.Text = item
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.TextSize = 12
                itemBtn.TextColor3 = Theme.TextPrimary
                itemBtn.ZIndex = 21
                MakeCorner(6, itemBtn)
                itemBtn.Parent = dropFrame

                itemBtn.MouseEnter:Connect(function()
                    Tween(itemBtn, {BackgroundTransparency = 0}, 0.1)
                end)
                itemBtn.MouseLeave:Connect(function()
                    Tween(itemBtn, {BackgroundTransparency = 1}, 0.1)
                end)
                itemBtn.MouseButton1Click:Connect(function()
                    selected = item
                    selLabel.Text = selected .. " ▾"
                    open = false
                    Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    Tween(container, {Size = UDim2.new(1, 0, 0, 38)}, 0.2)
                    if callback then task.spawn(callback, selected) end
                end)
            end

            row.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Tween(dropFrame, {Size = UDim2.new(1, 0, 0, totalH)}, 0.25, Enum.EasingStyle.Back)
                    Tween(container, {Size = UDim2.new(1, 0, 0, 38 + totalH + 4)}, 0.25)
                else
                    Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    Tween(container, {Size = UDim2.new(1, 0, 0, 38)}, 0.2)
                end
            end)

            local ctrl = {}
            function ctrl:Set(v) selected = v; selLabel.Text = v .. " ▾" end
            function ctrl:Get() return selected end
            return ctrl
        end

        -- TEXTBOX
        function Tab:AddTextbox(text, placeholder, callback)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 56)
            row.BackgroundColor3 = Theme.Surface
            MakeCorner(8, row)
            MakeStroke(Theme.Border, 1, row)
            row.Parent = content

            local rowLabel = Instance.new("TextLabel")
            rowLabel.Size = UDim2.new(1, 0, 0, 22)
            rowLabel.Position = UDim2.new(0, 12, 0, 6)
            rowLabel.BackgroundTransparency = 1
            rowLabel.Text = text
            rowLabel.Font = Enum.Font.GothamSemibold
            rowLabel.TextSize = 12
            rowLabel.TextColor3 = Theme.TextSecondary
            rowLabel.TextXAlignment = Enum.TextXAlignment.Left
            rowLabel.Parent = row

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -24, 0, 24)
            box.Position = UDim2.new(0, 12, 0, 28)
            box.BackgroundColor3 = Theme.Background
            box.Text = ""
            box.PlaceholderText = placeholder or "Type here..."
            box.PlaceholderColor3 = Theme.TextDisabled
            box.Font = Enum.Font.Gotham
            box.TextSize = 12
            box.TextColor3 = Theme.TextPrimary
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            MakeCorner(6, box)
            box.Parent = row

            local boxPad = Instance.new("UIPadding")
            boxPad.PaddingLeft = UDim.new(0, 8)
            boxPad.Parent = box

            box.Focused:Connect(function()
                Tween(row, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(row, {BackgroundColor3 = Theme.Surface}, 0.15)
                if callback then task.spawn(callback, box.Text, enter) end
            end)

            return box
        end

        -- LABEL
        function Tab:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 28)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextColor3 = Theme.TextSecondary
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true
            lbl.Parent = content

            local ctrl = {}
            function ctrl:Set(v) lbl.Text = v end
            return ctrl
        end

        -- KEYBIND
        function Tab:AddKeybind(text, default, callback)
            local key = default or Enum.KeyCode.Unknown
            local listening = false

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 38)
            row.BackgroundColor3 = Theme.Surface
            MakeCorner(8, row)
            MakeStroke(Theme.Border, 1, row)
            row.Parent = content

            local rowLabel = Instance.new("TextLabel")
            rowLabel.Size = UDim2.new(1, -100, 1, 0)
            rowLabel.Position = UDim2.new(0, 12, 0, 0)
            rowLabel.BackgroundTransparency = 1
            rowLabel.Text = text
            rowLabel.Font = Enum.Font.GothamSemibold
            rowLabel.TextSize = 13
            rowLabel.TextColor3 = Theme.TextPrimary
            rowLabel.TextXAlignment = Enum.TextXAlignment.Left
            rowLabel.Parent = row

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 26)
            keyBtn.Position = UDim2.new(1, -88, 0.5, -13)
            keyBtn.BackgroundColor3 = Theme.Background
            keyBtn.Text = key.Name
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 11
            keyBtn.TextColor3 = Theme.Accent
            MakeCorner(6, keyBtn)
            MakeStroke(Theme.AccentDim, 1, keyBtn)
            keyBtn.Parent = row

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                keyBtn.TextColor3 = Theme.TextSecondary
            end)

            UserInputService.InputBegan:Connect(function(input, gp)
                if listening and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    key = input.KeyCode
                    keyBtn.Text = key.Name
                    keyBtn.TextColor3 = Theme.Accent
                end
                if not listening and input.KeyCode == key then
                    if callback then task.spawn(callback) end
                end
            end)

            return keyBtn
        end

        return Tab
    end

    -- ── Status Bar ─────────────────────────────
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, 0, 0, 1)
    statusBar.Position = UDim2.new(0, 0, 0, 84)
    statusBar.BackgroundColor3 = Theme.Border
    statusBar.BorderSizePixel = 0
    statusBar.ZIndex = 3
    statusBar.Parent = Main

    return Window
end

-- ════════════════════════════════════════════
--  RETURN
-- ════════════════════════════════════════════
return MaruLib
