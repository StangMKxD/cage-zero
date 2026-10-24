--!strict
-- src/client/controllers/TrainingHUD.luau
-- Minimal Training Fixture HUD for Module 02 (02-player-actions) per F-19 & T-05
-- Displays live server context (Attacking/Defending), stamina gauge, ball status, training controls,
-- and toggleable Controls Codex manual modal (hidden by default).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local TrainingHUD = {}
local isInitialized = false
local activeCodexModal: Frame? = nil

function TrainingHUD.ToggleCodex()
	if not activeCodexModal or not activeCodexModal.Parent then
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
		local screenGui = playerGui and playerGui:FindFirstChild("Module02_TrainingHUD")
		activeCodexModal = if screenGui then (screenGui:FindFirstChild("ControlsCodexModal") :: Frame?) else nil
	end
	if activeCodexModal then
		activeCodexModal.Visible = not activeCodexModal.Visible
	end
end

function TrainingHUD.SetCodexVisible(visible: boolean)
	if not activeCodexModal or not activeCodexModal.Parent then
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
		local screenGui = playerGui and playerGui:FindFirstChild("Module02_TrainingHUD")
		activeCodexModal = if screenGui then (screenGui:FindFirstChild("ControlsCodexModal") :: Frame?) else nil
	end
	if activeCodexModal then
		activeCodexModal.Visible = visible
	end
end

function TrainingHUD.CreateScreenGui(targetParent: Instance): ScreenGui
	local localPlayer = Players.LocalPlayer
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Module02_TrainingHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Parent = targetParent

	-- 1. Bottom Container Frame
	local container = Instance.new("Frame")
	container.Name = "HUDContainer"
	container.Size = UDim2.new(0, 520, 0, 95)
	container.Position = UDim2.new(0.5, -260, 1.0, -115)
	container.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	container.BackgroundTransparency = 0.25
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 1.5
	stroke.Parent = container

	-- Context badge (Attacking / Defending)
	local contextBadge = Instance.new("TextLabel")
	contextBadge.Name = "ContextBadge"
	contextBadge.Size = UDim2.new(0, 130, 0, 24)
	contextBadge.Position = UDim2.new(0, 12, 0, 10)
	contextBadge.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	contextBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
	contextBadge.Font = Enum.Font.GothamBold
	contextBadge.TextSize = 12
	contextBadge.Text = "ATTACKING"
	contextBadge.Parent = container

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = contextBadge

	-- Ball status label
	local ballLabel = Instance.new("TextLabel")
	ballLabel.Name = "BallStatusLabel"
	ballLabel.Size = UDim2.new(0, 240, 0, 24)
	ballLabel.Position = UDim2.new(0, 152, 0, 10)
	ballLabel.BackgroundTransparency = 1
	ballLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
	ballLabel.Font = Enum.Font.GothamMedium
	ballLabel.TextSize = 12
	ballLabel.TextXAlignment = Enum.TextXAlignment.Left
	ballLabel.Text = "Ball: Free"
	ballLabel.Parent = container

	-- Codex Toggle Button on HUD
	local codexToggleBtn = Instance.new("TextButton")
	codexToggleBtn.Name = "CodexToggleBtn"
	codexToggleBtn.Size = UDim2.new(0, 100, 0, 24)
	codexToggleBtn.Position = UDim2.new(1, -112, 0, 10)
	codexToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	codexToggleBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
	codexToggleBtn.Font = Enum.Font.GothamBold
	codexToggleBtn.TextSize = 11
	codexToggleBtn.Text = "📖 คู่มือ [H]"
	codexToggleBtn.Parent = container

	local codexBtnCorner = Instance.new("UICorner")
	codexBtnCorner.CornerRadius = UDim.new(0, 4)
	codexBtnCorner.Parent = codexToggleBtn

	local codexBtnStroke = Instance.new("UIStroke")
	codexBtnStroke.Color = Color3.fromRGB(56, 189, 248)
	codexBtnStroke.Thickness = 1
	codexBtnStroke.Parent = codexToggleBtn

	-- Stamina bar background
	local staminaBg = Instance.new("Frame")
	staminaBg.Name = "StaminaBg"
	staminaBg.Size = UDim2.new(1, -24, 0, 14)
	staminaBg.Position = UDim2.new(0, 12, 0, 42)
	staminaBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	staminaBg.BorderSizePixel = 0
	staminaBg.Parent = container

	local stamBgCorner = Instance.new("UICorner")
	stamBgCorner.CornerRadius = UDim.new(0, 4)
	stamBgCorner.Parent = staminaBg

	-- Stamina fill bar
	local staminaFill = Instance.new("Frame")
	staminaFill.Name = "StaminaFill"
	staminaFill.Size = UDim2.new(1.0, 0, 1.0, 0)
	staminaFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	staminaFill.BorderSizePixel = 0
	staminaFill.Parent = staminaBg

	local stamFillCorner = Instance.new("UICorner")
	stamFillCorner.CornerRadius = UDim.new(0, 4)
	stamFillCorner.Parent = staminaFill

	-- Controls guide text
	local controlsLabel = Instance.new("TextLabel")
	controlsLabel.Name = "ControlsLabel"
	controlsLabel.Size = UDim2.new(1, -24, 0, 24)
	controlsLabel.Position = UDim2.new(0, 12, 0, 64)
	controlsLabel.BackgroundTransparency = 1
	controlsLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	controlsLabel.Font = Enum.Font.Gotham
	controlsLabel.TextSize = 10
	controlsLabel.Text = "[Shift] Sprint  [Q] Dash  [Space] Jump  [Z/X/C] Skills  [LMB] Shoot/Slide  [RMB] Curve/Volley/Poke  [E] Pass/Fake Shot  [MMB] Cage Press  [Alt] Shift Lock  [R] Reset  [H] Codex"
	controlsLabel.Parent = container

	-- 2. Shift Lock Center Reticle
	local shiftLockReticle = Instance.new("Frame")
	shiftLockReticle.Name = "ShiftLockReticle"
	shiftLockReticle.Size = UDim2.fromOffset(6, 6)
	shiftLockReticle.Position = UDim2.new(0.5, -3, 0.5, -3)
	shiftLockReticle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shiftLockReticle.BackgroundTransparency = 0.2
	shiftLockReticle.BorderSizePixel = 0
	shiftLockReticle.Visible = true
	shiftLockReticle.Parent = screenGui

	local reticleCorner = Instance.new("UICorner")
	reticleCorner.CornerRadius = UDim.new(1, 0)
	reticleCorner.Parent = shiftLockReticle

	-- 3. Vertical Tapered Kick Charge Gauge (KickChargeGaugeBg)
	local chargeGaugeBg = Instance.new("Frame")
	chargeGaugeBg.Name = "KickChargeGaugeBg"
	chargeGaugeBg.Size = UDim2.fromOffset(76, 114)
	chargeGaugeBg.Position = UDim2.new(0.5, -38, 0.5, 42)
	chargeGaugeBg.BackgroundTransparency = 1
	chargeGaugeBg.BorderSizePixel = 0
	chargeGaugeBg.Visible = false
	chargeGaugeBg.Parent = screenGui

	local chargeGaugeLabel = Instance.new("TextLabel")
	chargeGaugeLabel.Name = "Label"
	chargeGaugeLabel.Size = UDim2.fromOffset(92, 18)
	chargeGaugeLabel.Position = UDim2.new(0.5, -46, 0, -22)
	chargeGaugeLabel.BackgroundTransparency = 1
	chargeGaugeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	chargeGaugeLabel.Font = Enum.Font.GothamBlack
	chargeGaugeLabel.TextSize = 11
	chargeGaugeLabel.Text = "20% TAP"
	chargeGaugeLabel.Parent = chargeGaugeBg

	local segmentWidths = { 16, 20, 24, 28, 32, 36, 40, 44, 49, 56 }
	local segmentColors = {
		Color3.fromRGB(56, 189, 248), -- 1 (Bottom, narrow 16px)
		Color3.fromRGB(56, 189, 248), -- 2
		Color3.fromRGB(34, 211, 238), -- 3
		Color3.fromRGB(45, 212, 191), -- 4
		Color3.fromRGB(52, 211, 153), -- 5
		Color3.fromRGB(163, 230, 53), -- 6
		Color3.fromRGB(250, 204, 21), -- 7
		Color3.fromRGB(251, 146, 60), -- 8
		Color3.fromRGB(249, 115, 22), -- 9
		Color3.fromRGB(239, 68, 68),  -- 10 (Top, flared wide 56px MAX)
	}

	for i = 1, 10 do
		local w = segmentWidths[i]
		local h = if i == 10 then 7 else 6
		local yPos = 94 - (i - 1) * 10

		local segBg = Instance.new("Frame")
		segBg.Name = string.format("Seg_%02d", i)
		segBg.Size = UDim2.fromOffset(w, h)
		segBg.Position = UDim2.new(0.5, -w * 0.5, 0, yPos)
		segBg.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		segBg.BackgroundTransparency = 0.4
		segBg.BorderSizePixel = 0
		segBg.Parent = chargeGaugeBg

		local segCorner = Instance.new("UICorner")
		segCorner.CornerRadius = UDim.new(0, 3)
		segCorner.Parent = segBg

		local segStroke = Instance.new("UIStroke")
		segStroke.Color = Color3.fromRGB(45, 60, 80)
		segStroke.Thickness = 1
		segStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		segStroke.Parent = segBg

		local segFill = Instance.new("Frame")
		segFill.Name = "Fill"
		segFill.Size = UDim2.new(1, 0, 1, 0)
		segFill.BackgroundColor3 = segmentColors[i]
		segFill.BackgroundTransparency = 1
		segFill.BorderSizePixel = 0
		segFill.Parent = segBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 3)
		fillCorner.Parent = segFill
	end

	-- 4. Controls Codex Modal Dialog (ค่าปกติซ่อนไว้ก่อน)
	local codexModal = Instance.new("Frame")
	codexModal.Name = "ControlsCodexModal"
	codexModal.Size = UDim2.fromOffset(640, 440)
	codexModal.Position = UDim2.new(0.5, -320, 0.5, -220)
	codexModal.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	codexModal.BackgroundTransparency = 0.05
	codexModal.BorderSizePixel = 0
	codexModal.Visible = false -- ซ่อนเป็นค่าเริ่มต้น
	codexModal.ZIndex = 30
	codexModal.Parent = screenGui

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 10)
	modalCorner.Parent = codexModal

	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(56, 189, 248)
	modalStroke.Thickness = 2
	modalStroke.Parent = codexModal

	-- Modal Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 42)
	header.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	header.BorderSizePixel = 0
	header.ZIndex = 31
	header.Parent = codexModal

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(56, 189, 248)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "📖 CAGE-ZERO: CODEX คู่มือปุ่มควบคุม (CONTROLS GUIDE)"
	title.ZIndex = 32
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Position = UDim2.new(1, -34, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.Text = "✕"
	closeBtn.ZIndex = 32
	closeBtn.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	-- Column 1: Movement & Defense
	local col1 = Instance.new("Frame")
	col1.Name = "ColMovementDefense"
	col1.Size = UDim2.new(0.5, -18, 0, 345)
	col1.Position = UDim2.new(0, 12, 0, 50)
	col1.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	col1.BackgroundTransparency = 0.5
	col1.BorderSizePixel = 0
	col1.ZIndex = 31
	col1.Parent = codexModal

	local c1Corner = Instance.new("UICorner")
	c1Corner.CornerRadius = UDim.new(0, 8)
	c1Corner.Parent = col1

	local c1Title = Instance.new("TextLabel")
	c1Title.Name = "Title"
	c1Title.Size = UDim2.new(1, -16, 0, 22)
	c1Title.Position = UDim2.new(0, 8, 0, 6)
	c1Title.BackgroundTransparency = 1
	c1Title.TextColor3 = Color3.fromRGB(34, 197, 94)
	c1Title.Font = Enum.Font.GothamBold
	c1Title.TextSize = 12
	c1Title.TextXAlignment = Enum.TextXAlignment.Left
	c1Title.Text = "🏃 การเคลื่อนที่ & ฝ่ายรับ (Movement)"
	c1Title.ZIndex = 32
	c1Title.Parent = col1

	local c1Items = {
		{ key = "W, A, S, D", desc = "เดินเคลื่อนที่พื้น (Walk 20) / เอนตัวกลางอากาศ (Air Lean)" },
		{ key = "Left Shift / Q", desc = "วิ่งสปรินต์ (Sprint 32) / แดชพุ่งตัว (Dash Burst)" },
		{ key = "Space", desc = "งัดบอลขึ้น (BallPop เมื่อครองบอล) / กระโดด (Directional Jump)" },
		{ key = "LMB [ฝ่ายรับ]", desc = "สไลด์สกัดบอล [ฝ่ายรับ] (Slide Tackle ระยะ 8.5m)" },
		{ key = "RMB [ฝ่ายรับ]", desc = "จิ้มสกัดเร็ว [ฝ่ายรับ] (Quick Poke ระยะ 4.5m, CD 1.0s)" },
		{ key = "MMB [ฝ่ายรับ]", desc = "Cage Press: ปะทะไหล่พุ่งหน้า; กลางสนามคู่แข่งยังครองบอล, ชนกรงจริงจึง Wall Splat" },
	}
	for i, item in ipairs(c1Items) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, -16, 0, 38)
		row.Position = UDim2.new(0, 8, 0, 32 + (i - 1) * 44)
		row.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.ZIndex = 32
		row.Parent = col1

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local keyBadge = Instance.new("TextLabel")
		keyBadge.Size = UDim2.new(0, 88, 0, 22)
		keyBadge.Position = UDim2.new(0, 6, 0, 8)
		keyBadge.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
		keyBadge.BackgroundTransparency = 0.8
		keyBadge.TextColor3 = Color3.fromRGB(56, 189, 248)
		keyBadge.Font = Enum.Font.GothamBold
		keyBadge.TextSize = 10
		keyBadge.Text = item.key
		keyBadge.ZIndex = 33
		keyBadge.Parent = row

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = keyBadge

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -100, 1, 0)
		descLabel.Position = UDim2.new(0, 98, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Text = item.desc
		descLabel.ZIndex = 33
		descLabel.Parent = row
	end

	-- Column 2: Offense & Utility
	local col2 = Instance.new("Frame")
	col2.Name = "ColOffenseUtility"
	col2.Size = UDim2.new(0.5, -18, 0, 345)
	col2.Position = UDim2.new(0.5, 6, 0, 50)
	col2.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	col2.BackgroundTransparency = 0.5
	col2.BorderSizePixel = 0
	col2.ZIndex = 31
	col2.Parent = codexModal

	local c2Corner = Instance.new("UICorner")
	c2Corner.CornerRadius = UDim.new(0, 8)
	c2Corner.Parent = col2

	local c2Title = Instance.new("TextLabel")
	c2Title.Name = "Title"
	c2Title.Size = UDim2.new(1, -16, 0, 22)
	c2Title.Position = UDim2.new(0, 8, 0, 6)
	c2Title.BackgroundTransparency = 1
	c2Title.TextColor3 = Color3.fromRGB(249, 115, 22)
	c2Title.Font = Enum.Font.GothamBold
	c2Title.TextSize = 12
	c2Title.TextXAlignment = Enum.TextXAlignment.Left
	c2Title.Text = "⚽ ฝ่ายรุก & ระบบเกม (Attacking & Utility)"
	c2Title.ZIndex = 32
	c2Title.Parent = col2

	local c2Items = {
		{ key = "LMB [ฝ่ายรุก]", desc = "ยิงตรงพื้น/กลางอากาศ (Direct Shoot, กดค้างชาร์จ)" },
		{ key = "RMB [พื้น]", desc = "ปั่นไซด์โค้งเท้าขวา (A=Finesse แปใน / D=Trivela ก้อยนอก)" },
		{ key = "RMB [อากาศ]", desc = "วอลเล่ย์กลางอากาศ (Volley, กดค้างชาร์จ)" },
		{ key = "E [ฝ่ายรุก]", desc = "ส่งบอล 3D (Pass, แท็ปเบา / ค้างแรง); กด E ระหว่างง้างยิงเพื่อ Fake Shot" },
		{ key = "Z, X, C [ฝ่ายรุก]", desc = "Z=แตะบอลไปข้างหน้า (ไม่ตาม), X=กระชากบอล (พุ่งตามบอล), C=Sombrero" },
		{ key = "R / H / Alt", desc = "รีเซ็ตบอล [R] / เปิดคู่มือ [H] / Shift Lock [Left Alt]" },
	}
	for i, item in ipairs(c2Items) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, -16, 0, 38)
		row.Position = UDim2.new(0, 8, 0, 32 + (i - 1) * 44)
		row.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.ZIndex = 32
		row.Parent = col2

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local keyBadge = Instance.new("TextLabel")
		keyBadge.Size = UDim2.new(0, 92, 0, 22)
		keyBadge.Position = UDim2.new(0, 6, 0, 8)
		keyBadge.BackgroundColor3 = Color3.fromRGB(249, 115, 22)
		keyBadge.BackgroundTransparency = 0.8
		keyBadge.TextColor3 = Color3.fromRGB(249, 115, 22)
		keyBadge.Font = Enum.Font.GothamBold
		keyBadge.TextSize = 10
		keyBadge.Text = item.key
		keyBadge.ZIndex = 33
		keyBadge.Parent = row

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = keyBadge

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -104, 1, 0)
		descLabel.Position = UDim2.new(0, 102, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Text = item.desc
		descLabel.ZIndex = 33
		descLabel.Parent = row
	end

	-- Footer tip
	local footerLabel = Instance.new("TextLabel")
	footerLabel.Name = "FooterTip"
	footerLabel.Size = UDim2.new(1, -24, 0, 24)
	footerLabel.Position = UDim2.new(0, 12, 0, 405)
	footerLabel.BackgroundTransparency = 1
	footerLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	footerLabel.Font = Enum.Font.Gotham
	footerLabel.TextSize = 11
	footerLabel.Text = "💡 กดปุ่ม [H] หรือคลิก [✕] เพื่อปิดหน้าต่างคู่มือนี้  •  กด [L] เพื่อเล็งเป้า Shift Lock ได้แม่นยำขึ้น"
	footerLabel.ZIndex = 32
	footerLabel.Parent = codexModal

	-- Button Click Events
	codexToggleBtn.MouseButton1Click:Connect(function()
		codexModal.Visible = not codexModal.Visible
	end)

	closeBtn.MouseButton1Click:Connect(function()
		codexModal.Visible = false
	end)

	activeCodexModal = codexModal

	return screenGui
end

function TrainingHUD.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui", 10) :: PlayerGui?
	if not playerGui then
		return
	end

	local screenGui = TrainingHUD.CreateScreenGui(playerGui)
	local container = screenGui:WaitForChild("HUDContainer")
	local contextBadge = container:WaitForChild("ContextBadge") :: TextLabel
	local ballLabel = container:WaitForChild("BallStatusLabel") :: TextLabel
	local staminaBg = container:WaitForChild("StaminaBg")
	local staminaFill = staminaBg:WaitForChild("StaminaFill") :: Frame
	local shiftLockReticle = screenGui:WaitForChild("ShiftLockReticle") :: Frame
	local chargeGaugeBg = screenGui:WaitForChild("KickChargeGaugeBg") :: Frame
	local chargeGaugeLabel = chargeGaugeBg:WaitForChild("Label") :: TextLabel

	type ChargeSegment = {
		bg: Frame,
		fill: Frame,
		stroke: UIStroke,
		activeColor: Color3,
	}
	local chargeSegments: { ChargeSegment } = {}
	local segmentColors = {
		Color3.fromRGB(56, 189, 248),
		Color3.fromRGB(56, 189, 248),
		Color3.fromRGB(34, 211, 238),
		Color3.fromRGB(45, 212, 191),
		Color3.fromRGB(52, 211, 153),
		Color3.fromRGB(163, 230, 53),
		Color3.fromRGB(250, 204, 21),
		Color3.fromRGB(251, 146, 60),
		Color3.fromRGB(249, 115, 22),
		Color3.fromRGB(239, 68, 68),
	}

	for i = 1, 10 do
		local segBg = chargeGaugeBg:FindFirstChild(string.format("Seg_%02d", i)) :: Frame?
		if segBg then
			local fill = segBg:FindFirstChild("Fill") :: Frame?
			local stroke = segBg:FindFirstChildOfClass("UIStroke")
			if fill and stroke then
				table.insert(chargeSegments, {
					bg = segBg,
					fill = fill,
					stroke = stroke,
					activeColor = segmentColors[i],
				})
			end
		end
	end

	-- Keybinding: H to toggle Codex
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end
		if input.KeyCode == Enum.KeyCode.H then
			TrainingHUD.ToggleCodex()
		end
	end)

	-- Connect live update loop
	RunService.RenderStepped:Connect(function()
		local char = localPlayer and localPlayer.Character
		if char then
			-- Update Stamina
			local stam = (char:GetAttribute("Stamina") :: number?) or 1.0
			stam = math.clamp(stam, 0.0, 1.0)
			staminaFill.Size = UDim2.new(stam, 0, 1.0, 0)
			if stam < 0.20 then
				staminaFill.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
			elseif stam < 0.50 then
				staminaFill.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
			else
				staminaFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
			end

			-- Update Action Context & Charging
			local isCharging = char:GetAttribute("IsCharging") == true
			local chargePower = (char:GetAttribute("ChargePower") :: number?) or 0.20
			local chargeAction = (char:GetAttribute("ChargeAction") :: string?) or "DirectShoot"
			local ctx = char:GetAttribute("ActionContext") or "Attacking"

			if isCharging then
				contextBadge.Text = "CHARGING..."
				contextBadge.BackgroundColor3 = Color3.fromRGB(249, 115, 22)

				chargeGaugeBg.Visible = true
				local litCount = math.clamp(math.floor(chargePower * 10 + 0.05), 1, 10)
				local isMax = chargePower >= 0.98
				for idx, seg in ipairs(chargeSegments) do
					if idx <= litCount then
						seg.fill.BackgroundTransparency = 0
						seg.fill.BackgroundColor3 = seg.activeColor
						seg.stroke.Color = seg.activeColor
						seg.stroke.Thickness = if idx == 10 and isMax then 2 else 1
					else
						seg.fill.BackgroundTransparency = 1
						seg.stroke.Color = Color3.fromRGB(45, 60, 80)
						seg.stroke.Thickness = 1
					end
				end

				if chargeGaugeLabel then
					local actionThai = if chargeAction == "Pass" or chargeAction == "GroundPass" then "ส่งบอล"
						elseif chargeAction == "DirectShoot" or chargeAction == "ShootStraight" then "ยิงตรง"
						elseif chargeAction == "CurveShoot" or chargeAction == "ShootCurve" then "ปั่นโค้ง"
						elseif chargeAction == "Slide" or chargeAction == "SlideTackle" then "สไลด์"
						else "พลังยิง"
					if isMax then
						chargeGaugeLabel.Text = string.format("🔥 %s MAX!", actionThai)
						chargeGaugeLabel.TextColor3 = Color3.fromRGB(249, 115, 22)
					elseif chargePower >= 0.75 then
						chargeGaugeLabel.Text = string.format("%s %d%%", actionThai, math.floor(chargePower * 100))
						chargeGaugeLabel.TextColor3 = Color3.fromRGB(251, 146, 60)
					elseif chargePower >= 0.50 then
						chargeGaugeLabel.Text = string.format("%s %d%%", actionThai, math.floor(chargePower * 100))
						chargeGaugeLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
					else
						chargeGaugeLabel.Text = string.format("%s %d%%", actionThai, math.floor(chargePower * 100))
						chargeGaugeLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
					end
				end
			else
				chargeGaugeBg.Visible = false
				if ctx == "Attacking" then
					contextBadge.Text = "ATTACKING"
					contextBadge.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				else
					contextBadge.Text = "DEFENDING"
					contextBadge.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				end
			end
		end

		-- Update Ball Info
		local ball = Workspace:FindFirstChild("CageMatchBall")
		if ball then
			local bState = ball:GetAttribute("BallState") or "Free"
			local holder = ball:GetAttribute("PossessorUserId") or 0
			if bState == "Possessed" then
				local isMe = localPlayer and (holder == localPlayer.UserId)
				ballLabel.Text = if isMe then "Ball: Possessed (You)" else string.format("Ball: Possessed (ID: %d)", holder)
			else
				ballLabel.Text = string.format("Ball: %s", tostring(bState))
			end
		end

		local camCtrl = script.Parent:FindFirstChild("CameraShiftLockController")
		if camCtrl and camCtrl:IsA("ModuleScript") then
			local ok, ShiftLock = pcall(require, camCtrl)
			if ok and ShiftLock and type(ShiftLock.IsEnabled) == "function" then
				shiftLockReticle.Visible = ShiftLock.IsEnabled()
			end
		end
	end)

	return screenGui
end

return table.freeze(TrainingHUD)
