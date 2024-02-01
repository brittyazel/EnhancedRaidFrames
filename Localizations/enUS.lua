-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local L = LibStub("AceLocale-3.0"):NewLocale("EnhancedRaidFrames", "enUS", true)

if not L then
	return
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

L["General"] = true

L["General Options"] = true
L["Indicator Options"] = true
L["Target Marker Options"] = true
L["Profiles"] = true

L["Vertical Offset"] = true
L["verticalOffset_desc"] = "The vertical offset percentage relative to the starting position and the width of the frame"

L["Horizontal Offset"] = true
L["horizontalOffset_desc"] = "The horizontal offset percentage relative to the starting position and the height of the frame"

L["Example"] = true
L["Wildcards"] = true
L["Color"] = true

L["Color By Debuff Type"] = true
L["colorByDebuff_desc"] = "Color is determined by the type of debuff"

L["Color By Remaining Time"] = true
L["colorByTime_desc"] = "Color is determined based on the remaining time"

L["colorOverride_desc"] = "this will override the normal coloring"
L["zeroMeansIgnored_desc"] = "A value of '0' means this setting is ignored"

L["Time #1"] = true
L["colorByTime_low_desc"] = "The time (in seconds) for the lower boundary"

L["Time #2"] = true
L["colorByTime_high_desc"] = "The time (in seconds) for the upper boundary"

L["Poison"] = true
L["Curse"] = true
L["Disease"] = true
L["Magic"] = true

L["Top-Left"] = true
L["Top"] = true
L["Top-Right"] = true
L["Left"] = true
L["Center"] = true
L["Right"] = true
L["Bottom-Left"] = true
L["Bottom"] = true
L["Bottom-Right"] = true

L["Melee"] = true
L["10 yards"] = true
L["15 yards"] = true
L["20 yards"] = true
L["25 yards"] = true
L["30 yards"] = true
L["35 yards"] = true
L["40 yards"] = true

----------------------------------------------------
------------------- General Panel ------------------
----------------------------------------------------

L["generalOptions_desc"] = "Below you will find general configuration options. Please expand the 'Enhanced Raid Frames' menu item in the left-hand column to configure aura indicators, target markers, and more"

L["Open the Blizzard Raid Profiles Options"] = true
L["blizzardRaidOptionsButton_desc"] = "Launch the built-in raid profiles interface configuration menu"

L["Default Icon Visibility"] = true

L["Stock Buff Icons"] = true
L["showBuffs_desc"] = "Show the standard raid frame buff icons"

L["Stock Debuff Icons"] = true
L["showDebuffs_desc"] = "Show the standard raid frame debuff icons"

L["Stock Dispellable Icons"] = true
L["showDispellableDebuffs_desc"] = "Show the standard raid frame dispellable icons"

L["Power Bar Vertical Offset"] = true
L["powerBarOffset_desc"] = "Apply a vertical offset to icons and indicators to keep them from overlapping the power bar (mana/rage/energy)"

L["Raidframe Scale"] = true
L["frameScale_desc"] = "The the scale of the raidframe relative to the normal size"

L["Background Opacity"] = true
L["backgroundAlpha_desc"] = "The opacity percentage of the raid frame background"

L["Indicator Font"] = true
L["indicatorFont_desc"] = "The the font used for the indicators"

L["Mouseover Cast Compatibility"] = true
L["mouseoverCast_desc"] = "Enable compatibility with mouseover casting functionality. Consequently, this option will disable tooltips when hovering over indicators."

L["Out-of-Range"] = true

L["Override Default Distance"] = true
L["customRange_desc"] = "Overrides the default out-of-range indicator distance (default 40 yards)"

L["Select a Custom Distance"] = true
L["customRangeCheck_desc"] = "Changes the default 40 yard out-of-range distance to the specified distance"

L["Out-of-Range Opacity"] = true
L["rangeAlpha_desc"] = "The opacity percentage of the raid frame when out-of-range"

----------------------------------------------------
---------------- Target Marker Panel ---------------
----------------------------------------------------

L["markerOptions_desc"] = "Configure how the target marker icon should appear on the raid frames"

L["Show Target Markers"] = true
L["showTargetMarkers_desc"] = "Show the target marker icon on the raid frames"

L["Target Marker Size"] = true
L["markerSize_desc"] = "The size of the target marker in pixels"

L["Target Marker Opacity"] = true
L["markerAlpha_desc"] = "The opacity percentage of the target marker"

L["Position"] = true

L["Marker Position"] = true
L["markerPosition_desc"] = "Position of the target marker relative to the frame"

----------------------------------------------------
------------------ Indicator Panel -----------------
----------------------------------------------------

L["indicatorOptions_desc"] = "Please select an indicator position from the dropdown menu below"

L["instructions_desc1"] = "The box to the right contains the list of auras to watch at the selected position"

L["Aura Watch List"] = true
L["auras_desc"] = "The list of buffs, debuffs, and/or wildcards to watch in this position"
L["auras_usage"] = "Enter the names or spell IDs of each aura, each on a separate line"

L["dispelWildcard_desc"] = "any dispellable debuffs"
L["poisonWildcard_desc"] = "any poison debuffs"
L["curseWildcard_desc"] = "any curse debuffs"
L["diseaseWildcard_desc"] = "any disease debuffs"
L["magicWildcard_desc"] = "any magic debuffs"

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

L["Icon and Visuals"] = true

L["Indicator Size"] = true
L["indicatorSize_desc"] = "The size of the indicator in pixels"

L["Icon"] = true

L["Show Icon"] = true
L["showIcon_desc1"] = "Show an icon if the buff or debuff is currently on the unit"
L["showIcon_desc2"] = "if unchecked, a solid indicator color will be used"

L["Icon Opacity"] = true
L["indicatorAlpha_desc"] = "The opacity percentage of the indicator icon"

L["Indicator Color"] = true
L["indicatorColor_desc1"] = "The solid color used for the indicator when not showing the buff or debuff icon"
L["indicatorColor_desc2"] = "unless augmented by other color options"

L["Text"] = true

L["Show Countdown Text"] = true
L["showCountdownText_desc"] = "Display the time remaining on the buff or debuff"

L["Show Stack Size"] = true
L["showStackSize_desc"] = "Display the stack size of the buff or debuff"

L["Countdown Text Size"] = true
L["countdownTextSize_desc"] = "The size of the countdown text (in pixels)"

L["Stack Size Location"] = true
L["stackSizeLocation_desc"] = "The location of the stack size text within the indicator"

L["Text Color"] = true
L["textColor_desc1"] = "The color used for the countdown text"
L["textColor_desc2"] = "unless augmented by other text color options"

L["Animations"] = true

L["Show Countdown Swipe"] = true
L["showCountdownSwipe_desc"] = "Show the clockwise swipe animation indicating the time left on the buff or debuff"

L["Indicator Glow Effect"] = true
L["indicatorGlow_desc"] = "Display a glow animation effect on the indicator to make it easier to spot"

L["Glow At Countdown Time"] = true
L["glowRemainingSecs_desc1"] = "The amount of time (in seconds) remaining on the buff or debuff countdown before the glowing starts"
L["glowRemainingSecs_desc2"] = "A value of '0' means it will always glow"

----------------------------------------------------
-------------------- Utilities ---------------------
----------------------------------------------------

L["The database is being migrated to version:"] = true
L["Database migration successful."] = true

L["Profile"] = true
L["Import"] = true
L["Export"] = true
L["Import or Export the current profile:"] = true
L["ImportExport_Desc"] = [[

Below you will find a text representation of your Enhanced Raid Frame profile.

To export this profile, select and copy all of the text below and paste it somewhere safe.

To import a profile, replace all of the text below and press accept.

]]
L["ImportExport_WarningDesc"] = [[

Copying and pasting profile data can be a time consuming experience. It may stall your game for multiple seconds.

WARNING: This will overwrite the current profile, and any changes you have made will be lost.
]]
L["ImportWarning"] = "Are you absolutely certain you wish to import this profile? The current profile will be overwritten."
L["No data to import."] = true
L["Decoding failed."] = true
L["Decompression failed."] = true
L["Data import Failed."] = true
L["Aborting."] = true

L["Experimental"] = true
L["Experimental Options"] = true
L["Experimental_Options_Warning"] = [[

Warning:

Here you will fill find experimental and potentially dangerous options.

Use at your own risk.

]]