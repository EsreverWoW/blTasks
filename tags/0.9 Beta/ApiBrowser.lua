-- ***************************************************************************************************************************************************
-- * ApiBrowser.lua                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.28 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo = ...
local addonID, addonLongName, addonShortName = addonInfo.identifier, addonInfo.toc.Name, addonInfo.toc.NameShort
if not ApiBrowser then return end

local summary = addonShortName .. [[ is a library to split code execution over multiple frames to avoid lagging your users and being barked by the Evil Watchdog.]]

local symbols = {}

symbols[addonID .. ".Task.Create"] =
{
	summary = [[Creates a new task, without starting it.]],
	signatures =
	{
		"taskHandle = " .. addonID .. ".Task.Create(func) -- TaskHandle <-- function", 
		"taskHandle = " .. addonID .. ".Task.Create(func, addonIdentifier) -- TaskHandle <-- function, string",
	},
	parameter =
	{
		["func"] = "The function you want to be executed by the task. It'll be passed the task handle as first argument when started.",
		["addonIdentifier"] = "Identifier of the addon to attribute execution of the task to. Defaults to <<:Rift:Inspect.Addon.Current|Inspect.Addon.Current>>.",
	},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols[addonID .. ".Task.Current"] =
{
	summary = [[Returns a task handle to the task that is being executed, if any.]],
	signatures = { "taskHandle = " .. addonID .. ".Task.Current() -- TaskHandle <-- void", },
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task currently in execution, or nil if no task is being executed.", },
	type = "function",
}

symbols["TaskHandle"] =
{
	summary = [[A handle to control the execution of the task.


<u>Warnings:</u>
 - If no strong reference to the handle is kept, the task will be stopped shortly after, unless it has been <<:TaskHandle:Abandon|abandoned>>.
 
 - Keeping a strong reference to a finished task handle could prevent the resources acquired by it from being freed, so don't hold handles longer than needed.
 
 - Certain API methods or events could expose you task handles created by other addons. It'd be polite not to hold strong references to those.]],
	type = "type",
}

symbols["TaskHandle:Start"] =
{
	summary = [[Starts running the task, with an optional initial <<:WaitCondition|wait condition>>.


Notes:
 - Trying to start a started task will result on an error.
 - If the task is started by another task, it'll be marked as its <<:Task Hierarchy|child>>.
 - The task won't be executed immediately, but when the <<:Scheduler|scheduler>> considers appropiate.]],
	signatures =
	{
		"taskHandle = TaskHandle:Start() -- TaskHandle <-- void",
		"taskHandle = TaskHandle:Start(condition) -- TaskHandle <-- WaitCondition",
	},
	parameter = { ["condition"] = "Initial wait condition.", },
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Stop"] =
{
	summary = [[Finishes the task, with an optional error message.


Notes:
 - Trying to stop a finished task will result on an error.
 - Any <<:Task Hierarchy|child>> task that hasn't finished yet will be stopped too, unless it has been <<:TaskHandle:Abandon|abandoned>>.]],
	signatures =
	{
		"taskHandle = TaskHandle:Stop() -- TaskHandle <-- void",
		"taskHandle = TaskHandle:Stop(message) -- TaskHandle <-- string",
	},
	parameter = { ["message"] = "Error message to show when the task results are requested.", },
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Wait"] =
{
	summary = [[Prevents execution of the task until the given <<:WaitCondition|wait condition>> is met.


Notes:
 - The task must be active, that is, it must have been started, not have finished yet, and not be already waiting on another condition. It can be <<:TaskHandle:Suspend|suspended>>, though.]],
	signatures =
	{
		"taskHandle = TaskHandle:Wait(condition) -- TaskHandle <-- WaitCondition",
	},
	parameter = { ["condition"] = "Wait condition.", },
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Suspend"] =
{
	summary = [[Suspends execution of the task until explicitly <<:TaskHandle:Resume|resumed>>.


Notes:
 - The task must have been started and not have finished yet.
 - Trying to suspend a suspended task will result on an error.
 - <<:TaskHandle:Abandon|Abandoned>> tasks can't be suspended.]],
	signatures =
	{
		"taskHandle = TaskHandle:Suspend() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Resume"] =
{
	summary = [[Resumes execution of a <<:TaskHandle:Suspend|suspended>> task.


Notes:
 - The task must be <<:TaskHandle:Suspend|suspended>> and not have finished yet.
 - If the task was given a <<:WaitCondition|wait condition>>, it won't be resumed until it's met, even if the condition was temporarily met while it was suspended.]],
	signatures =
	{
		"taskHandle = TaskHandle:Resume() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Abandon"] =
{
	summary = [[Marks a task as abandoned and orphans it from its <<:Task Hierarchy|parent>>, if it had one.
	
Abandoned tasks aren't <<:TaskHandle|stopped automatically>> when no strong reference to them is kept, so they'll run until they finish unless you <<:TaskHandle:Stop|stop>> them manually.


Notes:
 - The task must have been started and not have finished yet.
 - Trying to abandon an abandoned task will result on an error.
 - <<:TaskHandle:Suspend|Suspended>> tasks can't be abandoned.]],
	signatures =
	{
		"taskHandle = TaskHandle:Abandon() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:BreathShort"] =
{
	summary = [[Signals to the <<:Scheduler|scheduler>> that the task is about to start a time consuming block of code, of shorter duration than <<:TaskHandle:Breath>>.
	
The scheduler will check the remaining time available and decide if it allows the task to continue immediately or defers it until more time is available.


<u>Warning:</u>
As the scheduler may decide to wait until the next frame or run other tasks, the global state may have changed when this function returns.
If that can be an issue, you should use some kind of concurrency control mechanism.


Notes:
 - The task must be active, that is, it must have been started, not have finished yet, and not be already waiting on another condition.
 - This can only be called from within the own task.]],
	signatures =
	{
		"taskHandle = TaskHandle:BreathShort() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Breath"] =
{
	summary = [[Signals to the <<:Scheduler|scheduler>> that the task is about to start a time consuming block of code.
	
The scheduler will check the remaining time available and decide if it allows the task to continue immediately or defers it until more time is available.


<u>Warning:</u>
As the scheduler may decide to wait until the next frame or run other tasks, the global state may have changed when this function returns.
If that can be an issue, you should use some kind of concurrency control mechanism.


Notes:
 - The task must be active, that is, it must have been started, not have finished yet, and not be already waiting on another condition.
 - This can only be called from within the own task.]],
	signatures =
	{
		"taskHandle = TaskHandle:Breath() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:BreathLong"] =
{
	summary = [[Signals to the <<:Scheduler|scheduler>> that the task is about to start a time consuming block of code, of longer duration than <<:TaskHandle:Breath>>.
	
The scheduler will check the remaining time available and decide if it allows the task to continue immediately or defers it until more time is available.


<u>Warning:</u>
As the scheduler may decide to wait until the next frame or run other tasks, the global state may have changed when this function returns.
If that can be an issue, you should use some kind of concurrency control mechanism.


Notes:
 - The task must be active, that is, it must have been started, not have finished yet, and not be already waiting on another condition.
 - This can only be called from within the own task.]],
	signatures =
	{
		"taskHandle = TaskHandle:BreathLong() -- TaskHandle <-- void",
	},
	parameter = {},
	result = { ["taskHandle"] = "Handle to the task.", },
	type = "function",
}

symbols["TaskHandle:Finished"] =
{
	summary = [[Checks if the task has finished.]],
	signatures =
	{
		"finished = TaskHandle:Finished() -- bool <-- void",
	},
	parameter = {},
	result = { ["finished"] = "A boolean indicating if the task has finished or not.", },
	type = "function",
}

symbols["TaskHandle:Result"] =
{
	summary = [[Gets the results of the task, or any error that ocurred during its execution.


<u>Warning:</u>
Errors will be rethrown when this method is called, including those that may have been caused by <<:TaskHandle:Stop|stopping>> the task, so ensure to handle them appropiately.


Notes:
 - Trying to get the results of a task that hasn't finished yet from within a task will <<:TaskHandle:Start|start>> the later, if needed, and make the former <<:TaskHandle:Wait|wait>> until it finishes. If that would result on a deadlock, an error will be thrown instead.
 - Trying to get the results of a task that hasn't finished yet from outside a task will result on an error.
 - A task can't get its own results!]],
	signatures =
	{
		"... = TaskHandle:Result() -- unknown <-- void",
	},
	parameter = {},
	result = { ["..."] = "Values returned by the task function.", },
	type = "function",
}

symbols["Event." .. addonID .. ".Task.Finished"] =
{
	summary = [[Signals a task has finished.]],
	signatures = { "Event." .. addonID .. ".Task.Finished(taskHandle)", },
	parameter = { ["taskHandle"] = "Handle to the task.", },
	type = "event",
}

symbols[addonID .. ".Wait.Or"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met while any of its subconditions is met.
	
	
<u>Warning</u>:
This function is deprecated and will be removed and replaced by the more generic "Any" in a future version.
As you can achieve the same result by adding (+) subconditions, please use that syntax instead.]],
	signatures = { "condition = " .. addonID .. ".Wait.Or(subcondition, otherSubcondition) -- WaitCondition <-- WaitCondition, WaitCondition", },
	parameter =
	{
		["subcondition"] = "A wait condition.",
		["otherSubcondition"] = "Another wait condition.",
	},
	result = { ["condition"] = "A wait condition that will be met while any of the subconditions is met.", },
	type = "function",
}

symbols[addonID .. ".Wait.And"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met while all its subconditions are met.
	
	
<u>Warning</u>:
This function is deprecated and will be removed and replaced by the more generic "All" in a future version.
As you can achieve the same result by multiplying (*) subconditions, please use that syntax instead.]],
	signatures = { "condition = " .. addonID .. ".Wait.And(subcondition, otherSubcondition) -- WaitCondition <-- WaitCondition, WaitCondition", },
	parameter =
	{
		["subcondition"] = "A wait condition.",
		["otherSubcondition"] = "Another wait condition.",
	},
	result = { ["condition"] = "A wait condition that will be met while all the subconditions are met.", },
	type = "function",
}

symbols[addonID .. ".Wait.Task"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met after the supplied task finishes.]],
	signatures = { "condition = " .. addonID .. ".Wait.Task(taskHandle) -- WaitCondition <-- TaskHandle", },
	parameter = { ["taskHandle"] = "Handle to task to wait for.", },
	result = { ["condition"] = "Wait condition that will be met after the supplied task finishes.", },
	type = "function",
}

symbols[addonID .. ".Wait.Children"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met after all <<:Task Hierarchy|children>> of the task finish.]],
	signatures = { "condition = " .. addonID .. ".Wait.Children() -- WaitCondition <-- void", },
	parameter = {},
	result = { ["condition"] = "Wait condition that will be met after all children of the task finish.", },
	type = "function",
}

symbols[addonID .. ".Wait.Timestamp"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met after a timestamp is reached.]],
	signatures = { "condition = " .. addonID .. ".Wait.Timestamp(timestamp) -- WaitCondition <-- number", },
	parameter = { ["timestamp"] = "Timestamp to wait until, in the same timespace than os.time.", },
	result = { ["condition"] = "Wait condition that will be met after the timestamp is reached.", },
	type = "function",
}

symbols[addonID .. ".Wait.Timespan"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met after a number of seconds have elapsed.]],
	signatures = { "condition = " .. addonID .. ".Wait.Timespan(seconds) -- WaitCondition <-- number", },
	parameter = { ["seconds"] = "Number of seconds to wait.", },
	result = { ["condition"] = "Wait condition that will be met after the specified seconds have elapsed.", },
	type = "function",
}

symbols[addonID .. ".Wait.Frame"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met after the current frame finishes.]],
	signatures = { "condition = " .. addonID .. ".Wait.Frame() -- WaitCondition <-- void", },
	parameter = {},
	result = { ["condition"] = "Wait condition that will be met after the current frame finishes.", },
	type = "function",
}

symbols[addonID .. ".Wait.Interaction"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met while the interaction type is available.]],
	signatures = { "condition = " .. addonID .. ".Wait.Interaction(interaction) -- WaitCondition <-- string", },
	parameter = { ["interaction"] = "Name of the interaction type. Check <<Rift:Inspect.Interaction>> for valid values.", },
	result = { ["condition"] = "Wait condition that will be met while the interaction type is available.", },
	type = "function",
}

symbols[addonID .. ".Wait.Queue"] =
{
	summary = [[Creates a <<:WaitCondition|wait condition>> that will be met while the supplied queue has enough available slots.]],
	signatures =
	{
		"condition = " .. addonID .. ".Wait.Queue(queue) -- WaitCondition <-- string",
		"condition = " .. addonID .. ".Wait.Queue(queue, size) -- WaitCondition <-- string, number",
	},
	parameter =
	{
		["queue"] = "Identifier of the queue. Check <<Rift:Inspect.Queue.Status>> for valid values.",
		["size"] = "Number of available slots needed. Defaults to 1 if not provided.",
	},
	result = { ["condition"] = "A wait condition that will be met while the queue has at least the requested number of available slots.", },
	type = "function",
}

symbols["WaitCondition"] =
{
	summary = [[A token object used to make tasks know which conditions they must wait on.

WaitConditions can be added (+) to create a new condition that will be met when any of the operands is met.
They can also be multiplied (*) to create a new condition that will be met when all the operands are met.


Note:
 - Certain wait conditions could cause a deadlock (a circle of wait dependences between tasks). When a potential deadlock is detected, an error is thrown.]],
	type = "type",
}

symbols["Scheduler"] =
{
	summary = "Tasks <<:" .. addonID .. [[.Task.Create|created>> with this library will be regularly run by a scheduler routine since they <<:TaskHandle:Start|start>> until they terminate or are <<:TaskHandle:Stop|stopped>>.
	
The scheduler measures the time spent by tasks, ensuring they don't run for a long time, to prevent lagging the user or being warned or killed by the <<:Rift:Inspect.System.Watchdog|Evil Watchdog>>.

As Lua's multitasking model is collaborative, your task will have to <<:TaskHandle:Breath|tell the scheduler>> when it's about to execute a potentially time consuming block of code, so the scheduler can evaluate whether it's appropiate to run it immediately, or wait until enough time is available. While [currently] the scheduler won't penalize you for not yielding, it would defeat the purpose of using this library not doing it.

The scheduler also tries to ensure that all tasks are assigned some CPU time so they don't starve. Currently, the scheduler selects which task to run using a round-robin algorithm, though other scheduling algorithms could be added or replace the current one in the future, so don't rely on this implementation detail.]],
}

symbols["Task Hierarchy"] =
{
	summary = [[The library keeps a hierarchical list of tasks that defines a parent-child relationship between tasks.
	
<u>Parent - children rules</u>
When a task is <<:TaskHandle:Start|started>>, the library checks if it has been done from within another task and, if so, marks the newly started task as a child of the former.
Tasks that aren't started from within another task are known as 'orphan', and therefore lack a parent, though they can have children of their own.
<<:TaskHandle:Abandon|Abandoning>> a task will also make it orphan.
Note this relationship is established at <<:TaskHandle:Start>> time, not at creation.

When a task is finished (either because it completes, throws an error or is automatically or manually <<:TaskHandle:Stop|stopped>>), all its children will be stopped. 

There is also a <<:blTasks.Wait.Children|wait condition>> that makes the parent task wait until all its children finish.

You can use these rules on your advantage to spawn children tasks that work in parallel, or terminate a whole tree of descendant tasks when the job they were doing isn't needed anymore, without needing to keep track of them yourself.
However, don't forget the <<:TaskHandle|reference rule>>: If you don't keep at least one strong reference to the task handles, their tasks could be stopped before they have finished their job. Usually, storing them in a local variable will suffice.]],
}

ApiBrowser.AddLibraryWithRiftLikeCatalogIndex(addonID, addonLongName, summary, symbols)
