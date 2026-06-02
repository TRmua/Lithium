--[Lithium]
getgenv().lithium = false
local font_path = "Lithium/Fonts/proggyclean.ttf"
local json_path = "Lithium/Fonts/proggyclean.json"

do
    if not game:IsLoaded() then game.Loaded:Wait() end
    if getgenv().lithium then return end
    getgenv().lithium = true
end

do
    if not LPH_OBFUSCATED then
        LPH_JIT = function(...) return ... end
        LPH_JIT_MAX = function(...) return ... end
        LPH_NO_VIRTUALIZE = function(...) return ... end
        LPH_NO_UPVALUES = function(f) return(function(...) return f(...) end) end
        LPH_ENCSTR = function(...) return ... end
        LPH_ENCNUM = function(...) return ... end
        LPH_CRASH = function() return print(debug.traceback()) end

        if not require or not request or not cloneref then
            return game.Players.LocalPlayer:Kick("Error - Unsupported executor.")
        end
        if not gethui then 
            gethui = function() return cloneref(game.Players.LocalPlayer.CoreGui) end 
        end
    end
end

local Services = setmetatable({}, {
    __index = function(_, Index) return cloneref(game:GetService(Index)) end
})

local player_list_module = nil
LPH_JIT_MAX(function()
    for _, v in getgc(true) do
        if type(v) == "table" and rawget(v, "GetStreamedInCharacters") and rawget(v, "GetPlayerFromCharacter") then
            player_list_module = v
            break
        end
    end
end)()

local vars = {
    plrs = Services.Players,
    uis = Services.UserInputService,
    rs = Services.RunService,
    hs = Services.HttpService,
    lighting = Services.Lighting,
    rstorage = Services.ReplicatedStorage,
    tservice = Services.TweenService,
    Chat = Services.Chat,
    rfirst = Services.ReplicatedFirst,
    collection = Services.CollectionService,
    gethui = gethui and gethui(),
    tserv = Services.TextService
}

setmetatable(vars, {
    __index = function(t, k)
        if k == "camera" then
            return workspace.CurrentCamera
        end
        return nil
    end
})

local func_vars = {
    c3 = Color3.fromRGB, nVec2 = Vector2.new, floor = math.floor,
    studs_to_meters = function(studs) return studs * 0.28 end,
    pos_to_vec = function(pos) return vars.camera:WorldToViewportPoint(pos) end
}

local esp_cache = { drawings = {} }
local hud_drawings = {
    bg = Drawing.new("Square"),
    title = Drawing.new("Text"),
    equip = Drawing.new("Text"),
    items = {}
}
for i = 1, 15 do
    local t = Drawing.new("Text")
    t.Size = 15; t.Color = Color3.new(1,1,1); t.Outline = true; t.ZIndex = 2; t.Visible = false
    hud_drawings.items[i] = t
end
hud_drawings.bg.Color = Color3.fromRGB(30, 30, 30); hud_drawings.bg.Transparency = 0.7
hud_drawings.bg.Filled = true; hud_drawings.bg.Thickness = 0; hud_drawings.bg.ZIndex = 1
hud_drawings.title.Size = 17; hud_drawings.title.Color = Color3.new(1,1,1); hud_drawings.title.Outline = true; hud_drawings.title.ZIndex = 2
hud_drawings.equip.Size = 13; hud_drawings.equip.Color = Color3.fromRGB(180, 180, 180); hud_drawings.equip.Outline = true; hud_drawings.equip.ZIndex = 2

local function draw_corner_box(d, b_pos, b_size, color, trans, outline_enabled, outline_color)
    local x, y, w, h = b_pos.X, b_pos.Y, b_size.X, b_size.Y
    local cLen = w * 0.25 

    local lines = {
        {func_vars.nVec2(x, y), func_vars.nVec2(x + cLen, y)},
        {func_vars.nVec2(x, y), func_vars.nVec2(x, y + cLen)},
        {func_vars.nVec2(x + w, y), func_vars.nVec2(x + w - cLen, y)},
        {func_vars.nVec2(x + w, y), func_vars.nVec2(x + w, y + cLen)},
        {func_vars.nVec2(x, y + h), func_vars.nVec2(x + cLen, y + h)},
        {func_vars.nVec2(x, y + h), func_vars.nVec2(x, y + h - cLen)},
        {func_vars.nVec2(x + w, y + h), func_vars.nVec2(x + w - cLen, y + h)},
        {func_vars.nVec2(x + w, y + h), func_vars.nVec2(x + w, y + h - cLen)}
    }

    for i = 1, 8 do
        local l, o = d.Corners[i], d.CornerOutlines[i]
        if lines[i] then
            l.From, l.To = lines[i][1], lines[i][2]
            l.Color, l.Transparency, l.Visible = color, trans, true
            if o and outline_enabled then
                o.From, o.To = l.From, l.To
                o.Color, o.Transparency, o.Visible = outline_color, trans, true
            elseif o then o.Visible = false end
        end
    end
end

local function get_esp_drawings(id_key)
    if not esp_cache.drawings[id_key] then
        local drawings = {
            Box = Drawing.new("Square"),
            BoxOutline = Drawing.new("Square"),
            BoxFill = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
            Corners = {},
            CornerOutlines = {} 
        }
        for _ = 1, 8 do
            table.insert(drawings.Corners, Drawing.new("Line"))
            table.insert(drawings.CornerOutlines, Drawing.new("Line"))
        end
        esp_cache.drawings[id_key] = drawings
    end

    local d = esp_cache.drawings[id_key]
    d.Box.Thickness, d.Box.ZIndex = 1.5, 10
    d.BoxOutline.Thickness, d.BoxOutline.ZIndex = 3.5, 9
    d.BoxOutline.Color = Color3.new(0, 0, 0)

    for _, line in ipairs(d.Corners) do line.Thickness, line.ZIndex = 1.5, 10 end
    for _, outline in ipairs(d.CornerOutlines) do 
        outline.Thickness, outline.ZIndex, outline.Color = 3.5, 9, Color3.new(0, 0, 0)
    end

    for _, text in ipairs({d.Name, d.Distance}) do
        text.Size, text.Center, text.Outline = 15, true, true
        text.OutlineColor = Color3.new(0, 0, 0)
    end
    return d
end

local _, res = pcall(loadstring, game:HttpGet("https://raw.githubusercontent.com/TRmua/Lithium/refs/heads/main/library_main.lua"))
local Library = res and res()

local plr = vars.plrs.LocalPlayer
if not Library then plr:Kick("[L_B_Y]: Unable to load Library.") return end

local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/TRmua/Lithium/refs/heads/main/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/TRmua/Lithium/refs/heads/main/SaveManager.lua"))()

local Window = Library:CreateWindow({Title = "Lithium", Center = true, AutoShow = true})

local Tabs = { 
    Main = Window:AddTab('Main'), 
    Combat = Window:AddTab('Combat'), 
    Visuals = Window:AddTab('Visuals'),
    World = Window:AddTab('World'), 
    Settings = Window:AddTab('Settings') 
}

local gameName = pcall(function() return Services.MarketplaceService:GetProductInfo(game.PlaceId).Name end) and Services.MarketplaceService:GetProductInfo(game.PlaceId).Name or "Unknown"

local cleanText = string.format('lithium | uid: PRIVATE | game: %s', gameName)
Library:SetWatermark(cleanText)

task.spawn(function()
    task.wait(0.5) 
    
    local roots = {game:GetService("CoreGui")}
    pcall(function() table.insert(roots, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")) end)
    local success, hui = pcall(gethui)
    if success and hui then table.insert(roots, hui) end

    local targetLabel
    for _, root in ipairs(roots) do
        for _, v in pairs(root:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == cleanText then
                targetLabel = v
                break
            end
        end
        if targetLabel then break end
    end

    if targetLabel then
        targetLabel.RichText = true
        
        game:GetService("RunService").RenderStepped:Connect(function()
            local accent = Color3.fromRGB(255, 255, 255)
            if typeof(Options) == "table" and Options.AccentColor then
                accent = Options.AccentColor.Value
            elseif typeof(Library) == "table" and Library.AccentColor then
                accent = Library.AccentColor
            end
            
            local hex = string.format("#%02X%02X%02X", math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255))
            targetLabel.Text = string.format('lithium | uid: <font color="%s">PRIVATE</font> | game: <font color="%s">%s</font>', hex, hex, gameName)
            
            local topFrame = targetLabel
            for _ = 1, 4 do
                if topFrame.Parent and topFrame.Parent:IsA("Frame") then
                    topFrame = topFrame.Parent
                end
            end
            
            for _, v in pairs(topFrame:GetDescendants()) do
                if v:IsA("UIStroke") then
                    local grad = v:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", v)
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                    })
                elseif v:IsA("Frame") and v ~= targetLabel then
                    if v.Size.Y.Offset <= 2 and (v.Size.X.Scale == 1 or v.Size.X.Offset > 10) then
                        local grad = v:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", v)
                        grad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, accent),
                            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                        })
                    elseif v.Size.X.Offset <= 2 and (v.Size.Y.Scale == 1 or v.Size.Y.Offset > 10) then
                        if v.Position.X.Scale > 0.5 or v.Position.X.Offset > 50 then
                            v.BackgroundColor3 = Color3.new(0, 0, 0)
                            local grad = v:FindFirstChildOfClass("UIGradient")
                            if grad then grad:Destroy() end
                        else
                            v.BackgroundColor3 = accent
                            local grad = v:FindFirstChildOfClass("UIGradient")
                            if grad then grad:Destroy() end
                        end
                    end
                end
            end
        end)
    end
end)

Tabs.Main:AddLeftGroupbox('Status'):AddLabel("script works")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder('LithiumProject')
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
ThemeManager:ApplyToTab(Tabs.Settings)

ThemeManager:ApplyTheme('Default')

Library:Notify("Loading Lithium...")

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local RunService = game:GetService("RunService")

local WorldLeft = Tabs.World:AddLeftGroupbox("World")
local WorldRight = Tabs.World:AddRightGroupbox("Lighting")

WorldLeft:AddToggle('RemoveClouds', {
    Text = 'Remove Clouds', 
    Default = false, 
    Callback = function(s)
        local clouds = Terrain:FindFirstChildOfClass("Clouds")
        if clouds then clouds.Enabled = not s end
    end
})

WorldLeft:AddToggle('RemoveGrass', {
    Text = 'Remove Grass', 
    Default = false, 
    Callback = function(s) 
        sethiddenproperty(Terrain, "Decoration", not s) 
    end
})

local currentFoliageAlpha = 0

WorldLeft:AddSlider('FoliageAlpha', {
    Text = 'Foliage Transparency', 
    Default = 0.5, 
    Min = 0, 
    Max = 1, 
    Rounding = 2,
    Suffix = '',
    Callback = function(alpha)
        currentFoliageAlpha = alpha
    end
})

task.spawn(function()
    while task.wait(1.5) do
        local static = workspace:FindFirstChild('world_assets') and workspace.world_assets:FindFirstChild('StaticObjects')
        if static then
            local folders = {static:FindFirstChild('Trees'), static:FindFirstChild('Foliage')}
            for _, folder in ipairs(folders) do
                if folder then
                    for _, obj in ipairs(folder:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local name = string.lower(obj.Name)
                            
                            if name:find("leaf") or name:find("leaves") or name:find("canopy") or name:find("bush") or folder.Name == "Foliage" then
                                if obj.Transparency ~= currentFoliageAlpha then
                                    obj.Transparency = currentFoliageAlpha
                                    if currentFoliageAlpha == 1 then
                                        obj.CanCollide = false
                                    end
                                end
                            end
                            
                        end
                    end
                end
            end
        end
    end
end)

WorldLeft:AddToggle('SkyboxToggle', { Text = 'Skybox Changer', Default = false })

local SkyBoxes = {
    ["Standard"] = {"rbxassetid://600835355", "rbxassetid://600835406", "rbxassetid://600835431", "rbxassetid://600835306", "rbxassetid://600835265", "rbxassetid://600835384"},
    ["Among Us"] = {"rbxassetid://5752463190", "rbxassetid://5752463190", "rbxassetid://5752463190", "rbxassetid://5752463190", "rbxassetid://5752463190", "rbxassetid://5752463190"},
    ["Spongebob"] = {"rbxassetid://277099484", "rbxassetid://277099500", "rbxassetid://277099554", "rbxassetid://277099531", "rbxassetid://277099589", "rbxassetid://277101591"},
    ["Deep Space"] = {"rbxassetid://159248188", "rbxassetid://159248183", "rbxassetid://159248187", "rbxassetid://159248173", "rbxassetid://159248192", "rbxassetid://159248176"},
    ["Winter"] = {"rbxassetid://510645155", "rbxassetid://510645130", "rbxassetid://510645179", "rbxassetid://510645117", "rbxassetid://510645146", "rbxassetid://510645195"},
    ["Clouded Sky"] = {"rbxassetid://252760981", "rbxassetid://252763035", "rbxassetid://252761439", "rbxassetid://252760980", "rbxassetid://252760986", "rbxassetid://252762652"}
}

WorldLeft:AddDropdown('SkyboxSelect', {
    Text = 'Skybox', 
    Values = {"Standard", "Among Us", "Spongebob", "Deep Space", "Winter", "Clouded Sky"}, 
    Default = 1
})

WorldRight:AddToggle('RemoveShadows', {
    Text = 'Remove Shadows', 
    Default = false, 
    Callback = function(s) Lighting.GlobalShadows = not s end
})

WorldRight:AddToggle('RemoveFog', { Text = 'Remove Fog', Default = false })
WorldRight:AddToggle('NoRain', { Text = 'No Rain', Default = false })
WorldRight:AddToggle('TimeOfDayToggle', { Text = 'Time of Day', Default = false })

WorldRight:AddSlider('TimeSlider', {
    Text = 'Time (h)', 
    Default = 12, 
    Min = 0, 
    Max = 24, 
    Rounding = 1,
    Suffix = ' h'
})

WorldRight:AddToggle('CustomLightingToggle', { Text = 'Custom Lighting', Default = false })

WorldRight:AddSlider('BrightnessSlider', {
    Text = 'Brightness', 
    Default = 5, 
    Min = 0, 
    Max = 10, 
    Rounding = 1,
    Suffix = ' x'
})

WorldRight:AddLabel('Ambient'):AddColorPicker('AmbientColor', { Default = Color3.fromRGB(170, 0, 255) })
WorldRight:AddLabel('Outdoor Ambient'):AddColorPicker('OutdoorAmbientColor', { Default = Color3.fromRGB(170, 0, 255) })
WorldRight:AddLabel('Color Shift Top'):AddColorPicker('ColorShiftTop', { Default = Color3.fromRGB(0, 0, 0) })
WorldRight:AddLabel('Color Shift Bottom'):AddColorPicker('ColorShiftBottom', { Default = Color3.fromRGB(0, 0, 0) })

WorldRight:AddToggle('CustomAtmosphereToggle', { Text = 'Custom Atmosphere', Default = false })

WorldRight:AddSlider('AtmosOffset', { Text = 'Offset', Default = 1, Min = 0, Max = 1, Rounding = 2 })
WorldRight:AddSlider('AtmosGlare', { Text = 'Glare', Default = 1, Min = 0, Max = 1, Rounding = 2 })
WorldRight:AddSlider('AtmosHaze', { Text = 'Haze', Default = 0, Min = 0, Max = 10, Rounding = 1 })

WorldRight:AddLabel('Atmosphere Color'):AddColorPicker('AtmosColor', { Default = Color3.fromRGB(200, 200, 200) })
WorldRight:AddLabel('Atmosphere Decay'):AddColorPicker('AtmosDecay', { Default = Color3.fromRGB(100, 130, 160) })

RunService.RenderStepped:Connect(function()
    if Toggles.SkyboxToggle.Value then
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        local a = SkyBoxes[Options.SkyboxSelect.Value]
        if a then
            sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = a[1], a[2], a[3], a[4], a[5], a[6]
        end
    end

    if Toggles.RemoveFog.Value then
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0 end
        Lighting.FogEnd = 9e9 
    end

    if Toggles.NoRain.Value then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") and string.lower(v.Name):find("rain") then
                v.Enabled = false
            end
        end
    end

    if Toggles.TimeOfDayToggle.Value then
        Lighting.ClockTime = Options.TimeSlider.Value
    end

    if Toggles.CustomLightingToggle.Value then
        Lighting.Brightness = Options.BrightnessSlider.Value
        Lighting.Ambient = Options.AmbientColor.Value
        Lighting.OutdoorAmbient = Options.OutdoorAmbientColor.Value
        Lighting.ColorShift_Top = Options.ColorShiftTop.Value
        Lighting.ColorShift_Bottom = Options.ColorShiftBottom.Value
    end

    if Toggles.CustomAtmosphereToggle.Value then
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atm.Offset = Options.AtmosOffset.Value
            atm.Glare = Options.AtmosGlare.Value
            atm.Haze = Options.AtmosHaze.Value
            atm.Color = Options.AtmosColor.Value
            atm.Decay = Options.AtmosDecay.Value
        end
    end
end)

local BoxGroup = Tabs.Visuals:AddLeftGroupbox("Boxes")
BoxGroup:AddToggle("box_enabled", {Text = "Box Enabled", Default = false})
BoxGroup:AddDropdown("box_type", {Text = "Box Type", Default = "corner", Values = {"2D", "corner"}})
BoxGroup:AddSlider("box_trans", {Text = "Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%"})
BoxGroup:AddLabel("Color"):AddColorPicker("box_color", {Default = Color3.fromRGB(255, 255, 255)})

BoxGroup:AddToggle("box_fill", {Text = "Box Fill", Default = false})
BoxGroup:AddSlider("fill_trans", {Text = "Fill Transparency", Default = 0.5, Min = 0.1, Max = 1, Rounding = 1})
BoxGroup:AddLabel("Fill Color"):AddColorPicker("fill_color", {Default = Color3.fromRGB(255, 255, 255)})

BoxGroup:AddToggle("box_outline", {Text = "Boxes Outline", Default = true})
BoxGroup:AddLabel("Outline Color"):AddColorPicker("outline_color", {Default = Color3.fromRGB(0, 0, 0)})
BoxGroup:AddSlider("render_range", {Text = "Render Range", Default = 600, Min = 0, Max = 5000, Rounding = 0, Suffix = " st"})

local NameGroup = Tabs.Visuals:AddRightGroupbox("Names")
local InvGroup = Tabs.Visuals:AddLeftGroupbox("Inventory Viewer")
InvGroup:AddToggle("inv_enabled", {Text = "Enable Inventory HUD", Default = false})
InvGroup:AddSlider("inv_x", {Text = "Pos X", Default = 150, Min = 0, Max = 2000, Rounding = 0})
InvGroup:AddSlider("inv_y", {Text = "Pos Y", Default = 150, Min = 0, Max = 1500, Rounding = 0})

NameGroup:AddToggle("name_enabled", {Text = "Name Enabled", Default = false})
NameGroup:AddSlider("name_trans", {Text = "Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%"})
NameGroup:AddLabel("Color"):AddColorPicker("name_color", {Default = Color3.fromRGB(255, 255, 255)})
NameGroup:AddToggle("dist_enabled", {Text = "Show Distance", Default = false})
NameGroup:AddLabel("Distance Color"):AddColorPicker("dist_color", {Default = Color3.fromRGB(255, 255, 0)})

local SkelGroup = Tabs.Visuals:AddRightGroupbox("Skeletons")
SkelGroup:AddToggle("skel_enabled", {Text = "Skeleton Enabled", Default = false})
SkelGroup:AddLabel("Color"):AddColorPicker("skel_color", {Default = Color3.fromRGB(255, 255, 255)})

--\\SETUP INVENTORY HUD
local CoreGui = game:GetService("CoreGui")
local OmenInvGui = CoreGui:FindFirstChild("OmenInventoryViewer")
local InvFrame, TitleLabel
local omen_slots = {}

if not OmenInvGui then
    OmenInvGui = Instance.new("ScreenGui")
    OmenInvGui.Name = "OmenInventoryViewer"
    OmenInvGui.Parent = CoreGui

    InvFrame = Instance.new("Frame")
    InvFrame.Name = "MainFrame"
    InvFrame.AutomaticSize = Enum.AutomaticSize.Y
    InvFrame.Size = UDim2.new(0, 350, 0, 0)
    InvFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    InvFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    InvFrame.BorderSizePixel = 0
    InvFrame.Position = UDim2.new(1, -20, 0.4, 0)
    InvFrame.AnchorPoint = Vector2.new(1, 0)
    InvFrame.Visible = false
    InvFrame.Parent = OmenInvGui

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = InvFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 10)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = InvFrame

    TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Size = UDim2.new(1, 0, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.LayoutOrder = 1
    TitleLabel.Parent = InvFrame

    for i = 1, 5 do
        local slot = Instance.new("TextLabel")
        slot.Name = "Slot" .. i
        slot.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
        slot.RichText = true
        slot.TextColor3 = Color3.fromRGB(255, 255, 255)
        slot.TextSize = 15
        slot.TextXAlignment = Enum.TextXAlignment.Left
        slot.Size = UDim2.new(1, 0, 0, 18)
        slot.BackgroundTransparency = 1
        slot.LayoutOrder = i + 1
        slot.Parent = InvFrame
        omen_slots[i] = slot
    end
else
    InvFrame = OmenInvGui:FindFirstChild("MainFrame")
    if InvFrame then
        TitleLabel = InvFrame:FindFirstChild("TitleLabel")
        for i = 1, 5 do
            omen_slots[i] = InvFrame:FindFirstChild("Slot" .. i)
        end
    end
end

--\LOGIC
vars.rs.RenderStepped:Connect(function()
    local active_drawings = {}
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local target_for_hud = LocalPlayer
    local closest_crosshair_dist = 250
    local screen_center = func_vars.nVec2(vars.camera.ViewportSize.X / 2, vars.camera.ViewportSize.Y / 2)
    
    if player_list_module then
        local box_en = Toggles.box_enabled.Value
        local box_out = Toggles.box_outline.Value
        local box_fill = Toggles.box_fill.Value
        local name_en = Toggles.name_enabled.Value
        local dist_en = Toggles.dist_enabled.Value
        local b_type = Options.box_type.Value
        local cam_cframe_pos = vars.camera.CFrame.Position
        local viewport_size = vars.camera.ViewportSize
        
        for _, char in pairs(player_list_module:GetStreamedInCharacters()) do
            local fake_player = player_list_module:GetPlayerFromCharacter(char)
            if fake_player and fake_player ~= LocalPlayer then
                local char_cframe, char_size = char:GetBoundingBox()
                local pos, on_screen = func_vars.pos_to_vec(char_cframe.Position)
                local dist_studs = (cam_cframe_pos - char_cframe.Position).Magnitude
                
                if on_screen and dist_studs <= Options.render_range.Value then
                    local crosshair_dist = (func_vars.nVec2(pos.X, pos.Y) - screen_center).Magnitude
                    if crosshair_dist < closest_crosshair_dist then
                        closest_crosshair_dist = crosshair_dist
                        target_for_hud = fake_player
                    end
                    
                    active_drawings[fake_player.Name] = true
                    local d = get_esp_drawings(fake_player.Name)
                    local head_2d = func_vars.pos_to_vec(char_cframe.Position + Vector3.new(0, char_size.Y / 2, 0))
                    local foot_2d = func_vars.pos_to_vec(char_cframe.Position - Vector3.new(0, char_size.Y / 2, 0))
                    
                    if head_2d and foot_2d then
                        local size_y = math.abs(head_2d.Y - foot_2d.Y)
                        local size_x = math.clamp(size_y * 0.55, 10, viewport_size.X)
                        size_y = math.clamp(size_y, 18, viewport_size.Y)
                        local b_pos = func_vars.nVec2(pos.X - size_x/2, head_2d.Y)
                        local b_size = func_vars.nVec2(size_x, size_y)
                        local b_trans = 1 - (Options.box_trans.Value / 100)
                        
                        if box_en then
                            if b_type == "2D" then
                                d.Box.Visible = true; d.Box.Position = b_pos; d.Box.Size = b_size
                                d.Box.Color = Options.box_color.Value; d.Box.Transparency = b_trans
                                if d.Corners then for _, l in pairs(d.Corners) do l.Visible = false end end
                                if d.CornerOutlines then for _, o in pairs(d.CornerOutlines) do o.Visible = false end end
                                d.BoxOutline.Visible = box_out
                                if box_out then 
                                    d.BoxOutline.Position = b_pos; d.BoxOutline.Size = b_size
                                    d.BoxOutline.Color = Options.outline_color.Value; d.BoxOutline.Transparency = b_trans 
                                end
                            else
                                d.Box.Visible = false; d.BoxOutline.Visible = false
                                draw_corner_box(d, b_pos, b_size, Options.box_color.Value, b_trans, box_out, Options.outline_color.Value)
                            end
                            if box_fill then
                                d.BoxFill.Visible = true; d.BoxFill.Position = func_vars.nVec2(b_pos.X + 1, b_pos.Y + 1)
                                d.BoxFill.Size = func_vars.nVec2(b_size.X - 2, b_size.Y - 2); d.BoxFill.Color = Options.fill_color.Value
                                d.BoxFill.Transparency = tonumber(Options.fill_trans.Value) or 0.5; d.BoxFill.Filled = true
                            else d.BoxFill.Visible = false end
                        else
                            d.Box.Visible = false; d.BoxOutline.Visible = false; d.BoxFill.Visible = false
                        end
                        
                        if name_en then
                            d.Name.Text = fake_player.Name; d.Name.Position = func_vars.nVec2(pos.X, b_pos.Y - 15)
                            d.Name.Color = Options.name_color.Value; d.Name.Visible = true
                        else d.Name.Visible = false end
                        
                        if dist_en then
                            d.Distance.Text = "[" .. func_vars.floor(func_vars.studs_to_meters(dist_studs)) .. "m]"
                            d.Distance.Position = func_vars.nVec2(pos.X, b_pos.Y + size_y + 2)
                            d.Distance.Color = Options.dist_color.Value; d.Distance.Visible = true
                        else d.Distance.Visible = false end
                    end
                end
            end
        end
    end

    --\\INVENTORY HUD
    if Toggles.inv_enabled and Toggles.inv_enabled.Value and target_for_hud ~= LocalPlayer then
        local inv = target_for_hud:FindFirstChild("GunInventory")
        
        if InvFrame then 
            InvFrame.Visible = true 
            InvFrame.Position = UDim2.new(0, Options.inv_x.Value, 0, Options.inv_y.Value)
            
            if TitleLabel then
                TitleLabel.Text = target_for_hud.Name .. "'s Inventory"
            end
            
            local slot_texts = {
                [1] = "1 -> <font color='rgb(144,144,144)'>Fist</font> [<font color='rgb(115, 36, 223)'>0/0</font>]", 
                [2] = "2 -> <font color='rgb(144,144,144)'>Fist</font> [<font color='rgb(115, 36, 223)'>0/0</font>]", 
                [3] = "3 -> <font color='rgb(144,144,144)'>Fist</font> [<font color='rgb(115, 36, 223)'>0/0</font>]", 
                [4] = "4 -> <font color='rgb(144,144,144)'>Fist</font>"
            }
            
            if inv then
                local currentSelected = inv:FindFirstChild("CurrentSelectedObject")
                local activeSlot = currentSelected and currentSelected.Value
                
                for _, itemFolder in pairs(inv:GetChildren()) do
                    local slotObj = itemFolder:FindFirstChild("Slot")
                    if slotObj then
                        local slotIndex = slotObj.Value 
                        if slotIndex >= 1 and slotIndex <= 4 then
                            local itemName = "Fist"
                            if itemFolder:IsA("ObjectValue") and itemFolder.Value then itemName = itemFolder.Value.Name
                            elseif itemFolder:IsA("StringValue") and itemFolder.Value ~= "" then itemName = itemFolder.Value
                            else 
                                local attrName = itemFolder:GetAttribute("ClassName") or itemFolder:GetAttribute("ItemId")
                                if attrName then itemName = attrName end
                            end
                            
                            itemName = string.gsub(itemName, "Equipment", "")
                            itemName = string.gsub(itemName, "Item", "")
                            itemName = string.gsub(itemName, "item", "")
                            
                            if itemName == "UnknownGun" or itemName == "nil" or itemName == "" or itemName == "Empty" then 
                                itemName = "Fist" 
                            end
                            
                            local mag = itemFolder:FindFirstChild("BulletsInMagazine")
                            local res = itemFolder:FindFirstChild("BulletsInReserve")
                            local magVal = mag and mag.Value or "0"
                            local resVal = res and res.Value or "0"
                            
                            if itemName == "Fist" or itemName == "Fists" then 
                                magVal = "0"; resVal = "0"; itemName = "Fist" 
                            end
                            
                            local txt = ""
                            if slotIndex == 4 then
                                txt = string.format("%d -> <font color='rgb(144,144,144)'>%s</font>", slotIndex, itemName)
                            else
                                txt = string.format("%d -> <font color='rgb(144,144,144)'>%s</font> [<font color='rgb(115, 36, 223)'>%s/%s</font>]", slotIndex, itemName, magVal, resVal)
                            end
                            
                            if itemFolder == activeSlot then 
                                txt = ">> " .. txt .. " <<" 
                            end
                            
                            slot_texts[slotIndex] = txt
                        end
                    end
                end
            end
            
            for i = 1, 4 do
                if omen_slots[i] then omen_slots[i].Text = slot_texts[i] end
            end
            
            if type(get_equip) == "function" then
                local bp = get_equip(target_for_hud, "EquipmentBackpack") or "None"
                local mask = get_equip(target_for_hud, "EquipmentMask") or "None"
                local pts = get_equip(target_for_hud, "EquipmentPants") or "None"
                local shirt = get_equip(target_for_hud, "EquipmentShirt") or "None"
                
                if omen_slots[5] then
                    omen_slots[5].Text = string.format("%s, %s, %s, %s", bp, mask, pts, shirt)
                end
            end
        end
    else
        if InvFrame then 
            InvFrame.Visible = false 
        end
    end

    --\\DRAWINGS
    if esp_cache and esp_cache.drawings then
        for id, drawings in pairs(esp_cache.drawings) do
            if not active_drawings[id] then
                if drawings.Box.Visible or drawings.Name.Visible then
                    drawings.Box.Visible = false; drawings.BoxOutline.Visible = false; drawings.BoxFill.Visible = false
                    drawings.Name.Visible = false; drawings.Distance.Visible = false
                    if drawings.Corners then for _, l in pairs(drawings.Corners) do l.Visible = false end end
                    if drawings.CornerOutlines then for _, o in pairs(drawings.CornerOutlines) do o.Visible = false end end
                end
            end
        end
    end
end)

print("ESP Active!")
    
if Library and Library.Notify then
    Library:Notify("Welcome to Lithium", 5)
end
