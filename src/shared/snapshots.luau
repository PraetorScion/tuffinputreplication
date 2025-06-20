local input = require("../../roblox_packages/.pesde/killergg+axis/0.1.0-rc.1.4/axis/src/input")
local Snapshot = {}

export type SnapshotData = {
	timeStamp: number,
	CFrame: CFrame,
	inputState: number,
}

export type SnapshotInstance = {
	cache: { SnapshotData },
	PushAt: (self: SnapshotInstance, timeStamp: number, CFrame: CFrame, inputState: number) -> (),
	GetBefore: (self: SnapshotInstance, timeStamp: number) -> SnapshotData?,
	GetAfter: (self: SnapshotInstance, timeStamp: number) -> SnapshotData?,
	GetAt: (self: SnapshotInstance, timeStamp: number) -> CFrame? | number?,
	GetLatest: (self: SnapshotInstance) -> SnapshotData?,
	RemoveOld: (self: SnapshotInstance, cutoffTime: number) -> (),
	Destroy: (self: SnapshotInstance) -> (),
	Subject: Player?,
}

local MAX_LENGTH = 10
local SnapshotInstances: { [Player]: SnapshotInstance } = {}

local function BinarySearch(cache: { SnapshotData }, timeStamp: number): number
	local low, high = 1, #cache
	while low <= high do
		local mid = (low + high) // 2
		if cache[mid].timeStamp < timeStamp then
			low = mid + 1
		else
			high = mid - 1
		end
	end
	return low
end

local function PushAt(self: SnapshotInstance, timeStamp: number, CFrame: CFrame, inputState: number): ()
	local cache = self.cache
	local index = BinarySearch(cache, timeStamp)
	table.insert(cache, index, { timeStamp = timeStamp, CFrame = CFrame, inputState = inputState })
	if #cache > MAX_LENGTH then
		table.remove(cache, 1)
	end
	-- print(`Pushed snapshot at {timeStamp} with CFrame {CFrame}`)
	-- print(`Cache length: {#cache}`)
	-- print(`Cache contents:`)
	-- for i, snapshot in cache do
	-- 	print(`{i}: {snapshot.timeStamp} - {snapshot.CFrame}`)
	-- end
end

local function GetBefore(self: SnapshotInstance, timeStamp: number): SnapshotData?
	local cache = self.cache
	for i = #cache, 1, -1 do
		if cache[i].timeStamp < timeStamp then
			return cache[i]
		end
	end
	return nil
end

local function GetAfter(self: SnapshotInstance, timeStamp: number): SnapshotData?
	local cache = self.cache
	for i = 1, #cache do
		if cache[i].timeStamp >= timeStamp then
			return cache[i]
		end
	end
	return nil
end

local function GetAt(
	self: SnapshotInstance,
	timeStamp: number,
	currentCFrame: CFrame?,
	currentInputState: number?
): CFrame? | number?
	local cache = self.cache
	if #cache == 0 then
		return nil
	end
	if #cache == 1 then
		return cache[1].CFrame
	end

	local before = self:GetBefore(timeStamp)
	local after = self:GetAfter(timeStamp)

	if before and after then
		local alpha = (timeStamp - before.timeStamp) / (after.timeStamp - before.timeStamp)

		return before.CFrame:Lerp(after.CFrame, alpha) and before.inputState
	elseif before then
		return before.CFrame and before.inputState
	elseif after then
		if currentCFrame and input then
			local alpha = timeStamp / after.timeStamp

			return currentCFrame:Lerp(after.CFrame, alpha) and currentInputState
		end
		return after.CFrame and currentInputState
	end

	return nil
end

local function GetLatest(self: SnapshotInstance): SnapshotData?
	local cache = self.cache
	if #cache > 0 then
		return cache[#cache]
	end
	return nil
end

local function RemoveOld(self: SnapshotInstance, cutoffTime: number): ()
	local cache = self.cache
	while #cache > 0 and cache[1].timeStamp < cutoffTime do
		table.remove(cache, 1)
	end
end

function Snapshot.new(subject: Player): SnapshotInstance
	local cache: { SnapshotData } = {}

	local function Destroy(): ()
		table.clear(cache)
	end

	return {
		cache = cache,
		PushAt = PushAt,
		GetBefore = GetBefore,
		GetAfter = GetAfter,
		GetAt = GetAt,
		GetLatest = GetLatest,
		RemoveOld = RemoveOld,
		Destroy = Destroy,
		Subject = subject,
	}
end

function Snapshot.RegisterPlayer(player: Player): SnapshotInstance
	if not SnapshotInstances[player] then
		SnapshotInstances[player] = Snapshot.new(player)
	end
	return SnapshotInstances[player]
end

function Snapshot.DeregisterPlayer(player: Player): ()
	local snapshot = SnapshotInstances[player]
	if snapshot then
		snapshot:Destroy()
		SnapshotInstances[player] = nil
	end
end

function Snapshot.GetSnapshotInstance(player: Player): SnapshotInstance
	return SnapshotInstances[player] or Snapshot.RegisterPlayer(player)
end

return Snapshot
