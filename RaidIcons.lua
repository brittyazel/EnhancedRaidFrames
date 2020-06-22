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

local icons = {}

-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:CreateIcon(frame)
	local frameName = frame:GetName()

	icons[frameName] = {}
	icons[frameName].texture = frame:CreateTexture(nil, "OVERLAY")
	EnhancedRaidFrames:SetIconAppearance(frame)
end

function EnhancedRaidFrames:SetIconAppearance(frame)
	local PAD = 3
	local pos = EnhancedRaidFrames.db.profile.iconPlacement
	local frameName = frame:GetName()
	if not icons[frameName] then return end
	local tex = icons[frameName].texture

	--------------------------
	--TODO: this is just temp becasue we're changing from pixel to percentage relativity, remove this in the future
	if EnhancedRaidFrames.db.profile.iconVerticalOffset > 1 then
		EnhancedRaidFrames.db.profile.iconVerticalOffset = 0
	end
	if EnhancedRaidFrames.db.profile.iconHorizontalOffset > 1 then
		EnhancedRaidFrames.db.profile.iconHorizontalOffset = 0
	end
	--------------------------

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
	tex:SetWidth(EnhancedRaidFrames.db.profile.iconSize)
	tex:SetHeight(EnhancedRaidFrames.db.profile.iconSize)

	-- Set the icon opacity
	tex:SetAlpha(EnhancedRaidFrames.db.profile.iconAlpha)
end

function EnhancedRaidFrames:UpdateIcons(frame, setAppearance)
	local unit = frame.unit
	local frameName = frame:GetName()

	-- If frame doesn't point at anything, no need for an icon
	if not unit then
		return
	end

	-- Initialize our storage and create texture
	if not icons[frameName] then -- No icon on this frame before, need a texture
		EnhancedRaidFrames:CreateIcon(frame)
	end

	if setAppearance then
		EnhancedRaidFrames:SetIconAppearance(frame)
	end

	--if they don't have raid icons set to show, don't show anything
	if not EnhancedRaidFrames.db.profile.showRaidIcons then
		icons[frameName].texture:Hide() -- hide the frame
		return
	end

	-- Get icon on unit
	local index = GetRaidTargetIndex(unit)

	if index and index >= 1 and index <= 8 then
		--the icons are stored in a single image, and UnitPopupButtons["RAID_TARGET_#"] is a table that contains the information for the texture and coords for each icon sub-texture
		local iconTable = UnitPopupButtons["RAID_TARGET_"..index]
		local texture = iconTable.icon
		local leftTexCoord = iconTable.tCoordLeft
		local rightTexCoord = iconTable.tCoordRight
		local topTexCoord = iconTable.tCoordTop
		local bottomTexCoord = iconTable.tCoordBottom

		icons[frameName].texture:SetTexture(texture, nil, nil, "TRILINEAR") --use trilinear filtering to reduce jaggies
		icons[frameName].texture:SetTexCoord(leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord) --texture contains all the icons in a single texture, and we need to set coords to crop out the other icons
		icons[frameName].texture:Show()
	else
		icons[frameName].texture:Hide()
	end
end