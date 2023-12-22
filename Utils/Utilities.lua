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

--- Test for whether or not we should continue processing a given unit
---@param frame table @The frame to test
---@return boolean @Whether or not we should continue processing the unit
function EnhancedRaidFrames.ShouldContinue(frame)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return false
	end
	
	-- Check that we have a frame and that it is visible
	if not frame or (frame and not frame:IsShown()) then
		return false
	end
	
	-- Only process player, raid and party units
	if not frame.unit or (not frame.unit:find("player", 1, true)
			and not frame.unit:find("raid", 1, true)
			and not frame.unit:find("party", 1, true)) then
		return false
	end

	return true
end

--- Serialize and compress the profile for copy+paste.
---@return string @The serialized and compressed profile
function EnhancedRaidFrames:SerializeAndCompressProfile()
	local serialized = self:Serialize(self.db.profile) -- Serialize the database into a single string value
	local compressed = LibDeflate:CompressZlib(serialized) -- Compress the serialized data
	local encoded = LibDeflate:EncodeForPrint(compressed) -- Encode the compressed data for print for easy copy+paste
	return encoded
end

--- Deserialize and decompress the profile from copy+paste.
---@param input string @The input string to deserialize and decompress
function EnhancedRaidFrames:DeserializeAndDecompressProfile(input)
	-- Stop here if the input is empty
	if input == "" then
		self:Print(L["No data to import."] .. " " .. L["Aborting."])
		return
	end

	-- Decode and check if decoding worked properly
	local decoded = LibDeflate:DecodeForPrint(input)
	if not decoded then
		self:Print(L["Decoding failed."] .. " " .. L["Aborting."])
		return
	end

	-- Decompress and verify if decompression worked properly
	local decompressed = LibDeflate:DecompressZlib(decoded)
	if not decompressed then
		self:Print(L["Decompression failed."] .. " " .. L["Aborting."])
		return
	end

	-- Deserialize the data and return it back into a table format
	local success, newProfile = self:Deserialize(decompressed)

	-- If we successfully deserialize, load the new table into the database
	if success and newProfile then
		for k, v in pairs(newProfile) do
			if type(v) == "table" then
				self.db.profile[k] = CopyTable(v)
			else
				self.db.profile[k] = v
			end
		end

		-- Reload our database object with the defaults post-import
		self:InitializeDatabase()
	else
		self:Print(L["Data import Failed."] .. " " .. L["Aborting."])
	end
end