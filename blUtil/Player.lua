-- ***************************************************************************************************************************************************
-- * Player.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * 0.0.1 / 2013.09.29 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonDetail, addonData = ...
local addonID = addonDetail.identifier
local Internal, Public = addonData.Internal, addonData.Public

local playerName = nil

function Public.Player.Name()
	if not playerName then
		playerName = Inspect.Unit.Detail("player")
		playerName = playerName and playerName.name or nil
	end
	
	return playerName
end
