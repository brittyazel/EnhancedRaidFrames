-- ----------------------------------------------------------------------------
-- Raid Frame Indicators by Szandos
-- ----------------------------------------------------------------------------
RaidFrameIndicators_Global = LibStub( "AceAddon-3.0" ):NewAddon( "Indicators", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0", "AceBucket-3.0")
local RaidFrameIndicators = RaidFrameIndicators_Global


local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local f = {} -- Indicators for the frames
local playerName
local pad = 2
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

	if RaidFrameIndicators.db.profile.enabled then
		-- Start update
		RaidFrameIndicators.updateTimer = RaidFrameIndicators:ScheduleRepeatingTimer("UpdateAllIndicators", 0.8)
		RaidFrameIndicators:RefreshConfig()
	end

	RaidFrameIndicators:SecureHook("CompactUnitFrame_UpdateBuffs", function(frame) RaidFrameIndicators:HideBuffs(frame) end)
	RaidFrameIndicators:SecureHook("CompactUnitFrame_UpdateDebuffs", function(frame) RaidFrameIndicators:HideDebuffs(frame) end)
	RaidFrameIndicators:SecureHook("CompactUnitFrame_UpdateDispellableDebuffs", function(frame) RaidFrameIndicators:HideDispelDebuffs(frame) end)

	self:RegisterBucketEvent({"COMBAT_LOG_EVENT_UNFILTERED"}, .1, "UpdateAllIndicators")

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



-- Hide buff/debuff icons
function RaidFrameIndicators:HideBuffs(frame)
	if frame.optionTable.displayBuffs then -- Normal frame
		if not RaidFrameIndicators.db.profile.showBuffs then
			CompactUnitFrame_HideAllBuffs(frame)
		end
	end
end


function RaidFrameIndicators:HideDebuffs(frame)
	if frame.optionTable.displayBuffs then -- Normal frame
		if not RaidFrameIndicators.db.profile.showDebuffs then
			CompactUnitFrame_HideAllDebuffs(frame)
		end
	end
end


function RaidFrameIndicators:HideDispelDebuffs(frame)
	if frame.optionTable.displayBuffs then -- Normal frame
		if not RaidFrameIndicators.db.profile.showDispelDebuffs then
			CompactUnitFrame_HideAllDispelDebuffs(frame)
		end
	end
end


-- Create the FontStrings used for indicators
function RaidFrameIndicators:CreateIndicator(frame)
	local frameName = frame:GetName()

	f[frameName] = {}

	-- Create indicators
	for i = 1, 9 do
		f[frameName][i] = {}
		f[frameName][i].text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f[frameName][i].icon = frame:CreateTexture(nil, "OVERLAY")
		if i == 1 then
			f[frameName][i].text:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
			f[frameName][i].icon:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
		end
		if i == 2 then
			f[frameName][i].text:SetPoint("TOP", frame, "TOP", 0, -pad)
			f[frameName][i].icon:SetPoint("TOP", frame, "TOP", 0, -pad)
		end
		if i == 3 then
			f[frameName][i].text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -pad, -pad)
			f[frameName][i].icon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -pad, -pad)
		end
		if i == 4 then
			f[frameName][i].text:SetPoint("LEFT", frame, "LEFT", pad, 0)
			f[frameName][i].icon:SetPoint("LEFT", frame, "LEFT", pad, 0)
		end
		if i == 5 then
			f[frameName][i].text:SetPoint("CENTER", frame, "CENTER", 0, 0)
			f[frameName][i].icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
		end
		if i == 6 then
			f[frameName][i].text:SetPoint("RIGHT", frame, "RIGHT", -pad, 0)
			f[frameName][i].icon:SetPoint("RIGHT", frame, "RIGHT", -pad, 0)
		end
		if i == 7 then
			f[frameName][i].text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad, pad)
			f[frameName][i].icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad, pad)
		end
		if i == 8 then
			f[frameName][i].text:SetPoint("BOTTOM", frame, "BOTTOM", 0, pad)
			f[frameName][i].icon:SetPoint("BOTTOM", frame, "BOTTOM", 0, pad)
		end
		if i == 9 then
			f[frameName][i].text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)
			f[frameName][i].icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)
		end
	end

	-- Set appearance
	RaidFrameIndicators:SetIndicatorAppearance(frame)

	-- hook enter and leave for showing ability tooltips
	RaidFrameIndicators:SecureHookScript(frame, "OnEnter", function() RaidFrameIndicators:Tooltip_OnEnter(frame) end)
	RaidFrameIndicators:SecureHookScript(frame, "OnLeave", function() RaidFrameIndicators:Tooltip_OnLeave(frame) end)
end

-- Set the appearance of the FontStrings
function RaidFrameIndicators:SetIndicatorAppearance(frame)
	local unit = frame.unit
	local frameName = frame:GetName()

	-- Check if the frame is poiting at anything
	if not unit then return end
	if not f[frameName] then return end

	local font = media and media:Fetch('font', RaidFrameIndicators.db.profile.indicatorFont) or STANDARD_TEXT_FONT

	for i = 1, 9 do
		f[frameName][i].text:SetFont(font, RaidFrameIndicators.db.profile["size"..i], "OUTLINE")
		f[frameName][i].text:SetTextColor(RaidFrameIndicators.db.profile["color"..i].r, RaidFrameIndicators.db.profile["color"..i].g, RaidFrameIndicators.db.profile["color"..i].b, RaidFrameIndicators.db.profile["color"..i].a)
		f[frameName][i].icon:SetWidth(RaidFrameIndicators.db.profile["iconSize"..i])
		f[frameName][i].icon:SetHeight(RaidFrameIndicators.db.profile["iconSize"..i])
		if RaidFrameIndicators.db.profile["showIcon"..i] then
			f[frameName][i].icon:Show()
		else
			f[frameName][i].icon:Hide()
		end
	end
end

-- Update all indicators
function RaidFrameIndicators:UpdateAllIndicators()
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame) RaidFrameIndicators:UpdateIndicatorFrame(frame) end)
end


-- Check the indicators on a frame and update the times on them
function RaidFrameIndicators:UpdateIndicatorFrame(frame)

	local currentTime = GetTime()
	local unit = frame.unit
	local frameName = frame:GetName()

	-- Check if the frame is pointing at anything
	if not unit then
		return
	end

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
	local remainingTime, remainingTimeAsText, showIndicator, count, expirationTime, castBy, icon, debuffType, n
	for i = 1, 9 do
		remainingTime = nil
		remainingTimeAsText = ""
		icon = ""
		showIndicator = true
		n = nil

		-- If we only are to show the indicator on me, then don't bother if I'm not the unit
		if RaidFrameIndicators.db.profile["me"..i] then
			local uName, uRealm
			uName, uRealm = UnitName(unit)
			if uName ~= playerName or uRealm ~= nil then
				showIndicator = false
			end
		end
		if showIndicator then

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

		end

		-- Show the text
		f[frameName][i].text:SetText(remainingTimeAsText)

		-- Show the icon
		f[frameName][i].icon:SetTexture(icon)
	end

end



-- Get all unit auras
function RaidFrameIndicators:UpdateUnitAuras(unit)

	-- Create tables for the unit
	if not unitBuffs[unit] then unitBuffs[unit] = {} end
	if not unitDebuffs[unit] then unitDebuffs[unit] = {} end

	-- Get all unit buffs
	local auraName, icon, count, expirationTime, castBy, debuffType, spellId
	local i = 1
	local j = 1

	while true do
		auraName, icon, count, _, _, expirationTime, castBy, _, _, spellId = UnitBuff(unit, i)

		if not spellId then
			break
		end

		if string.find(allAuras, "+"..auraName.."+") or string.find(allAuras, "+"..spellId.."+") then -- Only add the spell if we're watching for it
			if not unitBuffs[unit][j] then unitBuffs[unit][j] = {} end
			unitBuffs[unit][j].auraName = auraName
			unitBuffs[unit][j].spellId = spellId
			unitBuffs[unit][j].count = count
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
function RaidFrameIndicators:Tooltip_OnEnter(frame)
	local unit = frame.unit
	local frameName = frame:GetName()

	-- Check if the frame is poiting at anything
	if not unit then return end
	if not f[frameName] then return end

	if string.find(frameName, "Compact") then

		--safety check to kill any running indicator before starting a new one
		--this would be because the OnLeave function didn't get called or something
		RaidFrameIndicators:CancelTimer(tooltipTimer)

		--set a timer to run in a loop as long as we are inside a given frame. This is because each indicator isn't its own frame, but rather are all contained in the one frame thus have to share a single OnEnter event
		tooltipTimer = RaidFrameIndicators:ScheduleRepeatingTimer('SetTooltip', .1, frame)
	end
end

function RaidFrameIndicators:Tooltip_OnLeave(frame)
	--kill our running timer once we leave the raid frame
	RaidFrameIndicators:CancelTimer(tooltipTimer)
end

-- Sets the tooltip to the spell currently hovered over
function RaidFrameIndicators:SetTooltip(frame)
	local x, y = GetCursorPosition()
	local s = frame:GetEffectiveScale()
	local fL = frame:GetLeft()
	local fR = frame:GetRight()
	local fT = frame:GetTop()
	local fB = frame:GetBottom()
	local frameName = frame:GetName()
	local index, buff

	x = x/s
	y = y/s

	for i = 1, 9 do -- Loop over all indicators
		if f[frameName][i].icon:GetTexture() and RaidFrameIndicators.db.profile["showTooltip"..i] then -- Only show a tooltip if we have an icon
			-- Check if we are hovering above the area where an icon is shown
			local size = RaidFrameIndicators.db.profile["iconSize"..i]
			if (i == 1 and (x > fL + pad) and (x < fL + pad + size) and (y > fT - pad - size) and (y < fT - pad)) or -- Top left
					(i == 2 and (x > fL + (fR - fL - size)/2) and (x < fL + (fR -fL + size)/2) and (y > fT - pad - size) and (y < fT - pad)) or -- Top mid
					(i == 3 and (x > fR - pad - size) and (x < fR - pad) and (y > fT - pad - size) and (y < fT - pad)) or -- Top right
					(i == 4 and (x > fL + pad) and (x < fL + pad + size) and (y > fB + (fT - fB - size)/2) and (y < fB + (fT - fB + size)/2)) or -- Mid left
					(i == 5 and (x > fL + (fR - fL - size)/2) and (x < fL + (fR -fL + size)/2) and (y > fB + (fT - fB - size)/2) and (y < fB + (fT - fB + size)/2)) or -- Mid mid
					(i == 6 and (x > fR - pad - size) and (x < fR - pad) and (y > fB + (fT - fB - size)/2) and (y < fB + (fT - fB + size)/2)) or -- Mid right
					(i == 7 and (x > fL + pad) and (x < fL + pad + size) and (y > fB + pad) and (y < fB + pad + size)) or -- Bottom left
					(i == 8 and (x > fL + (fR - fL - size)/2) and (x < fL + (fR -fL + size)/2) and (y > fB + pad) and (y < fB + pad + size)) or -- Bottom mid
					(i == 9 and (x > fR - pad - size) and (x < fR - pad) and (y > fB + pad) and (y < fB + pad + size)) then -- Bottom right
				index = f[frameName][i].index
				buff = f[frameName][i].buff
				break -- No need to continue the for loop, the mouse can only be over one icon at a time
			end
		end
	end

	-- Set the tooltip
	if index and index ~= -1 then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		if buff then
			GameTooltip:SetUnitBuff(frame.displayedUnit, index)
		else
			GameTooltip:SetUnitDebuff(frame.displayedUnit, index)
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		UnitFrame_UpdateTooltip(frame)
	end
end

----------------------------------
----------------------------------


-- Used to update everything that is affected by the configuration
function RaidFrameIndicators:RefreshConfig()

	-- Set the appearance of the indicators
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame) RaidFrameIndicators:SetIndicatorAppearance(frame) end)

	-- Show/hide default icons
	CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
		RaidFrameIndicators:HideDebuffs(frame)
		RaidFrameIndicators:HideDispelDebuffs(frame)
		RaidFrameIndicators:HideBuffs(frame)
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
