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

local POSITIONS = { [1] = L["Top left"], [2] = L["Top Center"], [3] = L["Top Right"],
					[4] = L["Middle Left"], [5] = L["Middle Center"], [6] = L["Middle Right"],
					[7] = L["Bottom Left"], [8] = L["Bottom Center"], [9] = L["Bottom Right"]}

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateIconOptions()
	local THIRD_WIDTH = 1.15

	local iconOptions = {
		type = "group",
		childGroups = "tree",
		args  = {
			instructions = {
				type = "description",
				name = L["generalOptions_desc"]..":",
				fontSize = "medium",
				order = 1,
			},
			-------------------------------------------------
			generalHeader = {
				type = "header",
				name = L["General"],
				order = 2,
			},
			showRaidIcons = {
				type = "toggle",
				name = L["Show Raid Icons"],
				desc = L["showRaidIcons_desc"],
				get = function() return self.db.profile.showRaidIcons end,
				set = function(_, value)
					self.db.profile.showRaidIcons = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 3,
			},
			iconSize = {
				type = 'range',
				name = L["Icon Size"],
				desc = L["iconSize_desc"],
				min = 1,
				max = 40,
				step = 1,
				get = function() return self.db.profile.iconSize end,
				set = function(_, value)
					self.db.profile.iconSize = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 11,
			},
			iconAlpha = {
				type = "range",
				name = L["Icon Opacity"],
				desc = L["iconAlpha_desc"],
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return self.db.profile.iconAlpha end,
				set = function(_, value)
					self.db.profile.iconAlpha = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 12,
			},
			-------------------------------------------------
			positionOptions = {
				type = "header",
				name = L["Position"],
				order = 20,
			},
			iconPosition = {
				type = "select",
				name = L["Icon Position"],
				desc = L["iconPosition_desc"],
				values = POSITIONS,
				get = function() return self.db.profile.iconPosition end,
				set = function(_, value)
					self.db.profile.iconPosition = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 21,
			},
			iconVerticalOffset = {
				type = "range",
				name = L["Vertical Offset"],
				desc = L["verticalOffset_desc"],
				min = -1,
				max = 1,
				step = .01,
				get = function() return self.db.profile.iconVerticalOffset end,
				set = function(_, value)
					self.db.profile.iconVerticalOffset = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 22,
			},
			iconHorizontalOffset = {
				type = "range",
				name = L["Horizontal Offset"],
				desc = L["horizontalOffset_desc"],
				min = -1,
				max = 1,
				step = .01,
				get = function() return self.db.profile.iconHorizontalOffset end,
				set = function(_, value)
					self.db.profile.iconHorizontalOffset = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 23,
			},
		}
	}

	return iconOptions
end