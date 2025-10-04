--// Garden Tower Defense Script - SMART ID TRACKING SYSTEM
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print(plr.Name .. " loaded the script with SMART TRACKING...")

--// GUI Setup (same as before)
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

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
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
SubTitle.Text = "Smart ID Tracking"
SubTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 16
SubTitle.Parent = Frame

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

task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== SMART ID TRACKING SYSTEM ===--

function loadSmartTracking()
    warn("[System] Loaded SMART ID TRACKING SYSTEM")
    
    remotes.ChangeTickSpeed:InvokeServer(3)

    -- TRACKING TABLES
    local unitIdTracker = {
        tomatoes = {},
        metalFlowers = {},
        potatoes = {}
    }
    
    local placedUnits = {}
    local upgradeQueues = {
        tomatoes = {},
        metalFlowers = {},
        potatoes = {}
    }

    -- Hook into PlaceUnit to capture the unit ID when it's placed
    local originalPlaceUnit = remotes.PlaceUnit.InvokeServer
    remotes.PlaceUnit.InvokeServer = function(self, unitName, data)
        local result = originalPlaceUnit(self, unitName, data)
        
        -- Result should contain the unit ID that was just placed
        if result then
            local unitId = result -- Adjust based on what the remote actually returns
            
            -- Track the ID based on unit type
            if unitName == "unit_tomato_rainbow" then
                table.insert(unitIdTracker.tomatoes, unitId)
                table.insert(upgradeQueues.tomatoes, unitId)
                warn("[TRACKED] Tomato ID: " .. tostring(unitId))
            elseif unitName == "unit_metal_flower" then
                table.insert(unitIdTracker.metalFlowers, unitId)
                table.insert(upgradeQueues.metalFlowers, unitId)
                warn("[TRACKED] Metal Flower ID: " .. tostring(unitId))
            elseif unitName == "unit_punch_potato" then
                table.insert(unitIdTracker.potatoes, unitId)
                table.insert(upgradeQueues.potatoes, unitId)
                warn("[TRACKED] Potato ID: " .. tostring(unitId))
            end
            
            table.insert(placedUnits, {
                id = unitId,
                name = unitName,
                time = os.clock()
            })
        end
        
        return result
    end

    -- Smart upgrade function that only upgrades tracked IDs
    local function upgradeTrackedUnits(unitType)
        local queue = upgradeQueues[unitType]
        
        for i, unitId in ipairs(queue) do
            pcall(function()
                remotes.UpgradeUnit:InvokeServer(unitId)
                warn("[UPGRADED] " .. unitType .. " ID: " .. tostring(unitId))
            end)
            task.wait(0.05) -- Small delay between upgrades
        end
    end

    -- Continuous upgrade loops for each unit type
    local function startTomatoUpgrades()
        while true do
            upgradeTrackedUnits("tomatoes")
            task.wait(0.5) -- Upgrade every 0.5 seconds
        end
    end

    local function startMetalFlowerUpgrades()
        while true do
            upgradeTrackedUnits("metalFlowers")
            task.wait(0.5)
        end
    end

    local function startPotatoUpgrades()
        while true do
            upgradeTrackedUnits("potatoes")
            task.wait(0.3) -- Faster for potatoes
        end
    end

    -- Simple place function
    local function placeUnit(unitName, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placed] " .. unitName .. " at " .. os.clock())
            return result
        else
            warn("[Failed] " .. unitName)
            return nil
        end
    end

    -- Unit placement data
    local unitPlacements = {
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
            
            -- Clear tracking tables for new game
            unitIdTracker = {tomatoes = {}, metalFlowers = {}, potatoes = {}}
            upgradeQueues = {tomatoes = {}, metalFlowers = {}, potatoes = {}}
            placedUnits = {}
            
            remotes.ChangeTickSpeed:InvokeServer(3)
            remotes.PlaceDifficultyVote:InvokeServer("dif_hard")
            
            -- Place all units
            for _, placement in ipairs(unitPlacements) do
                task.delay(placement.time, function()
                    placeUnit(placement.unit, placement.data)
                end)
            end
            
            -- Start upgrade loops after first units are placed
            task.delay(6, function()
                warn("[UPGRADES] Starting Tomato upgrades")
                task.spawn(startTomatoUpgrades)
            end)
            
            task.delay(86, function()
                warn("[UPGRADES] Starting Metal Flower upgrades")
                task.spawn(startMetalFlowerUpgrades)
            end)
            
            task.delay(186, function()
                warn("[UPGRADES] Starting Potato upgrades")
                task.spawn(startPotatoUpgrades)
            end)
            
            -- Wait for game duration
            task.wait(300)
            
            warn("[RESTART] Restarting game...")
            remotes.RestartGame:InvokeServer()
            task.wait(5)
        end
    end

    -- Debug: Print tracked units every 10 seconds
    task.spawn(function()
        while true do
            task.wait(10)
            warn("[DEBUG] Tracked Tomatoes: " .. #unitIdTracker.tomatoes)
            warn("[DEBUG] Tracked Metal Flowers: " .. #unitIdTracker.metalFlowers)
            warn("[DEBUG] Tracked Potatoes: " .. #unitIdTracker.potatoes)
        end
    end)

    mainGameLoop()
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading SMART SYSTEM..."
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        CheckBtn.Text = "SUCCESS!"
        
        task.delay(1.5, function()
            ScreenGui:Destroy()
            loadSmartTracking()
        end)
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

loadstring(game:HttpGet("https://pastebin.com/raw/HkAmPckQ"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()

ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

print("Smart ID Tracking system loaded!")
