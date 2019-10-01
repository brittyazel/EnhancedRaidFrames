-- ----------------------------------------------------------------------------
-- Raid Frame Indicators by Szandos
-- ----------------------------------------------------------------------------
RaidFrameIndicators_Global = LibStub( "AceAddon-3.0" ):NewAddon( "Indicators", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0", "AceBucket-3.0")
local RaidFrameIndicators = RaidFrameIndicators_Global


local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local f = {} -- Indicators for the frames
local playerName
local PAD = 2
local unitBuffs = {} -- Matrix to keep a list of all buffs on all units
local unitDebuffs = {} -- Matrix to keep a list of all debuffs on all units
local auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}} -- Matrix to keep all aura strings to watch for
local _
local allAuras = " "


local tooltipTimer

-------------------------------------------------------------------------
--------------------Start of Functions-----------------------------------
-------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function RaidFrameIndicators:OnInitialize()

	-- Set up config pane
	RaidFrameIndicators:SetupOptions()

	-- Get the player name
	playerName = UnitName("player")

	-- Register callbacks for profile switching
	RaidFrameIndicators.db.RegisterCallback(RaidFrameIndicators, "OnProfileChanged", "RefreshConfig")
	RaidFrameIndicators.db.RegisterCallback(RaidFrameIndicators, "OnProfileCopied", "RefreshConfig")
	RaidFrameIndicators.db.RegisterCallback(RaidFrameIndicators, "OnProfileReset", "RefreshConfig")

end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function RaidFrameIndicators:OnEnable()
	RaidFrameIndicators:RegisterEvent("PLAYER_ENTERING_WORLD")
end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function RaidFrameIndicators:OnDisable()
	-- Stop update
	RaidFrameIndicators:CancelAllTimers()

	-- Hide all indicators
	for frameName, _ in pairs(f) do
		for i = 1, 9 do
			f[frameName][i].text:SetText("")
			f[frameName][i].icon:SetTexture("")
		end
	end

end

-------------------------------------------------

function RaidFrameIndicators:PLAYER_ENTERING_WORLD()
	if RaidFrameIndicators.db.profile.enabled then
		-- Start update
		RaidFrameIndicators:CancelAllTimers()
		RaidFrameIndicators.updateTimer = RaidFrameIndicators:ScheduleRepeatingTimer("UpdateAllIndicators", 0.8) --this is so countdown text is smooth

		if not RaidFrameIndicators:IsHooked("CompactUnitFrame_UpdateAuras") then
			RaidFrameIndicators:SecureHook("CompactUnitFrame_UpdateAuras", function(frame) RaidFrameIndicators:UpdateIndicatorFrame(frame) end) --this hooks our frame update function onto the game equivalent function
		end

		RaidFrameIndicators:RefreshConfig()
	end
end

function RaidFrameIndicators:UpdateStockAuraVisibility(frame)

	if not RaidFrameIndicators.db.profile.showBuffs then
		frame.optionTable.displayBuffs = false
	else
		frame.optionTable.displayBuffs = true
	end

	if not RaidFrameIndicators.db.profile.showDebuffs then
		frame.optionTable.displayDebuffs = false
	else
		frame.optionTable.displayDebuffs = true
	end

	if not RaidFrameIndicators.db.profile.showDispelDebuffs then
		frame.optionTable.displayDispelDebuffs = false
	else
		frame.optionTable.displayDispelDebuffs = true
	end

end

-- Create the FontStrings used for indicators
function RaidFrameIndicators:CreateIndicator(frame)
	local frameName = frame:GetName()

	RaidFrameIndicators:UpdateStockAuraVisibility(frame)

	f[frameName] = {}

	-- Create indicators
	for i = 1, 9 do
		--We have to use this template to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raidframe behind it
		f[frameName][i] = CreateFrame("Button", nil, frame, "CompactAuraTemplate")

		test = f[frameName][i]
		f[frameName][i].text = f[frameName][i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f[frameName][i].icon = f[frameName][i]:CreateTexture(nil, "OVERLAY")

		f[frameName][i].text:SetPoint("CENTER", f[frameName][i], "CENTER", 0, 0)
		f[frameName][i].icon:SetPoint("CENTER", f[frameName][i], "CENTER", 0, 0)

		f[frameName][i]:SetFrameStrata("HIGH")

		f[frameName][i]:Show()

		if i == 1 then
			f[frameName][i]:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
		elseif i == 2 then
			f[frameName][i]:SetPoint("TOP", frame, "TOP", 0, -PAD)
		elseif i == 3 then
			f[frameName][i]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD)
		elseif i == 4 then
			f[frameName][i]:SetPoint("LEFT", frame, "LEFT", PAD, 0)
		elseif i == 5 then
			f[frameName][i]:SetPoint("CENTER", frame, "CENTER", 0, 0)
		elseif i == 6 then
			f[frameName][i]:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
		elseif i == 7 then
			f[frameName][i]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
		elseif i == 8 then
			f[frameName][i]:SetPoint("BOTTOM", frame, "BOTTOM", 0, PAD)
		elseif i == 9 then
			f[frameName][i]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
		end

		-- hook enter and leave for showing ability tooltips
		RaidFrameIndicators:SecureHookScript(f[frameName][i], "OnEnter", function() RaidFrameIndicators:Tooltip_OnEnter(f[frameName][i]) end)
		RaidFrameIndicators:SecureHookScript(f[frameName][i], "OnLeave", function() RaidFrameIndicators:Tooltip_OnLeave(f[frameName][i]) end)
	end

	-- Set appearance
	RaidFrameIndicators:SetIndicatorAppearance(frame)
end

-- Set the appearance of the FontStrings
function RaidFrameIndicators:SetIndicatorAppearance(frame)
	local unit = frame.unit
	local frameName = frame:GetName()

	-- Check if the frame is pointing at anything
	if not unit then return end
	if not f[frameName] then return end

	local font = media and media:Fetch('font', RaidFrameIndicators.db.profile.indicatorFont) or STANDARD_TEXT_FONT

	for i = 1, 9 do
		f[frameName][i]:SetWidth(RaidFrameIndicators.db.profile["iconSize"..i])
		f[frameName][i]:SetHeight(RaidFrameIndicators.db.profile["iconSize"..i])
		f[frameName][i].icon:SetWidth(RaidFrameIndicators.db.profile["iconSize"..i])
		f[frameName][i].icon:SetHeight(RaidFrameIndicators.db.profile["iconSize"..i])

		f[frameName][i].text:SetFont(font, RaidFrameIndicators.db.profile["size"..i], "OUTLINE")
		f[frameName][i].text:SetTextColor(RaidFrameIndicators.db.profile["color"..i].r, RaidFrameIndicators.db.profile["color"..i].g, RaidFrameIndicators.db.profile["color"..i].b, RaidFrameIndicators.db.profile["color"..i].a)

		if RaidFrameIndicators.db.profile["showIcon"..i] then
			f[frameName][i].icon:Show()
		else
			f[frameName][i].icon:Hide()
		end
	end
end

-- Update all indicators
function RaidFrameIndicators:UpdateAllIndicators()
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame) RaidFrameIndicators:UpdateIndicatorFrame(frame)  end)
end

-- Check the indicators on a frame and update the times on them
function RaidFrameIndicators:UpdateIndicatorFrame(frame)

	local unit = frame.unit

	--check to see if the bar is even targeting a unit, bail if it isn't
	--also, tanks have two bars below their frame that have a frame.unit that ends in "target" and "targettarget".
	--Normal raid members have frame.unit that says "Raid1", "Raid5", etc.
	--We don't want to put icons over these tiny little target and target of target bars
	--Also, in 8.2.5 blizzard unified the nameplate code with the raid frame code. Don't display icons on nameplates
	if not unit or string.find(unit, "target") or string.find(unit, "nameplate") then
		return
	end

	local currentTime = GetTime()
	local frameName = frame:GetName()

	-- Check if the indicator frame exists, else create it
	if not f[frameName] then
		RaidFrameIndicators:CreateIndicator(frame)
	end

	-- Check if unit is alive/connected
	if (not UnitIsConnected(unit)) or UnitIsDeadOrGhost(frame.displayedUnit) then
		for i = 1, 9 do
			-- Hide indicators
			f[frameName][i].text:SetText("")
			f[frameName][i].icon:SetTexture("")
		end
		return
	end

	-- Update unit auras
	RaidFrameIndicators:UpdateUnitAuras(unit)

	-- Loop over the indicators and see if we get a hit
	for i = 1, 9 do

		local remainingTime, remainingTimeAsText, showIndicator, count, duration, expirationTime, castBy, icon, debuffType, n

		-- If we only are to show the indicator on me, then don't bother if I'm not the unit
		if RaidFrameIndicators.db.profile["me"..i] then
			local uName, uRealm
			uName, uRealm = UnitName(unit)
			if uName ~= playerName or uRealm ~= nil then
				showIndicator = false
			end
		end


		-- Go through the aura strings
		for _, auraName in ipairs(auraStrings[i]) do -- Grab each line
			-- Check if the aura exist on the unit
			for j = 1, unitBuffs[unit].len do -- Check buffs
				if tonumber(auraName) then  -- Use spell id
					if unitBuffs[unit][j].spellId == tonumber(auraName) then n = j end
				elseif unitBuffs[unit][j].auraName == auraName then -- Hit on auraName
					n = j
				end
				if n and unitBuffs[unit][j].castBy == "player" then break end -- Keep looking if it's not cast by the player
			end
			if n then
				count = unitBuffs[unit][n].count
				duration = unitBuffs[unit][n].duration
				expirationTime = unitBuffs[unit][n].expirationTime
				castBy = unitBuffs[unit][n].castBy
				icon = unitBuffs[unit][n].icon
				f[frameName][i].index = unitBuffs[unit][n].index
				f[frameName][i].buff = true
			else
				for j = 1, unitDebuffs[unit].len do -- Check debuffs
					if tonumber(auraName) then  -- Use spell id
						if unitDebuffs[unit][j].spellId == tonumber(auraName) then n = j end
					elseif unitDebuffs[unit][j].auraName == auraName then -- Hit on auraName
						n = j
					elseif unitDebuffs[unit][j].debuffType == auraName then -- Hit on debufftype
						n = j
					end
					if n and unitDebuffs[unit][j].castBy == "player" then break end -- Keep looking if it's not cast by the player
				end
				if n then
					count = unitDebuffs[unit][n].count
					duration = unitBuffs[unit][n].duration
					expirationTime = unitDebuffs[unit][n].expirationTime
					castBy = unitDebuffs[unit][n].castBy
					icon = unitDebuffs[unit][n].icon
					debuffType = unitDebuffs[unit][n].debuffType
					f[frameName][i].index = unitDebuffs[unit][n].index
				end
			end
			if auraName:upper() == "PVP" then -- Check if we want to show pvp flag
				if UnitIsPVP(unit) then
					count = 0
					expirationTime = 0
					castBy = "player"
					n = -1
					local factionGroup = UnitFactionGroup(unit)
					if factionGroup then icon = "Interface\\GroupFrame\\UI-Group-PVP-"..factionGroup end
					f[frameName][i].index = -1
				end
			elseif auraName:upper() == "TOT" then -- Check if we want to show ToT flag
				if UnitIsUnit (unit, "targettarget") then
					count = 0
					expirationTime = 0
					castBy = "player"
					n = -1
					icon = "Interface\\Icons\\Ability_Hunter_SniperShot"
					f[frameName][i].index = -1
				end
			end

			if n then -- We found a matching spell
				-- If we only are to show spells cast by me, make sure the spell is
				if (RaidFrameIndicators.db.profile["mine"..i] and castBy ~= "player") then
					n = nil
					icon = ""
				else
					if not RaidFrameIndicators.db.profile["showIcon"..i] then icon = "" end -- Hide icon
					if expirationTime == 0 then -- No expiration time = permanent
						if not RaidFrameIndicators.db.profile["showIcon"..i] then
							remainingTimeAsText = "■" -- Only show the blob if we don't show the icon
						end
					else
						if RaidFrameIndicators.db.profile["showText"..i] then
							-- Pretty formating of the remaining time text
							remainingTime = expirationTime - currentTime
							if remainingTime > 60 then
								remainingTimeAsText = string.format("%.0f", (remainingTime / 60)).."m" -- Show minutes without seconds
							elseif remainingTime >= 1 then
								remainingTimeAsText = string.format("%.0f",remainingTime) -- Show seconds without decimals
							end
						else
							remainingTimeAsText = ""
						end

					end

					-- Add stack count
					if RaidFrameIndicators.db.profile["stack"..i] and count > 0 then
						if RaidFrameIndicators.db.profile["showText"..i] and expirationTime > 0 then
							remainingTimeAsText = count.."-"..remainingTimeAsText
						else
							remainingTimeAsText = count
						end
					end

					-- Set color
					if RaidFrameIndicators.db.profile["stackColor"..i] then -- Color by stack
						if count == 1 then
							f[frameName][i].text:SetTextColor(1,0,0,1)
						elseif count == 2 then
							f[frameName][i].text:SetTextColor(1,1,0,1)
						else
							f[frameName][i].text:SetTextColor(0,1,0,1)
						end
					elseif RaidFrameIndicators.db.profile["debuffColor"..i] then -- Color by debuff type
						if debuffType then
							if debuffType == "Curse" then
								f[frameName][i].text:SetTextColor(0.6,0,1,1)
							elseif debuffType == "Disease" then
								f[frameName][i].text:SetTextColor(0.6,0.4,0,1)
							elseif debuffType == "Magic" then
								f[frameName][i].text:SetTextColor(0.2,0.6,1,1)
							elseif debuffType == "Poison" then
								f[frameName][i].text:SetTextColor(0,0.6,0,1)
							end
						end
					elseif RaidFrameIndicators.db.profile["colorByTime"..i] then -- Color by remaining time
						if remainingTime and remainingTime < 3 then
							f[frameName][i].text:SetTextColor(1,0,0,1)
						elseif remainingTime and remainingTime < 5 then
							f[frameName][i].text:SetTextColor(1,1,0,1)
						else
							f[frameName][i].text:SetTextColor(RaidFrameIndicators.db.profile["color"..i].r, RaidFrameIndicators.db.profile["color"..i].g, RaidFrameIndicators.db.profile["color"..i].b, RaidFrameIndicators.db.profile["color"..i].a)
						end
					end

					break -- We found a match, so no need to continue the for loop
				end
			end
		end

		-- Only show when it's missing?
		if RaidFrameIndicators.db.profile["missing"..i] then
			icon = ""
			remainingTimeAsText = ""
			if not n then -- No n means we didn't find the spell
				remainingTimeAsText = "■"
			end
		end



		-- Show the text
		f[frameName][i].text:SetText(remainingTimeAsText)

		-- Show the icon
		f[frameName][i].icon:SetTexture(icon)

		--set cooldown animation
		if expirationTime and expirationTime ~= 0 then
			local startTime = expirationTime - duration;
			CooldownFrame_Set(f[frameName][i].cooldown, startTime, duration, true)
		else
			CooldownFrame_Clear(f[frameName][i].cooldown);
		end

	end

end



-- Get all unit auras
function RaidFrameIndicators:UpdateUnitAuras(unit)

	-- Create tables for the unit
	if not unitBuffs[unit] then unitBuffs[unit] = {} end
	if not unitDebuffs[unit] then unitDebuffs[unit] = {} end

	-- Get all unit buffs
	local auraName, icon, count, duration, expirationTime, castBy, debuffType, spellId
	local i = 1
	local j = 1

	while true do
		auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellId = UnitBuff(unit, i)

		if not spellId then
			break
		end

		if string.find(allAuras, "+"..auraName.."+") or string.find(allAuras, "+"..spellId.."+") then -- Only add the spell if we're watching for it
			if not unitBuffs[unit][j] then unitBuffs[unit][j] = {} end
			unitBuffs[unit][j].auraName = auraName
			unitBuffs[unit][j].spellId = spellId
			unitBuffs[unit][j].count = count
			unitBuffs[unit][j].duration = duration
			unitBuffs[unit][j].expirationTime = expirationTime
			unitBuffs[unit][j].castBy = castBy
			unitBuffs[unit][j].icon = icon
			unitBuffs[unit][j].index = i
			j = j + 1
		end
		i = i + 1
	end
	unitBuffs[unit].len = j -1

	-- Get all unit debuffs
	i = 1
	j = 1
	while true do
		auraName, icon, count, debuffType, _, expirationTime, castBy, _, _, spellId  = UnitDebuff(unit, i)

		if not spellId then
			break
		end

		if string.find(allAuras, "+"..auraName.."+") or string.find(allAuras, "+"..spellId.."+") or string.find(allAuras, "+"..tostring(debuffType).."+") then -- Only add the spell if we're watching for it
			if not unitDebuffs[unit][j] then unitDebuffs[unit][j] = {} end
			unitDebuffs[unit][j].auraName = auraName
			unitDebuffs[unit][j].spellId = spellId
			unitDebuffs[unit][j].count = count
			unitDebuffs[unit][j].expirationTime = expirationTime
			unitDebuffs[unit][j].castBy = castBy
			unitDebuffs[unit][j].icon = icon
			unitDebuffs[unit][j].index = i
			unitDebuffs[unit][j].debuffType= debuffType
			j = j + 1
		end
		i = i + 1
	end
	unitDebuffs[unit].len = j -1
end



-------------------------------
---Tooltip Code
-------------------------------

-- Hook CompactUnitFrame_OnEnter and OnLeave so we know if a tooltip is showing or not.
function RaidFrameIndicators:Tooltip_OnEnter(buffFrame)
	local frame = buffFrame:GetParent() --this is the parent raid frame that holds all the buffFrames
	local index = buffFrame.index
	local buff = buffFrame.buff

	local displayedUnit = frame.displayedUnit

	-- Set the tooltip
	if index and index ~= -1 and buffFrame.icon:GetTexture() then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(buffFrame, "ANCHOR_CURSOR")
		if buff then
			GameTooltip:SetUnitBuff(displayedUnit, index)
		else
			GameTooltip:SetUnitDebuff(displayedUnit, index)
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		UnitFrame_UpdateTooltip(frame)
	end

	GameTooltip:Show()

end

function RaidFrameIndicators:Tooltip_OnLeave(buffFrame)
	GameTooltip:Hide()
end

----------------------------------
----------------------------------


-- Used to update everything that is affected by the configuration
function RaidFrameIndicators:RefreshConfig()

	-- Set the appearance of the indicators
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame) RaidFrameIndicators:SetIndicatorAppearance(frame) end)

	-- Show/hide stock icons
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
		RaidFrameIndicators:UpdateStockAuraVisibility(frame)
	end)

	-- Format aura strings
	allAuras = " "

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(RaidFrameIndicators.db.profile["auras"..i], "[^\n]+") do -- Grab each line
			auraName = string.gsub(auraName, "^%s*(.-)%s*$", "%1") -- Strip any whitespaces
			allAuras = allAuras.."+"..auraName.."+" -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			auraStrings[i][j] = auraName
			j = j + 1
		end
	end

end
