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
function EnhancedRaidFrames:MigrateDatabase()
	if not self.db.profile.DB_VERSION or self.db.profile.DB_VERSION < self.DATABASE_VERSION then
		self:Print(L["The database is being migrated to version:"] .. " " .. self.DATABASE_VERSION)
		--- Migrate the database to the current specification

		-----------------------------------------------------------

		-- Added in database version 2.1 on 12/4/2023
		-- Fix indicatorColor and textColor to be our new table format without explicit r/g/b/a keys assigned
		for i = 1, 9 do
			if self.db.profile[i] then
				--check to see if we have the old format prior to database version 2.2
				if self.db.profile[i].indicatorColor and self.db.profile[i].indicatorColor.r then
					--check to see if we have the old format
					self.db.profile[i].indicatorColor = { self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
														  self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a }
				end
				if self.db.profile[i].textColor and self.db.profile[i].textColor.r then
					--check to see if we have the old format
					self.db.profile[i].textColor = { self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
													 self.db.profile[i].textColor.b, self.db.profile[i].textColor.a }
				end
			end
		end

		-- Added in database version 2.2 on 12/4/2023
		-- Rename indicator position keys to be "indicator-1" rather than just "1"
		for i = 1, 9 do
			if self.db.profile[i] then
				for k, v in pairs(self.db.profile[i]) do
					self.db.profile["indicator-" .. i][k] = v
				end
			end
		end

		--Reload our database object with the defaults post-migration
		self:SetupDatabase()

		-----------------------------------------------------------

		self:Print(L["Database migration successful."])
		self.db.profile.DB_VERSION = self.DATABASE_VERSION

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
	if not unit:find("player", 1, true)
			and not unit:find("raid", 1, true)
			and not unit:find("party", 1, true) then
		return false
	end

	return true
end

--- Set the visibility on the stock buff/debuff frames
function EnhancedRaidFrames:UpdateAllStockAuraVisOverrides()
	if not self.isWoWClassicEra and not self.isWoWClassic then
		--10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateStockAuraVisOverrides(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateStockAuraVisOverrides(frame)
		end)
	end
end

--- Set the visibility on the stock buff/debuff frames for a single frame
---@param frame table @The frame to set the visibility on
function EnhancedRaidFrames:UpdateStockAuraVisOverrides(frame)
	if not self.ShouldContinue(frame.unit) then
		return
	end

	-- Tables to track the stock buff/debuff frames and their visibility flags in our database
	local allAuraFrames = { frame.buffFrames, frame.debuffFrames, frame.dispelDebuffFrames }
	local auraVisibilityFlags = { self.db.profile.showBuffs, self.db.profile.showDebuffs, self.db.profile.showDispellableDebuffs }

	-- Iterate through the stock buff/debuff/dispelDebuff frame types
	for i, auraFrames in ipairs(allAuraFrames) do
		if not auraFrames then
			break
		end

		-- Iterate through the individual buff/debuff/dispelDebuff frames
		for _, auraFrame in pairs(auraFrames) do
			-- Set our hook to override "OnShow" on the frame based on the visibility flag in our database
			if not auraVisibilityFlags[i] then
				--query the specific visibility flag for this frame type
				if not self:IsHooked(auraFrame, "OnShow") then
					--careful not to hook the same frame multiple times
					self:SecureHookScript(auraFrame, "OnShow", function(self)
						self:Hide()
					end)
				end
				-- Hide frame immediately as well, otherwise some already shown frames will remain visible
				auraFrame:Hide()
			else
				if self:IsHooked(auraFrame, "OnShow") then
					-- Unhook the frame if it's hooked and we want to return it to the default behavior
					self:Unhook(auraFrame, "OnShow")
				end
			end
		end
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

	if checkedRange and not inRange then
		--If we weren't able to check the range for some reason, we'll just treat them as in-range (for example, enemy units)
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
		self:Print(L["No data to import."] .. " " .. L["Aborting."])
		return
	end

	-- Decode and check if decoding worked properly
	local decoded = LibDeflate:DecodeForPrint(input)
	if decoded == nil then
		self:Print(L["Decoding failed."] .. " " .. L["Aborting."])
		return
	end

	-- Decompress and verify if decompression worked properly
	local decompressed = LibDeflate:DecompressZlib(decoded)
	if decompressed == nil then
		self:Print(L["Decompression failed."] .. " " .. L["Aborting."])
		return
	end

	-- Deserialize the data and return it back into a table format
	local result, newProfile = self:Deserialize(decompressed)

	-- If we successfully deserialize, load the new table into the database
	if result == true and newProfile then
		for k, v in pairs(newProfile) do
			if type(v) == "table" then
				self.db.profile[k] = CopyTable(v)
			else
				self.db.profile[k] = v
			end
		end
	else
		self:Print(L["Data import Failed."] .. " " .. L["Aborting."])
	end
end