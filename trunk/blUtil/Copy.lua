-- ***************************************************************************************************************************************************
-- * Copy.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.29 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

function Public.Copy.Shallow(origin)
	if type(origin) ~= "table" then return origin end
	
	local copy = {}
	
	for key, value in pairs(origin) do 
		copy[key] = value 
	end
	
	return copy
end

function Public.Copy.Deep(origin)
	if type(origin) ~= "table" then return origin end
	
	local copy = {}
	
	for key, value in pairs(origin) do 
		copy[key] = Public.Copy.Deep(value)
	end
	
	return copy
end
