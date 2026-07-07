--!strict
-- Round phase + countdown readout. Purely a render of whatever
-- RoundManagerService broadcasts — no client-side timer logic that could
-- drift from the server's clock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

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
	chip.Size = UDim2.fromOffset(300, 56)
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

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Theme.TextLight
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.4
	label.Text = "Waiting for players..."
	label.Parent = chip

	local roundStateChanged = Remotes.GetEvent(NetConstants.RoundStateChanged)
	roundStateChanged.OnClientEvent:Connect(function(data: RoundStateData)
		stroke.Color = PHASE_COLORS[data.Phase] or Theme.TextMuted

		if data.Phase == "Waiting" or data.Phase == "Ended" then
			label.Text = PHASE_LABELS[data.Phase] or data.Phase
		else
			label.Text = `{PHASE_LABELS[data.Phase] or data.Phase}: {math.ceil(data.TimeRemaining)}s`
		end
	end)
end

return RoundStatusUI
