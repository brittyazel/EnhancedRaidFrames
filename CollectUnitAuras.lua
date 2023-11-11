-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local addonName, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

EnhancedRaidFrames.unitAuras = {} -- Matrix to keep a list of all auras on all units
local unitAuras = EnhancedRaidFrames.unitAuras --local handle for the above table

-- Setup LibClassicDurations
if EnhancedRaidFrames.isWoWClassicEra then
	local LibClassicDurations = LibStub("LibClassicDurations")
	LibClassicDurations:Register(addonName) -- tell library it's being used and should start working
	EnhancedRaidFrames.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper -- wrapper function to use in place of UnitAura
end
-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- This function scans all raid frame units and updates the unitAuras table with all auras on each unit
function EnhancedRaidFrames:UpdateAllAuras()
	-- Clear out the unitAuras table
	table.wipe(unitAuras)

	-- Iterate over all raid frame units and force a full update
	CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
		self:UpdateUnitAuras("", frame.unit, {isFullUpdate = true})
	end)
end

--- This function scans all raid frame units and updates the unitAuras table with all auras on each unit
function EnhancedRaidFrames:UpdateAllAuras_Classic()
	-- Clear out the unitAuras table
	table.wipe(unitAuras)

	-- Iterate over all raid frame units and force a full update
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
		self:UpdateUnitAuras_Classic("", frame.unit)
	end)
end

--- This functions is bound to the UNIT_AURA event and is used to track auras on all raid frame units
--- It uses the C_UnitAuras API that was added in 10.0
--- Unit aura information is stored in the unitAuras table
function EnhancedRaidFrames:UpdateUnitAuras(_, unit, payload)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
		return
	end

	if not unit then
		return
	end

	-- Only process player, raid, party, and arena units
	if not string.find(unit, "player") and not string.find(unit, "raid") 
			and not string.find(unit, "party") and not string.find(unit, "arena") then
		return
	end
	
	if not UnitExists(unit) then
		return
	end
	
	-- Create the main table for the unit
	if not unitAuras[unit] then
		unitAuras[unit] = {}
		payload.isFullUpdate = true --force a full update if we don't have a table for the unit yet
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
		-- If we added auras, we need to force a targeted update on the unit to keep good responsiveness
		self:TargetedFrameUpdate(unit)
	end

	-- If an aura has been updated, query the updated information and add it to the table
	if payload.updatedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.updatedAuraInstanceIDs) do
			unitAuras[unit][auraInstanceID] = nil
			--it's possible for auraData to return nil if the aura was removed just prior to us querying it
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			EnhancedRaidFrames.addToAuraTable(unit, auraData)
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

--function to add or update an aura to the unitAuras table
function EnhancedRaidFrames.addToAuraTable(unit, auraData)
	if not auraData then
		return
	end
	
	local aura = {}
	aura.auraInstanceID = auraData.auraInstanceID
	if auraData.isHelpful then
		aura.auraType = "buff"
	elseif auraData.isHarmful then
		aura.auraType = "debuff"
	end
	aura.auraName = auraData.name:lower()
	aura.icon = auraData.icon
	aura.count = auraData.applications
	aura.duration = auraData.duration
	aura.expirationTime = auraData.expirationTime
	aura.castBy = auraData.sourceUnit
	aura.spellID = auraData.spellId
	
	unitAuras[unit][aura.auraInstanceID] = aura
end

--- Prior to WoW 10.0, this function was used to track auras on all raid frame units
--- Unit auras are now tracked using the UNIT_AURA event and APIs in Retail
--- Unit aura information is stored in the unitAuras table
function EnhancedRaidFrames:UpdateUnitAuras_Classic(_, unit)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
		return
	end

	if not unit then
		return
	end

	-- Only process player, raid, party, and arena units
	if not string.find(unit, "player") and not string.find(unit, "raid") 
			and not string.find(unit, "party") and not string.find(unit, "arena") then
		return
	end

	if not UnitExists(unit) then
		return
	end

	-- Create or clear out the tables for the unit
	unitAuras[unit] = {}

	-- Get all unit buffs
	local i = 1 --aura index counter
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID

		if not self.isWoWClassicEra then
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = UnitAura(unit, i, "HELPFUL")
		else
			--For wow classic. This is the LibClassicDurations wrapper
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID =  self.UnitAuraWrapper(unit, i, "HELPFUL")
		end

		-- break the loop once we have no more auras
		if not spellID then
			break
		end

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
		i = i + 1
	end

	-- Get all unit debuffs
	i = 1 --aura index counter
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID, debuffType

		if not self.isWoWClassicEra then
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  = UnitAura(unit, i, "HARMFUL")
		else
			--For wow classic. This is the LibClassicDurations wrapper
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  =  self.UnitAuraWrapper(unit, i, "HARMFUL")
		end

		-- break the loop once we have no more auras
		if not spellID then
			break
		end

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
		i = i + 1
	end
	
	-- If we added auras, we need to force a targeted update on the unit to keep good responsiveness
	self:TargetedFrameUpdate(unit)
end