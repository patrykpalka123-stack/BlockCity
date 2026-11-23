-- LocalScript: StarterPlayer > StarterPlayerScripts > HUD
-- Gwiazdki poszukiwania, powiadomienia, minimapa (prawy górny róg) ze sklepami i Twoją pozycją
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name = "HUD"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")

local wanted = Instance.new("TextLabel")
wanted.AnchorPoint = Vector2.new(0.5, 0); wanted.Position = UDim2.new(0.5, 0, 0, 10); wanted.Size = UDim2.fromOffset(300, 34)
wanted.BackgroundTransparency = 0.3; wanted.BackgroundColor3 = Color3.fromRGB(20, 24, 32); wanted.Font = Enum.Font.GothamBold; wanted.TextSize = 22
wanted.TextColor3 = Color3.fromRGB(255, 85, 85); wanted.Visible = false; wanted.Parent = gui

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0.18, 0); toast.Size = UDim2.fromOffset(520, 36)
toast.BackgroundTransparency = 0.35; toast.BackgroundColor3 = Color3.fromRGB(20, 24, 32); toast.Font = Enum.Font.GothamBold; toast.TextSize = 20
toast.TextColor3 = Color3.fromRGB(255, 210, 63); toast.Visible = false; toast.Parent = gui

local tkn = 0
RS:WaitForChild("Notify").OnClientEvent:Connect(function(text)
	tkn = tkn + 1
	local my = tkn
	toast.Text = text; toast.Visible = true
	task.delay(2.5, function() if tkn == my then toast.Visible = false end end)
end)

local function updWanted()
	local w = plr:GetAttribute("Wanted") or 0
	wanted.Visible = w > 0
	wanted.Text = string.rep("★", w) .. string.rep("☆", 3 - w) .. " POSZUKIWANY"
end
plr:GetAttributeChangedSignal("Wanted"):Connect(updWanted)

-- ===== minimapa =====
local SIZE = 170
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(1, 0); frame.Position = UDim2.new(1, -10, 0, 10); frame.Size = UDim2.fromOffset(SIZE, SIZE)
frame.BackgroundColor3 = Color3.fromRGB(86, 140, 64); frame.BorderSizePixel = 2; frame.ClipsDescendants = true; frame.Parent = gui
local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.fromScale(1, 1); vp.BackgroundColor3 = Color3.fromRGB(86, 140, 64); vp.Ambient = Color3.new(1, 1, 1); vp.LightColor = Color3.new(1, 1, 1); vp.Parent = frame
local cam = Instance.new("Camera"); vp.CurrentCamera = cam; cam.FieldOfView = 40; cam.Parent = vp
local mini = RS:WaitForChild("MiniMap"):Clone(); mini.Parent = vp

local arrow = Instance.new("TextLabel")
arrow.AnchorPoint = Vector2.new(0.5, 0.5); arrow.Position = UDim2.fromScale(0.5, 0.5); arrow.Size = UDim2.fromOffset(20, 20)
arrow.BackgroundTransparency = 1; arrow.Text = "▲"; arrow.TextColor3 = Color3.fromRGB(0, 229, 255); arrow.TextSize = 20; arrow.Font = Enum.Font.GothamBold; arrow.Parent = frame

local markers = {}
task.spawn(function()
	local shops = workspace:WaitForChild("City"):WaitForChild("Shops")
	for _, s in ipairs(shops:GetChildren()) do
		local m = Instance.new("TextLabel")
		m.AnchorPoint = Vector2.new(0.5, 0.5); m.Size = UDim2.fromOffset(16, 16); m.BackgroundColor3 = (s:GetAttribute("Shop") == "car") and Color3.fromRGB(230, 126, 34) or Color3.fromRGB(108, 63, 197)
		m.Text = (s:GetAttribute("Shop") == "car") and "A" or "B"; m.TextColor3 = Color3.new(1, 1, 1); m.TextSize = 12; m.Font = Enum.Font.GothamBold; m.Parent = frame
		Instance.new("UICorner", m).CornerRadius = UDim.new(1, 0)
		table.insert(markers, { s = s, m = m })
	end
end)

RunService.RenderStepped:Connect(function()
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local p = hrp.Position
	cam.CFrame = CFrame.lookAt(Vector3.new(p.X, 620, p.Z), Vector3.new(p.X, 0, p.Z), Vector3.new(0, 0, -1))
	local look = hrp.CFrame.LookVector
	arrow.Rotation = math.deg(math.atan2(look.X, -look.Z))
	for _, e in ipairs(markers) do
		local v = cam:WorldToViewportPoint(e.s.Position)
		e.m.Position = UDim2.fromOffset(v.X, v.Y)
		e.m.Visible = v.X > 0 and v.Y > 0 and v.X < SIZE and v.Y < SIZE
	end
end)
