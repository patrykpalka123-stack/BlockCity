-- LocalScript: StarterPlayer > StarterPlayerScripts > WeaponClient
-- Strzelanie LPM (broń z automatu strzela przy trzymaniu). Bronie pojawiają się na pasku 1-9 (Backpack).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local fire = RS:WaitForChild("FireGun")
local holding = false

local function tool()
	local t = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
	if t and t:GetAttribute("Gun") then return t end
	return nil
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		holding = true
		if tool() then fire:FireServer(mouse.Hit.Position) end
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end
end)
RunService.Heartbeat:Connect(function()
	local t = tool()
	if holding and t and t:GetAttribute("Auto") then fire:FireServer(mouse.Hit.Position) end
end)
