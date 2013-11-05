-- ***************************************************************************************************************************************************
-- * Handle.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.27 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

function Public.Handle.Blueprint()
	local blueprint = newproxy(true)
	local meta, methods = getmetatable(blueprint), {}
	
	meta.__index = methods
	
	return blueprint, methods, meta
end
