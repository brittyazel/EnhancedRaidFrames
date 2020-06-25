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

local _, addonTable = ... --make use of the default addon namespace
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Create our database defaults table
function EnhancedRaidFrames:CreateDefaults()
	local defaults = {}

	defaults.profile = {
		showBuffs = true,
		showDebuffs = true,
		showDispelDebuffs = true,

		indicatorFont = "Arial Narrow",
		frameScale = 1,
		backgroundAlpha = 1,

		customRangeCheck = false,
		customRange = 30,
		rangeAlpha = 0.55,

		showRaidIcons = true,
		iconPosition = 5,
		iconSize = 20,
		iconVerticalOffset = 0,
		iconHorizontalOffset = 0,
		iconAlpha = 1,
	}

	for i = 1, 9 do
		defaults.profile[i] = {
			auras = "",

			mineOnly= false,
			meOnly = false,
			missingOnly = false,

			showTooltip = true,
			tooltipLocation = "ANCHOR_CURSOR",

			showIcon = true,
			indicatorColor = {r = 1, g = 1, b = 1, a = 1},
			colorIndicatorByTime = false,
			colorIndicatorByDebuff = false,
			indicatorSize = 18,
			indicatorHorizontalOffset = 0,
			indicatorVerticalOffset = 0,

			showText = false,
			showStack = false,
			textColor = {r = 1, g = 1, b = 1, a = 1},
			colorTextByStack = false,
			colorTextByTime = false,
			colorTextByDebuff = false,
			textSize = 14,

			showCountdownSwipe = true,
			indicatorGlow = false,
			glowRemainingSecs = 3,
		}
	end

	return defaults
end