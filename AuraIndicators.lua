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

local addonName, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local f = {} -- Indicators for the frames
local unitAuras = {} -- Matrix to keep a list of all auras on all units

EnhancedRaidFrames.iconCache = {}
EnhancedRaidFrames.iconCache["poison"] = 132104
EnhancedRaidFrames.iconCache["disease"] = 132099
EnhancedRaidFrames.iconCache["curse"] = 132095
EnhancedRaidFrames.iconCache["magic"] = 135894

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:SetStockIndicatorVisibility(frame)
	if not EnhancedRaidFrames.db.profile.showBuffs then
		CompactUnitFrame_HideAllBuffs(frame)
	end

	if not EnhancedRaidFrames.db.profile.showDebuffs then
		CompactUnitFrame_HideAllDebuffs(frame)
	end

	if not EnhancedRaidFrames.db.profile.showDispelDebuffs then
		CompactUnitFrame_HideAllDispelDebuffs(frame)
	end
end

-- Create the FontStrings used for indicators
function EnhancedRaidFrames:CreateIndicators(frame)
	local frameName = frame:GetName()
	f[frameName] = {}

	-- Create indicators
	for i = 1, 9 do
		if _G[frameName.."_ERF_"..i] then
			--if the frame already exists, attach to it
			f[frameName][i] = _G[frameName.."_ERF_"..i]
		else
			--We have to use this template to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raidframe behind it
			f[frameName][i] = CreateFrame("Button", frameName.."_ERF_"..i, frame, "CompactAuraTemplate")
		end

		f[frameName][i]:RegisterForClicks("LeftButtonDown", "RightButtonUp")
		f[frameName][i]:SetFrameStrata("HIGH")

		--we further define this frame element in SetIndicatorAppearance. This is just a starting state
		f[frameName][i].text = f[frameName][i]:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we don't show the animation, text should be on the parent frame
		f[frameName][i].text:SetPoint("CENTER", f[frameName][i], "CENTER", 0, 0)

		--mark the position of this particular frame for use later (i.e. 1->9)
		f[frameName][i].position = i

		-- hook enter and leave for showing ability tooltips
		EnhancedRaidFrames:SecureHookScript(f[frameName][i], "OnEnter", function() EnhancedRaidFrames:Tooltip_OnEnter(f[frameName][i]) end)
		EnhancedRaidFrames:SecureHookScript(f[frameName][i], "OnLeave", function() GameTooltip:Hide() end)
	end

	EnhancedRaidFrames:SetIndicatorAppearance(frame)
end

-- Set the appearance of the Indicator
function EnhancedRaidFrames:SetIndicatorAppearance(frame)
	local unit = frame.unit
	local frameName = frame:GetName()

	-- Check if the frame is pointing at anything
	if not f[frameName] or not unit then
		return
	end

	local font = (media and media:Fetch('font', EnhancedRaidFrames.db.profile.indicatorFont)) or STANDARD_TEXT_FONT

	for i = 1, 9 do
		f[frameName][i]:SetWidth(EnhancedRaidFrames.db.profile["iconSize"..i])
		f[frameName][i]:SetHeight(EnhancedRaidFrames.db.profile["iconSize"..i])

		local PAD = 1
		local iconVerticalOffset = EnhancedRaidFrames.db.profile["indicatorVerticalOffset"..i] * frame:GetHeight()
		local iconHorizontalOffset = EnhancedRaidFrames.db.profile["indicatorHorizontalOffset"..i] * frame:GetWidth()

		--we probably don't want to overlap the power bar (rage,mana,energy,etc) so we need a compensation factor
		local powerBarVertOffset
		if frame.powerBar:IsShown() then
			powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
		else
			powerBarVertOffset = 0
		end

		f[frameName][i]:ClearAllPoints()
		if i == 1 then
			f[frameName][i]:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 2 then
			f[frameName][i]:SetPoint("TOP", frame, "TOP", 0 + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 3 then
			f[frameName][i]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
		elseif i == 4 then
			f[frameName][i]:SetPoint("LEFT", frame, "LEFT", PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 5 then
			f[frameName][i]:SetPoint("CENTER", frame, "CENTER", 0 + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 6 then
			f[frameName][i]:SetPoint("RIGHT", frame, "RIGHT", -PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
		elseif i == 7 then
			f[frameName][i]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		elseif i == 8 then
			f[frameName][i]:SetPoint("BOTTOM", frame, "BOTTOM", 0 + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		elseif i == 9 then
			f[frameName][i]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
		end

		--create a text overlay frame that will show our countdown text
		if not EnhancedRaidFrames.db.profile["showCooldownAnimation"..i] or not EnhancedRaidFrames.db.profile["showIcon"..i] then
			f[frameName][i].text:SetText("")
			f[frameName][i].text = f[frameName][i]:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we don't show the cooldown animation or the icon, text should be on the parent frame
			f[frameName][i].text:SetPoint("CENTER", f[frameName][i], "CENTER", 0, 0)
		else
			f[frameName][i].text:SetText("")
			f[frameName][i].text = f[frameName][i].cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we show the cooldown animation, text should be on the child '.cooldown' frame
			f[frameName][i].text:SetPoint("CENTER", f[frameName][i].cooldown, "CENTER", 0, 0)
		end

		f[frameName][i].text:SetFont(font, EnhancedRaidFrames.db.profile["size"..i], "OUTLINE")
		f[frameName][i].text:SetTextColor(EnhancedRaidFrames.db.profile["color"..i].r, EnhancedRaidFrames.db.profile["color"..i].g, EnhancedRaidFrames.db.profile["color"..i].b, EnhancedRaidFrames.db.profile["color"..i].a)
	end
end


------------------------------------------------
--------------- Process Indicators -------------
------------------------------------------------

function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
	local frameName = frame:GetName()
	local unit = frame.unit

	--check to see if the bar is even targeting a unit, bail if it isn't
	--also, tanks have two bars below their frame that have a frame.unit that ends in "target" and "targettarget".
	--Normal raid members have frame.unit that says "Raid1", "Raid5", etc.
	--We don't want to put icons over these tiny little target and target of target bars
	--Also, in 8.2.5 blizzard unified the nameplate code with the raid frame code. Don't display icons on nameplates
	if not unit or string.find(unit, "target") or string.find(unit, "nameplate") then
		return
	end

	EnhancedRaidFrames:SetStockIndicatorVisibility(frame)

	-- Check if the indicator frame exists, else create it
	if not f[frameName] then
		EnhancedRaidFrames:CreateIndicators(frame)
	end

	if setAppearance then
		EnhancedRaidFrames:SetIndicatorAppearance(frame)
	end

	-- Update unit auras
	EnhancedRaidFrames:UpdateUnitAuras(unit)

	-- Loop over all 9 indicators and process them individually
	for i = 1, 9 do
		EnhancedRaidFrames:ProcessIndicator(f[frameName][i], unit)
	end
end


-- process a single indicator and apply visuals
function EnhancedRaidFrames:ProcessIndicator(indicatorFrame, unit)
	local icon
	local displayText
	local textColor

	-- If we only are to show the indicator on me, then don't bother if I'm not the unit
	if EnhancedRaidFrames.db.profile["me"..indicatorFrame.position] then
		local unitName, unitRealm = UnitName(unit)
		if unitName ~= UnitName("player") or unitRealm ~= nil then
			return
		end
	end

	-- Go through the aura strings
	for _, auraName in pairs(EnhancedRaidFrames.auraStrings[indicatorFrame.position]) do -- Grab each line
		if not auraName then --if there's no auraName (i.e. the user never specified anything to go in this spot), stop here there's no need to keep going
			break
		end

		--query the icon and formatted text and text color for a given indicator and aura
		icon, displayText, textColor = EnhancedRaidFrames:ProcessIconAndText(indicatorFrame, auraName, unit)

		-- add spell icon info to cache in case we need it later on
		if icon and not EnhancedRaidFrames.iconCache[auraName] then
			EnhancedRaidFrames.iconCache[auraName] = icon
		end

		--if we find the aura, we can stop querying down the list
		if icon or displayText then
			break
		end
	end

	--output visuals to the indicator frame
	--set the texture or text on a frame, and show or hide the indicator frame
	if (icon or displayText) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		-- show the frame
		indicatorFrame:Show()
		-- Set text color
		indicatorFrame.text:SetTextColor(textColor[1],textColor[2],textColor[3],textColor[4])
		-- Show the text
		indicatorFrame.text:SetText(displayText)
		-- Show the icon
		indicatorFrame.icon:SetTexture(icon)
	else
		-- hide the frame
		indicatorFrame:Hide()
	end

	--set cooldown animation
	if EnhancedRaidFrames.db.profile["showCooldownAnimation"..indicatorFrame.position] and indicatorFrame:IsShown() and indicatorFrame.expirationTime and indicatorFrame.duration then
		CooldownFrame_Set(indicatorFrame.cooldown, indicatorFrame.expirationTime - indicatorFrame.duration, indicatorFrame.duration, true, true)
	else
		CooldownFrame_Clear(indicatorFrame.cooldown)
	end
end


--process the text and icon for an indicator and return these values
function EnhancedRaidFrames:ProcessIconAndText(indicatorFrame, auraName, unit)
	local icon
	local displayText = ""
	local textColor = {
		EnhancedRaidFrames.db.profile["color"..indicatorFrame.position].r,
		EnhancedRaidFrames.db.profile["color"..indicatorFrame.position].g,
		EnhancedRaidFrames.db.profile["color"..indicatorFrame.position].b,
		EnhancedRaidFrames.db.profile["color"..indicatorFrame.position].a,
	}

	local foundAura

	local remainingTime
	local count = 0
	local castBy = ""
	local debuffType

	indicatorFrame.duration = nil
	indicatorFrame.expirationTime = nil

	indicatorFrame.auraIndex = nil
	indicatorFrame.auraType = nil


	-- Check if the aura exist on the unit
	for _,v in pairs(unitAuras[unit]) do
		if (tonumber(auraName) and v.spellID == tonumber(auraName)) or v.auraName == auraName or (v.auraType == "debuff" and v.debuffType == auraName) then
			count = v.count
			castBy = v.castBy
			icon = v.icon
			debuffType = v.debuffType

			indicatorFrame.duration = v.duration
			indicatorFrame.expirationTime = v.expirationTime

			--set auraIndex and auraType for tooltip
			indicatorFrame.auraIndex = v.auraIndex
			indicatorFrame.auraType = v.auraType

			foundAura = true
			break
		end
	end

	if not foundAura then
		if auraName:upper() == "PVP" then -- Check if we want to show pvp flag
			if UnitIsPVP(unit) then
				count = 0
				castBy = "player"

				indicatorFrame.duration = 0
				indicatorFrame.expirationTime = 0

				local factionGroup = UnitFactionGroup(unit)
				if factionGroup then
					icon = "Interface\\GroupFrame\\UI-Group-PVP-"..factionGroup
				end

				foundAura = true
			end
		elseif auraName:upper() == "TOT" then -- Check if we want to show ToT flag
			if UnitIsUnit(unit, "targettarget") then
				count = 0
				castBy = "player"
				icon = "Interface\\Icons\\Ability_Hunter_SniperShot"

				indicatorFrame.duration = 0
				indicatorFrame.expirationTime = 0

				foundAura = true
			end
		end
	end

	--if we find the spell and we don't only want to show when it is missing
	if foundAura and not EnhancedRaidFrames.db.profile["missing"..indicatorFrame.position] then
		-- If we only are to show spells cast by me, make sure the spell is
		if (EnhancedRaidFrames.db.profile["mine"..indicatorFrame.position] and castBy ~= "player") then
			icon = ""
			displayText = ""
		else
			if not EnhancedRaidFrames.db.profile["showIcon"..indicatorFrame.position] then -- Hide icon
				icon = ""
			end
			if indicatorFrame.expirationTime == 0 then -- No expiration time = permanent
				if not EnhancedRaidFrames.db.profile["showIcon"..indicatorFrame.position] then
					displayText = "X" -- Only show the X if we don't show the icon
				end
			else
				if EnhancedRaidFrames.db.profile["showText"..indicatorFrame.position] then
					-- Pretty formatting of the remaining time text
					remainingTime = indicatorFrame.expirationTime - GetTime()
					if remainingTime > 60 then
						displayText = string.format("%.0f", (remainingTime / 60)).."m" -- Show minutes without seconds
					elseif remainingTime >= 1 then
						displayText = string.format("%.0f",remainingTime) -- Show seconds without decimals
					end
				else
					displayText = ""
				end

			end

			-- Add stack count
			if EnhancedRaidFrames.db.profile["stack"..indicatorFrame.position] and count > 0 then
				if EnhancedRaidFrames.db.profile["showText"..indicatorFrame.position] and indicatorFrame.expirationTime > 0 then
					displayText = count .."-".. displayText
				else
					displayText = count
				end
			end
		end

		--determine text color
		if EnhancedRaidFrames.db.profile["stackColor"..indicatorFrame.position] then -- Color by stack
			if count == 1 then
				textColor = {1,0,0,1}
			elseif count == 2 then
				textColor = {1,1,0,1}
			elseif count >= 3 then
				textColor = {0,1,0,1}
			end
		elseif EnhancedRaidFrames.db.profile["debuffColor"..indicatorFrame.position] then -- Color by debuff type
			if debuffType then
				if debuffType == "curse" then
					textColor = {0.6,0,1,1}
				elseif debuffType == "disease" then
					textColor = {0.6,0.4,0,1}
				elseif debuffType == "magic" then
					textColor = {0.2,0.6,1,1}
				elseif debuffType == "poison" then
					textColor = {0,0.6,0,1}
				end
			end
		elseif EnhancedRaidFrames.db.profile["colorByTime"..indicatorFrame.position] then -- Color by remaining time
			if remainingTime and remainingTime < 2 then
				textColor = {1,0,0,1}
			elseif remainingTime and remainingTime < 5 then
				textColor = {1,1,0,1}
			end
		end

		return icon, displayText, textColor
	end

	--if we don't find the spell and we want it to only show when missing
	if not foundAura and EnhancedRaidFrames.db.profile["missing"..indicatorFrame.position] then
		if EnhancedRaidFrames.db.profile["showIcon"..indicatorFrame.position] then
			--check our iconCache for the auraName. Note the icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons
			if not EnhancedRaidFrames.iconCache[auraName] then
				_,_,icon = GetSpellInfo(auraName)
				if icon then
					EnhancedRaidFrames.iconCache[auraName] = icon
				end
			else
				icon = EnhancedRaidFrames.iconCache[auraName]
			end

			if not icon then
				displayText = "X" --if you can't find an icon, display an X
			end
		else
			displayText = "X" --if we aren't showing icons, display and X
		end

		return icon, displayText, textColor
	end
end

------------------------------------------------
---------- Update Auras for all units ----------
------------------------------------------------

function EnhancedRaidFrames:UpdateUnitAuras(unit)
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

		if auraName and EnhancedRaidFrames.allAuras:find("+"..auraName:lower().."+") or EnhancedRaidFrames.allAuras:find("+"..spellID.."+") then -- Only add the spell if we're watching for it
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

		if auraName and EnhancedRaidFrames.allAuras:find("+"..auraName:lower().."+") or EnhancedRaidFrames.allAuras:find("+"..spellID.."+") or (debuffType and EnhancedRaidFrames.allAuras:find("+"..debuffType:lower().."+")) then -- Only add the spell if we're watching for it
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
	if not EnhancedRaidFrames.db.profile["showTooltip"..indicatorFrame.position] then --don't show tooltips unless we have the option set for this position
		return
	end

	local frame = indicatorFrame:GetParent() --this is the parent raid frame that holds all the indicatorFrames

	-- Set the tooltip
	if indicatorFrame.auraIndex and indicatorFrame.icon:GetTexture() then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
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