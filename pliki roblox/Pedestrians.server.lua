-- Script: ServerScriptService > Pedestrians
-- Przechodnie chodzą po chodnikach i przechodzą przez pasy, można z nimi rozmawiać (E), a przejechanie ich autem = zabicie
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Chat = game:GetService("Chat")

local C = require(SSS:WaitForChild("CityConfig"))
local Wanted = require(SSS:WaitForChild("Wanted"))
local P, N = C.PITCH, C.N

local folder = Instance.new("Folder"); folder.Name = "Pedestrians"; folder.Parent = workspace

local LINES = {}
for k = 1, N - 1 do table.insert(LINES, k * P + 26); table.insert(LINES, k * P + 62) end

local SAY = {
	"Cześć! Miasto jest super, prawda?", "Monety leżą na ulicach, zbieraj je!", "Uważaj na policję.",
	"Podobno wkrótce będzie tryb SkyWars!", "Mam dziś wolne, spaceruję.", "Salon aut jest przy głównym skrzyżowaniu.",
	"Wieczorem miasto wygląda świetnie.",
}

local function newPed()
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = Color3.fromRGB(241, 194, 125)
	d.TorsoColor = Color3.fromHSV(math.random(), 0.6, 0.8)
	d.LeftArmColor = d.HeadColor; d.RightArmColor = d.HeadColor
	d.LeftLegColor = Color3.fromRGB(44, 62, 80); d.RightLegColor = Color3.fromRGB(44, 62, 80)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then return nil end
	model.Name = "Pedestrian"
	local hum = model:WaitForChild("Humanoid")
	hum.WalkSpeed = 8 + math.random() * 3
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	return model
end

local spawnPed

local function walk(model)
	local hum = model:WaitForChild("Humanoid")
	local hrp = model:WaitForChild("HumanoidRootPart")
	local axis = math.random(0, 1)
	local line = LINES[math.random(#LINES)]
	local dir = (math.random() < 0.5) and 1 or -1
	local a = 90 + math.random() * 350
	local x, z
	if axis == 0 then x, z = a, line else x, z = line, a end
	model:PivotTo(CFrame.new(x, 4, z))
	model.Parent = folder

	-- rozmowa
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Porozmawiaj"; pp.MaxActivationDistance = 8; pp.RequiresLineOfSight = false; pp.Parent = hrp
	local lastTip = 0
	pp.Triggered:Connect(function(plr)
		if hum.Health <= 0 then return end
		local speed = hum.WalkSpeed
		hum.WalkSpeed = 0
		local text = SAY[math.random(#SAY)]
		if os.clock() - lastTip > 30 and math.random() < 0.35 then
			lastTip = os.clock()
			local cash = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Cash")
			if cash then cash.Value = cash.Value + 10; text = text .. " (+10 $ napiwek)" end
		end
		local head = model:FindFirstChild("Head")
		if head then Chat:Chat(head, text, Enum.ChatColor.White) end
		task.delay(3, function() if hum.Health > 0 then hum.WalkSpeed = speed end end)
	end)

	hum.Died:Connect(function()
		task.delay(10, function() model:Destroy(); spawnPed() end)
	end)

	while model.Parent and hum.Health > 0 do
		local nxt
		for _, v in ipairs(LINES) do
			if dir > 0 and v > a + 1 and (not nxt or v < nxt) then nxt = v
			elseif dir < 0 and v < a - 1 and (not nxt or v > nxt) then nxt = v end
		end
		if not nxt then
			dir = -dir
		else
			local tx = (axis == 0) and nxt or line
			local tz = (axis == 0) and line or nxt
			hum:MoveTo(Vector3.new(tx, 3, tz))
			hum.MoveToFinished:Wait()
			a = (axis == 0) and hrp.Position.X or hrp.Position.Z
			if math.abs(a - nxt) < 6 then a = nxt end
			if math.random() < 0.45 then
				local old = line
				axis = 1 - axis
				line = nxt
				a = old
				dir = (math.random() < 0.5) and 1 or -1
			end
		end
		task.wait(0.05)
	end
end

spawnPed = function()
	local m = newPed()
	if m then task.spawn(walk, m) end
end

for _ = 1, 30 do
	task.spawn(spawnPed)
	task.wait(0.1)
end

-- przejechanie przechodnia autem gracza
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local seat = hum and hum.SeatPart
			if seat and seat.AssemblyLinearVelocity.Magnitude > 24 then
				local sp = seat.Position
				for _, m in ipairs(folder:GetChildren()) do
					local ph = m:FindFirstChildOfClass("Humanoid")
					local hrp = m:FindFirstChild("HumanoidRootPart")
					if ph and hrp and ph.Health > 0 and (hrp.Position - sp).Magnitude < 9 then
						ph.Health = 0
						Wanted.kill(plr, hrp.Position, "car", m)
					end
				end
			end
		end
	end
end)
