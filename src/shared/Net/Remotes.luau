--!strict
-- Single source of truth for RemoteEvent instances. The server creates them
-- on boot; the client only ever looks them up (waits for them to exist,
-- never creates). No ad-hoc Instance.new("RemoteEvent") anywhere else in the
-- codebase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetConstants = require(script.Parent.NetConstants)

local REMOTE_NAMES = {
	NetConstants.RequestSpin,
	NetConstants.SpinResult,
	NetConstants.CurrencyChanged,
	NetConstants.RoundStateChanged,
}

local Remotes = {}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder then
		return folder
	end

	if RunService:IsServer() then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Remotes"

		for _, name in REMOTE_NAMES do
			local instance = Instance.new("RemoteEvent")
			instance.Name = name
			instance.Parent = newFolder
		end

		newFolder.Parent = ReplicatedStorage
		folder = newFolder
		return newFolder
	end

	local existing = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	folder = existing
	return existing
end

function Remotes.GetEvent(name: string): RemoteEvent
	return getFolder():WaitForChild(name) :: RemoteEvent
end

return Remotes
