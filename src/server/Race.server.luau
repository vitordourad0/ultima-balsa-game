local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Run = require(script.Parent.Run)
local markers = workspace:WaitForChild("Porto"):WaitForChild("RaceMarkers")
local checkpoints = {
	markers:WaitForChild("Checkpoint1"),
	markers:WaitForChild("Checkpoint2"),
	markers:WaitForChild("Checkpoint3"),
}
local resetPoints = {
	[0] = markers:WaitForChild("Spawn0"),
	markers:WaitForChild("Spawn1"),
	markers:WaitForChild("Spawn2"),
	markers:WaitForChild("Spawn3"),
}
local startGate = markers:WaitForChild("Start")
local finishGate = markers:WaitForChild("Finish")

local collisionGroup = "FerryRunners"
if not PhysicsService:IsCollisionGroupRegistered(collisionGroup) then
	PhysicsService:RegisterCollisionGroup(collisionGroup)
end
PhysicsService:CollisionGroupSetCollidable(collisionGroup, collisionGroup, false)

local channel = Instance.new("RemoteEvent")
channel.Name = "FerryRace"

local sessions = {}
local studio = RunService:IsStudio()

local function report(player, attempt, name, milestone)
	local fields = {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = attempt == 1 and "first_attempt" or "repeat_attempt",
		[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = milestone,
	}
	if studio then
		print(string.format("[UltimaBalsa] %s player=%d attempt=%d %s", name, player.UserId, attempt, milestone))
		return
	end

	-- Log every attempt. CustomField02 also isolates each player's first
	-- occurrence of each milestone in this server session.
	local ok, reason = pcall(function()
		AnalyticsService:LogCustomEvent(player, name, 1, fields)
	end)
	if not ok then
		warn("[UltimaBalsa] Analytics", name, reason)
	end
end

local function record(player, session, name)
	local milestone = session.seen[name] and "repeat_in_session" or "first_in_session"
	session.seen[name] = true
	task.defer(report, player, session.run.attempts, name, milestone)
end

local function funnel(player, session, step, label)
	if studio then
		return
	end
	local id = session.funnelId
	task.defer(function()
		local ok, reason = pcall(function()
			AnalyticsService:LogFunnelStepEvent(player, "UltimaBalsa_Run", id, step, label)
		end)
		if not ok then
			warn("[UltimaBalsa] Funnel", label, reason)
		end
	end)
end

local function publish(player, session)
	local state = session.run
	channel:FireClient(player, {
		phase = state.phase,
		checkpoint = state.checkpoint,
		startedAt = state.startedAt,
		finishedIn = state.finishedIn,
		best = state.best,
		hint = session.hint,
	})
end

local function inside(part, position)
	local relative = part.CFrame:PointToObjectSpace(position)
	local half = part.Size * 0.5
	return math.abs(relative.X) <= half.X and math.abs(relative.Y) <= half.Y and math.abs(relative.Z) <= half.Z
end

local function returnToRoof(session, character, root)
	local destination = resetPoints[session.run.checkpoint]
	character:PivotTo(destination.CFrame)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	session.lastPosition = nil
	session.hint = nil
end

local function onCharacter(player, session, character)
	if session.characterConnection then
		session.characterConnection:Disconnect()
	end
	session.characterConnection = character.DescendantAdded:Connect(function(object)
		if object:IsA("BasePart") then
			object.CollisionGroup = collisionGroup
		end
	end)
	for _, object in character:GetDescendants() do
		if object:IsA("BasePart") then
			object.CollisionGroup = collisionGroup
		end
	end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or sessions[player] ~= session or player.Character ~= character then
		return
	end
	returnToRoof(session, character, root)
	publish(player, session)
end

local function onPlayer(player)
	if sessions[player] then
		return
	end
	local session = {
		run = Run.new(),
		seen = {},
		lastRestart = -math.huge,
		lastSync = -math.huge,
	}
	sessions[player] = session
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, session, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, session, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session and session.characterConnection then
		session.characterConnection:Disconnect()
	end
	sessions[player] = nil
end)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

channel.OnServerEvent:Connect(function(player, action)
	local session = sessions[player]
	if not session then
		return
	end
	local now = workspace:GetServerTimeNow()
	if action == "Sync" and now - session.lastSync >= 1 then
		session.lastSync = now
		publish(player, session)
	elseif action == "Restart" and now - session.lastRestart >= 0.5 then
		session.lastRestart = now
		Run.restart(session.run)
		session.lastPosition = nil
		session.hint = nil
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			returnToRoof(session, character, root)
		end
		publish(player, session)
	end
end)
channel.Parent = ReplicatedStorage

local fork = markers:WaitForChild("Fork")

RunService.Heartbeat:Connect(function()
	local now = workspace:GetServerTimeNow()
	for player, session in sessions do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local position = root.Position
		local state = session.run
		if position.Y < 8 then
			returnToRoof(session, character, root)
			publish(player, session)
			continue
		end

		local previous = session.lastPosition
		session.lastPosition = position
		if state.phase == "ready" then
			-- The line is crossed toward the ferry, even when a frame straddles it.
			if previous and previous.Z > startGate.Position.Z and position.Z <= startGate.Position.Z then
				local alpha = (startGate.Position.Z - previous.Z) / (position.Z - previous.Z)
				if inside(startGate, previous:Lerp(position, alpha)) and Run.start(state, now) then
					session.funnelId = HttpService:GenerateGUID(false)
					record(player, session, "RaceStarted")
					if state.attempts > 1 then
						record(player, session, "RaceRetried")
					end
					funnel(player, session, 1, "Largada")
					publish(player, session)
				end
			end
		elseif state.phase == "running" then
			local nextCheckpoint = state.checkpoint + 1
			local gate = checkpoints[nextCheckpoint]
			if gate and inside(gate, position) and Run.checkpoint(state, nextCheckpoint) then
				if nextCheckpoint == 1 then
					record(player, session, "RaceCheckpoint1")
					funnel(player, session, 2, "Checkpoint 1")
				end
				publish(player, session)
			elseif not gate and inside(finishGate, position) and Run.finish(state, now) then
				record(player, session, "RaceFinished")
				funnel(player, session, 3, "Chegada")
				publish(player, session)
			end

			local hint = state.phase == "running" and state.checkpoint == 1 and inside(fork, position) or nil
			if hint ~= session.hint then
				session.hint = hint
				publish(player, session)
			end
		end
	end
end)
