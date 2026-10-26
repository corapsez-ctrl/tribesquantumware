-- QuantumWare for Tribes 3v3.
-- After it runs, Right Shift opens and closes the menu.
local SOURCE_URL = "https://raw.githubusercontent.com/corapsez-ctrl/tribesquantumware/main/quantumware.luau"

if typeof(getgenv) == "function" and type(getgenv().QuantumWareUnload) == "function" then
	pcall(getgenv().QuantumWareUnload)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local PURPLE = Color3.fromRGB(176, 80, 255)
local PURPLE_DIM = Color3.fromRGB(92, 40, 150)
local BLACK = Color3.fromRGB(0, 0, 0)
local ROW = Color3.fromRGB(14, 14, 16)
local MUTED = Color3.fromRGB(168, 168, 176)
local ENEMY_COLOR = Color3.fromRGB(255, 55, 55)
local ALLY_COLOR = Color3.fromRGB(70, 150, 255)

local LOBBY_TEAMS = {
	lobby = true,
	waiting = true,
	spectator = true,
	spectators = true,
	spectating = true,
	menu = true,
	intermission = true,
}

local PAGES = { "Blatant", "Rage", "Closet", "Visuals", "Settings" }

local modules = {
	aimbot = {
		page = "Blatant",
		name = "Aimbot",
		desc = "Puts the crosshair on an enemy and leads the shot",
		key = Enum.KeyCode.Q,
		enabled = false,
		fov = 280,
		min = 40,
		max = 700,
		step = 20,
	},
	speed = {
		page = "Blatant",
		name = "Speed",
		desc = "Pushes you faster. This game ignores normal walk speed",
		key = Enum.KeyCode.C,
		enabled = false,
		value = 46,
		min = 20,
		max = 120,
		step = 2,
	},
	jump = {
		page = "Blatant",
		name = "High Jump",
		desc = "Boosts the jump itself, not just the default jump stat",
		key = Enum.KeyCode.Z,
		enabled = false,
		value = 95,
		min = 60,
		max = 180,
		step = 5,
	},
	killaura = {
		page = "Blatant",
		name = "Killaura",
		desc = "Swings your sword at enemies in range, through walls",
		key = Enum.KeyCode.X,
		enabled = false,
		value = 36,
		min = 12,
		max = 80,
		step = 2,
	},
	silent = {
		page = "Blatant",
		name = "Silent Aim",
		desc = "Redirects shots at an enemy in view without moving the camera",
		key = Enum.KeyCode.R,
		enabled = false,
		fov = 220,
		min = 40,
		max = 600,
		step = 20,
	},
	fly = {
		page = "Blatant",
		name = "Fly",
		desc = "Fly with WASD, Space, and Ctrl",
		key = Enum.KeyCode.F,
		enabled = false,
		value = 60,
		min = 20,
		max = 160,
		step = 5,
	},
	smooth = {
		page = "Closet",
		name = "Smooth Aim",
		desc = "Eases the crosshair onto an enemy while held",
		key = Enum.KeyCode.E,
		hold = true,
		enabled = false,
		fov = 90,
		min = 30,
		max = 320,
		step = 10,
	},
	esp = {
		page = "Visuals",
		name = "ESP",
		desc = "Enemies in red with health, allies in blue",
		key = Enum.KeyCode.T,
		enabled = false,
	},
	allyEsp = {
		page = "Visuals",
		name = "Ally ESP",
		desc = "Also mark your two teammates",
		key = Enum.KeyCode.G,
		enabled = true,
	},
	tracers = {
		page = "Visuals",
		name = "Tracers",
		desc = "Draw a line to each living enemy",
		key = Enum.KeyCode.Y,
		enabled = false,
	},
	watermark = {
		page = "Visuals",
		name = "Watermark",
		desc = "Keep the purple QuantumWare mark on screen",
		key = Enum.KeyCode.H,
		enabled = true,
	},
	rage = {
		page = "Rage",
		name = "Underkill",
		desc = "Teleports under an enemy and swings your sword",
		key = Enum.KeyCode.V,
		enabled = false,
	},
}

local pageOrder = {
	Blatant = { "aimbot", "silent", "killaura", "fly", "speed", "jump" },
	Rage = { "rage" },
	Closet = { "smooth" },
	Visuals = { "esp", "allyEsp", "tracers", "watermark" },
}

local state = {
	page = "Blatant",
	menuOpen = false,
	menuKey = Enum.KeyCode.RightShift,
	binding = nil,
	holding = {},
	savedSpeed = nil,
	savedJumpPower = nil,
	savedJumpHeight = nil,
	savedCameraType = nil,
	cameraDistance = nil,
	jumpUntil = 0,
	nextSwing = 0,
	autoload = true,
	sourceUrl = "",
	silentTarget = nil,
	internalRay = false,
	wasFlying = false,
}

local visuals = {}
local characters = {}
local tracerFrames = {}
local ARROW_SPEED = 200
local knownSide = {}
local classifiedAt = 0
local connections = {}
local dragging = false
local dragStart
local dragOrigin

local function readableTeam(value)
	if value == nil then
		return nil
	end
	local text = string.lower(tostring(value))
	if text == "" or LOBBY_TEAMS[text] then
		return nil
	end
	return text
end

local function teamToken(player)
	if player.Team ~= nil and not player.Neutral then
		local name = readableTeam(player.Team.Name)
		if name then
			return name
		end
	end

	local sources = { player, player.Character, characters[player] }
	for _, inst in sources do
		if inst == nil then
			continue
		end
		for attr, value in inst:GetAttributes() do
			local key = string.lower(attr)
			if string.find(key, "team", 1, true) or key == "side" or key == "squad" or key == "tribe" then
				local token = readableTeam(value)
				if token then
					return token
				end
			end
		end
		for _, child in inst:GetChildren() do
			if child:IsA("ValueBase") then
				local key = string.lower(child.Name)
				if string.find(key, "team", 1, true) or key == "side" or key == "squad" then
					local token = readableTeam(child.Value)
					if token then
						return token
					end
				end
			end
		end
	end
	if player.TeamColor ~= nil then
		local colorName = string.lower(player.TeamColor.Name)
		if colorName ~= "medium stone grey" and colorName ~= "white" then
			return colorName
		end
	end
	return nil
end

local function tagBucket(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	for _, child in character:GetChildren() do
		if not child:IsA("BillboardGui") or child.Name == "QuantumESPName" then
			continue
		end
		for _, label in child:GetDescendants() do
			if label:IsA("TextLabel") then
				local color = label.TextColor3
				if color.B > color.R + 0.15 then
					return "blue"
				end
				if color.R > color.B + 0.15 then
					return "red"
				end
			end
		end
	end
	return nil
end

local function playerFromGui(object)
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		local text = object.Text
		for _, player in Players:GetPlayers() do
			if text == player.Name or text == player.DisplayName or text == "@" .. player.Name then
				return player
			end
		end
	elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
		local image = object.Image
		local userId = string.match(image, "id=(%d+)")
		if userId ~= nil then
			for _, player in Players:GetPlayers() do
				if tostring(player.UserId) == userId then
					return player
				end
			end
		end
	end
	return nil
end

local characterOf
local aimPartOf

local function refreshClassification()
	if os.clock() - classifiedAt < 0.35 then
		return
	end
	classifiedAt = os.clock()
	table.clear(knownSide)

	local tokens = {}
	for _, player in Players:GetPlayers() do
		tokens[player] = teamToken(player) or tagBucket(player)
	end
	local mine = tokens[localPlayer]
	local foundAlly = false
	local confident = mine ~= nil
	if mine ~= nil then
		for _, player in Players:GetPlayers() do
			if player ~= localPlayer and tokens[player] ~= nil then
				local side = if tokens[player] == mine then "ally" else "enemy"
				knownSide[player] = side
				foundAlly = foundAlly or side == "ally"
			end
		end
	end

	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	local camera = workspace.CurrentCamera
	if playerGui ~= nil and camera ~= nil then
		local hits = {}
		for _, object in playerGui:GetDescendants() do
			local screen = object:FindFirstAncestorOfClass("ScreenGui")
			if (screen ~= nil and screen.Name == "QuantumWare") or not object:IsA("GuiObject") or not object.Visible then
				continue
			end
			local player = playerFromGui(object)
			if player == nil then
				continue
			end
			local center = object.AbsolutePosition + object.AbsoluteSize / 2
			if center.Y > camera.ViewportSize.Y * 0.28 then
				continue
			end
			if center.X < camera.ViewportSize.X * 0.2 or center.X > camera.ViewportSize.X * 0.8 then
				continue
			end
			local previous = hits[player]
			if previous == nil or center.Y < previous.Y then
				hits[player] = center
			end
		end

		local mineHit = hits[localPlayer]
		local minX, maxX = math.huge, -math.huge
		local count = 0
		for _, center in hits do
			count += 1
			minX = math.min(minX, center.X)
			maxX = math.max(maxX, center.X)
		end
		if mineHit ~= nil and count >= 2 and maxX - minX > 40 then
			local mid = (minX + maxX) / 2
			local mineOnLeft = mineHit.X <= mid
			confident = true
			for player, center in hits do
				if player ~= localPlayer then
					local sameSide = (center.X <= mid) == mineOnLeft
					knownSide[player] = if sameSide then "ally" else "enemy"
					foundAlly = foundAlly or sameSide
				end
			end
		end
	end

	if confident and foundAlly then
		for _, player in Players:GetPlayers() do
			if player ~= localPlayer and knownSide[player] == nil then
				knownSide[player] = "enemy"
			end
		end
	end
end

local function sideOf(player)
	if player == localPlayer or player.Parent == nil then
		return nil
	end
	refreshClassification()
	return knownSide[player]
end

function characterOf(player)
	if player.Character ~= nil and player.Character.Parent ~= nil then
		return player.Character
	end
	local cached = characters[player]
	if cached ~= nil and cached.Parent ~= nil then
		return cached
	end
	return nil
end

function aimPartOf(character)
	if character == nil then
		return nil
	end
	return character:FindFirstChild("Head")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function guiParent()
	if typeof(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and typeof(result) == "Instance" then
			return result
		end
	end
	return localPlayer:WaitForChild("PlayerGui")
end

local parent = guiParent()
local existing = parent:FindFirstChild("QuantumWare")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "QuantumWare"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local watermark = Instance.new("TextLabel")
watermark.Name = "Watermark"
watermark.BackgroundTransparency = 1
watermark.Position = UDim2.fromOffset(16, 12)
watermark.Size = UDim2.fromOffset(280, 24)
watermark.Font = Enum.Font.GothamBold
watermark.TextSize = 18
watermark.TextXAlignment = Enum.TextXAlignment.Left
watermark.TextColor3 = PURPLE
watermark.Text = "QuantumWare"
watermark.Parent = gui

local popups = Instance.new("Frame")
popups.Name = "Popups"
popups.AnchorPoint = Vector2.new(1, 1)
popups.BackgroundTransparency = 1
popups.Position = UDim2.new(1, -16, 1, -16)
popups.Size = UDim2.fromOffset(220, 280)
popups.Parent = gui
local popupLayout = Instance.new("UIListLayout")
popupLayout.Padding = UDim.new(0, 6)
popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
popupLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
popupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
popupLayout.Parent = popups

local function notify(module)
	local row = Instance.new("TextLabel")
	row.BackgroundColor3 = BLACK
	row.BackgroundTransparency = 0.15
	row.Size = UDim2.fromOffset(180, 26)
	row.Font = Enum.Font.GothamBold
	row.TextSize = 13
	row.TextColor3 = PURPLE
	row.Text = module.name .. (if module.enabled then "  on" else "  off")
	row.Parent = popups
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row
	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = PURPLE
	rowStroke.Transparency = 0.4
	rowStroke.Parent = row
	task.delay(2, function()
		if row.Parent ~= nil then
			row:Destroy()
		end
	end)
end

local fovCircle = Instance.new("Frame")
fovCircle.Name = "Fov"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = gui
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = PURPLE
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.25
fovStroke.Parent = fovCircle

local tracerFolder = Instance.new("Folder")
tracerFolder.Name = "Tracers"
tracerFolder.Parent = gui

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP"
espFolder.Parent = gui

local holder = Instance.new("Frame")
holder.Name = "Menu"
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.fromOffset(660, 420)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.fromScale(1, 1)
shadow.Position = UDim2.fromOffset(0, 12)
shadow.BackgroundColor3 = BLACK
shadow.BackgroundTransparency = 0.45
shadow.BorderSizePixel = 0
shadow.Parent = holder
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 28)
shadowCorner.Parent = shadow

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(1, 1)
panel.BackgroundColor3 = BLACK
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = holder
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 26)
panelCorner.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = PURPLE
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.4
panelStroke.Parent = panel

local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Position = UDim2.fromOffset(20, 16)
brand.Size = UDim2.fromOffset(150, 26)
brand.Font = Enum.Font.GothamBold
brand.TextSize = 18
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.TextColor3 = PURPLE
brand.Text = "QuantumWare"
brand.ZIndex = 3
brand.Parent = panel

local bindHint = Instance.new("TextLabel")
bindHint.BackgroundTransparency = 1
bindHint.Position = UDim2.fromOffset(176, 18)
bindHint.Size = UDim2.fromOffset(460, 22)
bindHint.Font = Enum.Font.GothamBold
bindHint.TextSize = 13
bindHint.TextXAlignment = Enum.TextXAlignment.Left
bindHint.TextColor3 = PURPLE
bindHint.Text = "Click a key chip, then press a new key"
bindHint.ZIndex = 3
bindHint.Parent = panel

local pageColumn = Instance.new("Frame")
pageColumn.BackgroundTransparency = 1
pageColumn.Position = UDim2.fromOffset(16, 58)
pageColumn.Size = UDim2.fromOffset(148, 340)
pageColumn.Parent = panel
local pageLayout = Instance.new("UIListLayout")
pageLayout.Padding = UDim.new(0, 6)
pageLayout.Parent = pageColumn

local content = Instance.new("Frame")
content.Name = "Pages"
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(176, 54)
content.Size = UDim2.fromOffset(464, 348)
content.Parent = panel
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = content

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
	return item
end

local function label(parent, text, size, color, fontSize, xAlign)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Size = size
	item.Font = Enum.Font.GothamBold
	item.TextSize = fontSize
	item.TextColor3 = color
	item.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	item.Text = text
	item.Parent = parent
	return item
end

local saveSettings

local function renderPage()
	watermark.Visible = modules.watermark.enabled
	if state.binding == "menu" then
		bindHint.Text = "Press a key for the menu"
	elseif typeof(state.binding) == "table" then
		bindHint.Text = "Press a key for " .. state.binding.name
	else
		bindHint.Text = "Click a key chip, then press a new key"
	end

	for _, child in pageColumn:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	for _, pageName in PAGES do
		local selected = pageName == state.page
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 36)
		button.BackgroundColor3 = if selected then PURPLE_DIM else ROW
		button.BackgroundTransparency = if selected then 0.35 else 0.2
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextColor3 = if selected then PURPLE else MUTED
		button.Text = pageName
		button.Parent = pageColumn
		corner(button, 10)
		button.MouseButton1Click:Connect(function()
			state.page = pageName
			state.binding = nil
			renderPage()
		end)
	end

	if state.page == "Settings" then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 64)
		row.BackgroundColor3 = ROW
		row.BorderSizePixel = 0
		row.Parent = content
		corner(row, 12)
		label(row, "Menu key", UDim2.fromOffset(220, 28), Color3.new(1, 1, 1), 15).Position = UDim2.fromOffset(14, 8)
		label(row, "Opens and closes this panel", UDim2.fromOffset(240, 18), MUTED, 12).Position = UDim2.fromOffset(14, 34)

		local keyButton = Instance.new("TextButton")
		keyButton.AnchorPoint = Vector2.new(1, 0.5)
		keyButton.Position = UDim2.new(1, -14, 0.5, 0)
		keyButton.Size = UDim2.fromOffset(110, 28)
		keyButton.BackgroundColor3 = BLACK
		keyButton.BorderSizePixel = 0
		keyButton.AutoButtonColor = false
		keyButton.Font = Enum.Font.GothamBold
		keyButton.TextSize = 12
		keyButton.TextColor3 = PURPLE
		keyButton.Text = if state.binding == "menu" then "..." else state.menuKey.Name
		keyButton.Parent = row
		corner(keyButton, 8)
		local keyStroke = Instance.new("UIStroke")
		keyStroke.Color = PURPLE
		keyStroke.Transparency = 0.4
		keyStroke.Parent = keyButton
		keyButton.MouseButton1Click:Connect(function()
			state.binding = "menu"
			renderPage()
		end)

		local autoRow = Instance.new("Frame")
		autoRow.Size = UDim2.new(1, 0, 0, 64)
		autoRow.BackgroundColor3 = ROW
		autoRow.BorderSizePixel = 0
		autoRow.Parent = content
		corner(autoRow, 12)
		label(autoRow, "Autoload", UDim2.fromOffset(220, 28), Color3.new(1, 1, 1), 15).Position = UDim2.fromOffset(14, 8)
		label(autoRow, "Run QuantumWare again the next time you join", UDim2.fromOffset(280, 18), MUTED, 12).Position = UDim2.fromOffset(14, 34)

		local autoToggle = Instance.new("TextButton")
		autoToggle.AnchorPoint = Vector2.new(1, 0.5)
		autoToggle.Position = UDim2.new(1, -14, 0.5, 0)
		autoToggle.Size = UDim2.fromOffset(44, 24)
		autoToggle.BackgroundColor3 = if state.autoload then PURPLE else Color3.fromRGB(40, 40, 46)
		autoToggle.BorderSizePixel = 0
		autoToggle.AutoButtonColor = false
		autoToggle.Text = ""
		autoToggle.Parent = autoRow
		corner(autoToggle, 12)
		local autoKnob = Instance.new("Frame")
		autoKnob.Size = UDim2.fromOffset(16, 16)
		autoKnob.Position = if state.autoload then UDim2.fromOffset(24, 4) else UDim2.fromOffset(4, 4)
		autoKnob.BackgroundColor3 = Color3.new(1, 1, 1)
		autoKnob.BorderSizePixel = 0
		autoKnob.Parent = autoToggle
		corner(autoKnob, 8)
		autoToggle.MouseButton1Click:Connect(function()
			state.autoload = not state.autoload
			saveSettings()
			renderPage()
		end)

		local unload = Instance.new("TextButton")
		unload.Size = UDim2.new(1, 0, 0, 40)
		unload.BackgroundColor3 = ROW
		unload.BorderSizePixel = 0
		unload.AutoButtonColor = false
		unload.Font = Enum.Font.GothamBold
		unload.TextSize = 14
		unload.TextColor3 = PURPLE
		unload.Text = "Unload QuantumWare"
		unload.Parent = content
		corner(unload, 12)
		unload.MouseButton1Click:Connect(function()
			if gui.Parent then
				gui:SetAttribute("Unload", true)
			end
		end)
		return
	end

	for _, id in pageOrder[state.page] do
		local module = modules[id]
		local hasAmount = module.fov ~= nil or module.value ~= nil
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, if hasAmount then 78 else 64)
		row.BackgroundColor3 = ROW
		row.BorderSizePixel = 0
		row.Parent = content
		corner(row, 12)

		label(row, module.name, UDim2.fromOffset(200, 24), Color3.new(1, 1, 1), 15).Position = UDim2.fromOffset(14, 8)
		label(row, module.desc, UDim2.fromOffset(250, 18), MUTED, 12).Position = UDim2.fromOffset(14, 32)

		local toggle = Instance.new("TextButton")
		toggle.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Position = UDim2.new(1, -14, 0.5, 0)
		toggle.Size = UDim2.fromOffset(44, 24)
		toggle.BackgroundColor3 = if module.enabled then PURPLE else Color3.fromRGB(40, 40, 46)
		toggle.BorderSizePixel = 0
		toggle.AutoButtonColor = false
		toggle.Text = ""
		toggle.Parent = row
		corner(toggle, 12)
		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(16, 16)
		knob.Position = if module.enabled then UDim2.fromOffset(24, 4) else UDim2.fromOffset(4, 4)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = toggle
		corner(knob, 8)
		toggle.MouseButton1Click:Connect(function()
			module.enabled = not module.enabled
			if module == modules.esp or module == modules.allyEsp then
				refreshEsp()
			end
			notify(module)
			saveSettings()
			renderPage()
		end)

		local keyButton = Instance.new("TextButton")
		keyButton.AnchorPoint = Vector2.new(1, 0.5)
		keyButton.Position = UDim2.new(1, -68, 0.5, 0)
		keyButton.Size = UDim2.fromOffset(78, 26)
		keyButton.BackgroundColor3 = BLACK
		keyButton.BorderSizePixel = 0
		keyButton.AutoButtonColor = false
		keyButton.Font = Enum.Font.GothamBold
		keyButton.TextSize = 12
		keyButton.TextColor3 = PURPLE
		keyButton.Text = if state.binding == module then "Press" else module.key.Name
		keyButton.Parent = row
		corner(keyButton, 8)
		local keyStroke = Instance.new("UIStroke")
		keyStroke.Color = PURPLE
		keyStroke.Transparency = 0.45
		keyStroke.Parent = keyButton
		keyButton.MouseButton1Click:Connect(function()
			state.binding = module
			renderPage()
		end)

		if hasAmount then
			local amount = module.fov or module.value
			local caption = if module.fov then "FOV" else "Value"

			local function bump(direction)
				local step = module.step or 10
				local minValue = module.min or 20
				local maxValue = module.max or 400
				local nextValue = math.clamp((module.fov or module.value) + step * direction, minValue, maxValue)
				if module.fov then
					module.fov = nextValue
				else
					module.value = nextValue
				end
				saveSettings()
				renderPage()
			end

			local function smallButton(text, x, direction)
				local button = Instance.new("TextButton")
				button.Position = UDim2.fromOffset(x, 52)
				button.Size = UDim2.fromOffset(18, 18)
				button.BackgroundColor3 = BLACK
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.Font = Enum.Font.GothamBold
				button.TextSize = 14
				button.TextColor3 = PURPLE
				button.Text = text
				button.Parent = row
				corner(button, 4)
				button.MouseButton1Click:Connect(function()
					bump(direction)
				end)
			end

			label(row, caption, UDim2.fromOffset(36, 18), MUTED, 12).Position = UDim2.fromOffset(14, 52)
			smallButton("-", 52, -1)
			local valueLabel = label(row, tostring(amount), UDim2.fromOffset(36, 18), PURPLE, 12, Enum.TextXAlignment.Center)
			valueLabel.Position = UDim2.fromOffset(72, 52)
			smallButton("+", 110, 1)
		end
	end
end

local function destroyVisual(player)
	local visual = visuals[player]
	if visual == nil then
		return
	end
	visual.highlight:Destroy()
	visual.billboard:Destroy()
	visuals[player] = nil
end

local function wantedSide(player)
	local side = sideOf(player)
	if side == "ally" and not modules.allyEsp.enabled then
		return nil
	end
	return side
end

local function attach(player, character)
	destroyVisual(player)
	if not modules.esp.enabled or wantedSide(player) == nil then
		return
	end

	local head = aimPartOf(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if head == nil or humanoid == nil or player.Parent == nil or character.Parent == nil then
		return
	end

	local side = wantedSide(player)
	if side == nil then
		return
	end
	local color = if side == "ally" then ALLY_COLOR else ENEMY_COLOR

	local highlight = Instance.new("Highlight")
	highlight.Name = "QuantumESP"
	highlight.Adornee = character
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.72
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = espFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QuantumESPName"
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 46)
	billboard.StudsOffset = Vector3.new(0, 3.1, 0)
	billboard.LightInfluence = 0
	billboard.Parent = espFolder

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Text = player.DisplayName
	nameLabel.Parent = billboard

	local healthLabel = Instance.new("TextLabel")
	healthLabel.BackgroundTransparency = 1
	healthLabel.Position = UDim2.fromOffset(0, 20)
	healthLabel.Size = UDim2.new(1, 0, 0, 20)
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextSize = 14
	healthLabel.TextColor3 = color
	healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthLabel.TextStrokeTransparency = 0.2
	healthLabel.Text = string.format("%d HP", math.floor(humanoid.Health + 0.5))
	healthLabel.Parent = billboard

	characters[player] = character
	visuals[player] = {
		highlight = highlight,
		billboard = billboard,
		label = nameLabel,
		healthLabel = healthLabel,
		humanoid = humanoid,
		character = character,
	}

	character.Destroying:Connect(function()
		if visuals[player] ~= nil and visuals[player].highlight == highlight then
			destroyVisual(player)
		end
	end)
end

local function refreshEsp()
	if not modules.esp.enabled then
		for player in visuals do
			destroyVisual(player)
		end
		return
	end
	for _, player in Players:GetPlayers() do
		local character = characterOf(player)
		if player ~= localPlayer and character ~= nil then
			task.spawn(attach, player, character)
		end
	end
end

local function watch(player)
	if player == localPlayer then
		return
	end
	table.insert(connections, player.CharacterAdded:Connect(function(character)
		task.spawn(attach, player, character)
	end))
	table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(function()
		if player.Character ~= nil then
			task.spawn(attach, player, player.Character)
		else
			destroyVisual(player)
		end
	end))
	table.insert(connections, player:GetPropertyChangedSignal("Neutral"):Connect(function()
		if player.Character ~= nil then
			task.spawn(attach, player, player.Character)
		end
	end))
	if player.Character ~= nil then
		task.spawn(attach, player, player.Character)
	end
end

local function currentFov()
	local fov = 0
	if modules.aimbot.enabled then
		fov = math.max(fov, modules.aimbot.fov)
	end
	if modules.smooth.enabled then
		fov = math.max(fov, modules.smooth.fov)
	end
	if modules.silent.enabled then
		fov = math.max(fov, modules.silent.fov)
	end
	return fov
end

local function canSee(camera, part)
	local origin = camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if localPlayer.Character ~= nil then
		table.insert(ignore, localPlayer.Character)
	end
	if part.Parent ~= nil then
		table.insert(ignore, part.Parent)
	end
	params.FilterDescendantsInstances = ignore
	state.internalRay = true
	local hit = workspace:Raycast(origin, part.Position - origin, params)
	state.internalRay = false
	return hit == nil
end

local function predictedPoint(camera, part)
	local origin = camera.CFrame.Position
	local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart") or part
	local velocity = root.AssemblyLinearVelocity
	local gravity = workspace.Gravity
	if gravity <= 0 then
		gravity = 196.2
	end

	local predicted = part.Position
	local flight = 0
	for _ = 1, 5 do
		local offset = predicted - origin
		local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
		flight = math.max(flat, 1) / ARROW_SPEED
		predicted = part.Position + velocity * flight
	end

	-- Drop grows with the square of flight time, so long shots aim higher.
	local drop = 0.5 * gravity * flight * flight
	return predicted + Vector3.new(0, drop, 0)
end

local function closestEnemy(camera, fov, lockOffscreen, requireSight)
	local center = camera.ViewportSize / 2
	local bestPart = nil
	local bestScore = math.huge
	local fallback = nil
	local fallbackDistance = math.huge
	for _, player in Players:GetPlayers() do
		if sideOf(player) ~= "enemy" then
			continue
		end
		local character = characterOf(player)
		local part = aimPartOf(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if part == nil or humanoid == nil or humanoid.Health <= 0 then
			continue
		end
		local studs = (part.Position - camera.CFrame.Position).Magnitude
		if studs > 1200 then
			continue
		end
		if studs < fallbackDistance then
			fallbackDistance = studs
			fallback = part
		end
		local point, onScreen = camera:WorldToViewportPoint(part.Position)
		if not onScreen or point.Z <= 0 then
			continue
		end
		local pixels = (Vector2.new(point.X, point.Y) - center).Magnitude
		if pixels <= fov and pixels < bestScore and (not requireSight or canSee(camera, part)) then
			bestScore = pixels
			bestPart = part
		end
	end
	if bestPart == nil and lockOffscreen then
		return fallback
	end
	return bestPart
end

local function aimAt(camera, part, alpha)
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end

	if state.cameraDistance == nil then
		local current = (camera.CFrame.Position - root.Position).Magnitude
		state.cameraDistance = math.clamp(if current > 1 then current else 12, 8, 14)
	end

	local predicted = predictedPoint(camera, part)
	local lead = Vector3.new(predicted.X - part.Position.X, 0, predicted.Z - part.Position.Z)
	if lead.Magnitude > 10 then
		lead = lead.Unit * 10
	end
	local vertical = math.clamp(predicted.Y - part.Position.Y, -2, 6)
	local focus = part.Position + lead + Vector3.new(0, vertical, 0)

	local flat = Vector3.new(focus.X - root.Position.X, 0, focus.Z - root.Position.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	local camPos = root.Position + Vector3.new(0, 2.6, 0) - flat.Unit * state.cameraDistance
	local goal = CFrame.lookAt(camPos, focus)
	if alpha >= 1 then
		camera.CFrame = goal
	else
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	end
end

local function restoreCamera(camera)
	state.cameraDistance = nil
	if state.savedCameraType ~= nil then
		camera.CameraType = state.savedCameraType
		state.savedCameraType = nil
	end
end

local function ownCamera(camera)
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		state.savedCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
	end
end

local function applyMovement()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil then
		return
	end

	if modules.fly.enabled then
		state.wasFlying = true
		humanoid.PlatformStand = true
		local camera = workspace.CurrentCamera
		local direction = Vector3.zero
		if camera ~= nil then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				direction += camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				direction -= camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				direction -= camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				direction += camera.CFrame.RightVector
			end
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.yAxis
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			direction -= Vector3.yAxis
		end
		if direction.Magnitude > 0.05 then
			root.AssemblyLinearVelocity = direction.Unit * modules.fly.value
		else
			root.AssemblyLinearVelocity = Vector3.zero
		end
		return
	elseif state.wasFlying then
		state.wasFlying = false
		humanoid.PlatformStand = false
	end

	if modules.speed.enabled then
		if state.savedSpeed == nil then
			state.savedSpeed = humanoid.WalkSpeed
		end
		humanoid.WalkSpeed = modules.speed.value
		local move = humanoid.MoveDirection
		local flat = Vector3.new(move.X, 0, move.Z)
		if flat.Magnitude > 0.05 then
			local push = flat.Unit * modules.speed.value
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(push.X, velocity.Y, push.Z)
			for _, child in character:GetDescendants() do
				if child:IsA("LinearVelocity") then
					local current = child.VectorVelocity
					child.VectorVelocity = Vector3.new(push.X, current.Y, push.Z)
				end
			end
		end
	elseif state.savedSpeed ~= nil then
		humanoid.WalkSpeed = state.savedSpeed
		state.savedSpeed = nil
	end

	if modules.jump.enabled then
		if state.savedJumpPower == nil then
			state.savedJumpPower = humanoid.JumpPower
			state.savedJumpHeight = humanoid.JumpHeight
		end
		humanoid.JumpPower = modules.jump.value
		humanoid.JumpHeight = modules.jump.value * 0.45
		if os.clock() < state.jumpUntil then
			local velocity = root.AssemblyLinearVelocity
			if velocity.Y < modules.jump.value then
				root.AssemblyLinearVelocity = Vector3.new(velocity.X, modules.jump.value, velocity.Z)
			end
		end
	elseif state.savedJumpPower ~= nil then
		humanoid.JumpPower = state.savedJumpPower
		humanoid.JumpHeight = state.savedJumpHeight
		state.savedJumpPower = nil
		state.savedJumpHeight = nil
	end
end

local function updateEsp(camera)
	if not modules.esp.enabled then
		return
	end
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for player, visual in visuals do
		local side = wantedSide(player)
		local theirCharacter = visual.character or characterOf(player)
		local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = visual.humanoid
		local alive = side ~= nil and humanoid ~= nil and humanoid.Parent ~= nil and humanoid.Health > 0
		visual.highlight.Enabled = alive
		visual.billboard.Enabled = alive
		if not alive then
			continue
		end
		local distanceText = ""
		if root ~= nil and theirRoot ~= nil then
			distanceText = string.format("  %d", (theirRoot.Position - root.Position).Magnitude)
		end
		local health = math.floor(humanoid.Health + 0.5)
		visual.label.Text = player.DisplayName .. distanceText
		visual.healthLabel.Text = string.format("%d HP", health)
		local color = if side == "ally" then ALLY_COLOR else ENEMY_COLOR
		visual.label.TextColor3 = color
		visual.healthLabel.TextColor3 = color
		visual.highlight.FillColor = color
		visual.highlight.OutlineColor = color
		visual.highlight.FillTransparency = 0.72
		visual.highlight.OutlineTransparency = 0
	end
end

local function updateTracers(camera)
	local shown = 0
	if modules.tracers.enabled then
		local from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 8)
		for _, player in Players:GetPlayers() do
			local side = sideOf(player)
			if side == nil or (side == "ally" and not modules.allyEsp.enabled) then
				continue
			end
			local character = characterOf(player)
			local root = character and (character:FindFirstChild("HumanoidRootPart") or aimPartOf(character))
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root == nil or humanoid == nil or humanoid.Health <= 0 then
				continue
			end
			local point, onScreen = camera:WorldToViewportPoint(root.Position)
			if not onScreen or point.Z <= 0 then
				continue
			end
			shown += 1
			local frame = tracerFrames[shown]
			if frame == nil then
				frame = Instance.new("Frame")
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.BorderSizePixel = 0
				frame.BackgroundColor3 = PURPLE
				frame.Parent = tracerFolder
				tracerFrames[shown] = frame
			end
			local to = Vector2.new(point.X, point.Y)
			local delta = to - from
			frame.Visible = true
			frame.BackgroundColor3 = if side == "ally" then ALLY_COLOR else ENEMY_COLOR
			frame.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
			frame.Size = UDim2.fromOffset(math.max(delta.Magnitude, 1), 2)
			frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		end
	end
	for index = shown + 1, #tracerFrames do
		tracerFrames[index].Visible = false
	end
end

local swingKillaura
local applyRage

local function onStep()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end

	applyMovement()

	local aiming = false
	if not state.menuOpen then
		if modules.aimbot.enabled then
			local target = closestEnemy(camera, modules.aimbot.fov, false, true)
			if target then
				aiming = true
				ownCamera(camera)
				aimAt(camera, target, 1)
			end
		elseif modules.smooth.enabled and state.holding[modules.smooth.key] then
			local target = closestEnemy(camera, modules.smooth.fov, false, true)
			if target then
				aiming = true
				ownCamera(camera)
				aimAt(camera, target, 0.22)
			end
		end
		if modules.silent.enabled then
			state.silentTarget = closestEnemy(camera, modules.silent.fov, false, true)
		else
			state.silentTarget = nil
		end
	else
		state.silentTarget = nil
	end
	if not aiming then
		restoreCamera(camera)
	end

	local fov = currentFov()
	fovCircle.Visible = fov > 0 and not state.menuOpen
	fovCircle.Size = UDim2.fromOffset(fov * 2, fov * 2)

	updateEsp(camera)
	updateTracers(camera)
	if not state.menuOpen then
		swingKillaura()
		applyRage()
	end
end

local function isSwordName(name)
	local lowered = string.lower(name)
	return string.find(lowered, "sword", 1, true) ~= nil
		or string.find(lowered, "blade", 1, true) ~= nil
		or string.find(lowered, "melee", 1, true) ~= nil
		or string.find(lowered, "hatchet", 1, true) ~= nil
		or string.find(lowered, "katana", 1, true) ~= nil
end

local function equipSword(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	local held = character:FindFirstChildOfClass("Tool")
	if held ~= nil and isSwordName(held.Name) then
		return held
	end
	local containers = { character, backpack }
	for _, container in containers do
		if container == nil then
			continue
		end
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and isSwordName(child.Name) then
				if humanoid ~= nil and child.Parent ~= character then
					humanoid:EquipTool(child)
				end
				return child
			end
		end
	end
	return held
end

local function swingParts(character, tool)
	local parts = {}
	local function collect(root)
		if root == nil then
			return
		end
		for _, part in root:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end
	end
	collect(tool)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and isSwordName(part.Name) then
			table.insert(parts, part)
		end
	end
	if #parts == 0 then
		local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if hand ~= nil then
			table.insert(parts, hand)
		end
	end
	return parts
end

local function clickSwing()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local x = camera.ViewportSize.X / 2
	local y = camera.ViewportSize.Y / 2
	pcall(function()
		game:GetService("VirtualInputManager"):SendMouseButtonEvent(x, y, 0, true, game, 0)
		game:GetService("VirtualInputManager"):SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
	if typeof(mouse1press) == "function" then
		pcall(mouse1press)
	end
	if typeof(mouse1release) == "function" then
		pcall(mouse1release)
	elseif typeof(mouse1click) == "function" then
		pcall(mouse1click)
	end
end

local function hitCharacter(character, enemyCharacter)
	local tool = equipSword(character)
	if tool ~= nil then
		pcall(function()
			tool:Activate()
		end)
	end
	clickSwing()
	if typeof(firetouchinterest) ~= "function" or enemyCharacter == nil then
		return
	end
	local parts = swingParts(character, tool)
	for _, enemyPart in enemyCharacter:GetDescendants() do
		if enemyPart:IsA("BasePart") then
			for _, part in parts do
				pcall(firetouchinterest, part, enemyPart, 0)
				pcall(firetouchinterest, part, enemyPart, 1)
			end
		end
	end
end

function swingKillaura()
	if not modules.killaura.enabled or os.clock() < state.nextSwing then
		return
	end
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or root == nil then
		return
	end

	local range = modules.killaura.value
	local hitAny = false
	for _, player in Players:GetPlayers() do
		if sideOf(player) ~= "enemy" then
			continue
		end
		local theirCharacter = characterOf(player)
		local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = theirCharacter and theirCharacter:FindFirstChildOfClass("Humanoid")
		if theirRoot == nil or humanoid == nil or humanoid.Health <= 0 then
			continue
		end
		if (theirRoot.Position - root.Position).Magnitude <= range then
			hitCharacter(character, theirCharacter)
			hitAny = true
		end
	end
	if hitAny then
		state.nextSwing = os.clock() + 0.12
	end
end

function applyRage()
	if not modules.rage.enabled then
		return
	end
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or root == nil then
		return
	end

	local targetCharacter = nil
	local targetRoot = nil
	local closest = math.huge
	for _, player in Players:GetPlayers() do
		if sideOf(player) ~= "enemy" then
			continue
		end
		local theirCharacter = characterOf(player)
		local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = theirCharacter and theirCharacter:FindFirstChildOfClass("Humanoid")
		if theirRoot == nil or humanoid == nil or humanoid.Health <= 0 then
			continue
		end
		local distance = (theirRoot.Position - root.Position).Magnitude
		if distance < closest then
			closest = distance
			targetCharacter = theirCharacter
			targetRoot = theirRoot
		end
	end
	if targetRoot == nil then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(targetRoot.Position - Vector3.new(0, 3, 0))
	if os.clock() >= state.nextSwing then
		hitCharacter(character, targetCharacter)
		state.nextSwing = os.clock() + 0.12
	end
end

local function unload()
	pcall(function()
		RunService:UnbindFromRenderStep("QuantumWare")
	end)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for player in visuals do
		destroyVisual(player)
	end
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil and state.savedSpeed ~= nil then
		humanoid.WalkSpeed = state.savedSpeed
	end
	if humanoid ~= nil and state.savedJumpPower ~= nil then
		humanoid.JumpPower = state.savedJumpPower
		humanoid.JumpHeight = state.savedJumpHeight
	end
	gui:Destroy()
end

if typeof(getgenv) == "function" then
	getgenv().QuantumWareUnload = unload
end

local function toggleModule(module)
	module.enabled = not module.enabled
	if module == modules.esp or module == modules.allyEsp then
		refreshEsp()
	end
	notify(module)
	saveSettings()
	if state.menuOpen then
		renderPage()
	else
		watermark.Visible = modules.watermark.enabled
	end
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if state.binding ~= nil then
		if input.KeyCode == Enum.KeyCode.Escape then
			state.binding = nil
			renderPage()
			return
		end
		if input.KeyCode == Enum.KeyCode.Unknown then
			return
		end
		if state.binding == "menu" then
			state.menuKey = input.KeyCode
		else
			state.binding.key = input.KeyCode
		end
		state.binding = nil
		saveSettings()
		renderPage()
		return
	end

	if input.KeyCode == state.menuKey then
		if gameProcessed then
			return
		end
		state.menuOpen = not state.menuOpen
		holder.Visible = state.menuOpen
		return
	end

	state.holding[input.KeyCode] = true
	if gameProcessed then
		return
	end
	for _, module in modules do
		if module.key == input.KeyCode and not module.hold then
			toggleModule(module)
		end
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		state.holding[input.KeyCode] = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end))

table.insert(connections, panel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		dragOrigin = holder.Position
	end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		holder.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
	end
end))

table.insert(connections, gui:GetAttributeChangedSignal("Unload"):Connect(function()
	if gui:GetAttribute("Unload") then
		unload()
	end
end))

table.insert(connections, Players.PlayerAdded:Connect(watch))
table.insert(connections, Players.PlayerRemoving:Connect(destroyVisual))
table.insert(connections, localPlayer:GetPropertyChangedSignal("Team"):Connect(refreshEsp))

for _, player in Players:GetPlayers() do
	watch(player)
end

local function rememberCharacter(model)
	if not model:IsA("Model") then
		return
	end
	if model:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(model) or Players:FindFirstChild(model.Name)
	if player == nil or player == localPlayer then
		return
	end
	characters[player] = model
	if modules.esp.enabled then
		task.spawn(attach, player, model)
	end
end

table.insert(connections, UserInputService.JumpRequest:Connect(function()
	if modules.jump.enabled then
		state.jumpUntil = os.clock() + 0.3
	end
end))

table.insert(connections, workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("Model") then
		task.defer(rememberCharacter, inst)
	elseif inst:IsA("Humanoid") and inst.Parent ~= nil then
		task.defer(rememberCharacter, inst.Parent)
	end
end))

for _, inst in workspace:GetDescendants() do
	if inst:IsA("Humanoid") and inst.Parent ~= nil then
		rememberCharacter(inst.Parent)
	end
end

local function installSilentAim()
	if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
		return
	end
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if state.internalRay or method ~= "Raycast" or self ~= workspace or not modules.silent.enabled then
			return oldNamecall(self, ...)
		end
		local target = state.silentTarget
		if target == nil or target.Parent == nil then
			return oldNamecall(self, ...)
		end
		local origin = ...
		if typeof(origin) ~= "Vector3" then
			return oldNamecall(self, ...)
		end
		local args = { ... }
		args[2] = target.Position - origin
		return oldNamecall(self, unpack(args))
	end)
end

local HttpService = game:GetService("HttpService")
local SETTINGS_PATH = "QuantumWare/settings.json"
local SCRIPT_PATH = "QuantumWare/main.luau"
local AUTOEXEC_PATH = "autoexec/QuantumWare.lua"
local autoloadQueued = false

local function filesReady()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function ensureSettingsFolder()
	if typeof(makefolder) == "function" and (typeof(isfolder) ~= "function" or not isfolder("QuantumWare")) then
		pcall(makefolder, "QuantumWare")
	end
end

function saveSettings()
	if not filesReady() then
		return
	end
	ensureSettingsFolder()
	local data = {
		autoload = state.autoload ~= false,
		menuKey = state.menuKey.Name,
		sourceUrl = state.sourceUrl or "",
		modules = {},
	}
	for id, module in modules do
		data.modules[id] = {
			enabled = module.enabled,
			key = if module.key then module.key.Name else nil,
			fov = module.fov,
			value = module.value,
		}
	end
	pcall(writefile, SETTINGS_PATH, HttpService:JSONEncode(data))

	local loader = [[
repeat task.wait() until game:IsLoaded()
if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
	return
end
if not isfile("QuantumWare/settings.json") then
	return
end
local HttpService = game:GetService("HttpService")
local data = HttpService:JSONDecode(readfile("QuantumWare/settings.json"))
if data.autoload == false then
	return
end
local source
if type(data.sourceUrl) == "string" and data.sourceUrl ~= "" then
	local ok, body = pcall(function()
		return game:HttpGet(data.sourceUrl)
	end)
	if ok then
		source = body
	end
end
if type(source) ~= "string" and isfile("QuantumWare/main.luau") then
	source = readfile("QuantumWare/main.luau")
end
if type(source) == "string" and source ~= "" then
	loadstring(source)()
end
]]
	if state.autoload == false then
		autoloadQueued = false
		if typeof(delfile) == "function" then
			pcall(delfile, AUTOEXEC_PATH)
			pcall(delfile, "autoexecute/QuantumWare.lua")
		end
	else
		pcall(writefile, AUTOEXEC_PATH, loader)
		if typeof(isfolder) == "function" and isfolder("autoexecute") then
			pcall(writefile, "autoexecute/QuantumWare.lua", loader)
		end
		if not autoloadQueued then
			local queue = queue_on_teleport
			if typeof(queue) ~= "function" and typeof(syn) == "table" then
				queue = syn.queue_on_teleport
			end
			if typeof(queue) == "function" then
				autoloadQueued = pcall(queue, loader)
			end
		end
	end
end

local function rememberScriptCopy()
	if not filesReady() then
		return
	end
	ensureSettingsFolder()
	if state.sourceUrl ~= "" and typeof(game.HttpGet) == "function" then
		local ok, body = pcall(function()
			return game:HttpGet(state.sourceUrl)
		end)
		if ok and type(body) == "string" and body ~= "" then
			pcall(writefile, SCRIPT_PATH, body)
			return
		end
	end
	for _, path in { "quantumware.luau", "quantumware.lua", "QuantumWare.lua" } do
		if isfile(path) then
			local ok, body = pcall(readfile, path)
			if ok and type(body) == "string" and body ~= "" then
				pcall(writefile, SCRIPT_PATH, body)
				return
			end
		end
	end
end

local function loadSettings()
	if typeof(getgenv) == "function" then
		local env = getgenv()
		if type(env.QuantumWareSourceUrl) == "string" and env.QuantumWareSourceUrl ~= "" then
			state.sourceUrl = env.QuantumWareSourceUrl
		end
	end
	if state.sourceUrl == "" and SOURCE_URL ~= "" then
		state.sourceUrl = SOURCE_URL
	end
	if not filesReady() or not isfile(SETTINGS_PATH) then
		rememberScriptCopy()
		saveSettings()
		return
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_PATH))
	end)
	if not ok or type(data) ~= "table" then
		saveSettings()
		return
	end
	if type(data.menuKey) == "string" and Enum.KeyCode[data.menuKey] ~= nil then
		state.menuKey = Enum.KeyCode[data.menuKey]
	end
	if state.sourceUrl == "" and type(data.sourceUrl) == "string" then
		state.sourceUrl = data.sourceUrl
	end
	if data.autoload ~= nil then
		state.autoload = data.autoload
	end
	if type(data.modules) == "table" then
		for id, saved in data.modules do
			local module = modules[id]
			if module ~= nil and type(saved) == "table" then
				if saved.enabled ~= nil then
					module.enabled = saved.enabled
				end
				if type(saved.key) == "string" and Enum.KeyCode[saved.key] ~= nil then
					module.key = Enum.KeyCode[saved.key]
				end
				if type(saved.fov) == "number" then
					module.fov = saved.fov
				end
				if type(saved.value) == "number" then
					module.value = saved.value
				end
			end
		end
	end
	rememberScriptCopy()
	saveSettings()
end

loadSettings()
if modules.esp.enabled then
	refreshEsp()
end
renderPage()
pcall(installSilentAim)
RunService:BindToRenderStep("QuantumWare", Enum.RenderPriority.Last.Value, onStep)
table.insert(connections, RunService.Heartbeat:Connect(onStep))
pcall(function()
	table.insert(connections, RunService.PreSimulation:Connect(applyMovement))
end)
