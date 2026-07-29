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

local isClickTeleport = false
local isRunning = false
local noclipEnabled = false
local espEnabled = true
local espObjects = {}
local guiOpened = false

local function Notify(title, text, duration)
    duration = duration or 3
    StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration})
end

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

-- ====== CLICK TELEPORT (CÓ RESET VẬT LÝ) ======
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
        if RootPart then
            RootPart.Velocity = Vector3.new(0, 0, 0)
        end
    else
        Notify("❌ CLICK TELEPORT", "ĐÃ TẮT", 2)
        noclipEnabled = false
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        if RootPart then
            RootPart.Velocity = Vector3.new(0, 0, 0)
            RootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        if Humanoid then
            Humanoid.Sit = false
            Humanoid.PlatformStand = false
        end
    end
end

-- ====== TỰ ĐỘNG TẮT NOCLIP KHI BỊ GỤC (SỬA LỖI VĂNG) ======
Humanoid.HealthChanged:Connect(function()
    if Humanoid.Health <= 0 then
        if isClickTeleport then
            isClickTeleport = false
            noclipEnabled = false
            Notify("🔄", "Đã tự tắt Click Teleport khi bị gục!", 2)
        end
        
        if RootPart then
            RootPart.Velocity = Vector3.new(0, 0, 0)
            RootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        
        if Humanoid then
            Humanoid.Sit = false
            Humanoid.PlatformStand = false
        end
    end
end)

-- ====== ESP ======
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

            local dist = (root.Position - RootPart.Position).Magnitude
            local color = Color3.fromRGB(50, 255, 50)
            if humanoid.Health <= 0 then
                color = Color3.fromRGB(255, 50, 50)
            end

            local scale = 1 + (dist / 100)
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = root
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Size = Vector3.new(2.2 * scale, 5.8 * scale, 1.2 * scale)
            box.CFrame = CFrame.new(0, 1.5, 0)
            box.Color3 = color
            box.Transparency = 0.5
            box.Parent = root

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_NameTag"
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3.4, 0)
            billboard.Adornee = root
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 9999
            billboard.Parent = root

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = billboard
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = color
            nameLabel.Text = player.Name
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0.2

            table.insert(espObjects, box)
            table.insert(espObjects, billboard)
        end
    end
end

-- ====== GUI BẢNG CHỌN ======
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
    frame.Size = UDim2.new(0, 320, 0, 500)
    frame.Position = UDim2.new(0.5, -160, 0.5, -250)
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
    title.Size = UDim2.new(1, -45, 0, 40)
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
    closeBtn.ZIndex = 3

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
    listLayout.Padding = UDim.new(0, 6)

    local function UpdatePlayerList()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                local btn = Instance.new("TextButton")
                btn.Parent = scrollFrame
                btn.Size = UDim2.new(1, -10, 0, 50)
                btn.Position = UDim2.new(0, 5, 0, 0)
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                btn.Text = ""
                btn.AutoButtonColor = false

                local btnCorner = Instance.new("UICorner")
                btnCorner.Parent = btn
                btnCorner.CornerRadius = UDim.new(0, 8)

                local avatar = Instance.new("ImageLabel")
                avatar.Parent = btn
                avatar.Size = UDim2.new(0, 38, 0, 38)
                avatar.Position = UDim2.new(0, 6, 0.5, -19)
                avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                avatar.BorderSizePixel = 0
                avatar.Image = ""

                local avatarCorner = Instance.new("UICorner")
                avatarCorner.Parent = avatar
                avatarCorner.CornerRadius = UDim.new(0, 6)

                task.spawn(function()
                    local ok, url = pcall(function()
                        return Players:GetUserThumbnailAsync(
                            player.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size100x100
                        )
                    end)
                    if ok and avatar and avatar.Parent then
                        avatar.Image = url
                    end
                end)

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Parent = btn
                nameLabel.Size = UDim2.new(1, -58, 1, 0)
                nameLabel.Position = UDim2.new(0, 52, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 14
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Text = player.Name

                btn.MouseEnter:Connect(function()
                    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                end)

                btn.MouseButton1Click:Connect(function()
                    screenGui:Destroy()
                    guiOpened = false
                    TeleportToPlayer(player)
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

local function ToggleGUI()
    if guiOpened then
        local gui = game:GetService("CoreGui"):FindFirstChild("TeleportGUI")
        if gui then gui:Destroy() end
        guiOpened = false
    else
        CreatePlayerListGUI()
    end
end

-- ====== CHỐNG ĐẨY KHI XOAY CAMERA ======
RunService.Heartbeat:Connect(function()
    if not isClickTeleport then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == false then
                part.CanCollide = true
            end
        end
        if RootPart and RootPart.Velocity.Magnitude > 50 then
            RootPart.Velocity = Vector3.new(0, 0, 0)
            RootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then TeleportAndRevive() end
    if input.KeyCode == Enum.KeyCode.Z then ToggleClickTeleport() end
    if input.KeyCode == Enum.KeyCode.X then ToggleGUI() end
end)

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

RunService.Heartbeat:Connect(function()
    if noclipEnabled and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if espEnabled then UpdateESP() end
end)

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

Notify("🚀 SCRIPT ĐÃ CHẠY!", "[V] Teleport gục | [Z] Click TP | [X] Bảng chọn TP", 4)
print("✅ Script đã chạy!")
print("📌 [V] Teleport đến người gục")
print("📌 [Z] Bật/Tắt Click Teleport")
print("📌 [X] Mở bảng chọn người chơi để teleport")
print("👁️ ESP: Box xuyên tường + tên — Xanh lá = sống, Đỏ = gục")
print("🛡️ Tự động tắt Noclip khi bị gục để tránh văng")

wait(0.5)
UpdateESP()
