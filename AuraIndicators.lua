-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local LibSharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

EnhancedRaidFrames.iconCache = {}
EnhancedRaidFrames.iconCache["poison"] = 132104
EnhancedRaidFrames.iconCache["disease"] = 132099
EnhancedRaidFrames.iconCache["curse"] = 132095
EnhancedRaidFrames.iconCache["magic"] = 135894

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Creates all of our indicator frames on their respective raid frames
--- @param frame table @The raid frame to create indicators on
function EnhancedRaidFrames:CreateIndicators(frame)
	frame.ERF_indicatorFrames = {}

	-- Create indicators
	for i = 1, 9 do
		--I'm not sure if this is ever the case, but to stop us from creating redundant frames we should try to re-capture them when possible
		--On the global table, our frames our named "CompactRaidFrame#" + "-ERF_indicator-" + index#, i.e. "CompactRaidFrame1-ERF_indicator-1"
		if not _G[frame:GetName().."ERF_indicator"..i] then
			--We have to use CompactAuraTemplate to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raid frame behind it
			frame.ERF_indicatorFrames[i] = CreateFrame("Button", frame:GetName().."-ERF_indicator-"..i, frame, "ERF_indicatorTemplate")
		else
			frame.ERF_indicatorFrames[i] =  _G[frame:GetName().."-ERF_indicator-"..i]
			frame.ERF_indicatorFrames[i]:SetParent(frame) --if we capture an old indicator frame, we should reattach it to the current unit frame
		end

		--create local pointer for readability
		local indicatorFrame = frame.ERF_indicatorFrames[i]

		--mark the position of this particular frame for use later (i.e. 1->9)
		indicatorFrame.position = i

		--hook OnEnter and OnLeave for showing and hiding ability tooltips
		indicatorFrame:SetScript("OnEnter", function() self:Tooltip_OnEnter(indicatorFrame, frame) end)
		indicatorFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

		--disable the mouse click on our frames to allow those clicks to get passed straight through to the raid frame behind (switch target, right click, etc)
		--this MUST come after the SetScript lines for OnEnter and OnLeave. SetScript will re-enable mouse clicks when called.
		indicatorFrame:SetMouseClickEnabled(false)
	end

	--set our initial indicator appearance
	self:SetIndicatorAppearance(frame)
end

--- Set the appearance of the Indicator
--- @param frame table @The raid frame of our indicator
function EnhancedRaidFrames:SetIndicatorAppearance(frame)
	-- Check if the frame has an ERFIndicators table or if we have a frame unit, this is just for safety
	if not frame.ERF_indicatorFrames or not frame.unit then
		return
	end

	for i = 1, 9 do
		--create local pointer for readability
		local indicatorFrame = frame.ERF_indicatorFrames[i]

		--set icon size
		indicatorFrame:SetWidth(self.db.profile[i].indicatorSize)
		indicatorFrame:SetHeight(self.db.profile[i].indicatorSize)

		--------------------------------------

		--set indicator frame position
		local PAD = 1
		local indicatorVerticalOffset = floor((self.db.profile[i].indicatorVerticalOffset * frame:GetHeight()) + 0.5)
		local indicatorHorizontalOffset = floor((self.db.profile[i].indicatorHorizontalOffset * frame:GetWidth()) + 0.5)

		--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
		local powerBarVertOffset
		if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
			powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
		else
			powerBarVertOffset = 0
		end

		indicatorFrame:ClearAllPoints()
		if i == 1 then
			indicatorFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 2 then
			indicatorFrame:SetPoint("TOP", frame, "TOP", 0 + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 3 then
			indicatorFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 4 then
			indicatorFrame:SetPoint("LEFT", frame, "LEFT", PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 5 then
			indicatorFrame:SetPoint("CENTER", frame, "CENTER", 0 + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 6 then
			indicatorFrame:SetPoint("RIGHT", frame, "RIGHT", -PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 7 then
			indicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		elseif i == 8 then
			indicatorFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0 + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		elseif i == 9 then
			indicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		end

		--------------------------------------

		--set font size, shape, font, and switch our text object
		indicatorFrame.Text:SetText("") --clear previous text
		local font = (LibSharedMedia and LibSharedMedia:Fetch('font', self.db.profile.indicatorFont)) or STANDARD_TEXT_FONT
		indicatorFrame.Text:SetFont(font, self.db.profile[i].textSize, "OUTLINE")

		--switch the parent for our text frame to keep the text on top of the cooldown animation
		if not self.db.profile[i].showCountdownSwipe then
			indicatorFrame.Text:SetParent(indicatorFrame)
		else
			indicatorFrame.Text:SetParent(indicatorFrame.Cooldown)
		end

		--clear any animations
		ActionButton_HideOverlayGlow(indicatorFrame)
		CooldownFrame_Clear(indicatorFrame.Cooldown)
		indicatorFrame.Icon:SetAlpha(1)
	end
end

------------------------------------------------
--------------- Process Indicators -------------
------------------------------------------------

--- Kickstart the indicator processing for all indicators on a given frame
--- @param frame table @The raid frame of our indicators
--- @param setAppearance boolean @Indicates if we should trigger reapply appearance settings to the indicators
function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
	if not self.ShouldContinue(frame.unit) then
		return
	end

	self:SetStockIndicatorVisibility(frame)

	-- Create the indicator frame if it doesn't exist, otherwise just update the appearance
	if not frame.ERF_indicatorFrames then
		self:CreateIndicators(frame)
	else
		if setAppearance then
			self:SetIndicatorAppearance(frame)
		end
	end

	local unitIsConnected = UnitIsConnected(frame.unit)
	local unitIsDeadOrGhost = UnitIsDeadOrGhost(frame.unit)

	-- Loop over all 9 indicators and process them individually
	for i, indicator in ipairs(frame.ERF_indicatorFrames) do
		--if we don't have any auraStrings for this indicator, stop here
		if #self.auraStrings[i] > 0 and unitIsConnected and not unitIsDeadOrGhost then
			-- this is the meat of our processing loop
			self:ProcessIndicator(indicator, frame.unit)
		else
			indicator:Hide() --hide the frame
		end
	end
end

--- Update all aura indicators
--- @param skipCheck boolean @Indicates if we skip the check for tracked auras
function EnhancedRaidFrames:UpdateAllIndicators(skipCheck)
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown()
			and CompactPartyFrame and not CompactPartyFrame:IsShown()
			and CompactArenaFrame and not CompactArenaFrame:IsShown() then
		return
	end

	-- This is the heart and soul of the addon. Everything gets called from here.
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			if frame and frame.unit then
				if skipCheck or self:HasTrackedAuras(frame) then --if we don't have any tracked auras, don't bother updating
					self:UpdateIndicators(frame)
				end
			end
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			if frame and frame.unit then
				if skipCheck or self:HasTrackedAuras(frame) then --if we don't have any tracked auras, don't bother updating
					self:UpdateIndicators(frame)
				end
			end
		end)
	end
end

--- Process a single indicator location and apply any necessary visual effects for this moment in time
--- @param indicatorFrame table @The indicator frame to process
--- @param unit string @The unit to process the indicator for
function EnhancedRaidFrames:ProcessIndicator(indicatorFrame, unit)
	local i = indicatorFrame.position
	local parentFrame = indicatorFrame:GetParent()

	local auraInstanceID, icon, count, duration, expirationTime, debuffType, castBy, auraType, auraIndex, _

	--reset auraInstanceID/auraIndex and auraType for tooltip
	indicatorFrame.auraInstanceID = nil
	indicatorFrame.auraIndex = nil --legacy
	indicatorFrame.auraType = nil

	-- if we only are to show the indicator on me, then don't bother if I'm not the unit
	if self.db.profile[i].meOnly then
		local unitName, unitRealm = UnitName(unit)
		if unitName ~= UnitName("player") or unitRealm ~= nil then
			return
		end
	end

	--------------------------------------------------------
	--- parse each aura and find the information of each ---
	--------------------------------------------------------
	for _, auraIdentifier in pairs(self.auraStrings[i]) do
		--if we don't have any auraStrings for this indicator, stop here
		if not parentFrame.ERF_unitAuras then
			return
		end

		-- Check if the aura exist on the unit and grab the information we need if it does
		for _,aura in pairs(parentFrame.ERF_unitAuras) do --loop through list of auras
			if (tonumber(auraIdentifier) and aura.spellID == tonumber(auraIdentifier)) or
					aura.auraName == auraIdentifier or (aura.auraType == "debuff" and aura.debuffType == auraIdentifier) then
				auraInstanceID = aura.auraInstanceID or nil
				auraIndex = aura.auraIndex or nil --legacy
				icon = aura.icon
				count = aura.count
				duration = aura.duration
				expirationTime = aura.expirationTime
				castBy = aura.castBy
				auraType = aura.auraType
				debuffType = aura.debuffType or nil
				break --once we find the aura, we can stop searching
			end
		end
		
		-- add spell icon info to cache in case we need it later on
		if icon and not self.iconCache[auraIdentifier] then
			self.iconCache[auraIdentifier] = icon
		end

		-- when tracking multiple things, this determines "where" we stop in the list
		-- if we find the aura, we can stop querying down the list
		-- we want to stop only when castBy == "player" if we are tracking "mine only"
		if (auraInstanceID or auraIndex) and (not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and castBy == "player")) then
			break
		end
	end

	------------------------------------------------------
	------- output visuals to the indicator frame --------
	------------------------------------------------------

	-- if we find the spell and we don't only want to show when it is missing
	if (auraInstanceID or auraIndex) and not self.db.profile[i].missingOnly and
			(not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and castBy == "player")) then

		-- calculate remainingTime and round down, this is how the game seems to do it
		local remainingTime = expirationTime - GetTime()

		-- set auraInstanceID/auraIndex and auraType for tooltip
		indicatorFrame.auraInstanceID = auraInstanceID
		indicatorFrame.auraIndex = auraIndex --legacy
		indicatorFrame.auraType = auraType

		---------------------------------
		--- process icon to show
		---------------------------------

		if icon and self.db.profile[i].showIcon then
			indicatorFrame.Icon:SetTexture(icon)
			indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
		else
			if self.db.profile[i].colorIndicatorByTime then -- Color by remaining time
				if remainingTime and self.db.profile[i].colorIndicatorByTime_low ~= 0 and remainingTime <= self.db.profile[i].colorIndicatorByTime_low then
					indicatorFrame.Icon:SetColorTexture(self.RED_COLOR:GetRGB())
				elseif remainingTime and self.db.profile[i].colorIndicatorByTime_high ~= 0 and remainingTime <= self.db.profile[i].colorIndicatorByTime_high then
					indicatorFrame.Icon:SetColorTexture(self.YELLOW_COLOR:GetRGB())
				else
					--set color of custom texture
					indicatorFrame.Icon:SetColorTexture(self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
							self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a)
				end
				-- determine if we should change the background color from the default (player set color)
			elseif self.db.profile[i].colorIndicatorByDebuff and debuffType then -- Color by debuff type
				if debuffType == "poison" then
					indicatorFrame.Icon:SetColorTexture(self.GREEN_COLOR:GetRGB())
				elseif debuffType == "curse" then
					indicatorFrame.Icon:SetColorTexture(self.PURPLE_COLOR:GetRGB())
				elseif debuffType == "disease" then
					indicatorFrame.Icon:SetColorTexture(self.BROWN_COLOR:GetRGB())
				elseif debuffType == "magic" then
					indicatorFrame.Icon:SetColorTexture(self.BLUE_COLOR:GetRGB())
				end
			else
				--set color of custom texture
				indicatorFrame.Icon:SetColorTexture(self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
						self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a)
			end
		end

		---------------------------------
		--- process text to show
		---------------------------------
		if self.db.profile[i].showText ~= "none" then
			local formattedTime = ""
			local formattedCount = ""

			-- determine the formatted time string
			if remainingTime and (self.db.profile[i].showText == "stack+countdown" or self.db.profile[i].showText == "countdown") then
				if remainingTime > 60 then
					formattedTime = string.format("%.0f", remainingTime/60).."m" --Show minutes without seconds
				elseif remainingTime >= 0 then
					formattedTime = string.format("%.0f", remainingTime) --Show seconds without decimals
				end
			end

			-- determine the formatted stack string
			if count and count > 0 and (self.db.profile[i].showText == "stack+countdown" or self.db.profile[i].showText == "stack") then
				formattedCount = count
			end

			-- determine the final output string concatenation
			if formattedTime ~= "" and formattedCount ~= "" then
				indicatorFrame.Text:SetText(formattedCount .. "-" .. formattedTime) --append both values together with a hyphen separating
			elseif formattedCount ~= "" then
				indicatorFrame.Text:SetText(formattedCount) --show just the count
			elseif formattedTime ~= "" then
				indicatorFrame.Text:SetText(formattedTime) --show just the time remaining
			end
		else
			indicatorFrame.Text:SetText("")
		end

		---------------------------------
		--- process text color
		---------------------------------
		if self.db.profile[i].colorTextByTime then -- Color by remaining time
			if remainingTime and self.db.profile[i].colorTextByTime_low ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_low then
				indicatorFrame.Text:SetTextColor(self.RED_COLOR:GetRGB())
			elseif remainingTime and self.db.profile[i].colorTextByTime_high ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_high then
				indicatorFrame.Text:SetTextColor(self.YELLOW_COLOR:GetRGB())
			else
				--set default textColor to user selected choice
				indicatorFrame.Text:SetTextColor(self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
						self.db.profile[i].textColor.b, self.db.profile[i].textColor.a)
			end
		elseif self.db.profile[i].colorTextByDebuff and debuffType then -- Color by debuff type
			if debuffType == "poison" then
				indicatorFrame.Text:SetTextColor(self.GREEN_COLOR:GetRGB())
			elseif debuffType == "curse" then
				indicatorFrame.Text:SetTextColor(self.PURPLE_COLOR:GetRGB())
			elseif debuffType == "disease" then
				indicatorFrame.Text:SetTextColor(self.BROWN_COLOR:GetRGB())
			elseif debuffType == "magic" then
				indicatorFrame.Text:SetTextColor(self.BLUE_COLOR:GetRGB())
			end
		else
			--set default textColor to user selected choice
			indicatorFrame.Text:SetTextColor(self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
					self.db.profile[i].textColor.b, self.db.profile[i].textColor.a)
		end

		---------------------------------
		--- set cooldown animation
		---------------------------------
		if self.db.profile[i].showCountdownSwipe and expirationTime and duration then
			CooldownFrame_Set(indicatorFrame.Cooldown, expirationTime - duration, duration, true, true)
		else
			CooldownFrame_Clear(indicatorFrame.Cooldown)
		end

		---------------------------------
		--- set glow animation
		---------------------------------
		if self.db.profile[i].indicatorGlow and (self.db.profile[i].glowRemainingSecs == 0 or self.db.profile[i].glowRemainingSecs >= remainingTime) then
			ActionButton_ShowOverlayGlow(indicatorFrame)
		else
			ActionButton_HideOverlayGlow(indicatorFrame)
		end

		indicatorFrame:Show() --show the frame

	elseif not (auraInstanceID or auraIndex) and self.db.profile[i].missingOnly then --deal with "show only if missing"
		local auraIdentifier = self.auraStrings[i][1] --show the icon for the first auraString position

		--check our iconCache for the auraName. Note the icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons
		if not self.iconCache[auraIdentifier] then
			_,_,icon = GetSpellInfo(auraIdentifier)
			if icon then
				self.iconCache[auraIdentifier] = icon --cache our icon
			else
				icon = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
		else
			icon = self.iconCache[auraIdentifier]
		end

		if self.db.profile[i].showIcon then
			indicatorFrame.Icon:SetTexture(icon)
			indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
			indicatorFrame.Text:SetText("")
		else
			--set color of custom texture
			indicatorFrame.Icon:SetColorTexture(
					self.db.profile[i].indicatorColor.r,
					self.db.profile[i].indicatorColor.g,
					self.db.profile[i].indicatorColor.b,
					self.db.profile[i].indicatorColor.a)
			indicatorFrame.Text:SetText("")
		end

		indicatorFrame:Show() --show the frame

	else
		indicatorFrame:Hide() --hide the frame
		--if no aura is found and we're not showing missing, clear animations and hide the frame
		CooldownFrame_Clear(indicatorFrame.Cooldown)
		ActionButton_HideOverlayGlow(indicatorFrame)
	end
end

------------------------------------------------
----------------- Tooltip Code -----------------
------------------------------------------------

--- Show the tooltip for the indicator
--- @param indicatorFrame table @The indicator frame to process
--- @param parentFrame table @The parent frame of the indicator
function EnhancedRaidFrames:Tooltip_OnEnter(indicatorFrame, parentFrame)
	local i = indicatorFrame.position

	if not self.db.profile[i].showTooltip then --don't show tooltips unless we have the option set for this position
		return
	end

	-- Set the tooltip
	if (indicatorFrame.auraInstanceID or indicatorFrame.auraIndex) and indicatorFrame.auraInstanceID ~= 0 and indicatorFrame.Icon:GetTexture() then
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, self.db.profile[i].tooltipLocation)
		if indicatorFrame.auraType == "buff" then
			if indicatorFrame.auraInstanceID then
				GameTooltip:SetUnitBuffByAuraInstanceID(parentFrame.unit, indicatorFrame.auraInstanceID)
			elseif indicatorFrame.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, indicatorFrame.auraIndex, "HELPFUL")
			end
		elseif indicatorFrame.auraType == "debuff" then
			if indicatorFrame.auraInstanceID then
				GameTooltip:SetUnitDebuffByAuraInstanceID(parentFrame.unit, indicatorFrame.auraInstanceID)
			elseif indicatorFrame.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, indicatorFrame.auraIndex, "HARMFUL")
			end
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		UnitFrame_UpdateTooltip(parentFrame)
	end

	GameTooltip:Show()
end

------------------------------------------------
------------------- Utilities ------------------
------------------------------------------------

--- Generates a table of individual, sanitized aura strings from the raw user text input.
function EnhancedRaidFrames:GenerateAuraStrings()
	-- reset aura strings
	self.allAuras = " " --this is so we can do quick string searches later
	self.auraStrings = {{}, {}, {}, {}, {}, {}, {}, {}, {}}  -- Matrix to keep all aura strings to watch for

	for i = 1, 9 do
		local j = 1
		for auraName in string.gmatch(self.db.profile[i].auras, "[^\n]+") do -- Grab each line
			--sanitize strings
			auraName = auraName:lower() --force lowercase
			auraName = auraName:gsub("^%s*(.-)%s*$", "%1") --strip any leading or trailing whitespace
			auraName = auraName:gsub("\"", "") --strip any quotation marks if there are any
			self.allAuras = self.allAuras.." "..auraName.." " -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			self.auraStrings[i][j] = auraName
			j = j + 1
		end
	end
end

--- Does a quick scan of the current auras on the unit and returns true if any of them are set as tracked.
--- Its primary use is to reduce idle CPU usage by not scanning units that don't have any auras we're tracking.
--- @param frame table @The raid frame to check for tracked auras
function EnhancedRaidFrames:HasTrackedAuras(frame)
	-- If we don't have an aura table for the unit, return false
	if not frame.ERF_unitAuras then
		return false
	end

	-- Check each aura on the unit and return true if we find one we're watching for
	for _, aura in pairs(frame.ERF_unitAuras) do
		-- It's important to use the 4th argument in string.find to turn off pattern matching, 
		-- otherwise strings with parentheses in them will fail to be found
		if self.allAuras:find(" "..aura.auraName:lower().." ", nil, true) or --check for spell name
				self.allAuras:find(aura.spellID) or --check for spell ID
				(aura.auraType == "debuff" and self.allAuras:find(aura.debuffType:lower())) --check for debuff type
		then
			return true
		end
	end

	return false
end