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

local _, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Create our database defaults table
function EnhancedRaidFrames:CreateDefaults()
	local defaults = {}

	defaults.profile = {
		---Main Settings
		--Default Icon Visibility
		showBuffs = true,
		showDebuffs = true,
		showDispellableDebuffs = true,

		--Visual Options
		indicatorFont = "Arial Narrow",
		frameScale = 1,
		backgroundAlpha = 1,

		--Out-of-Range Options
		customRangeCheck = false,
		customRange = 30,
		rangeAlpha = 0.55,

		---Raid Icon Settings
		--General Options
		showRaidIcons = true,
		iconPosition = 5,

		--Visual Options
		iconSize = 20,
		iconAlpha = 1,

		--Position Options
		iconVerticalOffset = 0,
		iconHorizontalOffset = 0,
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
			showText = "none",
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