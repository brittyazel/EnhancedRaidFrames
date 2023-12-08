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
	if not self.isWoWClassicEra and not self.isWoWClassic then
		--10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			if frame and frame.unit then
				self:CreateAuraListener(frame)
			end
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			if frame and frame.unit then
				self:CreateAuraListener(frame)
			end
		end)
	end
end

--- Creates a listener for the UNIT_AURA event attached to a specified raid frame
---@param frame table @The raid frame to create the listener for
function EnhancedRaidFrames:CreateAuraListener(frame)
	-- Only create a listener if we don't already have one, or the unit assigned to it has changed
	if not frame.ERF_auraListenerFrame or frame.ERF_auraListenerFrame.unit ~= frame.unit then
		--only create a new frame if we don't have one yet
		if not frame.ERF_auraListenerFrame then
			--I'm not sure if this is ever the case, but to stop us from creating redundant frames we should try to re-capture them when possible
			--On the global table, our frames our named "CompactRaidFrame#" + "-ERF_auraListenerFrame", i.e. "CompactRaidFrame1-ERF_auraListenerFrame"
			if not _G[frame:GetName() .. "-ERF_auraListenerFrame"] then
				frame.ERF_auraListenerFrame = CreateFrame("Frame", frame:GetName() .. "-ERF_auraListenerFrame", frame)
			else
				frame.ERF_auraListenerFrame = _G[frame:GetName() .. "-ERF_auraListenerFrame"]
				frame.ERF_auraListenerFrame:SetParent(frame) --if we capture an old indicator frame, we should reattach it to the current unit frame
			end

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
	if not self.isWoWClassicEra and not self.isWoWClassic then
		--10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateUnitAuras(frame.unit, { isFullUpdate = true }, frame)
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

	-- Flag to determine if we need to run an update on the indicators since we only care about select auras
	local shouldRunUpdate = false

	-- If we get a full update signal, reset the table and rescan all auras for the unit
	if payload.isFullUpdate then
		-- Clear out the table
		parentFrame.ERF_unitAuras = {}
		-- Iterate through all buffs and debuffs on the unit
		for _, filter in pairs({ "HELPFUL", "HARMFUL" }) do
			AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
				local updateFlag = self:addToAuraTable(parentFrame, auraData)
				if updateFlag then
					shouldRunUpdate = true
				end
			end, true);
		end
		self:UpdateIndicators(parentFrame)
		return --bail early since we've already updated all the indicators
	end

	-- If new auras are added, update the table with their payload information
	if payload.addedAuras then
		for _, auraData in pairs(payload.addedAuras) do
			local updateFlag = self:addToAuraTable(parentFrame, auraData)
			if updateFlag then
				shouldRunUpdate = true
			end
		end
	end

	-- If an aura has been updated, query the updated information and add it to the table
	if payload.updatedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.updatedAuraInstanceIDs) do
			parentFrame.ERF_unitAuras[auraInstanceID] = nil
			--it's possible for auraData to return nil if the aura was removed just prior to us querying it
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			local updateFlag = self:addToAuraTable(parentFrame, auraData)
			if updateFlag then
				shouldRunUpdate = true
			end
		end
	end

	-- If an aura has been removed, remove it from the table
	if payload.removedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.removedAuraInstanceIDs) do
			if parentFrame.ERF_unitAuras[auraInstanceID] then
				parentFrame.ERF_unitAuras[auraInstanceID] = nil
				shouldRunUpdate = true
			end
		end
	end

	if shouldRunUpdate then
		self:UpdateIndicators(parentFrame)
	end
end

--- Add or update an aura to the ERFAuras table
---@param parentFrame table @The raid frame that we're updating
---@param auraData table @Payload from UNIT_AURA event
---@return boolean @True if we added or updated an aura
function EnhancedRaidFrames:addToAuraTable(parentFrame, auraData)
	if not auraData then
		return
	end

	-- Quickly check if we're watching for this aura, and ignore if we aren't
	-- It's important to use the 4th argument in string.find to turn off pattern matching, 
	-- otherwise strings with parentheses in them will fail to be found
	if self.allAuras:find(" " .. auraData.name:lower() .. " ", 1, true)
			or self.allAuras:find(auraData.spellId, 1, true)
			--check if the aura is a debuff, and if it's a dispellable debuff check if we're tracking the wildcard of that debuff type
			or (auraData.isHarmful and auraData.dispelName and self.allAuras:find(auraData.dispelName:lower(), 1, true)) then

		auraData.name = auraData.name:lower()
		if auraData.dispelName then
			auraData.dispelName = auraData.dispelName:lower()
		end

		parentFrame.ERF_unitAuras[auraData.auraInstanceID] = auraData

		--return true if we added or updated an aura
		return true
	end
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

	-- Iterate through all buffs and debuffs on the unit
	for _, filter in pairs({ "HELPFUL", "HARMFUL" }) do
		local i = 1 --counting the index of our aura
		repeat --repeat until we run out of auras
			local auraData = {}

			if self.isWoWClassicEra then
				--For wow classic. This is the LibClassicDurations wrapper
				auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration,
				auraData.expirationTime, auraData.sourceUnit, _, _, auraData.spellId = self.UnitAuraWrapper(unit, i, filter)
			else
				auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration,
				auraData.expirationTime, auraData.sourceUnit, _, _, auraData.spellId = UnitAura(unit, i, filter)
			end

			--if we don't have a name, then we've reached the end of the auras
			if auraData.name then
				-- Set our isHelpful/isHarmful flags just like in the C_UnitAuras API for compatibility with the rest of the addon
				if filter == "HELPFUL" then
					auraData.isHelpful = true
				else
					auraData.isHarmful = true
				end

				-- Add our auraIndex into the table
				auraData.auraIndex = i

				self:addToAuraTable_Classic(parentFrame, auraData, i)
			end

			i = i + 1 --increment our counter no matter what
		until (not auraData.name)
	end

	self:UpdateIndicators(parentFrame)
end

--- Add or update an aura to the ERFAuras table
---@param parentFrame table @The raid frame that we're updating
---@param auraData table @Payload from UNIT_AURA event
function EnhancedRaidFrames:addToAuraTable_Classic(parentFrame, auraData)
	if not auraData then
		return
	end

	-- Quickly check if we're watching for this aura, and ignore if we aren't
	-- It's important to use the 4th argument in string.find to turn off pattern matching, 
	-- otherwise strings with parentheses in them will fail to be found
	if self.allAuras:find(" " .. auraData.name:lower() .. " ", nil, true) or self.allAuras:find(auraData.spellId) or
			--check if the aura is a debuff, and if it's a dispellable debuff check if we're tracking the wildcard of that debuff type
			(auraData.isHarmful and auraData.dispelName and self.allAuras:find(auraData.dispelName:lower())) then

		auraData.name = auraData.name:lower()
		if auraData.dispelName then
			auraData.dispelName = auraData.dispelName:lower()
		end

		table.insert(parentFrame.ERF_unitAuras, auraData)
		return --return true if we added or updated an aura
	end
	return
end