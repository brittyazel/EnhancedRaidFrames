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

	local THIRD_WIDTH = 1.15
	
	local generalOptions = {
		type = "group",
		childGroups = "tree",
		args  = {
			instructions = {
				type = "description",
				name = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, raid icons, and more.",
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
				name = "Visual Options",
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
				name = "Out-of-Range Options",
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

function EnhancedRaidFrames:CreateIndicatorOptions()
	local THIRD_WIDTH = 1.1
	
	local indicatorOptions = {
		type = "group",
		childGroups = "select",
		name = "Indicator Options",
		args  = {
			instructions = {
				type = "description",
				name = "Please select an indicator position from the dropdown menu below:",
				order = 1,
			},
		}
	}

	--- Add options for each indicator
	for i,v in ipairs(POSITIONS) do
		indicatorOptions.args[v] = {}
		indicatorOptions.args[v].type = "group"
		indicatorOptions.args[v].name = i..": "..v
		indicatorOptions.args[v].desc = "The indicator positioned at the " .. v:lower() .. " of the raid frame"
		indicatorOptions.args[v].order = i+2
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
				get = function() return self.db.profile[i].auras end,
				set = function(_, value)
					self.db.profile[i].auras = value
					self:RefreshConfig()
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
				get = function() return self.db.profile[i].mineOnly end,
				set = function(_, value)
					self.db.profile[i].mineOnly = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			meOnly = {
				type = "toggle",
				name = "Show On Me Only",
				desc = "Only only show this indicator on myself",
				get = function() return self.db.profile[i].meOnly end,
				set = function(_, value)
					self.db.profile[i].meOnly = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			missingOnly = {
				type = "toggle",
				name = "Show Only if Missing",
				desc = "Show only when the buff or debuff is missing (reverse behavior from normal)",
				get = function() return self.db.profile[i].missingOnly end,
				set = function(_, value)
					self.db.profile[i].missingOnly = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 13,
			},
			showTooltip = {
				type = "toggle",
				name = "Show Tooltip",
				desc = "Show the tooltip on mouseover",
				get = function() return self.db.profile[i].showTooltip end,
				set = function(_, value)
					self.db.profile[i].showTooltip = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 14,
			},
			tooltipLocation = {
				type = "select",
				name = "Tooltip Location",
				desc = "The specified place where the tooltip should appear",
				style = "dropdown",
				values = {["ANCHOR_CURSOR"] = "Attached to Cursor", ["ANCHOR_PRESERVE"] = "Blizzard Default"},
				sorting = {[1] = "ANCHOR_CURSOR", [2] = "ANCHOR_PRESERVE"},
				get = function() return self.db.profile[i].tooltipLocation end,
				set = function(_, value)
					self.db.profile[i].tooltipLocation = value
					self:RefreshConfig()
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
				desc = "Show an icon if the buff or debuff is currently on the unit (if unchecked, a solid indicator color will be used instead)",
				get = function() return self.db.profile[i].showIcon end,
				set = function(_, value)
					self.db.profile[i].showIcon = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 31,
			},
			indicatorColor = {
				type = "color",
				name = "Indicator Color",
				desc = "The solid color used for the indicator when not showing the buff or debuff icon",
				get = function()
					return self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g, self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a
				end,
				set = function(_, r, g, b, a)
					self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g, self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a = r, g, b, a
					self:RefreshConfig()
				end,
				disabled = function () return self.db.profile[i].showIcon end,
				width = THIRD_WIDTH,
				order = 32,
			},
			colorIndicatorByTime = {
				type = "toggle",
				name = "Color By Remaining Time",
				desc = "Color the indicator based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFF569yellow|r, <2 seconds: |cFFC41F3Bred|r)",
				get = function() return self.db.profile[i].colorIndicatorByTime end,
				set = function(_, value)
					self.db.profile[i].colorIndicatorByTime = value
					self:RefreshConfig()
				end,
				disabled = function () return self.db.profile[i].showIcon end,
				width = THIRD_WIDTH,
				order = 33,
			},
			colorIndicatorByDebuff = {
				type = "toggle",
				name = "Color By Debuff Type",
				desc = "Color the indicator depending on the debuff type, will override the normal coloring (poison = |cFFA9D271green|r, magic = |cFF0070DEblue|r, curse = |cFFA330C9purple|r, and disease = |cFFC79C6Ebrown|r)",
				get = function() return self.db.profile[i].colorIndicatorByDebuff end,
				set = function(_, value)
					self.db.profile[i].colorIndicatorByDebuff = value
					self:RefreshConfig()
				end,
				disabled = function () return self.db.profile[i].showIcon end,
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
				get = function() return self.db.profile[i].indicatorVerticalOffset end,
				set = function(_, value)
					self.db.profile[i].indicatorVerticalOffset = value
					self:RefreshConfig()
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
				get = function() return self.db.profile[i].indicatorHorizontalOffset end,
				set = function(_, value)
					self.db.profile[i].indicatorHorizontalOffset = value
					self:RefreshConfig()
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
				get = function() return self.db.profile[i].indicatorSize end,
				set = function(_, value)
					self.db.profile[i].indicatorSize = value
					self:RefreshConfig()
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
			showCountdownText = {
				type = "toggle",
				name = "Show Countdown Text",
				desc = "Show countdown text specifying the time left on the buff or debuff",
				get = function() return self.db.profile[i].showCountdownText end,
				set = function(_, value)
					self.db.profile[i].showCountdownText = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 51,
			},
			showStackSize = {
				type = "toggle",
				name = "Show Stack Size",
				desc = "Show the stack size for buffs and debuffs that have stacks",
				get = function() return self.db.profile[i].showStackSize end,
				set = function(_, value)
					self.db.profile[i].showStackSize = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 52,
			},
			textColor = {
				type = "color",
				name = "Text Color",
				desc = "The text color for an indicator (unless augmented by other text color options)",
				get = function()
					return self.db.profile[i].textColor.r, self.db.profile[i].textColor.g, self.db.profile[i].textColor.b, self.db.profile[i].textColor.a
				end,
				set = function(_, r, g, b, a)
					self.db.profile[i].textColor.r, self.db.profile[i].textColor.g, self.db.profile[i].textColor.b, self.db.profile[i].textColor.a = r, g, b, a
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 53,
			},
			colorTextByStack = {
				type = "toggle",
				name = "Color By Stack Size",
				desc = "Color the text depending on the stack size, will override the normal text coloring (3+: |cFFA9D271green|r, 2: |cFFFFF569yellow|r, 1: |cFFC41F3Bred|r)",
				get = function() return self.db.profile[i].colorTextByStack end,
				set = function(_, value)
					self.db.profile[i].colorTextByStack = value
					self:RefreshConfig()
				end,
				disabled = function () return self.db.profile[i].colorTextByDebuff end,
				width = THIRD_WIDTH,
				order = 54,
			},
			colorTextByTime = {
				type = "toggle",
				name = "Color by Remaining Time",
				desc = "Color the text based on remaining time (>5 seconds: normal, 2-5 seconds: |cFFFFF569yellow|r, <2 seconds: |cFFC41F3Bred|r)",
				get = function() return self.db.profile[i].colorTextByTime end,
				set = function(_, value)
					self.db.profile[i].colorTextByTime = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 55,
			},
			colorTextByDebuff = {
				type = "toggle",
				name = "Color By Debuff Type",
				desc = "Color the text depending on the debuff type, will override the normal text coloring (poison = |cFFA9D271green|r, magic = |cFF0070DEblue|r, curse = |cFFA330C9purple|r, and disease = |cFFC79C6Ebrown|r)",
				get = function() return self.db.profile[i].colorTextByDebuff end,
				set = function(_, value)
					self.db.profile[i].colorTextByDebuff = value
					self:RefreshConfig()
				end,
				disabled = function () return self.db.profile[i].colorTextByStack end,
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
				get = function() return self.db.profile[i].textSize end,
				set = function(_, value)
					self.db.profile[i].textSize = value
					self:RefreshConfig()
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
				desc = "Show the clockwise swipe animation specifying the time left on the buff or debuff",
				get = function() return self.db.profile[i].showCountdownSwipe end,
				set = function(_, value)
					self.db.profile[i].showCountdownSwipe = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 71,
			},
			indicatorGlow = {
				type = "toggle",
				name = "Indicator Glow Effect",
				desc = "Display a glow animation effect on the indicator to make it easier to spot",
				get = function() return self.db.profile[i].indicatorGlow end,
				set = function(_, value)
					self.db.profile[i].indicatorGlow = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 72,
			},
			glowRemainingSecs = {
				type = "range",
				name = "Glow At Countdown Time",
				desc = "The amount of time remaining on the buff or debuff countdown before the glowing starts ('0' means it will always glow)",
				min = 0,
				max = 10,
				step = 1,
				get = function() return self.db.profile[i].glowRemainingSecs end,
				set = function(_, value)
					self.db.profile[i].glowRemainingSecs = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile[i].indicatorGlow end,
				width = THIRD_WIDTH,
				order = 73,
			},
		}
	end

	return indicatorOptions
end

function EnhancedRaidFrames:CreateIconOptions()
	local THIRD_WIDTH = 1.15
	
	local iconOptions = {
		type = "group",
		childGroups = "tree",
		args  = {
			instructions = {
				type = "description",
				name = "Configure how the raid marker icon should appear on the raid frames:",
				order = 1,
			},
			generalHeader = {
				type = "header",
				name = "General Options",
				order = 2,
			},
			showRaidIcons = {
				type = "toggle",
				name = "Show Raid Icons",
				desc = "Show the raid marker icon on the raid frames",
				get = function() return self.db.profile.showRaidIcons end,
				set = function(_, value)
					self.db.profile.showRaidIcons = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 3,
			},
			iconPosition = {
				type = "select",
				name = "Icon Position",
				desc = "Position of the raid icon relative to the frame",
				values = POSITIONS,
				get = function() return self.db.profile.iconPosition end,
				set = function(_, value)
					self.db.profile.iconPosition = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
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
				get = function() return self.db.profile.iconSize end,
				set = function(_, value)
					self.db.profile.iconSize = value
					self:RefreshConfig()
				end,
				disabled = function () return not self.db.profile.showRaidIcons end,
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
				name = "Icon Horizontal Offset",
				desc = "Horizontal offset percentage of the raid icon relative to its starting position",
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
			iconAlpha = {
				type = "range",
				name = "Icon Opacity",
				desc = "The opacity percentage of the raid icon",
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
				order = 24,
			},
		}
	}

	return iconOptions
end