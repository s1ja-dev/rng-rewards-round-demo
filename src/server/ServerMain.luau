--!strict
-- Orchestrates service initialization order and the shared Remotes-folder
-- bootstrap. This is the only module that knows about every service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local RewardRollService = require(script.Parent.Services.RewardRollService)
local RoundManagerService = require(script.Parent.Services.RoundManagerService)

local ServerMain = {}

function ServerMain.Start()
	Remotes.GetEvent(NetConstants.RequestSpin)

	RewardRollService.Init()
	RoundManagerService.Init()
end

return ServerMain
