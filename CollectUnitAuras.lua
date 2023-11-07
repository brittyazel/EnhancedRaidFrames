-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

EnhancedRaidFrames.unitAuras = {} -- Matrix to keep a list of all auras on all units
local unitAuras = EnhancedRaidFrames.unitAuras --local handle for the above table

------------------------------------------------
---------- Update Auras for all units ----------
------------------------------------------------

--- This functions is bound to the UNIT_AURA event and is used to track auras on all raid frame units
--- It uses the C_UnitAuras API that was added in 10.0
--- Unit aura information is stored in the unitAuras table
function EnhancedRaidFrames:UpdateUnitAuras(_, unit, payload)
	-- Only process player, raid, and party units
	if not string.find(unit, "player") and not string.find(unit, "raid") and not string.find(unit, "party") then
		return
	end

	-- Create the main table for the unit
	if not unitAuras[unit] then
		unitAuras[unit] = {}
	end
	
	-- If we get a full update signal, wipe the table and rescan all auras for the unit
	if payload.isFullUpdate then
		-- Clear out the table
		table.wipe(unitAuras[unit])
		-- These helper functions will iterate over all buffs and debuffs on the unit
		-- and call the addToAuraTable() function for each one
		AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(auraData)
			EnhancedRaidFrames.addToAuraTable(unit, auraData)
		end, true);
		AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(auraData)
			EnhancedRaidFrames.addToAuraTable(unit, auraData)
		end, true);
		return
	end

	-- If new auras are added, update the table with their payload information
	if payload.addedAuras then
		for _, auraData in pairs(payload.addedAuras) do
			EnhancedRaidFrames.addToAuraTable(unit, auraData)
		end
	end

	-- If an aura has been updated, query the updated information and add it to the table
	if payload.updatedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.updatedAuraInstanceIDs) do
			if unitAuras[unit][auraInstanceID] then
				local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
				EnhancedRaidFrames.addToAuraTable(unit, auraData)
			end
		end
	end

	-- If an aura has been removed, remove it from the table
	if payload.removedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.removedAuraInstanceIDs) do
			if unitAuras[unit][auraInstanceID] then
				unitAuras[unit][auraInstanceID] = nil
			end
		end
	end
end

--- Prior to WoW 10.0, this function was used to track auras on all raid frame units
--- Unit auras are now tracked using the UNIT_AURA event and APIs in Retail
--- Unit aura information is stored in the unitAuras table
function EnhancedRaidFrames:UpdateUnitAuras_Legacy(unit)
	-- Create or clear out the tables for the unit
	unitAuras[unit] = {}

	-- Get all unit buffs
	local i = 1
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID

		if UnitAura then
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = UnitAura(unit, i, "HELPFUL")
		else
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = self.UnitAuraWrapper(unit, i, "HELPFUL") --for wow classic. This is the LibClassicDurations wrapper
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		--it's important to use the 4th argument in string.find to turn of pattern matching, otherwise things with parentheses in them will fail to be found
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(" "..spellID.." ", nil, true) then -- Only add the spell if we're watching for it
			local auraTable = {}
			auraTable.auraType = "buff"
			auraTable.auraIndex = i
			auraTable.auraName = auraName:lower()
			auraTable.icon = icon
			auraTable.count = count
			auraTable.duration = duration
			auraTable.expirationTime = expirationTime
			auraTable.castBy = castBy
			auraTable.spellID = spellID

			table.insert(unitAuras[unit], auraTable)
		end
		i = i + 1
	end

	-- Get all unit debuffs
	i = 1
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID, debuffType

		if UnitAura then
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  = UnitAura(unit, i, "HARMFUL")
		else
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  = self.UnitAuraWrapper(unit, i, "HARMFUL") --for wow classic. This is the LibClassicDurations wrapper
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		--it's important to use the 4th argument in string.find to turn off pattern matching, otherwise things with parentheses in them will fail to be found
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(" "..spellID.." ", nil, true) or (debuffType and self.allAuras:find(" "..debuffType:lower().." ", nil, true)) then -- Only add the spell if we're watching for it
			local auraTable = {}
			auraTable.auraType = "debuff"
			auraTable.auraIndex = i
			auraTable.auraName = auraName:lower()
			auraTable.icon = icon
			auraTable.count = count
			if debuffType then
				auraTable.debuffType = debuffType:lower()
			end
			auraTable.duration = duration
			auraTable.expirationTime = expirationTime
			auraTable.castBy = castBy
			auraTable.spellID = spellID

			table.insert(unitAuras[unit], auraTable)
		end
		i = i + 1
	end
end

--function to add or update an aura to the unitAuras table
function EnhancedRaidFrames.addToAuraTable(thisUnit, thisAuraData)
	if not thisAuraData then
		return
	end

	local aura = {}
	aura.auraInstanceID = thisAuraData.auraInstanceID
	if thisAuraData.isHelpful then
		aura.auraType = "buff"
	elseif thisAuraData.isHarmful then
		aura.auraType = "debuff"
	end
	aura.auraName = thisAuraData.name:lower()
	aura.icon = thisAuraData.icon
	aura.count = thisAuraData.applications
	aura.duration = thisAuraData.duration
	aura.expirationTime = thisAuraData.expirationTime
	aura.castBy = thisAuraData.sourceUnit
	aura.spellID = thisAuraData.spellId

	-- Update the aura elements if it already exists
	if unitAuras[thisUnit][aura.auraInstanceID] then
		for k,v in pairs(aura) do
			unitAuras[thisUnit][aura.auraInstanceID][k] = v
		end
	else
		unitAuras[thisUnit][aura.auraInstanceID] = aura
	end
end