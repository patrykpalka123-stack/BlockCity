-- Script: ServerScriptService > CityGenerator
-- Buduje miasto: drogi, pasy, przejścia, chodniki, budynki z oknami, latarnie, światła, znaki, sklepy, dzień i noc
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local C = require(SSS:WaitForChild("CityConfig"))

local P, N = C.PITCH, C.N
local T = (N + 1) * P
local rng = Random.new(7)
local V3 = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local city = Instance.new("Folder"); city.Name = "City"; city.Parent = workspace
local lightsF = Instance.new("Folder"); lightsF.Name = "Lights"; lightsF.Parent = city
local shopsF = Instance.new("Folder"); shopsF.Name = "Shops"; shopsF.Parent = city
local mini = Instance.new("Folder"); mini.Name = "MiniMap"   -- uproszczona kopia dla minimapy

local function mk(parent, name, size, pos, mat, col, collide, miniToo)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true; p.Size = size; p.Position = pos
	p.Material = mat; p.Color = col
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if collide == false then p.CanCollide = false; p.CastShadow = false end
	p.Parent = parent
	if miniToo then local c = p:Clone(); c.Parent = mini end
	return p
end

-- teren, jezdnie
mk(city, "Ground", V3(T + 400, 1, T + 400), V3(T / 2, -0.5, T / 2), Enum.Material.Grass, rgb(86, 140, 64), true, true)
for k = 1, N do
	mk(city, "RoadZ", V3(24, 0.2, T), V3(k * P + 12, 0.1, T / 2), Enum.Material.Asphalt, rgb(55, 57, 62), true, true)
	mk(city, "RoadX", V3(T, 0.2, 24), V3(T / 2, 0.11, k * P + 12), Enum.Material.Asphalt, rgb(55, 57, 62), true, true)
end

-- podwójna żółta linia środkowa
local YEL, WHT = rgb(235, 185, 30), rgb(236, 236, 232)
for k = 1, N do
	for l = 1, N - 1 do
		for _, off in ipairs({ -0.5, 0.5 }) do
			mk(city, "LineZ", V3(0.4, 0.05, 24), V3(k * P + 12 + off, 0.24, l * P + 44), Enum.Material.SmoothPlastic, YEL, false)
			mk(city, "LineX", V3(24, 0.05, 0.4), V3(l * P + 44, 0.25, k * P + 12 + off), Enum.Material.SmoothPlastic, YEL, false)
		end
	end
end

-- przejścia dla pieszych (pasy równoległe do kierunku jazdy)
local function zebraZ(k, zc)
	for i = 0, 5 do mk(city, "Zebra", V3(2, 0.05, 6), V3(k * P + 2 + 4 * i, 0.26, zc), Enum.Material.SmoothPlastic, WHT, false) end
end
local function zebraX(l, xc)
	for i = 0, 5 do mk(city, "Zebra", V3(6, 0.05, 2), V3(xc, 0.27, l * P + 2 + 4 * i), Enum.Material.SmoothPlastic, WHT, false) end
end
for k = 1, N do
	for l = 1, N do
		if l > 1 then zebraZ(k, l * P - 3) end
		if l < N then zebraZ(k, l * P + 27) end
		if k > 1 then zebraX(l, k * P - 3) end
		if k < N then zebraX(l, k * P + 27) end
	end
end

-- latarnie, znaki, drzewa
local lamps = {}
local function lamp(x, z)
	mk(city, "Pole", V3(0.6, 18, 0.6), V3(x, 0.8 + 9, z), Enum.Material.Metal, rgb(70, 74, 80), true, false)
	local h = mk(city, "LampHead", V3(3, 0.6, 1.6), V3(x, 0.8 + 18, z), Enum.Material.SmoothPlastic, rgb(255, 244, 200), false, false)
	local pl = Instance.new("PointLight")
	pl.Range = 40; pl.Brightness = 1.5; pl.Color = rgb(255, 226, 160); pl.Enabled = false; pl.Parent = h
	table.insert(lamps, { h = h, l = pl })
end

local function sign(x, z, kind, ry)
	mk(city, "SignPole", V3(0.5, 10, 0.5), V3(x, 0.8 + 5, z), Enum.Material.Metal, rgb(70, 74, 80), true, false)
	local isStop = (kind == "STOP")
	local s = mk(city, "Sign", V3(3.4, 3.4, 0.3), V3(x, 0.8 + 10.5, z), Enum.Material.SmoothPlastic,
		isStop and rgb(200, 30, 30) or rgb(245, 245, 245), false, false)
	s.Orientation = V3(0, ry, 0)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local g = Instance.new("SurfaceGui"); g.Face = face; g.Parent = s
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = kind; t.TextScaled = true
		t.Font = Enum.Font.GothamBold
		t.TextColor3 = isStop and rgb(255, 255, 255) or rgb(200, 30, 30)
		t.Parent = g
	end
end

local function tree(x, z)
	mk(city, "Trunk", V3(1.6, 10, 1.6), V3(x, 0.8 + 5, z), Enum.Material.Wood, rgb(100, 70, 40), true, false)
	local l = mk(city, "Leaves", V3(10, 10, 10), V3(x, 0.8 + 14, z), Enum.Material.Grass, rgb(50, 120, 50), false, false)
	l.Shape = Enum.PartType.Ball
end

-- okna
local function win(pos, size)
	local w = mk(city, "Window", size, pos, Enum.Material.Glass, rgb(120, 170, 210), false, false)
	w.Transparency = 0.25; w.Reflectance = 0.2
end

local STY = {
	{ mat = Enum.Material.Brick,         col = rgb(160, 80, 62),   base = rgb(122, 56, 42) },
	{ mat = Enum.Material.SmoothPlastic, col = rgb(40, 74, 104),   base = rgb(37, 64, 90) },
	{ mat = Enum.Material.Concrete,      col = rgb(205, 200, 188), base = rgb(170, 165, 152) },
	{ mat = Enum.Material.Sandstone,     col = rgb(231, 212, 166), base = rgb(184, 165, 122) },
}
local NAMES = { "KAWIARNIA", "APTEKA", "SKLEP", "PIEKARNIA", "BANK", "HOTEL", "PIZZERIA", "KWIACIARNIA" }

local function label(part, text, face)
	local g = Instance.new("SurfaceGui"); g.Face = face; g.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = text; t.TextScaled = true
	t.Font = Enum.Font.GothamBold; t.TextColor3 = rgb(255, 233, 168); t.Parent = g
end

local function building(k, l, x0, z0)
	local forced = (l == 4 and (k == 3 or k == 4))
	if (not forced) and rng:NextNumber() < 0.2 then
		for _ = 1, 3 do tree(x0 + 6 + rng:NextNumber(0, 28), z0 + 6 + rng:NextNumber(0, 28)) end
		return
	end
	local sizes = { 20, 24, 28 }
	local w = forced and 28 or sizes[rng:NextInteger(1, 3)]
	local d = forced and 28 or sizes[rng:NextInteger(1, 3)]
	local cx = x0 + 20 + (forced and 0 or rng:NextNumber(-(32 - w) / 2, (32 - w) / 2))
	local cz = z0 + 20 + (forced and 0 or rng:NextNumber(-(32 - d) / 2, (32 - d) / 2))
	local f = forced and 3 or rng:NextInteger(1, 6)
	local st = forced and (k == 4 and STY[1] or STY[3]) or STY[rng:NextInteger(1, 4)]
	local gh, fh = 16, 12
	local y0 = 0.8 + gh

	mk(city, "Base", V3(w, gh, d), V3(cx, 0.8 + gh / 2, cz), st.mat, st.base, true, true)
	mk(city, "Upper", V3(w, f * fh, d), V3(cx, y0 + f * fh / 2, cz), st.mat, st.col, true, true)
	mk(city, "Cornice", V3(w + 1.6, 1, d + 1.6), V3(cx, y0 + f * fh + 0.5, cz), Enum.Material.Concrete, rgb(208, 207, 203), true, false)
	mk(city, "AC", V3(5, 3, 4), V3(cx - w / 2 + 5, y0 + f * fh + 2.5, cz - d / 2 + 5), Enum.Material.Metal, rgb(138, 143, 150), false, false)
	if f >= 4 then
		mk(city, "Antenna", V3(0.3, 12, 0.3), V3(cx + w / 2 - 4, y0 + f * fh + 7, cz + d / 2 - 4), Enum.Material.Metal, rgb(50, 50, 50), false, false)
	end

	for fl = 0, f - 1 do
		local wy = y0 + fl * fh + fh / 2 + 0.5
		local nx = math.floor(w / 8)
		for i = 0, nx - 1 do
			local ox = -w / 2 + (i + 0.5) * (w / nx)
			win(V3(cx + ox, wy, cz - d / 2 - 0.05), V3(5, 6, 0.3))
			win(V3(cx + ox, wy, cz + d / 2 + 0.05), V3(5, 6, 0.3))
		end
		local nz = math.floor(d / 8)
		for i = 0, nz - 1 do
			local oz = -d / 2 + (i + 0.5) * (d / nz)
			win(V3(cx - w / 2 - 0.05, wy, cz + oz), V3(0.3, 6, 5))
			win(V3(cx + w / 2 + 0.05, wy, cz + oz), V3(0.3, 6, 5))
		end
	end

	-- parter: witryny, drzwi, markiza, szyld (front = strona -Z, do jezdni)
	local fz = cz - d / 2
	win(V3(cx - w * 0.3, 0.8 + 8, fz - 0.05), V3(w * 0.28, 8, 0.3))
	win(V3(cx + w * 0.3, 0.8 + 8, fz - 0.05), V3(w * 0.28, 8, 0.3))
	mk(city, "Door", V3(7, 12, 0.5), V3(cx, 0.8 + 6, fz - 0.1), Enum.Material.Wood, rgb(60, 45, 35), false, false)
	local aw = mk(city, "Awning", V3(w * 0.9, 0.6, 5), V3(cx, 0.8 + 14, fz - 2.2), Enum.Material.Fabric, rgb(192, 57, 43), false, false)
	aw.Orientation = V3(-12, 0, 0)
	local name = forced and (k == 4 and "SALON AUT" or "SKLEP Z BRONIĄ") or NAMES[rng:NextInteger(1, #NAMES)]
	local sg = mk(city, "Sign", V3(w * 0.6, 3.5, 0.3), V3(cx, y0 + 3.5, fz - 0.3), Enum.Material.SmoothPlastic, rgb(29, 33, 39), false, false)
	label(sg, name, Enum.NormalId.Front)

	if forced then
		local kind = (k == 4) and "car" or "gun"
		local ring = mk(shopsF, "Shop_" .. kind, V3(0.3, 9, 9), V3(cx, 0.9, fz - 7), Enum.Material.Neon, rgb(255, 210, 63), false, false)
		ring.Orientation = V3(0, 0, 90); ring.Shape = Enum.PartType.Cylinder; ring.Transparency = 0.5
		ring:SetAttribute("Shop", kind)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = (kind == "car") and "Wybierz auto" or "Kup broń"
		pp.ObjectText = name; pp.MaxActivationDistance = 12; pp.HoldDuration = 0; pp.RequiresLineOfSight = false
		pp.Parent = ring
	end
end

-- chodniki, latarnie, znaki, budynki (jeden "kwartał" = 40 x 40 studów)
for k = 1, N - 1 do
	for l = 1, N - 1 do
		local x0, z0 = k * P + 24, l * P + 24
		mk(city, "Sidewalk", V3(40, 0.8, 40), V3(x0 + 20, 0.4, z0 + 20), Enum.Material.Concrete, rgb(178, 176, 168), true, true)
		lamp(x0 + 20, z0 + 2); lamp(x0 + 20, z0 + 38); lamp(x0 + 2, z0 + 20); lamp(x0 + 38, z0 + 20)
		if (k + l) % 2 == 0 then sign(x0 + 2, z0 + 8, "STOP", 0) else sign(x0 + 38, z0 + 32, "30", 90) end
		building(k, l, x0, z0)
	end
end

-- sygnalizacja świetlna na rogach skrzyżowań (kolory ustawia skrypt Traffic)
for k = 1, N do
	for l = 1, N do
		local ix, iz = k * P + 12, l * P + 12
		local corners = { { k * P - 2, l * P - 2, 0 }, { k * P + 26, l * P + 26, 0 }, { k * P + 26, l * P - 2, 1 }, { k * P - 2, l * P + 26, 1 } }
		for _, c in ipairs(corners) do
			local x, z, ax = c[1], c[2], c[3]
			local m = Instance.new("Model"); m.Name = "Light"; m:SetAttribute("Axis", ax); m.Parent = lightsF
			mk(m, "Pole", V3(0.8, 16, 0.8), V3(x, 8, z), Enum.Material.Metal, rgb(70, 74, 80), true, false)
			mk(m, "Housing", V3(2.2, 6, 2.2), V3(x, 14, z), Enum.Material.SmoothPlastic, rgb(20, 20, 22), false, false)
			local dx = (ix - x > 0) and 1.3 or -1.3
			local dz = (iz - z > 0) and 1.3 or -1.3
			local cols = { R = rgb(70, 10, 10), Y = rgb(70, 55, 0), G = rgb(10, 60, 25) }
			local ys = { R = 15.8, Y = 14, G = 12.2 }
			for _, nm in ipairs({ "R", "Y", "G" }) do
				local b = mk(m, nm, V3(1.6, 1.6, 1.6), V3(x + dx, ys[nm], z + dz), Enum.Material.SmoothPlastic, cols[nm], false, false)
				b.Shape = Enum.PartType.Ball
			end
		end
	end
end

-- start
local sp = Instance.new("SpawnLocation")
sp.Name = "SpawnLocation"; sp.Anchored = true; sp.Size = V3(6, 1, 6); sp.Position = V3(C.SPAWN.X, 0.7, C.SPAWN.Z)
sp.Transparency = 1; sp.CanCollide = false; sp.Neutral = true; sp.Parent = workspace

mini.Parent = RS

-- dzień i noc (cykl 4 minuty), latarnie świecą nocą
Lighting.ClockTime = 12
task.spawn(function()
	while true do
		local dt = task.wait(1)
		Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / 240) % 24
		local night = Lighting.ClockTime < 6 or Lighting.ClockTime > 18
		for _, l in ipairs(lamps) do
			l.l.Enabled = night
			l.h.Material = night and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
end)
