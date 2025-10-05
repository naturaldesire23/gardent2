--// Garden Tower Defense Script - ENHANCED
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

print(plr.Name .. " loaded script")

--// Key GUI (unchanged)
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
local remotes = ReplicatedStorage:WaitForChild("RemoteFunctions")

task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== MAIN FUNCTION ===--
local function startScript()
    warn("[System] Script started")
    
    pcall(function()
        remotes.ChangeTickSpeed:InvokeServer(3)
    end)

    local trackedIds = {
        tomatoes = {},
        metalFlowers = {},
        potatoes = {}
    }

    -- Upgrade function with validation
    local function upgradeUnit(unitId)
        if unitId == nil or type(unitId) ~= "number" then
            warn("[UpgradeUnit] Invalid unitId: ", unitId)
            return
        end
        pcall(function()
            local success = remotes.UpgradeUnit:InvokeServer(unitId)
            if success then
                warn("[UpgradeUnit] Upgraded unit: ", unitId)
            else
                warn("[UpgradeUnit] Failed to upgrade unit: ", unitId)
            end
        end)
    end

    -- Place function with enhanced ID tracking
    local function placeUnit(unitName, placeData)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, placeData)
        end)
        
        if success and result then
            warn("[Placed] " .. unitName)
            warn("[DEBUG] Result: ", result)
            
            local unitId = nil
            if type(result) == "number" then
                unitId = result
            elseif type(result) == "table" and result.unitId then
                unitId = result.unitId -- Adjust based on actual return structure from SimpleSpy logs
            end
            
            if unitId then
                warn("[DEBUG] Got ID: " .. unitId)
                if unitName:find("tomato") then
                    table.insert(trackedIds.tomatoes, unitId)
                elseif unitName:find("flower") then
                    table.insert(trackedIds.metalFlowers, unitId)
                elseif unitName:find("potato") then
                    table.insert(trackedIds.potatoes, unitId)
                end
            else
                warn("[DEBUG] No valid unit ID returned for " .. unitName)
            end
        else
            warn("[Failed] " .. unitName, result or "No result")
        end
    end

    -- Function to clear invalid IDs
    local function validateIds()
        for unitType, ids in pairs(trackedIds) do
            for i = #ids, 1, -1 do
                local id = ids[i]
                local success = pcall(function()
                    return remotes.UpgradeUnit:InvokeServer(id)
                end)
                if not success then
                    warn("[ValidateIds] Removing invalid ID: ", id, " from ", unitType)
                    table.remove(ids, i)
                end
            end
        end
    end

    -- Upgrade loops with periodic validation
    task.spawn(function()
        while true do
            task.wait(0.3)
            validateIds() -- Check for invalid IDs
            for _, id in ipairs(trackedIds.tomatoes) do
                upgradeUnit(id)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.3)
            validateIds()
            for _, id in ipairs(trackedIds.metalFlowers) do
                upgradeUnit(id)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)
            validateIds()
            for _, id in ipairs(trackedIds.potatoes) do
                upgradeUnit(id)
                upgradeUnit(id) -- Double upgrade for potatoes
            end
        end
    end)

    -- Placements (unchanged)
    local placements = {
        {time = 5, unit = "unit_tomato_rainbow", data = {Valid = true, Rotation = 180, CF = CFrame.new(-850.7767333984375, 61.93030548095703, -155.0453338623047, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-850.7767333984375, 61.93030548095703, -155.0453338623047)}},
        {time = 55, unit = "unit_tomato_rainbow", data = {Valid = true, Rotation = 180, CF = CFrame.new(-852.2405395507812, 61.93030548095703, -150.1680450439453, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)}},
        {time = 85, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-850.2332153320312, 61.93030548095703, -151.0040740966797, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-850.2332153320312, 61.93030548095703, -151.0040740966797)}},
        {time = 100, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-853.2742919921875, 61.93030548095703, -146.7690887451172, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)}},
        {time = 115, unit = "unit_metal_flower", data = {Valid = true, Rotation = 180, CF = CFrame.new(-857.4375, 61.93030548095703, -148.3301239013672, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)}},
        {time = 185, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-851.727783203125, 61.93030548095703, -135.6544952392578, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)}},
        {time = 190, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)}},
        {time = 195, unit = "unit_punch_potato", data = {Valid = true, Rotation = 180, CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1), Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)}}
    }

    -- Main loop with restart handling
    while true do
        warn("=== GAME START ===")
        trackedIds = {tomatoes = {}, metalFlowers = {}, potatoes = {}} -- Reset IDs for new match
        
        pcall(function() remotes.ChangeTickSpeed:InvokeServer(3) end)
        pcall(function() remotes.PlaceDifficultyVote:InvokeServer("dif_hard") end)
        
        -- Place units
        for _, p in ipairs(placements) do
            task.delay(p.time, function()
                placeUnit(p.unit, p.data)
            end)
        end
        
        task.wait(300) -- Wait for match duration
        warn("=== RESTART ===")
        pcall(function() remotes.RestartGame:InvokeServer() end)
        task.wait(5) -- Wait for game to reset
        validateIds() -- Clear any lingering invalid IDs
    end
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Starting..."
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        
        task.delay(1, function()
            ScreenGui:Destroy()
            startScript()
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
print("Loaded!")
