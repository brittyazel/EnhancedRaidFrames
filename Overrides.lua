-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2024 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames
local LibRangeCheck = LibStub("LibRangeCheck-3.0")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Set the visibility on the stock buff/debuff frames
function EnhancedRaidFrames:UpdateAllStockAuraVisibility()
	if not self.isWoWClassicEra and not self.isWoWClassic then
		-- 10.0 refactored CompactRaidFrameContainer with new functionality
		CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
			self:UpdateStockAuraVisibility(frame)
		end)

		-- In retail, there's a special type of boss aura called a "private aura" that is not accessible to addons.
		-- We can attempt to hide these auras by hooking the default CompactUnitFrame_UpdatePrivateAuras function.
		if not self:IsHooked("CompactUnitFrame_UpdatePrivateAuras") then
			self:SecureHook("CompactUnitFrame_UpdatePrivateAuras", function(frame)
				self:UpdatePrivateAuraVisOverrides(frame)
			end)
		end
	else
		CompactRaidFrameContainer_ApplyToFrames(CompactRaidFrameContainer, "normal", function(frame)
			self:UpdateStockAuraVisibility(frame)
		end)
	end
end

--- Set the visibility on the stock buff/debuff frames for a single frame
--- This function hooks the "OnShow" event of the stock buff/debuff frames.
---@param frame table @The frame to set the visibility on
function EnhancedRaidFrames:UpdateStockAuraVisibility(frame)
	if not self.ShouldContinue(frame) then
		return
	end

	-- Tables to track the stock buff/debuff frames and their visibility flags in our database
	local allAuraFrames = { frame.buffFrames, frame.debuffFrames, frame.dispelDebuffFrames }
	local auraVisibilityFlags = { self.db.profile.showBuffs, self.db.profile.showDebuffs, self.db.profile.showDispellableDebuffs }

	-- Iterate through the stock buff/debuff/dispelDebuff frame types
	for i, auraFrames in ipairs(allAuraFrames) do
		if not auraFrames then
			break
		end

		-- Iterate through the individual buff/debuff/dispelDebuff frames
		for _, auraFrame in pairs(auraFrames) do
			-- Set our hook to override "OnShow" on the frame based on the visibility flag in our database
			if not auraVisibilityFlags[i] then
				-- Query the specific visibility flag for this frame type
				if not self:IsHooked(auraFrame, "OnShow") then
					-- Be careful not to hook the same frame multiple times
					self:SecureHookScript(auraFrame, "OnShow", function(self)
						self:Hide()
					end)
				end
				-- Hide frame immediately as well, otherwise some already shown frames will remain visible
				auraFrame:Hide()
			else
				if self:IsHooked(auraFrame, "OnShow") then
					-- Unhook the frame if it's hooked and we want to return it to the default behavior
					self:Unhook(auraFrame, "OnShow")
				end
			end
		end
	end
end

--- Set the visibility on the private buff/debuff frames
--- This function is secure hooked to the CompactUnitFrame_UpdateAuras function.
--- We can't hide the private aura frames directly, so we'll hide their anchor frames instead.
---@param frame table @The frame to set the visibility on
function EnhancedRaidFrames:UpdatePrivateAuraVisOverrides(frame)
	if not self.ShouldContinue(frame) then
		return
	end

	-- If we don't have any private auras, stop here
	if not frame.PrivateAuraAnchors then
		return
	end

	-- Use our debuff visibility flag because that's where these auras are anchored by default
	if not self.db.profile.showDebuffs then
		-- Try to "hide" the private aura by clearing the attachment of its anchor frame and hiding the anchor frame
		for _, auraAnchor in ipairs(frame.PrivateAuraAnchors) do
			auraAnchor:ClearAllPoints()
			auraAnchor:Hide()
		end
	end
end

--- Updates the frame alpha based on if a unit is in range or not.
--- This function is secure hooked to the CompactUnitFrame_UpdateInRange function.
---@param frame table @The frame to update the alpha on
function EnhancedRaidFrames:UpdateInRange(frame)
	if not self.ShouldContinue(frame, true) then
		return
	end

	-- Sometimes the "displayed unit" is different than the actual unit, so we'll check both.
	-- (E.g. If we're in a vehicle, we'll use the vehicle unit instead of the player unit.)
	local effectiveUnit = frame.unit
	if frame.unit ~= frame.displayedUnit then
		effectiveUnit = frame.displayedUnit
	end

	local inRange, checkedRange

	-- Try to use LibRangeCheck if we have a custom range set
	if self.db.profile.customRangeCheck then
		local rangeChecker = LibRangeCheck:GetFriendChecker(self.db.profile.customRange)
		if rangeChecker then
			-- If we have a valid range checker, use it
			inRange = rangeChecker(effectiveUnit)
			checkedRange = true
		end
	end

	-- If we haven't successfully checked the range yet, use the default range checking function
	if not checkedRange then
		inRange, checkedRange = UnitInRange(effectiveUnit)
	end

	-- If we weren't able to check the range for some reason, treat them as being in-range as a fallback.
	if checkedRange and not inRange then
		frame:SetAlpha(self.db.profile.rangeAlpha)
	else
		frame:SetAlpha(1)
	end
end

--- Set the background alpha amount based on a defined value by the user.
---@param frame table @The frame to set the background alpha on
function EnhancedRaidFrames:UpdateBackgroundAlpha(frame)
	if not self.ShouldContinue(frame) then
		return
	end

	-- Set the background alpha to the user defined value
	frame.background:SetAlpha(self.db.profile.backgroundAlpha)
end

--- Set the scale of the overall raid frame container.
function EnhancedRaidFrames:UpdateScale()
	if not InCombatLockdown() then
		CompactRaidFrameContainer:SetScale(self.db.profile.frameScale)
		if CompactPartyFrame then
			CompactPartyFrame:SetScale(self.db.profile.frameScale)
		end
	end
end