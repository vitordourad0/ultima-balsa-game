local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local channel = ReplicatedStorage:WaitForChild("FerryRace")
local state = { phase = "ready", checkpoint = 0, startedAt = 0, finishedIn = 0, best = 0 }
local awaitingRestart = false

local ink = Color3.fromRGB(14, 30, 43)
local white = Color3.fromRGB(244, 250, 252)
local muted = Color3.fromRGB(182, 219, 230)
local aqua = Color3.fromRGB(116, 238, 220)
local amber = Color3.fromRGB(255, 215, 129)

local function ui(className, properties, parent)
	local object = Instance.new(className)
	for key, value in properties do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function corners(parent, radius)
	ui("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function label(parent, name, position, size, color, font, textSize)
	return ui("TextLabel", {
		Name = name,
		BackgroundTransparency = 1,
		Position = position,
		Size = size,
		TextColor3 = color,
		Font = font,
		TextSize = textSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}, parent)
end

local gui = ui("ScreenGui", {
	Name = "UltimaBalsa",
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
}, player:WaitForChild("PlayerGui"))

local panel = ui("Frame", {
	Name = "Corrida",
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 0, 104),
	BackgroundColor3 = ink,
	BackgroundTransparency = 0.08,
}, gui)
ui("UISizeConstraint", { MaxSize = Vector2.new(250, 104) }, panel)
corners(panel, 14)
ui("UIStroke", { Color = aqua, Transparency = 0.55, Thickness = 1 }, panel)

local timeLabel = label(panel, "Tempo", UDim2.fromOffset(12, 5), UDim2.fromOffset(123, 35), white, Enum.Font.RobotoMono, 25)
local bestLabel = label(panel, "Melhor", UDim2.fromOffset(126, 8), UDim2.new(1, -135, 0, 27), aqua, Enum.Font.GothamMedium, 13)
local status = label(panel, "Progresso", UDim2.fromOffset(12, 49), UDim2.new(1, -121, 0, 44), muted, Enum.Font.GothamBold, 13)
status.TextWrapped = true

local restart = ui("TextButton", {
	Name = "Reiniciar",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 48),
	Size = UDim2.fromOffset(96, 46),
	BackgroundColor3 = aqua,
	Font = Enum.Font.GothamBold,
	TextColor3 = ink,
	TextSize = 13,
	Text = "Reiniciar",
}, panel)
corners(restart, 9)

local function formatTime(seconds)
	local hundredths = math.floor(math.max(0, seconds) * 100)
	return string.format("%02d:%02d.%02d", math.floor(hundredths / 6000), math.floor(hundredths / 100) % 60, hundredths % 100)
end

local function refreshLabels()
	bestLabel.Text = "Melhor  " .. (state.best > 0 and formatTime(state.best) or "—")
	status.TextColor3 = muted
	if state.phase == "ready" then
		status.Text = "Atravesse a linha para largar"
	elseif state.phase == "finished" then
		status.TextColor3 = amber
		status.Text = "Você chegou à balsa!"
	elseif state.hint then
		status.TextColor3 = amber
		status.Text = "Seguro à direita\nAtalho em frente"
	else
		status.Text = string.format("Checkpoints  %d/3", state.checkpoint)
	end
	restart.Text = state.phase == "finished" and "Correr de novo" or "Reiniciar"
end

local function updateTimer()
	local elapsed = state.finishedIn
	if state.phase == "running" then
		elapsed = workspace:GetServerTimeNow() - state.startedAt
	end
	timeLabel.Text = formatTime(elapsed)
end

local function requestRestart()
	if awaitingRestart then
		return
	end
	awaitingRestart = true
	channel:FireServer("Restart")
	task.delay(0.65, function()
		awaitingRestart = false
	end)
end

restart.Activated:Connect(requestRestart)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		requestRestart()
	end
end)
channel.OnClientEvent:Connect(function(snapshot)
	state = snapshot
	refreshLabels()
	updateTimer()
end)
RunService.RenderStepped:Connect(updateTimer)
refreshLabels()
updateTimer()
channel:FireServer("Sync")
