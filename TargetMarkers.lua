-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------
---
function EnhancedRaidFrames:SetTargetMarkerAppearance(frame)
	if not frame.ERF_targetMarkerFrame then
		return
	end

	local targetMarker = frame.ERF_targetMarkerFrame

	local PAD = 3
	local pos = self.db.profile.markerPosition

	local markerVerticalOffset = self.db.profile.markerVerticalOffset * frame:GetHeight()
	local markerHorizontalOffset = self.db.profile.markerHorizontalOffset * frame:GetWidth()

	--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
	local powerBarVertOffset
	if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
		powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
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
		targetMarker:SetPoint("LEFT", PAD + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset/2)
	elseif pos == 5 then
		targetMarker:SetPoint("CENTER", 0 + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset/2)
	elseif pos == 6 then
		targetMarker:SetPoint("RIGHT", -PAD + markerHorizontalOffset, 0 + markerVerticalOffset + powerBarVertOffset/2)
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

	-- Set the marker opacity
	targetMarker:SetAlpha(self.db.profile.markerAlpha)
end

function EnhancedRaidFrames:UpdateTargetMarkers(frame, setAppearance)
	-- If the frame doesn't point at anything, no need for an marker
	if not frame.unit or not frame:IsShown() then
		return
	end

	-- If our texture doesn't exist, create it
	if not frame.ERF_targetMarkerFrame then
		frame.ERF_targetMarkerFrame = frame:CreateTexture(nil, "OVERLAY")
		self:SetTargetMarkerAppearance(frame)
	else
		if setAppearance then
			self:SetTargetMarkerAppearance(frame)
		end
	end

	--if they don't have target markers set to show, don't show anything
	if not self.db.profile.showTargetMarkers then
		frame.ERF_targetMarkerFrame:Hide() -- hide the frame
		return
	end

	-- Get target marker on unit
	local index = GetRaidTargetIndex(frame.unit)

	if index and index >= 1 and index <= 8 then

		local texture = UnitPopupRaidTarget1ButtonMixin:GetIcon() --this is the full texture file, we need to parse it to get the individual icons
		local tCoordsTable = _G["UnitPopupRaidTarget"..index.."ButtonMixin"]:GetTextureCoords()

		local leftTexCoord = tCoordsTable.tCoordLeft
		local rightTexCoord = tCoordsTable.tCoordRight
		local topTexCoord = tCoordsTable.tCoordTop
		local bottomTexCoord = tCoordsTable.tCoordBottom

		frame.ERF_targetMarkerFrame:SetTexture(texture, nil, nil, "TRILINEAR") --use trilinear filtering to reduce jaggies
		frame.ERF_targetMarkerFrame:SetTexCoord(leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord) --texture contains all the icons in a single texture, and we need to set coords to crop out the other icons
		frame.ERF_targetMarkerFrame:Show()
	else
		frame.ERF_targetMarkerFrame:Hide()
		frame.ERF_targetMarkerFrame:Hide()
	end
end

function EnhancedRaidFrames:UpdateAllTargetMarkers()
	if not self.isWoWClassicEra and not self.isWoWClassic then --10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateTargetMarkers(frame)
		end)
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateBackgroundAlpha(frame)
			self:UpdateTargetMarkers(frame)
		end)
	end
end