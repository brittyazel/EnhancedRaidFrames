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
				get = function() return self.db.profile["indicator-"..i].auras end,
				set = function(_, value)
					self.db.profile["indicator-"..i].auras = value
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
							return self.db.profile["indicator-"..i].mineOnly
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].mineOnly = value
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
							return self.db.profile["indicator-"..i].meOnly
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].meOnly = value
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
							return self.db.profile["indicator-"..i].missingOnly
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].missingOnly = value
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
							return self.db.profile["indicator-"..i].showTooltip
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].showTooltip = value
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
							return self.db.profile["indicator-"..i].tooltipLocation
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].tooltipLocation = value
							self:RefreshConfig()
						end,
						disabled = function() return not self.db.profile["indicator-"..i].showTooltip end,
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
							return self.db.profile["indicator-"..i].indicatorSize
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].indicatorSize = value
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
						get = function() return self.db.profile["indicator-"..i].indicatorVerticalOffset end,
						set = function(_, value)
							self.db.profile["indicator-"..i].indicatorVerticalOffset = value
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
						get = function() return self.db.profile["indicator-"..i].indicatorHorizontalOffset end,
						set = function(_, value)
							self.db.profile["indicator-"..i].indicatorHorizontalOffset = value
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
							return self.db.profile["indicator-"..i].showIcon
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].showIcon = value
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
							return self.db.profile["indicator-"..i].indicatorAlpha
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].indicatorAlpha = value
							self:RefreshConfig()
						end,
						disabled = function()
							return not self.db.profile["indicator-"..i].showIcon
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
							return unpack(self.db.profile["indicator-"..i].indicatorColor)
						end,
						set = function(_, r, g, b, a)
							self.db.profile["indicator-"..i].indicatorColor = {r, g, b, a}
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile["indicator-"..i].showIcon
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
							return self.db.profile["indicator-"..i].colorIndicatorByDebuff
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorIndicatorByDebuff = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile["indicator-"..i].showIcon
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
							return self.db.profile["indicator-"..i].colorIndicatorByTime
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorIndicatorByTime = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile["indicator-"..i].showIcon
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
							return self.db.profile["indicator-"..i].colorIndicatorByTime_low
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorIndicatorByTime_low = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile["indicator-"..i].showIcon or not self.db.profile["indicator-"..i].colorIndicatorByTime
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
							return self.db.profile["indicator-"..i].colorIndicatorByTime_high
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorIndicatorByTime_high = value
							self:RefreshConfig()
						end,
						disabled = function()
							return self.db.profile["indicator-"..i].showIcon or not self.db.profile["indicator-"..i].colorIndicatorByTime
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
					showCountdownText = {
						type = "toggle",
						name = L["Show Countdown Text"],
						desc = L["showCountdownText_desc"],
						get = function()
							return self.db.profile["indicator-"..i].showCountdownText
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].showCountdownText = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 2,
					},
					showStackSize = {
						type = "toggle",
						name = L["Show Stack Size"],
						desc = L["showStackSize_desc"],
						get = function()
							return self.db.profile["indicator-"..i].showStackSize
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].showStackSize = value
							self:RefreshConfig()
						end,
						width = THIRD_WIDTH,
						order = 3,
					},
					textSize = {
						type = "range",
						name = L["Countdown Text Size"],
						desc = L["countdownTextSize_desc"],
						min = 1,
						max = 30,
						step = 1,
						get = function()
							return self.db.profile["indicator-"..i].textSize
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].textSize = value
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText then
								return true
							end
						end,
						width = THIRD_WIDTH,
						order = 4,
					},
					stackSizeLocation = {
						type = "select",
						name = L["Stack Size Location"],
						desc = L["stackSizeLocation_desc"],
						style = "dropdown",
						values = {["TOPLEFT"] = L["Top-Left"], ["TOPRIGHT"] = L["Top-Right"], ["BOTTOMLEFT"] = L["Bottom-Left"], ["BOTTOMRIGHT"] = L["Bottom-Right"]},
						sorting = {[1] = "TOPLEFT", [2] = "TOPRIGHT", [3] = "BOTTOMLEFT", [4] = "BOTTOMRIGHT"},
						get = function()
							return self.db.profile["indicator-"..i].stackSizeLocation
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].stackSizeLocation = value
							self:RefreshConfig()
						end,
						disabled = function() return not self.db.profile["indicator-"..i].showStackSize end,
						width = THIRD_WIDTH,
						order = 5,
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
							return unpack(self.db.profile["indicator-"..i].textColor)
						end,
						set = function(_, r, g, b, a)
							self.db.profile["indicator-"..i].textColor = {r, g, b, a}
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText then
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
							return self.db.profile["indicator-"..i].colorTextByDebuff
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorTextByDebuff = value
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText then
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
							return self.db.profile["indicator-"..i].colorTextByTime
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorTextByTime = value
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText then
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
							return self.db.profile["indicator-"..i].colorTextByTime_low
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorTextByTime_low = value
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText or not self.db.profile["indicator-"..i].colorTextByTime then
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
							return self.db.profile["indicator-"..i].colorTextByTime_high
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].colorTextByTime_high = value
							self:RefreshConfig()
						end,
						disabled = function()
							if not self.db.profile["indicator-"..i].showCountdownText or not self.db.profile["indicator-"..i].colorTextByTime then
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
							return self.db.profile["indicator-"..i].showCountdownSwipe
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].showCountdownSwipe = value
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
							return self.db.profile["indicator-"..i].indicatorGlow
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].indicatorGlow = value
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
							return self.db.profile["indicator-"..i].glowRemainingSecs
						end,
						set = function(_, value)
							self.db.profile["indicator-"..i].glowRemainingSecs = value
							self:RefreshConfig()
						end,
						disabled = function()
							return not self.db.profile["indicator-"..i].indicatorGlow
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
