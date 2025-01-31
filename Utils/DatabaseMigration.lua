-- Enhanced Raid Frames is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2025 Britt W. Yazel
-- This code is licensed under the MIT license (see LICENSE for details)

-- Create a local handle to our addon table
---@type EnhancedRaidFrames
local EnhancedRaidFrames = _G.EnhancedRaidFrames

-- Import libraries
local L = LibStub("AceLocale-3.0"):GetLocale("EnhancedRaidFrames")

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--- Handle the migration of the database from one version to another
function EnhancedRaidFrames:MigrateDatabase()
	if not self.db.profile.DB_VERSION or self.db.profile.DB_VERSION < self.DATABASE_VERSION then
		-- Migrate the database to the current specification
		self:Print(L["The database is being migrated to version:"] .. " " .. self.DATABASE_VERSION)

		-----------------------------------------------------------
		-----------------------------------------------------------

		-- Added in database version 2.1 on 12/4/2023
		-- Fix indicatorColor and textColor to be our new table format without explicit R/G/B/A keys assigned
		for i = 1, 9 do
			if self.db.profile[i] then
				-- Check to see if we have the old format prior to database version 2.2
				if self.db.profile[i].indicatorColor and self.db.profile[i].indicatorColor.r then
					self.db.profile[i].indicatorColor = { self.db.profile[i].indicatorColor.r, self.db.profile[i].indicatorColor.g,
														  self.db.profile[i].indicatorColor.b, self.db.profile[i].indicatorColor.a }
				end
				-- Check to see if we have the old format prior to database version 2.2
				if self.db.profile[i].textColor and self.db.profile[i].textColor.r then
					self.db.profile[i].textColor = { self.db.profile[i].textColor.r, self.db.profile[i].textColor.g,
													 self.db.profile[i].textColor.b, self.db.profile[i].textColor.a }
				end
			end
		end

		-- Added in database version 2.2 on 12/4/2023
		-- Rename indicator position keys to be "indicator-1" rather than just "1"
		for i = 1, 9 do
			if self.db.profile[i] then
				for k, v in pairs(self.db.profile[i]) do
					self.db.profile["indicator-" .. i][k] = v
				end
			end
		end

		-- Reload our database object with the defaults post-migration
		self:InitializeDatabase()

		-----------------------------------------------------------
		-----------------------------------------------------------

		self:Print(L["Database migration successful."])
		self.db.profile.DB_VERSION = self.DATABASE_VERSION
	end
end