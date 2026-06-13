local Drawing = {}
local drawingGui = Instance.new("ScreenGui")
drawingGui.Name = "LithiumESP_Internal"
drawingGui.IgnoreGuiInset = true
drawingGui.DisplayOrder = 999

pcall(function()
    drawingGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end)

function Drawing.new(drawingType)
    local props = {
        Visible = false, ZIndex = 1, Transparency = 1, Color = Color3.new(1,1,1),
        Thickness = 1, Position = Vector2.new(0,0), Size = Vector2.new(0,0),
        Text = "", Center = false, Outline = false, OutlineColor = Color3.new(0,0,0),
        Filled = false, From = Vector2.new(0,0), To = Vector2.new(0,0)
    }

    local inst
    if drawingType == "Square" then
        inst = Instance.new("Frame")
        inst.BackgroundTransparency = 1
        inst.BorderSizePixel = 0
        local stroke = Instance.new("UIStroke", inst)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.LineJoinMode = Enum.LineJoinMode.Miter
    elseif drawingType == "Text" then
        inst = Instance.new("TextLabel")
        inst.BackgroundTransparency = 1
        inst.Size = UDim2.new(0, 200, 0, 20)
        inst.Font = Enum.Font.Roboto
        inst.TextSize = 13
        inst.TextWrapped = true
        inst.AutomaticSize = Enum.AutomaticSize.Y
        inst.TextYAlignment = Enum.TextYAlignment.Top
        inst.TextXAlignment = Enum.TextXAlignment.Left
        local stroke = Instance.new("UIStroke", inst)
        stroke.Enabled = false
        stroke.Thickness = 1
        stroke.Transparency = 0
    elseif drawingType == "Line" then
        inst = Instance.new("Frame")
        inst.AnchorPoint = Vector2.new(0.5, 0.5)
        inst.BorderSizePixel = 0
    end

    inst.Visible = false
    inst.Parent = drawingGui

    local proxy = setmetatable({}, {
        __index = props,
        __newindex = function(_, key, value)
            props[key] = value
            local rTrans = 1 - (props.Transparency or 1)

            if key == "Visible" then
                inst.Visible = value
            elseif key == "ZIndex" then
                inst.ZIndex = value
            elseif key == "Transparency" or key == "Filled" then
                if drawingType == "Text" then
                    inst.TextTransparency = rTrans
                    local stroke = inst:FindFirstChild("UIStroke")
                    if stroke then
                        stroke.Transparency = rTrans
                    end
                elseif drawingType == "Square" then
                    if props.Filled then
                        inst.BackgroundTransparency = rTrans
                        if inst:FindFirstChild("UIStroke") then inst.UIStroke.Enabled = false end
                    else
                        inst.BackgroundTransparency = 1
                        if inst:FindFirstChild("UIStroke") then
                            inst.UIStroke.Enabled = true
                            inst.UIStroke.Transparency = rTrans
                        end
                    end
                elseif drawingType == "Line" then
                    inst.BackgroundTransparency = rTrans
                end
            elseif key == "Color" then
                if drawingType == "Text" then
                    inst.TextColor3 = value
                elseif drawingType == "Square" then
                    inst.BackgroundColor3 = value
                    if inst:FindFirstChild("UIStroke") then inst.UIStroke.Color = value end
                else
                    inst.BackgroundColor3 = value
                end
            elseif key == "Position" then
                if drawingType ~= "Line" then
                    if drawingType == "Text" and props.Center then
                        inst.Position = UDim2.new(0, value.X, 0, value.Y)
                        inst.AnchorPoint = Vector2.new(0.5, 0)
                        inst.TextXAlignment = Enum.TextXAlignment.Center
                    elseif drawingType == "Text" then
                        inst.Position = UDim2.new(0, value.X + 4, 0, value.Y + 4)
                        inst.AnchorPoint = Vector2.new(0, 0)
                        inst.TextXAlignment = Enum.TextXAlignment.Left
                    else
                        inst.Position = UDim2.new(0, value.X, 0, value.Y)
                        inst.AnchorPoint = Vector2.new(0, 0)
                    end
                end
            elseif key == "Size" then
                if drawingType == "Square" then
                    inst.Size = UDim2.new(0, value.X, 0, value.Y)
                elseif drawingType == "Text" then
                    inst.Size = UDim2.new(0, value.X, 0, value.Y)
                end
            elseif key == "Text" and drawingType == "Text" then
                inst.Text = value
            elseif key == "Center" and drawingType == "Text" then
                if value then
                    inst.AnchorPoint = Vector2.new(0.5, 0)
                    inst.TextXAlignment = Enum.TextXAlignment.Center
                else
                    inst.AnchorPoint = Vector2.new(0, 0)
                    inst.TextXAlignment = Enum.TextXAlignment.Left
                end
            elseif key == "Outline" then
                local stroke = inst:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Enabled = value
                end
            elseif key == "OutlineColor" then
                local stroke = inst:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Color = value
                end
            elseif key == "Thickness" then
                local stroke = inst:FindFirstChild("UIStroke")
                if stroke and drawingType == "Square" then
                    stroke.Thickness = math.max(1, math.floor(value + 0.5))
                end
                if drawingType == "Line" and props.From and props.To then
                    inst.Size = UDim2.new(0, (props.To - props.From).Magnitude, 0, math.max(1, math.floor(value + 0.5)))
                end
            elseif (key == "From" or key == "To") and drawingType == "Line" then
                if props.From and props.To then
                    local dir = props.To - props.From
                    local center = (props.To + props.From) / 2
                    inst.Position = UDim2.new(0, center.X, 0, center.Y)
                    inst.Size = UDim2.new(0, dir.Magnitude, 0, props.Thickness or 1)
                    inst.Rotation = math.deg(math.atan2(dir.Y, dir.X))
                end
            end
        end
    })

    function proxy:Remove()
        inst:Destroy()
    end

    return proxy
end

return Drawing
