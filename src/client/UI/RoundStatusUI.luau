--!strict
-- Round phase + countdown readout. Purely a render of whatever
-- RoundManagerService broadcasts — no client-side timer logic that could
-- drift from the server's clock (the progress bar and pulse below are both
-- driven directly by the TimeRemaining the server just sent, not a local
-- ticking clock).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local RoundConfig = require(ReplicatedStorage.Shared.Config.RoundConfig)
local IconAssets = require(ReplicatedStorage.Shared.Config.IconAssets)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)

local PHASE_COLORS: { [string]: Color3 } = {
	Waiting = Theme.TextMuted,
	Intermission = Theme.Info,
	InRound = Theme.Success,
	Ended = Theme.Danger,
}

local PHASE_LABELS: { [string]: string } = {
	Waiting = "Waiting for players...",
	Intermission = "Next round in",
	InRound = "Round ends in",
	Ended = "Round over!",
}

-- Only phases with a meaningful countdown get a phase icon + progress bar;
-- Waiting/Ended show static text same as before this pass.
local PHASE_ICONS: { [string]: string } = {
	Intermission = IconAssets.PhaseIntermission,
	InRound = IconAssets.PhaseInRound,
	Ended = IconAssets.PhaseEnded,
}

local PHASE_DURATIONS: { [string]: number } = {
	Intermission = RoundConfig.IntermissionDuration,
	InRound = RoundConfig.RoundDuration,
}

local PULSE_WINDOW = 3
local PULSE_TWEEN = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

type RoundStateData = {
	Phase: string,
	TimeRemaining: number,
}

local RoundStatusUI = {}

function RoundStatusUI.Init(screenGui: ScreenGui)
	local chip = Instance.new("Frame")
	chip.Name = "RoundStatus"
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Position = UDim2.new(0.5, 0, 0, 16)
	chip.Size = UDim2.fromOffset(320, 74)
	chip.BackgroundColor3 = Theme.ChipBackground
	chip.BorderSizePixel = 0
	chip.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = chip

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.TextMuted
	stroke.Parent = chip

	-- Only shown once a phase icon is actually set (see IconAssets) — text
	-- alone (no left inset) is the fallback, same as every other icon in
	-- this portfolio.
	local icon = Instance.new("ImageLabel")
	icon.Name = "PhaseIcon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromOffset(12, 26)
	icon.Size = UDim2.fromOffset(28, 28)
	icon.BackgroundTransparency = 1
	icon.Visible = false
	icon.Parent = chip

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -24, 0, 52)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Theme.TextLight
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.4
	label.Text = "Waiting for players..."
	label.Parent = chip

	-- Countdown bar: track is a fixed dark background, fill is left-anchored
	-- and shrinks toward the left as time runs out — its right edge recedes
	-- first, reading as "draining right to left".
	local progressTrack = Instance.new("ImageLabel")
	progressTrack.Name = "ProgressTrack"
	progressTrack.AnchorPoint = Vector2.new(0.5, 1)
	progressTrack.Position = UDim2.new(0.5, 0, 1, -8)
	progressTrack.Size = UDim2.fromOffset(288, 14)
	progressTrack.BackgroundTransparency = 1
	progressTrack.Image = IconAssets.ProgressTrack
	progressTrack.ScaleType = Enum.ScaleType.Slice
	progressTrack.SliceCenter = Rect.new(16, 16, 240, 240)
	progressTrack.Visible = false
	progressTrack.Parent = chip

	local progressFill = Instance.new("ImageLabel")
	progressFill.Name = "ProgressFill"
	progressFill.AnchorPoint = Vector2.new(0, 0)
	progressFill.Position = UDim2.fromOffset(0, 0)
	progressFill.Size = UDim2.fromScale(1, 1)
	progressFill.BackgroundTransparency = 1
	progressFill.Image = IconAssets.ProgressFill
	progressFill.ScaleType = Enum.ScaleType.Slice
	progressFill.SliceCenter = Rect.new(16, 16, 240, 240)
	progressFill.Parent = progressTrack

	-- Tracks which whole second the last pulse fired for, so a phase that
	-- updates more than once within the same second (or a re-render) doesn't
	-- retrigger the flash — and resets once outside the last-3s window so it
	-- can fire again next round.
	local lastPulseSecond = -1

	local roundStateChanged = Remotes.GetEvent(NetConstants.RoundStateChanged)
	roundStateChanged.OnClientEvent:Connect(function(data: RoundStateData)
		local phaseColor = PHASE_COLORS[data.Phase] or Theme.TextMuted
		stroke.Color = phaseColor

		local iconId = PHASE_ICONS[data.Phase]
		if iconId and iconId ~= "" then
			icon.Image = iconId
			icon.Visible = true
			label.Position = UDim2.fromOffset(48, 0)
			label.Size = UDim2.new(1, -60, 0, 52)
		else
			icon.Visible = false
			label.Position = UDim2.fromOffset(12, 0)
			label.Size = UDim2.new(1, -24, 0, 52)
		end

		local totalDuration = PHASE_DURATIONS[data.Phase]
		if data.Phase == "Waiting" or data.Phase == "Ended" or not totalDuration then
			label.Text = PHASE_LABELS[data.Phase] or data.Phase
			progressTrack.Visible = false
			lastPulseSecond = -1
		else
			local currentSecond = math.max(math.ceil(data.TimeRemaining), 0)
			label.Text = `{PHASE_LABELS[data.Phase] or data.Phase}: {currentSecond}s`

			progressTrack.Visible = true
			progressFill.ImageColor3 = phaseColor
			local fraction = math.clamp(data.TimeRemaining / totalDuration, 0, 1)
			progressFill.Size = UDim2.fromScale(fraction, 1)

			-- Last 3 seconds: flash red, ease smoothly back to white, once
			-- per whole second (3 -> 2 -> 1), instead of a one-shot flash.
			if currentSecond <= PULSE_WINDOW and currentSecond >= 1 then
				if currentSecond ~= lastPulseSecond then
					lastPulseSecond = currentSecond
					label.TextColor3 = Theme.Danger
					TweenService:Create(label, PULSE_TWEEN, { TextColor3 = Theme.TextLight }):Play()
				end
			else
				lastPulseSecond = -1
			end
		end
	end)
end

return RoundStatusUI
