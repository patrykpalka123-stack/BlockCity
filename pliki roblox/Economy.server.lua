-- Script: ServerScriptService > Economy
-- 1 000 000 $ na start, sklepy (salon aut i broń), kupno i spawn aut
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")

local Catalog = require(RS:WaitForChild("Catalog"))
local Wanted = require(SSS:WaitForChild("Wanted"))

local function remote(name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = RS end
	return r
end
local shopOpen, buy = remote("ShopOpen"), remote("Buy")

local owned, playerCar = {}, {}

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local cash = Instance.new("IntValue"); cash.Name = "Cash"; cash.Value = 1000000; cash.Parent = ls
	owned[plr] = { car = { [1] = true }, gun = {} }
end)
Players.PlayerRemoving:Connect(function(plr)
	owned[plr] = nil
	if playerCar[plr] then playerCar[plr]:Destroy(); playerCar[plr] = nil end
end)

-- wejście w strefę sklepu (ProximityPrompt tworzy CityGenerator)
task.spawn(function()
	local shops = workspace:WaitForChild("City"):WaitForChild("Shops")
	for _, part in ipairs(shops:GetChildren()) do
		local pp = part:FindFirstChildOfClass("ProximityPrompt")
		if pp then
			pp.Triggered:Connect(function(plr) shopOpen:FireClient(plr, part:GetAttribute("Shop")) end)
		end
	end
end)

buy.OnServerEvent:Connect(function(plr, kind, i)
	if kind ~= "car" and kind ~= "gun" then return end
	local list = Catalog[kind]
	if type(i) ~= "number" or not list[i] then return end
	local it = list[i]
	local cash = plr.leaderstats.Cash
	local own = owned[plr]
	if not own then return end
	if not own[kind][i] then
		if cash.Value < it.price then Wanted.notify(plr, "Za mało pieniędzy!"); return end
		cash.Value = cash.Value - it.price
		own[kind][i] = true
	end
	if kind == "gun" then
		local tool = SS:FindFirstChild("Weapons") and SS.Weapons:FindFirstChild(it.name)
		if tool and not plr.Backpack:FindFirstChild(it.name) and not (plr.Character and plr.Character:FindFirstChild(it.name)) then
			tool:Clone().Parent = plr.Backpack
		end
		Wanted.notify(plr, "Wybrano: " .. it.name)
	else
		local folder = SS:FindFirstChild("PlayerCars")
		local tpl = folder and folder:FindFirstChild(it.model)
		if not tpl then
			Wanted.notify(plr, "Brak modelu w ServerStorage > PlayerCars: " .. it.model)
			return
		end
		if playerCar[plr] then playerCar[plr]:Destroy() end
		local car = tpl:Clone()
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then car:PivotTo(hrp.CFrame * CFrame.new(0, 4, -18)) end
		car.Parent = workspace
		playerCar[plr] = car
		Wanted.notify(plr, "Wybrano: " .. it.name)
	end
end)
