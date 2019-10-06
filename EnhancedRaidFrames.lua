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
--Copyright for portions of Neuron are held in the public domain,
--as determined by Szandos. All other copyrights for
--Enhanced Raid Frame are held by Britt Yazel, 2017-2019.

local _, AddonTable = ... --make use of the default addon namespace
AddonTable.EnhancedRaidFrames = LibStub( "AceAddon-3.0" ):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0")
local EnhancedRaidFrames = AddonTable.EnhancedRaidFrames

EnhancedRaidFrames.allAuras = " "
EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for


-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function EnhancedRaidFrames:OnInitialize()

	-- Set up config pane
	EnhancedRaidFrames:SetupOptions()

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

	--start a repeating timer to updated every frame every 0.8sec to make sure the the countdown timer stays accurate
	EnhancedRaidFrames.updateTimer = EnhancedRaidFrames:ScheduleRepeatingTimer("UpdateAllFrames", 0.8) --this is so countdown text is smooth
	--hook our UpdateIndicators function onto the default CompactUnitFrame_UpdateAuras function. The payload of the original function carries the identity of the frame needing updating
	EnhancedRaidFrames:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) EnhancedRaidFrames:UpdateIndicators(frame) end)


	-- Hook raid icon updates
	EnhancedRaidFrames:RegisterEvent("RAID_TARGET_UPDATE", "UpdateAllFrames")
	EnhancedRaidFrames:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateAllFrames")

	-- Make sure any icons already existing are shown
	EnhancedRaidFrames:UpdateAllFrames()

	EnhancedRaidFrames:RefreshConfig()
end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function EnhancedRaidFrames:OnDisable()

end

-----------------------------------------------------------
-----------------------------------------------------------
-----------------------------------------------------------

-- Update all indicators
function EnhancedRaidFrames:UpdateAllFrames()
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal",
			function(frame)
				EnhancedRaidFrames:UpdateIndicators(frame);
				EnhancedRaidFrames:UpdateIcons(frame);
			end)
end


-- Used to update everything that is affected by the configuration
function EnhancedRaidFrames:RefreshConfig()

	-- Set the appearance of the indicators
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal",
			function(frame)
				EnhancedRaidFrames:SetIndicatorAppearance(frame);
				EnhancedRaidFrames:SetIconAppearance(frame)
			end)

	EnhancedRaidFrames:UpdateAllFrames()

	-- Format aura strings
	EnhancedRaidFrames.allAuras = " "

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(EnhancedRaidFrames.db.profile["auras"..i], "[^\n]+") do -- Grab each line
			auraName = string.gsub(auraName, "^%s*(.-)%s*$", "%1") -- Strip any whitespaces
			EnhancedRaidFrames.allAuras = EnhancedRaidFrames.allAuras.."+"..auraName.."+" -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			EnhancedRaidFrames.auraStrings[i][j] = auraName
			j = j + 1
		end
	end

end
