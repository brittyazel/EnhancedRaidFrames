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
local PAD = 2
local unitBuffs = {} -- Matrix to keep a list of all buffs on all units
local unitDebuffs = {} -- Matrix to keep a list of all debuffs on all units

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
		--We have to use this template to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raidframe behind it
		f[frameName][i] = CreateFrame("Button", nil, frame, "CompactAuraTemplate")
		f[frameName][i]:RegisterForClicks("LeftButtonDown", "RightButtonUp");
		f[frameName][i]:SetFrameStrata("HIGH")

		--we further define this frame element in SetIndicatorAppearance. This is just a starting state
		f[frameName][i].text = f[frameName][i]:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall") --if we don't show the animation, text should be on the parent frame
		f[frameName][i].text:SetPoint("CENTER", f[frameName][i], "CENTER", 0, 0)

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

		--mark the position of this particular frame for use later (i.e. 1->9)
		f[frameName][i].position = i

		-- hook enter and leave for showing ability tooltips
		EnhancedRaidFrames:SecureHookScript(f[frameName][i], "OnEnter", function() EnhancedRaidFrames:Tooltip_OnEnter(f[frameName][i]) end)
		EnhancedRaidFrames:SecureHookScript(f[frameName][i], "OnLeave", function() EnhancedRaidFrames:Tooltip_OnLeave(f[frameName][i]) end)
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


-- Check the indicators on a frame and update the times on them
function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
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

	local currentTime = GetTime()
	local frameName = frame:GetName()

	-- Check if the indicator frame exists, else create it
	if not f[frameName] then
		EnhancedRaidFrames:CreateIndicators(frame)
	end

	if setAppearance then
		EnhancedRaidFrames:SetIndicatorAppearance(frame)
	end

	-- Update unit auras
	EnhancedRaidFrames:UpdateUnitAuras(unit)

	-- Loop over the indicators and see if we get a hit
	for i = 1, 9 do
		local remainingTime
		local displayText = ""
		local icon = ""
		local count = 0
		local duration = 0
		local expirationTime = 0
		local castBy = ""
		local debuffType

		-- If we only are to show the indicator on me, then don't bother if I'm not the unit
		if EnhancedRaidFrames.db.profile["me"..i] then
			local uName, uRealm = UnitName(unit)
			if uName ~= UnitName("player") or uRealm ~= nil then
				break
			end
		end

		-- Go through the aura strings
		for _, auraName in ipairs(EnhancedRaidFrames.auraStrings[i]) do -- Grab each line
			if not auraName then --if there's no auraName (i.e. the user never specified anything to go in this spot), stop here there's no need to keep going
				break
			end

			-- Check if the aura exist on the unit
			for j,v in ipairs(unitBuffs[unit]) do
				if (tonumber(auraName) and v.spellID == tonumber(auraName)) or v.auraName == auraName and v.castBy == "player" then
					count = v.count
					duration = v.duration
					expirationTime = v.expirationTime
					castBy = v.castBy
					icon = v.icon
					f[frameName][i].auraIndex = v.auraIndex
					f[frameName][i].isBuff = true
					break
				end
			end

			if not count then
				for j,v in ipairs(unitBuffs[unit]) do -- Check debuffs
					if (tonumber(auraName) and v.spellID == tonumber(auraName)) or v.auraName == auraName or v.debuffType == auraName then
						count = v.count
						duration = v.duration
						expirationTime = v.expirationTime
						icon = v.icon
						debuffType = v.debuffType
						f[frameName][i].auraIndex = v.auraIndex
						break
					end
				end
			end

			if not count then
				if auraName:upper() == "PVP" then -- Check if we want to show pvp flag
					if UnitIsPVP(unit) then
						count = 0
						expirationTime = 0
						duration = 0
						castBy = "player"
						f[frameName][i].skipTooltip = true

						local factionGroup = UnitFactionGroup(unit)
						if factionGroup then
							icon = "Interface\\GroupFrame\\UI-Group-PVP-"..factionGroup
						end
					end
				elseif auraName:upper() == "TOT" then -- Check if we want to show ToT flag
					if UnitIsUnit (unit, "targettarget") then
						count = 0
						expirationTime = 0
						duration = 0
						castBy = "player"
						icon = "Interface\\Icons\\Ability_Hunter_SniperShot"
						f[frameName][i].skipTooltip = true
					end
				end
			end

			if count then -- We found a matching spell
				-- If we only are to show spells cast by me, make sure the spell is
				if (EnhancedRaidFrames.db.profile["mine"..i] and castBy ~= "player") then
					icon = ""
				else
					if not EnhancedRaidFrames.db.profile["showIcon"..i] then -- Hide icon
						icon = ""
					end
					if expirationTime == 0 then -- No expiration time = permanent
						if not EnhancedRaidFrames.db.profile["showIcon"..i] then
							displayText = "■" -- Only show the blob if we don't show the icon
						end
					else
						if EnhancedRaidFrames.db.profile["showText"..i] then
							-- Pretty formatting of the remaining time text
							remainingTime = expirationTime - currentTime
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
					if EnhancedRaidFrames.db.profile["stack"..i] and count > 0 then
						if EnhancedRaidFrames.db.profile["showText"..i] and expirationTime > 0 then
							displayText = count .."-".. displayText
						else
							displayText = count
						end
					end

					-- Set color
					if EnhancedRaidFrames.db.profile["stackColor"..i] then -- Color by stack
						if count == 1 then
							f[frameName][i].text:SetTextColor(1,0,0,1)
						elseif count == 2 then
							f[frameName][i].text:SetTextColor(1,1,0,1)
						elseif count >= 3 then
							f[frameName][i].text:SetTextColor(0,1,0,1)
						else
							f[frameName][i].text:SetTextColor(1,1,1,1)
						end
					elseif EnhancedRaidFrames.db.profile["debuffColor"..i] then -- Color by debuff type
						if debuffType then
							if debuffType == "curse" then
								f[frameName][i].text:SetTextColor(0.6,0,1,1)
							elseif debuffType == "disease" then
								f[frameName][i].text:SetTextColor(0.6,0.4,0,1)
							elseif debuffType == "magic" then
								f[frameName][i].text:SetTextColor(0.2,0.6,1,1)
							elseif debuffType == "poison" then
								f[frameName][i].text:SetTextColor(0,0.6,0,1)
							end
						end
					elseif EnhancedRaidFrames.db.profile["colorByTime"..i] then -- Color by remaining time
						if remainingTime and remainingTime < 3 then
							f[frameName][i].text:SetTextColor(1,0,0,1)
						elseif remainingTime and remainingTime < 5 then
							f[frameName][i].text:SetTextColor(1,1,0,1)
						else
							f[frameName][i].text:SetTextColor(EnhancedRaidFrames.db.profile["color"..i].r, EnhancedRaidFrames.db.profile["color"..i].g, EnhancedRaidFrames.db.profile["color"..i].b, EnhancedRaidFrames.db.profile["color"..i].a)
						end
					end

					break -- We found a match, so no need to continue the for loop
				end
			end
		end

		-- Only show when it's missing
		if EnhancedRaidFrames.db.profile["missing"..i] and not count then
			if EnhancedRaidFrames.db.profile["showIcon"..i] then
				--try to find an icon
				if EnhancedRaidFrames.auraStrings[i][1] then --if the string is empty do nothing
					if string.lower(EnhancedRaidFrames.auraStrings[i][1]) == "poison" then
						icon = 132104
					elseif string.lower(EnhancedRaidFrames.auraStrings[i][1]) == "disease" then
						icon = 132099
					elseif string.lower(EnhancedRaidFrames.auraStrings[i][1]) == "curse" then
						icon = 132095
					elseif string.lower(EnhancedRaidFrames.auraStrings[i][1]) == "magic" then
						icon = 135894
					else
						_,_,icon = GetSpellInfo(EnhancedRaidFrames.auraStrings[i][1])
					end

					if not icon then
						displayText = "X" --if you can't find an icon, display an X
					end
				end
			else
				displayText = "X" --if we aren't showing icons, display and X
			end
		end

		--set the texture or text on a frame, and show or hide the indicator frame
		if (icon ~= "" or displayText ~= "") and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
			-- show the frame
			f[frameName][i]:Show()
			-- Show the text
			f[frameName][i].text:SetText(displayText)
			-- Show the icon
			f[frameName][i].icon:SetTexture(icon)
		else
			-- hide the frame
			f[frameName][i]:Hide()
		end

		--set cooldown animation
		if EnhancedRaidFrames.db.profile["showCooldownAnimation"..i] and icon~="" and f[frameName][i]:IsShown() then
			CooldownFrame_Set(f[frameName][i].cooldown, expirationTime - duration, duration, true, true)
		else
			CooldownFrame_Clear(f[frameName][i].cooldown);
		end
	end
end


-- Get all unit auras
function EnhancedRaidFrames:UpdateUnitAuras(unit)
	-- Create or clear out the tables for the unit
	unitBuffs[unit] = {}
	unitDebuffs[unit] = {}

	-- Get all unit buffs
	local auraName, icon, count, duration, expirationTime, castBy, debuffType, spellID, i

	i = 1
	while (true) do
		if not EnhancedRaidFrames.isWoWClassic then
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = UnitAura(unit, i, "HELPFUL")
		else
			auraName, icon, count, _, duration, expirationTime, castBy, _, _, spellID = EnhancedRaidFrames.UnitAuraWrapper(unit, i, "HELPFUL") --for wow classic. This is the libclassicdurations wrapper
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		if EnhancedRaidFrames.allAuras:find("+"..auraName:lower().."+") or EnhancedRaidFrames.allAuras:find("+"..spellID.."+") then -- Only add the spell if we're watching for it
			local len = #unitBuffs[unit]
			unitBuffs[unit][len+1] = {}
			unitBuffs[unit][len+1].auraName = auraName:lower()
			unitBuffs[unit][len+1].spellID = spellID
			unitBuffs[unit][len+1].count = count
			unitBuffs[unit][len+1].duration = duration
			unitBuffs[unit][len+1].expirationTime = expirationTime
			unitBuffs[unit][len+1].castBy = castBy
			unitBuffs[unit][len+1].icon = icon
			unitBuffs[unit][len+1].auraIndex = i
		end
		i = i + 1
	end

	-- Get all unit debuffs
	i = 1
	while (true) do
		if not EnhancedRaidFrames.isWoWClassic then
			auraName, icon, count, debuffType, duration, expirationTime, _, _, _, spellID  = UnitAura(unit, i, "HARMFUL")
		else
			auraName, icon, count, debuffType, duration, expirationTime, _, _, _, spellID  = EnhancedRaidFrames.UnitAuraWrapper(unit, i, "HARMFUL")
		end

		if not spellID then --break the loop once we have no more buffs
			break
		end

		if EnhancedRaidFrames.allAuras:find("+"..auraName:lower().."+") or EnhancedRaidFrames.allAuras:find("+"..spellID.."+") or (debuffType and EnhancedRaidFrames.allAuras:find("+"..debuffType:lower().."+")) then -- Only add the spell if we're watching for it
			local len = #unitDebuffs[unit]
			unitDebuffs[unit][len+1] = {}
			unitDebuffs[unit][len+1].auraName = auraName:lower()
			unitDebuffs[unit][len+1].spellID = spellID
			unitDebuffs[unit][len+1].count = count
			unitDebuffs[unit][len+1].duration = duration
			unitDebuffs[unit][len+1].expirationTime = expirationTime
			unitDebuffs[unit][len+1].icon = icon
			unitDebuffs[unit][len+1].auraIndex = i
			unitDebuffs[unit][len+1].debuffType = debuffType:lower()
		end
		i = i + 1
	end
end



-------------------------------
---Tooltip Code
-------------------------------
function EnhancedRaidFrames:Tooltip_OnEnter(buffFrame)
	if not EnhancedRaidFrames.db.profile["showTooltip"..buffFrame.position] then --don't show tooltips unless we have the option set for this position
		return
	end

	local frame = buffFrame:GetParent() --this is the parent raid frame that holds all the buffFrames

	-- Set the tooltip
	if buffFrame.auraIndex and not buffFrame.skipTooltip and buffFrame.icon:GetTexture() then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		if buffFrame.isBuff then
			GameTooltip:SetUnitAura(frame.unit, buffFrame.auraIndex, "HELPFUL")
		else
			GameTooltip:SetUnitAura(frame.unit, buffFrame.auraIndex, "HARMFUL")
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		if frame then
			UnitFrame_UpdateTooltip(frame)
		end
	end

	GameTooltip:Show()
end


function EnhancedRaidFrames:Tooltip_OnLeave(buffFrame)
	if not EnhancedRaidFrames.db.profile.showTooltips then --don't show tooltips unless we have the option set
		return
	end

	GameTooltip:Hide()
end