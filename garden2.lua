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
--  Helper functions (новые)
-- ===========================
-- Попытки обнаружить валютный объект игрока (leaderstats и распространённые имена)
local function findMoneyValue()
    -- 1) leaderstats common pattern
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, v in pairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local name = v.Name:lower()
                if name:find("cash") or name:find("coins") or name:find("money") or name:find("gold") or name:find("bucks") or name:find("gems") then
                    return v
                end
            end
        end
        -- fallback: первый числовой объект в leaderstats
        for _, v in pairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                return v
            end
        end
    end

    -- 2) некоторые игры хранят валюту прямо в Player
    local candidates = {"Money", "Cash", "Coins", "Gold", "Currency"}
    for _, name in ipairs(candidates) do
        local v = plr:FindFirstChild(name)
        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end

    -- не нашли
    return nil
end

-- Возвращает значение денег и сам объект (или nil, nil если не найден)
local function getMoney()
    local v = findMoneyValue()
    if v then
        return v.Value, v
    end
    return nil, nil
end

-- Попытка безопасного апгрейда одного юнита: пытается:
-- 1) получить цену через remotes.GetUpgradeCost (если есть) и дождаться денег
-- 2) вызвать remotes.UpgradeUnit и проверить результат (через возвращаемое значение или по изменению баланса)
-- Возвращает true при успешном апгрейде, false в противном случае.
local function safeUpgrade(unitID, opts)
    opts = opts or {}
    local maxWaitForMoney = opts.maxWaitForMoney or 30 -- секунда ожидания денег
    local maxAttempts = opts.maxAttempts or 6

    if not unitID then
        warn("[safeUpgrade] Нет unitID")
        return false
    end

    -- попробуем получить стоимость апгрейда, если такая RemoteFunction есть
    local cost = nil
    if remotes:FindFirstChild("GetUpgradeCost") then
        local ok, res = pcall(function()
            return remotes.GetUpgradeCost:InvokeServer(unitID)
        end)
        if ok and type(res) == "number" then
            cost = res
        end
    end

    -- основной цикл попыток
    local attempt = 0
    while attempt < maxAttempts do
        attempt = attempt + 1

        -- обновим текущее количество денег
        local moneyBefore, moneyObj = getMoney()

        -- если есть цена — дождёмся пока денег хватит (с таймаутом)
        if cost then
            if not moneyBefore or moneyBefore < cost then
                local waited = 0
                while (not moneyBefore or moneyBefore < cost) and waited < maxWaitForMoney do
                    warn(string.format("[safeUpgrade] Slot %s: не хватает денег (%s/%s). Жду... (%ss)", tostring(unitID), tostring(moneyBefore), tostring(cost), waited))
                    task.wait(1)
                    waited = waited + 1
                    moneyBefore, moneyObj = getMoney()
                end
                if not moneyBefore or moneyBefore < cost then
                    warn("[safeUpgrade] Таймаут ожидания денег или валюта не обнаружена. Попытка "..attempt.." из "..maxAttempts)
                    task.wait(0.5)
                    -- перейдём к следующей попытке (можно увеличить таймаут/поменять логику)
                    -- если денег нет, retry делает sense только если игрок будет фармить между попытками
                    -- продолжим цикл retry
                end
            end
        end

        -- Попробуем вызвать апгрейд
        local ok, res = pcall(function()
            return remotes.UpgradeUnit:InvokeServer(unitID)
        end)

        if not ok then
            warn("[safeUpgrade] InvokeServer error: "..tostring(res).." (попытка "..attempt..")")
            task.wait(1)
            continue
        end

        -- Если сервер вернул true — успех
        if res == true then
            warn("[safeUpgrade] Сервер подтвердил апгрейд для unit "..tostring(unitID))
            return true
        end

        -- Если у нас есть объект валюты, подождём маленькую паузу и посмотрим, уменьшился ли баланс
        if moneyObj then
            local before = moneyBefore or moneyObj.Value
            task.wait(0.6) -- дать серверу применить списание
            local after = moneyObj.Value
            if after < before then
                warn("[safeUpgrade] Баланс уменьшился: апгрейд выполнен для unit "..tostring(unitID).." ("..tostring(before).." -> "..tostring(after)..")")
                return true
            else
                warn("[safeUpgrade] Баланс не изменился и сервер не вернул true. Попытка "..attempt.." из "..maxAttempts)
                task.wait(0.7)
            end
        else
            -- не удалось получить валюту для проверки, но сервер вернул не-true; попробуем ещё раз или считать что не удалось
            if res then
                -- если сервер вернул какое-то ненулевое значение — допустим успешным
                warn("[safeUpgrade] Сервер вернул значение "..tostring(res)..", считаю апгрейд успешным (unit "..tostring(unitID)..")")
                return true
            end
            warn("[safeUpgrade] Не удалось проверить апгрейд (нет валюты, сервер не подтвердил). Попытка "..attempt.." из "..maxAttempts)
            task.wait(1)
        end
    end

    warn("[safeUpgrade] Не удалось выполнить апгрейд для unit "..tostring(unitID).." после "..tostring(maxAttempts).." попыток")
    return false
end

-- ===========================
--  GAME SCRIPTS (2x / 3x) — почти без изменений, кроме использования safeUpgrade
-- ===========================
function load2xScript()
    warn("[System] Loaded 2x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(2)

    local difficulty = "dif_hard"
    local unitIDs = {} -- Track unit IDs for upgrades

    local placements = {
        -- Slingshot (Early Game)
        {
            time = 15, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.806396484375, 61.9303092956543, -165.56829833984375),
                CF = CFrame.new(-845.806396484375, 61.9303092956543, -165.56829833984375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        },
        -- Rafflesia (Mid Game)
        {
            time = 47, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.3812866210938, 62.18030548095703, -159.8401641845703),
                DistanceAlongPath = 182.71156311035156,
                Rotation = 180,
                CF = CFrame.new(-842.3812866210938, 62.18030548095703, -159.8401641845703, 1, 0, -0, -0, 1, -0, -0, 0, 1)
            }
        },
        -- Golem Dragon (Late Game)
        {
            time = 85, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.949951171875, 61.93030548095703, -163.9769287109375),
                CF = CFrame.new(-855.949951171875, 61.93030548095703, -163.9769287109375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)

        if success and result then
            unitIDs[slot] = result -- Store the unit ID returned by the game
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | No ID returned")
        end
    end

    local function upgradeUnit(slot, times)
        if not unitIDs[slot] then
            warn("[Upgrade Failed] No unit ID for slot "..slot)
            return
        end

        for i = 1, times do
            warn("[Upgrade] Начинаю апгрейд "..i.." для слота "..slot)
            local ok = safeUpgrade(unitIDs[slot], { maxWaitForMoney = 25, maxAttempts = 8 })
            if ok then
                warn("[Upgrading] Slot "..slot.." | ID: "..unitIDs[slot].." | LevelAttempt "..i.." - SUCCESS")
            else
                warn("[Upgrading] Slot "....slot.." | ID: "..unitIDs[slot].." | LevelAttempt "..i.." - FAILED / TIMEOUT")
            end
            task.wait(1.5) -- небольшая пауза между апгрейдами
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)

        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end

        -- Upgrade units (4 times each)
        task.delay(90, function() upgradeUnit(1, 4) end) -- Slingshot
        task.delay(95, function() upgradeUnit(2, 4) end) -- Rafflesia
        task.delay(100, function() upgradeUnit(3, 4) end) -- Golem Dragon
    end

    while true do
        startGame()
        task.wait(174.5)
        remotes.RestartGame:InvokeServer()
        unitIDs = {} -- Reset unit IDs for next game
    end
end

function load3xScript()
    warn("[System] Loaded 3x Speed Script")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_hard"
    local unitIDs = {} -- Track unit IDs for upgrades

    local placements = {
        -- Slingshot (Early Game) - Faster timing for 3x
        {
            time = 12, unit = "unit_slingshot", slot = 1,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-845.806396484375, 61.9303092956543, -165.56829833984375),
                CF = CFrame.new(-845.806396484375, 61.9303092956543, -165.56829833984375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        },
        -- Rafflesia (Mid Game)
        {
            time = 32, unit = "unit_rafflesia", slot = 2,
            data = {
                Valid = true,
                PathIndex = 3,
                Position = Vector3.new(-842.3812866210938, 62.18030548095703, -159.8401641845703),
                DistanceAlongPath = 182.71156311035156,
                Rotation = 180,
                CF = CFrame.new(-842.3812866210938, 62.18030548095703, -159.8401641845703, 1, 0, -0, -0, 1, -0, -0, 0, 1)
            }
        },
        -- Golem Dragon (Late Game)
        {
            time = 57, unit = "unit_golem_dragon", slot = 3,
            data = {
                Valid = true,
                Rotation = 180,
                Position = Vector3.new(-855.949951171875, 61.93030548095703, -163.9769287109375),
                CF = CFrame.new(-855.949951171875, 61.93030548095703, -163.9769287109375, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1)
            }
        }
    }

    local function placeUnit(unitName, slot, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)

        if success and result then
            unitIDs[slot] = result -- Store the unit ID returned by the game
            warn("[Placing] "..unitName.." | ID: "..tostring(result))
        else
            warn("[Placing] "..unitName.." | No ID returned")
        end
    end

    local function upgradeUnit(slot, times)
        if not unitIDs[slot] then
            warn("[Upgrade Failed] No unit ID for slot "..slot)
            return
        end

        for i = 1, times do
            warn("[Upgrade] Начинаю апгрейд "..i.." для слота "..slot)
            local ok = safeUpgrade(unitIDs[slot], { maxWaitForMoney = 20, maxAttempts = 6 })
            if ok then
                warn("[Upgrading] Slot "..slot.." | ID: "..unitIDs[slot].." | LevelAttempt "..i.." - SUCCESS")
            else
                warn("[Upgrading] Slot "....slot.." | ID: "..unitIDs[slot].." | LevelAttempt "..i.." - FAILED / TIMEOUT")
            end
            task.wait(1) -- чуть меньшая пауза для 3x
        end
    end

    local function startGame()
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)

        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.slot, p.data)
            end)
        end

        -- Upgrade units (4 times each)
        task.delay(60, function() upgradeUnit(1, 4) end) -- Slingshot
        task.delay(65, function() upgradeUnit(2, 4) end) -- Rafflesia
        task.delay(70, function() upgradeUnit(3, 4) end) -- Golem Dragon
    end

    while true do
        startGame()
        task.wait(128)
        remotes.RestartGame:InvokeServer()
        unitIDs = {} -- Reset unit IDs for next game
    end
end

--=== SPEED MENU ===--
local function showSpeedMenu()
    Title.Text = "Select Speed"
    TextBox.Visible = false
    CheckBtn.Visible = false

    -- Reminder label directly below title
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
