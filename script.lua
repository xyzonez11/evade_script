local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:FindFirstChild("HumanoidRootPart")
local Mouse = LP:GetMouse()

-- ====== BIẾN ======
local isClickTeleport = false
local isRunning = false
local noclipEnabled = false
local espEnabled = true
local espObjects = {}
local selectedPlayer = nil
local guiOpened = false

-- ====== NOTIFICATION ======
local function Notify(title, text, duration)
    duration = duration or 3
    StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration})
end

-- ====== TÌM NGƯỜI GỤC ======
local function FindDownedPlayer()
    if not RootPart then return nil end
    local nearest = nil
    local nearestDist = math.huge
    local myPos = RootPart.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetChar = player.Character
            local humanoid = targetChar:FindFirstChild("Humanoid")
            local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart and humanoid.Health <= 0 then
                local dist = (rootPart.Position - myPos).Magnitude
                if dist < nearestDist and dist <= 250 then
                    nearest = targetChar
                    nearestDist = dist
                end
            end
        end
    end
    return nearest
end

-- ====== TELEPORT ======
local function TeleportToTarget(targetChar)
    if not targetChar or not RootPart then
        Notify("❌ Lỗi", "Không tìm thấy mục tiêu!", 2)
        return false
    end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Notify("❌ Lỗi", "Mục tiêu không có RootPart!", 2)
        return false
    end
    local targetPos = targetRoot.Position + Vector3.new(0, 1, 3)
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(RootPart, tweenInfo, {Position = targetPos})
    tween:Play()
    tween.Completed:Wait()
    return true
end

-- ====== TELEPORT ĐẾN NGƯỜI GỤC ======
local function TeleportAndRevive()
    if isRunning then return end
    if not Character or not RootPart then
        Notify("❌ Lỗi", "Chưa có nhân vật!", 2)
        return
    end
    isRunning = true
    local target = FindDownedPlayer()
    if target then
        local playerName = "người chơi"
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == target then
                playerName = player.Name
                break
            end
        end
        TeleportToTarget(target)
        Notify("✅ Đã teleport", "đến " .. playerName, 2)
    else
        Notify("❌", "Không có ai gục!", 1.5)
    end
    isRunning = false
end

-- ====== TELEPORT ĐẾN NGƯỜI CHƠI BẤT KỲ ======
local function TeleportToPlayer(player)
    if not player or not player.Character then
        Notify("❌ Lỗi", "Người chơi không hợp lệ!", 2)
        return
    end
    local targetChar = player.Character
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Notify("❌ Lỗi", "Không tìm thấy RootPart!", 2)
        return
    end
    local targetPos = targetRoot.Position + Vector3.new(0, 1, 3)
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(RootPart, tweenInfo, {Position = targetPos})
    tween:Play()
    tween.Completed:Wait()
    Notify("✅ Đã teleport", "đến " .. player.Name, 2)
end

-- ====== CLICK TELEPORT ======
local function ToggleClickTeleport()
    isClickTeleport = not isClickTeleport
    if isClickTeleport then
        Notify("🎯 CLICK TELEPORT", "ĐÃ BẬT! Click chuột để teleport", 3)
        noclipEnabled = true
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        Notify("❌ CLICK TELEPORT", "ĐÃ TẮT", 2)
        noclipEnabled = false
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ====== ESP BOX + TÊN + KHOẢNG CÁCH ======
local function UpdateESP()
    for _, obj in ipairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}

    if not espEnabled then return end
    if not RootPart then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if not root or not humanoid then continue end

            local dist = math.floor((root.Position - RootPart.Position).Magnitude)

            local color = Color3.fromRGB(50, 255, 50)
            if humanoid.Health <= 0 then
                color = Color3.fromRGB(255, 50, 50)
            end

            -- ── Box xuyên tường bao quanh toàn thân ──
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = root
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Size = Vector3.new(2.2, 5.8, 1.2)
            box.CFrame = CFrame.new(0, 1.5, 0)
            box.Color3 = color
            box.Transparency = 0.5
            box.Parent = workspace

            -- ── BillboardGui chứa tên + khoảng cách ──
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_NameTag"
            billboard.Size = UDim2.new(0, 150, 0, 44)
            billboard.StudsOffset = Vector3.new(0, 3.4, 0)
            billboard.Adornee = root
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 200
            billboard.Parent = root

            local layout = Instance.new("UIListLayout")
            layout.Parent = billboard
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            layout.Padding = UDim.new(0, 2)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = billboard
            nameLabel.Size = UDim2.new(1, 0, 0, 22)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = color
            nameLabel.Text = player.Name
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0.2

            local distLabel = Instance.new("TextLabel")
            distLabel.Parent = billboard
            distLabel.Size = UDim2.new(1, 0, 0, 18)
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            distLabel.Text = dist .. " m"
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextSize = 11
            distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            distLabel.TextStrokeTransparency = 0.2

            table.insert(espObjects, box)
            table.insert(espObjects, billboard)
        end
    end
end

-- ====== GUI BẢNG CHỌN NGƯỜI CHƠI ======
local function CreatePlayerListGUI()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGUI"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.Enabled = true

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 300, 0, 500)
    frame.Position = UDim2.new(0.5, -150, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 2

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "🚀 TELEPORT TO PLAYER"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = frame
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextScaled = true

    local corner2 = Instance.new("UICorner")
    corner2.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        guiOpened = false
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = frame
    scrollFrame.Size = UDim2.new(1, 0, 1, -40)
    scrollFrame.Position = UDim2.new(0, 0, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

    local function UpdatePlayerList()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                local btn = Instance.new("TextButton")
                btn.Parent = scrollFrame
                btn.Size = UDim2.new(1, -10, 0, 40)
                btn.Position = UDim2.new(0, 5, 0, 0)
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.Gotham
                btn.TextScaled = true
                btn.Text = "📌 " .. player.Name

                local btnCorner = Instance.new("UICorner")
                btnCorner.Parent = btn
                btnCorner.CornerRadius = UDim.new(0, 5)

                btn.MouseEnter:Connect(function()
                    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                end)

                btn.MouseButton1Click:Connect(function()
                    TeleportToPlayer(player)
                    screenGui:Destroy()
                    guiOpened = false
                end)
            end
        end
    end

    UpdatePlayerList()
    Players.PlayerAdded:Connect(UpdatePlayerList)
    Players.PlayerRemoving:Connect(UpdatePlayerList)

    guiOpened = true
    return screenGui
end

-- ====== MỞ/ĐÓNG GUI BẰNG PHÍM X ======
local function ToggleGUI()
    if guiOpened then
        local gui = game:GetService("CoreGui"):FindFirstChild("TeleportGUI")
        if gui then gui:Destroy() end
        guiOpened = false
    else
        CreatePlayerListGUI()
    end
end

-- ====== PHÍM BẤM ======
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.V then
        TeleportAndRevive()
    end

    if input.KeyCode == Enum.KeyCode.Z then
        ToggleClickTeleport()
    end

    if input.KeyCode == Enum.KeyCode.X then
        ToggleGUI()
    end
end)

-- ====== CLICK CHUỘT ======
Mouse.Button1Down:Connect(function()
    if not isClickTeleport then return end
    if not RootPart then return end
    local targetPos = Mouse.Hit.Position
    if targetPos then
        local distance = (targetPos - RootPart.Position).Magnitude
        if distance > 500 then
            Notify("⚠️ Quá xa", "Khoảng cách: " .. math.floor(distance), 1.5)
            return
        end
        Notify("🎯 Teleport!", "Đã dịch chuyển đến vị trí chuột", 1.5)
        RootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
        RootPart.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- ====== NOCLIP ======
RunService.Heartbeat:Connect(function()
    if noclipEnabled and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ====== CẬP NHẬT ESP LIÊN TỤC ======
RunService.Heartbeat:Connect(function()
    if espEnabled then
        UpdateESP()
    end
end)

-- ====== RESPAWN ======
LP.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    isRunning = false
    if isClickTeleport then
        isClickTeleport = false
        noclipEnabled = false
    end
    Notify("🔄 Respawn", "Nhân vật mới đã xuất hiện!", 2)
end)

-- ====== KHỞI ĐỘNG ======
Notify("🚀 SCRIPT ĐÃ CHẠY!", "[V] Teleport gục | [Z] Click TP | [X] Bảng chọn TP", 4)
print("✅ Script đã chạy!")
print("📌 [V] Teleport đến người gục")
print("📌 [Z] Bật/Tắt Click Teleport")
print("📌 [X] Mở bảng chọn người chơi để teleport")
print("👁️ ESP: Box bao quanh nhân vật — Xanh lá = sống, Đỏ = gục")

wait(0.5)
UpdateESP()
