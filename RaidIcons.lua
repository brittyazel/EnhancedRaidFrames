-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateIcon(frame)
	frame.ERFIcons = {}
	frame.ERFIcons.texture = frame:CreateTexture(nil, "OVERLAY")
	self:SetIconAppearance(frame)
end

function EnhancedRaidFrames:SetIconAppearance(frame)
	if not frame.ERFIcons then
		return
	end

	local tex = frame.ERFIcons.texture

	local PAD = 3
	local pos = self.db.profile.iconPosition

	local iconVerticalOffset = self.db.profile.iconVerticalOffset * frame:GetHeight()
	local iconHorizontalOffset = self.db.profile.iconHorizontalOffset * frame:GetWidth()

	--we probably don't want to overlap the power bar (rage, mana, energy, etc) so we need a compensation factor
	local powerBarVertOffset
	if self.db.profile.powerBarOffset and frame.powerBar:IsShown() then
		powerBarVertOffset = frame.powerBar:GetHeight() + 2 --add 2 to not overlap the powerBar border
	else
		powerBarVertOffset = 0
	end

	-- Set position relative to frame
	tex:ClearAllPoints()
	if pos == 1 then tex:SetPoint("TOPLEFT", PAD + iconHorizontalOffset, -PAD + iconVerticalOffset) end
	if pos == 2 then tex:SetPoint("TOP", 0 + iconHorizontalOffset, -PAD + iconVerticalOffset) end
	if pos == 3 then tex:SetPoint("TOPRIGHT", -PAD + iconHorizontalOffset, -PAD + iconVerticalOffset) end
	if pos == 4 then tex:SetPoint("LEFT", PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2) end
	if pos == 5 then tex:SetPoint("CENTER", 0 + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2) end
	if pos == 6 then tex:SetPoint("RIGHT", -PAD + iconHorizontalOffset, 0 + iconVerticalOffset + powerBarVertOffset/2) end
	if pos == 7 then tex:SetPoint("BOTTOMLEFT", PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset) end
	if pos == 8 then tex:SetPoint("BOTTOM", 0 + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset) end
	if pos == 9 then tex:SetPoint("BOTTOMRIGHT", -PAD + iconHorizontalOffset, PAD + iconVerticalOffset + powerBarVertOffset) end

	-- Set the icon size
	tex:SetWidth(self.db.profile.iconSize)
	tex:SetHeight(self.db.profile.iconSize)

	-- Set the icon opacity
	tex:SetAlpha(self.db.profile.iconAlpha)
end

function EnhancedRaidFrames:UpdateIcons(frame, setAppearance)
	-- If frame doesn't point at anything, no need for an icon
	if not frame.unit then
		return
	end

	-- Initialize our storage and create texture
	if not frame.ERFIcons then -- No icon on this frame before, need a texture
		self:CreateIcon(frame)
	end

	if setAppearance then
		self:SetIconAppearance(frame)
	end

	--if they don't have raid icons set to show, don't show anything
	if not self.db.profile.showRaidIcons then
		frame.ERFIcons.texture:Hide() -- hide the frame
		return
	end

	-- Get icon on unit
	local index = GetRaidTargetIndex(frame.unit)

	if index and index >= 1 and index <= 8 then

		local texture
		local tCoordsTable

		---I don't think classic has adpoted the new mixins yet. This should be removed in the future if it catches up
		if not self.isWoWClassicEra then
			texture = UnitPopupRaidTarget1ButtonMixin:GetIcon() --this is the full texture file, we need to parse it to get the individual icons
			tCoordsTable = _G["UnitPopupRaidTarget"..index.."ButtonMixin"]:GetTextureCoords()
		else
			tCoordsTable = UnitPopupButtons["RAID_TARGET_"..index]
			texture = tCoordsTable.icon
		end

		local leftTexCoord = tCoordsTable.tCoordLeft
		local rightTexCoord = tCoordsTable.tCoordRight
		local topTexCoord = tCoordsTable.tCoordTop
		local bottomTexCoord = tCoordsTable.tCoordBottom

		frame.ERFIcons.texture:SetTexture(texture, nil, nil, "TRILINEAR") --use trilinear filtering to reduce jaggies
		frame.ERFIcons.texture:SetTexCoord(leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord) --texture contains all the icons in a single texture, and we need to set coords to crop out the other icons
		frame.ERFIcons.texture:Show()
	else
		frame.ERFIcons.texture:Hide()
	end
end