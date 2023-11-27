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

--- Populate our "Indicator" options table for our Blizzard interface options
function EnhancedRaidFrames:CreateIndicatorOptions()
	local THIRD_WIDTH = 1.14

	local indicatorOptions = {
		type = "group",
		childGroups = "select",
		name = L["Indicator Options"],
		args  = {
			instructions = {
				type = "description",
				name = L["indicatorOptions_desc"]..":",
				fontSize = "medium",
				order = 1,
			},
		}
	}

	--- Add options for each indicator
	for i,v in ipairs(self.POSITIONS) do
		indicatorOptions.args[v] = {}
		indicatorOptions.args[v].type = "group"
		indicatorOptions.args[v].childGroups = "tab"
		indicatorOptions.args[v].name = i..": "..v
		indicatorOptions.args[v].order = i+1
		indicatorOptions.args[v].args = {
			--------------------------------------------
			instructions = {
				type = "description",
				name = self.NORMAL_COLOR:WrapTextInColorCode(v).."\n"..
						"\n"..
						L["instructions_desc1"]..".".."\n"..
						"\n"..
						L["auras_usage"]..".".."\n",
				fontSize = "medium",
				width = THIRD_WIDTH * 1.2,
				order = 1,
			},
			auras = {
				type = "input",
				name = L["Aura Watch List"],
				desc = L["auras_desc"],
				usage =L["auras_usage"]..".\n"..
						L["Example"]..":\n"..
						"\n"..
						self.WHITE_COLOR:WrapTextInColorCode("Rejuvenation").."\n"..
						self.WHITE_COLOR:WrapTextInColorCode("Curse").."\n"..
						self.WHITE_COLOR:WrapTextInColorCode("155777").."\n"..
						self.WHITE_COLOR:WrapTextInColorCode("Magic").."\n"..
						"\n"..
						L["Wildcards"]..":\n"..
						self.GREEN_COLOR:WrapTextInColorCode("Poison")..self.WHITE_COLOR:WrapTextInColorCode(": "..L["poisonWildcard_desc"]).."\n"..
						self.PURPLE_COLOR:WrapTextInColorCode("Curse")..self.WHITE_COLOR:WrapTextInColorCode(": "..L["curseWildcard_desc"]).."\n"..
						self.BROWN_COLOR:WrapTextInColorCode("Disease")..self.WHITE_COLOR:WrapTextInColorCode(": "..L["diseaseWildcard_desc"]).."\n"..
						self.BLUE_COLOR:WrapTextInColorCode("Magic")..self.WHITE_COLOR:WrapTextInColorCode(": "..L["magicWildcard_desc"]).."\n",
				multiline = 7,
				get = function() return self.db.profile[i].auras end,
				set = function(_, value)
					self.db.profile[i].auras = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH * 1.75,
				order = 2,
			},
			--------------------------------------------
			visibilityOptions = {
				type = "group",
				name = L["Visibility and Behavior"],
				order = 3,
				args = {
					generalOptions = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					mineOnly = {
						type = "toggle",
						name = L["Mine Only"],
						desc = L["mineOnly_desc"],
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
						name = L["Show On Me Only"],
						desc = L["meOnly_desc"],
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
						name = L["Show Only if Missing"],
						desc = L["missingOnly_desc"],
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
						name = L["Tooltips"],
						order = 10,
					},
					showTooltip = {
						type = "toggle",
						name = L["Show Tooltip"],
						desc = L["showTooltip_desc"],
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
						name = L["Tooltip Location"],
						desc = L["tooltipLocation_desc"],
						style = "dropdown",
						values = {["ANCHOR_CURSOR"] = L["Attached to Cursor"], ["ANCHOR_PRESERVE"] = L["Blizzard Default"]},
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
				name = L["Icon and Visuals"],
				order = 4,
				args = {
					-------------------------------------------------
					generalHeader = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					indicatorSize = {
						type = "range",
						name = L["Indicator Size"],
						desc = L["indicatorSize_desc"],
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
						name = L["Vertical Offset"],
						desc = L["verticalOffset_desc"],
						isPercent = true,
						min = -1,
						max = 1,
						step = .01,
						get = function() return self.db.profile[i].indicatorVerticalOffset end,
						set = function(_, value)
							self.db.profile[i].indicatorVerticalOffset = value
							self:RefreshConfig()
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 3,
					},
					indicatorHorizontalOffset = {
						type = "range",
						name = L["Horizontal Offset"],
						desc = L["horizontalOffset_desc"],
						isPercent = true,
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
						name = L["Icon"],
						order = 10,
					},
					showIcon = {
						type = "toggle",
						name = L["Show Icon"],
						desc = L["showIcon_desc1"].."\n"..
								"("..L["showIcon_desc2"]..")",
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
						name = L["Icon Opacity"],
						desc = L["indicatorAlpha_desc"],
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
						name = L["Color"],
						order = 20,
					},
					indicatorColor = {
						type = "color",
						name = L["Indicator Color"],
						desc = L["indicatorColor_desc1"].."\n"..
								"("..L["indicatorColor_desc2"]..")",
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
						name = L["Color By Debuff Type"],
						desc = L["colorByDebuff_desc"].."\n"..
								"("..L["colorOverride_desc"]..")".."\n"..
								"\n"..
								self.GREEN_COLOR:WrapTextInColorCode(L["Poison"]).."\n"..
								self.PURPLE_COLOR:WrapTextInColorCode(L["Curse"]).."\n"..
								self.BROWN_COLOR:WrapTextInColorCode(L["Disease"]).."\n"..
								self.BLUE_COLOR:WrapTextInColorCode(L["Magic"]).."\n",
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
						name = L["Color By Remaining Time"],
						desc = L["colorByTime_desc"].."\n"..
								"("..L["colorOverride_desc"]..")".."\n"..
								"\n"..
								self.RED_COLOR:WrapTextInColorCode(L["Time #1"]).."\n"..
								self.YELLOW_COLOR:WrapTextInColorCode(L["Time #2"]),
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
						name = L["Time #1"],
						desc = L["colorByTime_low_desc"].."\n"..
								"("..L["zeroMeansIgnored_desc"]..")",
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
						name = L["Time #2"],
						desc = L["colorByTime_high_desc"].."\n"..
								"("..L["zeroMeansIgnored_desc"]..")",
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
				name = L["Text"],
				order = 5,
				args = {
					-------------------------------------------------
					generalHeader = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					showText = {
						type = "select",
						name = L["Show Text"],
						desc = L["showText_desc"],
						style = "dropdown",
						values = {["stack"] = L["Stack Size"], ["countdown"] = L["Countdown"],
								  ["stack+countdown"] = L["Stack Size"].." + "..L["Countdown"], ["none"] = L["None"]},
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
						name = L["Text Size"],
						desc = L["textSize_desc"],
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
						name = L["Color"],
						order = 10,
					},
					textColor = {
						type = "color",
						name = L["Text Color"],
						desc = L["textColor_desc1"].."\n"..
								"("..L["textColor_desc2"]..")",
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
						name = L["Color By Debuff Type"],
						desc = L["colorByDebuff_desc"].."\n"..
								"("..L["colorOverride_desc"]..")".."\n"..
								"\n"..
								self.GREEN_COLOR:WrapTextInColorCode(L["Poison"]).."\n"..
								self.PURPLE_COLOR:WrapTextInColorCode(L["Curse"]).."\n"..
								self.BROWN_COLOR:WrapTextInColorCode(L["Disease"]).."\n"..
								self.BLUE_COLOR:WrapTextInColorCode(L["Magic"]).."\n",
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
						name = L["Color By Remaining Time"],
						desc = L["colorByTime_desc"].."\n"..
								"("..L["colorOverride_desc"]..")".."\n"..
								"\n"..
								self.RED_COLOR:WrapTextInColorCode(L["Time #1"]).."\n"..
								self.YELLOW_COLOR:WrapTextInColorCode(L["Time #2"]),
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
						name = L["Time #1"],
						desc = L["colorByTime_low_desc"].."\n"..
								"("..L["zeroMeansIgnored_desc"]..")",
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
						name = L["Time #2"],
						desc = L["colorByTime_high_desc"].."\n"..
								"("..L["zeroMeansIgnored_desc"]..")",
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
				name = L["Animations"],
				order = 6,
				args = {
					-------------------------------------------------
					generalOptions = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					showCountdownSwipe = {
						type = "toggle",
						name = L["Show Countdown Swipe"],
						desc = L["showCountdownSwipe_desc"],
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
						name = L["Indicator Glow Effect"],
						desc = L["indicatorGlow_desc"],
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
						name = L["Glow At Countdown Time"],
						desc = L["glowRemainingSecs_desc1"].."\n"..
								"("..L["glowRemainingSecs_desc2"]..")",
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
