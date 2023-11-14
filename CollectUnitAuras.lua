-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local addonName, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-- Setup LibClassicDurations
if EnhancedRaidFrames.isWoWClassicEra then
	local LibClassicDurations = LibStub("LibClassicDurations")
	LibClassicDurations:Register(addonName) -- tell library it's being used and should start working
	EnhancedRaidFrames.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper -- wrapper function to use in place of UnitAura
end
-------------------------------------------------------------------------
-------------------------------------------------------------------------
function EnhancedRaidFrames:CreateAllListeners()
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			if frame and frame.unit then
				self:CreateAuraListener(frame)
			end
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			if frame and frame.unit  then
				self:CreateAuraListener(frame)
			end
		end)
	end
end

function EnhancedRaidFrames:CreateAuraListener(frame)
	if not frame.ERFAuraListener or frame.ERFAuraListener.unit ~= frame.unit then
		if not frame.ERFAuraListener then --only create a new frame if we don't have one yet
			frame.ERFAuraListener = CreateFrame("Frame")
		end
		frame.ERFAuraListener.unit = frame.unit
		frame.ERFAuraListener:RegisterUnitEvent("UNIT_AURA", frame.unit)
		if not self.isWoWClassicEra and not self.isWoWClassic then
			frame.ERFAuraListener:SetScript("OnEvent", function(_, event, unit, payload)
				self:UpdateUnitAuras(event, unit, payload, frame)
			end)
		else
			frame.ERFAuraListener:SetScript("OnEvent", function(_, event, unit)
				self:UpdateUnitAuras_Classic(event, unit, frame)
			end)
		end
	end
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- This function does a quick scan of the current auras on the unit and returns true if any of them are set as tracked
-- This is primarily meant to reduce idle CPU usage by not scanning units that don't have any auras we're tracking
function EnhancedRaidFrames:HasTrackedAuras(frame)
	-- First check if we're watching for any special cases on the unit
	if self.allAuras:find("pvp") or self.allAuras:find("combat") or self.allAuras:find("tot") then
		return true
	end
	
	-- If we don't have an aura table for the unit, return false
	if not frame.ERFAuras then
		return false
	end
	
	-- Check each aura on the unit and return true if we find one we're watching for
	for _, aura in pairs(frame.ERFAuras) do
		if self.allAuras:find(aura.auraName:lower()) or 
				self.allAuras:find(aura.spellID) or 
				(aura.auraType == "debuff" and self.allAuras:find(aura.debuffType:lower()))
				then
			return true
		end
	end
	
	return false
end

--- This function scans all raid frame units and updates the unitAuras table with all auras on each unit
function EnhancedRaidFrames:UpdateAllAuras()
	-- Iterate over all raid frame units and force a full update
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateUnitAuras("", frame.unit, {isFullUpdate = true}, frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateUnitAuras_Classic("", frame.unit, frame)
		end)
	end
end

--- This functions is bound to the UNIT_AURA event and is used to track auras on all raid frame units
--- It uses the C_UnitAuras API that was added in 10.0
--- Unit aura information is stored in the unitAuras table
function EnhancedRaidFrames:UpdateUnitAuras(_, unit, payload, parentFrame)
	if not self.ShouldContinue(unit) then
		return
	end
	
	-- Create the main table for the unit
	if not parentFrame.ERFAuras then
		parentFrame.ERFAuras = {}
		payload.isFullUpdate = true --force a full update if we don't have a table for the unit yet
	end
	
	local shouldUpdateFrames = false

	-- If we get a full update signal, reset the table and rescan all auras for the unit
	if payload.isFullUpdate then
		-- Clear out the table
		parentFrame.ERFAuras = {}
		-- These helper functions will iterate over all buffs and debuffs on the unit
		-- and call the addToAuraTable() function for each one
		AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(auraData)
			shouldUpdateFrames = self:addToAuraTable(parentFrame, auraData)
		end, true);
		AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(auraData)
			shouldUpdateFrames = self:addToAuraTable(parentFrame, auraData)
		end, true);
		return
	end

	-- If new auras are added, update the table with their payload information
	if payload.addedAuras then
		for _, auraData in pairs(payload.addedAuras) do
			shouldUpdateFrames = self:addToAuraTable(parentFrame, auraData)
		end
	end

	-- If an aura has been updated, query the updated information and add it to the table
	if payload.updatedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.updatedAuraInstanceIDs) do
			parentFrame.ERFAuras[auraInstanceID] = nil
			--it's possible for auraData to return nil if the aura was removed just prior to us querying it
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			shouldUpdateFrames = self:addToAuraTable(parentFrame, auraData)
		end
	end

	-- If an aura has been removed, remove it from the table
	if payload.removedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.removedAuraInstanceIDs) do
			if parentFrame.ERFAuras[auraInstanceID] then
				parentFrame.ERFAuras[auraInstanceID] = nil
				shouldUpdateFrames = true
			end
		end
	end

	if shouldUpdateFrames then
		self:UpdateIndicators(parentFrame)
	end
end

--function to add or update an aura to the ERFAuras table
function EnhancedRaidFrames:addToAuraTable(parentFrame, auraData)
	if not auraData then
		return false
	end
	
	-- Quickly check if we're watching for this aura, and ignore if we aren't
	-- It's important to use the 4th argument in string.find to turn off pattern matching, 
	-- otherwise strings with parentheses in them will fail to be found
	if not self.allAuras:find(" "..auraData.name:lower().." ", nil, true) and not self.allAuras:find(" "..auraData.spellId.." ", nil, true) then
		return false
	end

	local aura = {}
	aura.auraInstanceID = auraData.auraInstanceID
	if auraData.isHelpful then
		aura.auraType = "buff"
	elseif auraData.isHarmful then
		aura.auraType = "debuff"
		aura.debuffType = auraData.dispelName:lower()
	end
	aura.auraName = auraData.name:lower()
	aura.icon = auraData.icon
	aura.count = auraData.applications
	aura.duration = auraData.duration
	aura.expirationTime = auraData.expirationTime
	aura.castBy = auraData.sourceUnit
	aura.spellID = auraData.spellId

	parentFrame.ERFAuras[aura.auraInstanceID] = aura
	return true --return true if we added or updated an aura
end

--- Prior to WoW 10.0, this function was used to track auras on all raid frame units
--- Unit auras are now tracked using the UNIT_AURA event and APIs in Retail
--- Unit aura information is stored in the ERFAuras table
function EnhancedRaidFrames:UpdateUnitAuras_Classic(_, unit, parentFrame)
	if not self.ShouldContinue(unit) then
		return
	end

	-- Create or clear out the tables for the unit
	parentFrame.ERFAuras = {}

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

		-- Quickly check if we're watching for this aura, and ignore if we aren't
		-- It's important to use the 4th argument in string.find to turn off pattern matching, 
		-- otherwise strings with parentheses in them will fail to be found
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(" "..spellID.." ", nil, true) then
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

			table.insert(parentFrame.ERFAuras, auraTable)
		end
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

		-- Quickly check if we're watching for this aura, and ignore if we aren't
		-- It's important to use the 4th argument in string.find to turn off pattern matching, 
		-- otherwise strings with parentheses in them will fail to be found
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(" "..spellID.." ", nil, true) then
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

			table.insert(parentFrame.ERFAuras, auraTable)
		end
		i = i + 1
	end
	
	self:UpdateIndicators(parentFrame)
end