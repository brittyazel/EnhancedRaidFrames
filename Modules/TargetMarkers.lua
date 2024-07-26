-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Create a target marker for a given frame
---@param frame table @The frame to create the target marker for
function EnhancedRaidFrames:CreateTargetMarker(frame)
	-- Create a texture for our target marker
	frame.ERF_targetMarkerFrame = frame:CreateTexture(nil, "OVERLAY")
	self:SetTargetMarkerAppearance(frame)
end

--- Set the appearance for our target marker for a given frame
---@param frame table @The frame to set the appearance for
function EnhancedRaidFrames:SetTargetMarkerAppearance(frame)
	local targetMarker = frame.ERF_targetMarkerFrame

	local PAD = 3
	local pos = self.db.profile.markerPosition

	local markerVerticalOffset = self.db.profile.markerVerticalOffset * frame:GetHeight()
	local markerHorizontalOffset = self.db.profile.markerHorizontalOffset * frame:GetWidth()

	-- We probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
	local powerBarVertOffset
	if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
		powerBarVertOffset = frame.powerBar:GetHeight() + 2 -- Add 2 to not overlap the powerBar border
	else
		powerBarVertOffset = 0
	end

	-- Set position relative to frame
	targetMarker:ClearAllPoints()
	if pos == 1 then
		targetMarker:SetPoint("TOPLEFT", PAD + markerHorizontalOffset, -PAD + markerVerticalOffset)
	elseif pos == 2 then
		targetMarker:SetPoint("TOP", 0 + markerHorizontalOffset, -PAD + markerVerticalOffset)
	elseif pos == 3 then
		targetMarker:SetPoint("TOPRIGHT", -PAD + markerHorizontalOffset, -PAD + markerVerticalOffset)
	elseif pos == 4 then
		targetMarker:SetPoint("LEFT", PAD + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset / 2)
	elseif pos == 5 then
		targetMarker:SetPoint("CENTER", 0 + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset / 2)
	elseif pos == 6 then
		targetMarker:SetPoint("RIGHT", -PAD + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset / 2)
	elseif pos == 7 then
		targetMarker:SetPoint("BOTTOMLEFT", PAD + markerHorizontalOffset, PAD + markerVerticalOffset + powerBarVertOffset)
	elseif pos == 8 then
		targetMarker:SetPoint("BOTTOM", 0 + markerHorizontalOffset, PAD + markerVerticalOffset + powerBarVertOffset)
	elseif pos == 9 then
		targetMarker:SetPoint("BOTTOMRIGHT", -PAD + markerHorizontalOffset, PAD + markerVerticalOffset + powerBarVertOffset)
	end

	-- Set the marker size
	targetMarker:SetWidth(self.db.profile.markerSize)
	targetMarker:SetHeight(self.db.profile.markerSize)

	-- Clear the marker
	self:ClearTargetMarker(frame)
end

--- Update the appearance of our target marker for a given frame
---@param frame table @The frame to update the appearance for
---@param setAppearance boolean @Whether or not to set the appearance of the marker
function EnhancedRaidFrames:UpdateTargetMarker(frame, setAppearance)
	if not self.ShouldContinue(frame) then
		return
	end

	-- If our target marker doesn't exist, create it
	if not frame.ERF_targetMarkerFrame then
		self:CreateTargetMarker(frame)
	else
		if setAppearance then
			self:SetTargetMarkerAppearance(frame)
		end
	end

	-- If they don't have target markers enabled, don't show anything
	if not self.db.profile.showTargetMarkers then
		self:ClearTargetMarker(frame)
		return
	end

	-- Get target marker on unit
	local index = GetRaidTargetIndex(frame.unit)

	if index and index >= 1 and index <= 8 then
		-- Get the full texture path for the marker
		local texture = UnitPopupRaidTarget1ButtonMixin:GetIcon() or "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		local coords = {}
		-- Get the texture coordinates for the marker
		if not self.isWoWClassicEra and not self.isWoWClassic then
			-- 11.0 changed GetTextureCoords to return the coords unpacked
			coords.tCoordLeft, coords.tCoordRight, coords.tCoordTop, coords.tCoordBottom = _G["UnitPopupRaidTarget" .. index .. "ButtonMixin"]:GetTextureCoords()
		else
			coords = _G["UnitPopupRaidTarget" .. index .. "ButtonMixin"]:GetTextureCoords()
		end

		-- Set the marker texture using trilinear filtering (reduces pixelation)
		frame.ERF_targetMarkerFrame:SetTexture(texture, nil, nil, "TRILINEAR")

		-- Set the texture coordinates to the correct icon of the larger texture
		frame.ERF_targetMarkerFrame:SetTexCoord(coords.tCoordLeft, coords.tCoordRight, coords.tCoordTop, coords.tCoordBottom)

		-- Set the marker opacity
		frame.ERF_targetMarkerFrame:SetAlpha(self.db.profile.markerAlpha)

		-- Show the marker
		frame.ERF_targetMarkerFrame:Show()
	else
		self:ClearTargetMarker(frame)
	end
end

--- Update the appearance of our target markers for all frames
function EnhancedRaidFrames:UpdateAllTargetMarkers()
	if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateTargetMarker(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateTargetMarker(frame)
		end)
	end
end

--- Clear the target marker for a given frame
---@param frame table @The frame to clear the target marker for
function EnhancedRaidFrames:ClearTargetMarker(frame)
	local targetMarker = frame.ERF_targetMarkerFrame
	targetMarker:Hide()
	targetMarker:SetAlpha(1)
end