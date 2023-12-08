-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Populate our "Profile Import/Export" options table for our Blizzard interface options
function EnhancedRaidFrames:CreateProfileImportExportOptions()

	local importexport = {
		name = L["Profile"] .. " " .. L["Import"] .. "/" .. L["Export"],
		type = "group",
		order = 1,
		args = {

			Header = {
				order = 1,
				name = L["Profile"] .. " " .. L["Import"] .. "/" .. L["Export"],
				type = "header",
			},

			Instructions = {
				order = 2,
				name = L["ImportExport_Desc"],
				type = "description",
				fontSize = "medium",
			},

			TextBox = {
				order = 3,
				name = L["Import or Export the current profile:"],
				desc = DIM_RED_FONT_COLOR:WrapTextInColorCode(L["ImportExport_WarningDesc"]),
				type = "input",
				multiline = 22,
				confirm = function()
					return L["ImportWarning"]
				end,
				validate = false,
				set = function(self, input)
					EnhancedRaidFrames:SetSerializedAndCompressedProfile(input)
				end,
				get = function()
					return EnhancedRaidFrames:GetSerializedAndCompressedProfile()
				end,
				width = "full",
			},
		},
	}

	return importexport
end