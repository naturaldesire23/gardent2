--// Garden Tower Defense Script - Dual Rainbow Tomato Fast Upgrade
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

--=== DUAL RAINBOW TOMATO FAST UPGRADE ===--

function loadRainbowTomatoScript()
    warn("[System] Loaded Dual Rainbow Tomato - Fast Upgrade Strategy")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_hard"
    
    local tomatoPlacements = {
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
            time = 42,
            unit = "unit_tomato_rainbow", 
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-852.2405395507812, 61.93030548095703, -150.1680450439453, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)
            }
        }
    }

    local function placeTomato(unitName, data)
        local success = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placing] Rainbow Tomato at "..os.clock())
            return true
        else
            warn("[Placing] Rainbow Tomato - Failed")
            return false
        end
    end

    local function upgradeUnit(unitId)
        local success, result = pcall(function()
            return remotes.UpgradeUnit:InvokeServer(unitId)
        end)
        if success then
            return true
        else
            return false
        end
    end

    local function fastInfiniteUpgrade()
        warn("[Fast Upgrade] Starting infinite fast upgrades...")
        
        while true do
            -- Rapidly upgrade all IDs from 1 to 100
            for id = 1, 100 do
                upgradeUnit(id)
                -- No delay between upgrades for maximum speed
            end
            -- Very small delay between full cycles
            task.wait(0.1)
        end
    end

    local function startGame()
        warn("[Game Start] Choosing Hard difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place both tomatoes at their times
        for _, placement in ipairs(tomatoPlacements) do
            task.delay(placement.time, function()
                placeTomato(placement.unit, placement.data)
            end)
        end
        
        -- Start fast infinite upgrades at 8 seconds (after first tomato)
        task.delay(8, function()
            warn("[Starting] Beginning fast infinite upgrades!")
            fastInfiniteUpgrade()
        end)
        
        -- Auto-restart at 180 seconds (3 minutes)
        task.delay(180, function()
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

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "SELECT STRATEGY"
    SubTitle.Text = "Dual Rainbow Tomato Fast Upgrade"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 80)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "⚠️ Dual Rainbow Tomato\n• Hard Difficulty\n• Place 1st: 5s\n• Place 2nd: 42s\n• Fast Infinite Upgrades\n• IDs 1-100 Rapid Fire"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Rainbow Tomato Button
    local btnRainbow = Instance.new("TextButton")
    btnRainbow.Size = UDim2.new(1, -40, 0, 120)
    btnRainbow.Position = UDim2.new(0, 20, 0, 160)
    btnRainbow.Text = "DUAL RAINBOW TOMATO\nFast Infinite Upgrades\nRapid Fire IDs 1-100"
    btnRainbow.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btnRainbow.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRainbow.Font = Enum.Font.GothamBold
    btnRainbow.TextSize = 18
    btnRainbow.BorderSizePixel = 0
    btnRainbow.Parent = Frame

    local btnRainbowCorner = Instance.new("UICorner")
    btnRainbowCorner.CornerRadius = UDim.new(0, 10)
    btnRainbowCorner.Parent = btnRainbow

    btnRainbow.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadRainbowTomatoScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading strategy selection..."
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
