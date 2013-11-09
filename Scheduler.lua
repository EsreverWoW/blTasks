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
local MAX_ACTIVE_TASKS = Internal.Constants.MAX_ACTIVE_TASKS

local frameStart = Inspect.Time.Real()
local activeTasks = {}
local pendingTasks = {}
local ignoredTasks = {}
local lastActive = 1
local lastPending = 1


local function CheckTaskActive(task)
	if task.suspended then return false end
	
	if task.state == STATE.WAITING then
		Internal.Wait.Check(task)
	end
	
	return task.state == STATE.ACTIVE
end

local function SelectTask()
	local tasks = Internal.Task.List
	local numActive = #activeTasks
	local taskInit = math.min(lastActive, numActive)

	if numActive > 0 then
		repeat
			lastActive = lastActive + 1
			if lastActive > numActive then lastActive = 1 end
			
			local taskID = activeTasks[lastActive]
			local task = taskID and tasks[taskID]
			
			if task then
				if CheckTaskActive(task) then
					if Internal.Scheduler.TimeRemaining(task.interval) then
						return task
					end
				elseif task.state == STATE.FINISHED or numActive / MAX_ACTIVE_TASKS > 0.7 then
					if lastActive < numActive then
						activeTasks[lastActive] = activeTasks[numActive]
					end
					activeTasks[numActive] = nil
					numActive = numActive - 1
					
					if task.state == STATE.FINISHED then
						ignoredTasks[taskID] = true
					else
						pendingTasks[#pendingTasks + 1] = taskID
					end
				end
			end
		until taskInit == lastActive or numActive <= 0 or Inspect.System.Watchdog() <= WATCHDOG_LIMIT or not Internal.Scheduler.TimeRemaining()
	end
end

local function ActivateTask()
	if #activeTasks >= MAX_ACTIVE_TASKS then return false end

	local tasks = Internal.Task.List
	local numPending = #pendingTasks
	local taskInit = math.min(lastPending, numPending)
	
	if numPending > 0 then
		repeat
			lastPending = lastPending + 1
			if lastPending > numPending then lastPending = 1 end
			
			local taskID = pendingTasks[lastPending]
			local task = taskID and tasks[taskID]
			
			if task then
				if task.state == STATE.FINISHED or CheckTaskActive(task) then
					if lastPending < numPending then
						pendingTasks[lastPending] = pendingTasks[numPending]
					end
					pendingTasks[numPending] = nil
					numPending = numPending - 1
					
					if task.state == STATE.FINISHED then
						ignoredTasks[taskID] = true
					else
						activeTasks[#activeTasks + 1] = taskID
					end
					
					return true
				end
			end
		until taskInit == lastPending or numPending <= 0 or Inspect.System.Watchdog() <= WATCHDOG_LIMIT or not Internal.Scheduler.TimeRemaining()
	end
	
	return false
end

local function OnFrame()
	frameStart = Inspect.Time.Real()
	
	while Inspect.System.Watchdog() > WATCHDOG_LIMIT and Internal.Scheduler.TimeRemaining() do
		local task = SelectTask()
		if task then
			Internal.Dispatcher.Run(task)
		elseif not ActivateTask() then
			break
		end
	end
end
Command.Event.Attach(Event.System.Update.Begin, OnFrame, addonID .. ".OnFrame")


function Internal.Scheduler.TimeRemaining(interval)
	return (Inspect.Time.Real() - frameStart) < (interval or Internal.Constants.TASK_INTERVAL.SHORT)
end

function Internal.Scheduler.Add(taskID)
	if #activeTasks >= MAX_ACTIVE_TASKS then
		pendingTasks[#pendingTasks + 1] = taskID
	else
		activeTasks[#activeTasks + 1] = taskID
	end
end

function Internal.Scheduler.Remove(taskID)
	if ignoredTasks[taskID] then
		ignoredTasks[taskID] = nil
	else
		local numActive = #activeTasks
		for i = 1, numActive do
			if activeTasks[i] == taskID then
				if i < numActive then
					activeTasks[i] = activeTasks[numActive]
				end
				activeTasks[numActive] = nil
				return
			end
		end

		local numPending = #pendingTasks
		for i = 1, numPending do
			if pendingTasks[i] == taskID then
				if i < numPending then
					pendingTasks[i] = pendingTasks[numPending]
				end
				pendingTasks[numPending] = nil
				return
			end
		end
	end
end
