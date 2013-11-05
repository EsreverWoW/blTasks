-- ***************************************************************************************************************************************************
-- * Dispatcher.lua                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.07.30 / Baanano: First version, spiritual sucessor to LibScheduler                                                                 *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local STATE = Internal.Constants.TASK_STATE

local dispatchedTasks = blUtil.WeakReference.Key()

function Internal.Dispatcher.Run(task)
	if not task then return end

	local handle = nil
	
	-- On first run, pass the task handle to the coroutine
	if not dispatchedTasks[task] then
		handle = Internal.Task.GetHandle(task)
		
		if not handle then
			task.state = STATE.FINISHED
			task.error = "Couldn't find task handle."
		end
		
		dispatchedTasks[task] = true
	end

	if task.state ~= STATE.FINISHED then
		-- Credit execution to the addon that created the task
		local result = nil
		Utility.Dispatch(
			function()
				result = { coroutine.resume(task.coroutine, handle) }
			end, task.addon, string.format("%s (running task for %s)", addonID, task.addon))
			
		-- Check if the task has finished
		if not table.remove(result, 1) then
			task.state = STATE.FINISHED
			task.error = result[1]
		elseif coroutine.status(task.coroutine) == "dead" then
			task.state = STATE.FINISHED
			task.results = result
		end
	end
		
	-- If the task has finished, notify
	if task.state == STATE.FINISHED then
		Internal.Task.Finish(task, handle)
	end
end
