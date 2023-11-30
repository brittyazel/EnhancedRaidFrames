-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local LibSharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

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
		if not _G[frame:GetName().."-ERF_indicator-"..i] then
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

		--hook OnCooldownDone for stopping our update ticker
		indicatorFrame.Cooldown:SetScript("OnCooldownDone", function() self:StopUpdateTicker(indicatorFrame) end)

		--disable the mouse click on our frames to allow those clicks to get passed straight through to the raid frame behind (switch target, right click, etc)
		--this MUST come after the SetScript lines for OnEnter and OnLeave. SetScript will re-enable mouse clicks when called.
		indicatorFrame:SetMouseClickEnabled(false)

		--capture a handle to our countdown font region which is managing our countdown text via the C_Cooldown API
		if not indicatorFrame.CountdownText then
			indicatorFrame.CountdownText = indicatorFrame.Cooldown:GetRegions()
		end
		
		if not indicatorFrame.Count then
			--create a handle that's easy to access for our stack count text
			indicatorFrame.Count = indicatorFrame.Cooldown.Count
		end
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
		--Set font family and size for our countdown text
		local font = (LibSharedMedia and LibSharedMedia:Fetch('font', self.db.profile.indicatorFont)) or "Fonts\\ARIALN.TTF"
		indicatorFrame.CountdownText:SetFont(font, self.db.profile[i].textSize, "OUTLINE")

		--Either show or hide the countdown swipe animation
		if self.db.profile[i].showCountdownSwipe then
			indicatorFrame.Cooldown:SetDrawSwipe(true)
			indicatorFrame.Cooldown:SetDrawEdge(true)
		else
			indicatorFrame.Cooldown:SetDrawSwipe(false)
			indicatorFrame.Cooldown:SetDrawEdge(false)
		end

		--Set the countdown text position
		indicatorFrame.CountdownText:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)

		--Set the countdown text to show or hide
		if self.db.profile[i].showCountdownText then
			indicatorFrame.Cooldown:SetHideCountdownNumbers(false)
		else
			indicatorFrame.Cooldown:SetHideCountdownNumbers(true)
		end
		
		--clear any animations
		ActionButton_HideOverlayGlow(indicatorFrame)
		indicatorFrame.Cooldown:Clear()
		self:StopUpdateTicker(indicatorFrame)
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

	self:UpdateStockIndicatorVisibility(frame)

	-- Create the indicator frame if it doesn't exist, otherwise just update the appearance
	if not frame.ERF_indicatorFrames then
		self:CreateIndicators(frame)
	else
		if setAppearance then
			self:SetIndicatorAppearance(frame)
		end
	end

	-- Loop over all 9 indicators and process them individually
	for i, indicator in ipairs(frame.ERF_indicatorFrames) do
		--if we don't have any auraStrings for this indicator, stop here
		if self.auraStrings[i][1] then --check if we have at least 1 auraString for this location
			-- this is the meat of our processing loop
			self:ProcessIndicator(indicator, frame.unit)
		else
			indicator:Hide() --hide the frame
		end
	end
end

--- Update all aura indicators
function EnhancedRaidFrames:UpdateAllIndicators()
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return
	end

	-- This is the heart and soul of the addon. Everything gets called from here.
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			if frame and frame.unit then
				self:UpdateIndicators(frame)
			end
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			if frame and frame.unit then
				self:UpdateIndicators(frame)
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

	--holds the information of the aura we're looking for once it is found
	local thisAura = {}
	indicatorFrame.thisAura = {} --for easy access from our tooltip code

	-- if we only are to show the indicator on me, then don't bother if I'm not the unit
	if self.db.profile[i].meOnly then
		if unit ~= "player" then
			return
		end
	end

	----------------------------------------------------------
	---- parse each aura and find the information of each ----
	----------------------------------------------------------
	for _, auraIdentifier in pairs(self.auraStrings[i]) do
		--if we don't have any auraStrings for this indicator, stop here
		if not parentFrame.ERF_unitAuras then
			return
		end

		-- Check if the aura exist on the unit and grab the information we need if it does
		for _,aura in pairs(parentFrame.ERF_unitAuras) do --loop through list of auras
			if aura.name == auraIdentifier or (tonumber(auraIdentifier) and aura.spellId == tonumber(auraIdentifier)) or
					(aura.isHarmful and aura.dispelName == auraIdentifier) then
				thisAura = aura
				indicatorFrame.thisAura = aura
				break --once we find the aura, we can stop searching
			end
		end

		-- add spell icon info to cache in case we need it later on
		if thisAura.icon and not self.iconCache[auraIdentifier] then
			self.iconCache[auraIdentifier] = thisAura.icon
		end

		-- when tracking multiple things, this determines "where" we stop in the list
		-- if we find the aura, we can stop querying down the list
		-- we want to stop only when sourceUnit == "player" if we are tracking "mine only"
		if (thisAura.auraInstanceID or thisAura.auraIndex) and (not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and thisAura.sourceUnit == "player")) then
			break
		end
	end

	------------------------------------------------------
	------- output visuals to the indicator frame --------
	------------------------------------------------------

	-- if we find the spell and we don't only want to show when it is missing
	if (thisAura.auraInstanceID or thisAura.auraIndex) and not self.db.profile[i].missingOnly and
			(not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and thisAura.sourceUnit == "player")) then
		
		---------------------------------
		---------- Set cooldown ---------
		---------------------------------
		if thisAura.expirationTime and thisAura.duration then
			indicatorFrame.Cooldown:SetCooldown(thisAura.expirationTime - thisAura.duration, thisAura.duration);
			self:StartUpdateTicker(indicatorFrame, thisAura)
		else
			indicatorFrame.Cooldown:Clear()
			self:StopUpdateTicker(indicatorFrame)
		end
		
		---------------------------------
		----- Process icon to show ------
		---------------------------------
		if thisAura.icon and self.db.profile[i].showIcon then
			indicatorFrame.Icon:SetTexture(thisAura.icon)
			indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
		else
			if self.db.profile[i].colorIndicatorByDebuff and thisAura.dispelName then -- Color by debuff type
				if thisAura.dispelName == "poison" then
					indicatorFrame.Icon:SetColorTexture(self.GREEN_COLOR:GetRGB())
				elseif thisAura.dispelName == "curse" then
					indicatorFrame.Icon:SetColorTexture(self.PURPLE_COLOR:GetRGB())
				elseif thisAura.dispelName == "disease" then
					indicatorFrame.Icon:SetColorTexture(self.BROWN_COLOR:GetRGB())
				elseif thisAura.dispelName == "magic" then
					indicatorFrame.Icon:SetColorTexture(self.BLUE_COLOR:GetRGB())
				end
			else
				--set color of custom texture
				indicatorFrame.Icon:SetColorTexture(self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
						self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a)
			end
		end

		---------------------------------
		-------- Process text -----------
		---------------------------------
		--Set the stack count text
		if self.db.profile[i].showStackSize and thisAura.applications and thisAura.applications > 1 then
			--adjust the position of the countdown text to make room for the stack count
			indicatorFrame.CountdownText:SetPoint("CENTER", indicatorFrame, "CENTER", -1, 1)
			indicatorFrame.Count:SetText(thisAura.applications)
		else
			--reset the position of the countdown text
			indicatorFrame.CountdownText:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)
			indicatorFrame.Count:SetText("")
		end

		--Set the countdown text color
		if self.db.profile[i].colorTextByDebuff and thisAura.isHarmful and thisAura.dispelName then -- Color by debuff type
			if thisAura.dispelName == "poison" then
				indicatorFrame.CountdownText:SetTextColor(self.GREEN_COLOR:GetRGB())
			elseif thisAura.dispelName == "curse" then
				indicatorFrame.CountdownText:SetTextColor(self.PURPLE_COLOR:GetRGB())
			elseif thisAura.dispelName == "disease" then
				indicatorFrame.CountdownText:SetTextColor(self.BROWN_COLOR:GetRGB())
			elseif thisAura.dispelName == "magic" then
				indicatorFrame.CountdownText:SetTextColor(self.BLUE_COLOR:GetRGB())
			end
		else
			--set default textColor to user selected choice
			indicatorFrame.CountdownText:SetTextColor(self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
					self.db.profile[i].textColor.b, self.db.profile[i].textColor.a)
		end

		---------------------------------
		------ Display our frame --------
		---------------------------------
		indicatorFrame:Show() --show the frame
		
		--- Deal with "show only if missing"
	elseif self.db.profile[i].missingOnly and not (thisAura.auraInstanceID or thisAura.auraIndex) then
		local auraIdentifier = self.auraStrings[i][1] --show the icon for the first auraString position
		local icon

		--check our iconCache for the name. Note the icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons
		if not self.iconCache[auraIdentifier] then
			icon = select(3, GetSpellInfo(auraIdentifier)) --icon is the 3rd return value of GetSpellInfo
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
		else
			--set color of custom texture
			indicatorFrame.Icon:SetColorTexture(
					self.db.profile[i].indicatorColor.r,
					self.db.profile[i].indicatorColor.g,
					self.db.profile[i].indicatorColor.b,
					self.db.profile[i].indicatorColor.a)
		end
		
		--Display our frame
		indicatorFrame:Show() --show the frame

	else
		--if no aura is found and we're not showing missing, clear animations and hide the frame
		indicatorFrame.Cooldown:Clear()
		self:StopUpdateTicker(indicatorFrame)
		ActionButton_HideOverlayGlow(indicatorFrame)
		indicatorFrame:Hide() --hide the frame
	end
end

--- Process a single tick of our indicator animation for things like color changing, glow, etc
--- @param indicatorFrame table @The indicator frame to process
--- @param aura table @The aura to process
function EnhancedRaidFrames:IndicatorTick(indicatorFrame, aura)
	if not indicatorFrame:IsShown() then
		return
	end
	
	local i = indicatorFrame.position

	local startTimeMs, durationMs = indicatorFrame.Cooldown:GetCooldownTimes();
	local remainingTimeSeconds = floor((durationMs / 1000.0) - (GetTime() - (startTimeMs / 1000.0)) + 0.5)

	--- Set glow animation based on time remaining
	if self.db.profile[i].indicatorGlow and (self.db.profile[i].glowRemainingSecs == 0 or self.db.profile[i].glowRemainingSecs >= remainingTimeSeconds) then
		ActionButton_ShowOverlayGlow(indicatorFrame)
	else
		ActionButton_HideOverlayGlow(indicatorFrame)
	end

	--- Set indicator background color based on time remaining
	if self.db.profile[i].colorIndicatorByTime and not (aura.icon and self.db.profile[i].showIcon) then -- Color by remaining time
		if remainingTimeSeconds and self.db.profile[i].colorIndicatorByTime_low ~= 0 and remainingTimeSeconds <= self.db.profile[i].colorIndicatorByTime_low then
			indicatorFrame.Icon:SetColorTexture(self.RED_COLOR:GetRGB())
		elseif remainingTimeSeconds and self.db.profile[i].colorIndicatorByTime_high ~= 0 and remainingTimeSeconds <= self.db.profile[i].colorIndicatorByTime_high then
			indicatorFrame.Icon:SetColorTexture(self.YELLOW_COLOR:GetRGB())
		end
	end

	--- Set indicator text color based on time remaining
	if self.db.profile[i].colorTextByTime then -- Color by remaining time
		if remainingTimeSeconds and self.db.profile[i].colorTextByTime_low ~= 0 and remainingTimeSeconds <= self.db.profile[i].colorTextByTime_low then
			indicatorFrame.CountdownText:SetTextColor(self.RED_COLOR:GetRGB())
		elseif remainingTimeSeconds and self.db.profile[i].colorTextByTime_high ~= 0 and remainingTimeSeconds <= self.db.profile[i].colorTextByTime_high then
			indicatorFrame.CountdownText:SetTextColor(self.YELLOW_COLOR:GetRGB())
		end
	end
end

--- Start the update ticker for our indicator animation
--- @param indicatorFrame table @The indicator frame to process
--- @param aura table @The aura to process
function EnhancedRaidFrames:StartUpdateTicker(indicatorFrame, aura)
	if indicatorFrame.updateTicker then
		self:StopUpdateTicker(indicatorFrame)
	end
	indicatorFrame.updateTicker = C_Timer.NewTicker(1.0, function() self:IndicatorTick(indicatorFrame, aura) end);
end

--- Stop the update ticker for our indicator animation
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:StopUpdateTicker(indicatorFrame)
	if not indicatorFrame.updateTicker then
		return
	end
	indicatorFrame.updateTicker:Cancel()
	indicatorFrame.updateTicker = nil
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
	if (indicatorFrame.thisAura.auraInstanceID or indicatorFrame.thisAura.auraIndex) and indicatorFrame.Icon:GetTexture() then
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, self.db.profile[i].tooltipLocation)
		if indicatorFrame.thisAura.isHelpful then
			if indicatorFrame.thisAura.auraInstanceID then
				GameTooltip:SetUnitBuffByAuraInstanceID(parentFrame.unit, indicatorFrame.thisAura.auraInstanceID)
			elseif indicatorFrame.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, indicatorFrame.thisAura.auraIndex, "HELPFUL")
			end
		elseif indicatorFrame.thisAura.isHarmful then
			if indicatorFrame.thisAura.auraInstanceID then
				GameTooltip:SetUnitDebuffByAuraInstanceID(parentFrame.unit, indicatorFrame.thisAura.auraInstanceID)
			elseif indicatorFrame.thisAura.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, indicatorFrame.thisAura.auraIndex, "HARMFUL")
			end
		end
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		UnitFrame_UpdateTooltip(parentFrame)
	end
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
		for name in string.gmatch(self.db.profile[i].auras, "[^\n]+") do -- Grab each line
			--sanitize strings
			name = name:lower() --force lowercase
			name = name:gsub("^%s*(.-)%s*$", "%1") --strip any leading or trailing whitespace
			name = name:gsub("\"", "") --strip any quotation marks if there are any
			self.allAuras = self.allAuras.." "..name.." " -- Add each watched aura to a string so we later can quickly determine if we need to look for one
			self.auraStrings[i][j] = name
			j = j + 1
		end
	end
end