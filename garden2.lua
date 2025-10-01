--// Garden Tower Defense Script - Sequential Upgrades
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

--=== GAME SCRIPTS - SEQUENTIAL UPGRADES ===--

function load3xScript()
    warn("[System] Loaded 3x Speed Script - Sequential Upgrades")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_apocalypse"
    
    local placements = {
        {
            time = 7, unit = "unit_rafflesia", slot = "2",
            data = {Valid=true,PathIndex=1,Position=Vector3.new(49.52396774291992,-21.75,-52.60224914550781),
                DistanceAlongPath=8.780204010731204,
                CF=CFrame.new(49.52396774291992,-21.75,-52.60224914550781,0.7071068286895752,0,-0.7071067690849304,-0,1,-0,0.7071068286895752,0,0.7071067690849304),
                Rotation=180}
        },
        {
            time = 15, unit = "unit_rafflesia", slot = "2",
            data = {Valid=true,PathIndex=2,Position=Vector3.new(-31.92138671875,-21.75,-9.259031295776367),
                DistanceAlongPath=59.0626757144928,
                CF=CFrame.new(-31.92138671875,-21.75,-9.259031295776367,1,0,-0,-0,1,-0,-0,0,1),
                Rotation=180}
        }
    }

    local function placeUnit(unitName, slot, data)
        local success = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placing] "..unitName.." at "..os.clock())
        else
            warn("[Placing] "..unitName.." at "..os.clock().." - Failed")
        end
    end

    local function tryUpgradeUnit(unitId)
        local success, result = pcall(function()
            return remotes.UpgradeUnit:InvokeServer(unitId)
        end)
        if success then
            warn("[Upgrade Attempt] Unit ID: "..unitId.." - Result: "..tostring(result))
            return result == true
        end
        return false
    end

    local function trySellUnit(unitId)
        local success, result = pcall(function()
            return remotes.SellUnit:InvokeServer(unitId)
        end)
        if success then
            warn("[Sell Attempt] Unit ID: "..unitId.." - Result: "..tostring(result))
            return result == true
        end
        return false
    end

    local function upgradeFirstRafflesiaOnly()
        warn("[Upgrade] Searching for FIRST rafflesia only...")
        
        -- First rafflesia is usually in lower IDs
        for id = 1, 100 do
            if tryUpgradeUnit(id) then
                warn("[Upgrade SUCCESS] First rafflesia ID: "..id)
                return id -- Return the ID so we know which one NOT to upgrade later
            end
        end
        
        warn("[Upgrade] Could not find first rafflesia")
        return nil
    end

    local function upgradeSecondRafflesiaOnly(firstRaffId)
        warn("[Upgrade] Searching for SECOND rafflesia only...")
        
        -- Second rafflesia is usually in higher IDs, skip the first one's ID
        for id = 100, 500 do
            if id ~= firstRaffId and tryUpgradeUnit(id) then
                warn("[Upgrade SUCCESS] Second rafflesia ID: "..id)
                return id -- Return the ID for selling later
            end
        end
        
        warn("[Upgrade] Could not find second rafflesia")
        return nil
    end

    local function sellSpecificRafflesia(unitId)
        if unitId then
            warn("[Sell] Selling specific rafflesia ID: "..unitId)
            if trySellUnit(unitId) then
                warn("[Sell SUCCESS] Sold rafflesia ID: "..unitId)
                return true
            end
        end
        warn("[Sell] Could not sell specified rafflesia")
        return false
    end

    local function startGame()
        warn("[Game Start] Choosing Apocalypse difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end
        
        local firstRafflesiaId = nil
        local secondRafflesiaId = nil
        
        -- Upgrade FIRST rafflesia only at 43 seconds
        task.delay(43, function()
            firstRafflesiaId = upgradeFirstRafflesiaOnly()
        end)
        
        -- Upgrade SECOND rafflesia only at 68 seconds
        task.delay(68, function()
            if firstRafflesiaId then
                secondRafflesiaId = upgradeSecondRafflesiaOnly(firstRafflesiaId)
            else
                warn("[Upgrade] Can't upgrade second without knowing first ID")
            end
        end)
        
        -- Sell SECOND rafflesia at 85 seconds
        task.delay(85, function()
            if secondRafflesiaId then
                sellSpecificRafflesia(secondRafflesiaId)
            else
                warn("[Sell] Don't know which rafflesia to sell")
            end
        end)
        
        -- Auto-restart at 103 seconds
        task.delay(103, function()
            warn("[Restart] Game ended, restarting in 3 seconds...")
            task.wait(3)
            remotes.RestartGame:InvokeServer()
            warn("[Restart] Game restarted, starting new cycle...")
            task.wait(2)
            startGame()
        end)
    end

    -- Start the first game
    startGame()
end

--=== SIMPLIFIED SPEED MENU ===--
local function showSpeedMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "SELECT SPEED MODE"
    SubTitle.Text = "Complete Automation"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 80)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "⚠️ Complete Automation\n• Place Rafflesias: 7s & 15s\n• Upgrade 1st: 43s\n• Upgrade 2nd: 68s\n• Sell 2nd: 85s\n• Auto-restart: 103s"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Only 3x Speed Button
    local btn3x = Instance.new("TextButton")
    btn3x.Size = UDim2.new(1, -40, 0, 120)
    btn3x.Position = UDim2.new(0, 20, 0, 160)
    btn3x.Text = "3× SPEED\nComplete Automation\nFull Cycle: 103s"
    btn3x.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btn3x.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn3x.Font = Enum.Font.GothamBold
    btn3x.TextSize = 18
    btn3x.BorderSizePixel = 0
    btn3x.Parent = Frame

    local btn3xCorner = Instance.new("UICorner")
    btn3xCorner.CornerRadius = UDim.new(0, 10)
    btn3xCorner.Parent = btn3x

    btn3x.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        load3xScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading speed selection..."
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        CheckBtn.Text = "SUCCESS!"
        
        task.delay(1.5, showSpeedMenu)
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
