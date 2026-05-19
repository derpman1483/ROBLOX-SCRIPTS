--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    GLARE UI  ·  single-function embed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    QUICK START
    ───────────
    local gui = GlareUI({
        Title    = "My Script",
        SubTitle = "v1.0",
        Theme    = "Dark",          -- Dark | Light | Ocean | Rose
        Key      = Enum.KeyCode.RightShift,
        Size     = {560, 400},      -- optional {W, H}
        Loader   = "Initializing…", -- nil = skip loader screen
    })

    local tab = gui:Tab("Combat")      -- icon arg optional
    local tab2 = gui:Tab("Visuals", "rbxassetid://…")

    -- All element methods return the TAB so you can chain:
    tab:Button("Kill Aura",    function() end)
       :Toggle("God Mode",     false, "GodMode",   function(v) end)
       :Slider("Walk Speed",   0, 500, 16, 1, "WalkSpeed", function(v) end)
       :Dropdown("Team",       {"Red","Blue"}, "Red", "Team", function(v) end)
       :Input("Username",      "type…", "Username", function(v) end)
       :Color("Chams Color",   Color3.fromRGB(255,80,80), "Color", function(c) end)
       :Bind("Toggle ESP",     Enum.KeyCode.X, "ESPKey", function(k) end)
       :Label("── info ──")
       :Section("Misc")
       :Para("Info", "Some longer text that wraps neatly.")

    gui:Notify("Loaded", "Script is ready.", "Success", 4)

    print(gui.Flags.WalkSpeed)  -- access any flag globally
    gui:Destroy()               -- nuke the entire gui
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
]]

local function GlareUI(cfg)
    cfg = cfg or {}

    local TW    = game:GetService("TweenService")
    local UIS   = game:GetService("UserInputService")
    local PLR   = game:GetService("Players")
    local TXT   = game:GetService("TextService")
    local lp    = PLR.LocalPlayer
    local mouse = lp:GetMouse()

    local TITLE    = cfg.Title    or "Glare"
    local SUB      = cfg.SubTitle or ""
    local THEME_ID = cfg.Theme    or "Dark"
    local KEY      = cfg.Key      or Enum.KeyCode.RightShift
    local SZ       = cfg.Size     or {560, 400}
    local W, H     = SZ[1], SZ[2]
    local LOADER   = cfg.Loader

    local THEMES = {
        Dark = {
            Bg         = Color3.fromRGB(14,  14,  20),
            Bg2        = Color3.fromRGB(20,  20,  28),
            Surface    = Color3.fromRGB(28,  28,  40),
            SurfaceHov = Color3.fromRGB(38,  38,  54),
            Border     = Color3.fromRGB(48,  48,  68),
            Accent     = Color3.fromRGB(108, 162, 255),
            AccentDk   = Color3.fromRGB(68,  108, 210),
            AccentGlow = Color3.fromRGB(88,  138, 235),
            Text       = Color3.fromRGB(228, 228, 240),
            TextMute   = Color3.fromRGB(130, 130, 155),
            TextDim    = Color3.fromRGB(72,  72,  96),
            Good       = Color3.fromRGB(80,  220, 140),
            Warn       = Color3.fromRGB(255, 192, 60),
            Bad        = Color3.fromRGB(255, 82,  82),
            TOn        = Color3.fromRGB(80,  220, 140),
            TOff       = Color3.fromRGB(55,  55,  76),
            SlFill     = Color3.fromRGB(108, 162, 255),
            SlBg       = Color3.fromRGB(38,  38,  58),
            TitleBg    = Color3.fromRGB(16,  16,  24),
            NotBg      = Color3.fromRGB(20,  20,  28),
            Close      = Color3.fromRGB(255, 82,  82),
            Minimize   = Color3.fromRGB(255, 192, 60),
        },
        Light = {
            Bg         = Color3.fromRGB(244, 244, 252),
            Bg2        = Color3.fromRGB(234, 234, 246),
            Surface    = Color3.fromRGB(255, 255, 255),
            SurfaceHov = Color3.fromRGB(226, 226, 240),
            Border     = Color3.fromRGB(198, 198, 220),
            Accent     = Color3.fromRGB(68,  128, 240),
            AccentDk   = Color3.fromRGB(48,  98,  200),
            AccentGlow = Color3.fromRGB(88,  148, 255),
            Text       = Color3.fromRGB(28,  28,  48),
            TextMute   = Color3.fromRGB(98,  98,  128),
            TextDim    = Color3.fromRGB(158, 158, 190),
            Good       = Color3.fromRGB(38,  178, 98),
            Warn       = Color3.fromRGB(208, 148, 28),
            Bad        = Color3.fromRGB(218, 58,  58),
            TOn        = Color3.fromRGB(48,  198, 118),
            TOff       = Color3.fromRGB(188, 188, 210),
            SlFill     = Color3.fromRGB(68,  128, 240),
            SlBg       = Color3.fromRGB(208, 208, 230),
            TitleBg    = Color3.fromRGB(228, 228, 244),
            NotBg      = Color3.fromRGB(255, 255, 255),
            Close      = Color3.fromRGB(218, 58,  58),
            Minimize   = Color3.fromRGB(208, 148, 28),
        },
        Ocean = {
            Bg         = Color3.fromRGB(7,   20,  36),
            Bg2        = Color3.fromRGB(10,  30,  50),
            Surface    = Color3.fromRGB(14,  42,  66),
            SurfaceHov = Color3.fromRGB(20,  56,  84),
            Border     = Color3.fromRGB(28,  76,  116),
            Accent     = Color3.fromRGB(0,   198, 210),
            AccentDk   = Color3.fromRGB(0,   152, 162),
            AccentGlow = Color3.fromRGB(0,   220, 232),
            Text       = Color3.fromRGB(198, 238, 250),
            TextMute   = Color3.fromRGB(98,  168, 198),
            TextDim    = Color3.fromRGB(48,  98,  138),
            Good       = Color3.fromRGB(0,   218, 158),
            Warn       = Color3.fromRGB(255, 198, 58),
            Bad        = Color3.fromRGB(255, 78,  98),
            TOn        = Color3.fromRGB(0,   218, 158),
            TOff       = Color3.fromRGB(28,  68,  98),
            SlFill     = Color3.fromRGB(0,   198, 210),
            SlBg       = Color3.fromRGB(18,  52,  82),
            TitleBg    = Color3.fromRGB(6,   18,  32),
            NotBg      = Color3.fromRGB(10,  30,  50),
            Close      = Color3.fromRGB(255, 78,  98),
            Minimize   = Color3.fromRGB(255, 198, 58),
        },
        Rose = {
            Bg         = Color3.fromRGB(18,  9,   16),
            Bg2        = Color3.fromRGB(28,  13,  26),
            Surface    = Color3.fromRGB(40,  18,  36),
            SurfaceHov = Color3.fromRGB(54,  26,  50),
            Border     = Color3.fromRGB(78,  38,  70),
            Accent     = Color3.fromRGB(255, 98,  158),
            AccentDk   = Color3.fromRGB(198, 58,  118),
            AccentGlow = Color3.fromRGB(255, 128, 178),
            Text       = Color3.fromRGB(250, 218, 234),
            TextMute   = Color3.fromRGB(178, 128, 158),
            TextDim    = Color3.fromRGB(108, 68,  98),
            Good       = Color3.fromRGB(158, 218, 118),
            Warn       = Color3.fromRGB(255, 198, 78),
            Bad        = Color3.fromRGB(255, 78,  78),
            TOn        = Color3.fromRGB(255, 98,  158),
            TOff       = Color3.fromRGB(68,  33,  62),
            SlFill     = Color3.fromRGB(255, 98,  158),
            SlBg       = Color3.fromRGB(58,  28,  52),
            TitleBg    = Color3.fromRGB(14,  6,   12),
            NotBg      = Color3.fromRGB(28,  13,  26),
            Close      = Color3.fromRGB(255, 78,  78),
            Minimize   = Color3.fromRGB(255, 198, 78),
        },
    }

    local T = THEMES[THEME_ID] or THEMES.Dark

    local function tw(obj, props, t, style, dir)
        TW:Create(obj,
            TweenInfo.new(t or 0.18,
                style or Enum.EasingStyle.Quart,
                dir   or Enum.EasingDirection.Out),
            props):Play()
    end

    local function corner(p, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 8)
        c.Parent = p
        return c
    end

    local function stroke(p, col, thick, trans)
        local s = Instance.new("UIStroke")
        s.Color = col or Color3.new(1,1,1)
        s.Thickness = thick or 1
        s.Transparency = trans or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = p
        return s
    end

    local function pad(p, t, b, l, r)
        local u = Instance.new("UIPadding")
        u.PaddingTop    = UDim.new(0, t or 0)
        u.PaddingBottom = UDim.new(0, b or 0)
        u.PaddingLeft   = UDim.new(0, l or 0)
        u.PaddingRight  = UDim.new(0, r or 0)
        u.Parent = p
        return u
    end

    local function list(p, spacing, dir)
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, spacing or 6)
        l.FillDirection = dir or Enum.FillDirection.Vertical
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.Parent = p
        return l
    end

    -- FIX: hook a UIListLayout to auto-update a ScrollingFrame's CanvasSize
    -- replaces AutomaticCanvasSize which silently fails in many executors
    local function autoCanvas(scrollFrame, layout, extraPad)
        extraPad = extraPad or 8
        local function update()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0,
                layout.AbsoluteContentSize.Y + extraPad)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
        update()
    end

    local function shadow(p, sz, tr)
        local s = Instance.new("ImageLabel")
        s.Name = "Shadow"
        s.AnchorPoint = Vector2.new(0.5, 0.5)
        s.BackgroundTransparency = 1
        s.Position = UDim2.new(0.5, 0, 0.5, 4)
        s.Size = UDim2.new(1, sz or 28, 1, sz or 28)
        s.ZIndex = math.max((p.ZIndex or 1) - 1, 0)
        s.Image = "rbxassetid://6014261993"
        s.ImageColor3 = Color3.new(0, 0, 0)
        s.ImageTransparency = tr or 0.55
        s.ScaleType = Enum.ScaleType.Slice
        s.SliceCenter = Rect.new(49, 49, 450, 450)
        s.Parent = p
        return s
    end

    local function make(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end

    local function roundTo(n, inc)
        return math.round(n / inc) * inc
    end

    local function drag(frame, handle)
        handle = handle or frame
        local on, ds, sp
        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                on = true; ds = i.Position; sp = frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if on and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                frame.Position = UDim2.new(
                    sp.X.Scale, sp.X.Offset + d.X,
                    sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then on = false end
        end)
    end

    -- FIX: removed ZIndexBehavior.Sibling (unreliable in executors)
    -- FIX: always parent to PlayerGui — CoreGui parenting silently fails to render in many executors
    local root = Instance.new("ScreenGui")
    root.Name = "GlareUI"
    root.ResetOnSpawn = false
    root.DisplayOrder = 999
    local ok = pcall(function() root.Parent = game:GetService("CoreGui") end)
    if not ok then root.Parent = lp:WaitForChild("PlayerGui") end

    local notifHolder = make("Frame", {
        Name = "Notifs",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 290, 1, -28),
        BackgroundTransparency = 1,
        ZIndex = 9000,
    }, root)
    local nl = list(notifHolder, 8)
    nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nl.HorizontalAlignment = Enum.HorizontalAlignment.Right

    -- FIX: loader uses Tween.Completed instead of task.delay
    if LOADER then
        local ldr = make("Frame", {
            Name = "Loader",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            ZIndex = 9999,
        }, root)
        make("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, -18),
            Size = UDim2.new(0, 380, 0, 28),
            BackgroundTransparency = 1,
            Text = LOADER,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = T.Text,
            ZIndex = 9999,
        }, ldr)
        local lbg = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 10),
            Size = UDim2.new(0, 280, 0, 2),
            BackgroundColor3 = T.Border,
            ZIndex = 9999,
        }, ldr)
        corner(lbg, 2)
        local lfill = make("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            ZIndex = 9999,
        }, lbg)
        corner(lfill, 2)
        local fillTween = TW:Create(lfill,
            TweenInfo.new(1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)})
        fillTween.Completed:Connect(function()
            local fadeTween = TW:Create(ldr,
                TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1})
            fadeTween.Completed:Connect(function() ldr:Destroy() end)
            fadeTween:Play()
        end)
        fillTween:Play()
    end

    local win = make("Frame", {
        Name = "GlareWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, W, 0, H),
        BackgroundColor3 = T.Bg,
        ClipsDescendants = false,
        ZIndex = 100,
    }, root)
    corner(win, 12)
    stroke(win, T.Border, 1, 0.4)
    shadow(win, 38, 0.42)

    local tbar = make("Frame", {
        Name = "TBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.TitleBg,
        ZIndex = 101,
    }, win)
    corner(tbar, 12)
    make("Frame", {
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = T.TitleBg,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, tbar)

    make("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.65, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = TITLE .. (SUB ~= "" and ("  ·  " .. SUB) or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
    }, tbar)

    local btnRow = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 52, 0, 22),
        BackgroundTransparency = 1,
        ZIndex = 102,
    }, tbar)
    list(btnRow, 7, Enum.FillDirection.Horizontal)

    local function winbtn(col)
        local b = make("TextButton", {
            Size = UDim2.new(0, 11, 0, 11),
            BackgroundColor3 = col,
            Text = "",
            ZIndex = 103,
        }, btnRow)
        corner(b, 6)
        return b
    end
    local minBtn   = winbtn(T.Minimize)
    local closeBtn = winbtn(T.Close)

    local content = make("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 101,
    }, win)

    local sidebar = make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 128, 1, 0),
        BackgroundColor3 = T.Bg2,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, content)

    local searchWrap = make("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = 103,
    }, sidebar)
    pad(searchWrap, 6, 0, 8, 8)

    local searchBox = make("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.Surface,
        Text = "",
        PlaceholderText = "Search…",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = T.Text,
        PlaceholderColor3 = T.TextDim,
        ClearTextOnFocus = false,
        ZIndex = 103,
    }, searchWrap)
    corner(searchBox, 6)
    pad(searchBox, 0, 0, 8, 8)

    -- FIX: removed AutomaticCanvasSize, use autoCanvas helper instead
    local tabScroll = make("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 103,
    }, sidebar)
    pad(tabScroll, 4, 4, 6, 6)
    local tabLayout = list(tabScroll, 4)
    autoCanvas(tabScroll, tabLayout, 8)

    make("Frame", {
        Position = UDim2.new(0, 128, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, content)

    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.new(0, 129, 0, 0),
        Size = UDim2.new(1, -129, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 102,
    }, content)

    drag(win, tbar)

    local tabs       = {}
    local activeTab  = nil
    local guiVisible = true
    local minimized  = false

    local function switchTab(tab)
        for _, t in pairs(tabs) do
            local a = (t == tab)
            tw(t._btn, {
                BackgroundColor3       = a and T.Accent or Color3.new(0,0,0),
                BackgroundTransparency = a and 0.78 or 1,
            }, 0.14)
            t._lbl.TextColor3 = a and T.Accent or T.TextMute
            t._page.Visible   = a
        end
        activeTab = tab
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, tab in pairs(tabs) do
            for _, el in pairs(tab._els) do
                if el.frame and el.name then
                    el.frame.Visible = q == "" or el.name:lower():find(q, 1, true) ~= nil
                end
            end
        end
    end)

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(win, {Size = UDim2.new(0, W, 0, minimized and 44 or H)}, 0.22)
        content.Visible = not minimized
    end)

    -- FIX: spawn+wait instead of task.delay
    closeBtn.MouseButton1Click:Connect(function()
        tw(win, {Size = UDim2.new(0, W, 0, 0), BackgroundTransparency = 1}, 0.18)
        spawn(function() wait(0.2); root:Destroy() end)
    end)

    UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == KEY then
            guiVisible = not guiVisible
            tw(win, {Size = UDim2.new(0, W, 0, guiVisible and H or 44)}, 0.22)
            content.Visible = guiVisible
        end
    end)

    local function makeRow(page, name, h)
        h = h or 36
        local f = make("Frame", {
            Size = UDim2.new(1, 0, 0, h),
            BackgroundColor3 = T.Surface,
            ZIndex = 104,
        }, page)
        corner(f, 8)
        stroke(f, T.Border, 1, 0.62)
        make("TextLabel", {
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0.54, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 105,
        }, f)
        f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.SurfaceHov}, 0.1) end)
        f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.Surface},    0.1) end)
        return f
    end

    local gui     = {}
    gui.Flags     = {}
    gui._root     = root

    function gui:Notify(title, body, ntype, dur)
        title = title or "Notice"
        body  = body  or ""
        dur   = dur   or 4
        local accent = ({
            Info    = T.Accent,
            Success = T.Good,
            Warning = T.Warn,
            Error   = T.Bad,
        })[ntype or "Info"] or T.Accent

        local card = make("Frame", {
            Name = "N" .. tostring(tick()),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = T.NotBg,
            ClipsDescendants = true,
            ZIndex = 9001,
        }, notifHolder)
        corner(card, 10)
        stroke(card, T.Border, 1, 0.5)
        shadow(card, 18, 0.6)

        make("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            ZIndex = 9002,
        }, card)

        local inner = make("Frame", {
            Position = UDim2.new(0, 11, 0, 0),
            Size = UDim2.new(1, -11, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 9002,
        }, card)
        pad(inner, 10, 10, 4, 10)
        list(inner, 3)

        make("TextLabel", {
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            ZIndex = 9002,
        }, inner)

        if body ~= "" then
            make("TextLabel", {
                Text = body,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = T.TextMute,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                ZIndex = 9002,
            }, inner)
        end

        local pbg = make("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = T.Border,
            BorderSizePixel = 0,
            ZIndex = 9003,
        }, inner)
        corner(pbg, 2)
        local pbar = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            ZIndex = 9003,
        }, pbg)
        corner(pbar, 2)

        local tgtH = body ~= "" and 78 or 52
        tw(card, {Size = UDim2.new(1, 0, 0, tgtH)}, 0.28)

        -- FIX: spawn+wait instead of task.delay
        spawn(function()
            wait(0.08)
            tw(pbar, {Size = UDim2.new(0, 0, 1, 0)}, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            wait(dur + 0.08)
            tw(card, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.22)
            wait(0.26)
            card:Destroy()
        end)
    end

    function gui:Destroy()
        root:Destroy()
    end

    function gui:SetTheme(name)
        T = THEMES[name] or T
    end

    function gui:Tab(name, icon)
        name = name or "Tab"

        local btn = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 104,
        }, tabScroll)
        corner(btn, 7)
        pad(btn, 0, 0, 6, 6)

        local brow = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 104,
        }, btn)
        -- FIX: capture the UIListLayout so we can set VerticalAlignment on IT,
        -- not on the Frame (brow.VerticalAlignment = ... was a silent no-op)
        local browLayout = list(brow, 5, Enum.FillDirection.Horizontal)
        browLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        if icon then
            make("ImageLabel", {
                Size = UDim2.new(0, 13, 0, 13),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = T.TextMute,
                ZIndex = 104,
            }, brow)
        end

        local lbl = make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = T.TextMute,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 104,
        }, brow)

        -- FIX: removed AutomaticCanvasSize, use autoCanvas helper
        local page = make("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            ZIndex = 103,
        }, pages)
        pad(page, 10, 10, 10, 10)
        local pageLayout = list(page, 6)
        autoCanvas(page, pageLayout, 20)

        local tab = {_btn=btn, _lbl=lbl, _page=page, _els={}}

        btn.MouseButton1Click:Connect(function() switchTab(tab) end)
        btn.MouseEnter:Connect(function()
            if activeTab ~= tab then tw(lbl, {TextColor3 = T.Text}, 0.12) end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= tab then tw(lbl, {TextColor3 = T.TextMute}, 0.12) end
        end)

        -- FIX: insert THEN switch directly — no task.defer
        table.insert(tabs, tab)
        if #tabs == 1 then switchTab(tab) end

        local function reg(frame, elname)
            table.insert(tab._els, {frame = frame, name = elname})
        end

        function tab:Button(label, callback)
            local f = makeRow(page, label)
            local b = make("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 76, 0, 23),
                BackgroundColor3 = T.Accent,
                Text = "Execute",
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = Color3.new(1, 1, 1),
                ZIndex = 105,
            }, f)
            corner(b, 6)
            -- FIX: spawn+wait instead of task.delay, spawn instead of task.spawn
            b.MouseButton1Click:Connect(function()
                tw(b, {BackgroundColor3 = T.AccentDk}, 0.07)
                spawn(function() wait(0.07); tw(b, {BackgroundColor3 = T.Accent}, 0.14) end)
                spawn(callback or function() end)
            end)
            b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = T.AccentGlow}, 0.1) end)
            b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = T.Accent},     0.1) end)
            reg(f, label)
            return self
        end

        function tab:Toggle(label, default, flag, callback)
            default = default or false
            local state = default
            if flag then gui.Flags[flag] = state end

            local f = makeRow(page, label)
            local TW2, TH = 38, 19

            local track = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, TW2, 0, TH),
                BackgroundColor3 = state and T.TOn or T.TOff,
                ZIndex = 105,
            }, f)
            corner(track, 10)

            local knob = make("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, state and TW2-TH+2 or 2, 0.5, 0),
                Size = UDim2.new(0, TH-4, 0, TH-4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 106,
            }, track)
            corner(knob, 10)

            local function set(v)
                state = v
                if flag then gui.Flags[flag] = v end
                tw(track, {BackgroundColor3 = v and T.TOn or T.TOff}, 0.18)
                tw(knob,  {Position = UDim2.new(0, v and TW2-TH+2 or 2, 0.5, 0)}, 0.18)
                spawn(callback or function() end, v) -- FIX
            end

            make("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 107,
            }, f).MouseButton1Click:Connect(function() set(not state) end)

            reg(f, label)
            return self
        end

        function tab:Slider(label, mn, mx, def, inc, flag, callback)
            mn  = mn  or 0
            mx  = mx  or 100
            def = def or mn
            inc = inc or 1
            local val = math.clamp(def, mn, mx)
            if flag then gui.Flags[flag] = val end

            local f = make("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = T.Surface,
                ZIndex = 104,
            }, page)
            corner(f, 8)
            stroke(f, T.Border, 1, 0.62)
            f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.SurfaceHov}, 0.1) end)
            f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.Surface},    0.1) end)

            make("TextLabel", {
                Position = UDim2.new(0, 12, 0, 2),
                Size = UDim2.new(0.7, 0, 0, 24),
                BackgroundTransparency = 1,
                Text = label,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 105,
            }, f)

            local valLbl = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 2),
                Size = UDim2.new(0, 58, 0, 24),
                BackgroundTransparency = 1,
                Text = tostring(val),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = T.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 105,
            }, f)

            local tbg = make("Frame", {
                Position = UDim2.new(0, 12, 0, 34),
                Size = UDim2.new(1, -24, 0, 6),
                BackgroundColor3 = T.SlBg,
                ZIndex = 105,
            }, f)
            corner(tbg, 3)

            local fill = make("Frame", {
                Size = UDim2.new((val-mn)/(mx-mn), 0, 1, 0),
                BackgroundColor3 = T.SlFill,
                BorderSizePixel = 0,
                ZIndex = 106,
            }, tbg)
            corner(fill, 3)

            local thumb = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((val-mn)/(mx-mn), 0, 0.5, 0),
                Size = UDim2.new(0, 13, 0, 13),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 107,
            }, tbg)
            corner(thumb, 7)
            stroke(thumb, T.SlFill, 2)

            local function setVal(v)
                v   = roundTo(math.clamp(v, mn, mx), inc)
                val = v
                if flag then gui.Flags[flag] = v end
                local t = (v - mn) / (mx - mn)
                tw(fill,  {Size     = UDim2.new(t, 0, 1, 0)},   0.07)
                tw(thumb, {Position = UDim2.new(t, 0, 0.5, 0)}, 0.07)
                valLbl.Text = tostring(v)
                spawn(callback or function() end, v) -- FIX
            end

            local sdrag = false
            make("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 108,
            }, tbg).InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sdrag = true end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sdrag = false end
            end)
            UIS.InputChanged:Connect(function(i)
                if sdrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local ap = tbg.AbsolutePosition
                    local as = tbg.AbsoluteSize
                    setVal(mn + (mx - mn) * math.clamp((mouse.X - ap.X) / as.X, 0, 1))
                end
            end)

            reg(f, label)
            return self
        end

        function tab:Dropdown(label, options, default, flag, callback, multi)
            options = options or {}
            local sel  = multi and {} or (default or options[1])
            local open = false
            if flag then gui.Flags[flag] = sel end

            local cont = make("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = T.Surface,
                ClipsDescendants = false,
                ZIndex = 110,
            }, page)
            corner(cont, 8)
            stroke(cont, T.Border, 1, 0.62)

            local hdr = make("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex = 111,
            }, cont)
            make("TextLabel", {
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.55, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = label,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 111,
            }, hdr)

            local selLbl = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -28, 0.5, 0),
                Size = UDim2.new(0.38, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = multi and "None" or (default or "Select"),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = T.TextMute,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 111,
            }, hdr)

            local arr = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                Text = "▾",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = T.TextMute,
                ZIndex = 111,
            }, hdr)

            local dropBg = make("Frame", {
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = T.Bg2,
                ClipsDescendants = true,
                ZIndex = 200,
            }, cont)
            corner(dropBg, 8)
            stroke(dropBg, T.Border, 1, 0.42)
            shadow(dropBg, 14, 0.52)

            -- FIX: removed AutomaticCanvasSize, use autoCanvas helper
            local dscroll = make("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = T.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ZIndex = 201,
            }, dropBg)
            pad(dscroll, 4, 4, 6, 6)
            local dLayout = list(dscroll, 3)
            autoCanvas(dscroll, dLayout, 8)

            local function updSel()
                if multi then
                    local parts = {}
                    for k in pairs(sel) do table.insert(parts, k) end
                    selLbl.Text = #parts == 0 and "None" or table.concat(parts, ", ")
                else
                    selLbl.Text = tostring(sel or "Select")
                end
            end

            local maxH = math.min(#options * 30 + 8, 158)

            for _, opt in ipairs(options) do
                local ob = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundColor3 = T.Surface,
                    BackgroundTransparency = 0.5,
                    Text = "",
                    ZIndex = 202,
                }, dscroll)
                corner(ob, 6)
                make("TextLabel", {
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -26, 1, 0),
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = T.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 202,
                }, ob)
                local chk = make("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Size = UDim2.new(0, 13, 0, 13),
                    BackgroundTransparency = 1,
                    Text = "✓",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = T.Accent,
                    TextTransparency = 1,
                    ZIndex = 202,
                }, ob)
                ob.MouseEnter:Connect(function() tw(ob, {BackgroundTransparency = 0},   0.1) end)
                ob.MouseLeave:Connect(function() tw(ob, {BackgroundTransparency = 0.5}, 0.1) end)
                ob.MouseButton1Click:Connect(function()
                    if multi then
                        if sel[opt] then
                            sel[opt] = nil
                            tw(chk, {TextTransparency = 1}, 0.1)
                        else
                            sel[opt] = true
                            tw(chk, {TextTransparency = 0}, 0.1)
                        end
                    else
                        sel = opt
                        open = false
                        tw(dropBg, {Size = UDim2.new(1, 0, 0, 0)},  0.16)
                        tw(cont,   {Size = UDim2.new(1, 0, 0, 36)}, 0.16)
                        tw(arr,    {Rotation = 0},                   0.16)
                    end
                    if flag then gui.Flags[flag] = sel end
                    updSel()
                    spawn(callback or function() end, sel) -- FIX
                end)
            end

            make("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 212,
            }, hdr).MouseButton1Click:Connect(function()
                open = not open
                tw(dropBg, {Size = UDim2.new(1, 0, 0, open and maxH or 0)}, 0.18)
                tw(cont,   {Size = UDim2.new(1, 0, 0, open and 36+maxH+4 or 36)}, 0.18)
                tw(arr,    {Rotation = open and 180 or 0}, 0.18)
            end)

            reg(cont, label)
            return self
        end

        function tab:Input(label, placeholder, flag, callback, numeric)
            local f = make("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = T.Surface,
                ZIndex = 104,
            }, page)
            corner(f, 8)
            stroke(f, T.Border, 1, 0.62)
            f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.SurfaceHov}, 0.1) end)
            f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.Surface},    0.1) end)

            make("TextLabel", {
                Position = UDim2.new(0, 12, 0, 4),
                Size = UDim2.new(1, -24, 0, 17),
                BackgroundTransparency = 1,
                Text = label,
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 105,
            }, f)

            local box = make("TextBox", {
                Position = UDim2.new(0, 12, 0, 26),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundColor3 = T.Bg2,
                Text = "",
                PlaceholderText = placeholder or "Type here…",
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = T.Text,
                PlaceholderColor3 = T.TextDim,
                ClearTextOnFocus = false,
                ZIndex = 105,
            }, f)
            corner(box, 6)
            pad(box, 0, 0, 8, 8)

            local fstroke
            box.Focused:Connect(function()
                fstroke = stroke(box, T.Accent, 1)
            end)
            box.FocusLost:Connect(function()
                local v = numeric and (tonumber(box.Text) or 0) or box.Text
                if flag then gui.Flags[flag] = v end
                spawn(callback or function() end, v) -- FIX
                if fstroke then fstroke:Destroy(); fstroke = nil end
            end)

            reg(f, label)
            return self
        end

        function tab:Color(label, default, flag, callback)
            default = default or Color3.fromRGB(255, 80, 80)
            local h, s, v = Color3.toHSV(default)
            local cur = default
            if flag then gui.Flags[flag] = cur end
            local popen = false
            local PH = 152

            local cont = make("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = T.Surface,
                ClipsDescendants = false,
                ZIndex = 104,
            }, page)
            corner(cont, 8)
            stroke(cont, T.Border, 1, 0.62)

            local hdr = make("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex = 105,
            }, cont)
            make("TextLabel", {
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = label,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 105,
            }, hdr)

            local prev = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 21, 0, 21),
                BackgroundColor3 = cur,
                ZIndex = 105,
            }, hdr)
            corner(prev, 6)
            stroke(prev, T.Border, 1, 0.4)

            local panel = make("Frame", {
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = T.Bg2,
                ClipsDescendants = true,
                ZIndex = 300,
            }, cont)
            corner(panel, 8)
            stroke(panel, T.Border, 1, 0.42)
            shadow(panel, 14, 0.52)

            local svSz = 94
            local svf = make("Frame", {
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(0, svSz, 0, svSz),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                ZIndex = 301,
            }, panel)
            corner(svf, 4)
            local sg = Instance.new("UIGradient", svf)
            sg.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            })
            sg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            local bk = make("Frame", {Size=UDim2.new(1,0,1,0), ZIndex=302}, svf)
            corner(bk, 4)
            local bkg = Instance.new("UIGradient", bk)
            bkg.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
            })
            bkg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            bkg.Rotation = 90

            local svc = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(s, 0, 1-v, 0),
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 303,
            }, svf)
            corner(svc, 5)
            stroke(svc, Color3.new(0,0,0), 1)

            local hbar = make("Frame", {
                Position = UDim2.new(0, svSz+18, 0, 10),
                Size = UDim2.new(0, 15, 0, svSz),
                ZIndex = 301,
            }, panel)
            corner(hbar, 4)
            local hg = Instance.new("UIGradient", hbar)
            hg.Rotation = 90
            hg.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
                ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
            })

            local hcur = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, h, 0),
                Size = UDim2.new(1, 4, 0, 4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 302,
            }, hbar)
            corner(hcur, 2)
            stroke(hcur, Color3.new(0,0,0), 1)

            local function toHex(c)
                return string.format("#%02X%02X%02X",
                    math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
            end

            local hexBox = make("TextBox", {
                Position = UDim2.new(0, 10, 0, svSz+14),
                Size = UDim2.new(0, svSz+23, 0, 22),
                BackgroundColor3 = T.Surface,
                Text = toHex(cur),
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = T.Text,
                ZIndex = 301,
            }, panel)
            corner(hexBox, 6)
            pad(hexBox, 0, 0, 8, 8)

            local function upd()
                cur = Color3.fromHSV(h, s, v)
                prev.BackgroundColor3 = cur
                svf.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
                svc.Position  = UDim2.new(s, 0, 1-v, 0)
                hcur.Position = UDim2.new(0.5, 0, h, 0)
                hexBox.Text   = toHex(cur)
                if flag then gui.Flags[flag] = cur end
                spawn(callback or function() end, cur) -- FIX
            end

            local svd, hd = false, false

            make("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=304,
            }, svf).InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svd = true end
            end)
            make("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=303,
            }, hbar).InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hd = true end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svd=false; hd=false end
            end)
            UIS.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if svd then
                    local ap=svf.AbsolutePosition; local as=svf.AbsoluteSize
                    s = math.clamp((mouse.X-ap.X)/as.X, 0, 1)
                    v = 1 - math.clamp((mouse.Y-ap.Y)/as.Y, 0, 1)
                    upd()
                elseif hd then
                    local ap=hbar.AbsolutePosition; local as=hbar.AbsoluteSize
                    h = math.clamp((mouse.Y-ap.Y)/as.Y, 0, 1)
                    upd()
                end
            end)

            make("TextButton", {
                Size=UDim2.new(1,0,0,36), BackgroundTransparency=1, Text="", ZIndex=306,
            }, hdr).MouseButton1Click:Connect(function()
                popen = not popen
                tw(panel, {Size = UDim2.new(1, 0, 0, popen and PH or 0)}, 0.18)
                tw(cont,  {Size = UDim2.new(1, 0, 0, popen and 36+PH+4 or 36)}, 0.18)
            end)

            reg(cont, label)
            return self
        end

        function tab:Bind(label, default, flag, callback)
            default = default or Enum.KeyCode.Unknown
            local cur       = default
            local listening = false
            if flag then gui.Flags[flag] = cur end

            local f = makeRow(page, label)
            local kb = make("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 80, 0, 23),
                BackgroundColor3 = T.Surface,
                Text = "[" .. cur.Name .. "]",
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = T.Accent,
                ZIndex = 105,
            }, f)
            corner(kb, 6)
            stroke(kb, T.Border, 1, 0.5)

            kb.MouseButton1Click:Connect(function()
                listening = true
                kb.Text = "…"
                kb.TextColor3 = T.Warn
            end)
            UIS.InputBegan:Connect(function(i, gp)
                if not gp and listening and i.UserInputType == Enum.UserInputType.Keyboard then
                    cur = i.KeyCode
                    if flag then gui.Flags[flag] = cur end
                    kb.Text = "[" .. cur.Name .. "]"
                    kb.TextColor3 = T.Accent
                    listening = false
                    spawn(callback or function() end, cur) -- FIX
                elseif not gp and not listening and i.KeyCode == cur then
                    spawn(callback or function() end, cur) -- FIX
                end
            end)

            reg(f, label)
            return self
        end

        function tab:Label(text)
            local l = make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = text or "",
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = T.TextDim,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 104,
            }, page)
            reg(l, text)
            return self
        end

        function tab:Section(title)
            local f = make("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 104,
            }, page)
            make("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0.33, 0, 0, 1),
                BackgroundColor3 = T.Border,
                BorderSizePixel = 0,
                ZIndex = 104,
            }, f)
            make("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0.34, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = title or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = T.TextDim,
                ZIndex = 104,
            }, f)
            make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.33, 0, 0, 1),
                BackgroundColor3 = T.Border,
                BorderSizePixel = 0,
                ZIndex = 104,
            }, f)
            reg(f, title)
            return self
        end

        function tab:Para(title, body)
            local f = make("Frame", {
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = T.Surface,
                ZIndex = 104,
            }, page)
            corner(f, 8)
            stroke(f, T.Border, 1, 0.62)
            pad(f, 8, 8, 12, 12)
            list(f, 4)

            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = title or "",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 105,
            }, f)
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = body or "",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = T.TextMute,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = 105,
            }, f)

            spawn(function() -- FIX: task.defer → spawn
                local bounds = TXT:GetTextSize(body or "", 11, Enum.Font.Gotham,
                    Vector2.new(math.max(f.AbsoluteSize.X - 24, 1), 9999))
                f.Size = UDim2.new(1, 0, 0, 34 + bounds.Y)
            end)

            reg(f, title)
            return self
        end

        return tab
    end

    return gui
end
local workspace = game:GetService("Workspace")
local localPlayer = game.Players.LocalPlayer

local gui = GlareUI({
    Title    = "Speed",
    SubTitle = "v1.0",
    Theme    = "Dark",
    Key      = Enum.KeyCode.RightShift,
    Size     = {560, 400}
})

local function teleportToObject(object)
    -- 1. Essential Character Guards
    local character = localPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- 2. Guard against a totally missing or nil object
    if not object then return end 

    -- 3. If it's a standard Part / MeshPart / Truss (BasePart)
    if object:IsA("BasePart") then
        hrp.CFrame = object.CFrame + Vector3.new(0, 3, 0)
        return
    end
    
    -- 4. If it's a Model (Character, Map Asset, Orb Group, etc.)
    if object:IsA("Model") then
        -- Try PrimaryPart first
        if object.PrimaryPart then
            hrp.CFrame = object.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
            return
        end
        
        -- Fallback: Look for any part inside the model
        local anyPart = object:FindFirstChildWhichIsA("BasePart", true) -- true = recursive search
        if anyPart then
            hrp.CFrame = anyPart.CFrame + Vector3.new(0, 3, 0)
            return
        end
        
        -- Ultimate Modern Fallback: Use its bounding box pivot point
        hrp.CFrame = object:GetPivot() + Vector3.new(0, 3, 0)
        return
    end
    
    -- 5. If it's a Folder, Tool, or any other Instance (Deep Search)
    -- It will search deep inside the hierarchy until it finds a valid part to land on
    local deepPart = object:FindFirstChildWhichIsA("BasePart", true)
    if deepPart then
        hrp.CFrame = deepPart.CFrame + Vector3.new(0, 3, 0)
        return
    end
    
    -- 6. Last resort: If it has a pivot point property (Configuration, Attachment, etc.)
    local success, pivotCF = pcall(function() return object:GetPivot() end)
    if success and pivotCF then
        hrp.CFrame = pivotCF + Vector3.new(0, 3, 0)
        return
    end
    
    warn("Teleport failed: Object type '" .. object.ClassName .. "' contains no visual parts or positional data.")
end

local function tpToOrbs()
    local orbFolder = workspace:WaitForChild("orbFolder")
    for _, city in ipairs(orbFolder:GetChildren()) do   -- GetChildren(), capital G
        if city:IsA("Folder") then
            for _, orb in ipairs(city:GetChildren()) do
                if orb:IsA("Model") then
                    teleportToObject(orb)
                    task.wait(0.1)  -- task.wait() is preferred over wait()
                end
            end
        end
    end
end

local function tpToHoops()
    local orbFolder = workspace:WaitForChild("Hoops")
    for _, hoop in ipairs(orbFolder:GetChildren()) do   -- GetChildren(), capital G
        teleportToObject(hoop)
        task.wait(0.1)
    end
end
local teleport = gui:Tab("Teleports")
teleport:Button("Collect Orbs", tpToOrbs)
teleport:Button("Collect Hoops", tpToHoops)
