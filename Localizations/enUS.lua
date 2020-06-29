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

L["Indicator Options"] = true
L["Icon Options"] = true
L["Profiles"] = true

L["Vertical Offset"] = true
L["verticalOffset_desc"] = "Vertical offset percentage relative to the starting position"

L["Horizontal Offset"] = true
L["horizontalOffset_desc"] = "Horizontal offset percentage relative to the starting position"

L["Example"] = true
L["Wildcards"] = true

----------------------------------------------------
------------------- General Panel ------------------
----------------------------------------------------

L["generalOptions_desc"] = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, raid icons, and more"

L["Open the Blizzard Raid Profiles Menu"] = true
L["blizzardRaidOptionsButton_desc"] = "Launch the built-in raid profiles interface configuration menu"

L["Default Icon Visibility"] = true

L["Stock Buff Icons"] = true
L["showBuffs_desc"] = "Show the standard raid frame buff icons"

L["Stock Debuff Icons"] = true
L["showDebuffs_desc"] = "Show the standard raid frame debuff icons"

L["Stock Dispellable Icons"] = true
L["showDispellableDebuffs_desc"] = "Show the standard raid frame dispellable icons"

L["Indicator Font"] = true
L["indicatorFont_desc"] = "The the font used for the indicators"

L["Raidframe Scale"] = true
L["frameScale_desc"] = "The the scale of the raidframe from 50% to 200% of the normal size"

L["Background Opacity"] = true
L["backgroundAlpha_desc"] = "The opacity percentage of the raid frame background"

L["Out-of-Range"] = true

L["Override Default Distance"] = true
L["customRange_desc"] = "Overrides the default out-of-range indicator distance (default 40 yards)"

L["Select a Custom Distance"] = true
L["customRangeCheck_desc"] = "Changes the default 40 yard out-of-range distance to the specified distance"

L["Out-of-Range Opacity"] = true
L["rangeAlpha_desc"] = "The opacity percentage of the raid frame when out-of-range"


----------------------------------------------------
--------------------- Icon Panel -------------------
----------------------------------------------------

L["generalOptions_desc"] = "Configure how the raid marker icon should appear on the raid frames"

L["Show Raid Icons"] = true
L["showRaidIcons_desc"] = "Show the raid marker icon on the raid frames"

L["Icon Size"] = true
L["iconSize_desc"] = "The size of the raid icon in pixels"

L["Icon Opacity"] = true
L["iconAlpha_desc"] = "The opacity percentage of the raid icon"

L["Position"] = true

L["Icon Position"] = true
L["iconPosition_desc"] = "Position of the raid icon relative to the frame"


----------------------------------------------------
------------------ Indicator Panel -----------------
----------------------------------------------------

L["indicatorOptions_desc"] = "Please select an indicator position from the dropdown menu below"

L["instructions_desc1"] = "The box to the right contains the list of auras to watch at the selected position"
L["instructions_desc2"] = "Type the names or spell IDs of each aura to track, each on a separate line"

L["Aura Watch List"] = true
L["auras_desc"] = "The list of buffs, debuffs, and/or wildcards to watch in this position"
L["auras_usage"] = "Any valid aura name or spell ID found in the game, spelled correctly, should work"

L["poison_desc"] = "any poison debuffs"
L["curse_desc"] = "any curse debuffs"
L["disease_desc"] = "any disease debuffs"
L["magic_desc"] = "any magic debuffs"
L["pvp_desc"] = "if the unit is PvP flagged"
L["tot_desc"] = "if the unit is the target of target"

L["Visibility and Behavior"] = true

L["Mine Only"] = true
L["mineOnly_desc"] = "Only show buffs and debuffs cast by me"

L["Show On Me Only"] = true
L["meOnly_desc"] = "Only only show this indicator on myself"

L["Show Only if Missing"] = true
L["missingOnly_desc"] = "Show only when the buff or debuff is missing"

L["Tooltips"] = true

L["Show Tooltip"] = true
L["showTooltip_desc"] = "Show the tooltip on mouseover"

L["Tooltip Location"] = true
L["tooltipLocation_desc"] = "The specified location where the tooltip should appear"
L["Attached to Cursor"] = true
L["Blizzard Default"] = true