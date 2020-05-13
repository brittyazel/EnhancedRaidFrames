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


local _, AddonTable = ...
local EnhancedRaidFrames = AddonTable.EnhancedRaidFrames

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
	local pad = 3
	local pos = EnhancedRaidFrames.db.profile.iconPosition
	local frameName = frame:GetName()
	if not icons[frameName] then return end
	local tex = icons[frameName].texture

	local iconVerticalOffset = EnhancedRaidFrames.db.profile.iconVerticalOffset
	local iconHorizontalOffset = EnhancedRaidFrames.db.profile.iconHorizontalOffset

	-- Set position relative to frame
	tex:ClearAllPoints()
	if pos == "TOPLEFT" then tex:SetPoint("TOPLEFT", pad + iconHorizontalOffset, -pad + iconVerticalOffset) end
	if pos == "TOP" then tex:SetPoint("TOP", 0 + iconHorizontalOffset, -pad + iconVerticalOffset) end
	if pos == "TOPRIGHT" then tex:SetPoint("TOPRIGHT", -pad + iconHorizontalOffset, -pad + iconVerticalOffset) end
	if pos == "LEFT" then tex:SetPoint("LEFT", pad + iconHorizontalOffset, 0 + iconVerticalOffset) end
	if pos == "CENTER" then tex:SetPoint("CENTER", 0 + iconHorizontalOffset, 0 + iconVerticalOffset) end
	if pos == "RIGHT" then tex:SetPoint("RIGHT", -pad + iconHorizontalOffset, 0 + iconVerticalOffset) end
	if pos == "BOTTOMLEFT" then tex:SetPoint("BOTTOMLEFT", pad + iconHorizontalOffset, pad + iconVerticalOffset) end
	if pos == "BOTTOM" then tex:SetPoint("BOTTOM", 0 + iconHorizontalOffset, pad + iconVerticalOffset) end
	if pos == "BOTTOMRIGHT" then tex:SetPoint("BOTTOMRIGHT", -pad + iconHorizontalOffset, pad + iconVerticalOffset) end

	-- Set the icon size
	tex:SetWidth(EnhancedRaidFrames.db.profile.iconSize)
	tex:SetHeight(EnhancedRaidFrames.db.profile.iconSize)
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