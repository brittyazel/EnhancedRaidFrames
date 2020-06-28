--Enhanced Raid Frames, a World of Warcraft® user interface addon.

--This file is part of Enhanced Raid Frames.
--
--Enhanced Raid Frames is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Enhanced Raid Frames is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this add-on.  If not, see <https://www.gnu.org/licenses/>.
--
--Copyright for Enhanced Raid Frames is held by Britt Yazel (aka Soyier), 2017-2020.

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateGeneralOptions()
	local THIRD_WIDTH = 1.15

	local generalOptions = {
		type = "group",
		childGroups = "tree",
		args  = {
			instructions = {
				type = "description",
				name = L["generalOptions_desc"],
				fontSize = "medium",
				order = 2,
			},
			-------------------------------------------------
			topSpacer = {
				type = "header",
				name = "",
				order = 3,
			},
			blizzardRaidOptionsButton = {
				type = 'execute',
				name = L["blizzardRaidOptionsButton_name"],
				desc = L["blizzardRaidOptionsButton_desc"],
				func = function() InterfaceOptionsFrame_OpenToCategory("Raid Profiles") end,
				width = THIRD_WIDTH * 1.5,
				order = 4,
			},
			-------------------------------------------------
			textHeader = {
				type = "header",
				name = L["Default Icon Visibility"],
				order = 10,
			},
			showBuffs = {
				type = "toggle",
				name = L["showBuffs_name"],
				desc = L["showBuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showBuffs end,
				set = function(_, value)
					self.db.profile.showBuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = L["showDebuffs_name"],
				desc = L["showDebuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showDebuffs end,
				set = function(_, value)
					self.db.profile.showDebuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			showDispellableDebuffs = {
				type = "toggle",
				name = L["showDispellableDebuffs_name"],
				desc = L["showDispellableDebuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showDispellableDebuffs end,
				set = function(_, value)
					self.db.profile.showDispellableDebuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 13,
			},
			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = L["General"],
				order = 30,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = L["indicatorFont_name"],
				desc = L["indicatorFont_desc"],
				values = AceGUIWidgetLSMlists.font,
				get = function() return self.db.profile.indicatorFont end,
				set = function(_, value)
					self.db.profile.indicatorFont = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 31,
			},
			frameScale = {
				type = "range",
				name = L["frameScale_name"],
				desc = L["frameScale_desc"],
				min = 0.5,
				max = 2,
				step = 0.1,
				get = function() return self.db.profile.frameScale end,
				set = function(_, value)
					self.db.profile.frameScale = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 33,
			},
			backgroundAlpha = {
				type = "range",
				name = L["backgroundAlpha_name"],
				desc = L["backgroundAlpha_desc"],
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return self.db.profile.backgroundAlpha end,
				set = function(_, value)
					self.db.profile.backgroundAlpha = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 34,
			},
			-------------------------------------------------
			outOfRangeOptions = {
				type = "header",
				name = L["Out-of-Range"],
				order = 40,
			},
			customRangeCheck = {
				type = "toggle",
				name = L["customRangeCheck_name"],
				desc = L["customRangeCheck_desc"],
				get = function() return self.db.profile.customRangeCheck end,
				set = function(_, value)
					self.db.profile.customRangeCheck = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 41,
			},
			customRange = {
				type = "select",
				name = L["customRangeCheck_name"],
				desc = L["customRangeCheck_desc"],
				values = { [5] = "Melee", [10] = "10 yards", [20] = "20 yards", [30] = "30 yards", [35] = "35 yards"},
				get = function() return self.db.profile.customRange end,
				set = function(_, value)
					self.db.profile.customRange = value
					self:RefreshConfig()
				end,
				disabled = function() return not self.db.profile.customRangeCheck end,
				width = THIRD_WIDTH,
				order = 42,
			},
			rangeAlpha = {
				type = "range",
				name = L["rangeAlpha_name"],
				desc = L["rangeAlpha_desc"],
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return self.db.profile.rangeAlpha end,
				set = function(_, value)
					self.db.profile.rangeAlpha = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 43,
			},
		}
	}

	return generalOptions
end