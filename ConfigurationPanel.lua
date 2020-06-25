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
				get = function() return profile["showBuffs"] end,
				set = function(_, value)
					profile["showBuffs"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				get = function() return profile["showDebuffs"] end,
				set = function(_, value)
					profile["showDebuffs"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable debuff icons",
				get = function() return profile["showDispelDebuffs"] end,
				set = function(_, value)
					profile["showDispelDebuffs"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 13,
			},

			-------------------------------------------------

			generalHeader = {
				type = "header",
				name = "General Options",
				order = 20,
			},
			stockOptionsButton = {
				type = 'execute',
				name = "Open the Blizzard Raid Profiles Menu",
				desc = "Launch the built-in raid profiles interface configuration menu",
				func = function() InterfaceOptionsFrame_OpenToCategory("Raid Profiles") end,
				width = THIRD_WIDTH*1.5,
				order = 21,
			},

			-------------------------------------------------

			visualOptions = {
				type = "header",
				name = "Visual Options",
				order = 30,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = "Indicator Font",
				desc = "Adjust the font used for the indicators",
				values = AceGUIWidgetLSMlists.font,
				get = function() return profile["indicatorFont"] end,
				set = function(_, value)
					profile["indicatorFont"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 31,
			},
			frameScale = {
				name = "Raidframe Scale",
				type = "range",
				min = 0.5,
				max = 2,
				step = 0.1,
				get = function() return profile["frameScale"] end,
				set = function(_, value)
					profile["frameScale"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 33,
			},
			backgroundAlpha = {
				name = "Background Opacity",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return profile["backgroundAlpha"] end,
				set = function(_, value)
					profile["backgroundAlpha"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 34,
			},

			-------------------------------------------------

			outOfRangeOptions = {
				type = "header",
				name = "Out-of-Range Indicator Options",
				order = 40,
			},
			customRangeCheck = {
				name = "Override Default Distance",
				type = "toggle",
				desc = "Overrides the default out-of-range indicator distance (default 40 yards).",
				get = function() return profile["customRangeCheck"] end,
				set = function(_, value)
					profile["customRangeCheck"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 41,
			},
			customRange = {
				name = "Select a Custom Distance",
				type = "select",
				desc = "Changes the default 40 yard out-of-range distance to the specified distance.",
				values = { [5] = "Melee", [10] = "10 yards", [20] = "20 yards", [30] = "30 yards", [35] = "35 yards"},
				get = function() return profile["customRange"] end,
				set = function(_, value)
					profile["customRange"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function() return not profile.customRangeCheck end,
				width = THIRD_WIDTH,
				order = 42,
			},
			rangeAlpha = {
				name = "Out-of-Range Fade",
				type = "range",
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return profile["rangeAlpha"] end,
				set = function(_, value)
					profile["rangeAlpha"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
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
		indicatorOptions.args[v].args = {

			--------------------------------------------
			auras = {
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
				get = function() return profile["auras"..i] end,
				set = function(_, value)
					profile["auras"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH*2,
				order = 1,
			},

			--------------------------------------------

			visibilityHeader = {
				type = "header",
				name = "Visibility and Behavior",
				order = 10,
			},
			mineOnly = {
				type = "toggle",
				name = "Mine Only",
				desc = "Only show buffs and debuffs cast by me",
				get = function() return profile["mineOnly"..i] end,
				set = function(_, value)
					profile["mineOnly"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			meOnly = {
				type = "toggle",
				name = "Show On Me Only",
				desc = "Only show this indicator on myself",
				get = function() return profile["meOnly"..i] end,
				set = function(_, value)
					profile["meOnly"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			missingOnly = {
				type = "toggle",
				name = "Show Only if Missing",
				desc = "Show only if the specified buff or debuff is missing on the target (first item in the list)",
				get = function() return profile["missingOnly"..i] end,
				set = function(_, value)
					profile["missingOnly"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 13,
			},
			showTooltip = {
				type = "toggle",
				name = "Show Tooltip",
				desc = "Show tooltip on mouseover",
				get = function() return profile["showTooltip"..i] end,
				set = function(_, value)
					profile["showTooltip"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 14,
			},
			tooltipLocation = {
				type = "select",
				name = "Tooltip Location",
				desc = "The place where the tooltip should appear",
				style = "dropdown",
				values = {["ANCHOR_CURSOR"]="Attached to Cursor", ["ANCHOR_PRESERVE"]="Blizzard Default"},
				sorting = {[1] = "ANCHOR_CURSOR", [2] = "ANCHOR_PRESERVE"},
				get = function() return profile["tooltipLocation"..i] end,
				set = function(_, value)
					profile["tooltipLocation"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 15,
			},


			--------------------------------------------

			iconHeader = {
				type = "header",
				name = "Icon and Position",
				order = 30,
			},
			showIcon = {
				type = "toggle",
				name = "Show Icon",
				desc = "Show an icon if the buff or debuff is currently on the unit (if unchecked, a solid color will be used instead)",
				get = function() return profile["showIcon"..i] end,
				set = function(_, value)
					profile["showIcon"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 31,
			},
			indicatorColor = {
				type = "color",
				name = "Indicator Color",
				desc = "The a solid color for the indicator frame (disabled if showing icon)",
				get = function()
					return profile["indicatorColor"..i].r, profile["indicatorColor"..i].g, profile["indicatorColor"..i].b, profile["indicatorColor"..i].a
				end,
				set = function(_, r, g, b, a)
					profile["indicatorColor"..i].r, profile["indicatorColor"..i].g, profile["indicatorColor"..i].b, profile["indicatorColor"..i].a = r, g, b, a
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return profile["showIcon"..i] end,
				width = THIRD_WIDTH,
				order = 32,
			},
			colorIndicatorByTime = {
				type = "toggle",
				name = "Color By Remaining Time",
				desc = "Color the indicator based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFF569yellow|r, <2 seconds: |cFFC41F3Bred|r)",
				get = function() return profile["colorIndicatorByTime"..i] end,
				set = function(_, value)
					profile["colorIndicatorByTime"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return profile["showIcon"..i] end,
				width = THIRD_WIDTH,
				order = 33,
			},
			colorIndicatorByDebuff = {
				type = "toggle",
				name = "Color By Debuff Type",
				desc = "Color the indicator depending on the debuff type, will override the normal coloring (poison = |cFFA9D271green|r, magic = |cFF0070DEblue|r, curse = |cFFA330C9purple|r, and disease = |cFFC79C6Ebrown|r)",
				get = function() return profile["colorIndicatorByDebuff"..i] end,
				set = function(_, value)
					profile["colorIndicatorByDebuff"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return profile["showIcon"..i] end,
				width = THIRD_WIDTH,
				order = 34,
			},
			indicatorVerticalOffset = {
				type = "range",
				name = "Vertical Offset",
				desc = "Vertical offset percentage of the indicator relative to its starting position",
				min = -1,
				max = 1,
				step = .01,
				get = function() return profile["indicatorVerticalOffset"..i] end,
				set = function(_, value)
					profile["indicatorVerticalOffset"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 35,
			},
			indicatorHorizontalOffset = {
				type = "range",
				name = "Horizontal Offset",
				desc = "Horizontal offset percentage of the indicator relative to its starting position",
				min = -1,
				max = 1,
				step = .01,
				get = function() return profile["indicatorHorizontalOffset"..i] end,
				set = function(_, value)
					profile["indicatorHorizontalOffset"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 36,
			},
			indicatorSize = {
				type = "range",
				name = "Indicator Size",
				desc = "The size of the indicator in pixels",
				min = 1,
				max = 30,
				step = 1,
				get = function() return profile["indicatorSize"..i] end,
				set = function(_, value)
					profile["indicatorSize"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 37,
			},

			--------------------------------------------

			textHeader = {
				type = "header",
				name = "Text and Color",
				order = 50,
			},
			showText = {
				type = "toggle",
				name = "Show Countdown Text",
				desc = "Show countdown text specifying the time left of the buff or debuff",
				get = function() return profile["showText"..i] end,
				set = function(_, value)
					profile["showText"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 51,
			},
			showStack = {
				type = "toggle",
				name = "Show Stack Size",
				desc = "Show stack size for buffs and debuffs that have stacks",
				get = function() return profile["showStack"..i] end,
				set = function(_, value)
					profile["showStack"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 52,
			},
			textColor = {
				type = "color",
				name = "Text Color",
				desc = "The text color for an indicator (unless augmented by other text color options)",
				get = function()
					return profile["textColor"..i].r, profile["textColor"..i].g, profile["textColor"..i].b, profile["textColor"..i].a
				end,
				set = function(_, r, g, b, a)
					profile["textColor"..i].r, profile["textColor"..i].g, profile["textColor"..i].b, profile["textColor"..i].a = r, g, b, a
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 53,
			},
			colorTextByStack = {
				type = "toggle",
				name = "Color By Stack Size",
				desc = "Color the text depending on the stack size, will override the normal text coloring (3+: |cFFA9D271green|r, 2: |cFFFFF569yellow|r, 1: |cFFC41F3Bred|r)",
				get = function() return profile["colorTextByStack"..i] end,
				set = function(_, value)
					profile["colorTextByStack"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return profile["colorTextByDebuff"..i] end,
				width = THIRD_WIDTH,
				order = 54,
			},
			colorTextByTime = {
				type = "toggle",
				name = "Color by Remaining Time",
				desc = "Color the text based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFF569yellow|r, <2 seconds: |cFFC41F3Bred|r)",
				get = function() return profile["colorTextByTime"..i] end,
				set = function(_, value)
					profile["colorTextByTime"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 55,
			},
			colorTextByDebuff = {
				type = "toggle",
				name = "Color By Debuff Type",
				desc = "Color the text depending on the debuff type, will override the normal text coloring (poison = |cFFA9D271green|r, magic = |cFF0070DEblue|r, curse = |cFFA330C9purple|r, and disease = |cFFC79C6Ebrown|r)",
				get = function() return profile["colorTextByDebuff"..i] end,
				set = function(_, value)
					profile["colorTextByDebuff"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return profile["colorTextByStack"..i] end,
				width = THIRD_WIDTH,
				order = 56,
			},
			textSize = {
				type = "range",
				name = "Text Size",
				desc = "The size of the indicator (in pixels)",
				min = 1,
				max = 30,
				step = 1,
				get = function() return profile["textSize"..i] end,
				set = function(_, value)
					profile["textSize"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 57,
			},

			--------------------------------------------

			animationHeader = {
				type = "header",
				name = "Animations and Effects",
				order = 70,
			},
			showCountdownSwipe = {
				type = "toggle",
				name = "Show Countdown Swipe",
				desc = "Show the clockwise swipe animation specifying the time left of the buff or debuff",
				get = function() return profile["showCountdownSwipe"..i] end,
				set = function(_, value)
					profile["showCountdownSwipe"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 71,
			},
			indicatorGlow = {
				type = "toggle",
				name = "Indicator Glow Effect",
				desc = "Display a glow animation effect on the indicator to make it easier to spot",
				get = function() return profile["indicatorGlow"..i] end,
				set = function(_, value)
					profile["indicatorGlow"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 72,
			},
			glowRemainingSecs = {
				type = "range",
				name = "Glow By Remaining Time",
				desc = "The amount of time remaining on the aura countdown before glowing starts (0 means to always glow)",
				min = 0,
				max = 10,
				step = 1,
				get = function() return profile["glowRemainingSecs"..i] end,
				set = function(_, value)
					profile["glowRemainingSecs"..i] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return not profile["indicatorGlow"..i] end,
				width = THIRD_WIDTH,
				order = 73,
			},
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
				get = function() return profile["showRaidIcons"] end,
				set = function(_, value)
					profile["showRaidIcons"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 3,
			},
			iconPosition = {
				type = "select",
				name = "Icon Position",
				desc = "Position of the raid icon relative to the frame",
				values = POSITIONS,
				get = function() return profile["iconPosition"] end,
				set = function(_, value)
					profile["iconPosition"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
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
				get = function() return profile["iconSize"] end,
				set = function(_, value)
					profile["iconSize"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
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
				get = function() return profile["iconVerticalOffset"] end,
				set = function(_, value)
					profile["iconVerticalOffset"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
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
				get = function() return profile["iconHorizontalOffset"] end,
				set = function(_, value)
					profile["iconHorizontalOffset"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
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
				get = function() return profile["iconAlpha"] end,
				set = function(_, value)
					profile["iconAlpha"] = value
					EnhancedRaidFrames:RefreshConfig()
				end,
				disabled = function () return not profile.showRaidIcons end,
				width = THIRD_WIDTH,
				order = 24,
			},
		}
	}

	return iconOptions
end