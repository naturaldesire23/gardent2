--// Garden Tower Defense Script - Back to Working Version
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

--=== GAME SCRIPTS - WORKING VERSION ===--

function load3xScript()
    warn("[System] Loaded 3x Speed Script - Working Version")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_apocalypse"
    
    -- Placement data
    local firstRaffData = {
        Valid = true,
        PathIndex = 1,
        Position = Vector3.new(51.70485305786133,-21.75,-54.78313446044922),
        DistanceAlongPath = 5.6959664442733,
        CF = CFrame.new(51.70485305786133,-21.75,-54.78313446044922,0.7071068286895752,0,-0.7071067690849304,-0,1,-0,0.7071068286895752,0,0.7071067690849304),
        Rotation = 180
    }
    
    local secondRaffData = {
        Valid = true,
        PathIndex = 2,
        Position = Vector3.new(-33.59211730957031,-21.749000549316406,-21.671918869018555),
        DistanceAlongPath = 46.379028904084905,
        CF = CFrame.new(-33.59211730957031,-21.749000549316406,-21.671918869018555,0.9244806170463562,0,0.38122913241386414,-0,1,-0,-0.38122913241386414,0,0.9244806170463562),
        Rotation = 180
    }

    local function placeUnit(unitName, data)
        local success = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placing] "..unitName.." at "..os.clock())
        else
            warn("[Placing] "..unitName.." at "..os.clock().." - Failed")
        end
    end

    local function upgradeUnit(unitId)
        local success, result = pcall(function()
            return remotes.UpgradeUnit:InvokeServer(unitId)
        end)
        if success and result == true then
            warn("[Upgrading] Unit ID: "..unitId.." - SUCCESS")
            return true
        else
            return false
        end
    end

    local function sellUnit(unitId)
        local success, result = pcall(function()
            return remotes.SellUnit:InvokeServer(unitId)
        end)
        if success and result == true then
            warn("[Selling] Unit ID: "..unitId.." - SUCCESS")
            return true
        else
            return false
        end
    end

    local function findAndUpgradeRafflesia(isFirst)
        warn("[Search] Looking for "..(isFirst and "first" or "second").." rafflesia...")
        
        local startId = isFirst and 1 or 50
        local endId = isFirst and 49 or 100
        
        for id = startId, endId do
            if upgradeUnit(id) then
                warn("[Found] "..(isFirst and "First" or "Second").." rafflesia ID: "..id)
                return true
            end
        end
        warn("[Search] Could not find "..(isFirst and "first" or "second").." rafflesia")
        return false
    end

    local function findAndSellRafflesia()
        warn("[Search] Looking for second rafflesia to sell...")
        for id = 50, 100 do
            if sellUnit(id) then
                warn("[Sold] Second rafflesia ID: "..id)
                return true
            end
        end
        warn("[Search] Could not find second rafflesia to sell")
        return false
    end

    local function startGame()
        warn("[Game Start] Choosing Apocalypse difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place first rafflesia at 5 seconds
        task.delay(5, function()
            placeUnit("unit_rafflesia", firstRaffData)
        end)
        
        -- Place second rafflesia at 8 seconds  
        task.delay(8, function()
            placeUnit("unit_rafflesia", secondRaffData)
        end)
        
        -- Upgrade first rafflesia at 38 seconds
        task.delay(38, function()
            findAndUpgradeRafflesia(true)
        end)
        
        -- Upgrade second rafflesia at 63 seconds
        task.delay(63, function()
            findAndUpgradeRafflesia(false)
        end)
        
        -- Sell second rafflesia at 80 seconds
        task.delay(80, function()
            findAndSellRafflesia()
        end)
        
        -- Auto-restart at 98 seconds
        task.delay(98, function()
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
    Instructions.Text = "⚠️ Complete Automation\n• Place Rafflesias: 5s & 8s\n• Upgrade 1st: 38s\n• Upgrade 2nd: 63s\n• Sell 2nd: 80s\n• Auto-restart: 98s"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Only 3x Speed Button
    local btn3x = Instance.new("TextButton")
    btn3x.Size = UDim2.new(1, -40, 0, 120)
    btn3x.Position = UDim2.new(0, 20, 0, 160)
    btn3x.Text = "3× SPEED\nComplete Automation\nFull Cycle: 98s"
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
