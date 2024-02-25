local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera

local placedBlocks = {} -- Table to store references to placed blocks

local boxSizeY = 3000
local boxSizeX = 3000
local rayCount = 50
local rayDelay = 0.005 -- in mins ex 0.03 = 3 sec
local bloomSize = 20
local blockSize = .15

local scanning = false -- Variable to track if a scan is in progress

local function lerpColor(color1, color2, t)
	return color1:lerp(color2, t)
end

local function calculateColor(distance)
	local t1 = math.clamp((distance - 10) / 20, 0, 1) -- 10 studs to start turning green, 30 studs max distance
	local t2 = math.clamp((distance - 30) / 20, 0, 1) -- 30 studs to start turning blue, 50 studs max distance

	if distance <= 30 then
		return lerpColor(Color3.new(1, 0, 0), Color3.new(0, 1, 0), t1) -- Red to Green
	else
		return lerpColor(Color3.new(0, 1, 0), Color3.new(0, 0, 1), t2) -- Green to Blue
	end
end

local function placeBlocks()
	scanning = true

	local viewportSize = camera.ViewportSize

	for _ = 1, rayCount do
		local offsetX = math.random(-boxSizeX, boxSizeX)
		local offsetY = math.random(-boxSizeY, boxSizeY)

		local rayOrigin = camera.CFrame.Position + camera.CFrame.RightVector * (offsetX / viewportSize.X) * 2
			+ camera.CFrame.UpVector * (offsetY / viewportSize.Y) * -2

		local rayDirection = (mouse.X / viewportSize.X - 0.5) * 2 * camera.CFrame.RightVector
			+ (mouse.Y / viewportSize.Y - 0.5) * -2 * camera.CFrame.UpVector
			+ camera.CFrame.LookVector

		local ignoreList = {player.Character}
		for _, block in ipairs(placedBlocks) do
			table.insert(ignoreList, block)
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = ignoreList

		local raycastResult = game.Workspace:Raycast(rayOrigin, rayDirection * 1000, raycastParams)
		if raycastResult then
			local part = Instance.new("Part")
			part.Size = Vector3.new(blockSize, blockSize, blockSize)
			part.Position = raycastResult.Position
			part.Anchored = true
			part.CanCollide = false

			-- Apply neon texture to all sides
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local neon = Instance.new("SurfaceLight")
				neon.Face = face
				neon.Brightness = .5
				neon.Color = Color3.new(1, 1, 1)
				neon.Range = 10
				neon.Parent = part
			end

			-- Apply bloom effect
			local bloom = Instance.new("BloomEffect")
			bloom.Enabled = false


			-- Calculate distance to camera
			local distance = (camera.CFrame.Position - raycastResult.Position).Magnitude

			-- Calculate color based on distance
			local color = calculateColor(distance)

			for _, neon in ipairs(part:GetChildren()) do
				if neon:IsA("SurfaceLight") then
					neon.Color = color
				end
			end

			part.Parent = game.Workspace

			-- Add the placed block to the list
			table.insert(placedBlocks, part)
		end
	end

	scanning = false
end


UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
			if not scanning then
				placeBlocks()
			end
			wait()
		end
	end
end)

RunService.Heartbeat:Connect(function()
	for _, part in ipairs(placedBlocks) do
		local distance = (camera.CFrame.Position - part.Position).Magnitude
		local color = calculateColor(distance)

		for _, neon in ipairs(part:GetChildren()) do
			if neon:IsA("SurfaceLight") then
				neon.Color = color
			end
		end
	end
end)
