-- ***************************************************************************************************************************************************
-- * Scheduler.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.07.30 / Baanano: First version, spiritual sucessor to LibScheduler                                                                 *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local WATCHDOG_LIMIT = Internal.Constants.WATCHDOG_LIMIT
local STATE = Internal.Constants.TASK_STATE

local lastTask = 1
local frameStart = Inspect.Time.Real()


local function CheckTaskActive(task)
	if task.suspended or not Internal.Scheduler.TimeRemaining(task.interval) then return false end
	
	if task.state == STATE.WAITING then
		Internal.Wait.Check(task)
	end
	
	return task.state == STATE.ACTIVE
end

local function SelectTask()
	local tasks = Internal.Task.List
	local taskInit = math.min(lastTask, #tasks)

	if #tasks > 0 then
		repeat
			lastTask = lastTask + 1
			if lastTask > #tasks then lastTask = 1 end
			
			local task = tasks[lastTask]
			if task and CheckTaskActive(task) then
				return task
			end
		until taskInit == lastTask
	end
end

local function OnFrame()
	frameStart = Inspect.Time.Real()
	
	while Inspect.System.Watchdog() > WATCHDOG_LIMIT do
		local task = SelectTask()
		
		if not task then break end
		
		Internal.Dispatcher.Run(task)
	end
end
Command.Event.Attach(Event.System.Update.Begin, OnFrame, addonID .. ".OnFrame")


function Internal.Scheduler.TimeRemaining(interval)
	return (Inspect.Time.Real() - frameStart) < interval
end
