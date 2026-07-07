--!strict
-- All tunable round-manager numbers in one place.

local RoundConfig = {
	MinPlayersToStart = 1,
	IntermissionDuration = 15,
	RoundDuration = 30,
	EndedDuration = 5,
	TickInterval = 1,

	SpinCooldown = 1,
}

export type RoundPhase = "Waiting" | "Intermission" | "InRound" | "Ended"

return RoundConfig
