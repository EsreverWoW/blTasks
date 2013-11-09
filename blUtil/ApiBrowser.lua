-- ***************************************************************************************************************************************************
-- * ApiBrowser.lua                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.5.0 / 2013.11.06 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo = ...
local addonID, addonLongName = addonInfo.identifier, addonInfo.toc.Name
if not ApiBrowser then return end

local summary =[[blUtil is a library containing commonly used stuff.]]

local symbols = {}

symbols["blUtil.Copy.Shallow"] =
{
	summary = [[Creates a shallow copy of a table. The metatable, if any, isn't copied.]],
	signatures =
	{
		"copy = blUtil.Copy.Shallow(origin) -- table <-- table", 
	},
	parameter =
	{
		["origin"] = "Table to copy.",
	},
	result = { ["copy"] = "Shallow copy of the table.", },
	type = "function",
}

symbols["blUtil.Copy.Deep"] =
{
	summary = [[Creates a deep copy of the values of a table. Neither the metatable, if any, nor keys are copied.]],
	signatures =
	{
		"copy = blUtil.Copy.Deep(origin) -- table <-- table", 
	},
	parameter =
	{
		["origin"] = "Table to copy.",
	},
	result = { ["copy"] = "Deep copy of the table.", },
	type = "function",
}

symbols["blUtil.Handle.Blueprint"] =
{
	summary = [[Creates a type blueprint and attaches to it a metatable and an index table where methods for that type can be added.]],
	signatures =
	{
		"blueprint, index, metatable = blUtil.Handle.Blueprint() -- userdata, table, table <-- void", 
	},
	parameter = {},
	result =
	{
		["blueprint"] = "Type blueprint, use newproxy(blueprint) to create instances of the type.",
		["index"] = "Shared index table for all instances of the type.",
		["metatable"] = "Shared metatable for all instances of the type.",
	},
	type = "function",
}

symbols["blUtil.Player.Name"] =
{
	summary = [[Returns the player name, or nil if it isn't available.]],
	signatures =
	{
		"playerName = blUtil.Player.Name() -- string <-- void", 
	},
	parameter = {},
	result =
	{
		["playerName"] = "Name of the player.",
	},
	type = "function",
}

symbols["blUtil.WeakReference.Key"] =
{
	summary = [[Applies a weak key metatable to the supplied table, or creates a new one if needed.]],
	signatures =
	{
		"weakTable = blUtil.WeakReference.Key() -- table <-- void", 
		"weakTable = blUtil.WeakReference.Key(origin) -- table <-- table", 
	},
	parameter =
	{
		["origin"] = "Table to apply the weak key metatable.",
	},
	result = { ["weakTable"] = "The supplied table, or a new empty one, with the weak key metatable applied.", },
	type = "function",
}

symbols["blUtil.WeakReference.Value"] =
{
	summary = [[Applies a weak value metatable to the supplied table, or creates a new one if needed.]],
	signatures =
	{
		"weakTable = blUtil.WeakReference.Value() -- table <-- void", 
		"weakTable = blUtil.WeakReference.Value(origin) -- table <-- table", 
	},
	parameter =
	{
		["origin"] = "Table to apply the weak value metatable.",
	},
	result = { ["weakTable"] = "The supplied table, or a new empty one, with the weak value metatable applied.", },
	type = "function",
}

symbols["blUtil.WeakReference.Full"] =
{
	summary = [[Applies a weak key and value metatable to the supplied table, or creates a new one if needed.]],
	signatures =
	{
		"weakTable = blUtil.WeakReference.Full() -- table <-- void", 
		"weakTable = blUtil.WeakReference.Full(origin) -- table <-- table", 
	},
	parameter =
	{
		["origin"] = "Table to apply the weak key and value metatable.",
	},
	result = { ["weakTable"] = "The supplied table, or a new empty one, with the weak key and value metatable applied.", },
	type = "function",
}

ApiBrowser.AddLibraryWithRiftLikeCatalogIndex(addonID, addonLongName, summary, symbols)
