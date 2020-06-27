--Enhanced Raid Frames, a World of Warcraft® user interface addon.

--This file is part of Enhanced Raid Frames.
--
--Enhanced Raid Frame is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Enhanced Raid Frame is distributed in the hope that it will be useful,
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
				name = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, raid icons, and more",
				fontSize = "medium",
				order = 2,
			},
			-------------------------------------------------
			topSpacer = {
				type = "header",
				name = "",
				order = 3,
			},
			stockOptionsButton = {
				type = 'execute',
				name = "Open the Blizzard Raid Profiles Menu",
				desc = "Launch the built-in raid profiles interface configuration menu",
				func = function() InterfaceOptionsFrame_OpenToCategory("Raid Profiles") end,
				width = THIRD_WIDTH * 1.5,
				order = 4,
			},
			-------------------------------------------------
			textHeader = {
				type = "header",
				name = "Default Icon Visibility",
				order = 10,
			},
			showBuffs = {
				type = "toggle",
				name = "Stock Buff Icons",
				desc = "Show the standard raid frame buff icons",
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
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
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
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable icons",
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
				name = "General",
				order = 30,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = "Indicator Font",
				desc = "The the font used for the indicators",
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
				name = "Raidframe Scale",
				desc = "The the scale of the raidframe from 50% to 200% of the normal size",
				type = "range",
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
				name = "Background Opacity",
				desc = "The opacity percentage of the raid frame background",
				type = "range",
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
				name = "Out-of-Range",
				order = 40,
			},
			customRangeCheck = {
				name = "Override Default Distance",
				type = "toggle",
				desc = "Overrides the default out-of-range indicator distance (default 40 yards)",
				get = function() return self.db.profile.customRangeCheck end,
				set = function(_, value)
					self.db.profile.customRangeCheck = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 41,
			},
			customRange = {
				name = "Select a Custom Distance",
				type = "select",
				desc = "Changes the default 40 yard out-of-range distance to the specified distance",
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
				name = "Out-of-Range Opacity",
				desc = "The opacity percentage of the raid frame when out-of-range",
				type = "range",
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