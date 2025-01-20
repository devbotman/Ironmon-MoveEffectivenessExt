local function MoveEffectivenessExt()
	-- Define descriptive attributes of the custom extension that are displayed on the Tracker settings
	local self = {}
	self.version = "0.1"
	self.name = "MoveEffectivenessExt"
	self.author = "DevBot"
	self.description = "This is a template file for my fancy custom code extension."
	self.github = "devbotman/Ironmon-MoveEffectivenessExt" 
	self.url = string.format("https://github.com/%s", self.github)

	--------------------------------------
	-- INTENRAL TRACKER FUNCTIONS BELOW
	-- Add any number of these below functions to your extension that you want to use.
	-- If you don't need a function, don't add it at all; leave ommitted for faster code execution.
	--------------------------------------

	-- Executed when the user clicks the "Options" button while viewing the extension details within the Tracker's UI
	-- Remove this function if you choose not to include a way for the user to configure options for your extension
	-- NOTE: You'll need to implement a way to save & load changes for your extension options, similar to Tracker's Settings.ini file
	function self.configureOptions()
		-- [ADD CODE HERE]
	end

	-- Executed when the user clicks the "Check for Updates" button while viewing the extension details within the Tracker's UI
	-- Returns [true, downloadUrl] if an update is available (downloadUrl auto opens in browser for user); otherwise returns [false, downloadUrl]
	-- Remove this function if you choose not to implement a version update check for your extension
	
	--[[function self.checkForUpdates()
		-- Update the pattern below to match your version. You can check what this looks like by visiting the latest release url on your repo
		local versionResponsePattern = '"tag_name":%s+"%w+(%d+%.%d+)"' -- matches "1.0" in "tag_name": "v1.0"
		local versionCheckUrl = string.format("https://api.github.com/repos/%s/releases/latest", self.github or "")
		local downloadUrl = string.format("%s/releases/latest", self.url or "")
		local compareFunc = function(a, b) return a ~= b and not Utils.isNewerVersion(a, b) end -- if current version is *older* than online version
		local isUpdateAvailable = Utils.checkForVersionUpdate(versionCheckUrl, self.version, versionResponsePattern, compareFunc)
		return isUpdateAvailable, downloadUrl
	end--]]

	-- Executed only once: When the extension is enabled by the user, and/or when the Tracker first starts up, after it loads all other required files and code
	function self.startup()
		-- [ADD CODE HERE]
	end

	-- Executed only once: When the extension is disabled by the user, necessary to undo any customizations, if able
	function self.unload()
		-- [ADD CODE HERE]
	end

	-- Executed once every 30 frames, after most data from game memory is read in
	function self.afterProgramDataUpdate()
		-- [ADD CODE HERE]
	end

	-- Executed once every 30 frames, after any battle related data from game memory is read in
	function TrackerScreen.drawMovesArea(data)
	local headerColor = Theme.COLORS["Header text"]
	local shadowcolor = Utils.calcShadowColor(Theme.COLORS["Lower box background"])
	local bgHeaderShadow = Utils.calcShadowColor(Theme.COLORS["Main background"])

	local moveTableHeaderHeightDiff = 13
	local moveOffsetY = 94
	local moveCatOffset = 7
	local moveNameOffset = 6 -- Move names (longest name is 12 characters?)
	local movePPOffset = 82
	local movePowerOffset = 102
	local moveAccOffset = 126

	-- Used to determine if the information about the move should be revealed to the player,
	-- or not, possibly because its randomized further and its requested to remain hidden
	local allowHiddenMoveInfo = Battle.isViewingOwn or Options["Reveal info if randomized"] or not MoveData.IsRand.moveType

	-- Draw move headers
	gui.defaultTextBackground(Theme.COLORS["Main background"])
	local headerY = moveOffsetY - moveTableHeaderHeightDiff
	Drawing.drawText(Constants.SCREEN.WIDTH + moveNameOffset - 1, headerY, data.m.nextmoveheader, headerColor, bgHeaderShadow)
	-- Check if ball catch rate should be displayed instead of other header labels
	if Options["Show Poke Ball catch rate"] and not Battle.isViewingOwn and Battle.isWildEncounter then
		local catchText = string.format("~ %.0f%%  %s", data.x.catchrate, Resources.TrackerScreen.ToCatch)
		local rightOffset = Constants.SCREEN.RIGHT_GAP - Constants.SCREEN.MARGIN - Utils.calcWordPixelLength(catchText) - 2
		Drawing.drawText(Constants.SCREEN.WIDTH + rightOffset, headerY, catchText, headerColor, bgHeaderShadow)
	else
		Drawing.drawText(Constants.SCREEN.WIDTH + movePPOffset, headerY, Resources.TrackerScreen.HeaderPP, headerColor, bgHeaderShadow)
		Drawing.drawText(Constants.SCREEN.WIDTH + movePowerOffset, headerY, Resources.TrackerScreen.HeaderPow, headerColor, bgHeaderShadow)
		Drawing.drawText(Constants.SCREEN.WIDTH + moveAccOffset, headerY, Resources.TrackerScreen.HeaderAcc, headerColor, bgHeaderShadow)
	end

	-- Inidicate there are more moves being tracked than can fit on screen
	if not Battle.isViewingOwn and #Tracker.getMoves(data.p.id) > 4 then
		local movesAsterisk = 1 + Utils.calcWordPixelLength(Resources.TrackerScreen.HeaderMoves)
		Drawing.drawText(Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + movesAsterisk, headerY, "*", Theme.COLORS[Theme.headerHighlightKey], bgHeaderShadow)
	end

	-- Redraw next move level in the header with a different color if close to learning new move
	if data.m.nextmovelevel ~= nil and data.m.nextmovespacing ~= nil and Battle.isViewingOwn and data.p.level + 1 >= data.m.nextmovelevel then
		local headerLevelHighlightX = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + data.m.nextmovespacing
		Drawing.drawText(headerLevelHighlightX, headerY, data.m.nextmovelevel, Theme.COLORS[Theme.headerHighlightKey], bgHeaderShadow)
	end

	-- Draw the Moves view box
	gui.defaultTextBackground(Theme.COLORS["Lower box background"])
	gui.drawRectangle(Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN, moveOffsetY - 2, Constants.SCREEN.RIGHT_GAP - (2 * Constants.SCREEN.MARGIN), 44, Theme.COLORS["Lower box border"], Theme.COLORS["Lower box background"])

	if Options["Show physical special icons"] then -- Check if move categories will be drawn
		moveNameOffset = moveNameOffset + 8
	end
	if not Theme.MOVE_TYPES_ENABLED then -- Check if move type will be drawn as a rectangle
		moveNameOffset = moveNameOffset + 5
	end


	-- Draw all four moves
	for i, move in ipairs(data.m.moves) do
		local moveTypeColor = Utils.inlineIf(move.name == MoveData.BlankMove.name, Theme.COLORS["Lower box text"], Constants.MoveTypeColors[move.type])
		local movePowerColor = Theme.COLORS["Lower box text"]

		if move.id == MoveData.Values.HiddenPowerId and Battle.isViewingOwn then
			moveTypeColor = Utils.inlineIf(move.type == PokemonData.Types.UNKNOWN, Theme.COLORS["Lower box text"], Constants.MoveTypeColors[move.type])
		elseif move.id == MoveData.Values.WeatherBallId and Options["Calculate variable damage"] then
			moveTypeColor = Constants.MoveTypeColors[move.type]
		end

		-- MOVE CATEGORY
		if Options["Show physical special icons"] and allowHiddenMoveInfo then
			if move.category == MoveData.Categories.PHYSICAL then
				Drawing.drawImageAsPixels(Constants.PixelImages.PHYSICAL, Constants.SCREEN.WIDTH + moveCatOffset, moveOffsetY + 2, { Theme.COLORS["Lower box text"] }, shadowcolor)
			elseif move.category == MoveData.Categories.SPECIAL then
				Drawing.drawImageAsPixels(Constants.PixelImages.SPECIAL, Constants.SCREEN.WIDTH + moveCatOffset, moveOffsetY + 2, { Theme.COLORS["Lower box text"] }, shadowcolor)
			end
		end

		-- MOVE TYPE COLORED RECTANGLE
		if not Theme.MOVE_TYPES_ENABLED and move.name ~= Constants.BLANKLINE and allowHiddenMoveInfo then
			gui.drawRectangle(Constants.SCREEN.WIDTH + moveNameOffset - 3, moveOffsetY + 2, 2, 7, moveTypeColor, moveTypeColor)
			moveTypeColor = Theme.COLORS["Lower box text"]
		end

        local stabby = 1
		if move.isstab then
			stabby = 1.5
			if move.effectiveness >= 1 then
			    movePowerColor = Theme.COLORS["Positive text"]
            end
		end
--[[--]]
		if not allowHiddenMoveInfo and not Battle.isGhost then
			moveTypeColor = Theme.COLORS["Lower box text"]
			movePowerColor = Theme.COLORS["Lower box text"]
		end

		-- DRAW MOVE EFFECTIVENESS
		if move.showeffective then
			if move.power ~= "---" and move.power~= "RNG" and move.power~= "100x" and move.power~= "ITM" and data.x.viewingOwn then
			    if move.effectiveness > 1 and not move.isstab then
		            movePowerColor = Theme.COLORS["Positive text"]
                end
                if move.effectiveness < 1 then
		            movePowerColor = Theme.COLORS["Negative text"]
		        end
			    Drawing.drawNumber(Constants.SCREEN.WIDTH + movePowerOffset, moveOffsetY, math.floor(move.power*move.effectiveness*stabby), 3, movePowerColor, shadowcolor)
			else
			    Drawing.drawNumber(Constants.SCREEN.WIDTH + movePowerOffset, moveOffsetY, move.power, 3, movePowerColor, shadowcolor)
			end
			if move.effectiveness == 0 then
				Drawing.drawText(Constants.SCREEN.WIDTH + movePowerOffset - 7, moveOffsetY, "X", Theme.COLORS["Negative text"], shadowcolor)
			else
				Drawing.drawMoveEffectiveness(Constants.SCREEN.WIDTH + movePowerOffset - 5, moveOffsetY, move.effectiveness)
			end
		else
			Drawing.drawNumber(Constants.SCREEN.WIDTH + movePowerOffset, moveOffsetY, move.power, 3, movePowerColor, shadowcolor)

		end

		local moveName = move.name .. Utils.inlineIf(move.starred, "*", "")

		-- DRAW ALL THE MOVE INFORMATION
		Drawing.drawText(Constants.SCREEN.WIDTH + moveNameOffset, moveOffsetY, moveName, moveTypeColor, shadowcolor)
		Drawing.drawNumber(Constants.SCREEN.WIDTH + movePPOffset, moveOffsetY, move.pp, 2, Theme.COLORS["Lower box text"], shadowcolor)
		--Drawing.drawNumber(Constants.SCREEN.WIDTH + movePowerOffset, moveOffsetY, math.floor(move.power*move.effectiveness), 3, movePowerColor, shadowcolor)
		Drawing.drawNumber(Constants.SCREEN.WIDTH + moveAccOffset, moveOffsetY, move.accuracy, 3, Theme.COLORS["Lower box text"], shadowcolor)

		moveOffsetY = moveOffsetY + 10 -- linespacing
	end
end


	-- Executed once every 30 frames or after any redraw event is scheduled (i.e. most button presses)
	function self.afterRedraw()
		-- [ADD CODE HERE]
	end

	-- Executed before a button's onClick() is processed, and only once per click per button
	-- Param: button: the button object being clicked
	function self.onButtonClicked(button)
		-- [ADD CODE HERE]
	end

	-- Executed after a new battle begins (wild or trainer), and only once per battle
	function self.afterBattleBegins()
		-- [ADD CODE HERE]
	end

	-- Executed after a battle ends, and only once per battle
	function self.afterBattleEnds()
		-- [ADD CODE HERE]
	end


	return self
end
return MoveEffectivenessExt