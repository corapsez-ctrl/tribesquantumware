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
		showCircle = true,
		circleColor = PURPLE,
		options = {
			{ field = "fov", name = "FOV", kind = "number" },
			{ field = "showCircle", name = "FOV circle", kind = "bool" },
			{ field = "circleColor", name = "Circle colour", kind = "color" },
		},
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
		options = {
			{ field = "value", name = "Speed", kind = "number" },
		},
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
		options = {
			{ field = "value", name = "Height", kind = "number" },
		},
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
		options = {
			{ field = "value", name = "Reach", kind = "number" },
		},
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
		showCircle = true,
		circleColor = PURPLE,
		options = {
			{ field = "fov", name = "FOV", kind = "number" },
			{ field = "showCircle", name = "FOV circle", kind = "bool" },
			{ field = "circleColor", name = "Circle colour", kind = "color" },
		},
	},
	fly = {
		page = "Blatant",
		name = "Fly",
		desc = "Fly with WASD, Space, and Ctrl",
		key = Enum.KeyCode.F,
		enabled = false,
		value = 300,
		min = 120,
		max = 700,
		step = 20,
		options = {
			{ field = "value", name = "Speed", kind = "number" },
		},
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
		showCircle = true,
		circleColor = PURPLE,
		options = {
			{ field = "fov", name = "FOV", kind = "number" },
			{ field = "showCircle", name = "FOV circle", kind = "bool" },
			{ field = "circleColor", name = "Circle colour", kind = "color" },
		},
	},
	trigger = {
		page = "Closet",
		name = "Triggerbot",
		desc = "Clicks when an enemy is inside the crosshair",
		key = Enum.KeyCode.B,
		enabled = false,
		fov = 30,
		min = 8,
		max = 140,
		step = 4,
		showCircle = true,
		circleColor = PURPLE,
		options = {
			{ field = "fov", name = "FOV", kind = "number" },
			{ field = "showCircle", name = "FOV circle", kind = "bool" },
			{ field = "circleColor", name = "Circle colour", kind = "color" },
		},
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
		desc = "Hides in the sky, then drops under an enemy and spams the dagger",
		key = Enum.KeyCode.V,
		enabled = false,
		hide = 2,
		attack = 0.5,
		options = {
			{ field = "hide", name = "Hide", kind = "number", min = 1, max = 5, step = 0.25 },
			{ field = "attack", name = "Attack", kind = "number", min = 0.35, max = 1, step = 0.05 },
		},
	},
}

local pageOrder = {
	Blatant = { "aimbot", "silent", "killaura", "fly", "speed", "jump" },
	Rage = { "rage" },
	Closet = { "smooth", "trigger" },
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
	rageSilent = false,
	rageHiddenGuis = {},
	internalRay = false,
	wasFlying = false,
	openModule = nil,
	rageActive = false,
	ragePhase = "hide",
	rageUntil = 0,
	rageSwung = false,
	rageTarget = nil,
	rageReturn = nil,
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

local rageStatus = Instance.new("TextLabel")
rageStatus.Name = "RageStatus"
rageStatus.AnchorPoint = Vector2.new(0.5, 0)
rageStatus.BackgroundTransparency = 1
rageStatus.Position = UDim2.new(0.5, 0, 0, 64)
rageStatus.Size = UDim2.fromOffset(320, 28)
rageStatus.Font = Enum.Font.GothamBold
rageStatus.TextSize = 22
rageStatus.TextColor3 = Color3.new(1, 1, 1)
rageStatus.TextStrokeColor3 = Color3.new(0, 0, 0)
rageStatus.TextStrokeTransparency = 0
rageStatus.Text = "status: void"
rageStatus.Visible = false
rageStatus.Parent = gui

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

local CIRCLE_COLORS = {
	PURPLE,
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(80, 255, 140),
	Color3.fromRGB(255, 210, 60),
}

local fovCircles = {}
for _, id in { "aimbot", "silent", "smooth", "trigger" } do
	local frame = Instance.new("Frame")
	frame.Name = "Fov" .. id
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(1, 0)
	frameCorner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = PURPLE
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = frame
	fovCircles[id] = stroke
end

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

local content = Instance.new("ScrollingFrame")
content.Name = "Pages"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(176, 54)
content.Size = UDim2.fromOffset(464, 348)
content.Active = true
content.ScrollingEnabled = true
content.ScrollBarThickness = 8
content.ScrollBarImageColor3 = PURPLE
content.AutomaticCanvasSize = Enum.AutomaticSize.None
content.CanvasSize = UDim2.fromOffset(0, 0)
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.Parent = panel
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content
local contentPad = Instance.new("UIPadding")
contentPad.PaddingBottom = UDim.new(0, 16)
contentPad.Parent = content

local function refreshCanvas()
	local height = contentLayout.AbsoluteContentSize.Y
	if height > 0 then
		content.CanvasSize = UDim2.fromOffset(0, height + 16)
	end
end

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

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
local moduleRows = {}

local function renderPage()
	watermark.Visible = modules.watermark.enabled
	if state.binding == "menu" then
		bindHint.Text = "Press a key for the menu"
	elseif typeof(state.binding) == "table" then
		bindHint.Text = "Press a key for " .. state.binding.name
	else
		bindHint.Text = "Right click a module for its settings"
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
			content.CanvasPosition = Vector2.zero
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

	table.clear(moduleRows)
	for _, id in pageOrder[state.page] do
		local module = modules[id]
		local opened = state.openModule == id and module.options ~= nil
		local optionCount = if opened then #module.options else 0
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 64 + optionCount * 32)
		row.BackgroundColor3 = ROW
		row.BorderSizePixel = 0
		row.Active = true
		row:SetAttribute("ModuleId", id)
		row.Parent = content
		corner(row, 12)
		moduleRows[id] = row

		local function toggleSettings()
			if module.options == nil or state.settingsClick == id then
				return
			end
			state.settingsClick = id
			task.defer(function()
				state.settingsClick = nil
			end)
			state.openModule = if state.openModule == id then nil else id
			renderPage()
		end

		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.BackgroundTransparency = 1
		hit.Size = UDim2.fromScale(1, 1)
		hit.Text = ""
		hit.AutoButtonColor = false
		hit.ZIndex = 1
		hit.Parent = row
		hit.MouseButton2Click:Connect(toggleSettings)

		label(row, module.name, UDim2.fromOffset(200, 24), if opened then PURPLE else Color3.new(1, 1, 1), 15).Position = UDim2.fromOffset(14, 8)
		label(row, module.desc, UDim2.fromOffset(250, 18), MUTED, 12).Position = UDim2.fromOffset(14, 32)

		local toggle = Instance.new("TextButton")
		toggle.AnchorPoint = Vector2.new(1, 0)
		toggle.Position = UDim2.new(1, -14, 0, 20)
		toggle.Size = UDim2.fromOffset(44, 24)
		toggle.BackgroundColor3 = if module.enabled then PURPLE else Color3.fromRGB(40, 40, 46)
		toggle.BorderSizePixel = 0
		toggle.AutoButtonColor = false
		toggle.Text = ""
		toggle.ZIndex = 3
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
		toggle.MouseButton2Click:Connect(toggleSettings)

		local keyButton = Instance.new("TextButton")
		keyButton.AnchorPoint = Vector2.new(1, 0)
		keyButton.Position = UDim2.new(1, -68, 0, 19)
		keyButton.Size = UDim2.fromOffset(78, 26)
		keyButton.BackgroundColor3 = BLACK
		keyButton.BorderSizePixel = 0
		keyButton.AutoButtonColor = false
		keyButton.Font = Enum.Font.GothamBold
		keyButton.TextSize = 12
		keyButton.TextColor3 = PURPLE
		keyButton.Text = if state.binding == module then "Press" else module.key.Name
		keyButton.ZIndex = 3
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
		keyButton.MouseButton2Click:Connect(toggleSettings)

		if opened then
			for index, option in module.options do
				local y = 58 + (index - 1) * 32
				label(row, option.name, UDim2.fromOffset(110, 22), MUTED, 12).Position = UDim2.fromOffset(14, y)

				if option.kind == "number" then
					local step = option.step or module.step or 1
					local minValue = option.min or module.min or 0
					local maxValue = option.max or module.max or 100
					local valueLabel = label(row, "", UDim2.fromOffset(52, 22), PURPLE, 12, Enum.TextXAlignment.Center)
					valueLabel.Position = UDim2.fromOffset(150, y)

					local function showValue()
						local amount = module[option.field]
						if step < 1 then
							valueLabel.Text = string.format("%.2f", amount) .. "s"
						else
							valueLabel.Text = tostring(math.floor(amount + 0.5))
						end
					end

					local function bump(direction)
						local snapped = math.floor((module[option.field] + step * direction) / step + 0.5) * step
						module[option.field] = math.clamp(snapped, minValue, maxValue)
						showValue()
						saveSettings()
					end

					local function smallButton(text, x, direction)
						local button = Instance.new("TextButton")
						button.Position = UDim2.fromOffset(x, y)
						button.Size = UDim2.fromOffset(22, 22)
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

					smallButton("-", 126, -1)
					smallButton("+", 204, 1)
					showValue()
				elseif option.kind == "bool" then
					local box = Instance.new("TextButton")
					box.Position = UDim2.fromOffset(126, y)
					box.Size = UDim2.fromOffset(44, 22)
					box.BackgroundColor3 = if module[option.field] then PURPLE else Color3.fromRGB(40, 40, 46)
					box.BorderSizePixel = 0
					box.AutoButtonColor = false
					box.Text = ""
					box.Parent = row
					corner(box, 11)
					local boxKnob = Instance.new("Frame")
					boxKnob.Size = UDim2.fromOffset(14, 14)
					boxKnob.Position = if module[option.field] then UDim2.fromOffset(26, 4) else UDim2.fromOffset(4, 4)
					boxKnob.BackgroundColor3 = Color3.new(1, 1, 1)
					boxKnob.BorderSizePixel = 0
					boxKnob.Parent = box
					corner(boxKnob, 7)
					box.MouseButton1Click:Connect(function()
						module[option.field] = not module[option.field]
						saveSettings()
						renderPage()
					end)
				elseif option.kind == "color" then
					for colorIndex, color in CIRCLE_COLORS do
						local swatch = Instance.new("TextButton")
						swatch.Position = UDim2.fromOffset(126 + (colorIndex - 1) * 26, y)
						swatch.Size = UDim2.fromOffset(20, 20)
						swatch.BackgroundColor3 = color
						swatch.BorderSizePixel = 0
						swatch.AutoButtonColor = false
						swatch.Text = ""
						swatch.Parent = row
						corner(swatch, 10)
						local swatchStroke = Instance.new("UIStroke")
						swatchStroke.Color = Color3.new(1, 1, 1)
						swatchStroke.Thickness = 2
						swatchStroke.Transparency = if module[option.field] == color then 0 else 1
						swatchStroke.Parent = swatch
						swatch.MouseButton1Click:Connect(function()
							module[option.field] = color
							saveSettings()
							renderPage()
						end)
					end
				elseif option.kind == "choice" then
					for choiceIndex, choice in option.choices do
						local picked = module[option.field] == choice
						local choiceButton = Instance.new("TextButton")
						choiceButton.Position = UDim2.fromOffset(126 + (choiceIndex - 1) * 78, y)
						choiceButton.Size = UDim2.fromOffset(74, 22)
						choiceButton.BackgroundColor3 = if picked then PURPLE else BLACK
						choiceButton.BorderSizePixel = 0
						choiceButton.AutoButtonColor = false
						choiceButton.Font = Enum.Font.GothamBold
						choiceButton.TextSize = 12
						choiceButton.TextColor3 = if picked then Color3.new(1, 1, 1) else PURPLE
						choiceButton.Text = choice
						choiceButton.Parent = row
						corner(choiceButton, 6)
						choiceButton.MouseButton1Click:Connect(function()
							module[option.field] = choice
							saveSettings()
							renderPage()
						end)
					end
				end
			end
		end
	end
	task.defer(refreshCanvas)
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
		local now = os.clock()
		local dt = math.clamp(now - (state.lastFly or now), 0, 0.05)
		state.lastFly = now
		root.AssemblyLinearVelocity = Vector3.zero
		if direction.Magnitude > 0.05 then
			root.CFrame += direction.Unit * modules.fly.value * dt
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
local clickSwing

local function onStep()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end

	applyMovement()
	if state.menuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end

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

	for _, id in { "aimbot", "silent", "smooth", "trigger" } do
		local module = modules[id]
		local stroke = fovCircles[id]
		local show = module.enabled and module.showCircle ~= false and not state.menuOpen and module.fov ~= nil
		if id == "smooth" and not state.holding[module.key] then
			show = false
		end
		stroke.Parent.Visible = show
		if show then
			stroke.Color = module.circleColor or PURPLE
			stroke.Parent.Size = UDim2.fromOffset(module.fov * 2, module.fov * 2)
		end
	end

	updateEsp(camera)
	updateTracers(camera)
	if not state.menuOpen then
		swingKillaura()
		if modules.trigger.enabled then
			local target = closestEnemy(camera, modules.trigger.fov, false, true)
			if target ~= nil and os.clock() >= (state.nextTrigger or 0) then
				clickSwing()
				state.nextTrigger = os.clock() + 0.15
			end
		end
	end
	applyRage()
end

local SWORD_WORDS = { "sword", "blade", "melee", "hatchet", "katana" }
local WEAPON_WORDS = {
	Sword = SWORD_WORDS,
	Dagger = { "dagger", "knife", "dirk", "shiv" },
	Hammer = { "hammer", "mace", "club", "maul" },
	Ranged = { "crossbow", "xbow", "bow", "gun", "rifle", "revolver", "staff", "wand", "sling", "bolt" },
}

local BOLT_WORDS = { "arrow", "bolt", "projectile", "crossbow", "bullet", "shot", "dart" }
local guidedBolts = {}

local function matchesWords(name, words)
	local lowered = string.lower(name)
	for _, word in words do
		if string.find(lowered, word, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function eachTool(character)
	local seen = {}
	local list = {}
	local function add(container)
		if container == nil then
			return
		end
		for _, child in container:GetDescendants() do
			if child:IsA("Tool") and not seen[child] then
				seen[child] = true
				table.insert(list, child)
			end
		end
	end
	add(character)
	add(localPlayer:FindFirstChildOfClass("Backpack"))
	add(localPlayer:FindFirstChild("StarterGear"))
	return list
end

local function scoreTool(tool, words)
	local blob = string.lower(tool.Name)
	for _, descendant in tool:GetDescendants() do
		blob ..= " " .. string.lower(descendant.Name)
	end
	if string.find(blob, "crossbow", 1, true) ~= nil or string.find(blob, "xbow", 1, true) ~= nil then
		return 3
	end
	for _, word in words do
		if string.find(blob, word, 1, true) ~= nil then
			return 2
		end
	end
	return 0
end

local function equipWeapon(character, words)
	local best = nil
	local bestScore = 0
	for _, tool in eachTool(character) do
		local score = scoreTool(tool, words)
		if score > bestScore then
			best = tool
			bestScore = score
		end
	end
	if best == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if best.Parent ~= character then
		pcall(function()
			best.Parent = character
		end)
		if humanoid ~= nil then
			pcall(function()
				humanoid:EquipTool(best)
			end)
		end
	end
	return best
end

local function leadPoint(fromPosition, part)
	local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart") or part
	local velocity = root.AssemblyLinearVelocity
	local flat = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(fromPosition.X, 0, fromPosition.Z)).Magnitude
	local flight = math.max(flat, 1) / ARROW_SPEED
	local gravity = workspace.Gravity
	if gravity <= 0 then
		gravity = 196.2
	end
	return part.Position + velocity * flight + Vector3.new(0, 0.5 * gravity * flight * flight, 0)
end

local function guideBolt(part)
	if not part:IsA("BasePart") or guidedBolts[part] then
		return
	end
	if os.clock() > (state.rageGuideUntil or 0) then
		return
	end
	local character = localPlayer.Character
	if character ~= nil and part:IsDescendantOf(character) then
		return
	end
	if state.rageVisual ~= nil and part:IsDescendantOf(state.rageVisual) then
		return
	end
	local from = state.rageShootFrom
	local goal = state.silentPoint
	if from == nil or goal == nil then
		return
	end
	local fromDistance = (part.Position - from).Magnitude
	local goalDistance = (part.Position - goal).Magnitude
	if fromDistance > 40 and goalDistance > 60 then
		return
	end
	local blob = string.lower(part.Name .. " " .. (if part.Parent then part.Parent.Name else ""))
	local named = matchesWords(blob, BOLT_WORDS)
	if not named then
		return
	end
	guidedBolts[part] = true
	part.CanCollide = false
	task.spawn(function()
		local started = os.clock()
		while part.Parent ~= nil and os.clock() - started < 1.3 do
			local point = state.silentPoint or goal
			local left = point - part.Position
			if left.Magnitude < 3.5 then
				part.CFrame = CFrame.new(point)
				part.AssemblyLinearVelocity = Vector3.zero
				local enemy = state.rageTarget and characterOf(state.rageTarget)
				if enemy ~= nil and typeof(firetouchinterest) == "function" then
					for _, enemyPart in enemy:GetDescendants() do
						if enemyPart:IsA("BasePart") then
							pcall(firetouchinterest, part, enemyPart, 0)
							pcall(firetouchinterest, part, enemyPart, 1)
						end
					end
				end
				break
			end
			part.AssemblyLinearVelocity = left.Unit * 420
			part.CFrame = CFrame.lookAt(part.Position, point)
			task.wait()
		end
		guidedBolts[part] = nil
	end)
end

table.insert(connections, workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("BasePart") then
		guideBolt(inst)
	elseif inst:IsA("Model") then
		local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		if primary ~= nil then
			guideBolt(primary)
		end
	end
end))

local function swingParts(character, tool, words)
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
		if part:IsA("BasePart") and matchesWords(part.Name, words) then
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

function clickSwing()
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

local function releaseMouse()
	local camera = workspace.CurrentCamera
	local x = if camera then camera.ViewportSize.X / 2 else 0
	local y = if camera then camera.ViewportSize.Y / 2 else 0
	pcall(function()
		game:GetService("VirtualInputManager"):SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
	if typeof(mouse1release) == "function" then
		pcall(mouse1release)
	end
end

local function hitCharacter(character, enemyCharacter, words)
	words = words or SWORD_WORDS
	local tool = equipWeapon(character, words)
	if tool ~= nil then
		pcall(function()
			tool:Activate()
		end)
	end
	clickSwing()
	if typeof(firetouchinterest) ~= "function" or enemyCharacter == nil then
		return
	end
	local parts = swingParts(character, tool, words)
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

local function livingEnemyRoot(player)
	if player == nil or sideOf(player) ~= "enemy" then
		return nil
	end
	local theirCharacter = characterOf(player)
	local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")
	local humanoid = theirCharacter and theirCharacter:FindFirstChildOfClass("Humanoid")
	if theirRoot == nil or humanoid == nil or humanoid.Health <= 0 then
		return nil
	end
	return theirRoot
end

local function nearestEnemy(origin)
	local targetPlayer = nil
	local closest = math.huge
	for _, player in Players:GetPlayers() do
		local theirRoot = livingEnemyRoot(player)
		if theirRoot == nil then
			continue
		end
		local offset = theirRoot.Position - origin
		local distance = Vector2.new(offset.X, offset.Z).Magnitude
		if distance < closest then
			closest = distance
			targetPlayer = player
		end
	end
	return targetPlayer
end

local function pickHideSpot(around)
	local angle = math.random() * math.pi * 2
	return Vector3.new(around.X + math.cos(angle) * 10000, around.Y + 700, around.Z + math.sin(angle) * 10000)
end

local function setRageStatus(text)
	rageStatus.Visible = text ~= nil
	if text ~= nil then
		rageStatus.Text = text
	end
end

local function hideRealCharacter(character, hidden)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.LocalTransparencyModifier = if hidden then 1 else 0
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			if hidden then
				if state.rageHiddenGuis[descendant] == nil then
					state.rageHiddenGuis[descendant] = descendant.Enabled
				end
				descendant.Enabled = false
			elseif state.rageHiddenGuis[descendant] ~= nil then
				descendant.Enabled = state.rageHiddenGuis[descendant]
			end
		end
	end
	if not hidden then
		table.clear(state.rageHiddenGuis)
	end
end

local function destroyRageVisual()
	if state.rageVisual ~= nil then
		state.rageVisual:Destroy()
		state.rageVisual = nil
	end
	state.rageVisualOffsets = nil
	state.rageVisualCharacter = nil
end

local function ensureRageVisual(character)
	if state.rageVisual ~= nil and state.rageVisual.Parent ~= nil and state.rageVisualCharacter == character then
		return state.rageVisual
	end
	destroyRageVisual()
	character.Archivable = true
	local ok, clone = pcall(function()
		return character:Clone()
	end)
	character.Archivable = false
	if not ok or clone == nil then
		return nil
	end
	local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
	if cloneRoot == nil then
		clone:Destroy()
		return nil
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			descendant.PlatformStand = true
		end
	end
	local offsets = {}
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			offsets[descendant] = cloneRoot.CFrame:ToObjectSpace(descendant.CFrame)
		end
	end
	clone.Name = "QuantumWareVisual"
	clone.Parent = workspace
	state.rageVisual = clone
	state.rageVisualOffsets = offsets
	state.rageVisualCharacter = character
	return clone
end

local function showSpawnView(character)
	if state.rageReturn == nil then
		return
	end
	hideRealCharacter(character, true)
	ensureRageVisual(character)
	local home = state.rageReturn
	if state.rageVisualOffsets ~= nil then
		for part, offset in state.rageVisualOffsets do
			if part.Parent ~= nil then
				part.CFrame = home * offset
			end
		end
	end
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	ownCamera(camera)
	local flat = Vector3.new(home.LookVector.X, 0, home.LookVector.Z)
	if flat.Magnitude < 0.05 then
		flat = Vector3.new(0, 0, -1)
	else
		flat = flat.Unit
	end
	local focus = home.Position + Vector3.new(0, 1.5, 0)
	camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, 1.2, 0) - flat * 12, focus)
end

local function clearRageView(character)
	setRageStatus(nil)
	destroyRageVisual()
	if character ~= nil then
		hideRealCharacter(character, false)
	end
	local camera = workspace.CurrentCamera
	if camera ~= nil then
		restoreCamera(camera)
	end
end

function applyRage()
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not modules.rage.enabled then
		if state.rageHolding then
			state.rageHolding = false
			releaseMouse()
		end
		if state.rageActive then
			state.rageActive = false
			state.rageTarget = nil
			state.rageSilent = false
			state.silentPoint = nil
			state.rageHidePos = nil
			state.rageGuideUntil = 0
			state.rageReleaseUntil = os.clock() + 0.3
			clearRageView(character)
		end
		if root ~= nil and state.rageReturn ~= nil and os.clock() < (state.rageReleaseUntil or 0) then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = state.rageReturn
		elseif os.clock() >= (state.rageReleaseUntil or 0) then
			state.rageReturn = nil
		end
		return
	end
	if character == nil or root == nil then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil and not state.rageStood then
		state.ragePlatform = humanoid.PlatformStand
		state.rageStood = true
	end
	if humanoid ~= nil then
		humanoid.PlatformStand = true
	end

	if not state.rageActive then
		state.rageActive = true
		state.rageReturn = root.CFrame
		state.ragePhase = "hide"
		state.rageUntil = os.clock() + math.clamp(modules.rage.hide or 2, 1, 5)
		state.rageHidePos = pickHideSpot(root.Position)
		state.rageTarget = nearestEnemy(root.Position)
		state.rageNextHit = 0
	end

	if livingEnemyRoot(state.rageTarget) == nil then
		local origin = if state.rageReturn then state.rageReturn.Position else root.Position
		state.rageTarget = nearestEnemy(origin)
	end

	local targetRoot = livingEnemyRoot(state.rageTarget)
	local now = os.clock()
	local hideTime = math.clamp(modules.rage.hide or 2, 1, 5)
	local attackTime = math.clamp(modules.rage.attack or 0.5, 0.35, 1)
	local around = if targetRoot then targetRoot.Position else root.Position

	if now >= state.rageUntil then
		if state.ragePhase ~= "attack" or targetRoot == nil then
			state.ragePhase = "attack"
			state.rageUntil = now + attackTime
			state.rageNextHit = 0
		else
			state.ragePhase = "hide"
			state.rageUntil = now + hideTime
			state.rageHidePos = pickHideSpot(around)
		end
	end

	if state.ragePhase ~= "attack" or targetRoot == nil then
		if state.rageHidePos == nil then
			state.rageHidePos = pickHideSpot(around)
		end
		placeBody(root, CFrame.new(state.rageHidePos))
		state.rageSilent = false
		state.silentPoint = nil
		setRageStatus("status: void")
		return
	end

	placeBody(root, CFrame.new(targetRoot.Position - Vector3.new(0, 2.5, 0)))
	state.rageSilent = false
	state.silentPoint = nil
	if now >= (state.rageNextHit or 0) then
		hitCharacter(character, targetRoot.Parent, WEAPON_WORDS.Dagger)
		state.rageNextHit = now + 0.12
	end
	setRageStatus("status: attacking")
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
	clearRageView(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and state.rageReturn ~= nil then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = state.rageReturn
	end
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
	if input.UserInputType == Enum.UserInputType.MouseButton2 and state.menuOpen then
		local mouse = UserInputService:GetMouseLocation()
		local inset = game:GetService("GuiService"):GetGuiInset()
		local function rowAt(point)
			for id, row in moduleRows do
				if row.Parent == nil or modules[id] == nil or modules[id].options == nil then
					continue
				end
				local pos = row.AbsolutePosition
				local size = row.AbsoluteSize
				if point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y then
					return id
				end
			end
			return nil
		end
		local hitId = rowAt(mouse) or rowAt(mouse - inset)
		if hitId ~= nil and state.settingsClick ~= hitId then
			state.settingsClick = hitId
			task.defer(function()
				state.settingsClick = nil
			end)
			state.openModule = if state.openModule == hitId then nil else hitId
			renderPage()
		end
		return
	end

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
		if state.menuOpen then
			state.savedMouseBehavior = UserInputService.MouseBehavior
			state.savedMouseIcon = UserInputService.MouseIconEnabled
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
			game:GetService("ContextActionService"):BindActionAtPriority("QuantumWareRMB", function()
				return Enum.ContextActionResult.Sink
			end, false, 4000, Enum.UserInputType.MouseButton2)
		else
			game:GetService("ContextActionService"):UnbindAction("QuantumWareRMB")
			if state.savedMouseBehavior ~= nil then
				UserInputService.MouseBehavior = state.savedMouseBehavior
			end
			if state.savedMouseIcon ~= nil then
				UserInputService.MouseIconEnabled = state.savedMouseIcon
			end
		end
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
	elseif state.menuOpen and input.UserInputType == Enum.UserInputType.MouseWheel then
		local mouse = UserInputService:GetMouseLocation()
		local pos = content.AbsolutePosition
		local size = content.AbsoluteSize
		if mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
			local maxY = math.max(0, content.AbsoluteCanvasSize.Y - content.AbsoluteWindowSize.Y)
			local nextY = math.clamp(content.CanvasPosition.Y - input.Position.Z * 56, 0, maxY)
			content.CanvasPosition = Vector2.new(0, nextY)
		end
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
		local castIndex = if method == "Raycast" or method == "Spherecast" or method == "Blockcast" or method == "Shapecast" then 2 else nil
		if state.internalRay or castIndex == nil or self ~= workspace or not (modules.silent.enabled or state.rageSilent) then
			return oldNamecall(self, ...)
		end
		local goal = state.silentPoint
		local target = state.silentTarget
		if goal == nil and target ~= nil and target.Parent ~= nil then
			goal = target.Position
		end
		if goal == nil then
			return oldNamecall(self, ...)
		end
		local args = { ... }
		local origin = args[1]
		local direction = args[castIndex]
		if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 80 then
			return oldNamecall(self, ...)
		end
		local camera = workspace.CurrentCamera
		if camera ~= nil and direction.Unit:Dot(camera.CFrame.LookVector) < 0.65 then
			return oldNamecall(self, ...)
		end
		args[castIndex] = goal - origin
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
		local packed = {
			enabled = module.enabled,
			key = if module.key then module.key.Name else nil,
			fov = module.fov,
			value = module.value,
		}
		if module.options then
			for _, option in module.options do
				local value = module[option.field]
				if typeof(value) == "Color3" then
					packed[option.field] = {
						math.floor(value.R * 255 + 0.5),
						math.floor(value.G * 255 + 0.5),
						math.floor(value.B * 255 + 0.5),
					}
				else
					packed[option.field] = value
				end
			end
		end
		data.modules[id] = packed
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
				if module.options then
					for _, option in module.options do
						local savedValue = saved[option.field]
						if option.kind == "number" and type(savedValue) == "number" then
							local minValue = option.min or module.min
							local maxValue = option.max or module.max
							if minValue and maxValue then
								savedValue = math.clamp(savedValue, minValue, maxValue)
							end
							module[option.field] = savedValue
						elseif option.kind == "bool" and type(savedValue) == "boolean" then
							module[option.field] = savedValue
						elseif option.kind == "choice" and type(savedValue) == "string" then
							for _, choice in option.choices do
								if choice == savedValue then
									module[option.field] = savedValue
									break
								end
							end
						elseif option.kind == "color" and type(savedValue) == "table" then
							local r, g, b = savedValue[1], savedValue[2], savedValue[3]
							if type(r) == "number" and type(g) == "number" and type(b) == "number" then
								module[option.field] = Color3.fromRGB(r, g, b)
							end
						end
					end
				end
			end
		end
	end
	rememberScriptCopy()
	if modules.fly.value <= 160 then
		modules.fly.value = 300
	end
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
