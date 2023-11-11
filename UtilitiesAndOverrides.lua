-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibRangeCheck = LibStub("LibRangeCheck-2.0")

-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- Prints a message to the chat frame when the database is updated
function EnhancedRaidFrames:UpdateNotifier()
	if not self.db.global.DB_VERSION or self.db.global.DB_VERSION < self.DATABASE_VERSION then
		self:Print(L["The database has been updated."])
		self.db.global.DB_VERSION = self.DATABASE_VERSION
	end
end

-- Generates a table of individual, sanitized aura strings from the raw user text input
function EnhancedRaidFrames:GenerateAuraStrings()
	-- reset aura strings
	self.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(self.db.profile[i].auras, "[^\n]+") do -- Grab each line
			--sanitize strings
			auraName = auraName:lower() --force lowercase
			auraName = auraName:gsub("^%s*(.-)%s*$", "%1") --strip any leading or trailing whitespace
			auraName = auraName:gsub("\"", "") --strip any quotation marks if there are any
			self.auraStrings[i][j] = auraName
			j = j + 1
		end
	end
end

-- Set the visibility on the stock buff/debuff frames
function EnhancedRaidFrames:SetStockIndicatorVisibility(frame)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
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

-- Hook for the CompactUnitFrame_UpdateInRange function
function EnhancedRaidFrames:UpdateInRange(frame)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
		return
	end

	if not frame.unit then
		return
	end

	-- Only process player, raid, party, and arena units
	if not string.find(frame.unit, "player") and not string.find(frame.unit, "raid")
			and not string.find(frame.unit, "party") and not string.find(frame.unit, "arena") then
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

-- Set the background alpha amount to allow full transparency if need be
function EnhancedRaidFrames:UpdateBackgroundAlpha(frame)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
		return
	end

	if not frame.unit then
		return
	end

	-- Only process player, raid, party, and arena units
	if not string.find(frame.unit, "player") and not string.find(frame.unit, "raid")
			and not string.find(frame.unit, "party") and not string.find(frame.unit, "arena") then
		return
	end

	frame.background:SetAlpha(self.db.profile.backgroundAlpha)
end

-- Set the scale of the overall raid frame container
function EnhancedRaidFrames:UpdateScale()
	if not InCombatLockdown() then
		CompactRaidFrameContainer:SetScale(self.db.profile.frameScale)
		if CompactPartyFrame then
			CompactPartyFrame:SetScale(self.db.profile.frameScale)
		end
	end
end

-- Serialize and compress the profile for copy+paste
function EnhancedRaidFrames:GetSerializedAndCompressedProfile()
	local uncompressed = self:Serialize(self.db.profile) --serialize the database into a string value
	local compressed = LibDeflate:CompressZlib(uncompressed) --compress the data
	local encoded = LibDeflate:EncodeForPrint(compressed) --encode the data for print for copy+paste
	return encoded
end

-- Deserialize and decompress the profile from copy+paste
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