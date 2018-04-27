-- Polling synced to os.time()

local SecondsPerHour = 3600
local HourDifference = math.floor((os.time() - tick()) / SecondsPerHour + 0.5) * SecondsPerHour

local SyncedPoller = {}

function SyncedPoller.new(Interval, Func)
	-- Calls Func every Interval seconds
	-- @param number Interval How often in seconds Func() should be called
	-- @param function Func the function to call

	spawn(function()
		while true do
			local t = tick() + HourDifference
			wait(math.ceil(t / Interval) * Interval + 1 - t)
			Func()
		end
	end)
end

return SyncedPoller
