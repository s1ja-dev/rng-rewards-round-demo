--!strict
-- Server-authoritative weighted RNG. `RequestSpin` carries no payload and
-- `SpinResult` tells the client what it already won — the client only ever
-- plays a reveal animation for a result the server already decided, it
-- never rolls or previews the outcome itself. No persistence in this demo
-- (coins reset each session) — that's already demonstrated by the
-- shop-inventory-suite-demo's DataService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local RewardTableConfig = require(ReplicatedStorage.Shared.Config.RewardTableConfig)
local RoundConfig = require(ReplicatedStorage.Shared.Config.RoundConfig)

local RewardRollService = {}

local random = Random.new()
local coins: { [Player]: number } = {}
local nextSpinAllowedAt: { [Player]: number } = {}

local function fireCurrencyChanged(player: Player)
	Remotes.GetEvent(NetConstants.CurrencyChanged):FireClient(player, { Coins = coins[player] or 0 })
end

function RewardRollService.GetCoins(player: Player): number
	return coins[player] or 0
end

local function onRequestSpin(player: Player)
	local now = os.clock()
	if (nextSpinAllowedAt[player] or 0) > now then
		return
	end
	nextSpinAllowedAt[player] = now + RoundConfig.SpinCooldown

	local totalWeight = RewardTableConfig.GetTotalWeight()
	local roll = random:NextNumber() * totalWeight
	local reward = RewardTableConfig.PickWeighted(roll)

	coins[player] = (coins[player] or 0) + reward.CoinAmount
	fireCurrencyChanged(player)

	Remotes.GetEvent(NetConstants.SpinResult):FireClient(player, {
		RewardId = reward.Id,
		RewardName = reward.Name,
		Rarity = reward.Rarity,
		CoinAmount = reward.CoinAmount,
	})
end

function RewardRollService.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		coins[player] = 0
		fireCurrencyChanged(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		coins[player] = nil
		nextSpinAllowedAt[player] = nil
	end)

	Remotes.GetEvent(NetConstants.RequestSpin).OnServerEvent:Connect(onRequestSpin)
end

return RewardRollService
