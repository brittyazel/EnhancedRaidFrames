-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

-------------------------------------------------------------------------
-------------------------------------------------------------------------
--- Populate our "Target Marker" options table for our Blizzard interface options
function EnhancedRaidFrames:CreateIconOptions()
	local THIRD_WIDTH = 1.25

	local markerOptions = {
		type = "group",
		childGroups = "tree",
		name = L["Target Marker Options"],
		args = {
			instructions = {
				type = "description",
				name = L["markerOptions_desc"] .. ":",
				fontSize = "medium",
				order = 1,
			},
			-------------------------------------------------
			generalHeader = {
				type = "header",
				name = L["General"],
				order = 2,
			},
			showTargetMarkers = {
				type = "toggle",
				name = L["Show Target Markers"],
				desc = L["showTargetMarkers_desc"],
				get = function()
					return self.db.profile.showTargetMarkers
				end,
				set = function(_, value)
					self.db.profile.showTargetMarkers = value
					self:RefreshConfig()
				end,
				width = THIRD_WIDTH,
				order = 3,
			},
			markerSize = {
				type = 'range',
				name = L["Target Marker Size"],
				desc = L["markerSize_desc"],
				min = 1,
				max = 40,
				step = 1,
				get = function()
					return self.db.profile.markerSize
				end,
				set = function(_, value)
					self.db.profile.markerSize = value
					self:RefreshConfig()
				end,
				disabled = function()
					return not self.db.profile.showTargetMarkers
				end,
				width = THIRD_WIDTH,
				order = 11,
			},
			markerAlpha = {
				type = "range",
				name = L["Target Marker Opacity"],
				desc = L["markerAlpha_desc"],
				isPercent = true,
				min = 0,
				max = 1,
				step = 0.01,
				get = function()
					return self.db.profile.markerAlpha
				end,
				set = function(_, value)
					self.db.profile.markerAlpha = value
					self:RefreshConfig()
				end,
				disabled = function()
					return not self.db.profile.showTargetMarkers
				end,
				width = THIRD_WIDTH,
				order = 12,
			},
			-------------------------------------------------
			positionOptions = {
				type = "header",
				name = L["Position"],
				order = 20,
			},
			markerPosition = {
				type = "select",
				name = L["Marker Position"],
				desc = L["markerPosition_desc"],
				values = self.POSITIONS,
				get = function()
					return self.db.profile.markerPosition
				end,
				set = function(_, value)
					self.db.profile.markerPosition = value
					self:RefreshConfig()
				end,
				disabled = function()
					return not self.db.profile.showTargetMarkers
				end,
				width = THIRD_WIDTH,
				order = 21,
			},
			markerVerticalOffset = {
				type = "range",
				name = L["Vertical Offset"],
				desc = L["verticalOffset_desc"],
				isPercent = true,
				min = -1,
				max = 1,
				step = .01,
				get = function()
					return self.db.profile.markerVerticalOffset
				end,
				set = function(_, value)
					self.db.profile.markerVerticalOffset = value
					self:RefreshConfig()
				end,
				disabled = function()
					return not self.db.profile.showTargetMarkers
				end,
				width = THIRD_WIDTH,
				order = 22,
			},
			markerHorizontalOffset = {
				type = "range",
				name = L["Horizontal Offset"],
				desc = L["horizontalOffset_desc"],
				isPercent = true,
				min = -1,
				max = 1,
				step = .01,
				get = function()
					return self.db.profile.markerHorizontalOffset
				end,
				set = function(_, value)
					self.db.profile.markerHorizontalOffset = value
					self:RefreshConfig()
				end,
				disabled = function()
					return not self.db.profile.showTargetMarkers
				end,
				width = THIRD_WIDTH,
				order = 23,
			},
		}
	}
	return markerOptions
end