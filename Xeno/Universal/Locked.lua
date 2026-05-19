-- ╔══════════════════════════════════════════════════════╗
-- ║        XENO-INSPIRED EXECUTOR UI  ·  LocalScript     ║
-- ║        v2.0 — Sidebar + Server Tab + EOS Scope       ║
-- ╚══════════════════════════════════════════════════════╝
print(("starting"))
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local HttpService      = game:GetService("HttpService")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  AUTOEXEC FIX: Wait for the game to fully load
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FILE SYSTEM SAFETIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function readfile_json()
    if isfile and isfile("exec/config.json") then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile("exec/config.json"))
        end)
        if success then return result end
        warn("[Xeno UI] Failed to decode config.json:", result)
    end
    return {}
end

local function writefile_json(data)
    if isfolder and not isfolder("exec") then
        makefolder("exec")
    end
    if writefile then
        writefile("exec/config.json", HttpService:JSONEncode(data))
    end
end   

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  THEME
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local T = {
    Bg          = Color3.fromRGB(12,  12,  17),
    Surface     = Color3.fromRGB(19,  19,  27),
    SurfaceAlt  = Color3.fromRGB(25,  25,  36),
    Border      = Color3.fromRGB(38,  38,  56),
    Accent      = Color3.fromRGB(82,  130, 255),
    AccentDark  = Color3.fromRGB(48,  82,  175),
    AccentLight = Color3.fromRGB(115, 160, 255),
    Success     = Color3.fromRGB(55,  200, 115),
    Warning     = Color3.fromRGB(255, 178, 55),
    Danger      = Color3.fromRGB(218, 65,  65),
    Text        = Color3.fromRGB(218, 223, 240),
    TextDim     = Color3.fromRGB(115, 120, 148),
    TextMuted   = Color3.fromRGB(60,  65,  90),
    TabOn       = Color3.fromRGB(26,  26,  38),
    TabOff      = Color3.fromRGB(16,  16,  24),
    BtnHover    = Color3.fromRGB(32,  32,  48),
    SidebarBg   = Color3.fromRGB(14,  14,  20),
    SidebarSel  = Color3.fromRGB(22,  22,  34),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE & CONFIG LOADING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local tabs         = {}
local activeTabId  = nil
local tabCounter   = 0
local savedScripts = {}
local eosScripts   = {}   
local minimized    = false
local activePage   = "executor"
local saveConfig   -- Forward declaration so all functions can use it safely

local configData = readfile_json()

if configData.eos then
    for key, value in pairs(configData.eos) do
        eosScripts[tonumber(key) or key] = {code = value.code, scope = value.scope}
    end
end

if configData.saved then
    for key, value in pairs(configData.saved) do
        savedScripts[key] = value
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function New(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end
local function corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end
local function stroke(col, thick, p)
    local s = Instance.new("UIStroke"); s.Color = col or T.Border
    s.Thickness = thick or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function pad(t, b, l, r, p)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0,t or 0); u.PaddingBottom = UDim.new(0,b or 0)
    u.PaddingLeft = UDim.new(0,l or 0); u.PaddingRight = UDim.new(0,r or 0); u.Parent = p
end
local function tw(obj, goal, dur, style, dir)
    TweenService:Create(obj, TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal):Play()
end
local function ripple(btn)
    local r = New("Frame", {BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=0.82,
        BorderSizePixel=0, Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5), ZIndex=btn.ZIndex+6, Parent=btn})
    corner(999, r); tw(r, {Size=UDim2.new(2,0,2,0), BackgroundTransparency=1}, 0.4)
    task.delay(0.4, function() r:Destroy() end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TOAST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function notify(text, col)
    local gui = New("ScreenGui", {Name="XenoToast", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui})
    local box = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
        Size=UDim2.new(0,270,0,46), Position=UDim2.new(1,20,1,-64),
        BackgroundTransparency=0.05, Parent=gui})
    corner(8, box); stroke(col or T.Accent, 1, box)
    New("Frame", {BackgroundColor3=col or T.Accent, BorderSizePixel=0, Size=UDim2.new(0,3,1,0), Parent=box})
    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-18,1,0), Position=UDim2.new(0,14,0,0),
        Font=Enum.Font.GothamMedium, Text=text, TextColor3=T.Text, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=box})
    tw(box, {Position=UDim2.new(1,-280,1,-64)}, 0.28, Enum.EasingStyle.Back)
    task.delay(2.8, function()
        tw(box, {Position=UDim2.new(1,20,1,-64)}, 0.22)
        task.delay(0.25, function() gui:Destroy() end)
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SCREEN GUI + MAIN FRAME
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local GUI = New("ScreenGui", {Name="XenoExecutor", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui})

local WIN_W, WIN_H = 700, 440

local Glow = New("Frame", {BackgroundColor3=T.Accent, BackgroundTransparency=0.88, BorderSizePixel=0,
    Size=UDim2.new(0,WIN_W+28,0,WIN_H+28),
    Position=UDim2.new(0.5,-(WIN_W+28)/2, 0.5,-(WIN_H+28)/2), ZIndex=0, Parent=GUI})
corner(16, Glow)

local Main = New("Frame", {Name="Main", BackgroundColor3=T.Bg, BorderSizePixel=0,
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    ClipsDescendants=true, ZIndex=1, Parent=GUI})
corner(10, Main)
stroke(T.Border, 1.5, Main)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TITLE BAR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local TBAR_H = 38
local TBar = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,TBAR_H), ZIndex=5, Parent=Main})
New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), ZIndex=6, Parent=TBar})
New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0,18,0,18),
    Position=UDim2.new(0,12,0.5,-9), Font=Enum.Font.GothamBold,
    Text="✦", TextColor3=T.Accent, TextSize=15, ZIndex=6, Parent=TBar})
New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0,55,1,0),
    Position=UDim2.new(0,34,0,0), Font=Enum.Font.GothamBold,
    Text="XENO", TextColor3=T.Text, TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6, Parent=TBar})
New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0,70,1,0),
    Position=UDim2.new(0,88,0,0), Font=Enum.Font.Gotham,
    Text="executor", TextColor3=T.TextMuted, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6, Parent=TBar})

local function winCircle(xOff, bg, hoverBg, icon)
    local btn = New("TextButton", {BackgroundColor3=bg, BorderSizePixel=0,
        Size=UDim2.new(0,14,0,14), Position=UDim2.new(1,xOff,0.5,-7),
        Font=Enum.Font.GothamBold, Text="", TextColor3=Color3.fromRGB(80,40,40),
        TextSize=9, AutoButtonColor=false, ZIndex=8, Parent=TBar})
    corner(99, btn)
    btn.MouseEnter:Connect(function() btn.Text=icon; tw(btn,{BackgroundColor3=hoverBg},0.1) end)
    btn.MouseLeave:Connect(function() btn.Text=""; tw(btn,{BackgroundColor3=bg},0.1) end)
    return btn
end
local CloseBtn = winCircle(-18, Color3.fromRGB(205,60,60),  Color3.fromRGB(235,80,80),  "✕")
local MinBtn   = winCircle(-40, Color3.fromRGB(190,150,35), Color3.fromRGB(225,180,45), "─")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  DRAGGING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local dragging, dragStart, winStart
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; winStart=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        Main.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset+d.X, winStart.Y.Scale, winStart.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MINIMIZE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function toggleMinimize()
    minimized = not minimized
    if minimized then
        tw(Main, {Size=UDim2.new(0,WIN_W,0,TBAR_H)}, 0.22, Enum.EasingStyle.Quad)
        tw(Glow,  {Size=UDim2.new(0,WIN_W+28,0,66)}, 0.22)
    else
        tw(Main, {Size=UDim2.new(0,WIN_W,0,WIN_H)}, 0.25, Enum.EasingStyle.Back)
        tw(Glow,  {Size=UDim2.new(0,WIN_W+28,0,WIN_H+28)}, 0.25)
    end
end
MinBtn.MouseButton1Click:Connect(function() ripple(MinBtn); toggleMinimize() end)
CloseBtn.MouseButton1Click:Connect(function()
    ripple(CloseBtn)
    tw(Main, {Size=UDim2.new(0,WIN_W,0,0), BackgroundTransparency=1}, 0.18)
    tw(Glow, {BackgroundTransparency=1}, 0.18)
    task.delay(0.2, function() GUI:Destroy() end)
end)
UserInputService.InputBegan:Connect(function(i, processed)
    if processed then return end
    if i.KeyCode == Enum.KeyCode.M then toggleMinimize() end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  LAYOUT CONSTANTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local SIDEBAR_W = 56
local TABBAR_H  = 32
local EOS_H     = 30
local BTN_H     = 46
local CONTENT_Y = TBAR_H                            
local EDITOR_Y  = TBAR_H + TABBAR_H                
local EDITOR_H  = WIN_H - EDITOR_Y - EOS_H - BTN_H 
local EOS_Y     = EDITOR_Y + EDITOR_H              
local BTN_Y     = EOS_Y + EOS_H                    

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  LEFT SIDEBAR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Sidebar = New("Frame", {BackgroundColor3=T.SidebarBg, BorderSizePixel=0,
    Size=UDim2.new(0,SIDEBAR_W,1,-TBAR_H), Position=UDim2.new(0,0,0,TBAR_H),
    ZIndex=10, Parent=Main})
New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0,
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0), ZIndex=11, Parent=Sidebar})

local sidebarBtns = {}

local function makeSideBtn(icon, label, yPos, pageId)
    local btn = New("TextButton", {BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Size=UDim2.new(1,-2,0,54), Position=UDim2.new(0,1,0,yPos),
        AutoButtonColor=false, Text="", ZIndex=11, Parent=Sidebar})

    local selBar = New("Frame", {BackgroundColor3=T.Accent, BorderSizePixel=0,
        Size=UDim2.new(0,3,0,28), Position=UDim2.new(0,0,0.5,-14),
        ZIndex=12, Visible=false, Parent=btn})
    corner(2, selBar)

    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,26),
        Position=UDim2.new(0,0,0,6), Font=Enum.Font.GothamBold,
        Text=icon, TextColor3=T.TextDim, TextSize=18,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, Parent=btn})

    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
        Position=UDim2.new(0,0,0,32), Font=Enum.Font.Gotham,
        Text=label, TextColor3=T.TextMuted, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=12, Parent=btn})

    btn.MouseEnter:Connect(function() if activePage ~= pageId then tw(btn, {BackgroundTransparency=0.85}, 0.1) end end)
    btn.MouseLeave:Connect(function() if activePage ~= pageId then tw(btn, {BackgroundTransparency=1}, 0.1) end end)

    sidebarBtns[pageId] = {btn=btn, selBar=selBar}
    return btn, selBar
end

local ExecSideBtn, ExecSelBar    = makeSideBtn("⌨", "EXEC",   8,   "executor")
local ServerSideBtn, ServerSelBar = makeSideBtn("◉", "SERVER", 70,  "server")

local function setSidebarActive(pageId)
    for pid, data in pairs(sidebarBtns) do
        if pid == pageId then
            data.selBar.Visible = true
            tw(data.btn, {BackgroundTransparency=0.88}, 0.12)
        else
            data.selBar.Visible = false
            tw(data.btn, {BackgroundTransparency=1}, 0.12)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  EXECUTOR PANEL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ExecutorPanel = New("Frame", {BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,-SIDEBAR_W,1,-TBAR_H), Position=UDim2.new(0,SIDEBAR_W,0,TBAR_H),
    ClipsDescendants=false, ZIndex=2, Parent=Main})

local TabHolder = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,TABBAR_H), Position=UDim2.new(0,0,0,0),
    ClipsDescendants=true, ZIndex=4, Parent=ExecutorPanel})
New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), ZIndex=5, Parent=TabHolder})

local TabStrip = New("ScrollingFrame", {BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,-38,1,0), CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.X, ScrollBarThickness=0,
    ScrollingDirection=Enum.ScrollingDirection.X, ZIndex=4, Parent=TabHolder})
pad(4,4,4,0,TabStrip)
New("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2), Parent=TabStrip})

local AddTabBtn = New("TextButton", {BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(0,28,0,22), Position=UDim2.new(1,-32,0.5,-11),
    Font=Enum.Font.GothamBold, Text="+", TextColor3=T.TextDim, TextSize=16,
    AutoButtonColor=false, ZIndex=5, Parent=TabHolder})
corner(6, AddTabBtn)
AddTabBtn.MouseEnter:Connect(function() tw(AddTabBtn,{BackgroundColor3=T.BtnHover,TextColor3=T.Text},0.1) end)
AddTabBtn.MouseLeave:Connect(function() tw(AddTabBtn,{BackgroundColor3=T.SurfaceAlt,TextColor3=T.TextDim},0.1) end)

local EditorArea = New("Frame", {BackgroundColor3=T.Bg, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,EDITOR_H), Position=UDim2.new(0,0,0,TABBAR_H),
    ClipsDescendants=true, ZIndex=2, Parent=ExecutorPanel})

local Gutter = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(0,36,1,0), ZIndex=3, Parent=EditorArea})
New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0,
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,0,0,0), ZIndex=4, Parent=Gutter})
local GutterNums = New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-4,1,0),
    Font=Enum.Font.Code, TextColor3=T.TextMuted, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Right, TextYAlignment=Enum.TextYAlignment.Top,
    ZIndex=4, Text="1", Parent=Gutter})
pad(8,0,0,4,GutterNums)

local EditorScroll = New("ScrollingFrame", {BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,36,0,0),
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollBarThickness=4, ScrollBarImageColor3=T.Border, ZIndex=2, Parent=EditorArea})
local Editor = New("TextBox", {BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,0,1,0), AutomaticSize=Enum.AutomaticSize.Y,
    Font=Enum.Font.Code, TextColor3=T.Text, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
    ClearTextOnFocus=false, MultiLine=true,
    PlaceholderText="-- Write your script here...",
    PlaceholderColor3=T.TextMuted,
    Text="-- Welcome to Xeno Executor!\nprint(\"Hello, World!\")\n",
    ZIndex=3, Parent=EditorScroll})
pad(8,8,10,10,Editor)

local function updateGutter(text)
    local n = 1
    for _ in text:gmatch("\n") do n += 1 end
    n = math.max(n, 25)
    local t = {}
    for i = 1, n do t[i] = tostring(i) end
    GutterNums.Text = table.concat(t, "\n")
end
Editor:GetPropertyChangedSignal("Text"):Connect(function() updateGutter(Editor.Text) end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SAFE CONFIG SAVER HOOK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Now that Editor exists, we assign the saveConfig function
saveConfig = function()
    -- Sync active text to its tab so changes aren't lost
    if activeTabId and tabs[activeTabId] and Editor then
        tabs[activeTabId].content = Editor.Text
    end

    local dataToSave = {
        eos = {},
        saved = savedScripts,
        tabs = {}
    }
    
    for id, data in pairs(eosScripts) do
        dataToSave.eos[tostring(id)] = data
    end
    for id, tab in pairs(tabs) do
        dataToSave.tabs[tostring(id)] = {
            name = tab.name,
            content = tab.content
        }
    end
    
    pcall(writefile_json, dataToSave)
end

-- Save automatically when you click off the script box
Editor.FocusLost:Connect(function() saveConfig() end)


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  EOS BAR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local EosBar = New("Frame", {BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,EOS_H), Position=UDim2.new(0,0,0,TABBAR_H+EDITOR_H),
    ZIndex=3, Parent=ExecutorPanel})
New("Frame",{BackgroundColor3=T.Border,BorderSizePixel=0,Size=UDim2.new(1,0,0,1),ZIndex=4,Parent=EosBar})
New("Frame",{BackgroundColor3=T.Border,BorderSizePixel=0,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),ZIndex=4,Parent=EosBar})

New("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(0,200,1,0),
    Position=UDim2.new(0,12,0,0), Font=Enum.Font.GothamMedium,
    Text="⚡  Execute on Game Start", TextColor3=T.TextDim, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=EosBar})

local EosPill = New("TextButton",{BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(0,40,0,18), Position=UDim2.new(0,200,0.5,-9),
    Text="", AutoButtonColor=false, ZIndex=6, Parent=EosBar})
corner(9,EosPill); stroke(T.Border,1,EosPill)

local EosThumb = New("Frame",{BackgroundColor3=T.TextMuted, BorderSizePixel=0,
    Size=UDim2.new(0,12,0,12), Position=UDim2.new(0,3,0.5,-6), ZIndex=7, Parent=EosPill})
corner(99,EosThumb)

local EosLabel = New("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(0,260,1,0),
    Position=UDim2.new(0,248,0,0), Font=Enum.Font.Gotham,
    Text="OFF", TextColor3=T.TextMuted, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=EosBar})

local EosPopup = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(0,228,0,102), Position=UDim2.new(0,196,0,-(102+6)),
    Visible=false, ZIndex=30, Parent=EosBar})
corner(10, EosPopup); stroke(T.Border, 1.5, EosPopup)

local EosCaret = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,20,1,-5),
    Rotation=45, ZIndex=29, Parent=EosPopup})
stroke(T.Border, 1.5, EosCaret)

New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-16,0,28),
    Position=UDim2.new(0,8,0,4), Font=Enum.Font.GothamBold,
    Text="When should this run?", TextColor3=T.Text, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=31, Parent=EosPopup})

local function eosOptBtn(label, sub, yOff, accent)
    local btn = New("TextButton", {BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
        Size=UDim2.new(1,-16,0,30), Position=UDim2.new(0,8,0,yOff),
        AutoButtonColor=false, Text="", ClipsDescendants=true, ZIndex=31, Parent=EosPopup})
    corner(6, btn)
    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-10,0,16),
        Position=UDim2.new(0,10,0,3), Font=Enum.Font.GothamMedium,
        Text=label, TextColor3=T.Text, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=32, Parent=btn})
    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-10,0,12),
        Position=UDim2.new(0,10,0,17), Font=Enum.Font.Gotham,
        Text=sub, TextColor3=T.TextMuted, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=32, Parent=btn})
    local dot = New("Frame", {BackgroundColor3=accent or T.Accent, BorderSizePixel=0,
        Size=UDim2.new(0,6,0,6), Position=UDim2.new(1,-14,0.5,-3), ZIndex=32, Parent=btn})
    corner(99, dot)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.BtnHover},0.1) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.SurfaceAlt},0.1) end)
    return btn
end

local EosCurrentBtn = eosOptBtn("This game only",   "Runs in this PlaceId only",    34, T.Success)
local EosAllBtn     = eosOptBtn("All games",        "Runs in every game you join",  68, T.Accent)

local function closeEosPopup()
    tw(EosPopup, {Position=UDim2.new(0,196,0,-(102+6))}, 0.12)
    task.delay(0.13, function() EosPopup.Visible = false end)
end

local function enableEos(scope)
    closeEosPopup()
    if activeTabId and tabs[activeTabId] then
        eosScripts[activeTabId] = { code=Editor.Text, scope=scope }
    end
    tw(EosPill,  {BackgroundColor3=T.AccentDark}, 0.14)
    tw(EosThumb, {Position=UDim2.new(0,25,0.5,-6), BackgroundColor3=T.Accent}, 0.14, Enum.EasingStyle.Back)
    if scope == "current" then
        EosLabel.Text = "ON — this game"; EosLabel.TextColor3 = T.Success
        notify("⚡ Execute on Start: This Game Only", T.Success)
    else
        EosLabel.Text = "ON — all games"; EosLabel.TextColor3 = T.Accent
        notify("⚡ Execute on Start: All Games", T.Accent)
    end
    saveConfig()
end

local function disableEos()
    if activeTabId then eosScripts[activeTabId] = nil end
    tw(EosPill,  {BackgroundColor3=T.SurfaceAlt}, 0.14)
    tw(EosThumb, {Position=UDim2.new(0,3,0.5,-6), BackgroundColor3=T.TextMuted}, 0.14, Enum.EasingStyle.Back)
    EosLabel.Text = "OFF"; EosLabel.TextColor3 = T.TextMuted
    notify("Execute on Start DISABLED", T.Warning)
    saveConfig()
end

local eosPopupOpen = false
EosPill.MouseButton1Click:Connect(function()
    if activeTabId and eosScripts[activeTabId] then
        disableEos(); eosPopupOpen = false; EosPopup.Visible = false; return
    end
    eosPopupOpen = not eosPopupOpen
    if eosPopupOpen then
        EosPopup.Visible = true
        EosPopup.Position = UDim2.new(0,196,0,-(60))
        EosPopup.BackgroundTransparency = 1
        tw(EosPopup, {Position=UDim2.new(0,196,0,-(102+6)), BackgroundTransparency=0}, 0.16, Enum.EasingStyle.Back)
    else
        closeEosPopup()
    end
end)
EosCurrentBtn.MouseButton1Click:Connect(function() ripple(EosCurrentBtn); enableEos("current") end)
EosAllBtn.MouseButton1Click:Connect(function()     ripple(EosAllBtn);     enableEos("all")     end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  BUTTON BAR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local BtnBar = New("Frame",{BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,BTN_H), Position=UDim2.new(0,0,0,TABBAR_H+EDITOR_H+EOS_H),
    ZIndex=3, Parent=ExecutorPanel})
New("Frame",{BackgroundColor3=T.Border,BorderSizePixel=0,Size=UDim2.new(1,0,0,1),ZIndex=4,Parent=BtnBar})

local function makeBtn(label, x, w, bg, tc)
    local orig = bg or T.SurfaceAlt
    local hov  = bg == T.Accent and T.AccentLight or T.BtnHover
    local b = New("TextButton",{BackgroundColor3=orig, BorderSizePixel=0,
        Size=UDim2.new(0,w,0,30), Position=UDim2.new(0,x,0.5,-15),
        Font=Enum.Font.GothamMedium, Text=label, TextColor3=tc or T.TextDim,
        TextSize=12, AutoButtonColor=false, ClipsDescendants=true, ZIndex=5, Parent=BtnBar})
    corner(7, b); stroke(bg == T.Accent and T.AccentDark or T.Border, 1, b)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hov},0.12) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=orig},0.12) end)
    b.MouseButton1Click:Connect(function() ripple(b) end)
    return b
end

local ExecuteBtn = makeBtn("▶  Execute",  10, 116, T.Accent, Color3.new(1,1,1))
local ClearBtn   = makeBtn("⊘  Clear",  134,  84, nil, T.TextDim)
local SaveBtn    = makeBtn("↓  Save",   226,  84, nil, T.TextDim)
local LoadBtn    = makeBtn("↑  Load",   318,  84, nil, T.TextDim)

local StatusLbl = New("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(0,180,1,0),
    Position=UDim2.new(1,-188,0,0), Font=Enum.Font.Gotham,
    Text="v2.0 ✦ ready", TextColor3=T.TextMuted, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5, Parent=BtnBar})
pad(0,0,0,8,StatusLbl)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SERVER INFO PANEL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ServerPanel = New("Frame", {BackgroundColor3=T.Bg, BorderSizePixel=0,
    Size=UDim2.new(1,-SIDEBAR_W,1,-TBAR_H), Position=UDim2.new(0,SIDEBAR_W,0,TBAR_H),
    Visible=false, ZIndex=2, Parent=Main})

local SrvHeader = New("Frame", {BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,40), ZIndex=3, Parent=ServerPanel})
New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0,
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), ZIndex=4, Parent=SrvHeader})
New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,14,0,0),
    Font=Enum.Font.GothamBold, Text="◉  Server Information",
    TextColor3=T.Text, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4, Parent=SrvHeader})

local SrvRefreshBtn = New("TextButton", {BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(0,72,0,24), Position=UDim2.new(1,-82,0.5,-12),
    Font=Enum.Font.GothamMedium, Text="↺  Refresh", TextColor3=T.TextDim, TextSize=11,
    AutoButtonColor=false, ZIndex=5, Parent=SrvHeader})
corner(6, SrvRefreshBtn)
SrvRefreshBtn.MouseEnter:Connect(function() tw(SrvRefreshBtn,{BackgroundColor3=T.BtnHover,TextColor3=T.Text},0.1) end)
SrvRefreshBtn.MouseLeave:Connect(function() tw(SrvRefreshBtn,{BackgroundColor3=T.SurfaceAlt,TextColor3=T.TextDim},0.1) end)

local SrvScroll = New("ScrollingFrame", {BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,0,1,-40), Position=UDim2.new(0,0,0,40),
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollBarThickness=4, ScrollBarImageColor3=T.Border, ZIndex=3, Parent=ServerPanel})
pad(8,8,10,10,SrvScroll)
local SrvLayout = New("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6), Parent=SrvScroll})

local srvRowOrder = 0
local function srvSection(title)
    srvRowOrder += 1
    local f = New("Frame", {BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,0,0,22), LayoutOrder=srvRowOrder, ZIndex=4, Parent=SrvScroll})
    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Font=Enum.Font.GothamBold, Text=title:upper(), TextColor3=T.Accent, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=f})
    New("Frame", {BackgroundColor3=T.Border, BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), ZIndex=5, Parent=f})
end

local infoLabels = {}
local function srvRow(key, defaultVal)
    srvRowOrder += 1
    local row = New("Frame", {BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0, Size=UDim2.new(1,0,0,26), LayoutOrder=srvRowOrder, ZIndex=4, Parent=SrvScroll})
    corner(5, row)
    New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0.45,0,1,0), Position=UDim2.new(0,10,0,0), Font=Enum.Font.GothamMedium, Text=key, TextColor3=T.TextDim, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=row})
    local valLbl = New("TextLabel", {BackgroundTransparency=1, Size=UDim2.new(0.55,-10,1,0), Position=UDim2.new(0.45,0,0,0), Font=Enum.Font.Code, Text=tostring(defaultVal or "—"), TextColor3=T.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=5, Parent=row})
    infoLabels[key] = valLbl
    return valLbl
end

srvSection("Game"); srvRow("Place Name"); srvRow("Place ID"); srvRow("Place Version"); srvRow("Game (Universe) ID"); srvRow("Job ID (Server)"); srvRow("VIP Server")
srvSection("Players"); srvRow("Your Username"); srvRow("Your Display Name"); srvRow("Your User ID"); srvRow("Player Count"); srvRow("Max Players"); srvRow("Players Online")
srvSection("Performance"); srvRow("Client FPS"); srvRow("Physics FPS"); srvRow("Server Heartbeat"); srvRow("Ping (ms)"); srvRow("Data Send (KB/s)"); srvRow("Data Recv (KB/s)")
srvSection("Environment"); srvRow("Workspace Gravity"); srvRow("Distributed Time"); srvRow("Lighting Brightness"); srvRow("Fog End"); srvRow("Ambient"); srvRow("Time of Day")
srvSection("Security"); srvRow("Filtering Enabled"); srvRow("Allow HTTP Requests"); srvRow("Studio Mode"); srvRow("Experimental Mode")

local function refreshServerInfo()
    local ok, pname = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    infoLabels["Place Name"].Text  = ok and pname or game.Name
    infoLabels["Place ID"].Text    = tostring(game.PlaceId)
    infoLabels["Place Version"].Text = tostring(game.PlaceVersion)
    infoLabels["Game (Universe) ID"].Text = tostring(game.GameId)
    infoLabels["Job ID (Server)"].Text = game.JobId ~= "" and game.JobId:sub(1,18).."…" or "Studio/local"
    infoLabels["VIP Server"].Text = tostring(game.VIPServerId ~= "")

    infoLabels["Your Username"].Text     = LocalPlayer.Name
    infoLabels["Your Display Name"].Text = LocalPlayer.DisplayName
    infoLabels["Your User ID"].Text      = tostring(LocalPlayer.UserId)
    local allPlayers = Players:GetPlayers()
    infoLabels["Player Count"].Text = tostring(#allPlayers)
    infoLabels["Max Players"].Text  = tostring(Players.MaxPlayers)
    local names = {}
    for _, p in ipairs(allPlayers) do table.insert(names, p.Name) end
    infoLabels["Players Online"].Text = table.concat(names, ", ")

    local ok2, ping = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"].Value) end)
    infoLabels["Ping (ms)"].Text = ok2 and tostring(ping) or "N/A"

    local ok3, send = pcall(function() return string.format("%.1f", Stats.Network.ServerStatsItem["Data Send"].Value/1024) end)
    infoLabels["Data Send (KB/s)"].Text = ok3 and send or "N/A"

    local ok4, recv = pcall(function() return string.format("%.1f", Stats.Network.ServerStatsItem["Data Receive"].Value/1024) end)
    infoLabels["Data Recv (KB/s)"].Text = ok4 and recv or "N/A"

    local ok5, physfps = pcall(function() return math.round(workspace:GetRealPhysicsFPS()) end)
    infoLabels["Physics FPS"].Text = ok5 and tostring(physfps) or "N/A"
    infoLabels["Server Heartbeat"].Text = "~60 Hz (server-side)"

    infoLabels["Workspace Gravity"].Text   = tostring(workspace.Gravity)
    infoLabels["Distributed Time"].Text    = string.format("%.1f s", workspace.DistributedGameTime)
    infoLabels["Lighting Brightness"].Text = string.format("%.2f", game:GetService("Lighting").Brightness)
    infoLabels["Fog End"].Text             = string.format("%.0f", game:GetService("Lighting").FogEnd)
    infoLabels["Ambient"].Text             = tostring(game:GetService("Lighting").Ambient)
    infoLabels["Time of Day"].Text         = game:GetService("Lighting").TimeOfDay

    local ok6, fe = pcall(function() return tostring(workspace.FilteringEnabled) end)
    infoLabels["Filtering Enabled"].Text = ok6 and fe or "N/A"
    local ok7, http = pcall(function() return tostring(game:GetService("HttpService").HttpEnabled) end)
    infoLabels["Allow HTTP Requests"].Text = ok7 and http or "N/A"
    infoLabels["Studio Mode"].Text         = tostring(RunService:IsStudio())
    local ok8, exp = pcall(function() return tostring(game.IsContentLoaded) end)
    infoLabels["Experimental Mode"].Text   = ok8 and exp or "N/A"

    notify("Server info refreshed", T.Success)
end

local fpsCount, fpsClock = 0, 0
RunService.RenderStepped:Connect(function(dt)
    fpsCount += 1
    fpsClock += dt
    if fpsClock >= 1 then
        if activePage == "server" and infoLabels["Client FPS"] then
            infoLabels["Client FPS"].Text = tostring(fpsCount) .. " fps"
        end
        fpsCount = 0; fpsClock = 0
    end
end)

SrvRefreshBtn.MouseButton1Click:Connect(function() ripple(SrvRefreshBtn); refreshServerInfo() end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  PAGE SWITCHING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function switchPage(pageId)
    activePage = pageId
    setSidebarActive(pageId)
    ExecutorPanel.Visible = (pageId == "executor")
    ServerPanel.Visible   = (pageId == "server")
    if pageId == "server" then refreshServerInfo() end
end

ExecSideBtn.MouseButton1Click:Connect(function()   switchPage("executor") end)
ServerSideBtn.MouseButton1Click:Connect(function() switchPage("server")   end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SAVE / LOAD MODAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ModalBg = New("Frame",{BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.45,
    BorderSizePixel=0, Size=UDim2.new(1,0,1,0), Visible=false, ZIndex=18, Parent=GUI})
local Modal = New("Frame",{BackgroundColor3=T.Surface, BorderSizePixel=0,
    Size=UDim2.new(0,300,0,360), Position=UDim2.new(0.5,-150,0.5,-180),
    Visible=false, ZIndex=20, Parent=GUI})
corner(10,Modal); stroke(T.Border,1.5,Modal)

local ModalTitleLbl = New("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(1,-38,0,38),
    Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamBold,
    Text="💾  Save Script", TextColor3=T.Text, TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21, Parent=Modal})
local ModalX = New("TextButton",{BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-30,0,8),
    Font=Enum.Font.GothamBold, Text="✕", TextColor3=T.TextDim,
    TextSize=11, AutoButtonColor=false, ZIndex=22, Parent=Modal})
corner(6,ModalX)
ModalX.MouseEnter:Connect(function() tw(ModalX,{BackgroundColor3=T.Danger,TextColor3=T.Text},0.1) end)
ModalX.MouseLeave:Connect(function() tw(ModalX,{BackgroundColor3=T.SurfaceAlt,TextColor3=T.TextDim},0.1) end)
ModalX.MouseButton1Click:Connect(function() Modal.Visible=false; ModalBg.Visible=false end)

New("Frame",{BackgroundColor3=T.Border,BorderSizePixel=0, Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,38),ZIndex=21,Parent=Modal})

local ModalInput = New("TextBox",{BackgroundColor3=T.SurfaceAlt, BorderSizePixel=0,
    Size=UDim2.new(1,-20,0,32), Position=UDim2.new(0,10,0,48),
    Font=Enum.Font.GothamMedium, PlaceholderText="Script name...", Text="",
    TextColor3=T.Text, PlaceholderColor3=T.TextMuted, TextSize=13,
    ClearTextOnFocus=false, ZIndex=22, Parent=Modal})
corner(7,ModalInput); stroke(T.Border,1,ModalInput); pad(0,0,10,10,ModalInput)

local ModalSaveBtn = New("TextButton",{BackgroundColor3=T.Accent, BorderSizePixel=0,
    Size=UDim2.new(1,-20,0,32), Position=UDim2.new(0,10,0,88),
    Font=Enum.Font.GothamBold, Text="SAVE", TextColor3=Color3.new(1,1,1),
    TextSize=12, AutoButtonColor=false, ClipsDescendants=true, ZIndex=22, Parent=Modal})
corner(7,ModalSaveBtn)
ModalSaveBtn.MouseEnter:Connect(function() tw(ModalSaveBtn,{BackgroundColor3=T.AccentLight},0.1) end)
ModalSaveBtn.MouseLeave:Connect(function() tw(ModalSaveBtn,{BackgroundColor3=T.Accent},0.1) end)

New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-20,0,18),
    Position=UDim2.new(0,14,0,130),Font=Enum.Font.GothamMedium,
    Text="Saved Scripts",TextColor3=T.TextDim,TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21,Parent=Modal})

local SaveList = New("ScrollingFrame",{BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,-20,0,185), Position=UDim2.new(0,10,0,150),
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollBarThickness=3, ScrollBarImageColor3=T.Border, ZIndex=21, Parent=Modal})
New("UIListLayout",{SortOrder=Enum.SortOrder.Name,Padding=UDim.new(0,4),Parent=SaveList})

local function refreshList()
    for _,c in ipairs(SaveList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local empty = true
    for name, content in pairs(savedScripts) do
        empty = false
        local row = New("Frame",{BackgroundColor3=T.SurfaceAlt,BorderSizePixel=0, Size=UDim2.new(1,0,0,30),ZIndex=22,Parent=SaveList})
        corner(6,row)
        New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-78,1,0), Position=UDim2.new(0,10,0,0),Font=Enum.Font.GothamMedium, Text=name,TextColor3=T.Text,TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=23,Parent=row})
        local lBtn = New("TextButton",{BackgroundColor3=T.AccentDark,BorderSizePixel=0, Size=UDim2.new(0,40,0,20),Position=UDim2.new(1,-72,0.5,-10), Font=Enum.Font.GothamBold,Text="Load",TextColor3=T.Text, TextSize=11,AutoButtonColor=false,ZIndex=23,Parent=row})
        corner(5,lBtn)
        local dBtn = New("TextButton",{BackgroundColor3=T.Danger,BorderSizePixel=0, Size=UDim2.new(0,24,0,20),Position=UDim2.new(1,-26,0.5,-10), Font=Enum.Font.GothamBold,Text="✕",TextColor3=Color3.new(1,1,1), TextSize=11,AutoButtonColor=false,ZIndex=23,Parent=row})
        corner(5,dBtn)
        local n, ct = name, content
        lBtn.MouseButton1Click:Connect(function()
            Editor.Text=ct; updateGutter(ct)
            notify("Loaded: "..n, T.Success)
            Modal.Visible=false; ModalBg.Visible=false
        end)
        dBtn.MouseButton1Click:Connect(function()
            savedScripts[n]=nil; refreshList()
            notify("Deleted: "..n, T.Danger)
            saveConfig()
        end)
    end
    if empty then
        New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,30), Font=Enum.Font.Gotham,Text="No saved scripts",TextColor3=T.TextMuted, TextSize=12,ZIndex=22,Parent=SaveList})
    end
end

local function openModal(saveMode)
    ModalTitleLbl.Text = saveMode and "💾  Save Script" or "📂  Load Script"
    ModalInput.Visible   = saveMode
    ModalSaveBtn.Visible = saveMode
    refreshList()
    Modal.Visible=true; ModalBg.Visible=true
end

ModalSaveBtn.MouseButton1Click:Connect(function()
    ripple(ModalSaveBtn)
    local n = ModalInput.Text ~= "" and ModalInput.Text or ("Script_"..tostring(tabCounter))
    savedScripts[n] = Editor.Text; refreshList()
    notify("Saved: "..n, T.Success); ModalInput.Text=""
    saveConfig()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB SYSTEM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function setActiveTab(id)
    if activeTabId and tabs[activeTabId] then tabs[activeTabId].content = Editor.Text end
    activeTabId = id
    local tab = tabs[id]; if not tab then return end
    Editor.Text = tab.content; updateGutter(tab.content)

    local eos = eosScripts[id]
    if eos then
        tw(EosPill,  {BackgroundColor3=T.AccentDark}, 0.01)
        tw(EosThumb, {Position=UDim2.new(0,25,0.5,-6), BackgroundColor3=T.Accent}, 0.01)
        if eos.scope == "current" then EosLabel.Text="ON — this game"; EosLabel.TextColor3=T.Success
        else EosLabel.Text="ON — all games"; EosLabel.TextColor3=T.Accent end
    else
        tw(EosPill,  {BackgroundColor3=T.SurfaceAlt}, 0.01)
        tw(EosThumb, {Position=UDim2.new(0,3,0.5,-6), BackgroundColor3=T.TextMuted}, 0.01)
        EosLabel.Text="OFF"; EosLabel.TextColor3=T.TextMuted
    end

    for tid, t in pairs(tabs) do
        if t.button then
            if tid == id then
                tw(t.button, {BackgroundColor3=T.TabOn}, 0.12)
                t.button.TextColor3 = T.Text
                t.indicator.Visible = true
            else
                tw(t.button, {BackgroundColor3=T.TabOff}, 0.12)
                t.button.TextColor3 = T.TextDim
                t.indicator.Visible = false
            end
        end
    end
end

-- forceId parameter ensures tabs keep their IDs after script restart (links perfectly to EOS toggles)
local function addTab(name, content, forceId)
    local id
    if forceId then
        id = forceId
        if forceId > tabCounter then tabCounter = forceId end
    else
        tabCounter += 1
        id = tabCounter
    end

    local tabName = name    or ("Script "..id)
    local tabText = content or ("-- "..tabName.."\n")

    local btn = New("TextButton",{BackgroundColor3=T.TabOff, BorderSizePixel=0,
        Size=UDim2.new(0,112,1,0), Font=Enum.Font.GothamMedium,
        Text="  "..tabName, TextColor3=T.TextDim, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
        AutoButtonColor=false, ClipsDescendants=true,
        LayoutOrder=id, ZIndex=4, Parent=TabStrip})
    corner(6,btn)
    local indicator = New("Frame",{BackgroundColor3=T.Accent, BorderSizePixel=0, Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2), ZIndex=5, Visible=false, Parent=btn})
    local xBtn = New("TextButton",{BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-18,0.5,-8), Font=Enum.Font.GothamBold, Text="×", TextColor3=T.TextMuted, TextSize=14, AutoButtonColor=false, ZIndex=6, Parent=btn})
    xBtn.MouseEnter:Connect(function() xBtn.TextColor3=T.Danger end)
    xBtn.MouseLeave:Connect(function() xBtn.TextColor3=T.TextMuted end)

    tabs[id] = {id=id, name=tabName, content=tabText, button=btn, indicator=indicator}
    btn.MouseButton1Click:Connect(function() setActiveTab(id) end)
    xBtn.MouseButton1Click:Connect(function()
        if activeTabId == id then
            local nxt = nil
            for tid in pairs(tabs) do if tid ~= id then nxt=tid; break end end
            if nxt then setActiveTab(nxt) else Editor.Text=""; activeTabId=nil end
        end
        tabs[id].button:Destroy(); tabs[id]=nil; eosScripts[id]=nil
        notify("Closed: "..tabName, T.TextDim)
        saveConfig()
    end)
    setActiveTab(id)
    saveConfig()
    return id
end

AddTabBtn.MouseButton1Click:Connect(function() ripple(AddTabBtn); addTab() end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  EXECUTE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function runScript(code)
    if not code or code:gsub("%s","") == "" then notify("Nothing to execute!", T.Warning); return end
    if activeTabId and tabs[activeTabId] then tabs[activeTabId].content = code end
    local fn, compileErr = loadstring(code)
    if not fn then
        notify("⚠ "..tostring(compileErr), T.Danger)
        StatusLbl.Text="⚠ syntax error"; StatusLbl.TextColor3=T.Danger
        task.delay(3, function() StatusLbl.Text="v2.0 ✦ ready"; StatusLbl.TextColor3=T.TextMuted end)
        return
    end
    local ok, runtimeErr = pcall(fn)
    if ok then
        notify("✓ Executed successfully!", T.Success)
        StatusLbl.Text="✓ success"; StatusLbl.TextColor3=T.Success
        task.delay(2, function() StatusLbl.Text="v2.0 ✦ ready"; StatusLbl.TextColor3=T.TextMuted end)
    else
        notify("✗ "..tostring(runtimeErr), T.Danger)
        StatusLbl.Text="✗ error"; StatusLbl.TextColor3=T.Danger
        task.delay(3, function() StatusLbl.Text="v2.0 ✦ ready"; StatusLbl.TextColor3=T.TextMuted end)
    end
end

ExecuteBtn.MouseButton1Click:Connect(function() runScript(Editor.Text) end)
ClearBtn.MouseButton1Click:Connect(function() Editor.Text=""; updateGutter(""); notify("Editor cleared", T.TextDim) end)
SaveBtn.MouseButton1Click:Connect(function()
    if activeTabId and tabs[activeTabId] then tabs[activeTabId].content=Editor.Text end
    openModal(true)
end)
LoadBtn.MouseButton1Click:Connect(function() openModal(false) end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  EXECUTE ON START (RUNS LOADED SCRIPTS)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
task.delay(1, function()
    local count = 0
    for _, entry in pairs(eosScripts) do
        if entry and entry.code and entry.code:gsub("%s","") ~= "" then
            local shouldRun = (entry.scope == "all") or (entry.scope == "current")
            if shouldRun then
                count += 1
                task.spawn(function()
                    local fn, e = loadstring(entry.code)
                    if fn then fn() else warn("[XenoEOS] "..tostring(e)) end
                end)
            end
        end
    end
    if count > 0 then
        notify("⚡ Execute on Start: ran "..count.." script(s)", T.Accent)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INIT (LOAD SAVED TABS OR DEFAULTS)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if configData.tabs and next(configData.tabs) then
    local sortedIds = {}
    for k in pairs(configData.tabs) do table.insert(sortedIds, tonumber(k)) end
    table.sort(sortedIds)
    
    for _, id in ipairs(sortedIds) do
        local tData = configData.tabs[tostring(id)]
        addTab(tData.name, tData.content, id) 
    end
else
    addTab("Script 1", "-- Welcome to Xeno Executor!\n-- Start scripting below\n\nprint(\"Hello, World!\")\n")
    addTab("Script 2", "-- Script 2\n\n")
end

switchPage("executor")

Main.BackgroundTransparency = 1
Glow.BackgroundTransparency = 1
task.wait()
tw(Main, {BackgroundTransparency=0}, 0.22, Enum.EasingStyle.Quad)
tw(Glow, {BackgroundTransparency=0.88}, 0.3)
notify("✦ Xeno v2.0 loaded", T.Accent)
