-- ***************************************************************************************************************************************************
-- * WeakReference.lua                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.27 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local weakKeyMT = { __mode = "k" }
local weakValueMT = { __mode = "v" }
local weakFullMT = { __mode = "kv" }

function Public.WeakReference.Key(tab)
	return setmetatable(type(tab) == "table" and tab or {}, weakKeyMT)
end

function Public.WeakReference.Value(tab)
	return setmetatable(type(tab) == "table" and tab or {}, weakValueMT)
end

function Public.WeakReference.Full(tab)
	return setmetatable(type(tab) == "table" and tab or {}, weakFullMT)
end
