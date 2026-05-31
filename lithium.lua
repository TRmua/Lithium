--\\[Lithium]
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

Library:Notify("Welcome to Lithium")

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
BoxGroup:AddSlider("render_range", {Text = "Render Range", Default = 1000, Min = 0, Max = 5000, Rounding = 0, Suffix = " st"})

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

local function gsub_itemname(name) return name and name:gsub("Equipment", "") or "Empty" end

local function update_invviewer(target)
    if target and (tserv and tserv.visuals and tserv.visuals.player_infoboard) then
        if playerinv then playerinv.Visible = true end
        local target_player = vars.plrs:FindFirstChild(target.Name)
        if target_player then
            local inventory = target_player:FindFirstChild("GunInventory")
            if inventory and player1 then
                player1.Text = " " .. target.Name .. "'s Inventory "
                for i, slot in ipairs(tables.slots) do
                    if i <= 4 then
                        local slotItem = inventory:FindFirstChild("Slot" .. i)
                        if slotItem then
                            local mag, reserve = slotItem:FindFirstChild("BulletsInMagazine"), slotItem:FindFirstChild("BulletsInReserve")
                            local muzzle, reticle = slotItem:FindFirstChild("AttachmentMuzzle"), slotItem:FindFirstChild("AttachmentReticle")
                            local ammo, attachments = "[--/--]", "[--/--]"
                            if mag and reserve then ammo = string.format("%s/%s", tostring(mag.Value or "--"), tostring(reserve.Value or "--")) end
                            if muzzle and reticle then attachments = string.format("%s/%s", tostring(muzzle.Value or "--"), tostring(reticle.Value or "--")) end
                            slot.Text = string.format("%d -> <font color='rgb(144,144,144)'>%s</font> [<font color='rgb(115, 36, 223)'>%s</font>] [<font color='rgb(115, 36, 223)'>%s</font>]", i, tostring(slotItem.Value), ammo, attachments)
                        else
                            slot.Text = string.format("%d -> <font color='rgb(144,144,144)'>Empty</font> [<font color='rgb(115, 36, 223)'>--/--</font>] [<font color='rgb(115, 36, 223)'>--/--</font>]", i)
                        end
                    elseif i == 5 then
                        local bp = gsub_itemname(target:GetAttribute("EquipmentBackpack"))
                        local mask = gsub_itemname(target:GetAttribute("EquipmentMask"))
                        local pts = gsub_itemname(target:GetAttribute("EquipmentPants"))
                        local shirt = gsub_itemname(target:GetAttribute("EquipmentShirt"))
                        slot.Text = string.format("%s, %s, %s, %s", bp, mask, pts, shirt)
                    end
                end
            end
        end
    else
        if playerinv then playerinv.Visible = false end
    end
end

local function get_equip(target, attr_name)
    local val = target:GetAttribute(attr_name)
    if not val and target.Character then
        val = target.Character:GetAttribute(attr_name)
    end
    
    if type(val) == "string" and string.find(val, '"ClassName"') then
        local extracted = string.match(val, '"ClassName"%s*:%s*"([^"]+)"')
        if extracted then
            val = extracted
        end
    end
    
    local clean_val = val and tostring(val) or "Empty"
    clean_val = string.gsub(clean_val, "Equipment", "")
    clean_val = string.gsub(clean_val, "Item", "")
    clean_val = string.gsub(clean_val, "item", "")
    
    if clean_val == "" or clean_val == "nil" then 
        clean_val = "Empty" 
    end
    
    return clean_val
end

local function get_equip(target, attr_name)
    local val = target:GetAttribute(attr_name)
    if not val and target.Character then
        val = target.Character:GetAttribute(attr_name)
    end
    
    if type(val) == "string" and string.find(val, '"ClassName"') then
        local extracted = string.match(val, '"ClassName"%s*:%s*"([^"]+)"')
        if extracted then
            val = extracted
        end
    end
    
    local clean_val = val and tostring(val) or "Empty"
    clean_val = string.gsub(clean_val, "Equipment", "")
    clean_val = string.gsub(clean_val, "Item", "")
    clean_val = string.gsub(clean_val, "item", "")
    
    if clean_val == "" or clean_val == "nil" then 
        clean_val = "Empty" 
    end
    
    return clean_val
end

local function get_equip(target, attr_name)
    local val = target:GetAttribute(attr_name)
    if not val and target.Character then val = target.Character:GetAttribute(attr_name) end
    if type(val) == "string" and string.find(val, '"ClassName"') then
        local extracted = string.match(val, '"ClassName"%s*:%s*"([^"]+)"')
        if extracted then val = extracted end
    end
    local clean_val = val and tostring(val) or "Empty"
    clean_val = string.gsub(clean_val, "Equipment", "")
    clean_val = string.gsub(clean_val, "Item", "")
    clean_val = string.gsub(clean_val, "item", "")
    if clean_val == "" or clean_val == "nil" then clean_val = "Empty" end
    return clean_val
end

vars.rs.RenderStepped:Connect(function()
    local active_drawings = {}
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local target_for_hud = LocalPlayer
    local closest_crosshair_dist = 250
    local screen_center = func_vars.nVec2(vars.camera.ViewportSize.X / 2, vars.camera.ViewportSize.Y / 2)
    
    if player_list_module then
        for _, char in pairs(player_list_module:GetStreamedInCharacters()) do
            local fake_player = player_list_module:GetPlayerFromCharacter(char)
            if fake_player and fake_player ~= LocalPlayer then
                local player_name = fake_player.Name
                local char_cframe, char_size = char:GetBoundingBox()
                local pos, on_screen = func_vars.pos_to_vec(char_cframe.Position)
                local dist_studs = (vars.camera.CFrame.Position - char_cframe.Position).Magnitude
                
                if on_screen and dist_studs <= Options.render_range.Value then
                    local crosshair_dist = (func_vars.nVec2(pos.X, pos.Y) - screen_center).Magnitude
                    if crosshair_dist < closest_crosshair_dist then
                        closest_crosshair_dist = crosshair_dist
                        target_for_hud = fake_player
                    end
                    active_drawings[player_name] = true
                    local d = get_esp_drawings(player_name)
                    local head_3d = char_cframe.Position + Vector3.new(0, char_size.Y / 2, 0)
                    local foot_3d = char_cframe.Position - Vector3.new(0, char_size.Y / 2, 0)
                    local head_2d, on_head = func_vars.pos_to_vec(head_3d)
                    local foot_2d, on_foot = func_vars.pos_to_vec(foot_3d)
                    
                    if not head_2d or not foot_2d then continue end
                    
                    local size_y = math.abs(head_2d.Y - foot_2d.Y)
                    local size_x = size_y * 0.55
                    size_x = math.clamp(size_x, 10, vars.camera.ViewportSize.X)
                    size_y = math.clamp(size_y, 18, vars.camera.ViewportSize.Y)
                    local b_pos = func_vars.nVec2(pos.X - size_x/2, head_2d.Y)
                    local b_size = func_vars.nVec2(size_x, size_y)
                    local b_trans = 1 - (Options.box_trans.Value / 100)
                    
                    if Toggles.box_enabled.Value then
                        if Options.box_type.Value == "2D" then
                            d.Box.Visible = true; d.Box.Position = b_pos; d.Box.Size = b_size
                            d.Box.Color = Options.box_color.Value; d.Box.Transparency = b_trans
                            if d.Corners then for _, l in pairs(d.Corners) do l.Visible = false end end
                            if d.CornerOutlines then for _, o in pairs(d.CornerOutlines) do o.Visible = false end end
                            if Toggles.box_outline.Value then
                                d.BoxOutline.Visible = true; d.BoxOutline.Position = b_pos; d.BoxOutline.Size = b_size
                                d.BoxOutline.Color = Options.outline_color.Value; d.BoxOutline.Transparency = b_trans
                            else d.BoxOutline.Visible = false end
                        else
                            d.Box.Visible = false; d.BoxOutline.Visible = false
                            draw_corner_box(d, b_pos, b_size, Options.box_color.Value, b_trans, Toggles.box_outline.Value, Options.outline_color.Value)
                        end
                        if Toggles.box_fill.Value then
                            d.BoxFill.Visible = true; d.BoxFill.Position = func_vars.nVec2(b_pos.X + 1, b_pos.Y + 1)
                            d.BoxFill.Size = func_vars.nVec2(b_size.X - 2, b_size.Y - 2); d.BoxFill.Color = Options.fill_color.Value
                            d.BoxFill.Transparency = tonumber(Options.fill_trans.Value) or 0.5; d.BoxFill.Filled = true; d.BoxFill.ZIndex = 8; d.BoxFill.Thickness = 0
                        else d.BoxFill.Visible = false end
                    else
                        d.Box.Visible = false; d.BoxOutline.Visible = false; d.BoxFill.Visible = false
                        if d.Corners then for _, l in pairs(d.Corners) do l.Visible = false end end
                        if d.CornerOutlines then for _, o in pairs(d.CornerOutlines) do o.Visible = false end end
                    end
                    if Toggles.name_enabled.Value then
                        d.Name.Text = player_name; d.Name.Position = func_vars.nVec2(pos.X, b_pos.Y - 15); d.Name.Color = Options.name_color.Value
                        d.Name.Transparency = 1 - (Options.name_trans.Value / 100); d.Name.Visible = true
                    else d.Name.Visible = false end
                    if Toggles.dist_enabled.Value then
                        local meters = func_vars.floor(func_vars.studs_to_meters(dist_studs))
                        d.Distance.Text = "[" .. meters .. "m]"; d.Distance.Position = func_vars.nVec2(pos.X, b_pos.Y + size_y + 2)
                        d.Distance.Color = Options.dist_color.Value; d.Distance.Visible = true
                    else d.Distance.Visible = false end
                end
            end
        end
    end

    if Toggles.inv_enabled and Toggles.inv_enabled.Value then
        local inv = target_for_hud:FindFirstChild("GunInventory")
        local start_x, start_y = Options.inv_x.Value, Options.inv_y.Value
        local cur_y = start_y + 5
        hud_drawings.bg.Visible = true; hud_drawings.title.Visible = true
        hud_drawings.title.Text = target_for_hud.Name .. "'s Inventory"
        hud_drawings.title.Position = func_vars.nVec2(start_x + 5, cur_y)
        cur_y = cur_y + 22
        local slot_texts = {[1] = "1 -> Fist [0/0]", [2] = "2 -> Fist [0/0]", [3] = "3 -> Fist [0/0]", [4] = "4 -> Fist"}
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
                        else local attrName = itemFolder:GetAttribute("ClassName") or itemFolder:GetAttribute("ItemId")
                            if attrName then itemName = attrName end
                        end
                        itemName = string.gsub(itemName, "Equipment", ""); itemName = string.gsub(itemName, "Item", ""); itemName = string.gsub(itemName, "item", "")
                        if itemName == "UnknownGun" or itemName == "nil" or itemName == "" or itemName == "Empty" then itemName = "Fist" end
                        local mag = itemFolder:FindFirstChild("BulletsInMagazine"); local res = itemFolder:FindFirstChild("BulletsInReserve")
                        local magVal = mag and mag.Value or "0"; local resVal = res and res.Value or "0"
                        if itemName == "Fist" or itemName == "Fists" then magVal = "0"; resVal = "0"; itemName = "Fist" end
                        local txt = (slotIndex == 4) and string.format("%d -> %s", slotIndex, itemName) or string.format("%d -> %s [%s/%s]", slotIndex, itemName, magVal, resVal)
                        if itemFolder == activeSlot then txt = ">> " .. txt .. " <<" end
                        slot_texts[slotIndex] = txt
                    end
                end
            end
        end
        for i = 1, 4 do
            hud_drawings.items[i].Text = slot_texts[i]; hud_drawings.items[i].Position = func_vars.nVec2(start_x + 5, cur_y); hud_drawings.items[i].Visible = true; cur_y = cur_y + 17
        end
        local bp = get_equip(target_for_hud, "EquipmentBackpack"); local mask = get_equip(target_for_hud, "EquipmentMask"); local pts = get_equip(target_for_hud, "EquipmentPants"); local shirt = get_equip(target_for_hud, "EquipmentShirt")
        hud_drawings.equip.Text = string.format("%s, %s, %s, %s", bp, mask, pts, shirt)
        hud_drawings.equip.Position = func_vars.nVec2(start_x + 5, cur_y); hud_drawings.equip.Visible = true
        hud_drawings.bg.Position = func_vars.nVec2(start_x, start_y); hud_drawings.bg.Size = func_vars.nVec2(350, (cur_y + 20) - start_y)
    else
        hud_drawings.bg.Visible = false; hud_drawings.title.Visible = false; hud_drawings.equip.Visible = false
        for i = 1, 15 do hud_drawings.items[i].Visible = false end
    end
    for id, drawings in pairs(esp_cache.drawings) do
        if not active_drawings[id] then
            drawings.Box.Visible = false; drawings.BoxOutline.Visible = false; drawings.BoxFill.Visible = false
            drawings.Name.Visible = false; drawings.Distance.Visible = false
            if drawings.Corners then for _, l in pairs(drawings.Corners) do l.Visible = false end end
            if drawings.CornerOutlines then for _, o in pairs(drawings.CornerOutlines) do o.Visible = false end end
        end
    end
end)

if Library and Library.Notify then
    Library:Notify("Loading Lithium...", 5)
end
