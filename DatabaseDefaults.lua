-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Latest Database Version (<major>.<minor>)
EnhancedRaidFrames.DATABASE_VERSION = 2.2

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Create a table containing our default database values
function EnhancedRaidFrames:CreateDefaults()
	local defaults = {}

	defaults.profile = {
		--------------------------------
		------- General Settings -------
		--------------------------------
		-- Default Icon Visibility
		showBuffs = true,
		showDebuffs = true,
		showDispellableDebuffs = true,

		-- Visual Options
		powerBarOffset = true,
		frameScale = 1,
		backgroundAlpha = 1,
		indicatorFont = "Arial Narrow",

		-- Out-of-Range Options
		customRangeCheck = false,
		customRange = 30,
		rangeAlpha = 0.55,

		--------------------------------
		---- Target Marker Settings ----
		--------------------------------
		-- General Options
		showTargetMarkers = true,
		markerPosition = 5,

		-- Visual Options
		markerSize = 20,
		markerAlpha = 1,

		-- Position Options
		markerVerticalOffset = 0,
		markerHorizontalOffset = 0,
	}

	-----------------------------------
	---- Indicator Option Settings ----
	-----------------------------------
	for i = 1, 9 do
		defaults.profile["indicator-" .. i] = {
			-- Aura Strings
			auras = "",

			-- Visibility and Behavior
			mineOnly = false,
			meOnly = false,
			missingOnly = false,
			showTooltip = true,
			tooltipLocation = "ANCHOR_CURSOR",

			-- Icon and Color
			indicatorSize = 18,
			indicatorHorizontalOffset = 0,
			indicatorVerticalOffset = 0,
			showIcon = true,
			indicatorAlpha = 1,
			indicatorColor = { 0, 1, 0.59, 1 },
			colorIndicatorByDebuff = false,
			colorIndicatorByTime = false,
			colorIndicatorByTime_low = 2,
			colorIndicatorByTime_high = 5,

			-- Text and Color
			showCountdownText = false,
			showStackSize = true,
			stackSizeLocation = "BOTTOMRIGHT",
			textColor = { 1, 1, 1, 1 },
			colorTextByTime = false,
			colorTextByTime_low = 2,
			colorTextByTime_high = 5,
			colorTextByDebuff = false,
			textSize = 14,
			textAlpha = 1,

			-- Animations and Effects
			showCountdownSwipe = true,
			indicatorGlow = false,
			glowRemainingSecs = 3,
		}
	end

	return defaults
end