-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ... --make use of the default addon namespace

---@class EnhancedRaidFrames : AceAddon-3.0 @define The main addon object for the Enhanced Raid Frames add-on
addonTable.EnhancedRaidFrames = LibStub("AceAddon-3.0"):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0",
		"AceEvent-3.0", "AceBucket-3.0", "AceConsole-3.0", "AceSerializer-3.0")
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	EnhancedRaidFrames.isWoWClassicEra = true
elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	EnhancedRaidFrames.isWoWClassic = true
end

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

local LibDualSpec
if not EnhancedRaidFrames.isWoWClassicEra then
	LibDualSpec = LibStub('LibDualSpec-1.0')
end

EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

EnhancedRaidFrames.DATABASE_VERSION = 2

-- Declare Color Global Constants
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
--- do init tasks here, like loading the Saved Variables or setting up slash commands.
function EnhancedRaidFrames:OnInitialize()
	-- Set up database defaults
	local defaults = self:CreateDefaults()

	-- Create database object
	self.db = AceDB:New("EnhancedRaidFramesDB", defaults) --EnhancedRaidFramesDB is our saved variable table

	-- Enhance database and profile options using LibDualSpec
	if not self.isWoWClassicEra then -- Not available in Classic Era
		LibDualSpec:EnhanceDatabase(self.db, "EnhancedRaidFrames") --enhance the database object with per spec profile features
		LibDualSpec:EnhanceOptions(AceDBOptions:GetOptionsTable(self.db), self.db) -- enhance the profile options table with per spec profile features
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
--- Register Events, Hook functions, Create Frames, Get information from the game that wasn't available in OnInitialize
function EnhancedRaidFrames:OnEnable()
	-- Populate our starting config values
	self:RefreshConfig()
	
	-- Create our listeners for UNIT_AURA events
	self:CreateAllListeners()

	-- Run a full update of all auras for a starting point
	self:UpdateAllAuras()

	-- Force a full update of all frames and auras when the raid roster changes
	self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 1, function()
		self:CreateAllListeners()
		self:UpdateAllAuras()
		self:UpdateAllIndicators(true)
	end)
	
	-- Hook our UpdateIndicators function onto the default CompactUnitFrame_UpdateAuras function. 
	-- We use SecureHook() because the default function is protected, and we want to make sure our code runs after the default code.
	self:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) self:SetStockIndicatorVisibility(frame) end)

	-- Hook our UpdateInRange function to the default CompactUnitFrame_UpdateInRange function.
	self:SecureHook("CompactUnitFrame_UpdateInRange", function(frame) self:UpdateInRange(frame) end)

	-- Force a full update of all frames when a raid target icon changes
	self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateAllTargetMarkers")

	-- Start a repeating timer to make sure the responsiveness feels right
	self:ScheduleRepeatingTimer("UpdateAllIndicators", 0.5)

	-- Register our slash command to open the config panel
	self:RegisterChatCommand("erf", function() Settings.OpenToCategory("Enhanced Raid Frames") end)

	-- Notify to the chat window of any new major updates, if necessary
	self:UpdateNotifier()
end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to build a "standby" mode, or be able to toggle modules on/off.
function EnhancedRaidFrames:OnDisable()
	-- empty --
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------
---
--- Create our database, import saved variables, and set up our configuration panels
function EnhancedRaidFrames:SetupConfigPanels()
	-- Build our config panels
	AceConfigRegistry:RegisterOptionsTable("Enhanced Raid Frames", self:CreateGeneralOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Indicator Options", self:CreateIndicatorOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Target Marker Options",  self:CreateIconOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Profiles", AceDBOptions:GetOptionsTable(self.db))
	AceConfigRegistry:RegisterOptionsTable("ERF Import Export Profile Options", self:CreateProfileImportExportOptions())

	-- Add to config panels to in-game interface options
	AceConfigDialog:AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Indicator Options", L["Indicator Options"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Target Marker Options", L["Target Marker Options"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Profiles", L["Profiles"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Import Export Profile Options", (L["Profile"].." "..L["Import"].."/"..L["Export"]), "Enhanced Raid Frames")
end

--- Refresh everything that is affected by changes to the configuration
function EnhancedRaidFrames:RefreshConfig()
	self:GenerateAuraStrings()
	self:UpdateScale()
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateIndicators(frame, true)
			self:UpdateBackgroundAlpha(frame)
			self:UpdateTargetMarkers(frame, true)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateIndicators(frame, true)
			self:UpdateBackgroundAlpha(frame)
			self:UpdateTargetMarkers(frame, true)
		end)
	end
end