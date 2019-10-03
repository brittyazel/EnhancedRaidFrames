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

local Defaults = {}
local Options = {}

local EnhancedRaidFrames = EnhancedRaidFrames_Global


function EnhancedRaidFrames:CreateDefaults ()
	Defaults.profile = {
		indicatorFont = "Arial Narrow",
		showBuffs = true,
		showDebuffs = true,
	}
	for i = 1, 9 do
		Defaults.profile["auras"..i] = ""
		Defaults.profile["size"..i] = 10
		Defaults.profile["color"..i] = {r = 1, g = 1, b = 1, a = 1,}
		Defaults.profile["mine"..i] = false
		Defaults.profile["stack"..i] = false
		Defaults.profile["stackColor"..i] = false
		Defaults.profile["debuffColor"..i] = false
		Defaults.profile["colorByTime"..i] = false
		Defaults.profile["missing"..i] = false
		Defaults.profile["me"..i] = false
		Defaults.profile["showText"..i] = false
		Defaults.profile["showCooldownAnimation"..i] = true
		Defaults.profile["showIcon"..i] = true
		Defaults.profile["iconSize"..i] = 16
	end
end

function EnhancedRaidFrames:CreateOptions ()
	Options = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return EnhancedRaidFrames.db.profile[item[#item]] end,
		set = function(item, value) EnhancedRaidFrames.db.profile[item[#item]] = value; EnhancedRaidFrames:RefreshConfig() end,
		args  = {

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
			indicatorFont = {
				type = 'select',
				dialogControl = "LSM30_Font",
				name = "Indicator Font",
				desc = "Adjust the font used for the indicators",
				values = AceGUIWidgetLSMlists.font,
				order = 17,
			},
		}
	}

	--- Add options for each indicator
	local indicatorNames = {"Top Left", "Top", "Top Right", "Left", "Center", "Right", "Bottom Left", "Bottom", "Bottom Right"}
	for i = 1, 9 do
		Options.args["i"..i] = {}
		Options.args["i"..i].type = 'group'
		Options.args["i"..i].name = indicatorNames[i]
		Options.args["i"..i].order = i*10+10
		Options.args["i"..i].args = {}
		Options.args["i"..i].args["auras"..i] = {
			type = "input",
			name = "Buffs/Debuffs",
			desc = "The buffs/debuffs to show in this indicator. Put each buff/debuff on a separate line. You can use 'Magic/Poison/Curse/Disease' to show any debuff of that type.",
			multiline = true,
			order = 1,
			width = "full",
		}
		Options.args["i"..i].args["mine"..i] = {
			type = "toggle",
			name = "Mine only",
			desc = "Only show buffs/debuffs cast by me",
			order = 10,
		}
		Options.args["i"..i].args["missing"..i] = {
			type = "toggle",
			name = "Show only if missing",
			desc = "Show only if all specified buffs/debuffs are missing on the target",
			order = 30,
		}
		Options.args["i"..i].args["me"..i] = {
			type = "toggle",
			name = "Show on me only",
			desc = "Only show this indicator on myself",
			order = 40,
		}
		Options.args["i"..i].args.textHeader = {
			type = "header",
			name = "Text",
			order = 100,
		}
		Options.args["i"..i].args["showText"..i] = {
			type = "toggle",
			name = "Show cooldown text",
			desc = "Show the cooldown text specifying the time left of the buff/debuff",
			order = 110,
		}
		Options.args["i"..i].args["stack"..i] = {
			type = "toggle",
			name = "Show stack size",
			desc = "Show stack size for buffs/debuffs that stack",
			order = 111,
		}
		Options.args["i"..i].args["size"..i] = {
			type = "range",
			name = "Text Size",
			desc = "Text size",
			min = 1,
			max = 30,
			step = 1,
			order = 120,
			width = "full",
		}
		Options.args["i"..i].args.coloringHeader = {
			type = "header",
			name = "Color",
			order = 150,
		}
		Options.args["i"..i].args["stackColor"..i] = {
			type = "toggle",
			name = "Color by stack size",
			desc = "Color the text depending on the stack size, will override any other coloring (3+: Green, 2: Yellow, 1: Red)",
			order = 160,
		}
		Options.args["i"..i].args["debuffColor"..i] = {
			type = "toggle",
			name = "Color by debuff type",
			desc = "Color the text depending on the debuff type, will override any other coloring (poison = green, magic = blue etc)",
			disabled = function () return EnhancedRaidFrames.db.profile["stackColor"..i] end,
			order = 165,
		}
		Options.args["i"..i].args["color"..i] = {
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
		Options.args["i"..i].args["colorByTime"..i] = {
			type = "toggle",
			name = "Color by remaining time",
			desc = "Color the counter based on remaining time (5s+: Selected color, 3-5s: Yellow, 3s-: Red)",
			disabled = function () return (EnhancedRaidFrames.db.profile["stackColor"..i] or EnhancedRaidFrames.db.profile["debuffColor"..i]) end,
			order = 180,
		}
		Options.args["i"..i].args.iconHeader = {
			type = "header",
			name = "Icon",
			order = 300,
		}
		Options.args["i"..i].args["showIcon"..i] = {
			type = "toggle",
			name = "Show icon",
			desc = "Show an icon if the buff/debuff are on the unit",
			order = 310,
		}
		Options.args["i"..i].args["showCooldownAnimation"..i] = {
			type = "toggle",
			name = "Show CD animation",
			desc = "Show the cooldown animation specifying the time left of the buff/debuff",
			order = 311,
		}
		Options.args["i"..i].args["iconSize"..i] = {
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
end

function EnhancedRaidFrames:SetupOptions()
	-- Set up defaults
	EnhancedRaidFrames:CreateDefaults()
	self.db = LibStub("AceDB-3.0"):New("IndicatorsDB", Defaults)

	-- Profile handling
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- Get the config up
	EnhancedRaidFrames:CreateOptions()
	local config = LibStub("AceConfig-3.0")
	config:RegisterOptionsTable("Options", Options)
	config:RegisterOptionsTable("Profiles", profiles)

	-- Add to Blizz option pane
	local dialog = LibStub("AceConfigDialog-3.0")
	self.optionsFrames = {}
	self.optionsFrames.Indicators = dialog:AddToBlizOptions("Options", "Enhanced Raid Frames")
	self.optionsFrames.Profile = dialog:AddToBlizOptions("Profiles", "Profiles", "Enhanced Raid Frames")
end
