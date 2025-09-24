--// Key system (fixed version)
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print("Waiting for key...")

--// Key GUI
local ScreenGui = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Enter Key"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, -20, 0, 40)
TextBox.Position = UDim2.new(0, 10, 0, 50)
TextBox.PlaceholderText = "Enter Key Here"
TextBox.Text = ""
TextBox.Font = Enum.Font.Gotham
TextBox.TextSize = 16
TextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

local CheckBtn = Instance.new("TextButton", Frame)
CheckBtn.Size = UDim2.new(1, -20, 0, 40)
CheckBtn.Position = UDim2.new(0, 10, 0, 100)
CheckBtn.Text = "Check Key"
CheckBtn.Font = Enum.Font.GothamBold
CheckBtn.TextSize = 18
CheckBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)

local Label = Instance.new("TextLabel", Frame)
Label.Size = UDim2.new(1, -20, 0, 40)
Label.Position = UDim2.new(0, 10, 0, 150)
Label.BackgroundTransparency = 1
Label.Text = ""
Label.Font = Enum.Font.GothamBold
Label.TextSize = 16
Label.TextColor3 = Color3.fromRGB(255, 255, 255)

--// Remotes
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("RemoteFunctions")

-- Вывод всех RemoteFunctions и RemoteEvents
warn("=== RemoteFunctions/Events list ===")
for _, v in pairs(remotes:GetChildren()) do
    if v:IsA("RemoteFunction") or v:IsA("RemoteEvent") then
        warn("[Remotes] Found:", v.Name, v.ClassName)
    end
end
warn("=== End of list ===")

-- Auto Skip (enable once at start)
task.delay(2, function()
    pcall(function()
        if remotes:FindFirstChild("ToggleAutoSkip") then
            remotes.ToggleAutoSkip:InvokeServer(true)
            warn("[System] Auto Skip Enabled")
        end
    end)
end)

-- ===========================
--  Safe Upgrade Function
-- ===========================
local function safeUpgrade(unitID)
    if not unitID then return false end

    -- проверяем наличие RemoteFunction
    local upgradeRemote = remotes:FindFirstChild("UpgradeUnit") -- тут можно поменять имя, если у тебя другое
    if not upgradeRemote then
        warn("[safeUpgrade] ❌ Remote UpgradeUnit не найден! Проверь имя RemoteFunction.")
        return false
    end

    local success, result = pcall(function()
        return upgradeRemote:InvokeServer(unitID)
    end)

    if success and result == true then
        warn("[safeUpgrade] ✅ Апгрейд успешен для ID:", unitID)
        return true
    else
        warn("[safeUpgrade] ❌ Не удалось апгрейдить ID:", unitID, "Ответ:", result)
        return false
    end
end

-- ===========================
--  GAME SCRIPTS (2x / 3x)
-- ===========================
function load2xScript()
    warn("[System] Loaded 2x Speed Script")
    if remotes:FindFirstChild("ChangeTickSpeed") then
        remotes.ChangeTickSpeed:InvokeServer(2)
    end

    local difficulty = "dif_hard"
    local unitIDs = {}

    local placements = {
        {
            time = 15, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.8, 61.93, -165.56),
                CF = CFrame.new(-845.8, 61.93, -165.56)
            }
        },
        {
            time = 47, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.38, 62.18, -159.84),
                DistanceAlongPath = 182.71,
                Rotation = 180,
                CF = CFrame.new(-842.38, 62.18, -159.84)
            }
        },
        {
            time = 85, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.94, 61.93, -163.97),
                CF = CFrame.new(-855.94, 61.93, -163.97)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)

        if success and result then
            unitIDs[slot] = result
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | ❌ ошибка размещения")
        end
    end

    local function upgradeUnit(slot, times)
        if not unitIDs[slot] then
            warn("[Upgrade Failed] ❌ Нет unitID для слота "..slot)
            return
        end

        for i = 1, times do
            task.delay(i * 2, function()
                local ok = safeUpgrade(unitIDs[slot])
                if ok then
                    warn("[Upgrading] ✅ Slot "..slot.." | Level "..i)
                else
                    warn("[Upgrading] ❌ Slot "..slot.." | Level "..i.." не удался")
                end
            end)
        end
    end

    local function startGame()
        if remotes:FindFirstChild("PlaceDifficultyVote") then
            remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        end

        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end

        task.delay(90, function() upgradeUnit(1, 4) end)
        task.delay(95, function() upgradeUnit(2, 4) end)
        task.delay(100, function() upgradeUnit(3, 4) end)
    end

    while true do
        startGame()
        task.wait(174.5)
        if remotes:FindFirstChild("RestartGame") then
            remotes.RestartGame:InvokeServer()
        end
        unitIDs = {}
    end
end

function load3xScript()
    warn("[System] Loaded 3x Speed Script")
    if remotes:FindFirstChild("ChangeTickSpeed") then
        remotes.ChangeTickSpeed:InvokeServer(3)
    end

    local difficulty = "dif_hard"
    local unitIDs = {}

    local placements = {
        {
            time = 12, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.8, 61.93, -165.56),
                CF = CFrame.new(-845.8, 61.93, -165.56)
            }
        },
        {
            time = 32, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.38, 62.18, -159.84),
                DistanceAlongPath = 182.71,
                Rotation = 180,
                CF = CFrame.new(-842.38, 62.18, -159.84)
            }
        },
        {
            time = 57, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.94, 61.93, -163.97),
                CF = CFrame.new(-855.94, 61.93, -163.97)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)

        if success and result then
            unitIDs[slot] = result
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | ❌ ошибка размещения")
        end
    end

    local function upgradeUnit(slot, times)
        if not unitIDs[slot] then
            warn("[Upgrade Failed] ❌ Нет unitID для слота "..slot)
            return
        end

        for i = 1, times do
            task.delay(i * 1.5, function()
                local ok = safeUpgrade(unitIDs[slot])
                if ok then
                    warn("[Upgrading] ✅ Slot "..slot.." | Level "..i)
                else
                    warn("[Upgrading] ❌ Slot "..slot.." | Level "..i.." не удался")
                end
            end)
        end
    end

    local function startGame()
        if remotes:FindFirstChild("PlaceDifficultyVote") then
            remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        end

        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end

        task.delay(60, function() upgradeUnit(1, 4) end)
        task.delay(65, function() upgradeUnit(2, 4) end)
        task.delay(70, function() upgradeUnit(3, 4) end)
    end

    while true do
        startGame()
        task.wait(128)
        if remotes:FindFirstChild("RestartGame") then
            remotes.RestartGame:InvokeServer()
        end
        unitIDs = {}
    end
end

--=== SPEED MENU ===--
local function showSpeedMenu()
    Title.Text = "Select Speed"
    TextBox.Visible = false
    CheckBtn.Visible = false

    local AutoSkipMsg = Instance.new("TextLabel", Frame)
    AutoSkipMsg.Size = UDim2.new(1, -20, 0, 30)
    AutoSkipMsg.Position = UDim2.new(0, 10, 0, 40)
    AutoSkipMsg.BackgroundTransparency = 1
    AutoSkipMsg.Text = "Pls Enable Auto Skip On Manually"
    AutoSkipMsg.Font = Enum.Font.GothamBold
    AutoSkipMsg.TextSize = 14
    AutoSkipMsg.TextColor3 = Color3.fromRGB(255, 200, 0)
    AutoSkipMsg.TextWrapped = true

    local btn2x = Instance.new("TextButton", Frame)
    btn2x.Size = UDim2.new(0.45, 0, 0, 50)
    btn2x.Position = UDim2.new(0.05, 0, 0.5, -25)
    btn2x.Text = "2x Speed"
    btn2x.BackgroundColor3 = Color3.fromRGB(80,160,250)

    local btn3x = Instance.new("TextButton", Frame)
    btn3x.Size = UDim2.new(0.45, 0, 0, 50)
    btn3x.Position = UDim2.new(0.5, 0, 0.5, -25)
    btn3x.Text = "3x Speed"
    btn3x.BackgroundColor3 = Color3.fromRGB(250,120,120)

    btn2x.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        load2xScript()
    end)

    btn3x.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        load3xScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:lower() == "cracked" then
        Label.Text = "Key Accepted!"
        Label.TextColor3 = Color3.fromRGB(0,255,0)
        task.delay(1, showSpeedMenu)
    else
        TextBox.Text = ""
        Label.Text = "Invalid Key!"
        Label.TextColor3 = Color3.fromRGB(255,0,0)
    end
end)

print("Script loaded! Enter key: cracked")
