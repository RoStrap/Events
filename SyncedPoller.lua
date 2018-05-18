-- Polling synced to os.time()

local Resources = require(game:GetService("ReplicatedStorage"):WaitForChild("Resources"))
local Table = Resources:LoadLibrary("Table")

local tick = tick
local wait = wait
local ceil = math.ceil

local HourDifference do
	-- Get the difference in seconds between os.time() and tick(), rounded to the nearest hour

	local SecondsPerHour = 3600
	HourDifference = math.floor((os.time() - tick()) / SecondsPerHour + 0.5) * SecondsPerHour
end

local SyncedPoller = {}

function SyncedPoller.new(Interval, Func)
	-- Calls Func every Interval seconds
	-- @param number Interval How often in seconds Func() should be called
	--	Obviously this uses `wait`, so 0 is a valid interval but it will in reality be about (1 / 30)
	-- @param function Func the function to call

	spawn(function()
		while true do
			local t = tick() + HourDifference
			wait(ceil(t / Interval) * Interval - t)
			Func()
		end
	end)
end

return Table.Lock(SyncedPoller)
