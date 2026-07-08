--!strict
-- Spin button + result reveal. The client only ever plays a reveal for a
-- result the server already rolled (`SpinResult`) — it never generates or
-- previews the outcome itself.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local IconAssets = require(ReplicatedStorage.Shared.Config.IconAssets)

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

-- Vector_UI_Pack_dobo_ui card art already comes pre-colored per rarity —
-- industry-standard white/green/blue/purple/gold convention — so the badge
-- itself needs no programmatic BackgroundColor3 tint anymore, just picking
-- the right image.
local RARITY_CARDS: { [string]: string } = {
	Common = IconAssets.CardCommon,
	Uncommon = IconAssets.CardUncommon,
	Rare = IconAssets.CardRare,
	Epic = IconAssets.CardEpic,
	Legendary = IconAssets.CardLegendary,
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

	local badge = Instance.new("ImageLabel")
	badge.Name = "SpinResultBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.4)
	badge.Size = UDim2.fromOffset(360, 100)
	badge.BackgroundTransparency = 1
	badge.ImageTransparency = 1
	badge.ScaleType = Enum.ScaleType.Slice
	badge.SliceCenter = Rect.new(32, 32, 224, 224)
	badge.Parent = screenGui

	-- Fallback fill for when the card art isn't set (id empty) — keeps the
	-- badge readable as a plain colored panel, same as before this pass.
	local fallbackCorner = Instance.new("UICorner")
	fallbackCorner.CornerRadius = UDim.new(0, 16)
	fallbackCorner.Parent = badge

	local dice = Instance.new("ImageLabel")
	dice.Name = "RarityDice"
	dice.AnchorPoint = Vector2.new(0, 0.5)
	dice.Position = UDim2.fromOffset(16, 50)
	dice.Size = UDim2.fromOffset(56, 56)
	dice.BackgroundTransparency = 1
	dice.ImageTransparency = 1
	dice.Image = IconAssets.Dice
	dice.Parent = badge

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(84, 0)
	label.Size = UDim2.new(1, -100, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.TextLight
	label.TextTransparency = 1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = badge

	local spinResult = Remotes.GetEvent(NetConstants.SpinResult)
	spinResult.OnClientEvent:Connect(function(data: SpinResultData)
		local accent = RARITY_COLORS[data.Rarity] or Theme.Info
		local cardImage = RARITY_CARDS[data.Rarity] or ""

		if cardImage ~= "" then
			badge.Image = cardImage
			badge.BackgroundColor3 = Theme.ChipBackground
			badge.BackgroundTransparency = 1
		else
			-- No card art uploaded for this rarity — flat-color fallback,
			-- same look the badge had before this pass.
			badge.Image = ""
			badge.BackgroundColor3 = accent
			badge.BackgroundTransparency = 0
		end

		-- Darkened rarity color for the dice, same "stroke = darker shade of
		-- fill" relationship used everywhere else in this portfolio — keeps
		-- it legible sitting on top of the (usually lighter) card color.
		dice.ImageColor3 = Theme.Darken(accent, 0.5)
		label.Text = `{data.Rarity}: {data.RewardName} (+{data.CoinAmount})`

		badge.ImageTransparency = 0
		dice.ImageTransparency = 0
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.5
		badge.Position = UDim2.fromScale(0.5, 0.4)

		TweenService:Create(badge, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.32),
		}):Play()

		task.delay(1.4, function()
			TweenService:Create(badge, TweenInfo.new(0.4), { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
			TweenService:Create(dice, TweenInfo.new(0.4), { ImageTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
	end)
end

return SpinWheelUI
