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

local L = LibStub("AceLocale-3.0"):NewLocale("EnhancedRaidFrames", "enUS", true)

if not L then return end

----------------------------------------------------
---------------------- Common ----------------------
----------------------------------------------------
L["Enhanced Raid Frames"] = true

L["General"] = true
L["Position"] = true

L["Indicator Options"] = true
L["Icon Options"] = true
L["Profiles"] = true

L["Vertical Offset"] = true
L["verticalOffset_desc"] = "Vertical offset percentage relative to the starting position"

L["Horizontal Offset"] = true
L["horizontalOffset_desc"] = "Horizontal offset percentage relative to the starting position"

----------------------------------------------------
------------------- General Panel ------------------
----------------------------------------------------

L["generalOptions_desc"] = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, raid icons, and more"

L["blizzardRaidOptionsButton_name"] = "Open the Blizzard Raid Profiles Menu"
L["blizzardRaidOptionsButton_desc"] = "Launch the built-in raid profiles interface configuration menu"

L["Default Icon Visibility"] = true

L["showBuffs_name"] = "Stock Buff Icons"
L["showBuffs_desc"] = "Show the standard raid frame buff icons"

L["showDebuffs_name"] = "Stock Debuff Icons"
L["showDebuffs_desc"] = "Show the standard raid frame debuff icons"

L["showDispellableDebuffs_name"] = "Stock Dispellable Icons"
L["showDispellableDebuffs_desc"] = "Show the standard raid frame dispellable icons"

L["indicatorFont_name"] = "Indicator Font"
L["indicatorFont_desc"] = "The the font used for the indicators"

L["frameScale_name"] = "Raidframe Scale"
L["frameScale_desc"] = "The the scale of the raidframe from 50% to 200% of the normal size"

L["backgroundAlpha_name"] = "Background Opacity"
L["backgroundAlpha_desc"] = "The opacity percentage of the raid frame background"

L["Out-of-Range"] = true

L["customRange_name"] = "Override Default Distance"
L["customRange_desc"] = "Overrides the default out-of-range indicator distance (default 40 yards)"

L["customRangeCheck_name"] = "Select a Custom Distance"
L["customRangeCheck_desc"] = "Changes the default 40 yard out-of-range distance to the specified distance"

L["rangeAlpha_name"] = "Out-of-Range Opacity"
L["rangeAlpha_desc"] = "The opacity percentage of the raid frame when out-of-range"


----------------------------------------------------
--------------------- Icon Panel -------------------
----------------------------------------------------

L["generalOptions_desc"] = "Configure how the raid marker icon should appear on the raid frames"

L["showRaidIcons_name"] = "Show Raid Icons"
L["showRaidIcons_desc"] = "Show the raid marker icon on the raid frames"

L["iconSize_name"] = "Icon Size"
L["iconSize_desc"] = "The size of the raid icon in pixels"

L["iconAlpha_name"] = "Icon Opacity"
L["iconAlpha_desc"] = "The opacity percentage of the raid icon"

L["iconPosition_name"] = "Icon Position"
L["iconPosition_desc"] = "Position of the raid icon relative to the frame"


