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

local addonName, addonTable = ... --make use of the default addon namespace
addonTable.EnhancedRaidFrames = LibStub("AceAddon-3.0"):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0", "AceBucket-3.0")
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

EnhancedRaidFrames.allAuras = " "
EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then --boolean check to set a flag if the current session is WoW Classic. Retail == 1, Classic == 2
	EnhancedRaidFrames.isWoWClassic = true
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function EnhancedRaidFrames:OnInitialize()
	-- Set up config pane
	EnhancedRaidFrames:Setup()

	-- Register callbacks for profile switching
	EnhancedRaidFrames.db.RegisterCallback(EnhancedRaidFrames, "OnProfileChanged", "RefreshConfig")
	EnhancedRaidFrames.db.RegisterCallback(EnhancedRaidFrames, "OnProfileCopied", "RefreshConfig")
	EnhancedRaidFrames.db.RegisterCallback(EnhancedRaidFrames, "OnProfileReset", "RefreshConfig")
end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function EnhancedRaidFrames:OnEnable()
	local profile = EnhancedRaidFrames.db.profile

	--start a repeating timer to updated every frame every 0.8sec to make sure the the countdown timer stays accurate
	EnhancedRaidFrames.updateTimer = EnhancedRaidFrames:ScheduleRepeatingTimer("UpdateAllFrames", 0.7) --this is so countdown text is smooth

	--hook our UpdateIndicators function onto the default CompactUnitFrame_UpdateAuras function. The payload of the original function carries the identity of the frame needing updating
	EnhancedRaidFrames:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) EnhancedRaidFrames:UpdateIndicators(frame) end)

	-- Updates Range Alpha
	EnhancedRaidFrames:SecureHook("CompactUnitFrame_UpdateInRange", function(frame) EnhancedRaidFrames:UpdateInRange(frame) end)

	-- Hook raid icon updates
	EnhancedRaidFrames:RegisterBucketEvent({"RAID_TARGET_UPDATE", "RAID_ROSTER_UPDATE"}, 1, "UpdateAllFrames")

	-- Make sure any icons already existing are shown
	EnhancedRaidFrames:RefreshConfig()
end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function EnhancedRaidFrames:OnDisable()
	-- empty --
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Create our database, import saved variables, and set up our configuration panels
function EnhancedRaidFrames:Setup()
	-- Set up database defaults
	local defaults = EnhancedRaidFrames:CreateDefaults()

	-- Create database object
	EnhancedRaidFrames.db = LibStub("AceDB-3.0"):New("EnhancedRaidFramesDB", defaults) --EnhancedRaidFramesDB is our saved variable table

	-- Profile handling
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(EnhancedRaidFrames.db) --create the config panel for profiles

	-- Per spec profiles
	if not EnhancedRaidFrames.isWoWClassic then
		local LibDualSpec = LibStub('LibDualSpec-1.0')
		LibDualSpec:EnhanceDatabase(EnhancedRaidFrames.db, "EnhancedRaidFrames") --enhance the database object with per spec profile features
		LibDualSpec:EnhanceOptions(profiles, EnhancedRaidFrames.db) -- enhance the profiles config panel with per spec profile features
	end

	-- LibClassicDurations
	if EnhancedRaidFrames.isWoWClassic then
		local LibClassicDurations = LibStub("LibClassicDurations")
		LibClassicDurations:Register(addonName) -- tell library it's being used and should start working
		EnhancedRaidFrames.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper
	end

	-- Build our config panels
	local generalOptions = EnhancedRaidFrames:CreateGeneralOptions()
	local indicatorOptions = EnhancedRaidFrames:CreateIndicatorOptions()
	local iconOptions = EnhancedRaidFrames:CreateIconOptions()

	local config = LibStub("AceConfig-3.0")
	config:RegisterOptionsTable("Enhanced Raid Frames", generalOptions)
	config:RegisterOptionsTable("Indicator Options", indicatorOptions)
	config:RegisterOptionsTable("Icon Options", iconOptions)
	config:RegisterOptionsTable("Profiles", profiles)

	-- Add to config panels to in-game interface options
	local dialog = LibStub("AceConfigDialog-3.0")
	dialog:AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	dialog:AddToBlizOptions("Indicator Options", "Indicator Options", "Enhanced Raid Frames")
	dialog:AddToBlizOptions("Icon Options", "Icon Options", "Enhanced Raid Frames")
	dialog:AddToBlizOptions("Profiles", "Profiles", "Enhanced Raid Frames")
end

-- Update all raid frames
function EnhancedRaidFrames:UpdateAllFrames(setAppearance)
	local profile = EnhancedRaidFrames.db.profile

	--don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() then
		return
	end

	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal",
			function(frame)
				EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
				EnhancedRaidFrames:UpdateIcons(frame, setAppearance)
				EnhancedRaidFrames:UpdateInRange(frame)
				EnhancedRaidFrames:UpdateBackgroundAlpha(frame)
			end)
end

-- Refresh everything that is affected by changes to the configuration
function EnhancedRaidFrames:RefreshConfig()
	local profile = EnhancedRaidFrames.db.profile

	EnhancedRaidFrames:UpdateAllFrames(true)

	CompactRaidFrameContainer:SetScale(profile.frameScale)

	-- reset aura strings
	EnhancedRaidFrames.allAuras = " "
	EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(profile["auras"..i], "[^\n]+") do -- Grab each line
			--sanitize strings
			auraName = auraName:lower() --force lowercase
			auraName = auraName:gsub("^%s*(.-)%s*$", "%1") --strip any leading or trailing whitespace
			auraName = auraName:gsub("\"", "") --strip any quotation marks if there are any
			EnhancedRaidFrames.allAuras = EnhancedRaidFrames.allAuras.." "..auraName.." " -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			EnhancedRaidFrames.auraStrings[i][j] = auraName
			j = j + 1
		end
	end
end