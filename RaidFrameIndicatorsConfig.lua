local Defaults = {}
local Options = {}

local RaidFrameIndicators = RaidFrameIndicators_Global


function RaidFrameIndicators:CreateDefaults ()
	Defaults.profile = {
		indicatorFont = "Arial Narrow",
		showIcons = true,
		enabled = true,
	}
	for i = 1, 9 do
		Defaults.profile["auras"..i] = ""
		Defaults.profile["size"..i] = 10
		Defaults.profile["color"..i] = {r = 1, g = 1, b = 1, a = 1,}
		Defaults.profile["mine"..i] = false
		Defaults.profile["stack"..i] = true
		Defaults.profile["stackColor"..i] = false
		Defaults.profile["debuffColor"..i] = false
		Defaults.profile["colorByTime"..i] = false
		Defaults.profile["missing"..i] = false
		Defaults.profile["me"..i] = false
		Defaults.profile["showText"..i] = true
		Defaults.profile["showDecimals"..i] = true
		Defaults.profile["showIcon"..i] = true
		Defaults.profile["showTooltip"..i] = true
		Defaults.profile["iconSize"..i] = 10
	end
end

function RaidFrameIndicators:CreateOptions ()
	Options = {
		type = 'group',
		childGroups = 'tree',
		get = function(item) return RaidFrameIndicators.db.profile[item[#item]] end,
		set = function(item, value) RaidFrameIndicators.db.profile[item[#item]] = value; RaidFrameIndicators:RefreshConfig() end,
		args  = {

			showBuffs = {
				type = "toggle",
				name = "Show Buff Icons",
				desc = "Show the standard raid frame buff icons",
				order = 11,
			},
			showDebuffs = {
				type = "toggle",
				name = "Show Debuff Icons",
				desc = "Show the standard raid frame debuff icons",
				order = 13,
			},
			showDispelDebuffs = {
				type = "toggle",
				name = "Show Dispellable Icons",
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
			enabled = {
				type = "toggle",
				name = "Enabled",
				desc = "Enable/Disable indicators",
				order = 18,
				set = function(item, value)
					RaidFrameIndicators.db.profile[item[#item]] = value
					if value == true then
						RaidFrameIndicators:OnEnable()
					else
						RaidFrameIndicators:OnDisable()
					end
				end,
			}
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
			name = "Text Counter",
			order = 100,
		}
		Options.args["i"..i].args["showText"..i] = {
			type = "toggle",
			name = "Show text counter",
			desc = "Show a text counter specifying the time left of the buff/debuff",
			order = 110,
		}
		Options.args["i"..i].args["showDecimals"..i] = {
			type = "toggle",
			name = "Show decimals",
			desc = "Show decimals on the text counter",
			disabled = function () return (not RaidFrameIndicators.db.profile["showText"..i]) end,
			order = 115,
		}
		Options.args["i"..i].args["size"..i] = {
			type = "range",
			name = "Size",
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
			disabled = function () return RaidFrameIndicators.db.profile["stackColor"..i] end,
			order = 165,
		}
		Options.args["i"..i].args["color"..i] = {
			type = "color",
			name = "Color",
			desc = "Color of the indicator",
			get = function(item)
				local t = RaidFrameIndicators.db.profile[item[#item]]
				return t.r, t.g, t.b, t.a
			end,
			set = function(item, r, g, b, a)
				local t = RaidFrameIndicators.db.profile[item[#item]]
				t.r, t.g, t.b, t.a = r, g, b, a
				RaidFrameIndicators:RefreshConfig()
			end,
			disabled = function () return (RaidFrameIndicators.db.profile["stackColor"..i] or RaidFrameIndicators.db.profile["debuffColor"..i]) end,
			order = 170,
		}
		Options.args["i"..i].args["colorByTime"..i] = {
			type = "toggle",
			name = "Color by remaining time",
			desc = "Color the counter based on remaining time (5s+: Selected color, 3-5s: Yellow, 3s-: Red)",
			disabled = function () return (RaidFrameIndicators.db.profile["stackColor"..i] or RaidFrameIndicators.db.profile["debuffColor"..i]) end,
			order = 180,
		}
		Options.args["i"..i].args.stackHeader = {
			type = "header",
			name = "Stack Size",
			order = 200,
		}
		Options.args["i"..i].args["stack"..i] = {
			type = "toggle",
			name = "Show stack size",
			desc = "Show stack size for buffs/debuffs that stack",
			order = 210,
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
		Options.args["i"..i].args["showTooltip"..i] = {
			type = "toggle",
			name = "Show tooltip",
			desc = "Show tooltip for the buff/debuff",
			disabled = function () return (not RaidFrameIndicators.db.profile["showIcon"..i]) end,
			order = 315,
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

local SlashCommands = {
        type    = "group",
	args  = {
		enable = {
			type = "execute",
			name = "enable",
			desc = "Enable indicators",
			func = function() RaidFrameIndicators.db.profile.enabled = true; RaidFrameIndicators:OnEnable() end,
		},
		disable = {
			type = "execute",
			name = "disable",
			desc = "Disable indicators",
			func = function() RaidFrameIndicators.db.profile.enabled = false; RaidFrameIndicators:OnDisable() end,
		},
		config = {
			type = "execute",
			name = "config",
			desc = "Show config",
			func = function() RaidFrameIndicators:ShowConfig() end,
		},
	}
}

function RaidFrameIndicators:ShowConfig()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Profile)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Indicators)
end

function RaidFrameIndicators:SetupOptions()
	-- Set up defaults
	RaidFrameIndicators:CreateDefaults()
	self.db = LibStub("AceDB-3.0"):New("IndicatorsDB", Defaults)
	
	-- Profile handling
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	-- Get the config up
	RaidFrameIndicators:CreateOptions()
	local config = LibStub("AceConfig-3.0")
	config:RegisterOptionsTable("Raid Frame Indicators", Options)
	config:RegisterOptionsTable("Raid Frame Indicators Profiles", profiles)
	
	-- Register slash commands
	config:RegisterOptionsTable("Raid Frame Indicators Options", SlashCommands, {"indicators", "raidrfameindicators"})
	
	-- Add to Blizz option pane
	local dialog = LibStub("AceConfigDialog-3.0")
	self.optionsFrames = {}
	self.optionsFrames.Indicators = dialog:AddToBlizOptions("Raid Frame Indicators","Raid Frame Indicators")
	self.optionsFrames.Profile = dialog:AddToBlizOptions("Raid Frame Indicators Profiles","Profiles", "Raid Frame Indicators")
end