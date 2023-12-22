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
		-- To stop us from creating redundant frames we should try to re-capture them when possible.
		if not _G[frame:GetName() .. "-ERF_indicator-" .. i] then
			frame.ERF_indicatorFrames[i] = CreateFrame("Button", frame:GetName() .. "-ERF_indicator-" .. i,
					frame, "ERF_indicatorTemplate")
		else
			frame.ERF_indicatorFrames[i] = _G[frame:GetName() .. "-ERF_indicator-" .. i]
			-- If we capture an old indicator frame, we should reattach it to the current unit frame.
			frame.ERF_indicatorFrames[i]:SetParent(frame)
		end

		-- Create local pointer for readability
		local indicatorFrame = frame.ERF_indicatorFrames[i]

		-- Indicate the position of this particular frame for use later (i.e. 1->9)
		indicatorFrame.position = i

		-- Hook OnEnter and OnLeave for showing and hiding ability tooltips
		indicatorFrame:SetScript("OnEnter", function()
			self:Tooltip_OnEnter(indicatorFrame, frame)
		end)
		indicatorFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Disable the mouse click on our frames to allow those clicks to get passed straight through to the raid frame.
		-- This MUST come after the SetScript lines for OnEnter and OnLeave. SetScript will re-enable mouse clicks when called.
		indicatorFrame:SetMouseClickEnabled(false)
	end

	-- Set our initial indicator appearance
	self:SetIndicatorAppearance(frame)
end

--- Set the appearance of the Indicator
--- @param frame table @The raid frame of our indicator
function EnhancedRaidFrames:SetIndicatorAppearance(frame)
	-- Loop over all 9 indicators and set their appearance
	for i = 1, 9 do
		-- Create local pointer for readability
		local indicatorFrame = frame.ERF_indicatorFrames[i]

		-- Set icon size
		indicatorFrame:SetWidth(self.db.profile["indicator-" .. i].indicatorSize)
		indicatorFrame:SetHeight(self.db.profile["indicator-" .. i].indicatorSize)

		--------------------------------------

		-- Set the indicator frame position
		local PAD = 1
		local indicatorVerticalOffset = floor((self.db.profile["indicator-" .. i].indicatorVerticalOffset * frame:GetHeight()) + 0.5)
		local indicatorHorizontalOffset = floor((self.db.profile["indicator-" .. i].indicatorHorizontalOffset * frame:GetWidth()) + 0.5)

		-- We probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
		local powerBarVertOffset
		if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
			powerBarVertOffset = frame.powerBar:GetHeight() + 2 -- Add 2 to not overlap the powerBar border
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
					PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset / 2)
		elseif i == 5 then
			indicatorFrame:SetPoint("CENTER", frame, "CENTER",
					0 + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset / 2)
		elseif i == 6 then
			indicatorFrame:SetPoint("RIGHT", frame, "RIGHT",
					-PAD + indicatorHorizontalOffset, 0 + indicatorVerticalOffset + powerBarVertOffset / 2)
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

		-- Set font family and size for our countdown text
		local font = (LibSharedMedia and LibSharedMedia:Fetch('font', self.db.profile.indicatorFont)) or "Fonts\\ARIALN.TTF"
		indicatorFrame.Countdown:SetFont(font, self.db.profile["indicator-" .. i].textSize, "OUTLINE")

		-- Clear the indicator frame
		self:ClearIndicator(indicatorFrame)
	end
end

------------------------------------------------
--------------- Process Indicators -------------
------------------------------------------------

--- Kickstart the indicator processing for all indicators on a given frame
--- @param frame table @The raid frame of our indicators
--- @param setAppearance boolean @Indicates if we should trigger reapply appearance settings to the indicators
function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
	if not self.ShouldContinue(frame) then
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
		if self.auraStrings[i][1] then
			-- Check if we have at least 1 auraString for this location
			-- This is the meat of our processing loop
			self:ProcessIndicator(indicator, frame.unit)
		else
			-- Clear the indicator frame
			self:ClearIndicator(indicator)
		end
	end
end

--- Update all aura indicators
function EnhancedRaidFrames:UpdateAllIndicators()
	-- Don't do any work if the raid frames aren't shown
	if not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown() then
		return
	end

	if not self.isWoWClassicEra and not self.isWoWClassic then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateIndicators(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateIndicators(frame)
		end)
	end
end

--- Process a single indicator location and apply any necessary visual effects for this moment in time
--- @param indicatorFrame table @The indicator frame to process
--- @param unit string @The unit to process the indicator for
function EnhancedRaidFrames:ProcessIndicator(indicatorFrame, unit)
	local i = indicatorFrame.position

	indicatorFrame.thisAura = nil

	-- Stop here if we're only showing the aura on the player and the player is not the unit
	if self.db.profile["indicator-" .. i].meOnly and unit ~= "player" then
		return
	end

	-- Find the current aura, if there is one
	indicatorFrame.thisAura = EnhancedRaidFrames:FindActiveAndTrackedAura(indicatorFrame)

	-- Process our visuals
	if indicatorFrame.thisAura then
		-- Clear the frame if we're only showing missing auras or we're only showing our own auras and the aura isn't ours
		if self.db.profile["indicator-" .. i].missingOnly
				or (self.db.profile["indicator-" .. i].mineOnly and not indicatorFrame.thisAura.sourceUnit == "player") then
			self:ClearIndicator(indicatorFrame)
			return
		end

		-- Only start our ticker and cooldown animation if the aura has a duration
		if indicatorFrame.thisAura.expirationTime and indicatorFrame.thisAura.duration then
			self:StartUpdateTicker(indicatorFrame) -- Start our update ticker
			self:SetCooldownAnimation(indicatorFrame) -- Set the cooldown animation
		end

		self:UpdateIndicatorIcon(indicatorFrame) -- Set our indicator icon
		self:UpdateStackSizeText(indicatorFrame) -- Set our stack size text

		-- Only call these if we don't have a timer running, otherwise it happens in the ticker function
		if self:TimeLeft(indicatorFrame.updateTicker) == 0 then
			self:UpdateIndicatorColor(indicatorFrame) -- Set our indicator color
			self:UpdateCountdownTextColor(indicatorFrame) -- Set our text color
		end

		indicatorFrame:Show() -- Display our aura indicator
	else
		-- If we're tracking missing auras, show the frame and set the icon
		if self.db.profile["indicator-" .. i].missingOnly then
			self:UpdateIndicatorIcon(indicatorFrame) -- Set our indicator icon
			self:UpdateIndicatorColor(indicatorFrame) -- Set our indicator color
			self:UpdateCountdownText(indicatorFrame) -- Clear our countdown text if there is any
			indicatorFrame:Show() -- Display our frame
		else
			self:ClearIndicator(indicatorFrame) -- Clear the indicator if we're not showing missing auras
		end
	end
end

--- Find the current aura for a given indicator frame
--- @param indicatorFrame table @The indicator frame to process
--- @return table @The aura table for the current aura
function EnhancedRaidFrames:FindActiveAndTrackedAura(indicatorFrame)
	local i = indicatorFrame.position
	local parentFrame = indicatorFrame:GetParent()

	-- If our unitAura table doesn't exist, stop here
	if not parentFrame.ERF_unitAuras then
		return
	end

	-- Loop through list of tracked auraStrings
	for _, auraIdentifier in pairs(self.auraStrings[i]) do
		-- Loop through list of the current auras on the unit
		for _, aura in pairs(parentFrame.ERF_unitAuras) do
			-- Check if the aura name matches our auraString
			if aura.name == auraIdentifier
					-- Check if the aura is a spellId and the spellId matches our auraString
					or (tonumber(auraIdentifier) and aura.spellId == tonumber(auraIdentifier))
					-- Check if the aura is a debuff, if it matches the "RAID" filter, and the auraString matches the "dispel" wildcard
					or (aura.isHarmful and aura.isRaid and "dispel" == auraIdentifier)
					-- Check if the aura is a debuff and if the auraString matches one of the debuff type wildcards
					or (aura.isHarmful and aura.dispelName == auraIdentifier) then

				-- Check if we should only show our own auras
				if not self.db.profile["indicator-" .. i].mineOnly
						or (self.db.profile["indicator-" .. i].mineOnly and aura.sourceUnit == "player") then
					-- Return once we find an aura that matches all of these conditions
					return aura

				end
			end
		end
	end
end

--- Process a single tick of our indicator animation for things like color changing, glow, etc
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:IndicatorTick(indicatorFrame)
	if indicatorFrame.thisAura then
		local remainingTime = floor(indicatorFrame.thisAura.expirationTime - GetTime())
		if remainingTime and remainingTime >= 0 then
			self:UpdateCountdownText(indicatorFrame, remainingTime) -- Set the countdown text
			self:UpdateOverlayGlow(indicatorFrame, remainingTime) -- Set glow animation based on time remaining
			self:UpdateCountdownTextColor(indicatorFrame, remainingTime) -- Set indicator text color based on time remaining
			self:UpdateIndicatorColor(indicatorFrame, remainingTime) -- Set indicator background color based on time remaining
		end
	end
end

--- Start the update ticker for our indicator animation
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:StartUpdateTicker(indicatorFrame)
	if not indicatorFrame.updateTicker then
		-- Run straight away to set initial values
		self:IndicatorTick(indicatorFrame)

		-- Only start the ticker if it isn't already running
		indicatorFrame.updateTicker = self:ScheduleRepeatingTimer(function()
			self:IndicatorTick(indicatorFrame)
		end, 0.5)
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

--- Clear all animations and hide the indicator frame
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:ClearIndicator(indicatorFrame)
	indicatorFrame.Cooldown:Clear()
	self:StopUpdateTicker(indicatorFrame)
	self:UpdateOverlayGlow(indicatorFrame)
	self:UpdateCountdownText(indicatorFrame)
	indicatorFrame:Hide() -- Hide the frame
	indicatorFrame.Icon:SetAlpha(1)
end

------------------------------------------------
-------------------- Visuals -------------------
------------------------------------------------

--- Set the cooldown animation on the indicator
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:SetCooldownAnimation(indicatorFrame)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	-- Start the cooldown animation
	if self.db.profile["indicator-" .. i].showCountdownSwipe then
		local startTime = thisAura.expirationTime - thisAura.duration
		local duration = thisAura.duration
		local modRate = thisAura.timeMod or 1
		indicatorFrame.Cooldown:SetCooldown(startTime, duration, modRate)
	end
end

--- Update the countdown text on the indicator
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateCountdownText(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	if self.db.profile["indicator-" .. i].showCountdownText and remainingTime and thisAura then
		if remainingTime < 60 then
			indicatorFrame.Countdown:SetText(remainingTime)
		else
			indicatorFrame.Countdown:SetText(floor(remainingTime / 60) .. "m") -- Convert minutes to seconds
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

	-- Set the stack count text
	if self.db.profile["indicator-" .. i].showStackSize and thisAura.applications and thisAura.applications > 1 then
		-- Set the position of the stack size text based on the user's choice
		-- Since space is limited, we have to move the countdown text to make room for the stack size text
		if self.db.profile["indicator-" .. i].stackSizeLocation == "TOPLEFT" then
			indicatorFrame.StackSize:ClearAllPoints()
			indicatorFrame.StackSize:SetPoint("TOPLEFT", indicatorFrame, "TOPLEFT", -3, 2)
			indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", 1, -1)
		elseif self.db.profile["indicator-" .. i].stackSizeLocation == "TOPRIGHT" then
			indicatorFrame.StackSize:ClearAllPoints()
			indicatorFrame.StackSize:SetPoint("TOPRIGHT", indicatorFrame, "TOPRIGHT", 4, 2)
			indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", -1, -1)
		elseif self.db.profile["indicator-" .. i].stackSizeLocation == "BOTTOMLEFT" then
			indicatorFrame.StackSize:ClearAllPoints()
			indicatorFrame.StackSize:SetPoint("BOTTOMLEFT", indicatorFrame, "BOTTOMLEFT", -3, -2)
			indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", 1, 1)
		elseif self.db.profile["indicator-" .. i].stackSizeLocation == "BOTTOMRIGHT" then
			indicatorFrame.StackSize:ClearAllPoints()
			indicatorFrame.StackSize:SetPoint("BOTTOMRIGHT", indicatorFrame, "BOTTOMRIGHT", 4, -2)
			indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", -1, 1)
		end
		indicatorFrame.StackSize:SetText(thisAura.applications)
	else
		-- Reset the position of the countdown text and clear our stack size text
		indicatorFrame.Countdown:SetPoint("CENTER", indicatorFrame, "CENTER", 0, 0)
		indicatorFrame.StackSize:SetText("")
	end
end

--- Update the indicator icon
--- @param indicatorFrame table @The indicator frame to process
function EnhancedRaidFrames:UpdateIndicatorIcon(indicatorFrame)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	-- Stop here if we've set to not show an icon
	if not self.db.profile["indicator-" .. i].showIcon then
		return
	end

	if thisAura then
		-- Set our active indicator icon
		if thisAura.icon then
			-- If we have an icon, use it
			-- add spell icon info to cache in case we need it later on
			if not self.iconCache[thisAura.name] or self.iconCache[thisAura.spellId] then
				self.iconCache[thisAura.name] = thisAura.icon
				self.iconCache[thisAura.spellId] = thisAura.icon
			end
			indicatorFrame.Icon:SetTexture(thisAura.icon)
		elseif self.iconCache[thisAura.name] then
			-- Look in our icon cache for the name
			indicatorFrame.Icon:SetTexture(self.iconCache[thisAura.name])
		elseif self.iconCache[thisAura.spellId] then
			-- Look in our icon cache for the spellId
			indicatorFrame.Icon:SetTexture(self.iconCache[thisAura.spellId])
		else
			-- If we can't find an icon, use the default question mark icon
			indicatorFrame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		-- Set the alpha of the icon to the user's choice
		indicatorFrame.Icon:SetAlpha(self.db.profile["indicator-" .. i].indicatorAlpha)
	else
		-- Set our "missing" indicator icon
		local auraIdentifier = self.auraStrings[i][1] --show the icon for the first auraString position

		if not self.iconCache[auraIdentifier] then
			-- Check our iconCache for the name. 
			-- Note: The icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons.
			local icon = select(3, GetSpellInfo(auraIdentifier)) -- Query the game for the icon
			if icon then
				self.iconCache[auraIdentifier] = icon --cache our icon if we found one
				indicatorFrame.Icon:SetTexture(icon)
			else
				indicatorFrame.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
		else
			indicatorFrame.Icon:SetTexture(self.iconCache[auraIdentifier])
		end
		-- Set the alpha of the icon to the user's choice
		indicatorFrame.Icon:SetAlpha(self.db.profile["indicator-" .. i].indicatorAlpha)
	end
end

--- Update the indicator color
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateIndicatorColor(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	-- Stop here if we've set to show an icon
	if self.db.profile["indicator-" .. i].showIcon then
		return
	end

	if thisAura then
		-- Set color based on time remaining
		if self.db.profile["indicator-" .. i].colorIndicatorByTime and remainingTime then
			-- Color by remaining time
			if remainingTime and self.db.profile["indicator-" .. i].colorIndicatorByTime_low ~= 0
					and remainingTime <= self.db.profile["indicator-" .. i].colorIndicatorByTime_low then
				indicatorFrame.Icon:SetColorTexture(self.RED_COLOR:GetRGB())
				return
			elseif remainingTime and self.db.profile["indicator-" .. i].colorIndicatorByTime_high ~= 0
					and remainingTime <= self.db.profile["indicator-" .. i].colorIndicatorByTime_high then
				indicatorFrame.Icon:SetColorTexture(self.YELLOW_COLOR:GetRGB())
				return
			end
		end

		-- Set the color by debuff type
		if self.db.profile["indicator-" .. i].colorIndicatorByDebuff and thisAura.isHarmful and thisAura.dispelName then
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

	-- Set the color to the user select choice
	indicatorFrame.Icon:SetColorTexture(unpack(self.db.profile["indicator-" .. i].indicatorColor))
end

--- Update the indicator countdown text color
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateCountdownTextColor(indicatorFrame, remainingTime)
	local i = indicatorFrame.position
	local thisAura = indicatorFrame.thisAura

	if thisAura then
		-- Set color based on time remaining
		if self.db.profile["indicator-" .. i].colorTextByTime and remainingTime then
			-- Color by remaining time
			if self.db.profile["indicator-" .. i].colorTextByTime_low ~= 0
					and remainingTime <= self.db.profile["indicator-" .. i].colorTextByTime_low then
				indicatorFrame.Countdown:SetTextColor(self.RED_COLOR:GetRGB())
				return
			elseif self.db.profile["indicator-" .. i].colorTextByTime_high ~= 0
					and remainingTime <= self.db.profile["indicator-" .. i].colorTextByTime_high then
				indicatorFrame.Countdown:SetTextColor(self.YELLOW_COLOR:GetRGB())
				return
			end
		end

		-- Set the color by debuff type
		if self.db.profile["indicator-" .. i].colorTextByDebuff and thisAura.isHarmful and thisAura.dispelName then
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

	-- Set the color to the user select choice
	indicatorFrame.Countdown:SetTextColor(unpack(self.db.profile["indicator-" .. i].textColor))
end

--- Update the indicator glow effect
--- @param indicatorFrame table @The indicator frame to process
--- @param remainingTime number @The time remaining on the aura
function EnhancedRaidFrames:UpdateOverlayGlow(indicatorFrame, remainingTime)
	local i = indicatorFrame.position

	if self.db.profile["indicator-" .. i].indicatorGlow and remainingTime
			and (self.db.profile["indicator-" .. i].glowRemainingSecs == 0
			or self.db.profile["indicator-" .. i].glowRemainingSecs >= remainingTime) then
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
	if not self.db.profile["indicator-" .. i].showTooltip or not thisAura then
		return
	end

	-- Set the tooltip
	if indicatorFrame.Icon:GetTexture() then
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, self.db.profile["indicator-" .. i].tooltipLocation)
		if thisAura.isHelpful then
			if thisAura.auraInstanceID then
				GameTooltip:SetUnitBuffByAuraInstanceID(parentFrame.unit, thisAura.auraInstanceID)
			elseif thisAura.auraIndex then
				-- The legacy way to set the tooltip for an aura
				GameTooltip:SetUnitAura(parentFrame.unit, thisAura.auraIndex, "HELPFUL")
			end
		elseif thisAura.isHarmful then
			if thisAura.auraInstanceID then
				GameTooltip:SetUnitDebuffByAuraInstanceID(parentFrame.unit, thisAura.auraInstanceID)
			elseif thisAura.auraIndex then
				-- The legacy way to set the tooltip for an aura
				if thisAura.isRaid then
					-- This is a raid debuff (aka dispellable), it uses a different UnitAura filter
					GameTooltip:SetUnitAura(parentFrame.unit, thisAura.auraIndex, "RAID|HARMFUL")
				else
					GameTooltip:SetUnitAura(parentFrame.unit, thisAura.auraIndex, "HARMFUL")
				end
			end
		end
	else
		-- Causes the tooltip to reset to the "default" tooltip which is usually information about the character
		UnitFrame_UpdateTooltip(parentFrame)
	end
end

------------------------------------------------
------------------- Utilities ------------------
------------------------------------------------

--- Generates a table of individual, sanitized aura strings from the raw user text input.
function EnhancedRaidFrames:GenerateAuraStrings()
	-- Reset the aura strings
	self.allAuras = " " -- Used for quick boolean searches
	self.auraStrings = { {}, {}, {}, {}, {}, {}, {}, {}, {} }  -- Matrix to keep all aura strings to watch for

	for i = 1, 9 do
		local rawStrings = {}
		-- Split the user input into individual strings based on new lines
		for rawString in self.db.profile["indicator-" .. i].auras:gmatch("[^\n]+") do
			table.insert(rawStrings, rawString)
		end

		-- Process each line
		for j, rawString in ipairs(rawStrings) do
			-- Sanitize strings
			local auraString = self:SanitizeAuraString(rawString)
			-- Add each watched aura to a matrix for quick searching later
			self.auraStrings[i][j] = auraString
			-- Add each watched aura to a single large string for quick boolean searches later on
			self.allAuras = self.allAuras .. " " .. auraString .. " "
		end
	end
end

--- Sanitize a single aura string
--- @param auraString string @The aura string to sanitize
function EnhancedRaidFrames:SanitizeAuraString(auraString)
	auraString = auraString:lower() -- Force lowercase
	auraString = auraString:gsub("^%s*(.-)%s*$", "%1") -- Strip any leading or trailing whitespace
	auraString = auraString:gsub("\"", "") -- Strip any quotation marks if there are any
	return auraString
end
