--// Garden Tower Defense Script - FIXED ERROR HANDLING
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

-- FIXED Unit tracking system
local unitTracker = {
    tomatoes = {},      -- Array to store tomato IDs
    metalFlowers = {},  -- Array to store metal flower IDs  
    potatoes = {},      -- Array to store potato IDs
    allUnits = {}       -- Lookup table for all units
}

-- Auto Skip (enable once at start)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== FIXED ERROR HANDLING SYSTEM ===--

function loadFixedTracking()
    warn("[System] Loaded FIXED ERROR HANDLING SYSTEM")
    
    -- Clear previous units PROPERLY
    unitTracker.tomatoes = {}
    unitTracker.metalFlowers = {}
    unitTracker.potatoes = {}
    unitTracker.allUnits = {}
    
    remotes.ChangeTickSpeed:InvokeServer(3)

    -- Track when units are placed - FIXED VERSION
    local function trackUnitPlacement(unitName, unitId)
        if not unitId then 
            warn("[TRACKER] No unit ID returned for: " .. unitName)
            return 
        end
        
        -- Make sure unitId is a number/string, not boolean
        local idString = tostring(unitId)
        
        unitTracker.allUnits[idString] = {
            name = unitName,
            id = idString,
            placedTime = os.clock()
        }
        
        if string.find(unitName:lower(), "tomato") then
            table.insert(unitTracker.tomatoes, idString)
            warn("[TRACKER] Tomato placed - ID: " .. idString .. " | Total: " .. #unitTracker.tomatoes)
        elseif string.find(unitName:lower(), "metal") then
            table.insert(unitTracker.metalFlowers, idString)
            warn("[TRACKER] Metal Flower placed - ID: " .. idString .. " | Total: " .. #unitTracker.metalFlowers)
        elseif string.find(unitName:lower(), "potato") then
            table.insert(unitTracker.potatoes, idString)
            warn("[TRACKER] Potato placed - ID: " .. idString .. " | Total: " .. #unitTracker.potatoes)
        else
            warn("[TRACKER] Unknown unit type: " .. unitName)
        end
    end

    -- Smart upgrade function that only upgrades existing units
    local function upgradeUnit(unitId)
        if unitTracker.allUnits[tostring(unitId)] then
            local success, result = pcall(function()
                return remotes.UpgradeUnit:InvokeServer(unitId)
            end)
            if success then
                return true
            else
                warn("[UPGRADE FAILED] ID: " .. tostring(unitId) .. " - " .. tostring(result))
                return false
            end
        end
        return false
    end

    -- FIXED: Smart place function with proper error handling
    local function placeUnit(unitName, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            if result then
                -- FIXED: Convert to string to avoid boolean concatenation
                local unitIdString = tostring(result)
                warn("[Placed] " .. unitName .. " - Returned ID: " .. unitIdString)
                trackUnitPlacement(unitName, unitIdString)
                return true, unitIdString
            else
                warn("[Place Failed] " .. unitName .. " - No ID returned")
                return false, "No ID returned"
            end
        else
            -- FIXED: Proper error message without concatenating boolean
            local errorMsg = tostring(result) or "Unknown error"
            warn("[Place Error] " .. unitName .. " - " .. errorMsg)
            return false, errorMsg
        end
    end

    -- FIXED UPGRADE SYSTEM: Upgrades ALL units of each type

    -- Upgrade ALL tomatoes with actual tracking
    local function upgradeTomatoesFixed()
        local tomatoCount = #unitTracker.tomatoes
        warn("[FIXED TRACKING] Starting TOMATO upgrades - " .. tomatoCount .. " tomatoes to upgrade")
        
        if tomatoCount == 0 then
            warn("[WARNING] No tomatoes found to upgrade!")
            return
        end
        
        task.spawn(function()
            while true do
                local upgraded = 0
                for _, unitId in ipairs(unitTracker.tomatoes) do
                    if upgradeUnit(unitId) then
                        upgraded += 1
                        -- Double upgrade for faster progression
                        task.wait(0.001)
                        upgradeUnit(unitId)
                    end
                    task.wait(0.001) -- Small delay between upgrades
                end
                if upgraded > 0 then
                    warn("[TOMATO UPGRADES] Upgraded " .. upgraded .. " tomatoes this cycle")
                end
                task.wait(0.05) -- Wait before next upgrade cycle
            end
        end)
    end

    -- Upgrade ALL metal flowers with actual tracking
    local function upgradeMetalFlowersFixed()
        local metalFlowerCount = #unitTracker.metalFlowers
        warn("[FIXED TRACKING] Starting METAL FLOWER upgrades - " .. metalFlowerCount .. " metal flowers to upgrade")
        
        if metalFlowerCount == 0 then
            warn("[WARNING] No metal flowers found to upgrade!")
            return
        end
        
        task.spawn(function()
            while true do
                local upgraded = 0
                for _, unitId in ipairs(unitTracker.metalFlowers) do
                    if upgradeUnit(unitId) then
                        upgraded += 1
                        -- Double upgrade for faster progression
                        task.wait(0.001)
                        upgradeUnit(unitId)
                    end
                    task.wait(0.001)
                end
                if upgraded > 0 then
                    warn("[METAL FLOWER UPGRADES] Upgraded " .. upgraded .. " metal flowers this cycle")
                end
                task.wait(0.05)
            end
        end)
    end

    -- Upgrade ALL potatoes with actual tracking
    local function upgradePotatoesFixed()
        local potatoCount = #unitTracker.potatoes
        warn("[FIXED TRACKING] Starting POTATO upgrades - " .. potatoCount .. " potatoes to upgrade")
        
        if potatoCount == 0 then
            warn("[WARNING] No potatoes found to upgrade!")
            return
        end
        
        task.spawn(function()
            while true do
                local upgraded = 0
                for _, unitId in ipairs(unitTracker.potatoes) do
                    if upgradeUnit(unitId) then
                        upgraded += 1
                        -- Triple upgrade for fastest progression
                        task.wait(0.001)
                        upgradeUnit(unitId)
                        task.wait(0.001)
                        upgradeUnit(unitId)
                    end
                    task.wait(0.001)
                end
                if upgraded > 0 then
                    warn("[POTATO UPGRADES] Upgraded " .. upgraded .. " potatoes this cycle")
                end
                task.wait(0.03) -- Faster cycle for potatoes
            end
        end)
    end

    -- Unit placement data with timing
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

    -- Main game loop with proper reset
    local function mainGameLoop()
        while true do
            warn("[GAME START] New game cycle starting...")
            
            -- Clear units for new game
            unitTracker.tomatoes = {}
            unitTracker.metalFlowers = {}
            unitTracker.potatoes = {}
            unitTracker.allUnits = {}
            
            -- Set game settings
            remotes.ChangeTickSpeed:InvokeServer(3)
            remotes.PlaceDifficultyVote:InvokeServer("dif_hard")
            
            -- Place all units and track their IDs
            for _, placement in ipairs(unitPlacements) do
                task.delay(placement.time, function()
                    local success, unitId = placeUnit(placement.unit, placement.data)
                    if success then
                        warn("[PLACEMENT TRACKED] " .. placement.unit .. " - ID: " .. tostring(unitId))
                    else
                        warn("[PLACEMENT FAILED] " .. placement.unit .. " - " .. tostring(unitId))
                    end
                end)
            end
            
            -- Start FIXED upgrades based on actual unit tracking
            -- Tomatoes start at 15s (after both placements)
            task.delay(15, function()
                local tomatoCount = #unitTracker.tomatoes
                warn("[FIXED TRACKING] Starting TOMATO upgrades - Tracking " .. tomatoCount .. " tomatoes")
                upgradeTomatoesFixed()
            end)
            
            -- Metal flowers start at 120s (after all placements)
            task.delay(120, function()
                local metalFlowerCount = #unitTracker.metalFlowers
                warn("[FIXED TRACKING] Starting METAL FLOWER upgrades - Tracking " .. metalFlowerCount .. " metal flowers")
                upgradeMetalFlowersFixed()
            end)
            
            -- Potatoes start at 210s (after all placements)
            task.delay(210, function()
                local potatoCount = #unitTracker.potatoes
                warn("[FIXED TRACKING] Starting POTATO upgrades - Tracking " .. potatoCount .. " potatoes")
                upgradePotatoesFixed()
            end)
            
            -- Wait for game duration
            task.wait(300) -- 5 minutes
            
            warn("[RESTART] Restarting game and clearing unit tracker...")
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
    
    Title.Text = "FIXED ERROR HANDLING SYSTEM"
    SubTitle.Text = "No More Boolean Concatenation Errors"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 FIXED ERROR HANDLING SYSTEM\n• Proper string conversion with tostring()\n• Better error handling for failed placements\n• No more boolean concatenation errors\n• Upgrades ALL units of each type\n• Detailed logging for debugging"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Fixed Tracking Button
    local btnFixed = Instance.new("TextButton")
    btnFixed.Size = UDim2.new(1, -40, 0, 120)
    btnFixed.Position = UDim2.new(0, 20, 0, 200)
    btnFixed.Text = "FIXED ERROR HANDLING SYSTEM\nNo More Boolean Concatenation\nProper String Conversion"
    btnFixed.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    btnFixed.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnFixed.Font = Enum.Font.GothamBold
    btnFixed.TextSize = 18
    btnFixed.BorderSizePixel = 0
    btnFixed.Parent = Frame

    local btnFixedCorner = Instance.new("UICorner")
    btnFixedCorner.CornerRadius = UDim.new(0, 10)
    btnFixedCorner.Parent = btnFixed

    btnFixed.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadFixedTracking()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading FIXED ERROR SYSTEM..."
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
