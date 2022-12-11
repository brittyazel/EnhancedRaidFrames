-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- TODO: Covert strings to ids and cache it
-- Probably want to move to adding spell ids over spell names in the interface with the possibility of inputing names that are converted to ids on the spot?
-- This way we can avoid all string matching, and some buffs/debuffs have the same name but not same spell ids, guardian berserk & feral berserk for instance.

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local unitAuras = {}
local unitDebuffs = {}

EnhancedRaidFrames.iconCache = {}
EnhancedRaidFrames.iconCache["poison"] = 132104
EnhancedRaidFrames.iconCache["disease"] = 132099
EnhancedRaidFrames.iconCache["curse"] = 132095
EnhancedRaidFrames.iconCache["magic"] = 135894

EnhancedRaidFrames.debug = false

local unitStates = {}

local dispels = {}
dispels.magic = {
	32375, -- Mass Dispell
}

dispels.magicPet = {
	89808, -- Singe Magic
}

dispels.curse = {
	2782, -- Remove Corruption
	374251, -- Cauterizing Flame
	51886, -- Cleanse Spirit
	475, -- Remove Curse
}
dispels.disease = {
	213634, -- Purify Disease
	374251, -- Cauterizing Flame
	213644, -- Cleanse Toxins
	218164, -- Detox
}

dispels.poison = {
	2782, -- Remove Corruption
	360823, -- Naturalize
	365585, -- Expunge
	374251, -- Cauterizing Flame
	213644, -- Cleanse Toxins
	218164, -- Detox
}

-- We cannot check talents with IsSpellKnown, a lot of healers have improved dispel talents
-- which enables them to dispel more debuff types. So we need to check the talents for those types.
dispelImprovements = {}
dispelImprovements.curse = {
	392378, -- Improved Nature's Cure
	383016, -- Improved Purify Spirit
}

dispelImprovements.disease = {
	390632, -- Improved Purify
	393024, -- Improved Cleanse
	388874, -- Improved Detox
}

dispelImprovements.poison = {
	392378, -- Improved Nature's Cure
	393024, -- Improved Cleanse
	388874, -- Improved Detox
}

healerSpecializations = {
	[2] = { 1 }, -- Paladin, Holy
	[5] = { 1, 2 }, -- Priest, Discipline + Holy
	[7] = { 3 }, -- Shaman, Restoration
	[10] = { 2 }, -- Monk, Mistweaver
	[11] = { 4 }, -- Druid, Restoration
	[13] = { 2 } -- Evoker, Preservation
}

local canDispellMagic = false
local canDispellCurse = false
local canDispellDisease = false
local canDispellPoison = false

function EnhancedRaidFrames:InitDispels()
	self:UpdateCanDispell()
end

function EnhancedRaidFrames:UpdateCanDispell()
	canDispelMagic = self:CanDispelType(dispels.magic, false)
	canDispelCurse = self:CanDispelType(dispels.curse, false)
	canDispelDisease = self:CanDispelType(dispels.disease, false)
	canDispelPoison = self:CanDispelType(dispels.poison, false)

	-- The only reason for this approach for healers rather than just adding their dispels to magic table is because
	-- IsSpellKnown returns False for Naturalize for some reason even though it is not a talent. So the frames wouldn't highlight when playing an Evoker.
	if not canDispelMagic then
		canDispelMagic = self:IsHealer()
	end

	local learnedTalents = self:LoopNodes()
	canDispelCurse = EnhancedRaidFrames:CanDispelTypeFromTalentPoints(dispelImprovements.curse, learnedTalents, canDispelCurse)
	canDispelDisease = EnhancedRaidFrames:CanDispelTypeFromTalentPoints(dispelImprovements.disease, learnedTalents, canDispelDisease)
	canDispelPoison = EnhancedRaidFrames:CanDispelTypeFromTalentPoints(dispelImprovements.poison, learnedTalents, canDispelPoison)
end

function EnhancedRaidFrames:IsHealer()
	local currentClassId = select(3, UnitClass("player"))

	if not self:IsHealerClass(currentClassId) then
		return false
	end

	if not self:IsHealerSpecialization(currentClassId) then
		return false
	end

	return true
end

function EnhancedRaidFrames:IsHealerClass(currentClassId)
	return healerSpecializations[currentClassId] ~= nil
end

function EnhancedRaidFrames:IsHealerSpecialization(currentClassId)
	local currentClass = healerSpecializations[currentClassId]
	local currentSpecialization = GetSpecialization()

	for i = 1, #currentClass do
		if currentClass[i] == currentSpecialization then
			return true
		end
	end

	return false
end

function EnhancedRaidFrames:CanDispelType(spells, isPetSpell)
	for i = 1, #spells do
		if IsSpellKnown(spells[i], isPetSpell) then
			return true
		end
	end

	return false
end

function EnhancedRaidFrames:CanDispelTypeFromTalentPoints(spells, learnedTalents, canDispelType)
	if canDispelType then
		return true
	end

	for i = 1, #spells do
		if learnedTalents[spells[i]] ~= nil then
			return true
		end
	end

	return false
end

function PrintSupportedDispels()
	PrintSpecificSupportedDispelType(canDispelMagic, "Magic")
	PrintSpecificSupportedDispelType(canDispelCurse, "Curse")
	PrintSpecificSupportedDispelType(canDispelDisease, "Disease")
	PrintSpecificSupportedDispelType(canDispelPoison, "Poison")
end

function PrintSpecificSupportedDispelType(canDispelType, typeName)
	if canDispelType then
		print(typeName .. ": true")
	else
		print(typeName .. ": false")
	end
end

function EnhancedRaidFrames:LoopNodes()
	local list = {}

	local configId = C_ClassTalents.GetActiveConfigID()
	if configId == nil then
		return
	end

	local configInfo = C_Traits.GetConfigInfo(configId)
	if configInfo == nil then
		return
	end

	for _, treeId in ipairs(configInfo.treeIDs) do

		local nodes = C_Traits.GetTreeNodes(treeId)
		for i, nodeId in ipairs(nodes) do

			nodeInfo = C_Traits.GetNodeInfo(configId, nodeId)
			-- Explicitly check for 1 rather than > 0 since all improved dispels are one pointers
			-- this way we can ignore some of the search
			if nodeInfo.ranksPurchased == 1 then
				for _, entryId in ipairs(nodeInfo.entryIDs) do
					local entryInfo = C_Traits.GetEntryInfo(configId, entryId)
					if entryInfo and entryInfo.definitionID then
						local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
						if definitionInfo.spellID then
							list[definitionInfo.spellID] = entryInfo.definitionID
						end
					end
				end
			end
		end
	end

	return list
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:SetStockIndicatorVisibility(frame)
	if not self.db.profile.showBuffs then
		CompactUnitFrame_HideAllBuffs(frame)
	end

	if not self.db.profile.showDebuffs then
		CompactUnitFrame_HideAllDebuffs(frame)
	end

	if not self.db.profile.showDispellableDebuffs then
		CompactUnitFrame_HideAllDispelDebuffs(frame)
	end
end

-- Create the FontStrings used for indicators
function EnhancedRaidFrames:CreateIndicators(frame)
	frame.ERFIndicators = {}
	-- Create indicators
	for i = 1, 9 do
		if self.db.profile[i].numIcons == nil then
			self.db.profile[i].numIcons = 1
		end

		numAuras = self.db.profile[i].numIcons

		local auras = {}
		for j = 1, numAuras do
			local indicatorFrame = nil
			local stacksFrame = nil

			--I'm not sure if this is ever the case, but to stop us from creating redundant frames we should try to re-capture them when possible
			--On the global table, our frames our named "CompactRaidFrame#" + "ERFIndicator" + index#, i.e. "CompactRaidFrame1ERFIndicator1"
			frameName = frame:GetName().."ERFIndicator"..i..j
			if not _G[frame:GetName().."ERFIndicator"..i] then
				--We have to use CompactAuraTemplate to allow for our clicks to be passed through, otherwise our frames won't allow selecting the raid frame behind it
				indicatorFrame = CreateFrame("Button", frameName, frame, "ERFIndicatorTemplate")

				if self.db.profile[i].showStacks then
					indicatorFrame.stacksText = indicatorFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
					indicatorFrame.stacksText:SetPoint("TOPRIGHT", 3, 3)
				end
			else
				indicatorFrame = frameName
				indicatorFrame:SetParent(frame) --if we capture an old indicator frame, we should reattach it to the current unit frame
			end

			--mark the position of this particular frame for use later (i.e. 1->9)
			indicatorFrame.position = i

			--hook OnEnter and OnLeave for showing and hiding ability tooltips
			indicatorFrame:SetScript("OnEnter", function() self:Tooltip_OnEnter(indicatorFrame) end)
			indicatorFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

			--disable the mouse click on our frames to allow those clicks to get passed straight through to the raid frame behind (switch target, right click, etc)
			indicatorFrame:SetMouseClickEnabled(false) --this MUST come after the SetScript lines for OnEnter and OnLeave. SetScript will re-enable mouse clicks when called.

			table.insert(auras, indicatorFrame)
		end

		frame.ERFIndicators[i] = auras
	end

	--override for a change made in 9.2 which broke muscle memory for lots of healers
	frame:RegisterForClicks("LeftButtonDown", "AnyUp");

	--set our initial indicator appearance
	self:SetIndicatorAppearance(frame)
end

-- Set the appearance of the Indicator
function EnhancedRaidFrames:SetIndicatorAppearance(frame)
	-- Check if the frame has an ERFIndicators table or if we have a frame unit, this is just for safety
	if not frame.ERFIndicators or not frame.unit then
		return
	end

	for i = 1, 9 do
		--create local pointer for readability
		local auras = frame.ERFIndicators[i]
		for j = 1, #auras do
			indicatorFrame = auras[j]

			--set icon size
			local iconSize = self.db.profile[i].indicatorSize
			indicatorFrame:SetWidth(iconSize)
			indicatorFrame:SetHeight(iconSize)

			--------------------------------------

			--set indicator frame position
			local PAD = 1
			local iconVerticalOffset = floor(self.db.profile[i].indicatorVerticalOffset * frame:GetHeight()) --round down
			local iconHorizontalOffset = floor(self.db.profile[i].indicatorHorizontalOffset * frame:GetWidth())--round down

			if self.db.profile[i].numIcons > 1 then
				growthDirection = self.db.profile[i].growthDirection
				local multiplier = 0
				if growthDirection ~= nil then
					if growthDirection == 1 then -- Left
						multiplier = (j - 1) * -1
					elseif growthDirection == 2 and #auras > 1 then -- Centered
						-- no need to do anything cause if it's centered it gets dynamically updated. See UpdatePosition
					elseif growthDirection == 3 then -- Right
						multiplier = j - 1
					end
				end

				iconHorizontalOffset = iconHorizontalOffset + multiplier * iconSize
			end

			--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
			local powerBarVertOffset
			if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
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

			--set font size, shape, font, and switch our text object
			indicatorFrame.Text:SetText("") --clear previous text
			local font = (media and media:Fetch('font', self.db.profile.indicatorFont)) or STANDARD_TEXT_FONT

			indicatorFrame.Text:SetFont(font, self.db.profile[i].textSize, "OUTLINE")
			if indicatorFrame.stacksText then
				indicatorFrame.stacksText:SetFont(font, self.db.profile[i].textSize, "OUTLINE")
				indicatorFrame.stacksText:SetTextColor(self.YELLOW_COLOR:GetRGB())
			end

			--switch the parent for our text frame to keep the text on top of the cooldown animation
			if self.db.profile[i].showCountdownSwipe then
				indicatorFrame.Text:SetParent(indicatorFrame.Cooldown)

				if indicatorFrame.stacksText then
					indicatorFrame.stacksText:SetParent(indicatorFrame.Cooldown)
				end
			else
				indicatorFrame.Text:SetParent(indicatorFrame)
			end

			--clear any animations
			ActionButton_HideOverlayGlow(indicatorFrame)
			CooldownFrame_Clear(indicatorFrame.Cooldown)
			indicatorFrame.Icon:SetAlpha(1)
		end
	end
end


------------------------------------------------
--------------- Process Indicators -------------
------------------------------------------------

function EnhancedRaidFrames:UpdateIndicators(frame, setAppearance)
	--check to see if the bar is even targeting a unit, bail if it isn't
	--also, tanks have two bars below their frame that have a frame.unit that ends in "target" and "targettarget".
	--Normal raid members have frame.unit that says "Raid1", "Raid5", etc.
	--We don't want to put icons over these tiny little target and target of target bars
	--Also, in 8.2.5 blizzard unified the nameplate code with the raid frame code. Don't display icons on nameplates

	if not frame.unit
			or string.find(frame.unit, "target")
			or string.find(frame.unit, "nameplate")
			or string.find(frame.unit, "pet")
			--10.0 introduced the CompactPartyFrame, we can't assume it exists in classic
			or (not CompactRaidFrameContainer:IsShown() and CompactPartyFrame and not CompactPartyFrame:IsShown()) then
		return
	end

	self:SetStockIndicatorVisibility(frame)

	-- Check if the indicator frame exists, else create it
	if not frame.ERFIndicators then
		self:CreateIndicators(frame)
	end

	if setAppearance then
		self:SetIndicatorAppearance(frame)
	end

	-- Update unit auras
	self:UpdateUnitAuras(frame.unit)

	self:UpdateUnitState(frame)

	-- TODO: Remove the assumption that we have 9 indicators.
	-- Start with 0 indicators and let the users add an indicator and position it.
	-- Now that we have dynamic aura groups in an indicator, there is probably zero need for 9 indicators.
	local raidRequirement = 5
	local isInRaid = GetNumGroupMembers() > raidRequirement
	for i = 1, 9 do
		local auraNames = self.auraStrings[i]
		local auras = frame.ERFIndicators[i]
		local shouldShowAuras = true
		local currProfile = self.db.profile[i]

		if self.db.profile[i].disableInRaid and isInRaid then
			shouldShowAuras = false
		end

		if shouldShowAuras then
			local shouldCopyTable
			auraNames, shouldCopyTable = self:TryApplyGeneralDebuffsSettings(self.db.profile[i].showGeneralDebuffs, auraNames, frame.unit)
			local auraNamesToUse = nil
			if shouldCopyTable then
				auraNamesToUse = GetTableCopy(auraNames)
			else
				auraNamesToUse = auraNames
			end

			frame.ERFIndicators[i].numVisibleAuras = 0
			for j = 1, #auras do
				--create local pointer for readability
				local indicatorFrame = auras[j]
				indicatorFrame:Show()

				-- this is the meat of our processing loop
				self:ProcessIndicator(indicatorFrame, frame, auraNamesToUse, i)
			end

			self:TryUpdateCenteredDynamicGroupsPosition(self.db.profile[i].growthDirection, self.db.profile[i].numIcons, self.db.profile[i].numVisibleAuras)
		else
			for j = 1, #auras do
				--create local pointer for readability
				local indicatorFrame = auras[j]
				indicatorFrame:Hide()
			end
		end
	end
end

function EnhancedRaidFrames:TryApplyGeneralDebuffsSettings(shouldShowGeneralDebuffs, auraNames, unit)
	if not shouldShowGeneralDebuffs then
		return auraNames, true
	end

	local debuffs = GetTableCopy(unitDebuffs[unit])

	-- Sort table so debuffs with lowest remaining duration are prioritized
	table.sort(debuffs, CompareExpirationTime)

	-- remove blacklisted auras from the table
	for k, v in pairs(debuffs) do
		for j = 1, #auraNames do
			if debuffs[k].name == auraNames[j] then
				debuffs[k] = nil
				break
			end
		end
	end

	-- replace auras with the debuffs table
	auraNames = {}
	for k, v in pairs(debuffs) do
		auraNames[k] = debuffs[k].name
	end

	return auraNames, false
end

function EnhancedRaidFrames:TryUpdateCenteredDynamicGroupsPosition(growthDirection, numIcons, numVisibleAuras)
	local growthDirectionCentered = growthDirection == 2
	local shouldUpdate = numIcons < 1 and growthDirectionCentered
	if not shouldUpdate then
		return
	end

	local numVisibleAuras = numVisibleAuras
	for j = 1, numVisibleAuras do
		--create local pointer for readability
		local indicatorFrame = auras[j]

		self:UpdatePosition(frame, indicatorFrame, numVisibleAuras, i, j)
	end
end

function GetTableCopy(t)
  local tableCopy = { }
  for k, v in pairs(t) do
		tableCopy[k] = v
	end

  return tableCopy
end


function CompareExpirationTime(auraA, auraB)
	return GetExpirationTime(auraA) < GetExpirationTime(auraB)
end

function GetExpirationTime(aura)
	-- Auras with expiration time of 0 don't expire ever, they're infinite, just make them expire in an absurdly long time
	if aura.expirationTime == 0 then
		return 999999999999999
	end

	return aura.expirationTime
end

function EnhancedRaidFrames:UpdatePosition(frame, indicatorFrame, numVisibleAuras, groupIndex, auraIndex)
	--set indicator frame position
	local PAD = 1
	local iconVerticalOffset = floor(self.db.profile[groupIndex].indicatorVerticalOffset * frame:GetHeight()) --round down
	local iconHorizontalOffset = floor(self.db.profile[groupIndex].indicatorHorizontalOffset * frame:GetWidth())--round down

	local iconSize = self.db.profile[groupIndex].indicatorSize
	local iconHalfSize = iconSize * 0.5
	local totalWidth = iconSize * numVisibleAuras
	local halfWidth = totalWidth * 0.5

	iconHorizontalOffset = iconHorizontalOffset - halfWidth + iconHalfSize
	multiplier = auraIndex - 1
	iconHorizontalOffset = iconHorizontalOffset + multiplier * iconSize

	--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
	local powerBarVertOffset
	if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
		powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
	else
		powerBarVertOffset = 0
	end

	-- This will get improved if I change so that we don't assume that we have 9 indicators and let the users create indicators based on their needs (that's destructive to their user profiles though)
	indicatorFrame:ClearAllPoints()
	if groupIndex == 1 then
		indicatorFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
	elseif groupIndex == 2 then
		indicatorFrame:SetPoint("TOP", frame, "TOP", 0 + iconHorizontalOffset, -PAD + iconVerticalOffset)
	elseif groupIndex == 3 then
		indicatorFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD + iconHorizontalOffset, -PAD + iconVerticalOffset)
	elseif groupIndex == 4 then
		indicatorFrame:SetPoint("LEFT", frame, "LEFT", PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
	elseif groupIndex == 5 then
		indicatorFrame:SetPoint("CENTER", frame, "CENTER", 0 + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
	elseif groupIndex == 6 then
		indicatorFrame:SetPoint("RIGHT", frame, "RIGHT", -PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2)
	elseif groupIndex == 7 then
		indicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
	elseif groupIndex == 8 then
		indicatorFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0 + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
	elseif groupIndex == 9 then
		indicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset)
	end
end

function SetDebug(shouldActivate)
	EnhancedRaidFrames.debug = shouldActivate

	if shouldActivate then
		canDispelMagic = true
		canDispelCurse = true
		canDispelDisease = true
		canDispelPoison = true
	else
		EnhancedRaidFrames:InitDispels()
	end
end

function SetIsGhost(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].isGhost = shouldActivate
	end
end

function SetIsDead(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].isDead = shouldActivate
	end
end

function SetHasMagic(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].hasMagic = shouldActivate
	end
end

function SetHasPoison(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].hasPoison = shouldActivate
	end
end

function SetHasDisease(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].hasDisease = shouldActivate
	end
end

function SetHasCurse(shouldActivate)
	TryEnableDebugOnDemand(shouldActivate)

	for k,v in pairs(unitStates) do
		unitStates[k].hasCurse = shouldActivate
	end
end

function TryEnableDebugOnDemand(shouldActivate)
	if shouldActivate then
		SetDebug(true)
	end
end

function EnhancedRaidFrames:UpdateUnitState(frame)
	local unit = frame.unit
	if unitStates[unit] == nil then
		unitStates[unit] = {}
	end

	local unitState = unitStates[unit]
	if not self.debug then
		unitState.isDead = UnitIsDead(unit)
		unitState.isGhost = UnitIsGhost(unit)
	end

	local healthBarColor = nil
	local backgroundColor = nil

	if unitState.isGhost then
		healthBarColor = self.DEFAULT_HEALTHBAR_COLOR
		backgroundColor = self.GHOST_COLOR
	elseif unitState.isDead then
		healthBarColor = self.DEFAULT_HEALTHBAR_COLOR
		backgroundColor = self.DEAD_COLOR
	elseif unitState.hasMagic and (canDispelMagic or self:CanDispelType(dispels.magicPet, true)) then
		healthBarColor = self.BLUE_COLOR
		backgroundColor = self.DEFAULT_BACKGROUND_COLOR
	elseif unitState.hasCurse and canDispelCurse then
		healthBarColor = self.PURPLE_COLOR
		backgroundColor = self.DEFAULT_BACKGROUND_COLOR
	elseif unitState.hasDisease and canDispelDisease then
		healthBarColor = self.BROWN_COLOR
		backgroundColor = self.DEFAULT_BACKGROUND_COLOR
	elseif unitState.hasPoison and canDispelPoison then
		healthBarColor = self.GREEN_COLOR
		backgroundColor = self.DEFAULT_BACKGROUND_COLOR
	else
		healthBarColor = self.DEFAULT_HEALTHBAR_COLOR
		backgroundColor = self.DEFAULT_BACKGROUND_COLOR
	end

	local frameName = frame:GetName()
	local healthBar = _G[frameName .. "HealthBar"]

	healthBar:SetStatusBarColor(healthBarColor:GetRGB())
	healthBar.background:SetColorTexture(backgroundColor:GetRGBA())
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end


-- process a single indicator and apply visuals
function EnhancedRaidFrames:ProcessIndicator(indicatorFrame, frame, auraNames, groupIndex)
	local unit = frame.unit
	local i = indicatorFrame.position

	local slotId, foundAura, icon, count, duration, expirationTime, debuffType, castByPlayer, isHarmful, auraIndex

	--reset auraIndex and auraType for tooltip
	indicatorFrame.auraIndex = nil
	indicatorFrame.isHarmful = nil

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

	for k, v in pairs(auraNames) do
		local auraName = auraNames[k]

		--if there's no auraName (i.e. the user never specified anything to go in this spot), stop here there's no need to keep going
		if not auraName then
			break
		end

		-- query the available information for a given indicator and aura
		foundAura, icon, count, duration, expirationTime, debuffType, sourceUnit, isHarmful, auraIndex = self:QueryAuraInfo(auraName, unit)
		slotId = k
		castByPlayer = sourceUnit == "player"


		if not hasThisAuraAlreadyBeenUsed then
			-- add spell icon info to cache in case we need it later on
			if icon and not self.iconCache[auraName] then
				EnhancedRaidFrames.iconCache[auraName] = icon
			end

			-- when tracking multiple things, this determines "where" we stop in the list
			-- if we find the aura, we can stop querying down the list
			-- we want to stop only when castBy == "player" if we are tracking "mine only"
			if foundAura and (not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and castByPlayer)) then
				frame.ERFIndicators[groupIndex].numVisibleAuras = frame.ERFIndicators[groupIndex].numVisibleAuras + 1
				break
			end
		end
	end

	------------------------------------------------------
	------- output visuals to the indicator frame --------
	------------------------------------------------------

	if not foundAura then
		indicatorFrame:Hide() --hide the frame
		--if no aura is found and we're not showing missing, clear animations and hide the frame
		CooldownFrame_Clear(indicatorFrame.Cooldown)
		ActionButton_HideOverlayGlow(indicatorFrame)
		return
	end

	auraNames[slotId] = nil

	-- if we find the spell and we don't only want to show when it is missing
	if foundAura and UnitIsConnected(unit) and not self.db.profile[i].missingOnly and (not self.db.profile[i].mineOnly or (self.db.profile[i].mineOnly and castByPlayer)) then

		-- calculate remainingTime and round down, this is how the game seems to do it
		local remainingTime = floor(expirationTime - GetTime())

		-- set auraIndex and auraType for tooltip
		indicatorFrame.auraIndex = auraIndex
		indicatorFrame.isHarmful = isHarmful

		---------------------------------
		--- process icon to show
		---------------------------------

		if icon and self.db.profile[i].showIcon then
			indicatorFrame.Icon:SetTexture(icon)
			indicatorFrame.Icon:SetAlpha(self.db.profile[i].indicatorAlpha)
		else
			--set color of custom texture
			local indicatorColor = self.db.profile[i].indicatorColor
			indicatorFrame.Icon:SetColorTexture(indicatorColor.r, indicatorColor.g, indicatorColor.b, indicatorColor.a)

			-- determine if we should change the background color from the default (player set color)
			if self.db.profile[i].colorIndicatorByDebuff and isHarmful and debuffType then -- Color by debuff type
				if debuffType == "Poison" then
					indicatorFrame.Icon:SetColorTexture(self.GREEN_COLOR:GetRGB())
				elseif debuffType == "Curse" then
					indicatorFrame.Icon:SetColorTexture(self.PURPLE_COLOR:GetRGB())
				elseif debuffType == "Disease" then
					indicatorFrame.Icon:SetColorTexture(self.BROWN_COLOR:GetRGB())
				elseif debuffType == "Magic" then
					indicatorFrame.Icon:SetColorTexture(self.BLUE_COLOR:GetRGB())
				end
			end
			if self.db.profile[i].colorIndicatorByTime then -- Color by remaining time
				if remainingTime and self.db.profile[i].colorIndicatorByTime_low ~= 0 and remainingTime <= self.db.profile[i].colorIndicatorByTime_low then
					indicatorFrame.Icon:SetColorTexture(self.YELLOW_COLOR:GetRGB())
				elseif remainingTime and self.db.profile[i].colorIndicatorByTime_high ~= 0 and remainingTime <= self.db.profile[i].colorIndicatorByTime_high then
					indicatorFrame.Icon:SetColorTexture(self.RED_COLOR:GetRGB())
				end
			end
		end

		---------------------------------
		--- process text to show
		---------------------------------
		local formattedTime = ""

		-- determine the formatted time string
		if self.db.profile[i].showDuration and remainingTime then
			if remainingTime > 60 then
				formattedTime = string.format("%.0f", remainingTime/60).."m" -- Show minutes without seconds
			elseif remainingTime >= 0 then
				formattedTime = string.format("%.0f", remainingTime) -- Show seconds without decimals
			end
		end

		indicatorFrame.Text:SetText(formattedTime)

		if self.db.profile[i].showStacks then
			local formattedCount = ""

			-- determine the formatted stack string
			if count and count > 0 then
				formattedCount = count
			end

			indicatorFrame.stacksText:SetText(formattedCount)
		end

		---------------------------------
		--- process text color
		---------------------------------
		--set default textColor to user selected choice
		indicatorFrame.Text:SetTextColor(
				self.db.profile[i].textColor.r,
				self.db.profile[i].textColor.g,
				self.db.profile[i].textColor.b,
				self.db.profile[i].textColor.a)

		if self.db.profile[i].colorTextByDebuff and isHarmful and debuffType then -- Color by debuff type
			if debuffType == "Curse" then
				indicatorFrame.Text:SetTextColor(self.PURPLE_COLOR:GetRGB())
			elseif debuffType == "Disease" then
				indicatorFrame.Text:SetTextColor(self.BROWN_COLOR:GetRGB())
			elseif debuffType == "Magic" then
				indicatorFrame.Text:SetTextColor(self.BLUE_COLOR:GetRGB())
			elseif debuffType == "Poison" then
				indicatorFrame.Text:SetTextColor(self.GREEN_COLOR:GetRGB())
			end
		end
		if self.db.profile[i].colorTextByTime then -- Color by remaining time
			if remainingTime and self.db.profile[i].colorTextByTime_low ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_low then
				indicatorFrame.Text:SetTextColor(0.77, 0.12, 0.23, 1)
			elseif remainingTime and self.db.profile[i].colorTextByTime_high ~= 0 and remainingTime <= self.db.profile[i].colorTextByTime_high then
				indicatorFrame.Text:SetTextColor(1, 0.96, 0.41, 1)
			end
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

	elseif not foundAura and self.db.profile[i].missingOnly then --deal with "show only if missing"
		local auraName = self.auraStrings[i][1] --show the icon for the first auraString position

		--check our iconCache for the auraName. Note the icon cache is pre-populated with generic "poison", "curse", "disease", and "magic" debuff icons
		if not self.iconCache[auraName] then
			_,_,icon = GetSpellInfo(auraName)
			if not icon then
				icon = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
		else
			icon = self.iconCache[auraName]
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
	end
end

--process the text and icon for an indicator and return these values
--this function returns foundAura, icon, count, duration, expirationTime, debuffType, castBy, auraIndex, auraType
function EnhancedRaidFrames:QueryAuraInfo(auraName, unit)
	local auraSpellId = tonumber(auraName)

	-- Check if the aura exist on the unit
	local auras = unitAuras[unit]
	for k, v in pairs(auras) do --loop through list of auras
		if auraSpellId and v.spellId == auraSpellId or v.name == auraName then
				return true, v.icon, v.applications, v.duration, v.expirationTime, v.dispelName, v.sourceUnit, v.isHarmful, v.index
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

	-- Check if we want to show combat flag
	if auraName:upper() == "COMBAT" then
		if UnitAffectingCombat(unit) then
			return true, "Interface\\Icons\\Ability_Dualwield", 0, 0, 0, "", "player"
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
	-- Create or clear out the tables for the unit
	unitAuras[unit] = {}
	unitDebuffs[unit] = {}


	local slots = { UnitAuraSlots(unit, "HELPFUL") }
	for i = 2, #slots do
		local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
		if aura then
			aura.name = string.lower(aura.name)
			aura.index = i - 1
			unitAuras[unit][slots[i]] = aura
		end
	end

	if unitStates[unit] == nil then
		unitStates[unit] = {}
	end

	local unitState = unitStates[unit];
	local hasCurse = false
	local hasDisease = false
	local hasMagic = false
	local hasPoison = false
	slots = { UnitAuraSlots(unit, "HARMFUL") }
	for i = 2, #slots do
		local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
		if aura then
			aura.name = string.lower(aura.name)
			aura.index = i - 1
			unitAuras[unit][slots[i]] = aura
			unitDebuffs[unit][slots[i]] = aura

			if aura.dispelName then
				if not hasCurse and aura.dispelName == "Curse" then
					hasCurse = true
				elseif not hasDisease and aura.dispelName == "Disease" then
					hasDisease = true
				elseif not hasMagic and aura.dispelName == "Magic" then
					hasMagic = true
				elseif not hasPoison and aura.dispelName == "Poison" then
					hasPoison = true
				end
			end
		end
	end

	if not self.debug then
		unitState.hasCurse = hasCurse;
		unitState.hasDisease = hasDisease;
		unitState.hasMagic = hasMagic;
		unitState.hasPoison = hasPoison;
	end
end

------------------------------------------------
----------------- Tooltip Code -----------------
------------------------------------------------
function EnhancedRaidFrames:Tooltip_OnEnter(indicatorFrame)
	local i = indicatorFrame.position

	if not self.db.profile[i].showTooltip then --don't show tooltips unless we have the option set for this position
		return
	end

	local frame = indicatorFrame:GetParent() --this is the parent raid frame that holds all the indicatorFrames
	-- Set the tooltip
	if indicatorFrame.auraIndex and indicatorFrame.Icon:GetTexture() then -- -1 is the pvp icon, no tooltip for that
		-- Set the buff/debuff as tooltip and anchor to the cursor
		GameTooltip:SetOwner(UIParent, self.db.profile[i].tooltipLocation)
		local filter = "HELPFUL"
		if indicatorFrame.isHarmful then
			filter = "HARMFUL"
		end

		GameTooltip:SetUnitAura(frame.unit, indicatorFrame.auraIndex, filter)
	else
		--causes the tooltip to reset to the "default" tooltip which is usually information about the character
		if frame then
			UnitFrame_UpdateTooltip(frame)
		end
	end

	GameTooltip:Show()
end
