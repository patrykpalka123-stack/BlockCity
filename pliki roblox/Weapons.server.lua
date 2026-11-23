-- Script: ServerScriptService > Weapons
-- Tworzy bronie (Tool) w ServerStorage > Weapons i obsługuje strzały (raycast). Szkło można rozbić.
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local SSS = game:GetService("ServerScriptService")
local Wanted = require(SSS:WaitForChild("Wanted"))
local V3 = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local GUNS = {
	["Pistolet"]  = { dmg = 45,  cd = 0.35, pel = 1, spr = 0,    auto = false, range = 300, size = V3(0.4, 0.9, 1.6), color = rgb(40, 40, 45) },
	["Karabin"]   = { dmg = 20,  cd = 0.1,  pel = 1, spr = 0.02, auto = true,  range = 400, size = V3(0.5, 1, 3.4),   color = rgb(52, 56, 60) },
	["Strzelba"]  = { dmg = 16,  cd = 0.9,  pel = 8, spr = 0.09, auto = false, range = 120, size = V3(0.5, 0.8, 3.2), color = rgb(74, 74, 74) },
	["Snajperka"] = { dmg = 100, cd = 1.1,  pel = 1, spr = 0,    auto = false, range = 800, size = V3(0.5, 0.9, 4.2), color = rgb(47, 59, 47) },
	["Minigun"]   = { dmg = 12,  cd = 0.05, pel = 1, spr = 0.06, auto = true,  range = 300, size = V3(1, 1, 3),       color = rgb(85, 85, 85) },
}

local folder = SS:FindFirstChild("Weapons") or Instance.new("Folder")
folder.Name = "Weapons"; folder.Parent = SS
for name, g in pairs(GUNS) do
	if not folder:FindFirstChild(name) then
		local tool = Instance.new("Tool")
		tool.Name = name; tool.RequiresHandle = true; tool.CanBeDropped = false; tool.ToolTip = name
		tool.GripPos = V3(0, 0, 0.4)
		tool:SetAttribute("Gun", name)
		tool:SetAttribute("Auto", g.auto)
		local h = Instance.new("Part")
		h.Name = "Handle"; h.Size = g.size; h.Color = g.color; h.Material = Enum.Material.Metal; h.CanCollide = false
		h.Parent = tool
		tool.Parent = folder
	end
end

local remote = RS:FindFirstChild("FireGun") or Instance.new("RemoteEvent")
remote.Name = "FireGun"; remote.Parent = RS

local last = {}
local rng = Random.new()

remote.OnServerEvent:Connect(function(plr, targetPos)
	if typeof(targetPos) ~= "Vector3" then return end
	local char = plr.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	local cfg = tool and GUNS[tool:GetAttribute("Gun") or ""]
	if not cfg then return end
	local now = os.clock()
	if (last[plr] or 0) + cfg.cd > now then return end
	last[plr] = now

	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not head then return end
	local origin = head.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	for _ = 1, cfg.pel do
		local dir = (targetPos - origin).Unit
		if cfg.spr > 0 then
			dir = (dir + V3(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * cfg.spr).Unit
		end
		local res = workspace:Raycast(origin, dir * cfg.range, params)
		local endPos = res and res.Position or (origin + dir * cfg.range)

		-- smuga pocisku
		local len = (endPos - origin).Magnitude
		local tr = Instance.new("Part")
		tr.Anchored = true; tr.CanCollide = false; tr.CanQuery = false; tr.Material = Enum.Material.Neon
		tr.Color = rgb(255, 238, 136); tr.Size = V3(0.1, 0.1, len)
		tr.CFrame = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -len / 2)
		tr.Parent = workspace
		Debris:AddItem(tr, 0.06)

		if res then
			local m = res.Instance:FindFirstAncestorOfClass("Model")
			local hum = m and m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				hum:TakeDamage(cfg.dmg)
				if hum.Health <= 0 and m.Parent == workspace:FindFirstChild("Pedestrians") then
					local hrp = m:FindFirstChild("HumanoidRootPart")
					Wanted.kill(plr, hrp and hrp.Position or endPos, "gun", m)
				end
			elseif res.Instance.Material == Enum.Material.Glass and res.Instance.Name == "Window" then
				res.Instance:Destroy()
			end
		end
	end
end)
