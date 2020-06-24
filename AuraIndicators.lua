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
--Copyright for Enhanced Raid Frames is held by Britt Yazel (aka Soyier), 2017-2020.

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local unitAuras = {} -- Matrix to keep a list of all auras on all units

EnhancedRaidFrames.iconCache = {}
EnhancedRaidFrames.iconCache["poison"] = 132104
EnhancedRaidFrames.iconCache["disease"] = 132099
EnhancedRaidFrames.iconCache["curse"] = 132095
EnhancedRaidFrames.iconCache["magic"] = 135894

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:SetStockIndicatorVisibility(frame)
	local profile = EnhancedRaidFrames.db.profile

	if not profile.showBuffs then
		CompactUnitFrame_HideAllBuffs(frame)
	end

	if not profile.showDebuffs then
		CompactUnitFrame_HideAllDebuffs(frame)
	end

	if not profile.showDispelDebuffs then
		CompactUnitFrame_HideAllDispelDebuffs(frame)
	end
end

-- Create the FontStrings used for indicators
function EnhancedRaidFrames:CreateIndicators(frame)
	local profile = EnhancedRaidFrames.db.profile
	frame.ERFIndicators = {}

	-- Create indicators
	for i = 1, 9 do
		--We have to use CompactAuraTemplate to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raid frame behind it
		frame.ERFIndicators[i] = CreateFrame("Button", nil, frame, "CompactAuraTemplate")

		--create local pointer for readability
		local indicatorFrame = frame.ERFIndicators[i]

		--register clicks
		indicatorFrame:RegisterForClicks("LeftButtonDown", "RightButtonUp")
		--set proper frame level
		indicatorFrame:SetFrameStrata("HIGH")

		--create font strings for both layers, the normal layer and the cooldown frame layer
		--the font string is further modified in SetIndicatorAppearance()
		indicatorFrame.cd_textPtr = indicatorFrame.cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we don't show the animation, text should be on the parent frame
		indicatorFrame.cd_textPtr:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)
		indicatorFrame.normal_textPtr = indicatorFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we don't show the cooldown animation or the icon, text should be on the parent frame
		indicatorFrame.normal_textPtr:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)

		--create a pointer at indicatorFrame.text that will be our handle going forward to our two string pointers
		indicatorFrame.text = indicatorFrame.normal_textPtr --set initial pointer to indicatorFrame.text

		--mark the position of this particular frame for use later (i.e. 1->9)
		indicatorFrame.position = i

		--hook enter and leave for showing ability tooltips
		EnhancedRaidFrames:SecureHookScript(indicatorFrame, "OnEnter", function() EnhancedRaidFrames:Tooltip_OnEnter(indicatorFrame) end)
		EnhancedRaidFrames:SecureHookScript(indicatorFrame, "OnLeave", function() GameTooltip:Hide() end)
	end

	--set our initial indicator appearance
	EnhancedRaidFrames:SetIndicatorAppearance(frame)
end

-- Set the appearance of the Indicator
function EnhancedRaidFrames:SetIndicatorAppearance(frame)
	local profile = EnhancedRaidFrames.db.profile

	-- Check if the frame has an ERFIndicators table or if we have a frame unit, this is just for safety
	if not frame.ERFIndicators or not frame.unit then
		return
	end

	for i = 1, 9 do
		--create local pointer for readability
		local indicatorFrame = frame.ERFIndicators[i]

		--set icon size
		indicatorFrame:SetWidth(profile["indicatorSize"..i])
		indicatorFrame:SetHeight(profile["indicatorSize"..i])

		--------------------------------------

		--set indicator frame position
		local PAD = 1
		local iconVerticalOffset = profile["indicatorVerticalOffset"..i] * frame:GetHeight()
		local iconHorizontalOffset = profile["indicatorHorizontalOffset"..i] * frame:GetWidth()

		--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
		local powerBarVertOffset
		if frame.powerBar:IsShown() then
			powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
		else
			powerBarVertOffset = 0
		end

		indicatorFrame:ClearAllPoints()
		if i == 1 then
			indicatorFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 2 then
			indicatorFrame:SetPoint("TOP", frame, "TOP", 0 + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 3 then
			indicatorFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 4 then
			indicatorFrame:SetPoint("LEFT", frame, "LEFT", PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 5 then
			indicatorFrame:SetPoint("CENTER", frame, "CENTER", 0 + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 6 then
			indicatorFrame:SetPoint("RIGHT", frame, "RIGHT", -PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 7 then
			indicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		elseif i == 8 then
			indicatorFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0 + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		elseif i == 9 then
			indicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		end

		--------------------------------------

		--set font size, shape, font, and switch our pointer if necessary
		local font = (media and media:Fetch('font', profile.indicatorFont)) or STANDARD_TEXT_FONT

		--switch the pointer for the text overlay
		if not profile["showCountdownSwipe"..i] then
			indicatorFrame.text:SetText("") --clear previous text pointer
			indicatorFrame.text = indicatorFrame.normal_textPtr --switch indicatorFrame.text to point to normal_textPtr
			indicatorFrame.text:SetFont(font, profile["textSize"..i], "OUTLINE")
		else
			indicatorFrame.text:SetText("") --clear previous text pointer
			indicatorFrame.text = indicatorFrame.cd_textPtr --switch indicatorFrame.text to point to cd_textPtr
			indicatorFrame.text:SetFont(font, profile["textSize"..i], "OUTLINE")
		end

		--clear any animations
		ActionButton_HideOverlayGlow(indicatorFrame)
		CooldownFrame_Clear(indicatorFrame.cooldown)
	end
end


------------------------------------------------
--------------- Process Indicators -------------
------------------------------------------------

function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
	local profile = EnhancedRaidFrames.db.profile

	--check to see if the bar is even targeting a unit, bail if it isn't
	--also, tanks have two bars below their frame that have a frame.unit that ends in "target" and "targettarget".
	--Normal raid members have frame.unit that says "Raid1", "Raid5", etc.
	--We don't want to put icons over these tiny little target and target of target bars
	--Also, in 8.2.5 blizzard unified the nameplate code with the raid frame code. Don't display icons on nameplates
	if not frame.unit or string.find(frame.unit, "target") or string.find(frame.unit, "nameplate") or not CompactRaidFrameContainer:IsShown() then
		return
	end

	EnhancedRaidFrames:SetStockIndicatorVisibility(frame)

	-- Check if the indicator frame exists, else create it
	if not frame.ERFIndicators then
		EnhancedRaidFrames:CreateIndicators(frame)
	end

	if setAppearance then
		EnhancedRaidFrames:SetIndicatorAppearance(frame)
	end

	-- Update unit auras
	EnhancedRaidFrames:UpdateUnitAuras(frame.unit)

	-- Loop over all 9 indicators and process them individually
	for i = 1, 9 do
		--create local pointer for readability
		local indicatorFrame = frame.ERFIndicators[i]
		-- this is the meat of our processing loop
		EnhancedRaidFrames:ProcessIndicator(indicatorFrame, frame.unit)
	end
end

-- process a single indicator and apply visuals
function EnhancedRaidFrames:ProcessIndicator(indicatorFrame, unit)
	local profile = EnhancedRaidFrames.db.profile

	local foundAura, icon, count, duration, expirationTime, debuffType, castBy, auraIndex, auraType, _

	--reset auraIndex and auraType for tooltip
	indicatorFrame.auraIndex = nil
	indicatorFrame.auraType = nil

	-- if we only are to show the indicator on me, then don't bother if I'm not the unit
	if profile["me"..indicatorFrame.position] then
		local unitName, unitRealm = UnitName(unit)
		if unitName ~= UnitName("player") or unitRealm ~= nil then
			return
		end
	end

	--------------------------------------------------------
	--- parse each aura and find the information of each ---
	--------------------------------------------------------

	for _, auraName in pairs(EnhancedRaidFrames.auraStrings[indicatorFrame.position]) do
		--if there's no auraName (i.e. the user never specified anything to go in this spot), stop here there's no need to keep going
		if not auraName then
			break
		end

		-- query the available information for a given indicator and aura
		foundAura, icon, count, duration, expirationTime, debuffType, castBy, auraIndex, auraType = EnhancedRaidFrames:QueryAuraInfo(auraName, unit)

		-- add spell icon info to cache in case we need it later on
		if icon and not EnhancedRaidFrames.iconCache[auraName] then
			EnhancedRaidFrames.iconCache[auraName] = icon
		end

		-- when tracking multiple things, this determines "where" we stop in the list
		-- if we find the aura, we can stop querying down the list
		if foundAura then
			-- we want to stop only when castBy == "player" if we are tracking "mine only"
			if not profile["mine"..indicatorFrame.position] or (profile["mine"..indicatorFrame.position] and castBy == "player") then
				break
			end
		end
	end

	------------------------------------------------------
	------- output visuals to the indicator frame --------
	------------------------------------------------------

	-- if we find the spell and we don't only want to show when it is missing
	if foundAura and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and not profile["missing"..indicatorFrame.position] then
		-- calculate remainingTime and round down, this is how the game seems to do it
		local remainingTime = floor(expirationTime - GetTime())

		-- set auraIndex and auraType for tooltip
		indicatorFrame.auraIndex = auraIndex
		indicatorFrame.auraType = auraType

		---------------------------------
		--- process icon to show
		---------------------------------
		if profile["showIcon"..indicatorFrame.position] then
			indicatorFrame.icon:SetTexture(icon)
		else
			--set color of custom texture
			indicatorFrame.icon:SetColorTexture(
					profile["indicatorColor"..indicatorFrame.position].r,
					profile["indicatorColor"..indicatorFrame.position].g,
					profile["indicatorColor"..indicatorFrame.position].b,
					profile["indicatorColor"..indicatorFrame.position].a)

			-- determine if we should change the background color from the default (player set color)
			if profile["colorIndicatorByDebuff"..indicatorFrame.position] and debuffType then -- Color by debuff type
				if debuffType == "curse" then
					indicatorFrame.icon:SetColorTexture(0.6,0,1,1)
				elseif debuffType == "disease" then
					indicatorFrame.icon:SetColorTexture(0.6,0.4,0,1)
				elseif debuffType == "magic" then
					indicatorFrame.icon:SetColorTexture(0.2,0.6,1,1)
				elseif debuffType == "poison" then
					indicatorFrame.icon:SetColorTexture(0,0.6,0,1)
				end
			end
			if profile["colorIndicatorByTime"..indicatorFrame.position] then -- Color by remaining time
				if remainingTime and remainingTime < 2 then
					indicatorFrame.icon:SetColorTexture(1,0,0,1)
				elseif remainingTime and remainingTime < 5 then
					indicatorFrame.icon:SetColorTexture(1,1,0,1)
				end
			end
		end

		---------------------------------
		--- process text to show
		---------------------------------
		if profile["showText"..indicatorFrame.position] or profile["showStack"..indicatorFrame.position] then
			-- Pretty formatting of the remaining time text
			local formattedTime = ""
			local formattedCount = ""

			-- determine the formatted time string
			if profile["showText"..indicatorFrame.position] and expirationTime ~= 0 then
				if remainingTime > 60 then
					formattedTime = string.format("%.0f", remainingTime/60).."m" -- Show minutes without seconds
				elseif remainingTime >= 0 then
					formattedTime = string.format("%.0f", remainingTime) -- Show seconds without decimals
				end
			end

			-- determine the formatted count string
			if profile["showStack"..indicatorFrame.position] and count > 0 then
				formattedCount = count
			end

			-- determine the final output string concatenation
			if formattedCount ~= "" and formattedTime ~= "" then
				indicatorFrame.text:SetText(formattedCount .. "-" .. formattedTime)
			elseif formattedCount ~= "" then
				indicatorFrame.text:SetText(formattedCount)
			elseif formattedTime ~= "" then
				indicatorFrame.text:SetText(formattedTime)
			else
				indicatorFrame.text:SetText("")
			end
		else
			indicatorFrame.text:SetText("")
		end

		---------------------------------
		--- process text color
		---------------------------------
		--set default textColor to user selected choice
		indicatorFrame.text:SetTextColor(
				profile["textColor" .. indicatorFrame.position].r,
				profile["textColor" .. indicatorFrame.position].g,
				profile["textColor" .. indicatorFrame.position].b,
				profile["textColor" .. indicatorFrame.position].a)

		-- determine if we should change the textColor from the default (player set color)
		if profile["colorTextByStack"..indicatorFrame.position] then -- Color by stack
			if count == 1 then
				indicatorFrame.text:SetTextColor(1,0,0,1)
			elseif count == 2 then
				indicatorFrame.text:SetTextColor(1,1,0,1)
			elseif count >= 3 then
				indicatorFrame.text:SetTextColor(0,1,0,1)
			end
		elseif profile["colorTextByDebuff"..indicatorFrame.position] and debuffType then -- Color by debuff type
			if debuffType == "curse" then
				indicatorFrame.text:SetTextColor(0.6,0,1,1)
			elseif debuffType == "disease" then
				indicatorFrame.text:SetTextColor(0.6,0.4,0,1)
			elseif debuffType == "magic" then
				indicatorFrame.text:SetTextColor(0.2,0.6,1,1)
			elseif debuffType == "poison" then
				indicatorFrame.text:SetTextColor(0,0.6,0,1)
			end
		end
		if profile["colorTextByTime"..indicatorFrame.position] then -- Color by remaining time
			if remainingTime and remainingTime < 2 then
				indicatorFrame.text:SetTextColor(1,0,0,1)
			elseif remainingTime and remainingTime < 5 then
				indicatorFrame.text:SetTextColor(1,1,0,1)
			end
		end

		---------------------------------
		--- set cooldown animation
		---------------------------------
		if profile["showCountdownSwipe"..indicatorFrame.position] and expirationTime and duration then
			CooldownFrame_Set(indicatorFrame.cooldown, expirationTime - duration, duration, true, true)
		end

		---------------------------------
		--- set glow animation
		---------------------------------
		if profile["indicatorGlow"..indicatorFrame.position] and (profile["glowSecondsLeft"..indicatorFrame.position] == 0 or profile["glowSecondsLeft"..indicatorFrame.position] >= remainingTime) then
			ActionButton_ShowOverlayGlow(indicatorFrame)
		end

		indicatorFrame:Show() --show the frame

	elseif not foundAura and profile["missing"..indicatorFrame.position] then --deal with "show only if missing"
		local auraName = EnhancedRaidFrames.auraStrings[indicatorFrame.position][1] --show the icon for the first auraString position

		--check our iconCache for the auraName. Note the icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons
		if not EnhancedRaidFrames.iconCache[auraName] then
			_,_,icon = GetSpellInfo(auraName)
			if not icon then
				icon = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
		else
			icon = EnhancedRaidFrames.iconCache[auraName]
		end

		if profile["showIcon"..indicatorFrame.position] then
			indicatorFrame.icon:SetTexture(icon)
			indicatorFrame.text:SetText("")
		else
			indicatorFrame.icon:SetTexture(nil)
			indicatorFrame.text:SetText("X") --if we aren't showing the icon, show an "X" to show 'something' to indicate the missing aura
		end

		indicatorFrame:Show() --show the frame

	else
		--if no aura is found and we're not showing missing, clear animations and hide the frame
		CooldownFrame_Clear(indicatorFrame.cooldown)
		ActionButton_HideOverlayGlow(indicatorFrame)
		indicatorFrame:Hide() --hide the frame
	end
end

--process the text and icon for an indicator and return these values
--this function returns foundAura, icon, count, duration, expirationTime, debuffType, castBy, auraIndex, auraType
function EnhancedRaidFrames:QueryAuraInfo(auraName, unit)
	local profile = EnhancedRaidFrames.db.profile

	-- Check if the aura exist on the unit
	for _,v in pairs(unitAuras[unit]) do --loop through list of auras
		if (tonumber(auraName) and v.spellID == tonumber(auraName)) or v.auraName == auraName or (v.auraType == "debuff" and v.debuffType == auraName) then
			return true, v.icon, v.count, v.duration, v.expirationTime, v.debuffType, v.castBy, v.auraIndex, v.auraType
		end
	end

	-- Check if we want to show pvp flag
	if auraName:upper() == "PVP" then
		if UnitIsPVP(unit) then
			local factionGroup = UnitFactionGroup(unit)
			if factionGroup then
				return true, "Interface\\GroupFrame\\UI-Group-PVP-"..factionGroup, 0, 0, 0, "", "player"
			end
		end
	end

	-- Check if we want to show ToT flag
	if auraName:upper() == "TOT" then
		if UnitIsUnit(unit, "targettarget") then
			return true, "Interface\\Icons\\Ability_Hunter_SniperShot", 0, 0, 0, "", "player"
		end
	end

	return false
end


------------------------------------------------
---------- Update Auras for all units ----------
------------------------------------------------

function EnhancedRaidFrames:UpdateUnitAuras(unit)
	local profile = EnhancedRaidFrames.db.profile

	-- Create or clear out the tables for the unit
	unitAuras[unit] = {}

	-- Get all unit buffs
	local i = 1
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID

		if not EnhancedRaidFrames.isWoWClassic then
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = UnitAura(unit, i, "HELPFUL")
		else
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = EnhancedRaidFrames.UnitAuraWrapper(unit, i, "HELPFUL") --for wow classic. This is the libclassicdurations wrapper
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		--it's important to use the 4th argument in string.find to turn of pattern matching, otherwise things with parentheses in them will fail to be found
		if auraName and EnhancedRaidFrames.allAuras:find(" "..auraName:lower().." ", nil, true) or EnhancedRaidFrames.allAuras:find(" "..spellID.." ", nil, true) then -- Only add the spell if we're watching for it
			local auraTable = {}
			auraTable.auraType = "buff"
			auraTable.auraIndex = i
			auraTable.auraName = auraName:lower()
			auraTable.icon = icon
			auraTable.count = count
			auraTable.duration = duration
			auraTable.expirationTime = expirationTime
			auraTable.castBy = castBy
			auraTable.spellID = spellID

			table.insert(unitAuras[unit], auraTable)
		end
		i = i + 1
	end

	-- Get all unit debuffs
	i = 1
	while (true) do
		local auraName, icon, count, duration, expirationTime, castBy, spellID, debuffType

		if not EnhancedRaidFrames.isWoWClassic then
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  = UnitAura(unit, i, "HARMFUL")
		else
			auraName, icon, count, debuffType, duration, expirationTime, castBy, _, _, spellID  = EnhancedRaidFrames.UnitAuraWrapper(unit, i, "HARMFUL") --for wow classic. This is the libclassicdurations wrapper
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		--it's important to use the 4th argument in string.find to turn of pattern matching, otherwise things with parentheses in them will fail to be found
		if auraName and EnhancedRaidFrames.allAuras:find(" "..auraName:lower().." ", nil, true) or EnhancedRaidFrames.allAuras:find(" "..spellID.." ", nil, true) or (debuffType and EnhancedRaidFrames.allAuras:find(" "..debuffType:lower().." ", nil, true)) then -- Only add the spell if we're watching for it
			local auraTable = {}
			auraTable.auraType = "debuff"
			auraTable.auraIndex = i
			auraTable.auraName = auraName:lower()
			auraTable.icon = icon
			auraTable.count = count
			if debuffType then
				auraTable.debuffType = debuffType:lower()
			end
			auraTable.duration = duration
			auraTable.expirationTime = expirationTime
			auraTable.castBy = castBy
			auraTable.spellID = spellID

			table.insert(unitAuras[unit], auraTable)
		end
		i = i + 1
	end
end

------------------------------------------------
----------------- Tooltip Code -----------------
------------------------------------------------
function EnhancedRaidFrames:Tooltip_OnEnter(indicatorFrame)
	local profile = EnhancedRaidFrames.db.profile

	if not profile["showTooltip"..indicatorFrame.position] then --don't show tooltips unless we have the option set for this position
		return
	end

	local frame = indicatorFrame:GetParent() --this is the parent raid frame that holds all the indicatorFrames

	-- Set the tooltip
	if indicatorFrame.auraIndex and indicatorFrame.icon:GetTexture() then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, profile["tooltipLocation"..indicatorFrame.position])
		if indicatorFrame.auraType == "buff" then
			GameTooltip:SetUnitAura(frame.unit, indicatorFrame.auraIndex, "HELPFUL")
		else
			GameTooltip:SetUnitAura(frame.unit, indicatorFrame.auraIndex, "HARMFUL")
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		if frame then
			UnitFrame_UpdateTooltip(frame)
		end
	end

	GameTooltip:Show()
end