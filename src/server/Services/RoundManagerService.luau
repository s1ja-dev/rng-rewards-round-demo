--!strict
-- Generic round-state machine: Waiting -> Intermission -> InRound -> Ended
-- -> (Intermission or Waiting). Reusable for any round-based game genre —
-- battle-royale-style lobbies, minigame rotations, PvP arenas — the game-
-- specific part (what actually happens during InRound) is intentionally not
-- this module's job; it only owns the clock and broadcasts phase changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local RoundConfig = require(ReplicatedStorage.Shared.Config.RoundConfig)

type RoundPhase = RoundConfig.RoundPhase

local RoundManagerService = {}

local currentPhase: RoundPhase = "Waiting"
local phaseEndsAt = 0

local function broadcastState(timeRemaining: number)
	Remotes.GetEvent(NetConstants.RoundStateChanged):FireAllClients({
		Phase = currentPhase,
		TimeRemaining = math.max(timeRemaining, 0),
	})
end

local function enterPhase(phase: RoundPhase, duration: number?)
	currentPhase = phase
	phaseEndsAt = if duration then os.clock() + duration else 0
	broadcastState(duration or 0)
end

function RoundManagerService.GetPhase(): RoundPhase
	return currentPhase
end

function RoundManagerService.Init()
	task.spawn(function()
		enterPhase("Waiting")

		while true do
			task.wait(RoundConfig.TickInterval)

			local playerCount = #Players:GetPlayers()
			local remaining = phaseEndsAt - os.clock()

			if currentPhase == "Waiting" then
				if playerCount >= RoundConfig.MinPlayersToStart then
					enterPhase("Intermission", RoundConfig.IntermissionDuration)
				else
					-- Re-broadcast every tick, not just once on entry, so a
					-- client joining partway through a long Waiting phase
					-- still gets the current phase instead of nothing.
					broadcastState(0)
				end
			elseif currentPhase == "Intermission" then
				if remaining <= 0 then
					enterPhase("InRound", RoundConfig.RoundDuration)
				else
					broadcastState(remaining)
				end
			elseif currentPhase == "InRound" then
				if playerCount == 0 then
					enterPhase("Waiting")
				elseif remaining <= 0 then
					enterPhase("Ended", RoundConfig.EndedDuration)
				else
					broadcastState(remaining)
				end
			elseif currentPhase == "Ended" then
				if remaining <= 0 then
					if playerCount >= RoundConfig.MinPlayersToStart then
						enterPhase("Intermission", RoundConfig.IntermissionDuration)
					else
						enterPhase("Waiting")
					end
				else
					broadcastState(remaining)
				end
			end
		end
	end)
end

return RoundManagerService
