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
			--We have to use CompactAuraTemplate to allow for our clicks to be passed through, otherwise our frames won't 
			--allow selecting the raid frame behind it
			frame.ERF_indicatorFrames[i] = CreateFrame("Button", frame:GetName().."-ERF_indicator-"..i,
					frame, "ERF_indicatorTemplate")
		else
			frame.ERF_indicatorFrames[i] =  _G[frame:GetName().."-ERF_indicator-"..i]
			--if we capture an old indicator frame, we should reattach it to the current unit frame
			frame.ERF_indicatorFrames[i]:SetParent(frame)
		end

		--create local pointer for readability
		local indicatorFrame = frame.ERF_indicatorFrames[i]

		--mark the position of this particular frame for use later (i.e. 1->9)
		indicatorFrame.position = i

		--hook OnEnter and OnLeave for showing and hiding ability tooltips
		indicatorFrame:SetScript("OnEnter", function() self:Tooltip_OnEnter(indicatorFrame, frame) end)
		indicatorFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

		--disable the mouse click on our frames to allow those clicks to get passed straight through to the raid frame 
		--behind (switch target, right click, etc)
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
			indicatorFrame:SetPoint("TOPLEFT", frame, "TOPLEFT",
					PAD + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 2 then
			indicatorFrame:SetPoint("TOP", frame, "TOP",
					0 + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 3 then
			indicatorFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
					-PAD + indicatorHorizontalOffset, -PAD + indicatorVerticalOffset)
		elseif i == 4 then
			indicatorFrame:SetPoint("LEFT", frame, "LEFT",
					PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 5 then
			indicatorFrame:SetPoint("CENTER", frame, "CENTER",
					0 + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 6 then
			indicatorFrame:SetPoint("RIGHT", frame, "RIGHT",
					-PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset/2)
		elseif i == 7 then
			indicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT",
					PAD + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		elseif i == 8 then
			indicatorFrame:SetPoint("BOTTOM", frame, "BOTTOM",
					0 + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		elseif i == 9 then
			indicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
					-PAD + indicatorHorizontalOffset, PAD + indicatorVerticalOffset + powerBarVertOffset)
		end

		--------------------------------------

		--Set font family and size for our countdown text
		local font = (LibSharedMedia and LibSharedMedia:Fetch('font', self.db.profile.indicatorFont)) or "Fonts\\ARIALN.TTF"
		indicatorFrame.Countdown:SetFont(font, self.db.profile[i].textSize, "OUTLINE")

		--clear any animations
		indicatorFrame.Cooldown:Clear()
		self:StopUpdateTicker(indicatorFrame)
		self:UpdateOverlayGlow(indicatorFrame)
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
	
	indicatorFrame.thisAura = nil

	--stop here if we're only showing the unit on us and we are not the unit
	if self.db.profile[i].meOnly and unit ~= "player" then
		return
	end

	----------------------------------------------------------
	------------------- Find the Aura ------------------------
	----------------------------------------------------------
	for _, auraIdentifier in pairs(self.auraStrings[i]) do
		--if our unitAura table doesn't exist, stop here
		if not parentFrame.ERF_unitAuras then
			return
		end

		-- Check if the aura exist on the unit and grab the information we need if it does
		for _,aura in pairs(parentFrame.ERF_unitAuras) do --loop through list of auras
			if aura.name == auraIdentifier or (tonumber(auraIdentifier) and aura.spellId == tonumber(auraIdentifier)) or
					(aura.isHarmful and aura.dispelName == auraIdentifier) then
				indicatorFrame.thisAura = aura --for easy access from our IndicatorTick and Tooltip functions
				break --once we find the aura, we can stop searching
			end
		end

		-- add spell icon info to cache in case we need it later on
		if indicatorFrame.thisAura and indicatorFrame.thisAura.icon and not self.iconCache[auraIdentifier] then
			self.iconCache[auraIdentifier] = indicatorFrame.thisAura.icon
		end

		-- when tracking multiple things, this determines "where" we stop in the list
		-- if we find the aura, we can stop querying down the list
		-- we want to stop only when sourceUnit == "player" if we are tracking "mine only"
		if indicatorFrame.thisAura and (not self.db.profile[i].mineOnly or 
				(self.db.profile[i].mineOnly and indicatorFrame.thisAura.sourceUnit == "player")) then
			break
		end
	end

	------------------------------------------------------
	------------------- Apply Visuals --------------------
	------------------------------------------------------

	--- Primary indicator processing pipeline if we find the aura (and we don't only want to show when it is missing)
	if indicatorFrame.thisAura and not self.db.profile[i].missingOnly and (not self.db.profile[i].mineOnly or 
			(self.db.profile[i].mineOnly and indicatorFrame.thisAura.sourceUnit == "player")) then

		--- Set the cooldown animation
		if self.db.profile[i].showCountdownSwipe and indicatorFrame.thisAura.expirationTime and indicatorFrame.thisAura.duration then
			indicatorFrame.Cooldown:SetCooldown(indicatorFrame.thisAura.expirationTime - indicatorFrame.thisAura.duration, 
					indicatorFrame.thisAura.duration, indicatorFrame.thisAura.timeMod)
		end

		--- Start our update ticker
		if indicatorFrame.thisAura.expirationTime and indicatorFrame.thisAura.duration then
			self:StartUpdateTicker(indicatorFrame)
		end

		--- Set our indicator icon
		self:UpdateIndicatorIcon(indicatorFrame)

		--- Set our indicator color
		if self:TimeLeft(indicatorFrame.updateTicker) == 0 then --only run this if we don't have a timer running
			self:UpdateIndicatorColor(indicatorFrame)
		end

		--- Set our stack size text
		self:UpdateStackSizeText(indicatorFrame)

		--- Set our text color
		if self:TimeLeft(indicatorFrame.updateTicker) == 0 then --only run this if we don't have a timer running
			self:UpdateCountdownTextColor(indicatorFrame)
		end

		---Display our frame
		indicatorFrame:Show()

	elseif not indicatorFrame.thisAura and self.db.profile[i].missingOnly then
		--- Deal with "show only if missing" condition

		--- Set our indicator icon
		self:UpdateIndicatorIcon(indicatorFrame)

		--- Set our indicator color
		self:UpdateIndicatorColor(indicatorFrame)

		--- Clear our countdown text if there is any
		self:UpdateCountdownText(indicatorFrame)

		--- Display our frame
		indicatorFrame:Show()

	else
		--- If we don't find the aura and we're not showing missing, clear animations and hide the frame
		indicatorFrame.Cooldown:Clear()
		self:StopUpdateTicker(indicatorFrame)
		self:UpdateOverlayGlow(indicatorFrame)
		self:UpdateCountdownText(indicatorFrame)
		indicatorFrame:Hide() --hide the frame
	end
end

--- Process a single tick of our indicator animation for things like color changing, glow, etc
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:IndicatorTick(indicatorFrame)
	if indicatorFrame.thisAura then
		local remainingTime = floor(indicatorFrame.thisAura.expirationTime - GetTime())

		if remainingTime and remainingTime >= 0 then
			--- Set the countdown text
			self:UpdateCountdownText(indicatorFrame, remainingTime)

			--- Set glow animation based on time remaining
			self:UpdateOverlayGlow(indicatorFrame, remainingTime)

			--- Set indicator text color based on time remaining
			self:UpdateCountdownTextColor(indicatorFrame, remainingTime)

			--- Set indicator background color based on time remaining
			self:UpdateIndicatorColor(indicatorFrame, remainingTime)
		end
	end
end

--- Start the update ticker for our indicator animation
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:StartUpdateTicker(indicatorFrame)
	self:IndicatorTick(indicatorFrame) --run right away to set initial values
	if not indicatorFrame.updateTicker then --only start the ticker if it isn't already running
		indicatorFrame.updateTicker = self:ScheduleRepeatingTimer(function() self:IndicatorTick(indicatorFrame) end, 0.5)
	end
end

--- Stop the update ticker for our indicator animation
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:StopUpdateTicker(indicatorFrame)
	if indicatorFrame.updateTicker then
		self:CancelTimer(indicatorFrame.updateTicker)
		indicatorFrame.updateTicker = nil
	end
end

------------------------------------------------
-------------------- Visuals -------------------
------------------------------------------------

--- Update the countdown text on the indicator
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateCountdownText(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	if self.db.profile[i].showCountdownText and remainingTime and thisAura then
		if remainingTime < 60 then
			indicatorFrame.Countdown:SetText(remainingTime)
		else
			indicatorFrame.Countdown:SetText(floor(remainingTime/60).."m") --shorten to minutes instead of seconds
		end
	else
		indicatorFrame.Countdown:SetText("")
	end
end

--- Update the stack size text on the indicator
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:UpdateStackSizeText(indicatorFrame)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	--Set the stack count text
	if self.db.profile[i].showStackSize and thisAura.applications and thisAura.applications > 1 then
		--adjust the position of the countdown text to make room for the stack count
		indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", -1, 1)
		indicatorFrame.Count:SetText(thisAura.applications)
	else
		--reset the position of the countdown text
		indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)
		indicatorFrame.Count:SetText("")
	end
end

--- Update the indicator icon
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:UpdateIndicatorIcon(indicatorFrame)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	-- Stop here if we've set to not show an icon
	if not self.db.profile[i].showIcon then
		return
	end

	if thisAura then
		--- Set our active indicator icon
		if thisAura.icon then --if we have an icon, use it
			indicatorFrame.Icon:SetTexture(thisAura.icon)
		elseif self.iconCache[thisAura.name] then --look in our icon cache for the name
			indicatorFrame.Icon:SetTexture(self.iconCache[thisAura.name])
		elseif self.iconCache[thisAura.spellId] then --look in our icon cache for the spellId
			indicatorFrame.Icon:SetTexture(self.iconCache[thisAura.spellId])
		else --if we don't have an icon, use the default question mark
			indicatorFrame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		--set the alpha of the icon
		indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
	else
		--- Set our "missing" indicator icon
		local auraIdentifier = self.auraStrings[i][1] --show the icon for the first auraString position

		-- Check our iconCache for the name. 
		-- Note: The icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons.
		if not self.iconCache[auraIdentifier] then
			-- Query the game for the icon
			local icon = select(3, GetSpellInfo(auraIdentifier)) --icon is the 3rd return value of GetSpellInfo
			if icon then
				self.iconCache[auraIdentifier] = icon --cache our icon if we found one
				indicatorFrame.Icon:SetTexture(icon)
			else
				indicatorFrame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
		else
			indicatorFrame.Icon:SetTexture(self.iconCache[auraIdentifier])
		end
		--set the alpha of the icon
		indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
	end
end

--- Update the indicator color
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateIndicatorColor(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	-- Stop here if we've set to show an icon
	if self.db.profile[i].showIcon then
		return
	end

	if thisAura then
		--- Set color based on time remaining
		if self.db.profile[i].colorIndicatorByTime and remainingTime then -- Color by remaining time
			if remainingTime and self.db.profile[i].colorIndicatorByTime_low ~= 0 
					and remainingTime <= self.db.profile[i].colorIndicatorByTime_low then
				indicatorFrame.Icon:SetColorTexture(self.RED_COLOR:GetRGB())
				return
			elseif remainingTime and self.db.profile[i].colorIndicatorByTime_high ~= 0 
					and remainingTime <= self.db.profile[i].colorIndicatorByTime_high then
				indicatorFrame.Icon:SetColorTexture(self.YELLOW_COLOR:GetRGB())
				return
			end
		end

		--- Set the color by debuff type
		if self.db.profile[i].colorIndicatorByDebuff and thisAura.isHarmful and thisAura.dispelName then
			if thisAura.dispelName == "poison" then
				indicatorFrame.Icon:SetColorTexture(self.GREEN_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "curse" then
				indicatorFrame.Icon:SetColorTexture(self.PURPLE_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "disease" then
				indicatorFrame.Icon:SetColorTexture(self.BROWN_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "magic" then
				indicatorFrame.Icon:SetColorTexture(self.BLUE_COLOR:GetRGB())
				return
			end
		end
	end

	--- Set the color to the user select choice
	indicatorFrame.Icon:SetColorTexture(self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
			self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a)
end

--- Update the indicator countdown text color
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateCountdownTextColor(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	if thisAura then
		--- Set color based on time remaining
		if self.db.profile[i].colorTextByTime and remainingTime then -- Color by remaining time
			if self.db.profile[i].colorTextByTime_low ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_low then
				indicatorFrame.Countdown:SetTextColor(self.RED_COLOR:GetRGB())
				return
			elseif self.db.profile[i].colorTextByTime_high ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_high then
				indicatorFrame.Countdown:SetTextColor(self.YELLOW_COLOR:GetRGB())
				return
			end
		end

		--- Set the color by debuff type
		if self.db.profile[i].colorTextByDebuff and thisAura.isHarmful and thisAura.dispelName then
			if thisAura.dispelName == "poison" then
				indicatorFrame.Countdown:SetTextColor(self.GREEN_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "curse" then
				indicatorFrame.Countdown:SetTextColor(self.PURPLE_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "disease" then
				indicatorFrame.Countdown:SetTextColor(self.BROWN_COLOR:GetRGB())
				return
			elseif thisAura.dispelName == "magic" then
				indicatorFrame.Countdown:SetTextColor(self.BLUE_COLOR:GetRGB())
				return
			end
		end
	end

	--- Set the color to the user select choice
	indicatorFrame.Countdown:SetTextColor(self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
			self.db.profile[i].textColor.b, self.db.profile[i].textColor.a)
end

--- Update the indicator glow effect
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateOverlayGlow(indicatorFrame, remainingTime)
	local i = indicatorFrame.position

	if self.db.profile[i].indicatorGlow and remainingTime 
			and (self.db.profile[i].glowRemainingSecs == 0 or self.db.profile[i].glowRemainingSecs >= remainingTime) then
		ActionButton_ShowOverlayGlow(indicatorFrame)
	else
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
	local thisAura = indicatorFrame.thisAura

	-- Stop here if we've set to not show a tooltip or we don't have an active aura
	if not self.db.profile[i].showTooltip or not thisAura then
		return
	end

	-- Set the tooltip
	if (thisAura.auraInstanceID or thisAura.auraIndex) and indicatorFrame.Icon:GetTexture() then
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, self.db.profile[i].tooltipLocation)
		if thisAura.isHelpful then
			if thisAura.auraInstanceID then
				GameTooltip:SetUnitBuffByAuraInstanceID(parentFrame.unit, thisAura.auraInstanceID)
			elseif indicatorFrame.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, thisAura.auraIndex, "HELPFUL")
			end
		elseif thisAura.isHarmful then
			if thisAura.auraInstanceID then
				GameTooltip:SetUnitDebuffByAuraInstanceID(parentFrame.unit, thisAura.auraInstanceID)
			elseif thisAura.auraIndex then --the legacy way of doing things
				GameTooltip:SetUnitAura(parentFrame.unit, thisAura.auraIndex, "HARMFUL")
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
			-- Add each watched aura to a string so we later can quickly determine if we need to look for one
			self.allAuras = self.allAuras.." "..name.." "
			self.auraStrings[i][j] = name
			j = j + 1
		end
	end
end