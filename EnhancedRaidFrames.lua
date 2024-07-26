-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

--- EnhancedRaidFrames is the main addon object for the Enhanced Raid Frames add-on.
---@class EnhancedRaidFrames : AceAddon-3.0 @The main addon object for the Enhanced Raid Frames add-on
_G.EnhancedRaidFrames = LibStub("AceAddon-3.0"):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0",
		"AceEvent-3.0", "AceBucket-3.0", "AceConsole-3.0", "AceSerializer-3.0")

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Called directly after the addon is fully loaded.
--- We do initialization tasks here, such as loading our saved variables or setting up slash commands.
function EnhancedRaidFrames:OnInitialize()
	-- Set up our database
	self:InitializeDatabase()

	-- Run our database migration if necessary
	self:MigrateDatabase()

	-- Setup config panels in the Blizzard interface options
	self:InitializeConfigPanels()

	-- Register callbacks for profile switching
	self.db.RegisterCallback(self, "OnProfileChanged", function()
		self:MigrateDatabase()
		self:RefreshConfig()
	end)
	self.db.RegisterCallback(self, "OnProfileCopied", function()
		self:MigrateDatabase()
		self:RefreshConfig()
	end)
	self.db.RegisterCallback(self, "OnProfileReset", function()
		self:MigrateDatabase()
		self:RefreshConfig()
	end)
end

--- Called during the PLAYER_LOGIN event when most of the data provided by the game is already present.
--- We perform more startup tasks here, such as registering events, hooking functions, creating frames, or getting 
--- information from the game that wasn't yet available during :OnInitialize()
function EnhancedRaidFrames:OnEnable()
	-- Populate our starting config values
	self:RefreshConfig()

	-- Run a full update of all auras for a starting point
	self:CreateAllAuraListeners() -- Explicitly create aura listeners for all frames regardless of visibility
	self:UpdateAllAuras()

	-- Force a full update of all frames and auras when the raid roster changes
	self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 0.25, function()
		self:UpdateAllStockAuraVisibility()
		self:CreateAllAuraListeners() -- Explicitly create aura listeners for all frames regardless of visibility
		self:UpdateAllAuras()
		self:UpdateAllIndicators()
		self:UpdateAllTargetMarkers()
	end)

	-- Force a full update of all frames when a raid target icon changes
	self:RegisterEvent("RAID_TARGET_UPDATE", function()
		self:UpdateAllTargetMarkers()
	end)

	-- Hook our UpdateInRange function to the default CompactUnitFrame_UpdateInRange function.
	-- Using SecureHook ensures that our function will run 'after' the default function, which is what we want.
	self:SecureHook("CompactUnitFrame_UpdateInRange", function(frame)
		self:UpdateInRange(frame)
	end)

	-- Register our slash command to open the config panel
	self:RegisterChatCommand("erf", function()
		Settings.OpenToCategory("Enhanced Raid Frames")
	end)
end

--- Called when our addon is manually being disabled during a running session.
--- We primarily use this to unhook scripts, unregister events, or hide frames that we created.
function EnhancedRaidFrames:OnDisable()
	-- Empty --
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Create a table containing our default database values
function EnhancedRaidFrames:InitializeDatabase()
	-- Set up database defaults
	local defaults = self:CreateDefaults()

	-- Create database object
	self.db = AceDB:New("EnhancedRaidFramesDB", defaults) --EnhancedRaidFramesDB is our saved variable table
	
	-- Enhance database and profile options using LibDualSpec
	if not self.isWoWClassicEra then
		-- Not available in Classic Era
		-- Enhance the database object with per spec profile features
		LibStub("LibDualSpec-1.0"):EnhanceDatabase(self.db, "EnhancedRaidFrames")
		-- Enhance the profile options table with per spec profile features
		LibStub("LibDualSpec-1.0"):EnhanceOptions(AceDBOptions:GetOptionsTable(self.db), self.db)
	end
end

--- Set up our configuration panels and add them to the Blizzard interface options
function EnhancedRaidFrames:InitializeConfigPanels()
	-- Build our config panels
	AceConfigRegistry:RegisterOptionsTable("Enhanced Raid Frames", self:CreateGeneralOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Indicator Options", self:CreateIndicatorOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Target Marker Options", self:CreateIconOptions())
	AceConfigRegistry:RegisterOptionsTable("ERF Profiles", AceDBOptions:GetOptionsTable(self.db))
	AceConfigRegistry:RegisterOptionsTable("ERF Import Export Profile Options", self:CreateProfileImportExportOptions())

	-- Add to config panels to in-game interface options
	AceConfigDialog:AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Indicator Options", L["Indicator Options"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Target Marker Options", L["Target Marker Options"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Profiles", L["Profiles"], "Enhanced Raid Frames")
	AceConfigDialog:AddToBlizOptions("ERF Import Export Profile Options",
			(L["Profile"] .. " " .. L["Import"] .. "/" .. L["Export"]), "Enhanced Raid Frames")
end

--- Refresh everything that is affected by changes to the configuration
function EnhancedRaidFrames:RefreshConfig()
	self:GenerateAuraStrings()
	self:UpdateScale()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateIndicators(frame, true)
			self:UpdateBackgroundAlpha(frame)
			self:UpdateTargetMarker(frame, true)
			self:UpdateStockAuraVisibility(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateIndicators(frame, true)
			self:UpdateBackgroundAlpha(frame)
			self:UpdateTargetMarker(frame, true)
			self:UpdateStockAuraVisibility(frame)
		end)
	end
end