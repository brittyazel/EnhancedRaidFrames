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


local EnhancedRaidFrames = EnhancedRaidFrames_Global

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

	-- Set position relative to frame
	tex:ClearAllPoints()
	if pos == "TOPLEFT" then tex:SetPoint("TOPLEFT", pad, -pad) end
	if pos == "TOP" then tex:SetPoint("TOP", 0, -pad) end
	if pos == "TOPRIGHT" then tex:SetPoint("TOPRIGHT", -pad, -pad) end
	if pos == "LEFT" then tex:SetPoint("LEFT", pad, 0) end
	if pos == "CENTER" then tex:SetPoint("CENTER", 0, 0) end
	if pos == "RIGHT" then tex:SetPoint("RIGHT", -pad, 0) end
	if pos == "BOTTOMLEFT" then tex:SetPoint("BOTTOMLEFT", pad, pad) end
	if pos == "BOTTOM" then tex:SetPoint("BOTTOM", 0, pad) end
	if pos == "BOTTOMRIGHT" then tex:SetPoint("BOTTOMRIGHT", -pad, pad) end

	-- Set the icon size
	tex:SetWidth(EnhancedRaidFrames.db.profile.iconSize)
	tex:SetHeight(EnhancedRaidFrames.db.profile.iconSize)
end


function EnhancedRaidFrames:UpdateIcons(frame)
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

	-- Get icon on unit
	local icon = GetRaidTargetIndex(unit)

	-- Only change icon texture if the icon on the frame actually changed
	if icon ~= icons[frameName].icon then
		icons[frameName].icon = icon
		if icon then
			icons[frameName].texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..icon)
			icons[frameName].texture:Show()
		else
			icons[frameName].texture:Hide()
		end
	end
end