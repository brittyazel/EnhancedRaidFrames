-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

EnhancedRaidFrames.DATABASE_VERSION = 2

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Create a table containing our default database values
function EnhancedRaidFrames:CreateDefaults()
	local defaults = {}

	defaults.profile = {
		---Main Settings
		--Default Icon Visibility
		showBuffs = true,
		showDebuffs = true,
		showDispellableDebuffs = true,

		--Visual Options
		powerBarOffset = true,
		frameScale = 1,
		backgroundAlpha = 1,
		indicatorFont = "Arial Narrow",

		--Out-of-Range Options
		customRangeCheck = false,
		customRange = 30,
		rangeAlpha = 0.55,

		---Target Markers Settings
		--General Options
		showTargetMarkers = true,
		markerPosition = 5,

		--Visual Options
		markerSize = 20,
		markerAlpha = 1,

		--Position Options
		markerVerticalOffset = 0,
		markerHorizontalOffset = 0,
	}

	---Indicator Options Settings
	for i = 1, 9 do
		defaults.profile[i] = {
			--Aura Strings
			auras = "",

			--Visibility and Behavior
			mineOnly= false,
			meOnly = false,
			missingOnly = false,
			showTooltip = true,
			tooltipLocation = "ANCHOR_CURSOR",

			--Icon and Color
			indicatorSize = 18,
			indicatorHorizontalOffset = 0,
			indicatorVerticalOffset = 0,
			showIcon = true,
			indicatorAlpha = 1,
			indicatorColor = {r = 0, g = 1, b = 0.59, a = 1},
			colorIndicatorByDebuff = false,
			colorIndicatorByTime = false,
			colorIndicatorByTime_low = 2,
			colorIndicatorByTime_high = 5,

			--Text and Color
			showCountdownText = false,
			showStackSize = true,
			textColor = {r = 1, g = 1, b = 1, a = 1},
			colorTextByTime = false,
			colorTextByTime_low = 2,
			colorTextByTime_high = 5,
			colorTextByDebuff = false,
			textSize = 14,
			textAlpha = 1,

			--Animations and Effects
			showCountdownSwipe = true,
			indicatorGlow = false,
			glowRemainingSecs = 3,
		}
	end

	return defaults
end