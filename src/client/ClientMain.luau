--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local Theme = require(script.Parent.Theme)
local CurrencyLabel = require(script.Parent.UI.HUD.CurrencyLabel)
local SpinWheelUI = require(script.Parent.UI.SpinWheelUI)
local RoundStatusUI = require(script.Parent.UI.RoundStatusUI)

local ClientMain = {}

local function formatNumber(value: number): string
	return tostring(math.floor(value))
end

function ClientMain.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RngRoundUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local _, coinsValueLabel = CurrencyLabel.new({
		Caption = "Coins",
		AccentColor = Theme.Warning,
		Position = UDim2.fromOffset(16, 16),
		Parent = screenGui,
	})

	local currencyChanged = Remotes.GetEvent(NetConstants.CurrencyChanged)
	currencyChanged.OnClientEvent:Connect(function(data: { Coins: number })
		coinsValueLabel.Text = formatNumber(data.Coins)
	end)

	RoundStatusUI.Init(screenGui)
	SpinWheelUI.Init(screenGui)
end

return ClientMain
