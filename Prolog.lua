-- ***************************************************************************************************************************************************
-- * Prolog.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.22 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier

-- Initialize Internal table
addonData.Internal = addonData.Internal or {}
local Internal = addonData.Internal

-- Initialize Internal hierarchy
Internal.Constants = {}
Internal.Task = {}
Internal.Scheduler = {}
Internal.Dispatcher = {}
Internal.Wait = {}

-- Initialize Public table
_G[addonID] = _G[addonID] or {}
addonData.Public = _G[addonID]
local Public = addonData.Public

-- Initialize Public hierarchy
Public.Task = {}
Public.Wait = {}
