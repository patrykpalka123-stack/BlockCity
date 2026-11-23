-- Script: ServerScriptService > Traffic
-- Światła, ruch uliczny (jazda prawą stroną, skręty, czerwone światło, hamowanie przed przeszkodą),
-- patrole policji, pościg i zatrzymanie gracza
local SSS = game:GetService("ServerScriptService")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local C = require(SSS:WaitForChild("CityConfig"))
local Wanted = require(SSS:WaitForChild("Wanted"))
local P, N, DIRS = C.PITCH, C.N, C.DIRS
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local city = workspace:WaitForChild("City")
local lightsF = city:WaitForChild("Lights")
local carsF = Instance.new("Folder"); carsF.Name = "TrafficCars"; carsF.Parent = workspace
local pedsF = workspace:WaitForChild("Pedestrians", 30)

-- ===== światła =====
local ON = { r = rgb(255, 40, 40), y = rgb(255, 200, 0), g = rgb(40, 230, 90) }
local OFF = { r = rgb(70, 10, 10), y = rgb(70, 55, 0), g = rgb(10, 60, 25) }
task.spawn(function()
	while true do
		for _, m in ipairs(lightsF:GetChildren()) do
			local st = C.lightOf(m:GetAttribute("Axis"))
			for key, name in pairs({ r = "R", y = "Y", g = "G" }) do
				local lp = m:FindFirstChild(name)
				if lp then
					local on = (st == key)
					lp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
					lp.Color = on and ON[key] or OFF[key]
				end
			end
		end
		task.wait(0.25)
	end
end)

-- ===== modele aut =====
-- Wrzuć własne modele (z Toolboxa) do ServerStorage > TrafficCars (cywilne) i ServerStorage > PoliceCar.
-- Przód modelu musi być zwrócony w stronę -Z, a model musi mieć PrimaryPart.
-- Gdy folderów nie ma, skrypt buduje zastępcze (proste) auta.
local function placeholder(col, police)
	local m = Instance.new("Model"); m.Name = police and "Police" or "Car"
	local function part(n, size, cf, c, mat, shape)
		local p = Instance.new("Part")
		p.Name = n; p.Size = size; p.CFrame = cf; p.Color = c; p.Anchored = true; p.CanCollide = false
		p.Material = mat or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Parent = m
		return p
	end
	local body = part("Body", Vector3.new(7.4, 2.4, 17), CFrame.new(0, 0, 0), col)
	part("Cabin", Vector3.new(6.4, 2, 8.5), CFrame.new(0, 2.1, 1.6), rgb(30, 40, 55), Enum.Material.Glass)
	for _, x in ipairs({ -3.7, 3.7 }) do
		for _, z in ipairs({ -5.2, 5.2 }) do
			part("Wheel", Vector3.new(1.8, 2.6, 2.6), CFrame.new(x, -1.1, z), rgb(20, 20, 20), nil, Enum.PartType.Cylinder)
		end
	end
	for _, x in ipairs({ -2.6, 2.6 }) do
		part("Head", Vector3.new(1.6, 0.8, 0.3), CFrame.new(x, 0.2, -8.6), rgb(255, 246, 214), Enum.Material.Neon)
		part("Tail", Vector3.new(1.6, 0.8, 0.3), CFrame.new(x, 0.2, 8.6), rgb(204, 16, 16), Enum.Material.Neon)
	end
	if police then
		part("SirenR", Vector3.new(1.6, 0.6, 1), CFrame.new(-1, 3.4, 1.6), rgb(255, 32, 32), Enum.Material.Neon)
		part("SirenB", Vector3.new(1.6, 0.6, 1), CFrame.new(1, 3.4, 1.6), rgb(32, 96, 255), Enum.Material.Neon)
		part("Stripe", Vector3.new(7.5, 0.8, 8), CFrame.new(0, 0.3, 0), rgb(12, 12, 14))
	end
	m.PrimaryPart = body
	return m
end

local CCOL = { rgb(27, 27, 31), rgb(218, 221, 226), rgb(138, 28, 28), rgb(31, 63, 120), rgb(58, 63, 70), rgb(255, 255, 255), rgb(47, 107, 59), rgb(176, 180, 186) }
local function newModel(police)
	local m
	local folder = police and SS:FindFirstChild("PoliceCar") or SS:FindFirstChild("TrafficCars")
	if folder then
		local list = folder:IsA("Model") and { folder } or folder:GetChildren()
		if #list > 0 then m = list[math.random(#list)]:Clone() end
	end
	if not m then m = placeholder(police and rgb(244, 244, 244) or CCOL[math.random(#CCOL)], police) end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
	end
	if not m.PrimaryPart then m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true) end
	m:SetAttribute("Police", police)
	m.Parent = carsF
	return m
end

-- ===== stan aut =====
local cars = {}
local people = {}  -- pozycje graczy i przechodniów (przeszkody)
local SEG = P - 24

local function segPos(c)
	local ex, ez = C.exitPt(c.d, c.k, c.l)
	local dd = DIRS[c.d + 1]
	c.x = ex + dd[1] * c.s; c.z = ez + dd[2] * c.s
	c.ang = math.atan2(dd[1], dd[2])
end

local function place(c)
	for _ = 1, 40 do
		local k, l, d = math.random(1, N), math.random(1, N), math.random(0, 3)
		local dd = DIRS[d + 1]
		if C.okI(k + dd[1], l + dd[2]) then
			c.k, c.l, c.d, c.s = k, l, d, math.random() * 30
			c.st = "seg"; c.v = 0; c.mode = "patrol"; c.stuck = 0
			segPos(c)
			return
		end
	end
end

local function enterInt(c)
	local dd = DIRS[c.d + 1]
	local nk, nl = c.k + dd[1], c.l + dd[2]
	local opts = {}
	for _, d2 in ipairs({ c.d, c.d, (c.d + 1) % 4, (c.d + 3) % 4 }) do
		local e = DIRS[d2 + 1]
		if C.okI(nk + e[1], nl + e[2]) then table.insert(opts, d2) end
	end
	if #opts == 0 then place(c); return end
	local d2 = opts[math.random(#opts)]
	local p0x, p0z = C.entryPt(c.d, nk, nl)
	local p2x, p2z = C.exitPt(d2, nk, nl)
	local cx, cz
	if d2 == c.d then
		cx, cz = (p0x + p2x) / 2, (p0z + p2z) / 2
	elseif c.d % 2 == 0 then
		cx, cz = C.laneC(d2, nk, nl), p0z
	else
		cx, cz = p0x, C.laneC(d2, nk, nl)
	end
	c.bz = { p0x, p0z, cx, cz, p2x, p2z }
	c.ik, c.il, c.d2, c.t = nk, nl, d2, 0
	if d2 == c.d then
		c.len = 24
	else
		c.len = (math.sqrt((cx - p0x) ^ 2 + (cz - p0z) ^ 2) + math.sqrt((p2x - cx) ^ 2 + (p2z - cz) ^ 2)) * 0.85
	end
	c.st = "int"
end

local function ahead(c, x, z, hx, hz)
	local best = 99999
	local function chk(ox, oz, w)
		local dx, dz = ox - x, oz - z
		local f = dx * hx + dz * hz
		if f > 1.2 and f < best and math.abs(dx * hz - dz * hx) < w then best = f end
	end
	for _, o in ipairs(cars) do if o ~= c then chk(o.x, o.z, 7) end end
	for _, o in ipairs(people) do chk(o[1], o[2], 4.5) end
	return best
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function targetPlayer(c)
	local best, bd
	for _, plr in ipairs(Players:GetPlayers()) do
		if Wanted.get(plr) > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local p = plr.Character.HumanoidRootPart.Position
			local d = (p.X - c.x) ^ 2 + (p.Z - c.z) ^ 2
			if not bd or d < bd then best, bd = plr, d end
		end
	end
	return best
end

local function chase(c, dt)
	local plr = targetPlayer(c)
	if not plr then return end
	local hrp = plr.Character.HumanoidRootPart
	local dx, dz = hrp.Position.X - c.x, hrp.Position.Z - c.z
	local dist = math.sqrt(dx * dx + dz * dz)
	local da = math.atan2(dx, dz) - c.ang
	while da > math.pi do da = da - 2 * math.pi end
	while da < -math.pi do da = da + 2 * math.pi end
	c.ang = c.ang + math.max(-2.2 * dt, math.min(2.2 * dt, da))
	local tv
	if dist < 16 then tv = 0 elseif dist < 56 then tv = math.min(c.cruise2, 20 + dist * 0.6) else tv = c.cruise2 end
	if c.v < tv then c.v = math.min(tv, c.v + 28 * dt) else c.v = math.max(tv, c.v - 64 * dt) end
	local sn, co = math.sin(c.ang), math.cos(c.ang)
	rayParams.FilterDescendantsInstances = { carsF, pedsF, plr.Character }
	local hit = workspace:Raycast(Vector3.new(c.x, 3, c.z), Vector3.new(sn, 0, co) * 16, rayParams)
	if hit and hit.Instance.CanCollide then
		c.v = c.v * 0.6
		c.ang = c.ang + (c.turnDir or 1) * 1.8 * dt
		if math.random() < 0.03 then c.turnDir = -(c.turnDir or 1) end
	else
		c.x = c.x + sn * c.v * dt
		c.z = c.z + co * c.v * dt
	end
end

local function step(c, dt)
	if c.mode == "chase" then chase(c, dt); return end
	local x, z, hx, hz
	if c.st == "seg" then
		local ex, ez = C.exitPt(c.d, c.k, c.l)
		local dd = DIRS[c.d + 1]
		hx, hz = dd[1], dd[2]
		x, z = ex + hx * c.s, ez + hz * c.s
	else
		local b, t = c.bz, c.t
		local u = 1 - t
		x = u * u * b[1] + 2 * u * t * b[3] + t * t * b[5]
		z = u * u * b[2] + 2 * u * t * b[4] + t * t * b[6]
		hx = 2 * u * (b[3] - b[1]) + 2 * t * (b[5] - b[3])
		hz = 2 * u * (b[4] - b[2]) + 2 * t * (b[6] - b[4])
		local hl = math.sqrt(hx * hx + hz * hz)
		if hl == 0 then hl = 1 end
		hx, hz = hx / hl, hz / hl
	end
	c.x, c.z, c.ang = x, z, math.atan2(hx, hz)
	local tv = c.cruise
	if c.st == "seg" then
		local ds = 29 - c.s
		if C.lightOf(c.d) ~= "g" and ds > -1.2 then
			tv = math.min(tv, (ds < 0.4) and 0 or math.sqrt(48 * ds))
		end
	end
	local gap = ahead(c, x, z, hx, hz) - 20
	if gap < 36 then tv = math.min(tv, math.max(0, gap * 1.1)) end
	if c.v < tv then c.v = math.min(tv, c.v + 20 * dt) else c.v = math.max(tv, c.v - 56 * dt) end
	if c.v < 0.8 then c.stuck = c.stuck + dt else c.stuck = 0 end
	if c.stuck > 25 then place(c); return end
	if c.st == "seg" then
		c.s = c.s + c.v * dt
		if c.s >= SEG then enterInt(c) end
	else
		c.t = c.t + c.v * dt / c.len
		if c.t >= 1 then c.k, c.l, c.d, c.s, c.st = c.ik, c.il, c.d2, 0, "seg" end
	end
end

local function spawnCar(police)
	local model = newModel(police)
	local c = { model = model, police = police, cruise = police and 36 or (26 + math.random() * 10), v = 0, x = 0, z = 0, ang = 0, stuck = 0, turnDir = 1, mode = "patrol", half = model:GetExtentsSize().Y / 2 }
	place(c)
	table.insert(cars, c)
end
for _ = 1, 14 do spawnCar(false) end
for _ = 1, 4 do spawnCar(true) end

-- ===== zatrzymanie gracza =====
local bustT, lostT = {}, {}
local function busted(plr)
	local cash = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Cash")
	if cash then cash.Value = math.max(0, cash.Value - 5000) end
	Wanted.clear(plr)
	bustT[plr], lostT[plr] = 0, 0
	local char = plr.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = false end
		char:PivotTo(CFrame.new(C.SPAWN))
	end
	Wanted.notify(plr, "ZŁAPANY! Mandat 5 000 $")
	for _, c in ipairs(cars) do
		if c.police and c.mode == "chase" then place(c) end
	end
end

-- ===== pętla główna =====
local flash = 0
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.1)
	-- przeszkody: gracze i przechodnie
	table.clear(people)
	local anyWanted, maxW = false, 0
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then table.insert(people, { hrp.Position.X, hrp.Position.Z }) end
		local w = Wanted.get(plr)
		if w > 0 then anyWanted = true; maxW = math.max(maxW, w) end
	end
	if pedsF then
		for _, m in ipairs(pedsF:GetChildren()) do
			local hrp = m:FindFirstChild("HumanoidRootPart")
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then table.insert(people, { hrp.Position.X, hrp.Position.Z }) end
		end
	end

	-- tryb pościgu / patrolu
	for _, c in ipairs(cars) do
		if c.police then
			if anyWanted then
				c.cruise2 = 44 + 10 * maxW
				if c.mode ~= "chase" then c.mode = "chase"; c.v = math.min(c.v, 20) end
				local plr = targetPlayer(c)
				if plr then
					local hp = plr.Character.HumanoidRootPart.Position
					if (hp.X - c.x) ^ 2 + (hp.Z - c.z) ^ 2 > 360 * 360 then
						for _ = 1, 14 do
							local x = P * math.random(1, N) + 12
							local z = P * math.random(1, N) + 12
							local d = math.sqrt((x - hp.X) ^ 2 + (z - hp.Z) ^ 2)
							if d > 120 and d < 280 then c.x, c.z, c.v = x, z, 0; c.ang = math.atan2(hp.X - x, hp.Z - z); break end
						end
					end
				end
			elseif c.mode == "chase" then
				place(c)
			end
		end
	end

	for _, c in ipairs(cars) do step(c, dt) end

	-- ustaw modele
	flash = flash + dt
	local f = (math.floor(flash * 5) % 2) == 0
	for _, c in ipairs(cars) do
		local y = (c.mode == "chase" and 0.9 or 0.2) + c.half
		local pos = Vector3.new(c.x, y, c.z)
		c.model:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(math.sin(c.ang), 0, math.cos(c.ang))))
		if c.police then
			local r, b = c.model:FindFirstChild("SirenR", true), c.model:FindFirstChild("SirenB", true)
			if r then r.Color = f and rgb(255, 32, 32) or rgb(60, 10, 10) end
			if b then b.Color = f and rgb(10, 20, 70) or rgb(32, 96, 255) end
		end
	end

	-- zatrzymanie i gubienie policji
	for _, plr in ipairs(Players:GetPlayers()) do
		if Wanted.get(plr) > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = plr.Character.HumanoidRootPart
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local seat = hum and hum.SeatPart
			local speed = seat and seat.AssemblyLinearVelocity.Magnitude or 0
			local near, seen = false, false
			for _, c in ipairs(cars) do
				if c.police then
					local d = math.sqrt((c.x - hrp.Position.X) ^ 2 + (c.z - hrp.Position.Z) ^ 2)
					if d < 14 then near = true end
					if d < 240 then seen = true end
				end
			end
			if near and speed < 28 then bustT[plr] = (bustT[plr] or 0) + dt else bustT[plr] = math.max(0, (bustT[plr] or 0) - dt) end
			if bustT[plr] > 1.6 then busted(plr)
			else
				if seen then lostT[plr] = 0 else lostT[plr] = (lostT[plr] or 0) + dt end
				if lostT[plr] > 14 then
					Wanted.clear(plr); lostT[plr] = 0
					Wanted.notify(plr, "Zgubiłeś policję")
				end
			end
		end
	end
end)
