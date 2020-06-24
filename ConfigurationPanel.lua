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

local POSITIONS = { [1] = "Top Left", [2] = "Top Center", [3] = "Top Right" ,
					[4] = "Middle Left", [5] = "Middle Center", [6] = "Middle Right",
					[7] = "Bottom Left", [8] = "Bottom Center", [9] = "Bottom Right"}

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateGeneralOptions()
	local profile = EnhancedRaidFrames.db.profile

	local THIRD_WIDTH = 1.15
	local generalOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return profile[item[#item]] end,
		set = function(item, value)
			profile[item[#item]] = value
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
				width = THIRD_WIDTH,
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				width = THIRD_WIDTH,
				order = 12,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable debuff icons",
				width = THIRD_WIDTH,
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
				width = THIRD_WIDTH,
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
				width = THIRD_WIDTH,
				order = 31,
			},
			backgroundAlpha = {
				name = "Background Opacity",
				type = "range",
				min = 0,
				max = 1,
				width = THIRD_WIDTH,
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
				width = THIRD_WIDTH,
				order = 41,
			},
			customRange = {
				name = "Select a Custom Distance",
				type = "select",
				desc = "Changes the default 40 yard out-of-range distance to the specified distance.",
				disabled = function() return not profile.customRangeCheck end,
				values = { [5] = "Melee", [10] = "10 yards", [20] = "20 yards", [30] = "30 yards", [35] = "35 yards"},
				width = THIRD_WIDTH,
				order = 42,
			},
			rangeAlpha = {
				name = "Out-of-Range Fade",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
				width = THIRD_WIDTH,
				order = 43,
			},
		}
	}

	return generalOptions
end

function EnhancedRaidFrames:CreateIndicatorOptions()
	local profile = EnhancedRaidFrames.db.profile

	local THIRD_WIDTH = 1.1
	local indicatorOptions = {
		type = 'group',
		childGroups = 'select',
		get = function(item) return profile[item[#item]] end,
		set = function(item, value)
			profile[item[#item]] = value
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
	for i,v in ipairs(POSITIONS) do
		indicatorOptions.args[v] = {}
		indicatorOptions.args[v].type = 'group'
		indicatorOptions.args[v].name = i..": "..v
		indicatorOptions.args[v].desc = "The indicator positioned at the " .. v:lower() .. " of the raid frame"
		indicatorOptions.args[v].order = i
		indicatorOptions.args[v].args = {}

		--------------------------------------------

		indicatorOptions.args[v].args["auras"..i] = {
			type = "input",
			name = "Buff and/or Debuff Watch List:",
			desc = "The buffs and/or debuffs to show for the indicator in this position.\n"..
			"\n"..
			"Write the name or spell ID of each buff/debuff on a separate line. i.e: Rejuvenation, Regrowth, Wild Growth, 155777, etc.\n"..
			"\n"..
			"You can use Magic, Poison, Curse, or Disease to show any debuff of that category.\n"..
			"\n"..
			"You can use PvP to show if a unit is PvP flagged.\n"..
			"\n"..
			"You can use ToT to show if a unit is the target of your target.\n",
			multiline = true,
			order = 1,
			width = THIRD_WIDTH*2,
		}

		--------------------------------------------

		indicatorOptions.args[v].args.visibilityHeader = {
			type = "header",
			name = "Visibility and Behavior",
			order = 10,
		}
		indicatorOptions.args[v].args["mine"..i] = {
			type = "toggle",
			name = "Mine Only",
			desc = "Only show buffs and debuffs cast by me",
			width = THIRD_WIDTH,
			order = 11,
		}
		indicatorOptions.args[v].args["me"..i] = {
			type = "toggle",
			name = "Show On Me Only",
			desc = "Only show this indicator on myself",
			width = THIRD_WIDTH,
			order = 12,
		}
		indicatorOptions.args[v].args["missing"..i] = {
			type = "toggle",
			name = "Show Only if Missing",
			desc = "Show only if the specified buff or debuff is missing on the target (first item in the list)",
			width = THIRD_WIDTH,
			order = 13,
		}
		indicatorOptions.args[v].args["showTooltip"..i] = {
			type = "toggle",
			name = "Show Tooltip",
			desc = "Show tooltip on mouseover",
			width = THIRD_WIDTH,
			order = 14,
		}
		indicatorOptions.args[v].args["tooltipLocation"..i] = {
			type = "select",
			name = "Tooltip Location",
			desc = "The place where the tooltip should appear",
			style = "dropdown",
			values = {["ANCHOR_CURSOR"]="Attached to Cursor", ["ANCHOR_PRESERVE"]="Blizzard Default"},
			sorting = {[1] = "ANCHOR_CURSOR", [2] = "ANCHOR_PRESERVE"},
			width = THIRD_WIDTH,
			order = 15,
		}


		--------------------------------------------

		indicatorOptions.args[v].args.iconHeader = {
			type = "header",
			name = "Icon and Position",
			order = 30,
		}
		indicatorOptions.args[v].args["showIcon"..i] = {
			type = "toggle",
			name = "Show Icon",
			desc = "Show an icon if the buff or debuff is currently on the unit",
			width = THIRD_WIDTH,
			order = 31,
		}
		indicatorOptions.args[v].args["indicatorColor"..i] = {
			type = "color",
			name = "Indicator Color",
			desc = "The a solid color for the indicator frame (unless augmented by other indicator color options)",
			get = function(item)
				local t = profile[item[#item]]
				return t.r, t.g, t.b, t.a
			end,
			set = function(item, r, g, b, a)
				local t = profile[item[#item]]
				t.r, t.g, t.b, t.a = r, g, b, a
				EnhancedRaidFrames:RefreshConfig()
			end,
			disabled = function () return profile["showIcon"..i] end,
			width = THIRD_WIDTH,
			order = 32,
		}
		indicatorOptions.args[v].args["colorIndicatorByTime"..i] = {
			type = "toggle",
			name = "Color By Remaining Time",
			desc = "Color the indicator based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFFF00yellow|r, <2 seconds: |cFFFF0000red|r)",
			disabled = function () return profile["showIcon"..i] end,
			width = THIRD_WIDTH,
			order = 33,
		}
		indicatorOptions.args[v].args["colorIndicatorByDebuff"..i] = {
			type = "toggle",
			name = "Color By Debuff Type",
			desc = "Color the indicator depending on the debuff type, will override the normal coloring (poison = |cFF00FF00green|r, magic = |cFF0000FFblue|r, etc)",
			disabled = function () return profile["showIcon"..i] end,
			width = THIRD_WIDTH,
			order = 34,
		}
		indicatorOptions.args[v].args["indicatorVerticalOffset"..i] = {
			type = "range",
			name = "Vertical Offset",
			desc = "Vertical offset percentage of the indicator relative to its starting position",
			min = -1,
			max = 1,
			step = .01,
			width = THIRD_WIDTH,
			order = 35,
		}
		indicatorOptions.args[v].args["indicatorHorizontalOffset"..i] = {
			type = "range",
			name = "Horizontal Offset",
			desc = "Horizontal offset percentage of the indicator relative to its starting position",
			min = -1,
			max = 1,
			step = .01,
			width = THIRD_WIDTH,
			order = 36,
		}
		indicatorOptions.args[v].args["indicatorSize"..i] = {
			type = "range",
			name = "Indicator Size",
			desc = "The size of the indicator in pixels",
			min = 1,
			max = 30,
			step = 1,
			width = THIRD_WIDTH,
			order = 37,
		}

		--------------------------------------------

		indicatorOptions.args[v].args.textHeader = {
			type = "header",
			name = "Text and Color",
			order = 50,
		}
		indicatorOptions.args[v].args["showText"..i] = {
			type = "toggle",
			name = "Show Countdown Text",
			desc = "Show countdown text specifying the time left of the buff or debuff",
			width = THIRD_WIDTH,
			order = 51,
		}
		indicatorOptions.args[v].args["showStack"..i] = {
			type = "toggle",
			name = "Show Stack Size",
			desc = "Show stack size for buffs and debuffs that have stacks",
			width = THIRD_WIDTH,
			order = 52,
		}
		indicatorOptions.args[v].args["textColor"..i] = {
			type = "color",
			name = "Text Color",
			desc = "The text color for an indicator (unless augmented by other text color options)",
			get = function(item)
				local t = profile[item[#item]]
				return t.r, t.g, t.b, t.a
			end,
			set = function(item, r, g, b, a)
				local t = profile[item[#item]]
				t.r, t.g, t.b, t.a = r, g, b, a
				EnhancedRaidFrames:RefreshConfig()
			end,
			width = THIRD_WIDTH,
			order = 53,
		}
		indicatorOptions.args[v].args["colorTextByStack"..i] = {
			type = "toggle",
			name = "Color By Stack Size",
			desc = "Color the text depending on the stack size, will override the normal text coloring (3+: |cFF00FF00green|r, 2: |cFFFFFF00yellow|r, 1: |cFFFF0000red|r)",
			disabled = function () return profile["colorTextByDebuff"..i] end,
			width = THIRD_WIDTH,
			order = 54,
		}
		indicatorOptions.args[v].args["colorTextByTime"..i] = {
			type = "toggle",
			name = "Color by Remaining Time",
			desc = "Color the text based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFFF00yellow|r, <2 seconds: |cFFFF0000red|r)",
			width = THIRD_WIDTH,
			order = 55,
		}
		indicatorOptions.args[v].args["colorTextByDebuff"..i] = {
			type = "toggle",
			name = "Color By Debuff Type",
			desc = "Color the text depending on the debuff type, will override the normal text coloring (poison = |cFF00FF00green|r, magic = |cFF0000FFblue|r, etc)",
			disabled = function () return profile["colorTextByStack"..i] end,
			width = THIRD_WIDTH,
			order = 56,
		}
		indicatorOptions.args[v].args["textSize"..i] = {
			type = "range",
			name = "Text Size",
			desc = "The size of the indicator (in pixels)",
			min = 1,
			max = 30,
			step = 1,
			width = THIRD_WIDTH,
			order = 57,
		}

		--------------------------------------------

		indicatorOptions.args[v].args.animationHeader = {
			type = "header",
			name = "Animations and Effects",
			order = 70,
		}
		indicatorOptions.args[v].args["showCountdownSwipe"..i] = {
			type = "toggle",
			name = "Show Countdown Swipe",
			desc = "Show the clockwise swipe animation specifying the time left of the buff or debuff",
			width = THIRD_WIDTH,
			order = 71,
		}
		indicatorOptions.args[v].args["indicatorGlow"..i] = {
			type = "toggle",
			name = "Indicator Glow Effect",
			desc = "Display a glow animation effect on the indicator to make it easier to spot",
			width = THIRD_WIDTH,
			order = 72,
		}
		indicatorOptions.args[v].args["glowSecondsLeft"..i] = {
			type = "range",
			name = "Glow with Seconds Left",
			desc = "The amount of time left on the aura countdown in which to start glowing (0 means always glow)",
			min = 0,
			max = 10,
			step = 1,
			disabled = function () return not profile["indicatorGlow"..i] end,
			width = THIRD_WIDTH,
			order = 73,
		}
	end

	return indicatorOptions
end

function EnhancedRaidFrames:CreateIconOptions()
	local profile = EnhancedRaidFrames.db.profile

	local THIRD_WIDTH = 1.15
	local iconOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return profile[item[#item]] end,
		set = function(item, value)
			profile[item[#item]] = value
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
				width = THIRD_WIDTH,
				order = 3,
			},
			iconPosition = {
				type = "select",
				name = "Icon Position",
				desc = "Position of the raid icon relative to the frame",
				values = POSITIONS,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
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
				desc = "The size of the raid icon in pixels",
				min = 1,
				max = 40,
				step = 1,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 21,
			},
			iconVerticalOffset = {
				type = "range",
				name = "Icon Vertical Offset",
				desc = "Vertical offset percentage of the raid icon relative to its starting position",
				min = -1,
				max = 1,
				step = .01,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 22,
			},
			iconHorizontalOffset = {
				type = "range",
				name = "Icon Horizontal Offset",
				desc = "Horizontal offset percentage of the raid icon relative to its starting position",
				min = -1,
				max = 1,
				step = .01,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 23,
			},
			iconAlpha = {
				type = "range",
				name = "Icon Opacity",
				desc = "The opacity percentage of the raid icon",
				min = 0,
				max = 1,
				step = 0.05,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 24,
			},
		}
	}

	return iconOptions
end