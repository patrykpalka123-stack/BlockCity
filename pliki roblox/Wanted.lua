-- ModuleScript: ServerScriptService > Wanted
local RS = game:GetService("ReplicatedStorage")
local M = {}

local notify = RS:FindFirstChild("Notify")
if not notify then
	notify = Instance.new("RemoteEvent")
	notify.Name = "Notify"
	notify.Parent = RS
end

function M.notify(player, text)
	notify:FireClient(player, text)
end

function M.get(player)
	return player:GetAttribute("Wanted") or 0
end

function M.clear(player)
	player:SetAttribute("Wanted", 0)
end

-- czy ktoś widział zdarzenie w punkcie pos (przechodzień do 100 studów albo radiowóz do 280)
local function witnessed(pos, exclude)
	local peds = workspace:FindFirstChild("Pedestrians")
	if peds then
		for _, m in ipairs(peds:GetChildren()) do
			local hum = m:FindFirstChildOfClass("Humanoid")
			local hrp = m:FindFirstChild("HumanoidRootPart")
			if m ~= exclude and hum and hum.Health > 0 and hrp and (hrp.Position - pos).Magnitude < 100 then
				return true
			end
		end
	end
	local cars = workspace:FindFirstChild("TrafficCars")
	if cars then
		for _, m in ipairs(cars:GetChildren()) do
			if m:GetAttribute("Police") and (m:GetPivot().Position - pos).Magnitude < 280 then
				return true
			end
		end
	end
	return false
end

-- wywołaj po zabiciu przechodnia; how = "gun" albo "car"
function M.kill(player, pos, how, victim)
	local msg = (how == "car") and "Przejechałeś przechodnia!" or "Zabiłeś przechodnia!"
	if witnessed(pos, victim) then
		player:SetAttribute("Wanted", math.min(3, M.get(player) + 1))
		M.notify(player, msg .. " Policja Cię ściga!")
	else
		M.notify(player, msg .. " Nikt tego nie widział.")
	end
end

return M
