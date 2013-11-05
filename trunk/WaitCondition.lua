-- ***************************************************************************************************************************************************
-- * WaitCondition.lua                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.07.30 / Baanano: First version, spiritual sucessor to LibScheduler                                                                 *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local STATE = Internal.Constants.TASK_STATE
local CONDITION = Internal.Constants.WAIT_CONDITION
local VALID_INTERACTIONS = {}
local VALID_QUEUES = {}

for interaction in pairs(Inspect.Interaction()) do VALID_INTERACTIONS[interaction] = true end
for queue in pairs(Inspect.Queue.Status()) do VALID_QUEUES[queue] = true end

local waitConditions = blUtil.WeakReference.Key()
local blueprint, methods, meta = blUtil.Handle.Blueprint()

local function CreateCondition(condition)
	-- Create new condition userdata
	local result = newproxy(blueprint)
	
	-- Put it on the table
	waitConditions[result] = condition
	
	return result
end

local function GetCondition(handle)
	local condition = handle and waitConditions[handle]
	assert(condition, "Invalid task wait condition handle.")
	return condition
end

local function CheckDeadlock(task, condition, avoidTasks)
	local conditionType = condition[1]

	-- AND
	if conditionType == CONDITION.AND then
		return CheckDeadlock(task, condition[2], avoidTasks) and CheckDeadlock(task, condition[3], avoidTasks)
	
	-- OR
	elseif conditionType == CONDITION.OR then
		return CheckDeadlock(task, condition[2], avoidTasks) or CheckDeadlock(task, condition[3], avoidTasks)
	
	-- TASK
	elseif conditionType == CONDITION.TASK then
		local nextTaskHandle = condition[2]
		if not nextTaskHandle then return true end

		local nextTask = Internal.Task.GetTask(nextTaskHandle)
		if nextTask.state ~= STATE.WAITING then return true end
		
		if avoidTasks[nextTask] then return false end

		local nextCondition = nextTask.wait and waitConditions[nextTask.wait]
		if not nextCondition then return true end
		
		local nextAvoidTasks = {}
		for handle in pairs(avoidTasks) do nextAvoidTasks[handle] = true end
		nextAvoidTasks[task] = true
				
		return CheckDeadlock(nextTask, nextCondition, nextAvoidTasks)
	
	-- CHILDREN
	elseif conditionType == CONDITION.CHILDREN then
		for child in pairs(task.children) do
			if not CheckDeadlock(task, { CONDITION.TASK, child }, avoidTasks) then return false end
		end
		return true
	
	end

	return true
end

local function EvaluateCondition(task, handle)
	handle = handle or task.wait
	
	local condition = GetCondition(handle)
	local conditionType = condition[1]
	
	-- AND
	if conditionType == CONDITION.AND then
		return EvaluateCondition(task, condition[2]) and EvaluateCondition(task, condition[3])
	
	-- OR
	elseif conditionType == CONDITION.OR then
		return EvaluateCondition(task, condition[2]) or EvaluateCondition(task, condition[3])
	
	-- TASK
	elseif conditionType == CONDITION.TASK then
		local taskHandle = condition[2]
		return not taskHandle or taskHandle:Finished()
	
	-- CHILDREN
	elseif conditionType == CONDITION.CHILDREN then
		for child in pairs(task.children) do
			if not child:Finished() then return false end
		end
		return true
	
	-- TIMESTAMP
	elseif conditionType == CONDITION.TIMESTAMP then
		return os.time() >= condition[2]

	-- TIMESPAN
	elseif conditionType == CONDITION.TIMESPAN then
		return Inspect.Time.Real() >= condition[2]
	
	-- FRAME
	elseif conditionType == CONDITION.FRAME then
		return Inspect.Time.Frame() > condition[2]

	-- INTERACTION
	elseif conditionType == CONDITION.INTERACTION then
		return Inspect.Interaction(condition[2])
	
	-- QUEUE
	elseif conditionType == CONDITION.QUEUE then
		if condition[3] then
			return Inspect.Queue.Status(condition[2], condition[3])
		else
			return Inspect.Queue.Status(condition[2])
		end		
		
	end
	
	-- Unknown condition
	return true
end


function meta.__add(a, b)
	return CreateCondition({ CONDITION.OR, GetCondition(a) and a, GetCondition(b) and b })
end

function meta.__mul(a, b)
	return CreateCondition({ CONDITION.AND, GetCondition(a) and a, GetCondition(b) and b })
end


function Internal.Wait.Validate(task, handle)
	local condition = task and handle and waitConditions[handle]
	
	if condition then
		assert(CheckDeadlock(task, condition, {}), "Deadlock detected.")
	end
	
	return condition and true or false
end

function Internal.Wait.Check(task)
	if EvaluateCondition(task) then
		task.state = STATE.ACTIVE
		task.wait = nil
	end
end


function Public.Wait.Or(a, b)
	return a + b
end

function Public.Wait.And(a, b)
	return a * b
end

function Public.Wait.Task(taskHandle)
	-- The task handle is put on a weak table so the condition doesn't prevent its collection
	return CreateCondition(blUtil.WeakReference.Value({ CONDITION.TASK, Internal.Task.GetTask(taskHandle) and taskHandle }))
end

function Public.Wait.Children()
	return CreateCondition({ CONDITION.CHILDREN })
end

function Public.Wait.Timestamp(timestamp)
	assert(type(timestamp) == "number", "Invalid timestamp.")
	return CreateCondition({ CONDITION.TIMESTAMP, timestamp })
end

function Public.Wait.Timespan(timespan)
	assert(type(timespan) == "number", "Invalid timespan.")
	return CreateCondition({ CONDITION.TIMESPAN, Inspect.Time.Real() + timespan })
end

function Public.Wait.Frame()
	return CreateCondition({ CONDITION.FRAME, Inspect.Time.Frame() })
end

function Public.Wait.Interaction(interaction)
	assert(interaction and VALID_INTERACTIONS[interaction], "Invalid interaction.")
	return CreateCondition({ CONDITION.INTERACTION, interaction })
end

function Public.Wait.Queue(queue, size)
	assert(queue and VALID_QUEUES[queue], "Invalid queue.")
	assert(not size or type(size) == "number", "Invalid size.")
	return CreateCondition({ CONDITION.QUEUE, queue, size })
end
