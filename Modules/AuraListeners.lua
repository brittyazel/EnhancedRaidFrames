-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local LibDispel = LibStub("LibDispel-1.0")

if EnhancedRaidFrames.isWoWClassicEra then
	-- Set up LibClassicDurations
	local LibClassicDurations = LibStub("LibClassicDurations")
	LibClassicDurations:Register("Enhanced Raid Frames") -- Tell library it's being used and should start working
	EnhancedRaidFrames.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper -- Wrapper function to use in place of UnitAura
end

-- Get our list of bleeds from LibDispel
local bleedList = LibDispel:GetBleedList()

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Creates a listener for the UNIT_AURA event attached to a specified raid frame
---@param frame table @The raid frame to create the listener for
function EnhancedRaidFrames:CreateAuraListener(frame)
	-- Skip the visibility check in ShouldContinue() as we need the listener to exist even if the frame is hidden
	if not self.ShouldContinue(frame, true) then
		return
	end

	-- To stop us from creating redundant frames we should try to re-capture them when possible.
	if not _G[frame:GetName() .. "-ERF_auraListenerFrame"] then
		frame.ERF_auraListenerFrame = CreateFrame("Frame", frame:GetName() .. "-ERF_auraListenerFrame", frame)
	else
		frame.ERF_auraListenerFrame = _G[frame:GetName() .. "-ERF_auraListenerFrame"]
		-- If we capture an old indicator frame, we should reattach it to the current unit frame.
		frame.ERF_auraListenerFrame:SetParent(frame)
	end

	-- Register the unit event
	frame.ERF_auraListenerFrame:UnregisterAllEvents() -- Clear any existing events
	frame.ERF_auraListenerFrame:RegisterUnitEvent("UNIT_AURA", frame.unit)

	-- Assign the OnEvent callback for the listener frame
	if not self.isWoWClassicEra and not self.isWoWClassic then
		frame.ERF_auraListenerFrame:SetScript("OnEvent", function(_, _, _, payload)
			self:UpdateUnitAuras(frame, payload)
		end)
	else
		frame.ERF_auraListenerFrame:SetScript("OnEvent", function()
			self:UpdateUnitAuras_Classic(frame) -- Classic uses the legacy method prior to 10.0
		end)
	end
end

--- Creates a listener for the UNIT_AURA event attached to all raid frames
--- This function explicitly creates a listener for all raid frames, even if they aren't visible.
function EnhancedRaidFrames:CreateAllAuraListeners()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:CreateAuraListener(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:CreateAuraListener(frame)
		end)
	end
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Scans all raid frame units and updates the unitAuras table with all auras on each unit.
function EnhancedRaidFrames:UpdateAllAuras()
	-- Iterate over all raid frame units and force a full update
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateUnitAuras(frame, { isFullUpdate = true })
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateUnitAuras_Classic(frame) -- Classic uses the legacy method prior to 10.0
		end)
	end
end

--- Called by our UNIT_AURA listeners and is used to store unit aura information for a given unit.
--- Unit aura information for tracked auras is stored in the ERF_unitAuras table.
--- It uses the C_UnitAuras API that was added in 10.0.
---@param parentFrame table @The raid frame to update
---@param payload table @The payload from the UNIT_AURA event
function EnhancedRaidFrames:UpdateUnitAuras(parentFrame, payload)
	if not self.ShouldContinue(parentFrame) then
		return
	end

	local unit = parentFrame.unit

	-- Create a listener frame for the unit if we don't happen to have one yet
	if not parentFrame.ERF_auraListenerFrame then
		self:CreateAuraListener(parentFrame)
	end

	-- Create the main table for the unit
	if not parentFrame.ERF_unitAuras then
		parentFrame.ERF_unitAuras = {}
		payload.isFullUpdate = true -- Force a full update if we don't have a table for the unit yet
	end

	-- Flag to determine if we need to run an update on the indicators since we only care about select auras
	-- This should filter out a lot of unnecessary updates from triggering an indicator update
	local shouldRunUpdate = false

	-- If we get a full update signal, reset the table and rescan all auras for the unit
	if payload.isFullUpdate then
		-- Clear out the table
		parentFrame.ERF_unitAuras = {}
		-- Iterate through all buffs and debuffs on the unit
		for _, filter in pairs({ "HELPFUL", "HARMFUL" }) do
			AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
				-- Add our auraData to the ERF_unitAuras table
				local updateFlag = self:addToAuraTable(parentFrame, auraData)
				if updateFlag then
					shouldRunUpdate = true
				end
			end, true);
		end

		-- Only update the indicators if we added any tracked auras
		if shouldRunUpdate then
			self:UpdateIndicators(parentFrame)
		end

		return -- End early since we've already updated all the indicators
	end

	-- If one or more new auras were added, update the table with their payload information
	if payload.addedAuras then
		for _, auraData in pairs(payload.addedAuras) do
			-- Add our auraData to the ERF_unitAuras table
			local updateFlag = self:addToAuraTable(parentFrame, auraData)
			if updateFlag then
				shouldRunUpdate = true
			end
		end
	end

	-- If one or more auras were updated, query their updated information and add it to the table
	if payload.updatedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.updatedAuraInstanceIDs) do
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			-- Though rare, it is possible for auraData to be nil if the aura was removed just prior to us querying it.
			if auraData then
				-- Add our auraData to the ERF_unitAuras table
				local updateFlag = self:addToAuraTable(parentFrame, auraData)
				if updateFlag then
					shouldRunUpdate = true
				end
			end
		end
	end

	-- If one or more auras was removed, remove them from the table
	if payload.removedAuraInstanceIDs then
		for _, auraInstanceID in pairs(payload.removedAuraInstanceIDs) do
			if parentFrame.ERF_unitAuras[auraInstanceID] then
				-- Set the table entry to nil to remove it
				parentFrame.ERF_unitAuras[auraInstanceID] = nil
				shouldRunUpdate = true
			end
		end
	end

	-- Only update the indicators if we added, updated, or removed a tracked aura
	if shouldRunUpdate then
		self:UpdateIndicators(parentFrame)
	end
end

--- Add or update an aura to the ERFAuras table
---@param parentFrame table @The raid frame that we're updating
---@param auraData table @Payload from UNIT_AURA event
---@return boolean @True if we added or updated an aura
function EnhancedRaidFrames:addToAuraTable(parentFrame, auraData)
	-- Inject bleed type into auraData courtesy of LibDispel
	if auraData.isHarmful and not EnhancedRaidFrames.isWoWClassicEra and not EnhancedRaidFrames.IsWowClassic then
		if bleedList[auraData.spellId] then
			auraData.dispelName = "bleed"
			if LibDispel:IsDispellableByMe("Bleed") then
				auraData.isRaid = true
			end
		end
	end
	
	-- Quickly check if we're watching for this aura, and ignore if we aren't
	-- It's important to use the 4th argument in string.find to turn off pattern matching, 
	-- otherwise strings with parentheses in them will fail to be found
	if self.allAuras:find(" " .. auraData.name:lower() .. " ", 1, true)
			or self.allAuras:find(auraData.spellId, 1, true)
			-- Check if the aura is a debuff, if it matches the "RAID" filter, and if we're tracking the wildcard for "dispel"
			or (auraData.isHarmful and auraData.isRaid and self.allAuras:find("dispel", 1, true))
			-- Check if the aura is a debuff, and if it has a dispelName see if we're tracking the wildcard for it
			or (auraData.isHarmful and auraData.dispelName and self.allAuras:find(auraData.dispelName:lower(), 1, true)) then

		-- Lowercase the aura name for consistency
		auraData.name = auraData.name:lower()

		-- Check to see if we have a dispel name, and lowercase it if we do
		if auraData.dispelName then
			auraData.dispelName = auraData.dispelName:lower()
		end

		if auraData.auraInstanceID then
			-- For 10.0 and newer
			-- Add our auraData to the ERF_unitAuras table using the auraInstanceID as the key
			parentFrame.ERF_unitAuras[auraData.auraInstanceID] = auraData
		else
			-- For 9.x and older
			-- Append our auraData to the ERF_unitAuras table
			table.insert(parentFrame.ERF_unitAuras, auraData)
		end

		-- Return true if we added or updated an aura
		return true
	end
end

--- Called by our UNIT_AURA listeners and is used to store unit aura information for a given unit.
--- Unit aura information for tracked auras is stored in the ERF_unitAuras table.
--- This function is less optimized than :UpdateUnitAuras(), but is still required for Classic and Classic Era.
---@param parentFrame table @The raid frame to update
function EnhancedRaidFrames:UpdateUnitAuras_Classic(parentFrame)
	if not self.ShouldContinue(parentFrame) then
		return
	end

	local unit = parentFrame.unit

	-- Create a listener frame for the unit if we don't happen to have one yet
	if not parentFrame.ERF_auraListenerFrame then
		self:CreateAuraListener(parentFrame)
	end

	-- Keep a record of how many auras we had previously
	local numPreviousAuras = 0
	if parentFrame.ERF_unitAuras then
		numPreviousAuras = #parentFrame.ERF_unitAuras
	end

	-- Create or clear out the tables for the unit
	parentFrame.ERF_unitAuras = {}

	-- Iterate through all buffs and debuffs on the unit
	for _, filter in pairs({ "HELPFUL", "HARMFUL", "RAID|HARMFUL" }) do
		-- Counter to keep track of our aura index
		local auraIndex = 1

		-- Loop through all auras on the unit until we run out
		repeat
			local shouldStop = false
			local auraData = {}

			if not self.isWoWClassicEra then
				auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration, auraData.expirationTime,
				auraData.sourceUnit, _, _, auraData.spellId, _, _, _, _, auraData.timeMod = UnitAura(unit, auraIndex, filter)
			else
				-- For wow classic we use LibClassicDurations instead of UnitAura() because by default the 
				-- game doesn't provide any aura duration information.
				auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration, auraData.expirationTime,
				auraData.sourceUnit, _, _, auraData.spellId, _, _, _, _, auraData.timeMod = self.UnitAuraWrapper(unit, auraIndex, filter)
			end

			-- Verify that we have an aura name as a proxy for if we've run out of auras to scan
			if auraData.name then
				-- Set our isHelpful/isHarmful flags to match the C_UnitAuras API syntax for compatibility with the rest of the addon
				if filter == "HELPFUL" then
					auraData.isHelpful = true
				elseif filter == "HARMFUL" then
					auraData.isHarmful = true
				elseif filter == "RAID|HARMFUL" then
					auraData.isHarmful = true
					auraData.isRaid = true
				end

				-- Add our auraIndex into the table
				auraData.auraIndex = auraIndex

				-- Add our auraData to the ERF_unitAuras table
				self:addToAuraTable(parentFrame, auraData)
			else
				shouldStop = true
			end

			-- Increment the aura index counter
			auraIndex = auraIndex + 1
		until (shouldStop)
	end

	-- Only update the indicators if we have at least 1 tracked aura in our table
	-- or if we had a tracked aura in our table previously and now we don't (to clear indicators)
	if #parentFrame.ERF_unitAuras > 0 or (#parentFrame.ERF_unitAuras == 0 and numPreviousAuras ~= 0) then
		self:UpdateIndicators(parentFrame)
	end
end