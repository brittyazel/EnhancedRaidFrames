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

local EnhancedRaidFrames = EnhancedRaidFrames_Global

-------------------------------------------------------------------------
-------------------------------------------------------------------------


function EnhancedRaidFrames:SetupOptions()
	-- Set up defaults
	local defaults = EnhancedRaidFrames:CreateDefaults()
	EnhancedRaidFrames.db = LibStub("AceDB-3.0"):New("IndicatorsDB", defaults)

	-- Profile handling
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(EnhancedRaidFrames.db)

	-- Get the config up
	local generalOptions = EnhancedRaidFrames:CreateGeneralOptions()
	local indicatorOptions = EnhancedRaidFrames:CreateIndicatorOptions()
	local iconOptions = EnhancedRaidFrames:CreateIconOptions()
	local config = LibStub("AceConfig-3.0")

	config:RegisterOptionsTable("Enhanced Raid Frames", generalOptions)
	config:RegisterOptionsTable("Indicator Options", indicatorOptions)
	config:RegisterOptionsTable("Icon Options", iconOptions)
	config:RegisterOptionsTable("Profiles", profiles)

	-- Add to Blizz option pane
	local dialog = LibStub("AceConfigDialog-3.0")
	EnhancedRaidFrames.optionsFrames = {}
	EnhancedRaidFrames.optionsFrames.Indicators = dialog:AddToBlizOptions("Enhanced Raid Frames", "Enhanced Raid Frames")
	EnhancedRaidFrames.optionsFrames.Indicators = dialog:AddToBlizOptions("Indicator Options", "Indicator Options", "Enhanced Raid Frames")
	EnhancedRaidFrames.optionsFrames.Profile = dialog:AddToBlizOptions("Icon Options", "Icon Options", "Enhanced Raid Frames")
	EnhancedRaidFrames.optionsFrames.Profile = dialog:AddToBlizOptions("Profiles", "Profiles", "Enhanced Raid Frames")
end


function EnhancedRaidFrames:CreateDefaults ()
	local defaults = {}

	defaults.profile = {
		indicatorFont = "Arial Narrow",
		showTooltips=true,

		showBuffs = true,
		showDebuffs = true,
		showDispelDebuffs=true,

		iconSize = 20,
		iconPosition = "CENTER",
	}
	for i = 1, 9 do
		defaults.profile["auras"..i] = ""
		defaults.profile["size"..i] = 10
		defaults.profile["color"..i] = {r = 1, g = 1, b = 1, a = 1,}
		defaults.profile["mine"..i] = false
		defaults.profile["stack"..i] = false
		defaults.profile["stackColor"..i] = false
		defaults.profile["debuffColor"..i] = false
		defaults.profile["colorByTime"..i] = false
		defaults.profile["missing"..i] = false
		defaults.profile["me"..i] = false
		defaults.profile["showText"..i] = false
		defaults.profile["showCooldownAnimation"..i] = true
		defaults.profile["showIcon"..i] = true
		defaults.profile["iconSize"..i] = 16
	end

	return defaults
end

function EnhancedRaidFrames:CreateGeneralOptions()
	local generalOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value) EnhancedRaidFrames.db.profile[item[#item]] = value; EnhancedRaidFrames:RefreshConfig() end,
		args  = {
			generalHeader = {
				type = "header",
				name = "Global Options",
				order = 1,
			},
			showTooltips = {
				type = "toggle",
				name = "Show Tooltips",
				desc = "Show tooltips when mousing over indicator frames",
				order = 2,
			},
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = "Indicator Font",
				desc = "Adjust the font used for the indicators",
				values = AceGUIWidgetLSMlists.font,
				order = 3,
			},
			textHeader = {
				type = "header",
				name = "Default Buff/Debuff Icons",
				order = 7,
			},
			showBuffs = {
				type = "toggle",
				name = "Stock Buff Icons",
				desc = "Show the standard raid frame buff icons",
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Stock Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				order = 13,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Stock Dispellable Icons",
				desc = "Show the standard raid frame dispellable debuff icons",
				order = 15,
			},
		}

	}

	return generalOptions

end


function EnhancedRaidFrames:CreateIndicatorOptions()

	local indicatorOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value) EnhancedRaidFrames.db.profile[item[#item]] = value; EnhancedRaidFrames:RefreshConfig() end,
		args  = {}
	}

	--- Add options for each indicator
	local indicatorNames = {"Top Left", "Top", "Top Right", "Left", "Center", "Right", "Bottom Left", "Bottom", "Bottom Right"}
	for i = 1, 9 do
		indicatorOptions.args["i"..i] = {}
		indicatorOptions.args["i"..i].type = 'group'
		indicatorOptions.args["i"..i].name = indicatorNames[i]
		indicatorOptions.args["i"..i].order = i*10+10
		indicatorOptions.args["i"..i].args = {}
		indicatorOptions.args["i"..i].args["auras"..i] = {
			type = "input",
			name = "Buffs/Debuffs",
			desc = "The buffs/debuffs to show in this indicator. Put each buff/debuff on a separate line. You can use 'Magic/Poison/Curse/Disease' to show any debuff of that type.",
			multiline = true,
			order = 1,
			width = "full",
		}
		indicatorOptions.args["i"..i].args["mine"..i] = {
			type = "toggle",
			name = "Mine only",
			desc = "Only show buffs/debuffs cast by me",
			order = 10,
		}
		indicatorOptions.args["i"..i].args["missing"..i] = {
			type = "toggle",
			name = "Show only if missing",
			desc = "Show only if all specified buffs/debuffs are missing on the target",
			order = 30,
		}
		indicatorOptions.args["i"..i].args["me"..i] = {
			type = "toggle",
			name = "Show on me only",
			desc = "Only show this indicator on myself",
			order = 40,
		}
		indicatorOptions.args["i"..i].args.textHeader = {
			type = "header",
			name = "Text",
			order = 100,
		}
		indicatorOptions.args["i"..i].args["showText"..i] = {
			type = "toggle",
			name = "Show cooldown text",
			desc = "Show the cooldown text specifying the time left of the buff/debuff",
			order = 110,
		}
		indicatorOptions.args["i"..i].args["stack"..i] = {
			type = "toggle",
			name = "Show stack size",
			desc = "Show stack size for buffs/debuffs that stack",
			order = 111,
		}
		indicatorOptions.args["i"..i].args["size"..i] = {
			type = "range",
			name = "Text Size",
			desc = "Text size",
			min = 1,
			max = 30,
			step = 1,
			order = 120,
			width = "full",
		}
		indicatorOptions.args["i"..i].args.coloringHeader = {
			type = "header",
			name = "Color",
			order = 150,
		}
		indicatorOptions.args["i"..i].args["stackColor"..i] = {
			type = "toggle",
			name = "Color by stack size",
			desc = "Color the text depending on the stack size, will override any other coloring (3+: Green, 2: Yellow, 1: Red)",
			order = 160,
		}
		indicatorOptions.args["i"..i].args["debuffColor"..i] = {
			type = "toggle",
			name = "Color by debuff type",
			desc = "Color the text depending on the debuff type, will override any other coloring (poison = green, magic = blue etc)",
			disabled = function () return EnhancedRaidFrames.db.profile["stackColor"..i] end,
			order = 165,
		}
		indicatorOptions.args["i"..i].args["color"..i] = {
			type = "color",
			name = "Color",
			desc = "Color of the indicator",
			get = function(item)
				local t = EnhancedRaidFrames.db.profile[item[#item]]
				return t.r, t.g, t.b, t.a
			end,
			set = function(item, r, g, b, a)
				local t = EnhancedRaidFrames.db.profile[item[#item]]
				t.r, t.g, t.b, t.a = r, g, b, a
				EnhancedRaidFrames:RefreshConfig()
			end,
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 170,
		}
		indicatorOptions.args["i"..i].args["colorByTime"..i] = {
			type = "toggle",
			name = "Color by remaining time",
			desc = "Color the counter based on remaining time (5s+: Selected color, 3-5s: Yellow, 3s-: Red)",
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 180,
		}
		indicatorOptions.args["i"..i].args.iconHeader = {
			type = "header",
			name = "Icon",
			order = 300,
		}
		indicatorOptions.args["i"..i].args["showIcon"..i] = {
			type = "toggle",
			name = "Show icon",
			desc = "Show an icon if the buff/debuff are on the unit",
			order = 310,
		}
		indicatorOptions.args["i"..i].args["showCooldownAnimation"..i] = {
			type = "toggle",
			name = "Show CD animation",
			desc = "Show the cooldown animation specifying the time left of the buff/debuff",
			order = 311,
		}
		indicatorOptions.args["i"..i].args["iconSize"..i] = {
			type = "range",
			name = "Icon size",
			desc = "Icon size",
			min = 1,
			max = 30,
			step = 1,
			order = 320,
			width = "full",
		}
	end

	return indicatorOptions
end

function EnhancedRaidFrames:CreateIconOptions()
	local iconOptions = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value) EnhancedRaidFrames.db.profile[item[#item]] = value; EnhancedRaidFrames:RefreshConfig() end,
		args  = {
			iconSize = {
				type = 'range',
				name = "Icon Size",
				desc = "The size of the raid icons",
				min = 1,
				max = 40,
				step = 1,
				order = 10,
			},
			iconPosition = {
				type = "select",
				name = "Icon Position",
				desc = "Position of the raid icon relative to the frame",
				order = 20,
				values = { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right" ,
				           ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right",
				           ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right"},
			},
		}
	}

	return iconOptions

end