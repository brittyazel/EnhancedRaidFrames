-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local addonName, addonTable = ... --make use of the default addon namespace

---@class EnhancedRaidFrames : AceAddon-3.0 @define The main addon object for the Enhanced Raid Frames add-on
addonTable.EnhancedRaidFrames = LibStub("AceAddon-3.0"):NewAddon("EnhancedRaidFrames", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0", "AceBucket-3.0", "AceConsole-3.0", "AceSerializer-3.0")
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

EnhancedRaidFrames.allAuras = " "
EnhancedRaidFrames.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then --boolean check to set a flag if the current session is WoW Classic. Retail == 1, Classic == 2
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
	-- Set up config pane
	self:Setup()

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
	--start a repeating timer to updated every frame every 0.8sec to make sure the the countdown timer stays accurate
	self.updateTimer = self:ScheduleRepeatingTimer("UpdateAllFrames", 0.5) --this is so countdown text is smooth

	--hook our UpdateIndicators function onto the default CompactUnitFrame_UpdateAuras function. The payload of the original function carries the identity of the frame needing updating
	self:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) self:UpdateIndicators(frame) end)

	-- Updates Range Alpha
	self:SecureHook("CompactUnitFrame_UpdateInRange", function(frame) self:UpdateInRange(frame) end)

	-- Hook raid icon updates
	self:RegisterBucketEvent({"RAID_TARGET_UPDATE", "RAID_ROSTER_UPDATE"}, 1, "UpdateAllFrames")

	-- Make sure any icons already existing are shown
	self:RefreshConfig()

	-- notify of any new major updates, if necessary
	self:UpdateNotifier()

	self:RegisterChatCommand("erf",function()
		if Settings then --10.0 introduced a new Settings API
			Settings.OpenToCategory("Enhanced Raid Frames")
		else
			InterfaceOptionsFrame_OpenToCategory("Enhanced Raid Frames")
			InterfaceOptionsFrame_OpenToCategory("Enhanced Raid Frames")
		end
	end)
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
function EnhancedRaidFrames:Setup()
	-- Set up database defaults
	local defaults = self:CreateDefaults()

	-- Create database object
	self.db = LibStub("AceDB-3.0"):New("EnhancedRaidFramesDB", defaults) --EnhancedRaidFramesDB is our saved variable table

	-- Profile handling
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) --create the config panel for profiles

	-- Per spec profiles
	if not self.isWoWClassicEra then
		local LibDualSpec = LibStub('LibDualSpec-1.0')
		LibDualSpec:EnhanceDatabase(self.db, "EnhancedRaidFrames") --enhance the database object with per spec profile features
		LibDualSpec:EnhanceOptions(profiles, self.db) -- enhance the profiles config panel with per spec profile features
	end

	-- LibClassicDurations
	if self.isWoWClassicEra then
		local LibClassicDurations = LibStub("LibClassicDurations")
		LibClassicDurations:Register(addonName) -- tell library it's being used and should start working
		self.UnitAuraWrapper = LibClassicDurations.UnitAuraWrapper
	end

	-- Build our config panels
	local generalOptions = self:CreateGeneralOptions()
	local indicatorOptions = self:CreateIndicatorOptions()
	local iconOptions = self:CreateIconOptions()
	local importExportProfileOptions = self:CreateProfileImportExportOptions()

	self.config = LibStub("AceConfigRegistry-3.0")
	self.config:RegisterOptionsTable("Enhanced Raid Frames", generalOptions)
	self.config:RegisterOptionsTable("ERF Indicator Options", indicatorOptions)
	self.config:RegisterOptionsTable("ERF Icon Options", iconOptions)
	self.config:RegisterOptionsTable("ERF Profiles", profiles)
	self.config:RegisterOptionsTable("ERF Import Export Profile Options", importExportProfileOptions)

	-- Add to config panels to in-game interface options
	self.dialog = LibStub("AceConfigDialog-3.0")
	self.dialog:AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	self.dialog:AddToBlizOptions("ERF Indicator Options", L["Indicator Options"], "Enhanced Raid Frames")
	self.dialog:AddToBlizOptions("ERF Icon Options", L["Icon Options"], "Enhanced Raid Frames")
	self.dialog:AddToBlizOptions("ERF Profiles", L["Profiles"], "Enhanced Raid Frames")
	self.dialog:AddToBlizOptions("ERF Import Export Profile Options", (L["Profile"].." "..L["Import"].."/"..L["Export"]), "Enhanced Raid Frames")
end

--- Update all raid frames
---@param setAppearance boolean
function EnhancedRaidFrames:UpdateAllFrames(setAppearance)
	--don't do any work if the raid frames aren't shown
	--10.0 introduced the CompactPartyFrame, we can't assume it exists in Classic
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return
	end

	--this is the heart and soul of the addon. Everything gets called from here.
	if CompactRaidFrameContainer.ApplyToFrames then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal",
				function(frame)
					self:UpdateIndicators(frame, setAppearance)
					self:UpdateIcons(frame, setAppearance)
					self:UpdateInRange(frame)
					self:UpdateBackgroundAlpha(frame)
				end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal",
				function(frame)
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

	if not InCombatLockdown() then
		CompactRaidFrameContainer:SetScale(self.db.profile.frameScale)
		if CompactPartyFrame then
			CompactPartyFrame:SetScale(self.db.profile.frameScale)
		end
	end

	-- reset aura strings
	self.allAuras = " "
	self.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(self.db.profile[i].auras, "[^\n]+") do -- Grab each line
			--sanitize strings
			auraName = auraName:lower() --force lowercase
			auraName = auraName:gsub("^%s*(.-)%s*$", "%1") --strip any leading or trailing whitespace
			auraName = auraName:gsub("\"", "") --strip any quotation marks if there are any
			self.allAuras = EnhancedRaidFrames.allAuras.." "..auraName.." " -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			self.auraStrings[i][j] = auraName
			j = j + 1
		end
	end
end


function EnhancedRaidFrames:GetSerializedAndCompressedProfile()
	local uncompressed = EnhancedRaidFrames:Serialize(EnhancedRaidFrames.db.profile) --serialize the database into a string value
	local compressed = LibDeflate:CompressZlib(uncompressed) --compress the data
	local encoded = LibDeflate:EncodeForPrint(compressed) --encode the data for print for copy+paste
	return encoded
end


function EnhancedRaidFrames:SetSerializedAndCompressedProfile(input)
	--check if the input is empty
	if input == "" then
		EnhancedRaidFrames:Print(L["No data to import."].." "..L["Aborting."])
		return
	end

	--decode and check if decoding worked properly
	local decoded = LibDeflate:DecodeForPrint(input)
	if decoded == nil then
		EnhancedRaidFrames:Print(L["Decoding failed."].." "..L["Aborting."])
		return
	end

	--uncompress and check if uncompresion worked properly
	local uncompressed = LibDeflate:DecompressZlib(decoded)
	if uncompressed == nil then
		EnhancedRaidFrames:Print(L["Decompression failed."].." "..L["Aborting."])
		return
	end

	--deserialize the data and return it back into a table format
	local result, newProfile = EnhancedRaidFrames:Deserialize(uncompressed)

	if result == true and newProfile then --if we successfully deserialize, load the new table and reload
		for k,v in pairs(newProfile) do
			if type(v) == "table" then
				EnhancedRaidFrames.db.profile[k] = CopyTable(v)
			else
				EnhancedRaidFrames.db.profile[k] = v
			end
		end
	else
		EnhancedRaidFrames:Print(L["Data import Failed."].." "..L["Aborting."])
	end
end