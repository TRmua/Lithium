local UI = {}
UI.__index = UI

local Services = setmetatable({}, { __index = function(_, k) return game:GetService(k) end })
local Players      = Services.Players
local UIS          = Services.UserInputService
local CoreGui      = Services.CoreGui
local TweenService = Services.TweenService
local GuiService   = Services.GuiService
local LocalPlayer  = Players.LocalPlayer

UI.Theme = {
    Bg           = Color3.fromRGB(12, 13, 20),
    BgTop        = Color3.fromRGB(22, 24, 36),
    BgBot        = Color3.fromRGB(8, 9, 15),
    Surface      = Color3.fromRGB(24, 26, 38),
    SurfaceHover = Color3.fromRGB(34, 37, 54),
    Surface2     = Color3.fromRGB(42, 45, 62),
    Surface3     = Color3.fromRGB(52, 56, 76),
    Accent       = Color3.fromRGB(0, 200, 255),
    Accent2      = Color3.fromRGB(140, 100, 255),
    AccentDim    = Color3.fromRGB(0, 130, 180),
    AccentGlow   = Color3.fromRGB(120, 230, 255),
    Glow         = Color3.fromRGB(0, 130, 190),
    Text         = Color3.fromRGB(248, 248, 252),
    TextDim      = Color3.fromRGB(145, 150, 175),
    TextMuted    = Color3.fromRGB(95, 100, 125),
    Border       = Color3.fromRGB(48, 50, 70),
    BorderLight  = Color3.fromRGB(70, 73, 100),
    Highlight    = Color3.fromRGB(90, 90, 130),
    Danger       = Color3.fromRGB(239, 68, 68),
    Success      = Color3.fromRGB(34, 197, 94),
    Font         = Enum.Font.Gotham,
    FontBold     = Enum.Font.GothamBold,
    FontMedium   = Enum.Font.GothamMedium,
    FontBlack    = Enum.Font.GothamBlack,
}

local TH = UI.Theme

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p return c end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke") s.Color = c or TH.Border s.Thickness = t or 1 s.Transparency = tr or 0 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s
end
local function gradient(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) })
    g.Rotation = rot or 45
    g.Parent = p
    return g
end
local function padding(p, top, bot, l, r)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0) pad.PaddingBottom = UDim.new(0, bot or 0)
    pad.PaddingLeft = UDim.new(0, l or 0) pad.PaddingRight = UDim.new(0, r or 0)
    pad.Parent = p
    return pad
end
local function getMousePos()
    local m = UIS:GetMouseLocation()
    return Vector2.new(m.X, m.Y - GuiService:GetGuiInset().Y)
end

UI._notifHolder = nil
UI._notifications = {}

function UI:Notify(title, text, duration)
    if not self._notifHolder then return end
    duration = duration or 3
    local n = Instance.new("Frame")
    n.Size = UDim2.new(0, 300, 0, 62)
    n.BackgroundColor3 = TH.Surface
    n.BorderSizePixel = 0
    n.Parent = self._notifHolder
    corner(n, 9)
    stroke(n, TH.BorderLight, 1, 0.4)
    local nGrad = Instance.new("UIGradient")
    nGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TH.Surface2), ColorSequenceKeypoint.new(1, TH.Surface) })
    nGrad.Rotation = 90
    nGrad.Parent = n
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0.65, 0)
    accent.Position = UDim2.new(0, 0, 0.5, 0)
    accent.AnchorPoint = Vector2.new(0, 0.5)
    accent.BackgroundColor3 = TH.Accent
    accent.BorderSizePixel = 0
    accent.Parent = n
    corner(accent, 2)
    gradient(accent, TH.Accent, TH.Accent2, 90)
    local ti = Instance.new("TextLabel")
    ti.Size = UDim2.new(1, -24, 0, 20)
    ti.Position = UDim2.new(0, 16, 0, 8)
    ti.BackgroundTransparency = 1
    ti.Text = title
    ti.TextColor3 = TH.AccentGlow
    ti.Font = TH.FontBold
    ti.TextSize = 12
    ti.TextXAlignment = Enum.TextXAlignment.Left
    ti.Parent = n
    local te = Instance.new("TextLabel")
    te.Size = UDim2.new(1, -24, 0, 26)
    te.Position = UDim2.new(0, 16, 0, 28)
    te.BackgroundTransparency = 1
    te.Text = text
    te.TextColor3 = TH.TextDim
    te.Font = TH.Font
    te.TextSize = 11
    te.TextXAlignment = Enum.TextXAlignment.Left
    te.TextWrapped = true
    te.Parent = n
    n.Position = UDim2.new(1, 320, 0, 0)
    local targetY = 0
    for _, existing in ipairs(self._notifications) do targetY = targetY + 70 end
    table.insert(self._notifications, n)
    TweenService:Create(n, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(1, -320, 0, targetY) }):Play()
    task.delay(duration, function()
        TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(1, 320, 0, n.Position.Y.Offset) }):Play()
        task.wait(0.35)
        for i, v in ipairs(UI._notifications) do if v == n then table.remove(UI._notifications, i) break end end
        n:Destroy()
        local y = 0
        for _, existing in ipairs(UI._notifications) do
            TweenService:Create(existing, TweenInfo.new(0.2), {Position = UDim2.new(1, -320, 0, y)}):Play()
            y = y + 70
        end
    end)
end

local Widgets = {}

function Widgets.Section(parent, name)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 34)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 14)
    accent.Position = UDim2.new(0, 0, 0.5, -7)
    accent.BackgroundColor3 = TH.Accent
    accent.BorderSizePixel = 0
    accent.Parent = h
    corner(accent, 2)
    gradient(accent, TH.Accent, TH.Accent2, 90)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -14, 1, 0)
    l.Position = UDim2.new(0, 14, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = string.upper(name)
    l.TextColor3 = TH.AccentGlow
    l.Font = TH.FontBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    return h
end

function Widgets.Toggle(parent, opts)
    local label = opts.Text or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback or function() end

    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 42)
    c.BackgroundColor3 = TH.Surface
    c.BorderSizePixel = 0
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.55, 0)
    bar.Position = UDim2.new(0, 0, 0.5, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = TH.Accent
    bar.BorderSizePixel = 0
    bar.BackgroundTransparency = default and 0 or 1
    bar.Parent = c
    corner(bar, 2)
    gradient(bar, TH.Accent, TH.Accent2, 90)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TH.Text
    lbl.Font = TH.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c

    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 40, 0, 22)
    sw.Position = UDim2.new(1, -54, 0.5, -11)
    sw.BackgroundColor3 = default and TH.Accent or TH.Surface3
    sw.BorderSizePixel = 0
    sw.Parent = c
    corner(sw, 11)
    local swS = Instance.new("UIStroke")
    swS.Color = default and TH.AccentGlow or TH.Border
    swS.Thickness = 1
    swS.Transparency = default and 0.3 or 0
    swS.Parent = sw

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    corner(knob, 9)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = c

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = state and TH.Accent or TH.Surface3}):Play()
        TweenService:Create(swS, TweenInfo.new(0.22), {Color = state and TH.AccentGlow or TH.Border, Transparency = state and 0.3 or 0}):Play()
        TweenService:Create(knob, TweenInfo.new(0.22), {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
        TweenService:Create(bar, TweenInfo.new(0.18), {BackgroundTransparency = state and 0 or 1}):Play()
        callback(state)
    end)
    btn.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.SurfaceHover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.Surface}):Play() end)

    return {
        Set = function(v)
            state = v
            TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = state and TH.Accent or TH.Surface3}):Play()
            TweenService:Create(swS, TweenInfo.new(0.22), {Color = state and TH.AccentGlow or TH.Border, Transparency = state and 0.3 or 0}):Play()
            TweenService:Create(knob, TweenInfo.new(0.22), {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
            TweenService:Create(bar, TweenInfo.new(0.18), {BackgroundTransparency = state and 0 or 1}):Play()
            callback(state)
        end
    }
end

function Widgets.Slider(parent, opts)
    local label = opts.Text or "Slider"
    local min, max = opts.Min or 0, opts.Max or 100
    local default = opts.Default or min
    local isFloat = opts.Decimal ~= nil and opts.Decimal > 0 or (default ~= math.floor(default))
    local callback = opts.Callback or function() end

    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 58)
    c.BackgroundColor3 = TH.Surface
    c.BorderSizePixel = 0
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -90, 0, 18)
    lbl.Position = UDim2.new(0, 18, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TH.Text
    lbl.Font = TH.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c

    local vl = Instance.new("Frame")
    vl.Size = UDim2.new(0, 68, 0, 22)
    vl.Position = UDim2.new(1, -80, 0, 4)
    vl.BackgroundColor3 = TH.Surface3
    vl.BorderSizePixel = 0
    vl.Parent = c
    corner(vl, 5)
    stroke(vl, TH.BorderLight, 1, 0.4)

    local vlText = Instance.new("TextLabel")
    vlText.Size = UDim2.new(1, 0, 1, 0)
    vlText.BackgroundTransparency = 1
    vlText.Text = isFloat and string.format("%.2f", default) or tostring(default)
    vlText.TextColor3 = TH.AccentGlow
    vlText.Font = TH.FontBold
    vlText.TextSize = 11
    vlText.Parent = vl

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -36, 0, 6)
    bg.Position = UDim2.new(0, 18, 1, -22)
    bg.BackgroundColor3 = TH.Surface3
    bg.BorderSizePixel = 0
    bg.Parent = c
    corner(bg, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = TH.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bg
    corner(fill, 3)
    gradient(fill, TH.Accent, TH.Accent2, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    corner(knob, 7)
    stroke(knob, TH.Accent, 2)

    local dragging = false
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 2, 0)
    hit.Position = UDim2.new(0, 0, -0.5, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = bg

    local function setX(x)
        local rel = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local v = min + (max-min) * rel
        if not isFloat then v = math.floor(v + 0.5) end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        vlText.Text = isFloat and string.format("%.2f", v) or tostring(v)
        callback(v)
    end

    hit.MouseButton1Down:Connect(function() dragging = true end)
    hit.MouseButton1Up:Connect(function() dragging = false end)
    hit.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.SurfaceHover}):Play() end)
    hit.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.Surface}):Play() end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setX(input.Position.X) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

function Widgets.Keybind(parent, opts)
    local label = opts.Text or "Key"
    local default = opts.Default or Enum.KeyCode.E
    local callback = opts.Callback or function() end

    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 42)
    c.BackgroundColor3 = TH.Surface
    c.BorderSizePixel = 0
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TH.Text
    lbl.Font = TH.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 100, 0, 28)
    keyBtn.Position = UDim2.new(1, -114, 0.5, -14)
    keyBtn.BackgroundColor3 = TH.Surface3
    keyBtn.Text = default.Name
    keyBtn.TextColor3 = TH.Text
    keyBtn.Font = TH.FontBold
    keyBtn.TextSize = 11
    keyBtn.Parent = c
    corner(keyBtn, 6)
    stroke(keyBtn, TH.BorderLight, 1, 0.5)

    local listening = false
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = TH.AccentDim
        local conn
        conn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            local newKey
            if input.UserInputType == Enum.UserInputType.Keyboard then newKey = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then newKey = input.UserInputType end
            if newKey then
                keyBtn.Text = newKey.Name
                keyBtn.BackgroundColor3 = TH.Surface3
                callback(newKey)
                listening = false
                conn:Disconnect()
            end
        end)
    end)
end

function Widgets.Dropdown(parent, opts)
    local label = opts.Text or "Dropdown"
    local options = opts.Values or {}
    local defaultIdx = opts.Default or 1
    local callback = opts.Callback or function() end

    local ROW_H, OPT_H = 42, 30
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, ROW_H)
    c.BackgroundColor3 = TH.Surface
    c.BorderSizePixel = 0
    c.ClipsDescendants = true
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -140, 0, ROW_H)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TH.Text
    lbl.Font = TH.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 116, 0, 30)
    btn.Position = UDim2.new(1, -130, 0.5, -15)
    btn.BackgroundColor3 = TH.Surface3
    btn.Text = "›  " .. (options[defaultIdx] or "?")
    btn.TextColor3 = TH.Text
    btn.Font = TH.FontBold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = c
    corner(btn, 6)
    stroke(btn, TH.BorderLight, 1, 0.5)
    padding(btn, 0, 0, 10, 0)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -24, 0, #options * OPT_H)
    list.Position = UDim2.new(0, 12, 0, ROW_H + 4)
    list.BackgroundTransparency = 1
    list.Visible = false
    list.ZIndex = 5
    list.Parent = c
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 4)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = list

    local curIdx = defaultIdx
    local optionBtns = {}
    local isOpen = false
    local openH = ROW_H + 4 + #options * OPT_H + 10

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, OPT_H - 4)
        ob.BackgroundColor3 = (i == curIdx) and TH.AccentDim or TH.Surface3
        ob.Text = "   " .. opt
        ob.TextColor3 = (i == curIdx) and Color3.new(1,1,1) or TH.TextDim
        ob.Font = TH.FontMedium
        ob.TextSize = 11
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.LayoutOrder = i
        ob.ZIndex = 6
        ob.Parent = list
        corner(ob, 5)
        ob.MouseButton1Click:Connect(function()
            curIdx = i
            for k, b in ipairs(optionBtns) do
                local a = (k == curIdx)
                TweenService:Create(b, TweenInfo.new(0.15), {
                    BackgroundColor3 = a and TH.AccentDim or TH.Surface3,
                    TextColor3 = a and Color3.new(1,1,1) or TH.TextDim
                }):Play()
            end
            isOpen = false
            btn.Text = "›  " .. opt
            TweenService:Create(c, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, ROW_H)}):Play()
            task.delay(0.15, function() if not isOpen then list.Visible = false end end)
            callback(opt, i)
        end)
        optionBtns[i] = ob
    end

    local toggleArea = Instance.new("TextButton")
    toggleArea.Size = UDim2.new(1, 0, 0, ROW_H)
    toggleArea.BackgroundTransparency = 1
    toggleArea.Text = ""
    toggleArea.ZIndex = 30
    toggleArea.Parent = c
    toggleArea.MouseButton1Click:Connect(function()
        if isOpen then
            isOpen = false
            btn.Text = "›  " .. options[curIdx]
            TweenService:Create(c, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, ROW_H)}):Play()
            task.delay(0.15, function() if not isOpen then list.Visible = false end end)
        else
            isOpen = true
            btn.Text = "‹  " .. options[curIdx]
            list.Visible = true
            TweenService:Create(c, TweenInfo.new(0.22), {Size = UDim2.new(1, 0, 0, openH)}):Play()
        end
    end)
    toggleArea.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.SurfaceHover}):Play() end)
    toggleArea.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.Surface}):Play() end)
end

function Widgets.ColorPicker(parent, opts)
    local label = opts.Title or opts.Text or "Color"
    local defaultColor = opts.Default or Color3.fromRGB(0, 200, 255)
    local callback = opts.Callback or function() end
    local parentWindow = opts._window

    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 42)
    c.BackgroundColor3 = TH.Surface
    c.BorderSizePixel = 0
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TH.Text
    lbl.Font = TH.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c

    local prev = Instance.new("Frame")
    prev.Size = UDim2.new(0, 96, 0, 28)
    prev.Position = UDim2.new(1, -110, 0.5, -14)
    prev.BackgroundColor3 = defaultColor
    prev.BorderSizePixel = 0
    prev.Parent = c
    corner(prev, 6)
    stroke(prev, TH.BorderLight, 1.5, 0.3)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = c

    btn.MouseButton1Click:Connect(function()
        if UI._activePicker then pcall(function() UI._activePicker:Destroy() end) UI._activePicker = nil end
        local panel = Instance.new("Frame")
        panel.Name = "ColorPickerPanel"
        panel.Size = UDim2.new(0, 280, 0, 300)
        panel.Position = UDim2.new(0.5, -140, 0.5, -150)
        panel.BackgroundColor3 = TH.Surface2
        panel.BorderSizePixel = 0
        panel.ZIndex = 5000
        panel.Parent = parentWindow
        corner(panel, 12)
        stroke(panel, TH.BorderLight, 1.5, 0)
        UI._activePicker = panel

        local panelHeader = Instance.new("Frame")
        panelHeader.Size = UDim2.new(1, 0, 0, 40)
        panelHeader.BackgroundTransparency = 1
        panelHeader.ZIndex = 5001
        panelHeader.Parent = panel
        local panelTitle = Instance.new("TextLabel")
        panelTitle.Size = UDim2.new(1, -60, 1, 0)
        panelTitle.Position = UDim2.new(0, 18, 0, 0)
        panelTitle.BackgroundTransparency = 1
        panelTitle.Text = label
        panelTitle.TextColor3 = TH.Text
        panelTitle.Font = TH.FontBold
        panelTitle.TextSize = 13
        panelTitle.TextXAlignment = Enum.TextXAlignment.Left
        panelTitle.ZIndex = 5002
        panelTitle.Parent = panelHeader
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
        closeBtn.BackgroundColor3 = TH.Surface
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = TH.TextDim
        closeBtn.Font = TH.FontBold
        closeBtn.TextSize = 14
        closeBtn.ZIndex = 5002
        closeBtn.Parent = panelHeader
        corner(closeBtn, 7)
        closeBtn.MouseButton1Click:Connect(function()
            if UI._activePicker then UI._activePicker:Destroy() UI._activePicker = nil end
        end)
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, -32, 0, 1)
        divider.Position = UDim2.new(0, 16, 0, 40)
        divider.BackgroundColor3 = TH.Border
        divider.BackgroundTransparency = 0.5
        divider.BorderSizePixel = 0
        divider.ZIndex = 5001
        divider.Parent = panel

        local SV_S = 160
        local sv = Instance.new("Frame")
        sv.Size = UDim2.new(0, SV_S, 0, SV_S)
        sv.Position = UDim2.new(0, 20, 0, 54)
        sv.BackgroundColor3 = Color3.fromHSV(0,1,1)
        sv.BorderSizePixel = 0
        sv.ZIndex = 5002
        sv.Parent = panel
        corner(sv, 6)
        local svW = Instance.new("Frame")
        svW.Size = UDim2.new(1, 0, 1, 0)
        svW.BackgroundColor3 = Color3.new(1,1,1)
        svW.BorderSizePixel = 0
        svW.ZIndex = 5003
        svW.Parent = sv
        corner(svW, 6)
        local gW = Instance.new("UIGradient")
        gW.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
        gW.Parent = svW
        local svB = Instance.new("Frame")
        svB.Size = UDim2.new(1, 0, 1, 0)
        svB.BackgroundColor3 = Color3.new(0,0,0)
        svB.BorderSizePixel = 0
        svB.ZIndex = 5004
        svB.Parent = sv
        corner(svB, 6)
        local gB = Instance.new("UIGradient")
        gB.Rotation = 90
        gB.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
        gB.Parent = svB
        local cur = Instance.new("Frame")
        cur.Size = UDim2.new(0, 16, 0, 16)
        cur.AnchorPoint = Vector2.new(0.5, 0.5)
        cur.BackgroundColor3 = Color3.new(1,1,1)
        cur.BorderSizePixel = 0
        cur.ZIndex = 5005
        cur.Parent = sv
        corner(cur, 8)
        stroke(cur, Color3.new(0,0,0), 2)
        local hue = Instance.new("Frame")
        hue.Size = UDim2.new(0, 28, 0, SV_S)
        hue.Position = UDim2.new(0, SV_S + 30, 0, 54)
        hue.BackgroundColor3 = Color3.new(1,1,1)
        hue.BorderSizePixel = 0
        hue.ZIndex = 5002
        hue.Parent = panel
        corner(hue, 6)
        local hGrad = Instance.new("UIGradient")
        hGrad.Rotation = 90
        hGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
        })
        hGrad.Parent = hue
        local hCur = Instance.new("Frame")
        hCur.Size = UDim2.new(1, 8, 0, 5)
        hCur.AnchorPoint = Vector2.new(0.5, 0.5)
        hCur.BackgroundColor3 = Color3.new(1,1,1)
        hCur.BorderSizePixel = 0
        hCur.ZIndex = 5005
        hCur.Parent = hue
        corner(hCur, 2)
        stroke(hCur, Color3.new(0,0,0), 2)
        local hex = Instance.new("TextBox")
        hex.Size = UDim2.new(1, -40, 0, 34)
        hex.Position = UDim2.new(0, 20, 1, -50)
        hex.BackgroundColor3 = TH.Surface
        hex.Text = "#00C8FF"
        hex.TextColor3 = TH.Text
        hex.Font = TH.FontBold
        hex.TextSize = 13
        hex.ClearTextOnFocus = false
        hex.ZIndex = 5002
        hex.Parent = panel
        corner(hex, 6)
        stroke(hex, TH.BorderLight, 1, 0.5)

        local H, S, V = defaultColor:ToHSV()
        local lock = false
        local function update(fire)
            local col = Color3.fromHSV(H, S, V)
            prev.BackgroundColor3 = col
            sv.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
            cur.Position = UDim2.new(S, 0, 1-V, 0)
            hCur.Position = UDim2.new(0.5, 0, H, 0)
            if not lock then
                lock = true
                hex.Text = string.format("#%02X%02X%02X", math.floor(col.R*255+0.5), math.floor(col.G*255+0.5), math.floor(col.B*255+0.5))
                lock = false
            end
            if fire ~= false then callback(col) end
        end
        update(false)

        local dragSV, dragHue = false, false
        local svHit = Instance.new("TextButton")
        svHit.Size = UDim2.new(1, 0, 1, 0)
        svHit.BackgroundTransparency = 1
        svHit.Text = ""
        svHit.ZIndex = 5006
        svHit.Parent = sv
        local hHit = Instance.new("TextButton")
        hHit.Size = UDim2.new(1, 0, 1, 0)
        hHit.BackgroundTransparency = 1
        hHit.Text = ""
        hHit.ZIndex = 5006
        hHit.Parent = hue
        local function svXY(mx, my)
            local rx = math.clamp((mx - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((my - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            S = rx V = 1 - ry update()
        end
        local function hY(my)
            local ry = math.clamp((my - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
            H = ry update()
        end
        svHit.MouseButton1Down:Connect(function() dragSV = true local m = getMousePos() svXY(m.X, m.Y) end)
        hHit.MouseButton1Down:Connect(function() dragHue = true local m = getMousePos() hY(m.Y) end)
        UIS.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local m = getMousePos()
                if dragSV then svXY(m.X, m.Y) end
                if dragHue then hY(m.Y) end
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = false dragHue = false end
        end)
        hex.FocusLost:Connect(function()
            if lock then return end
            local t = hex.Text:gsub("#",""):gsub("%s","")
            if #t >= 6 then
                local r = tonumber(t:sub(1,2), 16) local g = tonumber(t:sub(3,4), 16) local b = tonumber(t:sub(5,6), 16)
                if r and g and b then
                    local cc = Color3.fromRGB(r,g,b)
                    H,S,V = cc:ToHSV()
                    update()
                    return
                end
            end
            update()
        end)
    end)
end

function Widgets.Button(parent, opts)
    local label = opts.Text or "Button"
    local callback = opts.Callback or function() end
    local c = Instance.new("TextButton")
    c.Size = UDim2.new(1, 0, 0, 38)
    c.BackgroundColor3 = TH.Surface
    c.Text = "  " .. label
    c.TextColor3 = TH.Text
    c.Font = TH.FontMedium
    c.TextSize = 12
    c.TextXAlignment = Enum.TextXAlignment.Left
    c.Parent = parent
    corner(c, 8)
    stroke(c, TH.BorderLight, 1, 0.5)
    padding(c, 0, 0, 14, 0)
    c.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.SurfaceHover, TextColor3 = TH.AccentGlow}):Play() end)
    c.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = TH.Surface, TextColor3 = TH.Text}):Play() end)
    c.MouseButton1Click:Connect(callback)
end

local Window = {}
Window.__index = Window

function UI:CreateWindow(config)
    config = config or {}
    local W, H = config.Width or 820, config.Height or 560
    local Title = config.Title or "LITHIUM"
    local Subtitle = config.Subtitle or ""
    local Logo = config.Logo or ""

    local gui = Instance.new("ScreenGui")
    gui.Name = "LithiumUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    local ok = pcall(function() gui.Parent = gethui() end)
    if not ok then
        ok = pcall(function() gui.Parent = CoreGui end)
        if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end

    self._notifHolder = Instance.new("Frame")
    self._notifHolder.Name = "Notifications"
    self._notifHolder.Size = UDim2.new(0, 340, 1, -80)
    self._notifHolder.Position = UDim2.new(1, -360, 0, 70)
    self._notifHolder.BackgroundTransparency = 1
    self._notifHolder.ZIndex = 6000
    self._notifHolder.Parent = gui

    local WW, WH = W + 70, H + 70
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(0, WW, 0, WH)
    wrap.Position = UDim2.new(0, 60, 0, 80)
    wrap.BackgroundTransparency = 1
    wrap.Active = true
    wrap.Draggable = true
    wrap.Parent = gui

    local layers = Instance.new("Frame")
    layers.Size = UDim2.new(1, 0, 1, 0)
    layers.BackgroundTransparency = 1
    layers.ZIndex = 0
    layers.Parent = wrap
    for i = 7, 1, -1 do
        local g = Instance.new("Frame")
        local sp = i * 6
        g.Size = UDim2.new(0, W + sp*2, 0, H + sp*2)
        g.Position = UDim2.new(0.5, -W/2 - sp, 0.5, -H/2 - sp)
        g.BackgroundColor3 = TH.Glow
        g.BackgroundTransparency = 1 - (0.13/i)
        g.BorderSizePixel = 0
        g.ZIndex = 1
        g.Parent = layers
        corner(g, 20)
    end
    for i = 1, 6 do
        local sh = Instance.new("Frame")
        sh.Size = UDim2.new(0, W, 0, H)
        sh.Position = UDim2.new(0.5, -W/2 + i*3, 0.5, -H/2 + i*3)
        sh.BackgroundColor3 = Color3.new(0,0,0)
        sh.BackgroundTransparency = 1 - (0.20/i)
        sh.BorderSizePixel = 0
        sh.ZIndex = 2
        sh.Parent = layers
        corner(sh, 16)
    end

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, W, 0, H)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = TH.Bg
    main.BorderSizePixel = 0
    main.ZIndex = 10
    main.Parent = wrap
    corner(main, 16)
    stroke(main, TH.BorderLight, 1, 0.4)

    local gr = Instance.new("UIGradient")
    gr.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TH.BgTop), ColorSequenceKeypoint.new(1, TH.BgBot) })
    gr.Rotation = 90
    gr.Parent = main

    local topHi = Instance.new("Frame")
    topHi.Size = UDim2.new(1, -32, 0, 1)
    topHi.Position = UDim2.new(0, 16, 0, 1)
    topHi.BackgroundColor3 = TH.Highlight
    topHi.BackgroundTransparency = 0.5
    topHi.BorderSizePixel = 0
    topHi.ZIndex = 11
    topHi.Parent = main

    local accLine = Instance.new("Frame")
    accLine.Size = UDim2.new(1, -32, 0, 2)
    accLine.Position = UDim2.new(0, 16, 0, 0)
    accLine.BackgroundColor3 = TH.Accent
    accLine.BorderSizePixel = 0
    accLine.ZIndex = 12
    accLine.Parent = main
    corner(accLine, 1)
    gradient(accLine, TH.Accent, TH.Accent2, 0)

    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 64)
    hdr.BackgroundTransparency = 1
    hdr.ZIndex = 15
    hdr.Parent = main

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 40, 0, 40)
    logo.Position = UDim2.new(0, 18, 0.5, -20)
    logo.BackgroundColor3 = TH.Bg
    logo.BorderSizePixel = 0
    logo.ZIndex = 16
    logo.Parent = hdr
    corner(logo, 11)
    local logoGlow = Instance.new("Frame")
    logoGlow.Size = UDim2.new(1, 6, 1, 6)
    logoGlow.Position = UDim2.new(0, -3, 0, -3)
    logoGlow.BackgroundColor3 = TH.Accent
    logoGlow.BackgroundTransparency = 0.7
    logoGlow.BorderSizePixel = 0
    logoGlow.ZIndex = 15
    logoGlow.Parent = logo
    corner(logoGlow, 13)
    if Logo ~= "" and Logo ~= "rbxassetid://0" then
        local logoImg = Instance.new("ImageLabel")
        logoImg.Size = UDim2.new(1, -4, 1, -4)
        logoImg.Position = UDim2.new(0, 2, 0, 2)
        logoImg.BackgroundTransparency = 1
        logoImg.Image = Logo
        logoImg.ScaleType = Enum.ScaleType.Fit
        logoImg.ZIndex = 17
        logoImg.Parent = logo
        corner(logoImg, 9)
    else
        local lt = Instance.new("TextLabel")
        lt.Size = UDim2.new(1, 0, 1, 0)
        lt.BackgroundTransparency = 1
        lt.Text = "L"
        lt.TextColor3 = Color3.new(1,1,1)
        lt.Font = TH.FontBlack
        lt.TextSize = 22
        lt.ZIndex = 17
        lt.Parent = logo
    end

    local ti = Instance.new("TextLabel")
    ti.Size = UDim2.new(0, 400, 0, 24)
    ti.Position = UDim2.new(0, 70, 0.5, -16)
    ti.BackgroundTransparency = 1
    ti.Text = Title
    ti.TextColor3 = TH.Text
    ti.Font = TH.FontBlack
    ti.TextSize = 20
    ti.TextXAlignment = Enum.TextXAlignment.Left
    ti.ZIndex = 16
    ti.Parent = hdr
    local tiGrad = Instance.new("UIGradient")
    tiGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, TH.AccentGlow),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, TH.Accent2),
    })
    tiGrad.Parent = ti

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 500, 0, 13)
    st.Position = UDim2.new(0, 70, 0.5, 8)
    st.BackgroundTransparency = 1
    st.Text = Subtitle
    st.TextColor3 = TH.TextMuted
    st.Font = TH.Font
    st.TextSize = 10
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.ZIndex = 16
    st.Parent = hdr

    local sdot = Instance.new("Frame")
    sdot.Size = UDim2.new(0, 7, 0, 7)
    sdot.Position = UDim2.new(1, -310, 0.5, -3.5)
    sdot.BackgroundColor3 = TH.Success
    sdot.BorderSizePixel = 0
    sdot.ZIndex = 16
    sdot.Parent = hdr
    corner(sdot, 4)
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(0, 55, 0, 14)
    sl.Position = UDim2.new(1, -300, 0.5, -7)
    sl.BackgroundTransparency = 1
    sl.Text = "Active"
    sl.TextColor3 = TH.Success
    sl.Font = TH.FontBold
    sl.TextSize = 10
    sl.TextXAlignment = Enum.TextXAlignment.Left
    sl.ZIndex = 16
    sl.Parent = hdr

    local fpsLbl = Instance.new("TextLabel")
    fpsLbl.Size = UDim2.new(0, 190, 0, 14)
    fpsLbl.Position = UDim2.new(1, -230, 0.5, -7)
    fpsLbl.BackgroundTransparency = 1
    fpsLbl.Text = "FPS: -- | Ping: --"
    fpsLbl.TextColor3 = TH.TextDim
    fpsLbl.Font = TH.FontBold
    fpsLbl.TextSize = 10
    fpsLbl.TextXAlignment = Enum.TextXAlignment.Right
    fpsLbl.ZIndex = 16
    fpsLbl.Parent = hdr

    local cl = Instance.new("TextButton")
    cl.Size = UDim2.new(0, 32, 0, 32)
    cl.Position = UDim2.new(1, -46, 0.5, -16)
    cl.BackgroundColor3 = TH.Surface
    cl.Text = "✕"
    cl.TextColor3 = TH.TextDim
    cl.Font = TH.FontBold
    cl.TextSize = 15
    cl.ZIndex = 16
    cl.Parent = hdr
    corner(cl, 9)
    cl.MouseEnter:Connect(function() TweenService:Create(cl, TweenInfo.new(0.15), {BackgroundColor3 = TH.Danger, TextColor3 = Color3.new(1,1,1)}):Play() end)
    cl.MouseLeave:Connect(function() TweenService:Create(cl, TweenInfo.new(0.15), {BackgroundColor3 = TH.Surface, TextColor3 = TH.TextDim}):Play() end)
    cl.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local dv = Instance.new("Frame")
    dv.Size = UDim2.new(1, -32, 0, 1)
    dv.Position = UDim2.new(0, 16, 0, 66)
    dv.BackgroundColor3 = TH.Border
    dv.BackgroundTransparency = 0.5
    dv.BorderSizePixel = 0
    dv.ZIndex = 15
    dv.Parent = main

    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, -32, 0, 36)
    searchBar.Position = UDim2.new(0, 16, 0, 76)
    searchBar.BackgroundColor3 = TH.Surface
    searchBar.BorderSizePixel = 0
    searchBar.ZIndex = 15
    searchBar.Parent = main
    corner(searchBar, 8)
    stroke(searchBar, TH.Border, 1, 0.5)
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 26, 1, 0)
    searchIcon.Position = UDim2.new(0, 12, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "⌕"
    searchIcon.TextColor3 = TH.TextDim
    searchIcon.Font = TH.FontBold
    searchIcon.TextSize = 18
    searchIcon.ZIndex = 16
    searchIcon.Parent = searchBar
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -44, 1, 0)
    searchBox.Position = UDim2.new(0, 38, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Tìm tính năng..."
    searchBox.PlaceholderColor3 = TH.TextMuted
    searchBox.TextColor3 = TH.Text
    searchBox.Font = TH.Font
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 16
    searchBox.Parent = searchBar

    local sb = Instance.new("Frame")
    sb.Size = UDim2.new(0, 180, 1, -210)
    sb.Position = UDim2.new(0, 16, 0, 122)
    sb.BackgroundTransparency = 1
    sb.ZIndex = 15
    sb.Parent = main
    local sbl = Instance.new("UIListLayout")
    sbl.Padding = UDim.new(0, 5)
    sbl.Parent = sb

    local ct = Instance.new("Frame")
    ct.Size = UDim2.new(1, -226, 1, -138)
    ct.Position = UDim2.new(0, 210, 0, 122)
    ct.BackgroundTransparency = 1
    ct.ZIndex = 15
    ct.Parent = main

    local win = setmetatable({
        Gui = gui, Main = main, Wrapper = wrap,
        Sidebar = sb, Content = ct,
        Pages = {}, Tabs = {},
        FPSLabel = fpsLbl,
        Title = Title,
        _activeTab = nil,
    }, Window)
    UI._currentWindow = win

    task.spawn(function()
        while gui.Parent do
            local fps = math.floor(1 / Services.RunService.RenderStepped:Wait())
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            fpsLbl.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
            task.wait(0.5)
        end
    end)

    return win
end

function Window:AddTab(name, icon)
    icon = icon or "●"
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = TH.Surface
    btn.Text = ""
    btn.ZIndex = 16
    btn.Parent = self.Sidebar
    corner(btn, 9)
    stroke(btn, TH.BorderLight, 1, 0.6)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.5, 0)
    bar.Position = UDim2.new(0, 0, 0.5, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = TH.Accent
    bar.BorderSizePixel = 0
    bar.BackgroundTransparency = 1
    bar.ZIndex = 17
    bar.Parent = btn
    corner(bar, 2)
    gradient(bar, TH.Accent, TH.Accent2, 90)

    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 36, 1, 0)
    ic.Position = UDim2.new(0, 14, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextColor3 = TH.TextDim
    ic.Font = TH.FontBold
    ic.TextSize = 16
    ic.TextXAlignment = Enum.TextXAlignment.Left
    ic.ZIndex = 17
    ic.Parent = btn

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -60, 1, 0)
    lb.Position = UDim2.new(0, 50, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = name
    lb.TextColor3 = TH.TextDim
    lb.Font = TH.FontMedium
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 17
    lb.Parent = btn

    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.ZIndex = 15
    p.Parent = self.Content

    local L = Instance.new("ScrollingFrame")
    L.Size = UDim2.new(0.5, -7, 1, 0)
    L.BackgroundTransparency = 1
    L.BorderSizePixel = 0
    L.ScrollBarThickness = 3
    L.ScrollBarImageColor3 = TH.Accent
    L.CanvasSize = UDim2.new(0, 0, 0, 0)
    L.AutomaticCanvasSize = Enum.AutomaticSize.Y
    L.ZIndex = 15
    L.Parent = p
    local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 8) ll.Parent = L

    local R = Instance.new("ScrollingFrame")
    R.Size = UDim2.new(0.5, -7, 1, 0)
    R.Position = UDim2.new(0.5, 7, 0, 0)
    R.BackgroundTransparency = 1
    R.BorderSizePixel = 0
    R.ScrollBarThickness = 3
    R.ScrollBarImageColor3 = TH.Accent
    R.CanvasSize = UDim2.new(0, 0, 0, 0)
    R.AutomaticCanvasSize = Enum.AutomaticSize.Y
    R.ZIndex = 15
    R.Parent = p
    local rl = Instance.new("UIListLayout") rl.Padding = UDim.new(0, 8) rl.Parent = R

    self.Pages[name] = p
    self.Tabs[name] = { Button = btn, Bar = bar, Icon = ic, Label = lb }

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    local tab = {
        Left = L,
        Right = R,
        Page = p,
    }

    function tab:AddSection(name) Widgets.Section(L, name) end
    function tab:AddToggle(opts) Widgets.Toggle(L, opts) end
    function tab:AddSlider(opts) Widgets.Slider(L, opts) end
    function tab:AddKeybind(opts) Widgets.Keybind(L, opts) end
    function tab:AddDropdown(opts) Widgets.Dropdown(L, opts) end
    function tab:AddColorPicker(opts)
        opts._window = self.Main
        Widgets.ColorPicker(L, opts)
    end
    function tab:AddButton(opts) Widgets.Button(L, opts) end

    function tab:AddSectionR(name) Widgets.Section(R, name) end
    function tab:AddToggleR(opts) Widgets.Toggle(R, opts) end
    function tab:AddSliderR(opts) Widgets.Slider(R, opts) end
    function tab:AddKeybindR(opts) Widgets.Keybind(R, opts) end
    function tab:AddDropdownR(opts) Widgets.Dropdown(R, opts) end
    function tab:AddColorPickerR(opts)
        opts._window = self.Main
        Widgets.ColorPicker(R, opts)
    end
    function tab:AddButtonR(opts) Widgets.Button(R, opts) end

    return tab
end

function Window:SelectTab(name)
    if not self.Tabs[name] then return end
    if UI._activePicker then pcall(function() UI._activePicker:Destroy() end) UI._activePicker = nil end
    for n, page in pairs(self.Pages) do page.Visible = (n == name) end
    for n, o in pairs(self.Tabs) do
        local a = (n == name)
        TweenService:Create(o.Button, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundColor3 = a and TH.AccentDim or TH.Surface}):Play()
        TweenService:Create(o.Bar, TweenInfo.new(0.25), {BackgroundTransparency = a and 0 or 1}):Play()
        TweenService:Create(o.Icon, TweenInfo.new(0.25), {TextColor3 = a and TH.AccentGlow or TH.TextDim}):Play()
        TweenService:Create(o.Label, TweenInfo.new(0.25), {TextColor3 = a and Color3.new(1,1,1) or TH.TextDim}):Play()
    end
    self._activeTab = name
end

function UI:CreateWatermark(text)
    local wm = Instance.new("Frame")
    wm.Name = "Watermark"
    wm.Size = UDim2.new(0, 340, 0, 32)
    wm.Position = UDim2.new(0, 20, 0, 20)
    wm.BackgroundColor3 = TH.Surface
    wm.BorderSizePixel = 0
    wm.ZIndex = 998
    wm.Visible = true
    wm.Parent = self._currentWindow.Gui
    corner(wm, 9)
    stroke(wm, TH.BorderLight, 1, 0.4)
    local wGrad = Instance.new("UIGradient")
    wGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TH.AccentDim), ColorSequenceKeypoint.new(1, TH.Accent2) })
    wGrad.Rotation = 0
    wGrad.Parent = wm
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 0.6, 0)
    accentBar.Position = UDim2.new(0, 0, 0.5, 0)
    accentBar.AnchorPoint = Vector2.new(0, 0.5)
    accentBar.BackgroundColor3 = Color3.new(1,1,1)
    accentBar.BorderSizePixel = 0
    accentBar.BackgroundTransparency = 0.3
    accentBar.ZIndex = 999
    accentBar.Parent = wm
    corner(accentBar, 2)
    local wmText = Instance.new("TextLabel")
    wmText.Size = UDim2.new(1, -24, 1, 0)
    wmText.Position = UDim2.new(0, 16, 0, 0)
    wmText.BackgroundTransparency = 1
    wmText.Text = text or "LITHIUM"
    wmText.TextColor3 = Color3.new(1,1,1)
    wmText.Font = TH.FontBold
    wmText.TextSize = 11
    wmText.TextXAlignment = Enum.TextXAlignment.Left
    wmText.ZIndex = 1000
    wmText.Parent = wm
    return wm
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if UI._currentWindow and UI._currentWindow.Gui then
            if not UI._currentWindow.Gui.Enabled and UI._activePicker then
                pcall(function() UI._activePicker:Destroy() end)
                UI._activePicker = nil
            end
        end
    end
end)

return UI
