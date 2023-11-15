-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
if EnhancedRaidFrames.isWoWClassicEra then
	-- Setup LibClassicDurations
	local LibClassicDurations = LibStub("LibClassicDurations")
	LibClassicDurations:Register("Enhanced Raid Frames") -- tell library it's being used and should start working
	EnhancedRaidFrames.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper -- wrapper function to use in place of UnitAura
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Creates all of our listeners for the UNIT_AURA event attached to their respective raid frames
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

--- Creates a listener for the UNIT_AURA event attached to a specified raid frame
---@param frame table @The raid frame to create the listener for
function EnhancedRaidFrames:CreateAuraListener(frame)
	if not frame.ERF_auraListenerFrame or frame.ERF_auraListenerFrame.unit ~= frame.unit then
		if not frame.ERF_auraListenerFrame then --only create a new frame if we don't have one yet
			frame.ERF_auraListenerFrame = CreateFrame("Frame")
		end
		frame.ERF_auraListenerFrame.unit = frame.unit
		frame.ERF_auraListenerFrame:RegisterUnitEvent("UNIT_AURA", frame.unit)
		if not self.isWoWClassicEra and not self.isWoWClassic then
			frame.ERF_auraListenerFrame:SetScript("OnEvent", function(_, _, unit, payload)
				self:UpdateUnitAuras(unit, payload, frame)
			end)
		else
			frame.ERF_auraListenerFrame:SetScript("OnEvent", function(_, _, unit)
				self:UpdateUnitAuras_Classic(unit, frame)
			end)
		end
	end
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Scans all raid frame units and updates the unitAuras table with all auras on each unit.
function EnhancedRaidFrames:UpdateAllAuras()
	-- Iterate over all raid frame units and force a full update
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateUnitAuras(frame.unit, {isFullUpdate = true}, frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateUnitAuras_Classic(frame.unit, frame)
		end)
	end
end

--- Called by our UNIT_AURA listeners and is used to store unit aura information for a given unit.
--- Unit aura information for tracked auras is stored in the ERF_unitAuras table.
--- It uses the C_UnitAuras API that was added in 10.0
---@param unit string @The unit to update auras for
---@param payload table @The payload from the UNIT_AURA event
---@param parentFrame table @The raid frame to update
function EnhancedRaidFrames:UpdateUnitAuras(unit, payload, parentFrame)
	if not self.ShouldContinue(unit) then
		return
	end
	
	-- Create the main table for the unit
	if not parentFrame.ERF_unitAuras then
		parentFrame.ERF_unitAuras = {}
		payload.isFullUpdate = true --force a full update if we don't have a table for the unit yet
	end
	
	local shouldUpdateFrames = false

	-- If we get a full update signal, reset the table and rescan all auras for the unit
	if payload.isFullUpdate then
		-- Clear out the table
		parentFrame.ERF_unitAuras = {}
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
			parentFrame.ERF_unitAuras[auraInstanceID] = nil
			--it's possible for auraData to return nil if the aura was removed just prior to us querying it
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			shouldUpdateFrames = self:addToAuraTable(parentFrame, auraData)
		end
	end

	-- If an aura has been removed, remove it from the table
	if payload.removedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.removedAuraInstanceIDs) do
			if parentFrame.ERF_unitAuras[auraInstanceID] then
				parentFrame.ERF_unitAuras[auraInstanceID] = nil
				shouldUpdateFrames = true
			end
		end
	end

	if shouldUpdateFrames then
		self:UpdateIndicators(parentFrame)
	end
end

--- Add or update an aura to the ERFAuras table
---@param parentFrame table @The raid frame that we're updating
---@param auraData table @Payload from UNIT_AURA event
function EnhancedRaidFrames:addToAuraTable(parentFrame, auraData)
	if not auraData then
		return false
	end
	
	-- Quickly check if we're watching for this aura, and ignore if we aren't
	-- It's important to use the 4th argument in string.find to turn off pattern matching, 
	-- otherwise strings with parentheses in them will fail to be found
	if not self.allAuras:find(" "..auraData.name:lower().." ", nil, true) and not self.allAuras:find(auraData.spellId) and 
			(auraData.isHarmful and not auraData.dispelName or (auraData.dispelName and not self.allAuras:find(auraData.dispelName:lower()))) then
		return false
	end

	local aura = {}
	aura.auraInstanceID = auraData.auraInstanceID
	if auraData.isHelpful then
		aura.auraType = "buff"
	elseif auraData.isHarmful then
		aura.auraType = "debuff"
		if auraData.dispelName then
			aura.debuffType = auraData.dispelName:lower()
		end
	end
	aura.auraName = auraData.name:lower()
	aura.icon = auraData.icon
	aura.count = auraData.applications
	aura.duration = auraData.duration
	aura.expirationTime = auraData.expirationTime
	aura.castBy = auraData.sourceUnit
	aura.spellID = auraData.spellId

	parentFrame.ERF_unitAuras[aura.auraInstanceID] = aura
	return true --return true if we added or updated an aura
end

--- Called by our UNIT_AURA listeners and is used to store unit aura information for a given unit.
--- Unit aura information for tracked auras is stored in the ERF_unitAuras table.
--- This function is less optimized than :UpdateUnitAuras(), but is still required for Classic and Classic Era.
---@param unit string @The unit to update auras for
---@param parentFrame table @The raid frame to update
function EnhancedRaidFrames:UpdateUnitAuras_Classic(unit, parentFrame)
	if not self.ShouldContinue(unit) then
		return
	end

	-- Create or clear out the tables for the unit
	parentFrame.ERF_unitAuras = {}

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
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(spellID) then
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

			table.insert(parentFrame.ERF_unitAuras, auraTable)
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
		if auraName and self.allAuras:find(" "..auraName:lower().." ", nil, true) or self.allAuras:find(spellID) or
				(debuffType and self.allAuras:find(debuffType:lower())) then -- Only add the spell if we're watching for it

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

			table.insert(parentFrame.ERF_unitAuras, auraTable)
		end
		i = i + 1
	end
	
	self:UpdateIndicators(parentFrame)
end