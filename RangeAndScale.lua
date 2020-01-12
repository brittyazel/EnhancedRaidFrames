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


-------------------------------------------------------------------------
-------------------------------------------------------------------------

function EnhancedRaidFrames:UpdateRangeAlpha(frame)
	if string.match(frame.unit, "party") or string.match(frame.unit, "raid") then
		if IsSpellInRange(EnhancedRaidFrames.db.profile.range.spell, frame.displayedUnit) then
			frame:SetAlpha(EnhancedRaidFrames.db.profile.range.alpha.maximum)
			frame.background:SetAlpha(EnhancedRaidFrames.db.profile.range.background.maximum)
		else
			frame:SetAlpha(EnhancedRaidFrames.db.profile.range.alpha.minimum)
			frame.background:SetAlpha(EnhancedRaidFrames.db.profile.range.background.minimum)
		end
	end
end