local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)
local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry = {},
    RegistryMap = {},
    OpenedFrames = {},
    Signals = {},
    ScreenGui = ScreenGui,
    FontColor = Color3.fromRGB(220, 220, 220),
    MainColor = Color3.fromRGB(20, 20, 20),
    BackgroundColor = Color3.fromRGB(12, 12, 12),
    AccentColor = Color3.fromRGB(198, 107, 118),
    OutlineColor = Color3.fromRGB(45, 45, 45),
    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code
}

function Library:Create(Class, Properties)
    local _Instance = type(Class) == 'string' and Instance.new(Class) or Class
    for Property, Value in next, Properties do
        _Instance[Property] = Value
    end
    return _Instance
end

function Library:CreateLabel(Properties)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 13,
        TextStrokeTransparency = 0
    })
    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if ObjPos.Y > (Cutoff or 35) then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:CreateWindow(Config)
    local Window = { Tabs = {}, ActiveTab = nil }
    local Size = Config.Size or UDim2.fromOffset(720, 620)

    local Outer = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.Black,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = Size,
        ZIndex = 1,
        Parent = ScreenGui
    })
    Library:MakeDraggable(Outer, 32)

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2,
        Parent = Outer
    })

    local TabBar = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 28),
        ZIndex = 3,
        Parent = Inner
    })

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar
    })

    local TabContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 40),
        Size = UDim2.new(1, -12, 1, -46),
        ZIndex = 3,
        Parent = Inner
    })

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {} }

        local TabButton = Library:Create('TextButton', {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 88, 1, 0),
            Font = Library.Font,
            Text = Name,
            TextColor3 = Color3.fromRGB(160, 160, 160),
            TextSize = 13,
            ZIndex = 4,
            Parent = TabBar
        })

        local TabUnderline = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2),
            Visible = false,
            ZIndex = 5,
            Parent = TabButton
        })

        local TabFrame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            ZIndex = 3,
            Parent = TabContainer
        })

        local function CreateColumn(XScale)
            local Col = Library:Create('ScrollingFrame', {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(XScale, 0, 0, 0),
                Size = UDim2.new(0.333, -4, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Library.AccentColor,
                ZIndex = 3,
                Parent = TabFrame
            })
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Col
            })
            return Col
        end

        local LeftCol = CreateColumn(0)
        local MiddleCol = CreateColumn(0.333)
        local RightCol = CreateColumn(0.666)

        local function CreateGroupbox(Title, Column)
            local Groupbox = {}

            local BoxFrame = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 4,
                Parent = Column
            })

            local Header = Library:CreateLabel({
                BackgroundColor3 = Library.MainColor,
                BackgroundTransparency = 0,
                BorderColor3 = Library.OutlineColor,
                Size = UDim2.new(1, 0, 0, 22),
                Text = Title,
                TextSize = 13,
                ZIndex = 5,
                Parent = BoxFrame
            })

            local Content = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 26),
                Size = UDim2.new(1, -12, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 5,
                Parent = BoxFrame
            })

            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Content
            })

            Library:Create('UIPadding', {
                PaddingBottom = UDim.new(0, 6),
                Parent = Content
            })

            function Groupbox:AddToggle(Idx, Info)
                local Toggle = { Value = Info.Default or false }
                local Holder = Library:Create('TextButton', {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = '',
                    ZIndex = 6,
                    Parent = Content
                })

                local Box = Library:Create('Frame', {
                    BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    Size = UDim2.fromOffset(12, 12),
                    Position = UDim2.fromOffset(0, 2),
                    ZIndex = 7,
                    Parent = Holder
                })

                Library:CreateLabel({
                    Position = UDim2.fromOffset(18, 0),
                    Size = UDim2.new(1, -18, 1, 0),
                    Text = Info.Text or Idx,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = Holder
                })

                function Toggle:SetValue(Val)
                    Toggle.Value = Val
                    Box.BackgroundColor3 = Val and Library.AccentColor or Library.MainColor
                    if Info.Callback then Info.Callback(Val) end
                end

                Holder.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)

                Toggles[Idx] = Toggle
                return Toggle
            end

            function Groupbox:AddSlider(Idx, Info)
                local Slider = { Value = Info.Default or Info.Min }
                local Frame = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    Size = UDim2.new(1, 0, 0, 18),
                    ZIndex = 6,
                    Parent = Content
                })

                local Fill = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor,
                    BackgroundTransparency = 0.35,
                    BorderSizePixel = 0,
                    Size = UDim2.new((Slider.Value - Info.Min) / (Info.Max - Info.Min), 0, 1, 0),
                    ZIndex = 7,
                    Parent = Frame
                })

                local Label = Library:CreateLabel({
                    Position = UDim2.fromOffset(4, 0),
                    Size = UDim2.new(1, -8, 1, 0),
                    Text = Info.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 8,
                    Parent = Frame
                })

                local ValLabel = Library:CreateLabel({
                    Position = UDim2.fromOffset(4, 0),
                    Size = UDim2.new(1, -8, 1, 0),
                    Text = tostring(Slider.Value) .. (Info.Suffix or ''),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 8,
                    Parent = Frame
                })

                Frame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local Pct = math.clamp((Mouse.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X, 0, 1)
                            local Val = math.floor((Info.Min + (Info.Max - Info.Min) * Pct) * (10 ^ (Info.Rounding or 0)) + 0.5) / (10 ^ (Info.Rounding or 0))
                            Slider.Value = Val
                            Fill.Size = UDim2.new(Pct, 0, 1, 0)
                            ValLabel.Text = tostring(Val) .. (Info.Suffix or '')
                            if Info.Callback then Info.Callback(Val) end
                            RenderStepped:Wait()
                        end
                    end
                end)

                Options[Idx] = Slider
                return Slider
            end

            function Groupbox:AddDropdown(Idx, Info)
                local Dropdown = { Value = Info.Values[Info.Default or 1] }
                local Frame = Library:Create('TextButton', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = '',
                    ZIndex = 6,
                    Parent = Content
                })

                Library:CreateLabel({
                    Position = UDim2.fromOffset(4, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Text = Info.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = Frame
                })

                local ValLabel = Library:CreateLabel({
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, -4, 1, 0),
                    Text = tostring(Dropdown.Value) .. ' ▼',
                    TextColor3 = Color3.fromRGB(160, 160, 160),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 7,
                    Parent = Frame
                })

                local CurrentIdx = Info.Default or 1
                Frame.MouseButton1Click:Connect(function()
                    CurrentIdx = CurrentIdx % #Info.Values + 1
                    Dropdown.Value = Info.Values[CurrentIdx]
                    ValLabel.Text = tostring(Dropdown.Value) .. ' ▼'
                    if Info.Callback then Info.Callback(Dropdown.Value) end
                end)

                Options[Idx] = Dropdown
                return Dropdown
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Title) return CreateGroupbox(Title, LeftCol) end
        function Tab:AddMiddleGroupbox(Title) return CreateGroupbox(Title, MiddleCol) end
        function Tab:AddRightGroupbox(Title) return CreateGroupbox(Title, RightCol) end

        local function Select()
            if Window.ActiveTab then
                Window.ActiveTab.Frame.Visible = false
                Window.ActiveTab.Underline.Visible = false
                Window.ActiveTab.Button.TextColor3 = Color3.fromRGB(160, 160, 160)
            end
            TabFrame.Visible = true
            TabUnderline.Visible = true
            TabButton.TextColor3 = Library.FontColor
            Window.ActiveTab = { Frame = TabFrame, Underline = TabUnderline, Button = TabButton }
        end

        TabButton.MouseButton1Click:Connect(Select)
        if not Window.ActiveTab then Select() end

        return Tab
    end

    return Window
end

return Library
