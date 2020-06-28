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

local POSITIONS = { [1] = "Top Left", [2] = "Top Center", [3] = "Top Right" ,
					[4] = "Middle Left", [5] = "Middle Center", [6] = "Middle Right",
					[7] = "Bottom Left", [8] = "Bottom Center", [9] = "Bottom Right"}

local yellowCode = "|cFFFFF569<text>|r"
local redCode = "|cFFC41F3B<text>|r"
local greenCode = "|cFFA9D271<text>|r"
local purpleCode = "|cFFA330C9<text>|r"
local blueCode = "|cFF0070DEMagic|r"
local brownCode = "|cFFC79C6E<text>|r"

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateIndicatorOptions()
	local THIRD_WIDTH = 1.1

	local indicatorOptions = {
		type = "group",
		childGroups = "select",
		name = "Indicator Options",
		args  = {
			instructions = {
				type = "description",
				name = "Please select an indicator position from the dropdown menu below"..":",
				fontSize = "medium",
				order = 1,
			},
		}
	}

	--- Add options for each indicator
	for i,v in ipairs(POSITIONS) do
		indicatorOptions.args[v] = {}
		indicatorOptions.args[v].type = "group"
		indicatorOptions.args[v].childGroups = "tab"
		indicatorOptions.args[v].name = i..": "..v
		indicatorOptions.args[v].order = i+1
		indicatorOptions.args[v].args = {
			--------------------------------------------
			instructions = {
				type = "description",
				name = "The box to the right contains the list of auras to watch at the position"..": "..gsub(yellowCode,"<text>", v:lower()).."\n"..
						"\n"..
						"Type the names or spell IDs of each aura to track, each on a separate line".."\n",
				fontSize = "medium",
				width = THIRD_WIDTH,
				order = 1,
			},
			auras = {
				type = "input",
				name = "Aura Watch List",
				desc = "The list of buffs, debuffs, and/or wildcards to watch in this position",
				usage = "\n"..
						"\n"..
						"Any valid aura name or spell ID found in the game, spelled correctly, should work"..". ".."Example"..":\n"..
						"\n"..
						"Rejuvenation".."\n"..
						"PvP".."\n"..
						"Curse".."\n"..
						"155777".."\n"..
						"Magic".."\n"..
						"\n"..
						"Wildcards"..":\n"..
						gsub(greenCode, "<text>", "Poison")..": ".."any poison effects".."\n"..
						gsub(purpleCode, "<text>", "Curse")..": ".."any curse effects".."\n"..
						gsub(brownCode, "<text>", "Disease")..": ".."any disease effects".."\n"..
						gsub(blueCode, "<text>", "Magic")..": ".."any magic effects".."\n"..
						gsub(redCode, "<text>", "PvP")..": ".."if the unit is PvP flagged".."\n"..
						gsub(redCode, "<text>", "ToT")..": ".."if the unit is the target of target".."\n",
				multiline = 5,
				get = function() return self.db.profile[i].auras end,
				set = function(_, value)
					self.db.profile[i].auras = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH*1.7,
				order = 2,
			},
			--------------------------------------------
			visibilityOptions = {
				type = "group",
				name = "Visibility and Behavior",
				order = 3,
				args = {
					generalOptions = {
						type = "header",
						name = "General",
						order = 1,
					},
					mineOnly = {
						type = "toggle",
						name = "Mine Only",
						desc = "Only show buffs and debuffs cast by me",
						descStyle = "inline",
						get = function()
							return self.db.profile[i].mineOnly
						end,
						set = function(_, value)
							self.db.profile[i].mineOnly = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 2,
					},
					meOnly = {
						type = "toggle",
						name = "Show On Me Only",
						desc = "Only only show this indicator on myself",
						descStyle = "inline",
						get = function()
							return self.db.profile[i].meOnly
						end,
						set = function(_, value)
							self.db.profile[i].meOnly = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 3,
					},
					missingOnly = {
						type = "toggle",
						name = "Show Only if Missing",
						desc = "Show only when the buff or debuff is missing",
						descStyle = "inline",
						get = function()
							return self.db.profile[i].missingOnly
						end,
						set = function(_, value)
							self.db.profile[i].missingOnly = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 4,
					},
					-------------------------------------------------
					tooltipOptions = {
						type = "header",
						name = "Tooltips",
						order = 10,
					},
					showTooltip = {
						type = "toggle",
						name = "Show Tooltip",
						desc = "Show the tooltip on mouseover",
						get = function()
							return self.db.profile[i].showTooltip
						end,
						set = function(_, value)
							self.db.profile[i].showTooltip = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 11,
					},
					tooltipLocation = {
						type = "select",
						name = "Tooltip Location",
						desc = "The specified location where the tooltip should appear",
						style = "dropdown",
						values = {["ANCHOR_CURSOR"] = "Attached to Cursor", ["ANCHOR_PRESERVE"] = "Blizzard Default"},
						sorting = {[1] = "ANCHOR_CURSOR", [2] = "ANCHOR_PRESERVE"},
						get = function()
							return self.db.profile[i].tooltipLocation
						end,
						set = function(_, value)
							self.db.profile[i].tooltipLocation = value
							self:RefreshConfig()
						end,
						disabled = function() return not self.db.profile[i].showTooltip end,
						width = THIRD_WIDTH,
						order = 12,
					},
				},
			},
			-------------------------------------------------
			iconOptions = {
				type = "group",
				name = "Icon and Visuals",
				order = 4,
				args = {
					-------------------------------------------------
					generalHeader = {
						type = "header",
						name = "General",
						order = 1,
					},
					indicatorSize = {
						type = "range",
						name = "Indicator Size",
						desc = "The size of the indicator in pixels",
						min = 1,
						max = 30,
						step = 1,
						get = function()
							return self.db.profile[i].indicatorSize
						end,
						set = function(_, value)
							self.db.profile[i].indicatorSize = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 2,
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
						order = 3,
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
						order = 4,
					},
					-------------------------------------------------
					iconHeader = {
						type = "header",
						name = "Icon",
						order = 10,
					},
					showIcon = {
						type = "toggle",
						name = "Show Icon",
						desc = "Show an icon if the buff or debuff is currently on the unit".."\n"..
								"(if unchecked, a solid indicator color will be used)",
						get = function()
							return self.db.profile[i].showIcon
						end,
						set = function(_, value)
							self.db.profile[i].showIcon = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 11,
					},
					indicatorAlpha = {
						type = "range",
						name = "Icon Opacity",
						desc = "The opacity percentage of the indicator icon",
						min = 0,
						max = 1,
						step = 0.05,
						get = function()
							return self.db.profile[i].indicatorAlpha
						end,
						set = function(_, value)
							self.db.profile[i].indicatorAlpha = value
							self:RefreshConfig()
						end,
						disabled = function()
							return not self.db.profile[i].showIcon
						end,
						width = THIRD_WIDTH,
						order = 12,
					},
					-------------------------------------------------
					colorHeader = {
						type = "header",
						name = "Color",
						order = 20,
					},
					indicatorColor = {
						type = "color",
						name = "Indicator Color",
						desc = "The solid color used for the indicator when not showing the buff or debuff icon (unless augmented by other color options)",
						hasAlpha = true,
						get = function()
							return self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g, self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a
						end,
						set = function(_, r, g, b, a)
							self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g, self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a = r, g, b, a
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile[i].showIcon
						end,
						width = THIRD_WIDTH,
						order = 21,
					},
					colorIndicatorByDebuff = {
						type = "toggle",
						name = "Color By Debuff Type",
						desc = "Color the indicator depending on the debuff type".."\n"..
								"(this will override the normal coloring)".."\n"..
								"\n"..
								gsub(greenCode, "<text>", "Poison").."\n"..
								gsub(purpleCode, "<text>", "Curse").."\n"..
								gsub(brownCode, "<text>", "Disease").."\n"..
								gsub(blueCode, "<text>", "Magic").."\n",
						get = function()
							return self.db.profile[i].colorIndicatorByDebuff
						end,
						set = function(_, value)
							self.db.profile[i].colorIndicatorByDebuff = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile[i].showIcon
						end,
						width = THIRD_WIDTH,
						order = 22,
					},
					colorIndicatorByTime = {
						type = "toggle",
						name = "Color By Remaining Time",
						desc = "Color the indicator based on remaining time".."\n"..
								"(this will override the normal coloring)".."\n"..
								"\n"..
								gsub(redCode, "<text>", "Time #1").."\n"..
								gsub(yellowCode, "<text>", "Time #2"),
						get = function()
							return self.db.profile[i].colorIndicatorByTime
						end,
						set = function(_, value)
							self.db.profile[i].colorIndicatorByTime = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile[i].showIcon
						end,
						width = THIRD_WIDTH,
						order = 23,
					},
					colorIndicatorByTime_low = {
						type = "range",
						name = "Time #1",
						desc = "The time (in seconds) for the lower boundary".."\n"..
								"('0' means ignored)",
						min = 0,
						max = 10,
						step = 1,
						get = function()
							return self.db.profile[i].colorIndicatorByTime_low
						end,
						set = function(_, value)
							self.db.profile[i].colorIndicatorByTime_low = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile[i].showIcon or not self.db.profile[i].colorIndicatorByTime
						end,
						width = THIRD_WIDTH,
						order = 24,
					},
					colorIndicatorByTime_high = {
						type = "range",
						name = "Time #2",
						desc = "The time (in seconds) for the upper boundary".."\n"..
								"('0' means ignored)",
						min = 0,
						max = 10,
						step = 1,
						get = function()
							return self.db.profile[i].colorIndicatorByTime_high
						end,
						set = function(_, value)
							self.db.profile[i].colorIndicatorByTime_high = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile[i].showIcon or not self.db.profile[i].colorIndicatorByTime
						end,
						width = THIRD_WIDTH,
						order = 25,
					},
				},
			},
			--------------------------------------------
			textOptions = {
				type = "group",
				name = "Text",
				order = 5,
				args = {
					-------------------------------------------------
					generalHeader = {
						type = "header",
						name = "General",
						order = 1,
					},
					showText = {
						type = "select",
						name = "Show Text",
						desc = "The text to show on the indicator frame",
						style = "dropdown",
						values = {["stack"] = "Stack Size", ["countdown"] = "Countdown", ["stack+countdown"] = "Stack Size + Countdown", ["none"] = "None"},
						sorting = {[1] = "stack", [2] = "countdown", [3] = "stack+countdown", [4] = "none"},
						get = function()
							return self.db.profile[i].showText
						end,
						set = function(_, value)
							self.db.profile[i].showText = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 2,
					},
					textSize = {
						type = "range",
						name = "Text Size",
						desc = "The size of the indicator (in pixels)",
						min = 1,
						max = 30,
						step = 1,
						get = function()
							return self.db.profile[i].textSize
						end,
						set = function(_, value)
							self.db.profile[i].textSize = value
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 3,
					},
					-------------------------------------------------
					colorHeader = {
						type = "header",
						name = "Color",
						order = 10,
					},
					textColor = {
						type = "color",
						name = "Text Color",
						desc = "The color used for the indicator text".."\n"..
						"(unless augmented by other text color options)",
						hasAlpha = true,
						get = function()
							return self.db.profile[i].textColor.r, self.db.profile[i].textColor.g, self.db.profile[i].textColor.b, self.db.profile[i].textColor.a
						end,
						set = function(_, r, g, b, a)
							self.db.profile[i].textColor.r, self.db.profile[i].textColor.g, self.db.profile[i].textColor.b, self.db.profile[i].textColor.a = r, g, b, a
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 11,
					},
					colorTextByDebuff = {
						type = "toggle",
						name = "Color By Debuff Type",
						desc = "Color the indicator text depending on the debuff type".."\n"..
								"(this will override the normal coloring)".."\n"..
								"\n"..
								gsub(greenCode, "<text>", "Poison").."\n"..
								gsub(purpleCode, "<text>", "Curse").."\n"..
								gsub(brownCode, "<text>", "Disease").."\n"..
								gsub(blueCode, "<text>", "Magic").."\n",
						get = function()
							return self.db.profile[i].colorTextByDebuff
						end,
						set = function(_, value)
							self.db.profile[i].colorTextByDebuff = value
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 12,
					},
					colorTextByTime = {
						type = "toggle",
						name = "Color By Remaining Time",
						desc = "Color the indicator text based on remaining time".."\n"..
								"(this will override the normal coloring)".."\n"..
								"\n"..
								gsub(redCode, "<text>", "Time #1").."\n"..
								gsub(yellowCode, "<text>", "Time #2"),
						get = function()
							return self.db.profile[i].colorTextByTime
						end,
						set = function(_, value)
							self.db.profile[i].colorTextByTime = value
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 13,
					},
					colorTextByTime_low = {
						type = "range",
						name = "Time #1",
						desc = "The time (in seconds) for the lower boundary".."\n"..
								"('0' means ignored)",
						min = 0,
						max = 10,
						step = 1,
						get = function()
							return self.db.profile[i].colorTextByTime_low
						end,
						set = function(_, value)
							self.db.profile[i].colorTextByTime_low = value
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" or not self.db.profile[i].colorTextByTime then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 14,
					},
					colorTextByTime_high = {
						type = "range",
						name = "Time #2",
						desc = "The time (in seconds) for the upper boundary".."\n"..
								"('0' means ignored)",
						min = 0,
						max = 10,
						step = 1,
						get = function()
							return self.db.profile[i].colorTextByTime_high
						end,
						set = function(_, value)
							self.db.profile[i].colorTextByTime_high = value
							self:RefreshConfig()
						end,
						disabled = function()
							if self.db.profile[i].showText == "none" or not self.db.profile[i].colorTextByTime then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 15,
					},
				},
			},
			--------------------------------------------
			animationOptions = {
				type = "group",
				name = "Animations",
				order = 6,
				args = {
					-------------------------------------------------
					generalOptions = {
						type = "header",
						name = "General",
						order = 1,
					},
					showCountdownSwipe = {
						type = "toggle",
						name = "Show Countdown Swipe",
						desc = "Show the clockwise swipe animation specifying the time left on the buff or debuff",
						get = function()
							return self.db.profile[i].showCountdownSwipe
						end,
						set = function(_, value)
							self.db.profile[i].showCountdownSwipe = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 2,
					},
					indicatorGlow = {
						type = "toggle",
						name = "Indicator Glow Effect",
						desc = "Display a glow animation effect on the indicator to make it easier to spot",
						get = function()
							return self.db.profile[i].indicatorGlow
						end,
						set = function(_, value)
							self.db.profile[i].indicatorGlow = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 3,
					},
					glowRemainingSecs = {
						type = "range",
						name = "Glow At Countdown Time",
						desc = "The amount of time (in seconds) remaining on the buff or debuff countdown before the glowing starts".."\n"..
								"('0' means it will always glow)",
						min = 0,
						max = 10,
						step = 1,
						get = function()
							return self.db.profile[i].glowRemainingSecs
						end,
						set = function(_, value)
							self.db.profile[i].glowRemainingSecs = value
							self:RefreshConfig()
						end,
						disabled = function()
							return not self.db.profile[i].indicatorGlow
						end,
						width = THIRD_WIDTH,
						order = 4,
					},
				},
			},
		}
	end

	return indicatorOptions
end