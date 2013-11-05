-- ***************************************************************************************************************************************************
-- * Prolog.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.27 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier

-- Initialize Internal table
addonData.Internal = addonData.Internal or {}
local Internal = addonData.Internal

-- Initialize Internal hierarchy
--Internal.MODULE = {}

-- Initialize Public table
_G[addonID] = _G[addonID] or {}
addonData.Public = _G[addonID]
local Public = addonData.Public

-- Initialize Public hierarchy
Public.Copy = {}
Public.Handle = {}
Public.Player = {}
Public.WeakReference = {}
