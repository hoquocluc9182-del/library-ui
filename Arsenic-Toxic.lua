local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library
Library.Theme = {
    Background = Color3.fromRGB(20, 20, 25), Sidebar = Color3.fromRGB(25, 25, 32),
    Panel = Color3.fromRGB(30, 30, 40), Element = Color3.fromRGB(38, 38, 50),
    ElementHover = Color3.fromRGB(48, 48, 65), Accent = Color3.fromRGB(200, 200, 210),
    Text = Color3.fromRGB(240, 240, 250), SubText = Color3.fromRGB(160, 160, 180),
    Stroke = Color3.fromRGB(55, 55, 75), ToggleOff = Color3.fromRGB(55, 55, 75),
    Danger = Color3.fromRGB(230, 80, 90), Success = Color3.fromRGB(90, 210, 130),
}
local T = Library.Theme
Library.AccentObjects = {}
Library.TextAccentObjects = {}
Library.Connections = {}
local SPIN_IMG = "rbxassetid://76889967877413"

local function New(class, props)
    local o = Instance.new(class)
    for k, v in next, props do o[k] = v end
    return o
end
local function Corner(p, r) return New("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = p}) end
local function Stroke(p, c, t) return New("UIStroke", {Color = c or T.Stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p}) end
local function AddGradient(p, colorSeq) return New("UIGradient", {Color = colorSeq or ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(0.7,0.7,0.7))}), Rotation = 45, Parent = p}) end

local function RegisterAccent(obj, isText)
    if isText then table.insert(Library.TextAccentObjects, obj) else table.insert(Library.AccentObjects, obj) end
end
local function UnregisterAccent(obj, isText)
    local list = isText and Library.TextAccentObjects or Library.AccentObjects
    for i, v in ipairs(list) do if v == obj then table.remove(list, i) break end end
end

function Library:SetAccentColor(newColor)
    T.Accent = newColor
    for _, obj in ipairs(Library.AccentObjects) do
        if obj and obj.Parent then obj.BackgroundColor3 = newColor end
    end
    for _, obj in ipairs(Library.TextAccentObjects) do
        if obj and obj.Parent then obj.TextColor3 = newColor end
    end
end

local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function CleanupOldGUI()
    local targetParent = getGuiParent()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local coreGui = game:GetService("CoreGui")
    for _, parent in ipairs({targetParent, playerGui, coreGui}) do
        if parent then
            for _, obj in ipairs(parent:GetChildren()) do
                if obj.Name == "ArsenicUI" or obj.Name == "ArsenicFloatingIcon" or obj.Name == "ArsenicWatermark" or obj.Name == "ArsenicKeySystem" then obj:Destroy() end
            end
        end
    end
end

local function SetupDrag(dragArea, target)
    local dragging, dragStart, startPos, isDragged
    local conn1 = dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; isDragged = false; dragStart = input.Position; startPos = target.Position
            local connEnd; connEnd = input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then dragging = false; connEnd:Disconnect() end 
            end)
        end
    end)
    local conn2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then isDragged = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(Library.Connections, conn1)
    table.insert(Library.Connections, conn2)
    return function() return isDragged end
end

function Library:Window(opts)
    opts = opts or {}
    CleanupOldGUI()
    local title = opts.Title or "Arsenic Toxic"
    local size = opts.Size or UDim2.fromOffset(580, 400)
    local configFolder = "ArsenicConfigs"

    local gui = New("ScreenGui", {Name = "ArsenicUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, Enabled = true, Parent = getGuiParent()})
    Library.Gui = gui
    Library.Connections = {}
    Library.AccentObjects = {}
    Library.TextAccentObjects = {}

    local floatGui = New("ScreenGui", {Name = "ArsenicFloatingIcon", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = true, Parent = getGuiParent()})
    local imgBtn = New("ImageButton", {Size = UDim2.new(0, 65, 0, 65), Position = UDim2.new(0, 20, 0.5, -32), BackgroundColor3 = T.Panel, BorderSizePixel = 0, AutoButtonColor = false, Parent = floatGui})
    Corner(imgBtn, 12); Stroke(imgBtn, T.Accent, 2.5)
    imgBtn.Image = SPIN_IMG

    local wasIconDragged = SetupDrag(imgBtn, imgBtn)
    imgBtn.MouseButton1Click:Connect(function() if not wasIconDragged() then gui.Enabled = not gui.Enabled end end)

    local Main = New("Frame", {Name = "Main", Size = size, Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2), BackgroundColor3 = T.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui})
    Corner(Main, 10); Stroke(Main, T.Stroke, 1.5)

    local topIcon = New("ImageLabel", {Size = UDim2.new(0, 75, 0, 75), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = SPIN_IMG, ZIndex = 50, Parent = gui})
    
    local function updateTopIconPos()
        topIcon.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset + 5, Main.Position.Y.Scale, Main.Position.Y.Offset + 5)
    end
    updateTopIconPos()
    Main:GetPropertyChangedSignal("Position"):Connect(updateTopIconPos)

    local TopBar = New("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.Sidebar, BorderSizePixel = 0, Parent = Main})
    AddGradient(TopBar, ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(0.85,0.85,0.85))}))
    
    New("TextLabel", {Size = UDim2.new(1, -140, 0, 40), Position = UDim2.new(0, 50, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = title, Parent = TopBar})

    local minBtn = New("TextButton", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -66, 0.5, -13), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = T.Text, Text = "-", AutoButtonColor = false, Parent = TopBar})
    Corner(minBtn, 6)
    local closeBtn = New("TextButton", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0.5, -13), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.Text, Text = "X", AutoButtonColor = false, Parent = TopBar})
    Corner(closeBtn, 6)

    SetupDrag(TopBar, Main)

    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(Main, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        task.wait(0.2); gui:Destroy(); floatGui:Destroy()
    end)
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = T.Danger end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = T.Element end)

    local Sidebar = New("Frame", {Size = UDim2.new(0, 140, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundColor3 = T.Sidebar, BorderSizePixel = 0, Parent = Main})
    
    local SearchBox = New("TextBox", {Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = T.Background, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text, PlaceholderText = "Search...", PlaceholderColor3 = T.SubText, Text = "", ClearTextOnFocus = false, Parent = Sidebar})
    Corner(SearchBox, 6); Stroke(SearchBox, T.Stroke, 1)

    local TabList = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(0,0,0,0), Parent = Sidebar})
    New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList})
    New("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TabList})

    local Content = New("Frame", {Size = UDim2.new(1, -140, 1, -40), Position = UDim2.new(0, 140, 0, 40), BackgroundTransparency = 1, Parent = Main})
    local Window = {Gui = gui, FloatGui = floatGui, Main = Main, Tabs = {}, CurrentTab = nil, Minimized = false, Elements = {}}

    minBtn.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Window._oldSize = Main.Size
            TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 40)}):Play()
            Sidebar.Visible = false; Content.Visible = false
        else
            TweenService:Create(Main, TweenInfo.new(0.2), {Size = Window._oldSize or size}):Play()
            Sidebar.Visible = true; Content.Visible = true
        end
    end)

    local rightShiftConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift and gui.Enabled then gui.Enabled = not gui.Enabled end
    end)
    table.insert(Library.Connections, rightShiftConn)
    
    local spinConn = RunService.RenderStepped:Connect(function()
        if topIcon and topIcon.Parent then topIcon.Rotation = (os.clock() * 60) % 360 end
    end)
    table.insert(Library.Connections, spinConn)
    
    gui.Destroying:Connect(function()
        for _, conn in ipairs(Library.Connections) do pcall(function() conn:Disconnect() end) end
        table.clear(Library.Connections)
    end)

    function Window:Filter(text)
        text = string.lower(text)
        if not Window.CurrentTab then return end
        for _, sec in ipairs(Window.CurrentTab.Sections) do
            local hasMatch = false
            for _, el in ipairs(sec.Elements) do
                local elText = el.Text or ""
                if text == "" or string.find(string.lower(elText), text, 1, true) then
                    if el.Frame then el.Frame.Visible = true end
                    hasMatch = true
                else
                    if el.Frame then el.Frame.Visible = false end
                end
            end
            sec.Frame.Visible = (text == "") or hasMatch
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Window:Filter(SearchBox.Text)
    end)

    function Window:Tab(name)
        local Tab = {Name = name, Sections = {}}
        Tab.Frame = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = Content})
        New("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Tab.Frame})
        New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), Parent = Tab.Frame})

        local btn = New("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. name, AutoButtonColor = false, Parent = TabList})
        Corner(btn, 6)

        local function select()
            SearchBox.Text = ""
            for _, t in pairs(Window.Tabs) do
                t.Frame.Visible = false
                TweenService:Create(t.Btn, TweenInfo.new(0.15), {BackgroundColor3 = T.Element, TextColor3 = T.SubText}):Play()
            end
            Tab.Frame.Visible = true
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = T.Accent, TextColor3 = T.Background}):Play()
            Window.CurrentTab = Tab
        end
        
        btn.MouseButton1Click:Connect(select)
        Tab.Btn = btn

        function Tab:Section(secName)
            local Section = {Name = secName, Elements = {}}
            local Frame = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = Tab.Frame})
            Corner(Frame, 8); Stroke(Frame, T.Stroke, 1)
            
            local HeaderBtn = New("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 8), BackgroundTransparency = 1, Text = "", Parent = Frame})
            New("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = secName, Parent = HeaderBtn})
            local ArrowLbl = New("TextLabel", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.SubText, Text = "▼", Parent = HeaderBtn})

            local C = New("Frame", {Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 34), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Parent = Frame})
            New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = C})
            New("UIPadding", {PaddingBottom = UDim.new(0, 10), Parent = C})
            
            local isCollapsed = false
            HeaderBtn.MouseButton1Click:Connect(function()
                isCollapsed = not isCollapsed
                C.Visible = not isCollapsed
                ArrowLbl.Text = isCollapsed and "▶" or "▼"
                Frame.AutomaticSize = isCollapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y
                if isCollapsed then Frame.Size = UDim2.new(1, 0, 0, 30) else Frame.Size = UDim2.new(1, 0, 0, 0) end
            end)

            Section.Frame = Frame
            Section.Content = C
            table.insert(Tab.Sections, Section)

            function Section:Button(o)
                o = o or {}
                local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, Text = o.Text or "Button", AutoButtonColor = false, Parent = C})
                Corner(b, 6)
                b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.ElementHover}):Play() end)
                b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.Element}):Play() end)
                b.MouseButton1Click:Connect(function() if o.Callback then pcall(o.Callback) end end)
                local api = {Instance = b, Type = "Button", Text = o.Text, Frame = b}
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Toggle(o)
                o = o or {}
                local state = o.Default or false
                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = C})
                Corner(h, 6)
                New("TextLabel", {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "Toggle", Parent = h})
                local sw = New("Frame", {Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = state and T.Accent or T.ToggleOff, BorderSizePixel = 0, Parent = h})
                Corner(sw, 9)
                local knob = New("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sw})
                Corner(knob, 7)
                local clk = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = h})
                local api = {Value = state, Type = "Toggle", Text = o.Text, Frame = h}
                
                local function set(v, fire)
                    state = v; api.Value = v
                    if v then RegisterAccent(sw) else UnregisterAccent(sw) end
                    TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = v and T.Accent or T.ToggleOff}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.15), {Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                    if fire and o.Callback then pcall(o.Callback, v) end
                end
                if state then RegisterAccent(sw) end
                clk.MouseButton1Click:Connect(function() set(not state, true) end)
                api.Set = function(v, fire) set(v, fire) end
                api.Get = function() return state end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Slider(o)
                o = o or {}
                local min, max, decimals = o.Min or 0, o.Max or 100, o.Decimals or 0
                local mult = 10 ^ decimals
                local val = math.clamp(o.Default or min, min, max)
                local suffix = o.Suffix or ""
                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = C})
                Corner(h, 6)
                New("TextLabel", {Size = UDim2.new(0.7, 0, 0, 22), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "Slider", Parent = h})
                local valLbl = New("TextLabel", {Size = UDim2.new(0.3, -10, 0, 22), Position = UDim2.new(0.7, 0, 0, 4), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(val) .. suffix, Parent = h})
                local dragArea = New("TextButton", {Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 1, -24), BackgroundTransparency = 1, Text = "", Parent = h})
                local bar = New("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = T.ToggleOff, BorderSizePixel = 0, Parent = dragArea})
                Corner(bar, 3)
                local fill = New("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = bar})
                Corner(fill, 3); RegisterAccent(fill)
                local knob = New("Frame", {Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = bar})
                Corner(knob, 7)
                local api = {Value = val, Type = "Slider", Text = o.Text, Frame = h}
                
                local function set(v, fire)
                    v = math.clamp(v, min, max); v = math.floor(v * mult + 0.5) / mult
                    val = v; api.Value = v
                    local rel = (v - min) / (max - min)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    valLbl.Text = tostring(v) .. suffix
                    if fire and o.Callback then pcall(o.Callback, v) end
                end
                set(val, false)
                local isDragging = false
                local function update(x)
                    local rel = (x - dragArea.AbsolutePosition.X) / math.max(dragArea.AbsoluteSize.X, 1)
                    set(min + (max - min) * math.clamp(rel, 0, 1), true)
                end
                dragArea.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true; update(input.Position.X) end end)
                local c1 = UserInputService.InputChanged:Connect(function(i) if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i.Position.X) end end)
                local c2 = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then isDragging = false end end)
                table.insert(Library.Connections, c1); table.insert(Library.Connections, c2)
                
                api.Set = function(v, fire) set(v, fire) end
                api.Get = function() return val end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:TextBox(o)
                o = o or {}
                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = C})
                Corner(h, 6)
                New("TextLabel", {Size = UDim2.new(1, -160, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "TextBox", Parent = h})
                local tb = New("TextBox", {Size = UDim2.new(0, 140, 0, 24), Position = UDim2.new(1, -150, 0.5, -12), BackgroundColor3 = T.Background, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text, PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = T.SubText, Text = o.Default or "", ClearTextOnFocus = false, Parent = h})
                Corner(tb, 5); Stroke(tb, T.Stroke, 1)
                local api = {Value = o.Default or "", Type = "TextBox", Text = o.Text, Frame = h}
                tb.FocusLost:Connect(function(enter) api.Value = tb.Text; if o.Callback then pcall(o.Callback, tb.Text, enter) end end)
                api.Set = function(v) tb.Text = tostring(v); api.Value = v end
                api.Get = function() return tb.Text end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Keybind(o)
                o = o or {}
                local key = o.Default or Enum.KeyCode.RightShift
                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = C})
                Corner(h, 6)
                New("TextLabel", {Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "Keybind", Parent = h})
                local btn = New("TextButton", {Size = UDim2.new(0, 80, 0, 22), Position = UDim2.new(1, -90, 0.5, -11), BackgroundColor3 = T.Background, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Accent, Text = key.Name, AutoButtonColor = false, Parent = h})
                Corner(btn, 5); Stroke(btn, T.Stroke, 1); RegisterAccent(btn, true)
                
                local api = {Value = key, Type = "Keybind", Text = o.Text, Listening = false, Frame = h}
                btn.MouseButton1Click:Connect(function()
                    if api.Listening then return end
                    api.Listening = true; btn.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode; btn.Text = key.Name; api.Listening = false; api.Value = key
                            if conn then conn:Disconnect() end
                            if o.Callback then pcall(o.Callback, key) end
                        end
                    end)
                end)
                api.Set = function(k) key = k; btn.Text = k.Name; api.Value = k end
                api.Get = function() return key end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Dropdown(o)
                o = o or {}
                local options = o.Options or {}
                local multi = o.Multi or false
                local current = o.Default or (options[1] or "None")
                local selectedItems = {}
                if multi and type(current) == "table" then for _, v in ipairs(current) do selectedItems[v] = true end elseif multi then selectedItems[current] = true end

                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, Parent = C, ClipsDescendants = true})
                Corner(h, 6)
                New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = h})

                local btn = New("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = h})
                New("TextLabel", {Size = UDim2.new(1, -70, 0, 32), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "Dropdown", Parent = btn})
                local cur = New("TextLabel", {Size = UDim2.new(0, 100, 0, 32), Position = UDim2.new(1, -110, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, Text = (multi and "Multiple" or tostring(current)) .. "  v", Parent = btn})

                local list = New("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = T.Background, BorderSizePixel = 0, Visible = false, Parent = h})
                Corner(list, 6)
                New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})

                local api = {Value = multi and selectedItems or current, Type = "Dropdown", Text = o.Text, Frame = h}
                local optionButtons = {}; local open = false

                local function refresh()
                    for _, b in ipairs(optionButtons) do b:Destroy() end
                    optionButtons = {}
                    local height = 0
                    for _, opt in ipairs(options) do
                        local isSelected = multi and selectedItems[opt] or (current == opt)
                        local ob = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = isSelected and T.Element or T.Background, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = isSelected and T.Accent or T.Text, Text = "   " .. tostring(opt), TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Parent = list})
                        ob.MouseEnter:Connect(function() TweenService:Create(ob, TweenInfo.new(0.1), {BackgroundColor3 = T.ElementHover}):Play() end)
                        ob.MouseLeave:Connect(function() TweenService:Create(ob, TweenInfo.new(0.1), {BackgroundColor3 = isSelected and T.Element or T.Background}):Play() end)
                        ob.MouseButton1Click:Connect(function()
                            if multi then
                                selectedItems[opt] = not selectedItems[opt]
                                if not selectedItems[opt] then selectedItems[opt] = nil end
                                api.Value = selectedItems
                                if o.Callback then pcall(o.Callback, selectedItems) end
                            else
                                current = opt; api.Value = opt; cur.Text = tostring(opt) .. "  v"
                                open = false; list.Visible = false; list.Size = UDim2.new(1, 0, 0, 0)
                                if o.Callback then pcall(o.Callback, opt) end
                            end
                            refresh()
                        end)
                        table.insert(optionButtons, ob); height += 28
                    end
                    list.Size = UDim2.new(1, 0, 0, open and height or 0); api._height = height
                end
                refresh()

                btn.MouseButton1Click:Connect(function()
                    open = not open; list.Visible = open
                    if open then list.Size = UDim2.new(1, 0, 0, api._height or (#options * 28)) else list.Size = UDim2.new(1, 0, 0, 0) end
                end)

                api.Set = function(v)
                    if multi and type(v) == "table" then
                        selectedItems = {}
                        for k, val in pairs(v) do selectedItems[k] = val end
                        api.Value = selectedItems; refresh()
                    elseif not multi then
                        current = v; api.Value = v; cur.Text = tostring(v) .. "  v"
                    end
                end
                api.Get = function() return api.Value end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:ColorPicker(o)
                o = o or {}
                local color = o.Default or Color3.fromRGB(255, 255, 255)
                local h = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0, Parent = C})
                Corner(h, 6)
                New("TextLabel", {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "Color Picker", Parent = h})
                local colorBtn = New("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0.5, -12), BackgroundColor3 = color, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = h})
                Corner(colorBtn, 4); Stroke(colorBtn, T.Stroke, 1)
                
                local api = {Value = color, Type = "ColorPicker", Text = o.Text, Frame = h}
                colorBtn.MouseButton1Click:Connect(function()
                    local picker = New("Frame", {Size = UDim2.new(0, 200, 0, 180), Position = UDim2.new(1, -210, 0.5, -90), BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 50, Parent = gui})
                    Corner(picker, 8); Stroke(picker, T.Stroke, 1)
                    local svFrame = New("Frame", {Size = UDim2.new(1, -10, 0, 120), Position = UDim2.new(0, 5, 0, 5), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 51, Parent = picker})
                    Corner(svFrame, 4)
                    local hueBar = New("Frame", {Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 5, 0, 130), BackgroundColor3 = T.Element, BorderSizePixel = 0, ZIndex = 51, Parent = picker})
                    Corner(hueBar, 4)
                    New("UIGradient", {Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
                    }), Parent = hueBar})
                    local closePicker = New("TextButton", {Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 5, 1, -25), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Text, Text = "Close", AutoButtonColor = false, ZIndex = 51, Parent = picker})
                    Corner(closePicker, 4)
                    
                    local hue, sat, val = color:ToHSV()
                    local function updateColor()
                        local newColor = Color3.fromHSV(hue, sat, val)
                        api.Value = newColor; colorBtn.BackgroundColor3 = newColor
                        svFrame.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        if o.Callback then pcall(o.Callback, newColor) end
                    end
                    
                    local hueDrag, svDrag = false, false
                    hueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDrag = true; hue = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1); updateColor() end end)
                    svFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDrag = true; sat = math.clamp((input.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1); val = 1 - math.clamp((input.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1); updateColor() end end)
                    
                    local c1 = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if hueDrag then hue = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1); updateColor()
                            elseif svDrag then sat = math.clamp((input.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1); val = 1 - math.clamp((input.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1); updateColor() end
                        end
                    end)
                    local c2 = UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDrag = false; svDrag = false end end)
                    table.insert(Library.Connections, c1); table.insert(Library.Connections, c2)
                    closePicker.MouseButton1Click:Connect(function() picker:Destroy() end)
                end)
                
                api.Set = function(c) color = c; api.Value = c; colorBtn.BackgroundColor3 = c; if o.Callback then pcall(o.Callback, c) end end
                api.Get = function() return api.Value end
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Paragraph(o)
                o = o or {}
                local p = New("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = o.Text or "Paragraph text...", Parent = C})
                local api = {Instance = p, Type = "Paragraph", Text = o.Text, Frame = p}
                table.insert(Section.Elements, api)
                table.insert(Window.Elements, api)
                return api
            end

            function Section:Divider()
                local d = New("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BorderSizePixel = 0, Parent = C})
                return {Instance = d}
            end
            
            return Section
        end
        if not Window.CurrentTab then select() end
        table.insert(Window.Tabs, Tab)
        return Tab
    end

    local activeNotifs = {}
    local function updateNotifPositions()
        local yOffset = 20
        for _, box in ipairs(activeNotifs) do
            TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 0, yOffset)}):Play()
            yOffset = yOffset + 70
        end
    end

    function Window:Notify(o)
        o = o or {}
        local duration = o.Duration or 3
        local box = New("Frame", {Size = UDim2.new(0, 240, 0, 60), Position = UDim2.new(1, 260, 0, 20), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = gui})
        Corner(box, 8); Stroke(box, T.Stroke, 1)
        
        table.insert(activeNotifs, box)
        updateNotifPositions()

        local notifIcon = New("ImageLabel", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 10, 0.5, -15), BackgroundTransparency = 1, Image = SPIN_IMG, Parent = box})
        
        New("TextLabel", {Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 45, 0, 10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Title or "Arsenic Alert", Parent = box})
        New("TextLabel", {Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 45, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Text or "", TextTruncate = Enum.TextTruncate.AtEnd, Parent = box})
        
        local rotConn = RunService.RenderStepped:Connect(function()
            if notifIcon and notifIcon.Parent then notifIcon.Rotation = (os.clock() * 90) % 360 end
        end)
        
        task.delay(duration, function()
            if rotConn then rotConn:Disconnect() end
            for i, v in ipairs(activeNotifs) do if v == box then table.remove(activeNotifs, i) break end end
            updateNotifPositions()
            TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 260, 0, box.Position.Y.Offset)}):Play()
            task.wait(0.35); box:Destroy()
        end)
    end

    function Window:Watermark(enabled)
        if not enabled then return end
        local wmGui = New("ScreenGui", {Name = "ArsenicWatermark", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = getGuiParent()})
        local wmLabel = New("TextLabel", {Size = UDim2.new(0, 250, 0, 30), Position = UDim2.new(1, -260, 0, 15), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Text, Text = " Arsenic | FPS: 60 | Ping: 20ms ", Parent = wmGui})
        Corner(wmLabel, 6); Stroke(wmLabel, T.Stroke, 1); AddGradient(wmLabel)
        
        local lastUpdate = 0
        local conn = RunService.RenderStepped:Connect(function(dt)
            lastUpdate += dt
            if lastUpdate >= 0.5 then
                lastUpdate = 0
                local fps = math.floor(1 / math.max(dt, 0.001))
                local ping = 0
                pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
                wmLabel.Text = string.format(" %s | FPS: %d | Ping: %dms ", title, fps, ping)
            end
        end)
        table.insert(Library.Connections, conn)
    end

    function Window:SaveConfig(name)
        if not writefile or not makefolder or not isfolder then return false end
        if not isfolder(configFolder) then makefolder(configFolder) end
        local data = {}
        for _, element in ipairs(Window.Elements) do
            if element.Text and element.Value ~= nil then
                if element.Type == "ColorPicker" then data[element.Text] = {Type = element.Type, Value = {element.Value.R, element.Value.G, element.Value.B}}
                elseif element.Type == "Keybind" then data[element.Text] = {Type = element.Type, Value = element.Value.Name}
                else data[element.Text] = {Type = element.Type, Value = element.Value} end
            end
        end
        local success, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if success then pcall(writefile, configFolder .. "/" .. name .. ".json", encoded); return true end
        return false
    end

    function Window:LoadConfig(name)
        if not isfile or not readfile then return false end
        local path = configFolder .. "/" .. name .. ".json"
        if not isfile(path) then return false end
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not success or not data then return false end
        for _, element in ipairs(Window.Elements) do
            if element.Text and data[element.Text] then
                local saved = data[element.Text]
                if element.Type == saved.Type then
                    if element.Type == "ColorPicker" and type(saved.Value) == "table" then element.Set(Color3.fromRGB(saved.Value[1], saved.Value[2], saved.Value[3]))
                    elseif element.Type == "Keybind" then local key = Enum.KeyCode[saved.Value]; if key then element.Set(key) end
                    else element.Set(saved.Value, true) end
                end
            end
        end
        return true
    end

    return Window
end
return Library
