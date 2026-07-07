--!strict
-- Weighted reward table. Every reward is a coin amount, differentiated by
-- rarity/size — keeps the demo focused on the weighted-RNG mechanic itself
-- rather than a large item catalog. `PickWeighted` is a pure function (given
-- a random draw in [0, GetTotalWeight())) so the odds themselves are
-- trivially unit-testable independent of which RNG source calls it.

export type RewardRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

export type RewardDefinition = {
	Id: string,
	Name: string,
	Rarity: RewardRarity,
	Weight: number,
	CoinAmount: number,
}

local REWARDS: { RewardDefinition } = {
	{ Id = "common_coins", Name = "Small Coin Pouch", Rarity = "Common", Weight = 50, CoinAmount = 10 },
	{ Id = "uncommon_coins", Name = "Coin Pouch", Rarity = "Uncommon", Weight = 30, CoinAmount = 25 },
	{ Id = "rare_coins", Name = "Coin Chest", Rarity = "Rare", Weight = 15, CoinAmount = 75 },
	{ Id = "epic_coins", Name = "Coin Vault", Rarity = "Epic", Weight = 4, CoinAmount = 200 },
	{ Id = "legendary_coins", Name = "Jackpot", Rarity = "Legendary", Weight = 1, CoinAmount = 1000 },
}

local RewardTableConfig = {}

function RewardTableConfig.GetAll(): { RewardDefinition }
	return REWARDS
end

function RewardTableConfig.GetTotalWeight(): number
	local total = 0
	for _, reward in REWARDS do
		total += reward.Weight
	end
	return total
end

-- `roll` must be in [0, GetTotalWeight()).
function RewardTableConfig.PickWeighted(roll: number): RewardDefinition
	local cumulative = 0
	for _, reward in REWARDS do
		cumulative += reward.Weight
		if roll < cumulative then
			return reward
		end
	end
	-- Floating point edge case at the very top of the range — fall back to
	-- the last entry rather than erroring.
	return REWARDS[#REWARDS]
end

return RewardTableConfig
