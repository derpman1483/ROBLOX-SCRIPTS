--[[
    NANITE  v2.0
]]

-- ─────────────────────────────────────────────────────────────────────────────
if not game:IsLoaded() then game.Loaded:Wait() end

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StatsService     = game:GetService("Stats")
local GuiService       = game:GetService("GuiService")
local VirtualUser      = game:GetService("VirtualUser")
local Lighting         = game:GetService("Lighting")

-- ── Core refs ─────────────────────────────────────────────────────────────────
local LP      = Players.LocalPlayer
local Cam     = workspace.CurrentCamera
local Mouse   = LP:GetMouse()
local PlaceId = game.PlaceId
local JobId   = game.JobId

-- ── State ─────────────────────────────────────────────────────────────────────
local barOpen       = false
local openPanel     = nil      -- name of currently open panel, or nil
local checkingKey   = false    -- false | { kb = keybindTable, box = TextBox }
local noclipDef     = {}
local movers        = {}
local espConns      = {}
local notifs        = {}
local spectateTarget = nil     -- Player currently being spectated, or nil
local ghostDef      = {}       -- original transparencies for Ghost

-- ── Actions config ────────────────────────────────────────────────────────────
local ACTIONS = {
    { name = "Noclip",       color = Color3.fromRGB(0,   200, 140), en = false },
    { name = "Flight",       color = Color3.fromRGB(200, 60,  60 ), en = false },
    { name = "Invulnerable", color = Color3.fromRGB(200, 60,  120), en = false },
    { name = "ESP",          color = Color3.fromRGB(220, 180, 0  ), en = false },
    { name = "Click-TP",     color = Color3.fromRGB(100, 80,  200), en = false },
    { name = "Respawn",      color = Color3.fromRGB(60,  100, 200), en = false },
    { name = "Inf Jump",     color = Color3.fromRGB(0,   180, 200), en = false },
    { name = "Anti-AFK",     color = Color3.fromRGB(180, 100, 0  ), en = false },
    { name = "Ghost",        color = Color3.fromRGB(160, 160, 160), en = false },
    { name = "Spin",         color = Color3.fromRGB(200, 60,  200), en = false },
    { name = "Bhop",         color = Color3.fromRGB(0,   210, 255), en = false },
    { name = "Freeze",       color = Color3.fromRGB(80,  160, 220), en = false },
    { name = "No Fall",      color = Color3.fromRGB(230, 120, 0  ), en = false },
    { name = "Fling",        color = Color3.fromRGB(220, 40,  40 ), en = false },
    { name = "Fullbright",   color = Color3.fromRGB(255, 230, 80 ), en = false },
    { name = "Zoom Hack",    color = Color3.fromRGB(60,  200, 120), en = false },
}

local ACT_MAP = {}
for _, act in ipairs(ACTIONS) do ACT_MAP[act.name] = act end
local function getAction(name) return ACT_MAP[name] end

-- ── Sliders config ────────────────────────────────────────────────────────────
local SLIDERS = {
    { name = "Walk Speed",    color = Color3.fromRGB(44,  153, 93 ),
      lo = 0,  hi = 300, def = 16,  val = 16,  active = false,
      fn = function(v)
          local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
          if h then h.WalkSpeed = v end
      end },
    { name = "Jump Power",    color = Color3.fromRGB(59,  126, 184),
      lo = 0,  hi = 350, def = 50,  val = 50,  active = false,
      fn = function(v)
          local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
          if h then if h.UseJumpPower then h.JumpPower = v else h.JumpHeight = v end end
      end },
    { name = "Flight Speed",  color = Color3.fromRGB(177, 45,  45 ),
      lo = 1,  hi = 25,  def = 3,   val = 3,   active = false, fn = function() end },
    { name = "Field of View", color = Color3.fromRGB(198, 178, 75 ),
      lo = 45, hi = 120, def = 70,  val = 70,  active = false,
      fn = function(v)
          TweenService:Create(Cam, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), { FieldOfView = v }):Play()
      end },
    { name = "Gravity",       color = Color3.fromRGB(120, 80,  200),
      lo = 0,  hi = 500, def = 196, val = 196, active = false,
      fn = function(v) workspace.Gravity = v end },
}

-- ── Keybinds config ───────────────────────────────────────────────────────────
local KEYBINDS = {
    { name = "Toggle Bar",   id = "togglebar", cur = "RightControl" },
    { name = "Noclip",       id = "noclip",    cur = nil },
    { name = "Flight",       id = "flight",    cur = nil },
    { name = "Invulnerable", id = "invuln",    cur = nil },
    { name = "ESP",          id = "esp",       cur = nil },
    { name = "Click-TP",     id = "clicktp",   cur = nil },
    { name = "Respawn",      id = "respawn",   cur = nil },
}

-- ── Theme ─────────────────────────────────────────────────────────────────────
local BG  = Color3.fromRGB(10,  10,  10 )
local BG2 = Color3.fromRGB(18,  18,  18 )
local BG3 = Color3.fromRGB(26,  26,  26 )
local LN  = Color3.fromRGB(44,  44,  44 )
local TX  = Color3.fromRGB(220, 220, 220)
local DM  = Color3.fromRGB(105, 105, 105)
local WHT = Color3.new(1, 1, 1)

-- ── Layout constants ──────────────────────────────────────────────────────────
local SB_H            = 58
local SB_OPEN_Y       = -12
local PANEL_Y         = SB_OPEN_Y - SB_H - 6
local TOGGLE_Y_OPEN   = SB_OPEN_Y - SB_H - 8
local TOGGLE_Y_CLOSED = -4

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function N(cls, parent, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function tw(obj, t, props, style)
    TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint), props):Play()
end

local function drag(obj)
    local active, rel = false, nil
    local offset = Vector2.zero
    local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
    if sg and sg.IgnoreGuiInset then offset = GuiService:GetGuiInset() end

    obj.InputBegan:Connect(function(i, p)
        if p then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            rel    = obj.AbsolutePosition + obj.AbsoluteSize * obj.AnchorPoint
                     - UserInputService:GetMouseLocation()
            active = true
        end
    end)
    local ie = UserInputService.InputEnded:Connect(function(i)
        if active and i.UserInputType == Enum.UserInputType.MouseButton1 then active = false end
    end)
    local rs = RunService.RenderStepped:Connect(function()
        if active and rel then
            local p = UserInputService:GetMouseLocation() + rel + offset
            obj.Position = UDim2.fromOffset(p.X, p.Y)
        end
    end)
    obj.Destroying:Connect(function() ie:Disconnect() rs:Disconnect() end)
end

local function getPing()
    return math.clamp(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue(), 10, 700)
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local guiP = gethui and gethui() or game:GetService("CoreGui")
do
    local old = guiP:FindFirstChild("Nanite")
    if old then old:Destroy() end
    local oldESP = guiP:FindFirstChild("NaniteESP")
    if oldESP then oldESP:Destroy() end
end

local UI   = N("ScreenGui", guiP, {
    Name = "Nanite", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
local espF = N("Folder", guiP, { Name = "NaniteESP" })

-- ── Notifications ─────────────────────────────────────────────────────────────
local notifHolder = N("Frame", UI, {
    Name = "Notifs", Size = UDim2.new(0, 320, 1, 0),
    Position = UDim2.new(0.5, -160, 0, 0),
    BackgroundTransparency = 1, ZIndex = 200,
})

local stopSpectateBtn = N("TextButton", UI, {
    Name = "StopSpectate", Size = UDim2.new(0, 160, 0, 30),
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12),
    BackgroundColor3 = Color3.fromRGB(60, 80, 160), BackgroundTransparency = 0.25,
    BorderSizePixel = 0, Text = "⏹  Stop Spectating", TextColor3 = TX,
    TextSize = 11, Font = Enum.Font.GothamBold, Visible = false, ZIndex = 100,
})
N("UICorner", stopSpectateBtn, { CornerRadius = UDim.new(0, 8) })
N("UIStroke", stopSpectateBtn, { Color = LN, Thickness = 1 })
stopSpectateBtn.MouseButton1Click:Connect(function()
    spectateTarget = nil
    local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then Cam.CameraSubject = h end
    stopSpectateBtn.Visible = false
end)

local function stackNotifs()
    local y = 0
    for i = #notifs, 1, -1 do
        local n = notifs[i]
        if n and n.Parent then
            y = y + n.Size.Y.Offset + (i < #notifs and 5 or 2)
            n:TweenPosition(UDim2.new(0.5, 0, 0, y), "Out", "Quint", 0.45, true)
        end
    end
end

local function notify(title, body)
    task.spawn(function()
        local lines = body and math.ceil(#body / 46) or 0
        local h     = 40 + lines * 14
        local n = N("Frame", notifHolder, {
            Size = UDim2.new(0, 320, 0, h), AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, -0.2, 0), BackgroundColor3 = BG2,
            BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 200,
        })
        N("UICorner", n, { CornerRadius = UDim.new(0, 10) })
        N("UIStroke", n, { Color = LN, Thickness = 1 })
        N("TextLabel", n, {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 12, 0, 9),
            BackgroundTransparency = 1, Text = title, TextColor3 = TX,
            TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
        })
        if body then
            N("TextLabel", n, {
                Size = UDim2.new(1, -16, 0, h - 26), Position = UDim2.new(0, 12, 0, 23),
                BackgroundTransparency = 1, Text = body, TextColor3 = DM,
                TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true, ZIndex = 201,
            })
        end
        local btn = N("TextButton", n, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 202 })
        table.insert(notifs, n); stackNotifs()

        local function dis()
            local i = table.find(notifs, n)
            if i then table.remove(notifs, i) end
            tw(n, 0.3, { Position = UDim2.new(1.5, 0, 0, n.Position.Y.Offset) })
            task.delay(0.35, function() if n.Parent then n:Destroy() end end)
            stackNotifs()
        end

        btn.MouseButton1Click:Connect(dis)
        task.delay(math.clamp(2.5 + (body and #body * 0.05 or 0), 2.5, 9), function() if n.Parent then dis() end end)
    end)
end

-- ── Action toggler logic ──────────────────────────────────────────────────────
local actBtnObjs = {}

local function refreshActBtn(name)
    local act = getAction(name)
    local o = actBtnObjs[name]
    if not o or not act then return end
    if act.en then
        tw(o.frame,  0.35, { BackgroundTransparency = 0.15 })
        tw(o.stroke, 0.35, { Transparency = 0.7 })
    else
        tw(o.frame,  0.25, { BackgroundTransparency = 0.72 })
        tw(o.stroke, 0.25, { Transparency = 0.4 })
    end
end

local function handleActionToggle(actName, state)
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local hrp = c and c:FindFirstChild("HumanoidRootPart")

    if actName == "Flight" then
        if h then h.PlatformStand = state end
    elseif actName == "Invulnerable" then
        if h then
            h.MaxHealth = state and math.huge or 100
            h.Health    = state and math.huge or 100
        end
    elseif actName == "ESP" then
        for _, hl in ipairs(espF:GetChildren()) do hl.Enabled = state end
    elseif actName == "Respawn" then
        if state and h then h:ChangeState(Enum.HumanoidStateType.Dead) end
        task.defer(function() 
            local act = getAction("Respawn")
            if act and act.en then act.en = false; refreshActBtn("Respawn") end
        end)
    elseif actName == "Ghost" then
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    if state then
                        ghostDef[p] = p.Transparency
                        p.Transparency = 0.65
                    elseif ghostDef[p] ~= nil then
                        p.Transparency = ghostDef[p]
                        ghostDef[p] = nil
                    end
                end
            end
        end
    elseif actName == "Freeze" then
        if hrp then hrp.Anchored = state end
    elseif actName == "Fullbright" then
        local act = getAction("Fullbright")
        if state then
            act.oldAmbient = Lighting.Ambient
            act.oldBrightness = Lighting.Brightness
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = act.oldAmbient or Color3.fromRGB(127, 127, 127)
            Lighting.Brightness = act.oldBrightness or 1
        end
    elseif actName == "Zoom Hack" then
        local act = getAction("Zoom Hack")
        if state then
            act.oldZoom = LP.CameraMaxZoomDistance
            LP.CameraMaxZoomDistance = 100000
        else
            LP.CameraMaxZoomDistance = act.oldZoom or 128
        end
    end
end

local function toggleAction(name)
    local act = getAction(name)
    if act then
        act.en = not act.en
        handleActionToggle(name, act.en)
        refreshActBtn(name)
    end
end

-- ── ESP ───────────────────────────────────────────────────────────────────────
local function createEsp(player)
    if player == LP then return end
    local hl = N("Highlight", espF, {
        Name = player.Name, FillTransparency = 1, OutlineTransparency = 0,
        OutlineColor = WHT, Adornee = player.Character, Enabled = getAction("ESP").en,
    })
    if espConns[player] then espConns[player]:Disconnect() end
    espConns[player] = player.CharacterAdded:Connect(function(c) task.wait(); hl.Adornee = c end)
end

local function removeEsp(player)
    if espConns[player] then espConns[player]:Disconnect(); espConns[player] = nil end
    local h = espF:FindFirstChild(player.Name)
    if h then h:Destroy() end
end

-- ── Toggle button ─────────────────────────────────────────────────────────────
local toggleBtn = N("TextButton", UI, {
    Name = "Toggle", Size = UDim2.new(0, 34, 0, 18),
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, TOGGLE_Y_CLOSED),
    BackgroundColor3 = BG2, BorderSizePixel = 0, Text = "▲", TextColor3 = DM,
    TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 50,
})
N("UICorner", toggleBtn, { CornerRadius = UDim.new(0, 6) })
N("UIStroke", toggleBtn, { Color = LN, Thickness = 1 })

-- ── SmartBar ──────────────────────────────────────────────────────────────────
local smartBar = N("Frame", UI, {
    Name = "SmartBar", Size = UDim2.new(0, 560, 0, SB_H),
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 100),
    BackgroundColor3 = BG, BorderSizePixel = 0, Visible = false, ZIndex = 40,
})
N("UICorner", smartBar, { CornerRadius = UDim.new(0, 14) })
N("UIStroke", smartBar, { Color = LN, Thickness = 1 })

local sbTime = N("TextLabel", smartBar, {
    Name = "Time", Size = UDim2.new(0, 55, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "00:00", TextColor3 = DM,
    TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 41,
})

local navRow = N("Frame", smartBar, {
    Name = "NavRow", Size = UDim2.new(1, -80, 1, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1, ZIndex = 41,
})
N("UIListLayout", navRow, {
    FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6),
})

local NAV_DEFS = {
    { name = "Character", label = "CHARACTER" }, { name = "Players", label = "PLAYERS" },
    { name = "Server", label = "SERVER" }, { name = "Settings", label = "SETTINGS" },
}

local navBtns = {}
for _, def in ipairs(NAV_DEFS) do
    local btn = N("Frame", navRow, {
        Name = def.name, Size = UDim2.new(0, 112, 0, 38),
        BackgroundColor3 = BG2, BorderSizePixel = 0, ZIndex = 42,
    })
    N("UICorner", btn, { CornerRadius = UDim.new(0, 10) })
    N("UIStroke", btn, { Name = "Stroke", Color = LN, Thickness = 1 })

    local lbl = N("TextLabel", btn, {
        Name = "Label", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = def.label, TextColor3 = DM, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 43,
    })
    local interact = N("TextButton", btn, {
        Name = "Interact", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 44,
    })
    navBtns[def.name] = { frame = btn, label = lbl, interact = interact }
end

-- ── Dynamic Panel builder ─────────────────────────────────────────────────────
local allPanels = {}

local function buildPanel(name, fixedHeight)
    local isAuto = fixedHeight == nil
    local p = N("Frame", UI, {
        Name = name, Size = UDim2.new(0, 560, 0, fixedHeight or 0),
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 100),
        BackgroundColor3 = BG, BorderSizePixel = 0, Visible = false, ZIndex = 30,
        AutomaticSize = isAuto and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    })
    N("UICorner", p, { CornerRadius = UDim.new(0, 14) })
    N("UIStroke", p, { Color = LN, Thickness = 1 })

    N("TextLabel", p, {
        Name = "Title", Size = UDim2.new(1, -24, 0, 14), Position = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1, Text = string.upper(name), TextColor3 = TX,
        TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31,
    })
    N("Frame", p, {
        Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 32),
        BackgroundColor3 = LN, BorderSizePixel = 0, ZIndex = 31,
    })

    local content = N("Frame", p, {
        Name = "Content", Size = UDim2.new(1, -28, isAuto and 0 or 1, isAuto and 0 or -44),
        Position = UDim2.new(0, 14, 0, 40), BackgroundTransparency = 1, ZIndex = 31,
        AutomaticSize = isAuto and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    })
    
    if isAuto then N("UIPadding", content, { PaddingBottom = UDim.new(0, 14) }) end
    allPanels[name] = p
    return p, content
end

-- ── Character panel (Dynamically Extends) ─────────────────────────────────────
local charPanel, charContent = buildPanel("Character")

N("UIListLayout", charContent, {
    FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Actions Header
local actHeader = N("Frame", charContent, { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 1 })
N("TextLabel", actHeader, {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "ACTIONS",
    TextColor3 = DM, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
})

-- Buttons Grid
local actGrid = N("Frame", charContent, {
    Name = "Grid", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 32,
    LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.Y,
})
N("UIGridLayout", actGrid, {
    CellSize = UDim2.new(0, 78, 0, 52), CellPadding = UDim2.new(0, 6, 0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top,
})

for _, act in ipairs(ACTIONS) do
    local btn = N("Frame", actGrid, {
        Name = act.name, BackgroundColor3 = act.color, BackgroundTransparency = 0.72,
        BorderSizePixel = 0, ZIndex = 33,
    })
    N("UICorner", btn, { CornerRadius = UDim.new(0, 10) })
    local stroke = N("UIStroke", btn, { Name = "S", Color = act.color, Thickness = 1, Transparency = 0.4 })
    N("TextLabel", btn, {
        Size = UDim2.new(1, -4, 1, 0), BackgroundTransparency = 1, Text = act.name,
        TextColor3 = TX, TextSize = 10, Font = Enum.Font.GothamBold, TextWrapped = true, ZIndex = 34,
    })
    local interact = N("TextButton", btn, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 35 })
    actBtnObjs[act.name] = { frame = btn, stroke = stroke }

    interact.MouseButton1Click:Connect(function() toggleAction(act.name) end)
    interact.MouseEnter:Connect(function() if not act.en then tw(btn, 0.25, { BackgroundTransparency = 0.5 }) end end)
    interact.MouseLeave:Connect(function() if not act.en then tw(btn, 0.2, { BackgroundTransparency = 0.72 }) end end)
end

-- Properties Header
local propHeader = N("Frame", charContent, { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 3 })
N("TextLabel", propHeader, {
    Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = "PROPERTIES",
    TextColor3 = DM, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32,
})
local resetBtn = N("TextButton", propHeader, {
    Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0),
    BackgroundTransparency = 1, Text = "RESET", TextColor3 = DM, TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 35,
})

-- Slider Grid
local sliderGrid = N("Frame", charContent, {
    Name = "SliderGrid", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 32,
    LayoutOrder = 4, AutomaticSize = Enum.AutomaticSize.Y,
})
N("UIGridLayout", sliderGrid, {
    CellSize = UDim2.new(0.5, -4, 0, 28), CellPadding = UDim2.new(0, 6, 0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top,
})

for _, sl in ipairs(SLIDERS) do
    local s = N("Frame", sliderGrid, { BackgroundColor3 = sl.color, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 33 })
    N("UICorner", s, { CornerRadius = UDim.new(0, 8) })
    N("UIStroke", s, { Color = sl.color, Thickness = 1, Transparency = 0.5 })

    local prog = N("Frame", s, { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = sl.color, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 34 })
    N("UICorner", prog, { CornerRadius = UDim.new(0, 8) })

    local info = N("TextLabel", s, {
        Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = sl.name .. ": " .. sl.def,
        TextColor3 = TX, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.2, ZIndex = 35,
    })
    local interact = N("TextButton", s, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 36 })

    sl.obj = s; sl.progObj = prog; sl.infoObj = info
    interact.MouseButton1Down:Connect(function() sl.active = true; tw(s, 0.2, { BackgroundTransparency = 0.9 }) end)
    s.MouseEnter:Connect(function() if not sl.active then tw(s, 0.25, { BackgroundTransparency = 0.65 }) end end)
    s.MouseLeave:Connect(function() if not sl.active then tw(s, 0.2, { BackgroundTransparency = 0.8 }) end end)
end

local function updateSlider(sl, mouseX)
    if not (sl.obj and sl.obj.Parent) then return end
    local interact = sl.obj:FindFirstChildWhichIsA("TextButton")
    if not interact then return end
    local L, R = interact.AbsolutePosition.X, interact.AbsolutePosition.X + interact.AbsoluteSize.X
    local inv = math.clamp((mouseX - L) / math.max(R - L, 1), 0, 1)
    local val = math.floor(sl.lo + (sl.hi - sl.lo) * inv + 0.5)
    sl.val = val; sl.progObj.Size = UDim2.new(inv, 0, 1, 0); sl.infoObj.Text = sl.name .. ": " .. val; sl.fn(val)
end

resetBtn.MouseButton1Click:Connect(function()
    for _, sl in ipairs(SLIDERS) do
        if sl.obj and sl.obj.Parent then
            local inv = (sl.def - sl.lo) / math.max(sl.hi - sl.lo, 1)
            sl.val = sl.def; tw(sl.progObj, 0.35, { Size = UDim2.new(inv, 0, 1, 0) })
            sl.infoObj.Text = sl.name .. ": " .. sl.def; sl.fn(sl.def)
        end
    end
    notify("Sliders Reset", "All sliders returned to default values.")
end)
resetBtn.MouseEnter:Connect(function() resetBtn.TextColor3 = TX end)
resetBtn.MouseLeave:Connect(function() resetBtn.TextColor3 = DM end)

-- ── Players panel (Fixed height to respect scrolling rules) ───────────────────
local playersPanel, playersContent = buildPanel("Players", 240)

local searchBox
do
    local sh = N("Frame", playersContent, {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = BG2, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 32,
    })
    N("UICorner", sh, { CornerRadius = UDim.new(0, 8) }); N("UIStroke", sh, { Color = LN, Thickness = 1 })
    N("TextLabel", sh, {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 9, 0.5, -8), BackgroundTransparency = 1, Text = "⌕",
        TextColor3 = DM, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 33,
    })
    searchBox = N("TextBox", sh, {
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Search players...", TextColor3 = TX, PlaceholderColor3 = DM, TextSize = 12, Font = Enum.Font.Gotham,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
    })
end

local playerList = N("ScrollingFrame", playersContent, {
    Name = "List", Size = UDim2.new(1, 0, 1, -38), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = LN, ScrollBarImageTransparency = 0.4,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 32,
})
N("UIListLayout", playerList, { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name })

local function createPlayerEntry(player)
    if playerList:FindFirstChild(player.Name) then return end
    local entry = N("Frame", playerList, {
        Name = player.Name, Size = UDim2.new(1, -4, 0, 42), BackgroundColor3 = BG2, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 33,
    })
    N("UICorner", entry, { CornerRadius = UDim.new(0, 8) }); N("UIStroke", entry, { Color = LN, Thickness = 1, Transparency = 0.3 })

    local av = N("ImageLabel", entry, {
        Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 8, 0.5, -14), BackgroundColor3 = BG3, BackgroundTransparency = 0.5,
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png", ZIndex = 34,
    })
    N("UICorner", av, { CornerRadius = UDim.new(0, 6) })

    N("TextLabel", entry, {
        Size = UDim2.new(0.45, 0, 0, 14), Position = UDim2.new(0, 44, 0.5, -14), BackgroundTransparency = 1, Text = player.DisplayName,
        TextColor3 = TX, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34,
    })
    N("TextLabel", entry, {
        Size = UDim2.new(0.45, 0, 0, 12), Position = UDim2.new(0, 44, 0.5, 2), BackgroundTransparency = 1, Text = "@" .. player.Name,
        TextColor3 = DM, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34,
    })

    if player ~= LP then
        local actRow = N("Frame", entry, { Size = UDim2.new(0, 136, 0, 22), Position = UDim2.new(1, -144, 0.5, -11), BackgroundTransparency = 1, ZIndex = 35 })
        N("UIListLayout", actRow, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center })

        local function mkBtn(lbl, col)
            local b = N("TextButton", actRow, {
                Size = UDim2.new(0, 64, 0, 22), BackgroundColor3 = col, BackgroundTransparency = 0.5, Text = lbl, TextColor3 = TX,
                TextSize = 10, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 36,
            })
            N("UICorner", b, { CornerRadius = UDim.new(0, 6) })
            return b
        end
        local tpBtn = mkBtn("Teleport", Color3.fromRGB(0, 120, 90)); local spBtn = mkBtn("Spectate", Color3.fromRGB(60, 80, 160))

        tpBtn.MouseButton1Click:Connect(function()
            local tr = workspace:FindFirstChild(player.Name) and workspace:FindFirstChild(player.Name):FindFirstChild("HumanoidRootPart")
            local lr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if tr and lr then lr.CFrame = tr.CFrame; notify("Teleported", "Teleported to " .. player.DisplayName) end
        end)
        spBtn.MouseButton1Click:Connect(function()
            local th = workspace:FindFirstChild(player.Name) and workspace:FindFirstChild(player.Name):FindFirstChildOfClass("Humanoid")
            if th then spectateTarget = player; Cam.CameraSubject = th; stopSpectateBtn.Visible = true; notify("Spectating", "Now spectating " .. player.DisplayName) end
        end)
    end
    entry.MouseEnter:Connect(function() tw(entry, 0.2, { BackgroundTransparency = 0.2 }) end)
    entry.MouseLeave:Connect(function() tw(entry, 0.2, { BackgroundTransparency = 0.4 }) end)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(searchBox.Text)
    for _, e in ipairs(playerList:GetChildren()) do
        if e:IsA("Frame") then e.Visible = #q == 0 or string.find(string.lower(e.Name), q, 1, true) ~= nil end
    end
end)

-- ── Server panel ──────────────────────────────────────────────────────────────
local serverPanel, serverContent = buildPanel("Server")
N("UIListLayout", serverContent, { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

local srvVals, srvOrder = {}, 0
local function mkStat(lbl)
    srvOrder += 1
    local row = N("Frame", serverContent, { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = srvOrder, BackgroundColor3 = BG2, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 32 })
    N("UICorner", row, { CornerRadius = UDim.new(0, 6) })
    N("TextLabel", row, { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = lbl, TextColor3 = DM, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33 })
    return N("TextLabel", row, { Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = "—", TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 33 })
end

srvVals.players = mkStat("Players"); srvVals.ping = mkStat("Latency"); srvVals.fps = mkStat("FPS")
srvVals.place   = mkStat("Place ID"); srvVals.job = mkStat("Job ID"); srvVals.gravity = mkStat("Gravity")

local fpsHistory = {}
local function updateServer()
    srvVals.players.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
    srvVals.ping.Text = math.floor(getPing()) .. " ms"; srvVals.place.Text = tostring(PlaceId)
    srvVals.job.Text = string.sub(JobId, 1, 12) .. "…"; srvVals.gravity.Text = tostring(math.floor(workspace.Gravity))
    if #fpsHistory > 0 then local sum = 0 for _, v in ipairs(fpsHistory) do sum += v end srvVals.fps.Text = math.round(sum / #fpsHistory) .. " fps" end
end

-- ── Settings panel (floating, draggable) ─────────────────────────────────────
local settPanel = N("Frame", UI, {
    Name = "Settings", Size = UDim2.new(0, 480, 0, 340), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0),
    BackgroundColor3 = BG, BorderSizePixel = 0, Visible = false, ZIndex = 60,
})
N("UICorner", settPanel, { CornerRadius = UDim.new(0, 14) }); N("UIStroke", settPanel, { Color = LN, Thickness = 1 }); drag(settPanel)

N("TextLabel", settPanel, { Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 14, 0, 12), BackgroundTransparency = 1, Text = "KEYBINDS", TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61 })
N("TextLabel", settPanel, { Size = UDim2.new(1, -20, 0, 11), Position = UDim2.new(0, 14, 0, 26), BackgroundTransparency = 1, Text = "Click a field then press any key to bind.", TextColor3 = DM, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61 })
N("Frame", settPanel, { Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 44), BackgroundColor3 = LN, BorderSizePixel = 0, ZIndex = 61 })

local kbScroll = N("ScrollingFrame", settPanel, {
    Size = UDim2.new(1, -20, 1, -58), Position = UDim2.new(0, 10, 0, 52), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = LN,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 62,
})
N("UIListLayout", kbScroll, { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

for i, kb in ipairs(KEYBINDS) do
    local row = N("Frame", kbScroll, { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = BG2, BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 63 })
    N("UICorner", row, { CornerRadius = UDim.new(0, 8) }); N("UIStroke", row, { Color = LN, Thickness = 1, Transparency = 0.5 })
    N("TextLabel", row, { Size = UDim2.new(0.55, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = kb.name, TextColor3 = TX, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 64 })

    local box = N("TextBox", row, {
        Size = UDim2.new(0, 120, 0, 24), Position = UDim2.new(1, -128, 0.5, -12), BackgroundColor3 = BG3, BackgroundTransparency = 0.3,
        Text = kb.cur or "No Keybind", TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamBold, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center, BorderSizePixel = 0, ZIndex = 64,
    })
    N("UICorner", box, { CornerRadius = UDim.new(0, 6) }); local boxStroke = N("UIStroke", box, { Color = LN, Thickness = 1, Transparency = 0.5 })

    box.Focused:Connect(function() checkingKey = { kb = kb, box = box }; box.Text = "press a key…"; tw(boxStroke, 0.2, { Transparency = 0, Color = Color3.fromRGB(0, 200, 100) }) end)
    box.FocusLost:Connect(function()
        if not checkingKey or checkingKey.kb ~= kb then return end
        checkingKey = false; if box.Text == "press a key…" then box.Text = kb.cur or "No Keybind" end; tw(boxStroke, 0.2, { Transparency = 0.5, Color = LN })
    end)
    row.MouseEnter:Connect(function() tw(row, 0.2, { BackgroundTransparency = 0.2 }) end)
    row.MouseLeave:Connect(function() tw(row, 0.2, { BackgroundTransparency = 0.4 }) end)
end

-- ── Panel Animations ──────────────────────────────────────────────────────────
local function closePanelAnim(name, cb)
    local p = allPanels[name]
    if not p or not p.Visible then if cb then cb() end return end
    tw(p, 0.3, { Position = UDim2.new(0.5, 0, 1, 100) })
    task.delay(0.32, function() p.Visible = false; if cb then cb() end end)
end

local function openPanelAnim(name)
    if openPanel == name then closePanelAnim(name); openPanel = nil; navBtns[name].label.TextColor3 = DM return end
    if openPanel then closePanelAnim(openPanel); navBtns[openPanel].label.TextColor3 = DM end
    openPanel = name; navBtns[name].label.TextColor3 = TX
    local p = allPanels[name]; p.Position = UDim2.new(0.5, 0, 1, 100); p.Visible = true
    tw(p, 0.45, { Position = UDim2.new(0.5, 0, 1, PANEL_Y) }, Enum.EasingStyle.Back)
    if name == "Server" then task.spawn(updateServer) end
end

local function openSettings() settPanel.Size = UDim2.new(0, 480, 0, 0); settPanel.Visible = true; tw(settPanel, 0.4, { Size = UDim2.new(0, 480, 0, 340) }) end
local function closeSettings() tw(settPanel, 0.3, { Size = UDim2.new(0, 480, 0, 0) }); task.delay(0.32, function() settPanel.Visible = false end) end

for name, nb in pairs(navBtns) do
    nb.interact.MouseButton1Click:Connect(function()
        if name == "Settings" then if settPanel.Visible then closeSettings() else openSettings() end else openPanelAnim(name) end
        tw(nb.frame, 0.1, { BackgroundColor3 = BG3 }); task.delay(0.1, function() tw(nb.frame, 0.2, { BackgroundColor3 = BG2 }) end)
    end)
    nb.interact.MouseEnter:Connect(function() tw(nb.frame, 0.2, { BackgroundColor3 = BG3 }) if name ~= openPanel then nb.label.TextColor3 = TX end end)
    nb.interact.MouseLeave:Connect(function() tw(nb.frame, 0.2, { BackgroundColor3 = BG2 }) if name ~= openPanel then nb.label.TextColor3 = DM end end)
end

local function openBar()
    barOpen = true; toggleBtn.Text = "▼"; smartBar.Visible = true
    tw(smartBar, 0.5, { Position = UDim2.new(0.5, 0, 1, SB_OPEN_Y) }, Enum.EasingStyle.Back)
    tw(toggleBtn, 0.4, { Position = UDim2.new(0.5, 0, 1, TOGGLE_Y_OPEN) })
end

local function closeBar()
    barOpen = false; toggleBtn.Text = "▲"
    if openPanel then closePanelAnim(openPanel); openPanel = nil end
    if settPanel.Visible then closeSettings() end
    for _, nb in pairs(navBtns) do nb.label.TextColor3 = DM end
    tw(smartBar, 0.35, { Position = UDim2.new(0.5, 0, 1, 100) }); tw(toggleBtn, 0.3, { Position = UDim2.new(0.5, 0, 1, TOGGLE_Y_CLOSED) })
    task.delay(0.4, function() if not barOpen then smartBar.Visible = false end end)
end
toggleBtn.MouseButton1Click:Connect(function() if barOpen then closeBar() else openBar() end end)

-- ── Input ─────────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if checkingKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            local parts = string.split(tostring(input.KeyCode), ".")
            checkingKey.kb.cur = parts[3]; checkingKey.box.Text = parts[3]
            checkingKey.box:ReleaseFocus(); checkingKey = false
        end
        return
    end
    if processed then return end

    for _, kb in ipairs(KEYBINDS) do
        if kb.cur then
            local ok, kc = pcall(function() return Enum.KeyCode[kb.cur] end)
            if ok and input.KeyCode == kc then
                if kb.id == "togglebar" then
                    if barOpen then closeBar() else openBar() end
                elseif getAction(kb.name) then
                    toggleAction(kb.name)
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        for _, sl in ipairs(SLIDERS) do
            if sl.active then sl.active = false; if sl.obj then tw(sl.obj, 0.25, { BackgroundTransparency = 0.8 }) end end
        end
    end
end)

Mouse.Move:Connect(function() for _, sl in ipairs(SLIDERS) do if sl.active then updateSlider(sl, Mouse.X) end end end)

Mouse.Button1Down:Connect(function()
    if not getAction("Click-TP").en then return end
    if Mouse.Target and Mouse.Target:IsDescendantOf(workspace) then
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not getAction("Inf Jump").en then return end
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

LP.Idled:Connect(function()
    if not getAction("Anti-AFK").en then return end
    VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
end)

-- ── RunService ────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if not UI.Parent then return end
    local char = LP.Character
    if not char then return end

    local noclipOn = getAction("Noclip").en
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if noclipOn then
                if noclipDef[p] == nil then noclipDef[p] = p.CanCollide end
                p.CanCollide = false
            elseif noclipDef[p] ~= nil then
                p.CanCollide = noclipDef[p]
                noclipDef[p] = nil
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not UI.Parent then return end
    local char = LP.Character
    local ppart = char and char.PrimaryPart
    if not ppart then return end

    local bv, bg = movers[1], movers[2]
    if bv then
        local ok = pcall(function() bv.Parent = bv.Parent end)
        if not ok then movers = {}; bv = nil; bg = nil end
    end
    if not bv then
        bv = Instance.new("BodyVelocity"); bv.MaxForce  = Vector3.one * 9e9
        bg = Instance.new("BodyGyro");     bg.MaxTorque = Vector3.one * 9e9; bg.P = 9e4
        movers = { bv, bg }
    end

    if getAction("Flight").en then
        local cf = Cam.CFrame
        local vel = Vector3.zero
        local rot = cf.Rotation
        local speed = SLIDERS[3].val * 45

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cf.LookVector;  rot *= CFrame.Angles(math.rad(-30), 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cf.LookVector;  rot *= CFrame.Angles(math.rad(30), 0, 0)  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cf.RightVector; rot *= CFrame.Angles(0, 0, math.rad(-30)) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cf.RightVector; rot *= CFrame.Angles(0, 0, math.rad(30))  end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then vel += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.yAxis end

        TweenService:Create(bv, TweenInfo.new(0.4), { Velocity = vel * speed }):Play()
        TweenService:Create(bg, TweenInfo.new(0.4), { CFrame = rot }):Play()
        bv.Parent = ppart; bg.Parent = ppart
    else
        bv.Parent = nil; bg.Parent = nil
    end

    if getAction("Invulnerable").en then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.Health = math.huge; h.MaxHealth = math.huge end
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if getAction("Spin").en and hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(8), 0)
    end
    
    if getAction("Fling").en and hrp then
        hrp.RotVelocity = Vector3.new(0, 50000, 0)
    end

    if getAction("Bhop").en then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h and h:GetState() == Enum.HumanoidStateType.Running and h.MoveDirection.Magnitude > 0 then h.Jump = true end
    end

    if getAction("No Fall").en then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h and h:GetState() == Enum.HumanoidStateType.Freefall and hrp and hrp.Velocity.Y < -50 then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z)
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    table.insert(fpsHistory, 1 / dt)
    if #fpsHistory > 12 then table.remove(fpsHistory, 1) end
end)

-- ── Player events ─────────────────────────────────────────────────────────────
for _, p in ipairs(Players:GetPlayers()) do createPlayerEntry(p); createEsp(p) end
Players.PlayerAdded:Connect(function(p) if UI.Parent then createPlayerEntry(p); createEsp(p) end end)
Players.PlayerRemoving:Connect(function(p) removePlayerEntry(p); removeEsp(p); noclipDef = {} end)

-- Re-apply persistant states if Character Respawns
LP.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    if getAction("Invulnerable").en then
        local h = char:WaitForChild("Humanoid", 3)
        if h then h.MaxHealth = math.huge; h.Health = math.huge end
    end
    if getAction("Flight").en then
        local h = char:WaitForChild("Humanoid", 3)
        if h then h.PlatformStand = true end
    end
    if getAction("Freeze").en then
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if hrp then hrp.Anchored = true end
    end
    if getAction("Zoom Hack").en then
        LP.CameraMaxZoomDistance = 100000
    end
end)

-- ── Main loop ─────────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        if not UI.Parent then espF:Destroy(); for _, c in pairs(espConns) do c:Disconnect() end break end
        sbTime.Text = os.date("%H:%M")
        if serverPanel.Visible then updateServer() end
    end
end)

-- ── Start ─────────────────────────────────────────────────────────────────────
task.defer(function()
    task.wait(0.15)
    for _, sl in ipairs(SLIDERS) do
        if sl.obj and sl.obj.Parent then
            local inv = (sl.def - sl.lo) / math.max(sl.hi - sl.lo, 1)
            sl.val = sl.def; sl.progObj.Size = UDim2.new(inv, 0, 1, 0)
            sl.infoObj.Text = sl.name .. ": " .. sl.def; sl.fn(sl.def)
        end
    end
end)

openBar()
notify("Nanite loaded", "RightControl to toggle. Assign keybinds in Settings.")
