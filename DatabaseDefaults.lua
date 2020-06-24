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
		indicatorFont = "Arial Narrow",

		showBuffs = true,
		showDebuffs = true,
		showDispelDebuffs = true,

		frameScale = 1,
		rangeAlpha = 0.55,
		backgroundAlpha = 1,
		customRange = 30,

		showRaidIcons = true,
		iconSize = 20,
		iconPosition = 5,
		iconVerticalOffset = 0,
		iconHorizontalOffset = 0,
		iconAlpha = 1,
	}

	for i = 1, 9 do
		defaults.profile["auras"..i] = ""

		defaults.profile["mine"..i] = false
		defaults.profile["me"..i] = false
		defaults.profile["missing"..i] = false
		defaults.profile["showTooltip"..i] = true
		defaults.profile["tooltipLocation"..i] = "ANCHOR_CURSOR"

		defaults.profile["showIcon"..i] = true
		defaults.profile["indicatorColor"..i] = {r = 1, g = 1, b = 1, a = 1}
		defaults.profile["colorIndicatorByTime"..i] = false
		defaults.profile["colorIndicatorByDebuff"..i] = false
		defaults.profile["indicatorSize"..i] = 18
		defaults.profile["indicatorHorizontalOffset"..i] = 0
		defaults.profile["indicatorVerticalOffset"..i] = 0

		defaults.profile["showText"..i] = false
		defaults.profile["showStack"..i] = false
		defaults.profile["textColor"..i] = {r = 1, g = 1, b = 1, a = 1}
		defaults.profile["colorTextByStack"..i] = false
		defaults.profile["colorTextByTime"..i] = false
		defaults.profile["colorTextByDebuff"..i] = false
		defaults.profile["textSize"..i] = 14

		defaults.profile["showCountdownSwipe"..i] = true
		defaults.profile["indicatorGlow"..i] = false
		defaults.profile["glowRemainingSecs"..i] = 3
	end

	return defaults
end