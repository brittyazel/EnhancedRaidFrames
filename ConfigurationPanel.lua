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

local addonName, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

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
				width = 1.15,
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				width = 1.15,
				order = 12,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable debuff icons",
				width = 1.15,
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
				width = 1.15,
				order = 21,
			},

			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = "Visual Options",
				order = 30,
			},
			frameScale = {
				name = "Raidframe Scale",
				type = "range",
				min = 0.5,
				max = 2,
				step = 0.1,
				width = 1.15,
				order = 31,
			},
			backgroundAlpha = {
				name = "Background Transparency",
				type = "range",
				min = 0,
				max = 1,
				width = 1.15,
				step = 0.05,
				order = 33,
			},

			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = "Out-of-Range Indicator Options",
				order = 40,
			},
			customRangeCheck = {
				name = "Override Default Distance",
				type = "toggle",
				desc = "Overrides the default out-of-range indicator distance (default 40 yards).",
				width = 1.15,
				order = 41,
			},
			customRange = {
				name = "Select a Custom Distance",
				type = "select",
				desc = "Changes the default 40 yard out-of-range distance to the specified distance.",
				disabled = function() return not EnhancedRaidFrames.db.profile.customRangeCheck end,
				values = { [5] = "Melee", [10] = "10 yards", [20] = "20 yards", [30] = "30 yards", [35] = "35 yards"},
				width = 1.15,
				order = 42,
			},
			rangeAlpha = {
				name = "Out-of-Range Fade",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
				width = 1.15,
				order = 43,
			},
		}

	}

	return generalOptions
end

function EnhancedRaidFrames:CreateIndicatorOptions()
	local indicatorOptions = {
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
				name = "Please select an indicator position from the menu below:",
				order = 1,
			},
		}
	}

	--- Add options for each indicator
	local indicatorNames = {"Top-Left", "Top-Center", "Top-Right", "Middle-Left", "Middle-Center", "Middle-Right", "Bottom-Left", "Bottom-Center", "Bottom-Right"}

	for i,v in ipairs(indicatorNames) do
		indicatorOptions.args[v] = {}
		indicatorOptions.args[v].type = 'group'
		indicatorOptions.args[v].name = i..": "..v
		indicatorOptions.args[v].desc = "The indicator positioned at the " .. v:lower() .. " of the raid frame"
		indicatorOptions.args[v].order = i
		indicatorOptions.args[v].args = {}
		indicatorOptions.args[v].args["auras"..i] = {
			type = "input",
			name = "Buff/Debuff watch list:",
			desc = "The buffs and/or debuffs to show for the indicator in this position.\n"..
			"\n"..
			"Write the name or spell ID of each buff/debuff on a separate line. i.e: Rejuvenation, Regrowth, Wild Growth, etc.\n"..
			"\n"..
			"Keep in mind, certain spells like a Druid's Germination will only work with their spell ID, i.e.: 155777.\n"..
			"\n"..
			"You can use Magic, Poison, Curse, or Disease to show any debuff of that category.\n"..
			"\n"..
			"You can use PvP to show if a unit is PvP flagged.\n"..
			"\n"..
			"You can use ToT to show if a unit is the target of your target.\n",
			multiline = true,
			order = 1,
			width = "full",
		}

		--------------------------------------------
		indicatorOptions.args[v].args.visibilityHeader = {
			type = "header",
			name = "Visibility",
			order = 5,
		}
		indicatorOptions.args[v].args["mine"..i] = {
			type = "toggle",
			name = "Mine only",
			desc = "Only show buffs/debuffs cast by me",
			order = 10,
		}
		indicatorOptions.args[v].args["missing"..i] = {
			type = "toggle",
			name = "Show only if missing",
			desc = "Show only if the specified buff/debuff is missing on the target",
			order = 30,
		}
		indicatorOptions.args[v].args["me"..i] = {
			type = "toggle",
			name = "Show on me only",
			desc = "Only show this indicator on myself",
			order = 40,
		}
		indicatorOptions.args[v].args.textHeader = {
			type = "header",
			name = "Text",
			order = 100,
		}
		indicatorOptions.args[v].args["showText"..i] = {
			type = "toggle",
			name = "Show cooldown text",
			desc = "Show cooldown text specifying the time left of the buff/debuff",
			order = 110,
		}
		indicatorOptions.args[v].args["stack"..i] = {
			type = "toggle",
			name = "Show stack size",
			desc = "Show stack size for buffs/debuffs that stack",
			order = 111,
		}
		indicatorOptions.args[v].args["color"..i] = {
			type = "color",
			name = "Text color",
			desc = "The text color for an indicator (unless augmented by other text color options)",
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
		indicatorOptions.args[v].args["stackColor"..i] = {
			type = "toggle",
			name = "Color by stack size",
			desc = "Color the text depending on the stack size, will override any other coloring (3+: |cFF00FF00green|r, 2: |cFFFFFF00yellow|r, 1: |cFFFF0000red|r)",
			disabled = function () return EnhancedRaidFrames.db.profile["debuffColor"..i] end,
			order = 160,
		}
		indicatorOptions.args[v].args["debuffColor"..i] = {
			type = "toggle",
			name = "Color by debuff type",
			desc = "Color the text depending on the debuff type, will override any other coloring (poison = |cFF00FF00green|r, magic = |cFF0000FFblue|r, etc)",
			disabled = function () return EnhancedRaidFrames.db.profile["stackColor"..i] end,
			order = 165,
		}
		indicatorOptions.args[v].args["colorByTime"..i] = {
			type = "toggle",
			name = "Color by remaining time",
			desc = "Color the counter based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFFF00yellow|r, <2 seconds: |cFFFF0000red|r)",
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 180,
		}
		indicatorOptions.args[v].args["size"..i] = {
			type = "range",
			name = "Text Size",
			desc = "The size of the indicator text",
			min = 1,
			max = 30,
			step = 1,
			order = 190,
			width = "full",
		}
		indicatorOptions.args[v].args.iconHeader = {
			type = "header",
			name = "Icon",
			order = 300,
		}
		indicatorOptions.args[v].args["showIcon"..i] = {
			type = "toggle",
			name = "Show icon",
			desc = "Show an icon if the buff/debuff is currently on the unit",
			order = 310,
		}
		indicatorOptions.args[v].args["showCooldownAnimation"..i] = {
			type = "toggle",
			name = "Show CD animation",
			desc = "Show the cooldown animation specifying the time left of the buff/debuff",
			disabled = function () return not EnhancedRaidFrames.db.profile["showIcon"..i] end,
			order = 311,
		}
		indicatorOptions.args[v].args["showTooltip"..i] = {
			type = "toggle",
			name = "Show tooltip",
			desc = "Show tooltip on mouseover",
			disabled = function () return not EnhancedRaidFrames.db.profile["showIcon"..i] end,
			order = 315,
		}
		indicatorOptions.args[v].args["iconSize"..i] = {
			type = "range",
			name = "Icon size",
			desc = "The size of the indicator icon",
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
				name = "Configure how the raid marker icon should appear on the raid frames:",
				order = 1,
			},
			showRaidIcons = {
				type = "toggle",
				name = "Show Raid Icons",
				desc = "Show the raid marker icon on the raid frames",
				width = 1.15,
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
				width = 1.15,
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
				desc = "The size of the raid icon",
				min = 1,
				max = 40,
				step = 1,
				disabled = function () return not EnhancedRaidFrames.db.profile.showRaidIcons end,
				width = 1.15,
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
				width = 1.15,
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
				width = 1.15,
				order = 23,
			},
		}
	}

	return iconOptions
end