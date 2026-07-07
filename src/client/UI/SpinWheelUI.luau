--!strict
-- Spin button + result reveal. The client only ever plays a reveal for a
-- result the server already rolled (`SpinResult`) — it never generates or
-- previews the outcome itself.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)

local RARITY_COLORS: { [string]: Color3 } = {
	Common = Theme.TextMuted,
	Uncommon = Theme.Success,
	Rare = Theme.Info,
	Epic = Theme.Premium,
	Legendary = Theme.Warning,
}

type SpinResultData = {
	RewardId: string,
	RewardName: string,
	Rarity: string,
	CoinAmount: number,
}

local SpinWheelUI = {}

function SpinWheelUI.Init(screenGui: ScreenGui)
	local _, spinClicked = ButtonComponent.new({
		Text = "Spin!",
		Size = UDim2.fromOffset(180, 56),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		BackgroundColor = Theme.Warning,
		Parent = screenGui,
	})

	local requestSpin = Remotes.GetEvent(NetConstants.RequestSpin)
	spinClicked:Connect(function()
		requestSpin:FireServer()
	end)

	local badge = Instance.new("Frame")
	badge.Name = "SpinResultBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.4)
	badge.Size = UDim2.fromOffset(360, 90)
	badge.BackgroundColor3 = Theme.Warning
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel = 0
	badge.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Transparency = 1
	stroke.Parent = badge

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Theme.TextLight
	label.TextTransparency = 1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = badge

	local spinResult = Remotes.GetEvent(NetConstants.SpinResult)
	spinResult.OnClientEvent:Connect(function(data: SpinResultData)
		local accent = RARITY_COLORS[data.Rarity] or Theme.Info
		badge.BackgroundColor3 = accent
		stroke.Color = Theme.Darken(accent, 0.55)
		label.Text = `{data.Rarity}: {data.RewardName} (+{data.CoinAmount})`

		badge.BackgroundTransparency = 0
		stroke.Transparency = 0
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.5
		badge.Position = UDim2.fromScale(0.5, 0.4)

		TweenService:Create(badge, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.32),
		}):Play()

		task.delay(1.4, function()
			TweenService:Create(badge, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
	end)
end

return SpinWheelUI
