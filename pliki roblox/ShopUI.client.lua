-- LocalScript: StarterPlayer > StarterPlayerScripts > ShopUI
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local Catalog = require(RS:WaitForChild("Catalog"))
local open = RS:WaitForChild("ShopOpen")
local buy = RS:WaitForChild("Buy")

local gui = Instance.new("ScreenGui"); gui.Name = "ShopUI"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(360, 420); frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(24, 28, 36); frame.Visible = false; frame.Parent = gui
Instance.new("UICorner", frame)
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6); layout.Parent = frame
local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.Parent = frame

local function btn(text, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 38); b.BackgroundColor3 = Color3.fromRGB(48, 54, 68); b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 16; b.Text = text; b.Parent = frame
	Instance.new("UICorner", b)
	b.MouseButton1Click:Connect(cb)
	return b
end

local function show(kind)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0, 30); t.BackgroundTransparency = 1; t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold; t.TextSize = 20; t.Text = (kind == "car") and "Salon aut" or "Sklep z bronią"; t.Parent = frame
	for i, it in ipairs(Catalog[kind]) do
		btn(it.name .. " – " .. (it.price == 0 and "darmowy" or (it.price .. " $")), function() buy:FireServer(kind, i) end)
	end
	btn("Zamknij ✕", function() frame.Visible = false end)
	frame.Visible = true
end
open.OnClientEvent:Connect(show)
