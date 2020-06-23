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
--Copyright for Enhanced Raid Frames is held by Britt Yazel (aka Soyier), 2017-2020.

local _, addonTable = ...
local EnhancedRaidFrames = addonTable.EnhancedRaidFrames

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateIcon(frame)
	frame.ERFIcons = {}
	frame.ERFIcons.texture = frame:CreateTexture(nil, "OVERLAY")
	EnhancedRaidFrames:SetIconAppearance(frame)
end

function EnhancedRaidFrames:SetIconAppearance(frame)
	if not frame.ERFIcons then
		return
	end

	local tex = frame.ERFIcons.texture

	local PAD = 3
	local pos = EnhancedRaidFrames.db.profile.iconPlacement

	local iconVerticalOffset = EnhancedRaidFrames.db.profile.iconVerticalOffset * frame:GetHeight()
	local iconHorizontalOffset = EnhancedRaidFrames.db.profile.iconHorizontalOffset * frame:GetWidth()

	--we probably don't want to overlap the power bar (rage,mana,energy,etc) so we need a compensation factor
	local powerBarVertOffset
	if frame.powerBar:IsShown() then
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
	tex:SetWidth(EnhancedRaidFrames.db.profile.indicatorSize)
	tex:SetHeight(EnhancedRaidFrames.db.profile.indicatorSize)

	-- Set the icon opacity
	tex:SetAlpha(EnhancedRaidFrames.db.profile.iconAlpha)
end

function EnhancedRaidFrames:UpdateIcons(frame, setAppearance)
	-- If frame doesn't point at anything, no need for an icon
	if not frame.unit then
		return
	end

	-- Initialize our storage and create texture
	if not frame.ERFIcons then -- No icon on this frame before, need a texture
		EnhancedRaidFrames:CreateIcon(frame)
	end

	if setAppearance then
		EnhancedRaidFrames:SetIconAppearance(frame)
	end

	--if they don't have raid icons set to show, don't show anything
	if not EnhancedRaidFrames.db.profile.showRaidIcons then
		frame.ERFIcons.texture:Hide() -- hide the frame
		return
	end

	-- Get icon on unit
	local index = GetRaidTargetIndex(frame.unit)

	if index and index >= 1 and index <= 8 then
		--the icons are stored in a single image, and UnitPopupButtons["RAID_TARGET_#"] is a table that contains the information for the texture and coords for each icon sub-texture
		local iconTable = UnitPopupButtons["RAID_TARGET_"..index]
		local texture = iconTable.icon
		local leftTexCoord = iconTable.tCoordLeft
		local rightTexCoord = iconTable.tCoordRight
		local topTexCoord = iconTable.tCoordTop
		local bottomTexCoord = iconTable.tCoordBottom

		frame.ERFIcons.texture:SetTexture(texture, nil, nil, "TRILINEAR") --use trilinear filtering to reduce jaggies
		frame.ERFIcons.texture:SetTexCoord(leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord) --texture contains all the icons in a single texture, and we need to set coords to crop out the other icons
		frame.ERFIcons.texture:Show()
	else
		frame.ERFIcons.texture:Hide()
	end
end