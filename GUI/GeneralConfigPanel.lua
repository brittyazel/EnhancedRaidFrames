-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateGeneralOptions()
	local THIRD_WIDTH = 1.15

	local generalOptions = {
		type = "group",
		childGroups = "tree",
		name = L["General Options"],
		args  = {
			instructions = {
				type = "description",
				name = L["generalOptions_desc"],
				fontSize = "medium",
				order = 2,
			},
			-------------------------------------------------
			topSpacer = {
				type = "header",
				name = "",
				order = 3,
			},
			blizzardRaidOptionsButton = {
				type = 'execute',
				name = L["Open the Blizzard Raid Profiles Options"],
				desc = L["blizzardRaidOptionsButton_desc"],
				func = function()
					if Settings then --10.0 introduced a new Settings API
						Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID, RAID_FRAMES_LABEL)
					else
						InterfaceOptionsFrame_OpenToCategory("Raid Profiles")
					end
				end,
				width = THIRD_WIDTH * 1.5,
				order = 4,
			},
			-------------------------------------------------
			textHeader = {
				type = "header",
				name = L["Default Icon Visibility"],
				order = 10,
			},
			showBuffs = {
				type = "toggle",
				name = L["Stock Buff Icons"],
				desc = L["showBuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showBuffs end,
				set = function(_, value)
					self.db.profile.showBuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = L["Stock Debuff Icons"],
				desc = L["showDebuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showDebuffs end,
				set = function(_, value)
					self.db.profile.showDebuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			showDispellableDebuffs = {
				type = "toggle",
				name = L["Stock Dispellable Icons"],
				desc = L["showDispellableDebuffs_desc"],
				descStyle = "inline",
				get = function() return self.db.profile.showDispellableDebuffs end,
				set = function(_, value)
					self.db.profile.showDispellableDebuffs = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 13,
			},
			-------------------------------------------------
			visualOptions = {
				type = "header",
				name = L["General"],
				order = 30,
			},
			powerBarOffset = {
				type = "toggle",
				name = L["Power Bar Vertical Offset"],
				desc = L["powerBarOffset_desc"],
				get = function() return self.db.profile.powerBarOffset end,
				set = function(_, value)
					self.db.profile.powerBarOffset = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 31,
			},
			frameScale = {
				type = "range",
				name = L["Raidframe Scale"],
				desc = L["frameScale_desc"],
				min = 0.5,
				max = 2,
				step = 0.1,
				get = function() return self.db.profile.frameScale end,
				set = function(_, value)
					self.db.profile.frameScale = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 32,
			},
			backgroundAlpha = {
				type = "range",
				name = L["Background Opacity"],
				desc = L["backgroundAlpha_desc"],
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return self.db.profile.backgroundAlpha end,
				set = function(_, value)
					self.db.profile.backgroundAlpha = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 33,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = L["Indicator Font"],
				desc = L["indicatorFont_desc"],
				values = AceGUIWidgetLSMlists.font,
				get = function() return self.db.profile.indicatorFont end,
				set = function(_, value)
					self.db.profile.indicatorFont = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 34,
			},
			-------------------------------------------------
			outOfRangeOptions = {
				type = "header",
				name = L["Out-of-Range"],
				order = 40,
			},
			customRangeCheck = {
				type = "toggle",
				name = L["Override Default Distance"],
				desc = L["customRangeCheck_desc"],
				get = function() return self.db.profile.customRangeCheck end,
				set = function(_, value)
					self.db.profile.customRangeCheck = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 41,
			},
			customRange = {
				type = "select",
				name = L["Select a Custom Distance"],
				desc = L["customRangeCheck_desc"],
				values = { [5] = "Melee", [10] = "10 yards", [20] = "20 yards", [30] = "30 yards", [35] = "35 yards"},
				get = function() return self.db.profile.customRange end,
				set = function(_, value)
					self.db.profile.customRange = value
					self:RefreshConfig()
				end,
				disabled = function() return not self.db.profile.customRangeCheck end,
				width = THIRD_WIDTH,
				order = 42,
			},
			rangeAlpha = {
				type = "range",
				name = L["Out-of-Range Opacity"],
				desc = L["rangeAlpha_desc"],
				min = 0,
				max = 1,
				step = 0.05,
				get = function() return self.db.profile.rangeAlpha end,
				set = function(_, value)
					self.db.profile.rangeAlpha = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 43,
			},
		}
	}

	return generalOptions
end