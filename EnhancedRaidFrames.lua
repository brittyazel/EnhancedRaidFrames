-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace

---@class EnhancedRaidFrames : AceAddon-3.0 @define The main addon object for the Enhanced Raid Frames add-on
addonTable.EnhancedRaidFrames = LibStub("AceAddon-3.0"):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0",
		"AceEvent-3.0", "AceBucket-3.0", "AceConsole-3.0", "AceSerializer-3.0")
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

EnhancedRaidFrames.allAuras = " "
EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	EnhancedRaidFrames.isWoWClassicEra = true
elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	EnhancedRaidFrames.isWoWClassic = true
end

EnhancedRaidFrames.DATABASE_VERSION = 2

--Declare Color Globals
EnhancedRaidFrames.NORMAL_COLOR = NORMAL_FONT_COLOR or CreateColor(1.0, 0.82, 0.0) --the default game text color, dull yellow color
EnhancedRaidFrames.WHITE_COLOR = WHITE_FONT_COLOR or CreateColor(1.0, 1.0, 1.0) --default game white color for text
EnhancedRaidFrames.RED_COLOR = DIM_RED_FONT_COLOR or CreateColor(0.8, 0.1, 0.1) --solid red color
EnhancedRaidFrames.YELLOW_COLOR = DARKYELLOW_FONT_COLOR or CreateColor(1.0, 0.82, 0.0) --solid yellow color
EnhancedRaidFrames.GREEN_COLOR = CreateColor(0.6627, 0.8235, 0.4431) --poison text color
EnhancedRaidFrames.PURPLE_COLOR = CreateColor(0.6392, 0.1882, 0.7882) --curse text color
EnhancedRaidFrames.BROWN_COLOR = CreateColor(0.7804, 0.6118, 0.4314) --disease text color
EnhancedRaidFrames.BLUE_COLOR = CreateColor(0.0, 0.4392, 0.8706) --magic text color

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function EnhancedRaidFrames:OnInitialize()
	-- Set up database defaults
	local defaults = self:CreateDefaults()

	-- Create database object
	self.db = LibStub("AceDB-3.0"):New("EnhancedRaidFramesDB", defaults) --EnhancedRaidFramesDB is our saved variable table

	-- Setup LibDualSpec for per spec profiles
	-- Not available in Classic Era
	if not self.isWoWClassicEra then
		local profileOptionTable = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
		LibStub('LibDualSpec-1.0'):EnhanceDatabase(self.db, "EnhancedRaidFrames") --enhance the database object with per spec profile features
		LibStub('LibDualSpec-1.0'):EnhanceOptions(profileOptionTable, self.db) -- enhance the profile option table with per spec profile features
	end
	
	-- Setup config panels in the Blizzard interface options
	self:SetupConfigPanels()

	-- Register callbacks for profile switching
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function EnhancedRaidFrames:OnEnable()
	-- Register for the UNIT_AURA event to track auras on all raid frame units
	if not self.isWoWClassicEra and not self.isWoWClassic then
		self:RegisterEvent("UNIT_AURA", "UpdateUnitAuras")
		self:UpdateAllAuras() -- Run a full update of all auras for a starting point
	else
		self:RegisterEvent("UNIT_AURA", "UpdateUnitAuras_Classic")
		self:UpdateAllAuras_Classic() -- Run a full update of all auras for a starting point
	end

	-- Hook our UpdateIndicators function onto the default CompactUnitFrame_UpdateAuras function. 
	-- The payload of the original function carries the identity of the frame needing updating.
	-- Without this, things like the default aura icons will pop in and out.
	self:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) self:UpdateIndicators(frame) end)

	-- Hook our UpdateInRange function to the default CompactUnitFrame_UpdateInRange function.
	self:SecureHook("CompactUnitFrame_UpdateInRange", function(frame) self:UpdateInRange(frame) end)

	-- Force a full update of all frames when a raid target icon changes
	self:RegisterBucketEvent("RAID_TARGET_UPDATE", 1, "UpdateAllFrames")

	-- Force a full update of all frames and auras when the raid roster changes
	self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 1, function()
		self:UpdateAllFrames()
		self:UpdateAllAuras()
	end)

	-- Start a repeating timer to make sure the responsiveness feels right
	self:ScheduleRepeatingTimer("UpdateAllFrames", 0.25)

	-- Populate our starting config values
	self:RefreshConfig()

	-- Register our slash command to open the config panel
	self:RegisterChatCommand("erf", function() Settings.OpenToCategory("Enhanced Raid Frames") end)

	-- Notify to the chat window of any new major updates, if necessary
	self:UpdateNotifier()
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

--- Create our database, import saved variables, and set up our configuration panels
function EnhancedRaidFrames:SetupConfigPanels()
	-- Build our config panels
	local generalOptions = self:CreateGeneralOptions()
	local indicatorOptions = self:CreateIndicatorOptions()
	local iconOptions = self:CreateIconOptions()
	local profileOptionTable = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local importExportProfileOptions = self:CreateProfileImportExportOptions()
	
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Enhanced Raid Frames", generalOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ERF Indicator Options", indicatorOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ERF Icon Options", iconOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ERF Profiles", profileOptionTable)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ERF Import Export Profile Options", importExportProfileOptions)

	-- Add to config panels to in-game interface options
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ERF Indicator Options", L["Indicator Options"], "Enhanced Raid Frames")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ERF Icon Options", L["Icon Options"], "Enhanced Raid Frames")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ERF Profiles", L["Profiles"], "Enhanced Raid Frames")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ERF Import Export Profile Options", (L["Profile"].." "..L["Import"].."/"..L["Export"]), "Enhanced Raid Frames")
end

--- Update all raid frames
function EnhancedRaidFrames:UpdateAllFrames(setAppearance)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return
	end
	
	self:UpdateScale()

	-- This is the heart and soul of the addon. Everything gets called from here.
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateIndicators(frame, setAppearance)
			self:UpdateIcons(frame, setAppearance)
			self:UpdateInRange(frame)
			self:UpdateBackgroundAlpha(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateIndicators(frame, setAppearance)
			self:UpdateIcons(frame, setAppearance)
			self:UpdateInRange(frame)
			self:UpdateBackgroundAlpha(frame)
		end)
	end
end

-- Refresh everything that is affected by changes to the configuration
function EnhancedRaidFrames:RefreshConfig()
	self:UpdateAllFrames(true)
	self:GenerateAuraStrings()
end