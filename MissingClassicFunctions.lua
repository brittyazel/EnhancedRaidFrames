--Enhanced Raid Frames, a World of Warcraft® user interface addon.

--This file is part of Enhanced Raid Frames.
--
--Enhanced Raid Frames is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Enhanced Raid Frames is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this add-on.  If not, see <https://www.gnu.org/licenses/>.
--
--Copyright for Enhanced Raid Frames is held by Britt Yazel (aka Soyier), 2017-2020.



--This file is meant to supply some of the missing Retail functions that aren't yet found in Classic

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and not CreateColorFromHexString then --I want to remove this ASAP. Blizzard, get on this.

	local function ExtractColorValueFromHex(str, index)
		return tonumber(str:sub(index, index + 1), 16) / 255;
	end

	--this is a baseline Retail function. We did not write this.
	function CreateColorFromHexString(hexColor)
		if #hexColor == 8 then
			local a, r, g, b = ExtractColorValueFromHex(hexColor, 1), ExtractColorValueFromHex(hexColor, 3), ExtractColorValueFromHex(hexColor, 5), ExtractColorValueFromHex(hexColor, 7);
			return CreateColor(r, g, b, a);
		else
			GMError("CreateColorFromHexString input must be hexadecimal digits in this format: AARRGGBB.");
		end
	end

end