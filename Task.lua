-- ***************************************************************************************************************************************************
-- * Task.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.07.30 / Baanano: First version, spiritual sucessor to LibScheduler                                                                 *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local STATE = Internal.Constants.TASK_STATE
local INTERVAL = Internal.Constants.TASK_INTERVAL

local tasks = {}
local freeIDs = {}
local handle2task = blUtil.WeakReference.Key()
local abandonedHandles = {}
local blueprint, methods, meta = blUtil.Handle.Blueprint()
local TaskFinishedEvent = Utility.Event.Create(addonID, "Task.Finished")

meta.__gc =
	function(handle)
		local taskID = handle and handle2task[handle]
		if taskID then
			if taskID >= #tasks then
				tasks[taskID] = nil
				while tasks[#tasks] == false do
					freeIDs[#tasks] = nil
					tasks[#tasks] = nil
				end
			else
				tasks[taskID] = false
				freeIDs[taskID] = true
			end
			Internal.Scheduler.Remove(taskID)
		end
	end


local function GetContextTask()	
	local currentCoroutine = coroutine.running()
	for _, task in pairs(tasks) do
		if task and task.coroutine == currentCoroutine then
			return task
		end
	end
end
	
local function GetTaskByHandle(handle)
	local taskID = handle and handle2task[handle]
	local task = taskID and tasks[taskID]
	assert(task, "Invalid task handle. HANDLE: " .. tostring(handle) .. " / TASK ID: " .. tostring(taskID) .. " / TASK: " .. tostring(task))
	return task
end

local function GetHandleByTask(task)
	for handle, taskID in pairs(handle2task) do
		if tasks[taskID] == task then
			return handle
		end
	end
end

local function FinishTask(task, handle)
	-- Remove the coroutine to free its resources (coroutines that died from an error retain their resources)
	task.coroutine = nil
	
	-- Stop children
	for child in pairs(task.children) do
		local childTask = handle2task[child] and tasks[handle2task[child]]
		if childTask and childTask.state <= STATE.WAITING then
			child:Stop("Parent finished.")
		end
	end
	
	-- Remove the handle from the list of abandoned handlers so it can be garbage collected
	handle = handle or GetHandleByTask(task)
	if handle then
		abandonedHandles[handle] = nil
	end
	
	-- Trigger the event
	TaskFinishedEvent(handle)
end

local function HandleBreath(handle, interval)
	-- Check the task exists, it's active and this has been called from within the task
	local task = GetTaskByHandle(handle)
	assert(task.state == STATE.ACTIVE, "The task isn't active.")
	assert(task == GetContextTask(), "This can only be called from within the own task")
	
	-- Apply the new interval
	task.interval = type(interval) == "number" and math.max(math.min(interval, INTERVAL.SHORT), INTERVAL.LONG) or INTERVAL.SHORT
	
	-- Yield
	if not Internal.Scheduler.TimeRemaining(task.interval) then
		coroutine.yield()
	end
	
	return handle
end


function methods.Start(handle, waitCondition)
	-- Check the task exists and is pending start
	local task = GetTaskByHandle(handle)
	assert(task.state == STATE.PENDING, "The task has already been started.")

	-- Check if the task needs to be started in ACTIVE or WAITING state
	if waitCondition then
		-- Check the wait condition is valid
		assert(Internal.Wait.Validate(task, waitCondition), "Invalid wait condition.")
		
		task.wait = waitCondition
		task.state = STATE.WAITING
	else
		task.state = STATE.ACTIVE
	end	
	
	-- If started from a known task, assign as children
	local parentTask = GetContextTask()
	if parentTask then
		parentTask.children[handle] = true
	end
	
	return handle
end

function methods.Stop(handle, reason)
	-- Check the task exists and hasn't ended
	local task = GetTaskByHandle(handle)
	assert(task.state <= STATE.WAITING, "The task has already ended.")

	-- Cancel the task
	task.state = STATE.FINISHED
	task.error = type(reason) == "string" and reason or "Task stopped."
	
	-- Check if the task is the one running now (this isn't possible after finishing it)
	local running = task == GetContextTask()
	
	-- Finish it!
	FinishTask(task, handle)
	
	-- If it was running, yield
	if running then
		coroutine.yield()
	end	
	
	return handle
end

function methods.Wait(handle, waitCondition)
	-- Check the task exists and is active
	local task = GetTaskByHandle(handle)
	assert(task.state ~= STATE.PENDING, "The task hasn't been started yet.")
	assert(task.state ~= STATE.WAITING, "The task is already waiting.")
	assert(task.state == STATE.ACTIVE, "The task has already ended.")
	
	-- Check the wait condition is valid
	assert(Internal.Wait.Validate(task, waitCondition), "Invalid wait condition.")

	task.wait = waitCondition
	task.state = STATE.WAITING

	-- If the task is running, yield
	if task == GetContextTask() then
		coroutine.yield()
	end
	
	return handle
end

function methods.Suspend(handle)
	-- Check the task exists and is active or waiting and is not suspended
	local task = GetTaskByHandle(handle)
	assert(task.state ~= STATE.PENDING, "The task hasn't been started yet.")
	assert(task.state <= STATE.WAITING, "The task has already ended.")
	assert(not task.suspended, "The task is already suspended.")
	assert(not abandonedHandles[handle], "The task can't be suspended because it's abandoned.")

	-- Suspend it
	task.suspended = true
	
	-- If the task is running, yield
	if task == GetContextTask() then
		coroutine.yield()
	end
	
	return handle
end

function methods.Resume(handle)
	-- Check the task exists and is suspended and hasn't ended
	local task = GetTaskByHandle(handle)
	assert(task.state <= STATE.WAITING, "The task has already ended.")
	assert(task.suspended, "The task isn't suspended.")
	
	-- Resume it
	task.suspended = false
	
	return handle
end

function methods.Abandon(handle)
	-- Check the task exists, it's active or waiting, it isn't suspended and hasn't been already abandoned
	local task = GetTaskByHandle(handle)
	assert(task.state ~= STATE.PENDING, "The task hasn't been started yet.")
	assert(task.state <= STATE.WAITING, "The task has already ended.")
	assert(not task.suspended, "The task can't be abandoned because it's suspended.")
	assert(not abandonedHandles[handle], "The task is already abandoned.")
	
	-- Abandon it
	abandonedHandles[handle] = true
	for _, task in pairs(tasks) do
		if task and task.children[handle] then
			task.children[handle] = nil
			break
		end
	end
	
	return handle
end

function methods.BreathShort(handle)
	return HandleBreath(handle, INTERVAL.SHORT)
end

function methods.Breath(handle)
	return HandleBreath(handle, INTERVAL.MEDIUM)
end

function methods.BreathLong(handle)
	return HandleBreath(handle, INTERVAL.LONG)
end

function methods.Finished(handle)
	local task = GetTaskByHandle(handle)
	return task.state == STATE.FINISHED
end

function methods.Result(handle)
	-- Check the task exists
	local task = GetTaskByHandle(handle)

	-- Check the task isn't trying to get its own results
	local contextTask = GetContextTask()
	assert(task ~= contextTask, "A task can't get its own results!")
	
	-- Return results or error if the task has finished
	if task.state == STATE.FINISHED then
		if task.error then
			error(task.error, 2)
		else
			return unpack(task.results)
		end
	end
	
	-- If the task isn't finished and this isn't being called from within a task, error
	if not contextTask then
		error("The task hasn't finished yet.", 2)
	end
	
	-- Get the contextTask handle
	local contextHandle = GetHandleByTask(contextTask)
	assert(contextHandle, "Couldn't find context task handle.")

	-- Prepare the wait condition and validate it
	local waitCondition = Public.Wait.Task(handle)
	Internal.Wait.Validate(contextTask, waitCondition)
	
	-- Start the task if needed
	if task.state == STATE.PENDING then
		handle:Start()
	end

	-- Make the context task wait
	contextHandle:Wait(waitCondition)
	
	return handle:Result()
end


Internal.Task.List = tasks
Internal.Task.GetTask = GetTaskByHandle
Internal.Task.GetHandle = GetHandleByTask
Internal.Task.Finish = FinishTask


function Public.Task.Create(taskFunction, addon)
	assert(type(taskFunction) == "function", string.format("Bad argument #1: Expected 'function', got '%s'", type(taskFunction)))
	
	local taskCoroutine = coroutine.create(taskFunction)
	
	local task =
	{
		addon = type(addon) == "string" and addon or Inspect.Addon.Current(),
		coroutine = taskCoroutine,
		children = blUtil.WeakReference.Key(),
		state = STATE.PENDING,
		interval = INTERVAL.SHORT,
		wait = nil,
		suspended = nil,
		error = nil,
		results = nil,
	}
	
	local id = next(freeIDs) or #tasks + 1
	freeIDs[id] = nil
	
	local handle = newproxy(blueprint)
	
	tasks[id] = task
	handle2task[handle] = id
	
	Internal.Scheduler.Add(id)
	
	return handle
end

function Public.Task.Current()
	return GetHandleByTask(GetContextTask())
end
