-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibRangeCheck = LibStub("LibRangeCheck-2.0")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Handle the migration of the database from one version to another
function EnhancedRaidFrames:UpdateNotifier()
	if not self.db.global.DB_VERSION or self.db.global.DB_VERSION < self.DATABASE_VERSION then
		self:Print(L["The database has been updated."])
		-- Update the database version to the current version
		-- <This is where we would put in any database migration code>
		self.db.global.DB_VERSION = self.DATABASE_VERSION
	end
end

--- Test for whether or not we should continue processing a given unit
---@param unit string @The unit to test
---@return boolean @Whether or not we should continue processing the unit
function EnhancedRaidFrames.ShouldContinue(unit)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return false
	end

	if not unit then
		return false
	end

	-- Only process player, raid and party units
	if not string.find(unit, "player") and not string.find(unit, "raid") and not string.find(unit, "party") then
		return false
	end
	
	return true
end

--- Set the visibility on the stock buff/debuff frames
---@param frame table @The frame to set the visibility on
function EnhancedRaidFrames:UpdateStockIndicatorVisibility(frame)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return
	end
	
	if not self.db.profile.showBuffs then
		CompactUnitFrame_HideAllBuffs(frame)
	end

	if not self.db.profile.showDebuffs then
		CompactUnitFrame_HideAllDebuffs(frame)
	end

	if not self.db.profile.showDispellableDebuffs then
		CompactUnitFrame_HideAllDispelDebuffs(frame)
	end
end

--- Updates the frame alpha based on if a unit is in range or not.
--- This function is secure hooked to the CompactUnitFrame_UpdateInRange function.
---@param frame table @The frame to update the alpha on
function EnhancedRaidFrames:UpdateInRange(frame)
	if not self.ShouldContinue(frame.unit) then
		return
	end
	
	local effectiveUnit = frame.unit
	if frame.unit ~= frame.displayedUnit then
		effectiveUnit = frame.displayedUnit
	end

	if not UnitExists(effectiveUnit) then
		return
	end
	
	local inRange, checkedRange

	--if we have a custom range set use LibRangeCheck, otherwise use default UnitInRange function
	if self.db.profile.customRangeCheck then
		local rangeChecker = LibRangeCheck:GetFriendChecker(self.db.profile.customRange)
		if rangeChecker then
			inRange = rangeChecker(effectiveUnit)
			checkedRange = true
		else
			inRange, checkedRange = UnitInRange(effectiveUnit) --if no rangeChecker can be generated, fallback to UnitInRange
		end
	else
		inRange, checkedRange = UnitInRange(effectiveUnit)
	end
	
	if checkedRange and not inRange then --If we weren't able to check the range for some reason, we'll just treat them as in-range (for example, enemy units)
		frame:SetAlpha(self.db.profile.rangeAlpha)
	else
		frame:SetAlpha(1)
	end
	
end

--- Set the background alpha amount based on a defined value by the user.
---@param frame table @The frame to set the background alpha on
function EnhancedRaidFrames:UpdateBackgroundAlpha(frame)
	if not self.ShouldContinue(frame.unit) then
		return
	end

	frame.background:SetAlpha(self.db.profile.backgroundAlpha)
end

--- Set the scale of the overall raid frame container.
function EnhancedRaidFrames:UpdateScale()
	if not InCombatLockdown() then
		CompactRaidFrameContainer:SetScale(self.db.profile.frameScale)
		if CompactPartyFrame then
			CompactPartyFrame:SetScale(self.db.profile.frameScale)
		end
	end
end

--- Serialize and compress the profile for copy+paste.
function EnhancedRaidFrames:GetSerializedAndCompressedProfile()
	local uncompressed = self:Serialize(self.db.profile) --serialize the database into a string value
	local compressed = LibDeflate:CompressZlib(uncompressed) --compress the data
	local encoded = LibDeflate:EncodeForPrint(compressed) --encode the data for print for copy+paste
	return encoded
end

--- Deserialize and decompress the profile from copy+paste.
function EnhancedRaidFrames:SetSerializedAndCompressedProfile(input)
	--check if the input is empty
	if input == "" then
		self:Print(L["No data to import."].." "..L["Aborting."])
		return
	end

	-- Decode and check if decoding worked properly
	local decoded = LibDeflate:DecodeForPrint(input)
	if decoded == nil then
		self:Print(L["Decoding failed."].." "..L["Aborting."])
		return
	end

	-- Decompress and verify if decompression worked properly
	local decompressed = LibDeflate:DecompressZlib(decoded)
	if decompressed == nil then
		self:Print(L["Decompression failed."].." "..L["Aborting."])
		return
	end

	-- Deserialize the data and return it back into a table format
	local result, newProfile = self:Deserialize(decompressed)

	-- If we successfully deserialize, load the new table into the database
	if result == true and newProfile then 
		for k,v in pairs(newProfile) do
			if type(v) == "table" then
				self.db.profile[k] = CopyTable(v)
			else
				self.db.profile[k] = v
			end
		end
	else
		self:Print(L["Data import Failed."].." "..L["Aborting."])
	end
end