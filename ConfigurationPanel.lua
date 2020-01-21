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
--Copyright for portions of Neuron are held in the public domain,
--as determined by Szandos. All other copyrights for
--Enhanced Raid Frame are held by Britt Yazel, 2017-2019.

local _, AddonTable = ...
local EnhancedRaidFrames = AddonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateGeneralOptions()
	local generalOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value)
			EnhancedRaidFrames.db.profile[item[#item]] = value
			EnhancedRaidFrames:RefreshConfig()
		end,
		args  = {
			instructions = {
				type = "description",
				name = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, raid icons, and more.",
				order = 2,
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
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				order = 12,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable debuff icons",
				order = 13,
			},

			-------------------------------------------------
			generalHeader = {
				type = "header",
				name = "General Options",
				order = 20,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = "Indicator Font",
				desc = "Adjust the font used for the indicators",
				values = AceGUIWidgetLSMlists.font,
				order = 21,
			},
			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = "Visual Options",
				order = 30,
			},
			frameScale = {
				order = 31,
				name = "Raidframe Scale",
				type = "range",
				min = 0.5,
				max = 2,
				step = 0.1,
			},
			rangeAlpha = {
				order = 32,
				name = "Out-of-Range Fade",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
			},
			backgroundAlpha = {
				order = 33,
				name = "Background Transparency",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
			},
		}

	}

	return generalOptions

end


function EnhancedRaidFrames:CreateIndicatorOptions()

	local indicatorOptions = {
		type = 'group',
		childGroups = 'select',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value)
			EnhancedRaidFrames.db.profile[item[#item]] = value
			EnhancedRaidFrames:RefreshConfig()
		end,
		args  = {
			instructions = {
				type = "description",
				name = "Please select an indicator position from the dropdown menu below:",
				order = 1,
			},
		}
	}

	--- Add options for each indicator
	local indicatorNames = {"Top Left", "Top", "Top Right", "Left", "Center", "Right", "Bottom Left", "Bottom", "Bottom Right"}

	for i = 1, 9 do
		indicatorOptions.args["i"..i] = {}
		indicatorOptions.args["i"..i].type = 'group'
		indicatorOptions.args["i"..i].name = indicatorNames[i]
		indicatorOptions.args["i"..i].order = i
		indicatorOptions.args["i"..i].args = {}
		indicatorOptions.args["i"..i].args["auras"..i] = {
			type = "input",
			name = "Buffs/Debuff watch list",
			desc = "The buffs and/or debuffs to show for the indicator in this position.\n"..
			"\n"..
			"Write the name or spell ID of each buff/debuff on a separate line. i.e: 'Rejuvenation', 'Regrowth', 'Wild Growth', etc.\n"..
			"\n"..
			"Keep in mind, certain spells like a Druid's Germination will only work with their spell ID, i.e.: '155777'\n"..
			"\n"..
			"You can use 'Magic', 'Poison', 'Curse', or 'Disease' to show any debuff of that category.\n"..
			"\n"..
			"You can use 'PvP' to show if a unit is PvP flagged.\n"..
			"\n"..
			"You can use 'ToT' to show if a unit is the target of your target.",
			multiline = true,
			order = 1,
			width = "full",
		}
		indicatorOptions.args["i"..i].args.visibilityHeader = {
			type = "header",
			name = "Visibility",
			order = 5,
		}
		indicatorOptions.args["i"..i].args["mine"..i] = {
			type = "toggle",
			name = "Mine only",
			desc = "Only show buffs/debuffs cast by me",
			order = 10,
		}
		indicatorOptions.args["i"..i].args["missing"..i] = {
			type = "toggle",
			name = "Show only if missing",
			desc = "Show only if all specified buffs/debuffs are missing on the target",
			order = 30,
		}
		indicatorOptions.args["i"..i].args["me"..i] = {
			type = "toggle",
			name = "Show on me only",
			desc = "Only show this indicator on myself",
			order = 40,
		}
		indicatorOptions.args["i"..i].args.textHeader = {
			type = "header",
			name = "Text",
			order = 100,
		}
		indicatorOptions.args["i"..i].args["showText"..i] = {
			type = "toggle",
			name = "Show cooldown text",
			desc = "Show the cooldown text specifying the time left of the buff/debuff",
			order = 110,
		}
		indicatorOptions.args["i"..i].args["stack"..i] = {
			type = "toggle",
			name = "Show stack size",
			desc = "Show stack size for buffs/debuffs that stack",
			order = 111,
		}
		indicatorOptions.args["i"..i].args["color"..i] = {
			type = "color",
			name = "Text color",
			desc = "The text color for an indicator unless augmented by other text color options",
			get = function(item)
				local t = EnhancedRaidFrames.db.profile[item[#item]]
				return t.r, t.g, t.b, t.a
			end,
			set = function(item, r, g, b, a)
				local t = EnhancedRaidFrames.db.profile[item[#item]]
				t.r, t.g, t.b, t.a = r, g, b, a
				EnhancedRaidFrames:RefreshConfig()
			end,
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 120,
		}
		indicatorOptions.args["i"..i].args["stackColor"..i] = {
			type = "toggle",
			name = "Color by stack size",
			desc = "Color the text depending on the stack size, will override any other coloring (3+: Green, 2: Yellow, 1: Red)",
			disabled = function () return EnhancedRaidFrames.db.profile["debuffColor"..i] end,
			order = 160,
		}
		indicatorOptions.args["i"..i].args["debuffColor"..i] = {
			type = "toggle",
			name = "Color by debuff type",
			desc = "Color the text depending on the debuff type, will override any other coloring (poison = green, magic = blue etc)",
			disabled = function () return EnhancedRaidFrames.db.profile["stackColor"..i] end,
			order = 165,
		}
		indicatorOptions.args["i"..i].args["colorByTime"..i] = {
			type = "toggle",
			name = "Color by remaining time",
			desc = "Color the counter based on remaining time (5s+: Selected color, 3-5s: Yellow, 3s-: Red)",
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 180,
		}
		indicatorOptions.args["i"..i].args["size"..i] = {
			type = "range",
			name = "Text Size",
			desc = "The size to make the indicator text",
			min = 1,
			max = 30,
			step = 1,
			order = 190,
			width = "full",
		}
		indicatorOptions.args["i"..i].args.iconHeader = {
			type = "header",
			name = "Icon",
			order = 300,
		}
		indicatorOptions.args["i"..i].args["showIcon"..i] = {
			type = "toggle",
			name = "Show icon",
			desc = "Show an icon if the buff/debuff are on the unit",
			order = 310,
		}
		indicatorOptions.args["i"..i].args["showCooldownAnimation"..i] = {
			type = "toggle",
			name = "Show CD animation",
			desc = "Show the cooldown animation specifying the time left of the buff/debuff",
			disabled = function () return not EnhancedRaidFrames.db.profile["showIcon"..i] end,
			order = 311,
		}
		indicatorOptions.args["i"..i].args["showTooltip"..i] = {
			type = "toggle",
			name = "Show tooltip",
			desc = "Show tooltip on mouseover",
			disabled = function () return not EnhancedRaidFrames.db.profile["showIcon"..i] end,
			order = 315,
		}
		indicatorOptions.args["i"..i].args["iconSize"..i] = {
			type = "range",
			name = "Icon size",
			desc = "The size to make the indicator icon",
			min = 1,
			max = 30,
			step = 1,
			width = "full",
			disabled = function () return not EnhancedRaidFrames.db.profile["showIcon"..i] end,
			order = 320,
		}
	end

	return indicatorOptions
end

function EnhancedRaidFrames:CreateIconOptions()
	local iconOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value)
			EnhancedRaidFrames.db.profile[item[#item]] = value
			EnhancedRaidFrames:RefreshConfig()
		end,
		args  = {
			instructions = {
				type = "description",
				name = "Configure how raid marker icons should appear on the raid frames:",
				order = 1,
			},
			showRaidIcons = {
				type = "toggle",
				name = "Show Raid Icons",
				desc = "Show raid marker icons on the raid frames",
				order = 3,
			},
			iconPosition = {
				type = "select",
				name = "Icon Position",
				desc = "Position of the raid icon relative to the frame",
				values = { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right" ,
				           ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right",
				           ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right"},
				disabled = function () return not EnhancedRaidFrames.db.profile.showRaidIcons end,
				order = 10,
			},

			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = "Visual Options",
				order = 20,
			},
			iconSize = {
				type = 'range',
				name = "Icon Size",
				desc = "The size of the raid icons",
				min = 1,
				max = 40,
				step = 1,
				disabled = function () return not EnhancedRaidFrames.db.profile.showRaidIcons end,
				order = 21,
			},
			iconVerticalOffset = {
				type = "range",
				name = "Icon Vertical Offset",
				desc = "Vertical offset of the raid icon relative to its starting position",
				min = -20,
				max = 20,
				step = 1,
				disabled = function () return not EnhancedRaidFrames.db.profile.showRaidIcons end,
				order = 22,
			},
			iconHorizontalOffset = {
				type = "range",
				name = "Icon Horizontal Offset",
				desc = "Horizontal offset of the raid icon relative to its starting position",
				min = -20,
				max = 20,
				step = 1,
				disabled = function () return not EnhancedRaidFrames.db.profile.showRaidIcons end,
				order = 23,
			},
		}
	}

	return iconOptions

end