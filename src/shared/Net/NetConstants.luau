--!strict
-- String identifiers for every remote. Kept separate from Remotes.luau so
-- both server and client can reference names without pulling in the
-- Instance-creation logic.

local NetConstants = {
	-- No payload: the server rolls the reward and tells the client what it
	-- won. The client never picks or previews the outcome itself.
	RequestSpin = "RequestSpin",
	SpinResult = "SpinResult",

	CurrencyChanged = "CurrencyChanged",

	RoundStateChanged = "RoundStateChanged",
}

return NetConstants
