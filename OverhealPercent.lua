OverhealPercent = {}
OverhealPercent.orderedCaptureData = {}
OverhealPercent.unorderedCaptureData = {}
OverhealPercent.globalStringInfoArray = {};
OverhealPercent.CombatEventData = {}

OverhealPercent.EVENTTYPE_HEAL = 2;

OverhealPercent.DAMAGETYPE_PHYSICAL	= 1;
OverhealPercent.DAMAGETYPE_HOLY     = 2;
OverhealPercent.DAMAGETYPE_NATURE   = 3;
OverhealPercent.DAMAGETYPE_FIRE     = 4;
OverhealPercent.DAMAGETYPE_FROST    = 5;
OverhealPercent.DAMAGETYPE_SHADOW   = 6;
OverhealPercent.DAMAGETYPE_ARCANE   = 7;
OverhealPercent.DAMAGETYPE_UNKNOWN  = 999;
OverhealPercent.playerName = "";

OverhealPercent.m_healAmount = 0;
OverhealPercent.m_overhealAmount = 0;
OverhealPercent.m_numberOfHits = 0;
OverhealPercent.m_numberOfCrits = 0;
OverhealPercent.m_sessionHealAmount = 0;
OverhealPercent.m_sessionOverhealAmount = 0;
OverhealPercent.m_sessionNumberOfHeals = 0;
OverhealPercent.m_sessionNumberOfCrits = 0;
OverhealPercent.m_displayFrame = nil;
OverhealPercent.m_inCombat = false;
OverhealPercent.m_frameLocked = true;
OverhealPercent.m_printEndOfCombatResults = true;
OverhealPercent.m_frameXPos = 0;
OverhealPercent.m_frameYPos = 0;
OverhealPercent.m_soundEnabled = true;

OverhealPercent.m_ignoredSpells = {
	["Judgement of Light"] = true
};

function print(string)
	DEFAULT_CHAT_FRAME:AddMessage(string)
end

SLASH_OVERHEAL_PERCENT1, SLASH_OVERHEAL_PERCENT2 = '/op', '/overhealpercent';
SlashCmdList["OVERHEAL_PERCENT"] = function(msg, editbox)
	if not msg or msg == "" then
		OverhealPercent.PrintHelp();
		return;
	end

	if msg == "lock" then
		OverhealPercent.m_frameLocked = not OverhealPercent.m_frameLocked;

		if OverhealPercent.m_frameLocked then
			print("OverhealPercent: Frame Locked.");
		else
			print("OverhealPercent: Frame Unlocked.");
		end
	elseif msg == "sound" then
		OverhealPercent.m_soundEnabled = not OverhealPercent.m_soundEnabled;

		if OverhealPercent.m_soundEnabled then
			print("Low overhealing sound enabled.");
		else
			print("Low overhealing sound disabled.");
		end
	elseif msg == "session clear" then
		OverhealPercent.ClearSession();
	elseif msg == "session stats" then
		OverhealPercent.PrintSessionStats();
	elseif msg == "results" then
		OverhealPercent.m_printEndOfCombatResults = not OverhealPercent.m_printEndOfCombatResults;

		if OverhealPercent.m_printEndOfCombatResults then
			print("OverhealPercent: Printing combat results to chat.");
		else
			print("OverhealPercent: Not printing combat results to chat.");
		end
	elseif msg == "reset" then
		OverhealPercent.m_displayFrame:SetPoint("TOPLEFT", 0, 0);
	else
		OverhealPercent.PrintHelp();
	end
end

function OverhealPercent.PrintHelp()
	print("Overheal Percent by Atashi!");
	print("</op lock> to toggle frame lock");
	print("</op reset> to reset the window position");
	print("</op session clear> to clear session");
	print("</op session stats> to show detailed session stats");
	print("</op sound> to toggle the low overhealing sound");
	print("</op results> to toglle printing of combat stats when exiting combat");
end

function OverhealPercent.OnLoad(self)
	print("OverhealPercent Loaded");
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_LOGOUT");

 	OverhealPercent.playerName = UnitName("player");
	OverhealPercent.CreateFrame();
end

function OverhealPercent.CreateFrame()
	OverhealPercent.m_displayFrame = CreateFrame("Frame", "frame", UIParent);
	OverhealPercent.m_displayFrame:SetFrameStrata("BACKGROUND");
	OverhealPercent.m_displayFrame:SetWidth(140);
	OverhealPercent.m_displayFrame:SetHeight(40);

	OverhealPercent.m_displayFrame:SetMovable(true);
	OverhealPercent.m_displayFrame:EnableMouse(true);
	OverhealPercent.m_displayFrame:SetScript("OnMouseDown", function(self, button)
		if OverhealPercent.m_frameLocked then
			return;
		end

		if not OverhealPercent.m_displayFrame.isMoving then
			OverhealPercent.m_displayFrame:StartMoving();
			OverhealPercent.m_displayFrame.isMoving = true;
		end
	end);

	OverhealPercent.m_displayFrame:SetScript("OnMouseUp", function(self, button)
		if OverhealPercent.m_frameLocked then
			return;
		end

		if OverhealPercent.m_displayFrame.isMoving then
			OverhealPercent.m_displayFrame:StopMovingOrSizing();
			OverhealPercent.m_displayFrame.isMoving = false;

			local point, relativeTo, relativePoint, xOfs, yOfs = OverhealPercent.m_displayFrame:GetPoint(1);
			OverhealPercent.m_frameXPos = xOfs;
			OverhealPercent.m_frameYPos = yOfs;
		end
	end)

	OverhealPercent.m_displayFrame.fightText = frame.text or frame:CreateFontString(nil, "ARTWORK");
	OverhealPercent.m_displayFrame.fightText:SetFont("Fonts\\FRIZQT__.TTF", 15);
	OverhealPercent.m_displayFrame.fightText:SetTextColor(0.0, 1.0, 0.0, 1);
	OverhealPercent.m_displayFrame.fightText:SetPoint("TOPLEFT", 3, -3);
	OverhealPercent.m_displayFrame.fightText:SetText("Overhealing: 0%");

	OverhealPercent.m_displayFrame.sessionText = frame:CreateFontString(nil, "ARTWORK");
	OverhealPercent.m_displayFrame.sessionText:SetFont("Fonts\\FRIZQT__.TTF", 15);
	OverhealPercent.m_displayFrame.sessionText:SetTextColor(0.0, 1.0, 0.0, 1);
	OverhealPercent.m_displayFrame.sessionText:SetPoint("TOPLEFT", 3, -20);
	OverhealPercent.m_displayFrame.sessionText:SetText("Session: 0%");

	if OP_FRAME_X_POS and OP_FRAME_Y_POS then
		OverhealPercent.m_displayFrame:SetPoint("TOPLEFT", OP_FRAME_X_POS, OP_FRAME_Y_POS);
	end
	OverhealPercent.m_frameXPos = OP_FRAME_X_POS;
	OverhealPercent.m_frameYPos = OP_FRAME_Y_POS;

	local texture = frame:CreateTexture(nil,"BACKGROUND");
	texture:SetTexture(0, 0, 0);
	texture:SetAllPoints(frame);
	OverhealPercent.m_displayFrame.texture = texture;

	OverhealPercent.m_displayFrame:Show();
end

function OverhealPercent.OnEvent(event, arg)
	if event == "CHAT_MSG_SPELL_SELF_BUFF" then
		OverhealPercent.ParseForOutgoingSpellHeals(arg1);

		if (OverhealPercent.m_inCombat) and (OverhealPercent.m_healAmount > 0) then
			OverhealPercent.SetOverhealText(OverhealPercent.m_overhealAmount / OverhealPercent.m_healAmount);
			OverhealPercent.SetSessionOverheal(OverhealPercent.m_sessionOverhealAmount / OverhealPercent.m_sessionHealAmount);
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		OverhealPercent.ClearText();
	elseif event == "PLAYER_REGEN_ENABLED" then
		OverhealPercent.m_inCombat = false;

		if OverhealPercent.m_healAmount > 0 then
			OverhealPercent.PrintBattleStats();
		end
	elseif event == "ADDON_LOADED" then
		if arg1 == "OverhealPercent" then
			if OP_FRAME_X_POS and OP_FRAME_Y_POS then
				OverhealPercent.m_displayFrame:SetPoint("TOPLEFT", OP_FRAME_X_POS, OP_FRAME_Y_POS);
			end
		end
	elseif event == "PLAYER_LOGOUT" then
		OP_FRAME_X_POS = OverhealPercent.m_frameXPos;
		OP_FRAME_Y_POS = OverhealPercent.m_frameYPos;
		OP_PRINT_RESULTS = OverhealPercent.m_printEndOfCombatResults;
		OP_PLAY_SOUND = OverhealPercent.m_soundEnabled;
	end
end

function OverhealPercent.ClearText()
	OverhealPercent.m_healAmount = 0;
	OverhealPercent.m_overhealAmount = 0;
	OverhealPercent.m_inCombat = true;
	OverhealPercent.SetOverhealText(0);
end

function OverhealPercent.ClearSession()
	OverhealPercent.m_sessionOverhealAmount = 0;
	OverhealPercent.m_sessionHealAmount = 0;
end

function OverhealPercent.PrintSessionStats()
	if OverhealPercent.m_sessionHealAmount == 0 then
		print("No healing done in session, bad healer!");
		return;
	end

	print("Total Healing done: " .. OverhealPercent.m_sessionHealAmount);

	if OverhealPercent.m_sessionOverhealAmount > 0 then
		print("Total Overhealing done " .. OverhealPercent.m_sessionOverhealAmount .. " (" .. OverhealPercent.GetSessionOverhealPercentage() .. "%)");
	else
		print("No overhealing! Congratulations :D");
	end

	print("Total number of heals: " .. OverhealPercent.m_sessionNumberOfHeals);

	if OverhealPercent.m_sessionNumberOfCrits > 0 then
		print("Total number of crits: " .. OverhealPercent.m_sessionNumberOfCrits .. " (" .. OverhealPercent.GetSessionCritPercentage() .. "%)");
	end
end

function OverhealPercent.PrintBattleStats()
	local overhealPercentage = OverhealPercent.GetBattleOverhealPercentage();
	local critPercentage = OverhealPercent.GetBattleCritPercentage();

	if OverhealPercent.m_printEndOfCombatResults then
		print("Healed " .. OverhealPercent.m_healAmount .. ", overhealed " .. OverhealPercent.m_overhealAmount .. " (" .. overhealPercentage .. "%) Crit% " .. critPercentage);
	end
	
	if OverhealPercent.m_soundEnabled and overhealPercentage < 5 then
		PlaySoundFile("Interface\\AddOns\\OverhealPercent\\wAWWWW.mp3")
	end
end

function OverhealPercent.SetOverhealText(a_amount)
	OverhealPercent.m_displayFrame.fightText:SetText("Overhealing: " .. math.floor(a_amount * 100 + 0.5) .. "%");
	OverhealPercent.m_displayFrame.fightText:SetTextColor(1.0 * a_amount, 1.0 - (1.0 * a_amount), 0.0, 1)
end

function OverhealPercent.SetSessionOverheal(a_amount)
	OverhealPercent.m_displayFrame.sessionText:SetText("Session: " .. math.floor(a_amount * 100 + 0.5) .. "%");
	OverhealPercent.m_displayFrame.sessionText:SetTextColor(1.0 * a_amount, 1.0 - (1.0 * a_amount), 0.0, 1)
end

function OverhealPercent.GetBattleOverhealPercentage()
	return math.floor((OverhealPercent.m_overhealAmount / OverhealPercent.m_healAmount) * 100 + 0.5);
end

function OverhealPercent.GetBattleCritPercentage()
	if OverhealPercent.m_numberOfCrits == 0 then
		return 0;
	end

	return math.floor((OverhealPercent.m_numberOfCrits / OverhealPercent.m_numberOfHits) * 100 + 0.5);
end

function OverhealPercent.GetSessionOverhealPercentage()
	return math.floor((OverhealPercent.m_sessionOverhealAmount / OverhealPercent.m_sessionHealAmount) * 100 + 0.5);
end

function OverhealPercent.GetSessionCritPercentage()
	if OverhealPercent.m_sessionNumberOfCrits  == 0 then
		return 0;
	end

	return math.floor((OverhealPercent.m_sessionNumberOfCrits / OverhealPercent.m_sessionNumberOfHeals) * 100 + 0.5);
end

-- **********************************************************************************
-- Parse the passed combat message for outgoing heal info.
-- **********************************************************************************
function OverhealPercent.ParseForOutgoingSpellHeals(combatMessage)
	if not OverhealPercent.m_inCombat then
		return
	end

	local eventData

	-- Look for a critical heal to yourself.
	local capturedData = OverhealPercent.GetCapturedData(combatMessage, "HEALEDCRITSELFSELF", {"%s", "%a"});
	if capturedData ~= nil then
		if OverhealPercent.m_ignoredSpells[capturedData.SpellName] ~= nil then
			return;
		end
		eventData = OverhealPercent.GetHealEventData(OverhealPercent.DIRECTIONTYPE_PLAYER_INCOMING, OverhealPercent.HEALTYPE_CRIT, capturedData.Amount, capturedData.SpellName, OverhealPercent.playerName);
		OverhealPercent.m_sessionNumberOfCrits = OverhealPercent.m_sessionNumberOfCrits + 1;
	end

	-- Look for a heal to yourself.
	local capturedData = OverhealPercent.GetCapturedData(combatMessage, "HEALEDSELFSELF", {"%s", "%a"});
	if capturedData ~= nil then
		if OverhealPercent.m_ignoredSpells[capturedData.SpellName] ~= nil then
			return;
		end
		eventData = OverhealPercent.GetHealEventData(OverhealPercent.DIRECTIONTYPE_PLAYER_INCOMING, OverhealPercent.HEALTYPE_NORMAL, capturedData.Amount, capturedData.SpellName, OverhealPercent.playerName);
		OverhealPercent.m_sessionNumberOfHeals = OverhealPercent.m_sessionNumberOfHeals + 1;
	end

	-- Look for a critical heal to someone else.
	local capturedData = OverhealPercent.GetCapturedData(combatMessage, "HEALEDCRITSELFOTHER", {"%s", "%n", "%a"});
	if capturedData ~= nil and capturedData.Name ~= "you" then
		if OverhealPercent.m_ignoredSpells[capturedData.SpellName] ~= nil then
			return;
		end
		eventData = OverhealPercent.GetHealEventData(OverhealPercent.DIRECTIONTYPE_PLAYER_OUTGOING, OverhealPercent.HEALTYPE_CRIT, capturedData.Amount, capturedData.SpellName, capturedData.Name);
		OverhealPercent.m_sessionNumberOfCrits = OverhealPercent.m_sessionNumberOfCrits + 1;
	end

	-- Look for a heal to someone else.
	local capturedData = OverhealPercent.GetCapturedData(combatMessage, "HEALEDSELFOTHER", {"%s", "%n", "%a"});
	if capturedData ~= nil and capturedData.Name ~= "you" then
		if OverhealPercent.m_ignoredSpells[capturedData.SpellName] ~= nil then
			return;
		end
		eventData = OverhealPercent.GetHealEventData(OverhealPercent.DIRECTIONTYPE_PLAYER_OUTGOING, OverhealPercent.HEALTYPE_NORMAL, capturedData.Amount, capturedData.SpellName, capturedData.Name);
		OverhealPercent.m_sessionNumberOfHeals = OverhealPercent.m_sessionNumberOfHeals + 1;
	end

	if eventData then
		OverhealPercent.PopulateOverhealData(eventData);

		OverhealPercent.m_healAmount = OverhealPercent.m_healAmount + eventData.Amount;
		OverhealPercent.m_sessionHealAmount = OverhealPercent.m_sessionHealAmount + eventData.Amount;
		
		if eventData.PartialAmount and eventData.PartialAmount > 0 then
			OverhealPercent.m_overhealAmount = OverhealPercent.m_overhealAmount + eventData.PartialAmount;
			OverhealPercent.m_sessionOverhealAmount = OverhealPercent.m_sessionOverhealAmount + eventData.PartialAmount;
		end

		return true;
	else
		-- Return the parse was NOT successful.
		return false;
	end
end

-- **********************************************************************************
-- This function returns the captured data table with all the captured data in fields.
-- If the pattern wasn't found then nil is returned.
-- Capture order keys.
-- %a = amount
-- %b = name of a buff/debuff
-- %c = name of creature (pet)
-- %f = name of the faction
-- %k = name of the skill
-- %n = name of enemy/player
-- %p = power type (mana, rage, energy)
-- %s = name of the ability/spell
-- %t = damage type
-- **********************************************************************************
function OverhealPercent.GetCapturedData(combatMessage, globalStringName, captureOrder)
	-- Check if the passed global string does not exist.
	if (getglobal(globalStringName) == nil) then
		print("Unable to find global string: " .. globalStringName, 1, 0, 0);
		return;
	end

	-- Format the global string into a lua compatible search string.
	local globalStringInfo = OverhealPercent.GetGlobalStringInfo(globalStringName);
	local stringFound = false;
	OverhealPercent.EraseTable(OverhealPercent.orderedCaptureData);

	-- Get the unordered capture data.
	local tempCapturedData = OverhealPercent.GetUnorderedCaptureDataTable(string.gfind(combatMessage, globalStringInfo.Search)());

	-- If a match was found.
	if (table.getn(tempCapturedData) == 0) then
		return nil
	end

	-- Loop through all of the values in the passed capture order table.
	for argNum, substituteValue in captureOrder do
		local captureString = tempCapturedData[globalStringInfo.ArgumentOrder[argNum]];

		if (substituteValue == "%a") then
			OverhealPercent.orderedCaptureData.Amount = captureString;
		elseif (substituteValue == "%b") then
			OverhealPercent.orderedCaptureData.BuffName = captureString;
		elseif (substituteValue == "%c") then
			OverhealPercent.orderedCaptureData.PetName = captureString;
		elseif (substituteValue == "%f") then
			OverhealPercent.orderedCaptureData.FactionName = captureString;
		elseif (substituteValue == "%k") then
			OverhealPercent.orderedCaptureData.SkillName = captureString;
		elseif (substituteValue == "%n") then
			OverhealPercent.orderedCaptureData.Name = captureString;
		elseif (substituteValue == "%p") then
			OverhealPercent.orderedCaptureData.PowerType = captureString;
		elseif (substituteValue == "%s") then
			OverhealPercent.orderedCaptureData.SpellName = captureString;
		elseif (substituteValue == "%t") then
			OverhealPercent.orderedCaptureData.DamageType = OverhealPercent.GetDamageTypeNumber(captureString);
		end
	end

	return OverhealPercent.orderedCaptureData;
end

-- **********************************************************************************
-- Get a lua compatible search string and the argument order from a global string
-- provided by blizzard.
-- **********************************************************************************
function OverhealPercent.GetGlobalStringInfo(globalStringName)
	-- Check if the passed global string does not exist.
	local globalString = getglobal(globalStringName);
	if (globalString == nil) then
		return;
	end

	-- Check if the global string info doesn't already exist for the passed global string name.
	if (OverhealPercent.globalStringInfoArray[globalStringName] == nil) then
		local searchString = "";
		local currentChar;
		local formatCode;
		local argumentNumber = 0;
		local argumentOrder = {};

		-- Loop through all of the characters in the passed string.
		local stringLength = string.len(globalString);
		for index = 0, stringLength do
		 -- Get the current character.
		 currentChar = string.sub(globalString, index, index);

		 -- Check if we aren't in a formatting code.
		 if (formatCode == nil) then
				-- Check if the current character is the start of a formatting code.
				if (currentChar == "%") then
				 formatCode = currentChar;
				else
					-- Check if the character is one of the magic characters and escape it.
					if (string.find(currentChar, "[%^%$%(%)%.%[%]%*%-%+%?]")) then
						searchString = searchString .. "%" .. currentChar;
					-- Normal character so just add it to the formatted string.
					else
						searchString = searchString .. currentChar;
					end
				end

			-- We are in a formatting code.
			else
				-- Add the current character to the format code.
				formatCode = formatCode .. currentChar;

				-- Check if the % character is being escaped.
				if (formatCode == "%%") then
					-- Add the % to the search string.
					searchString = searchString .. "%%";
					formatCode = nil;
				-- Check if it's a digit, a period, or a $ and do nothing so we loop to the next character in the format code.
				elseif (string.find(currentChar, "[%$%.%d]")) then
					-- Do nothing.
				-- Check for one of the types that need a string.
				elseif (string.find(currentChar, "[cEefgGiouXxqs]")) then
					-- Replace the format code with lua capture string syntax.
					searchString = searchString .. "(.+)";

					-- Increment the argument number.
					argumentNumber = argumentNumber + 1;

					-- Check if there is an argument position specified.
					local _, _, argumentPosition = string.find(formatCode, "(%d+)%$");
					if (argumentPosition) then
						argumentOrder[argumentNumber] = tonumber(argumentPosition);
					else
						argumentOrder[argumentNumber] = argumentNumber;
					end

					formatCode = nil;

				-- Check if it's the type that needs a number.
				elseif (currentChar == "d") then
					-- Replace the format code with lua capture digits syntax.
					searchString = searchString .. "(%d+)";
					argumentNumber = argumentNumber + 1;

					-- Check if there is an argument position specified.
					local _, _, argumentPosition = string.find(formatCode, "(%d+)%$");
					if (argumentPosition) then
						argumentOrder[argumentNumber] = tonumber(argumentPosition);
					else
						argumentOrder[argumentNumber] = argumentNumber;
					end

					formatCode = nil;
				else
					formatCode = nil;
				end
			end
		end

		-- Cache the global string info for later retrieval.
		OverhealPercent.globalStringInfoArray[globalStringName] = {Search=searchString, ArgumentOrder=argumentOrder};
	end

	-- Return the format info for the global string.
	return OverhealPercent.globalStringInfoArray[globalStringName];
end

-- **********************************************************************************
-- Erases the passed table without losing the reference to the original memory.
-- This helps prevent GC churn.
-- **********************************************************************************
function OverhealPercent.EraseTable(t)
	-- Loop through all the keys in the table and clear it.
	for key in pairs(t) do
 		t[key] = nil;
	end

	-- Set the length of the table to 0.
	table.setn(t, 0);
end

-- **********************************************************************************
-- This function populates the unordered capture data table with all of the
-- parameters passed.
-- **********************************************************************************
function OverhealPercent.GetUnorderedCaptureDataTable(c1, c2, c3, c4, c5, c6, c7, c8, c9)
	-- Erase old unorderd capture data.
	OverhealPercent.EraseTable(OverhealPercent.unorderedCaptureData);

	if (c1 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c1);
	end
	if (c2 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c2);
	end
	if (c3 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c3);
	end
	if (c4 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c4);
	end
	if (c5 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c5);
	end
	if (c6 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c6);
	end
	if (c7 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c7);
	end
	if (c8 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c8);
	end
	if (c9 ~= nil) then
		table.insert(OverhealPercent.unorderedCaptureData, c9);
	end

	-- Return the populated unordered capture data table.
	return OverhealPercent.unorderedCaptureData;
end

-- **********************************************************************************
-- Gets the damage type number for the given string.
-- **********************************************************************************
function OverhealPercent.GetDamageTypeNumber(damageTypeString)
	-- Return the correct damage type number for the passed string.
	if (damageTypeString == SPELL_SCHOOL0_CAP) then
		return OverhealPercent.DAMAGETYPE_PHYSICAL;
	elseif (damageTypeString == SPELL_SCHOOL1_CAP) then
		return OverhealPercent.DAMAGETYPE_HOLY;
	elseif (damageTypeString == SPELL_SCHOOL2_CAP) then
		return OverhealPercent.DAMAGETYPE_FIRE;
	elseif (damageTypeString == SPELL_SCHOOL3_CAP) then
		return OverhealPercent.DAMAGETYPE_NATURE;
	elseif (damageTypeString == SPELL_SCHOOL4_CAP) then
		return OverhealPercent.DAMAGETYPE_FROST;
	elseif (damageTypeString == SPELL_SCHOOL5_CAP) then
		return OverhealPercent.DAMAGETYPE_SHADOW;
	elseif (damageTypeString == SPELL_SCHOOL6_CAP) then
		return OverhealPercent.DAMAGETYPE_ARCANE;
	elseif (damageTypeString == "Arcane") then
		return OverhealPercent.DAMAGETYPE_ARCANE;
	end

	-- Return the unknown damage type.
	return OverhealPercent.DAMAGETYPE_UNKNOWN;
end

-- **********************************************************************************
-- Populates the combat event data table for a heal event with the passed info.
-- **********************************************************************************
function OverhealPercent.GetHealEventData(directionType, healType, amount, effectName, name)
	local eventData = OverhealPercent.CombatEventData;

	OverhealPercent.EraseTable(eventData);

	eventData.EventType = OverhealPercent.EVENTTYPE_HEAL;
	eventData.DirectionType = directionType;
	eventData.HealType = healType;
	eventData.Amount = amount;
	eventData.EffectName = effectName;
	eventData.Name = name;

	return eventData;
end

-- **********************************************************************************
-- Populates the passed event data with overheal info.
-- **********************************************************************************
function OverhealPercent.PopulateOverhealData(eventData)
	-- Get the appropriate unit id for the unit being checked for overheals.
	local unitID = OverhealPercent.GetUnitIDFromName(eventData.Name);

	if not unitID then
		if UnitName("target") == eventData.Name then
			unitID = "target";
		end
	end

	if (unitID) then
		local overhealAmount = eventData.Amount - (UnitHealthMax(unitID) - UnitHealth(unitID));
		--[[
		DEFAULT_CHAT_FRAME:AddMessage("Health: "..UnitHealth(unitID))
		DEFAULT_CHAT_FRAME:AddMessage("HealthMax: "..UnitHealthMax(unitID))
		DEFAULT_CHAT_FRAME:AddMessage("Overheal: "..overhealAmount)
		DEFAULT_CHAT_FRAME:AddMessage("Amount: "..eventData.Amount)
		]]--

		-- Check if any overhealing occured.
		if (overhealAmount > 0) then
			eventData.PartialAmount = overhealAmount;
		end
	end
end

-- **********************************************************************************
-- Gets a unit id for the name.
-- **********************************************************************************
function OverhealPercent.GetUnitIDFromName(uName)
	local unitID;

	if (uName == OverhealPercent.playerName) or (uName == "you") then
		unitID = "player";
	elseif (uName == UnitName("pet")) then
		unitID = "pet";
	else -- Check if the name is one of the player's raid or party members.
		local numRaidMembers = GetNumRaidMembers();

		for i = 1, numRaidMembers do
			if (uName == UnitName("raid" .. i)) then
				unitID = "raid" .. i;
			end
		end

		for i = 1, numRaidMembers do
			if (uName == UnitName("raidpet" .. i)) then
				unitID = "raidpet" .. i;
			end
		end

		-- Check if the unit ID was not already found.
		if (not unitID) then
			local numPartyMembers = GetNumPartyMembers();

			for i = 1, numPartyMembers do
				if (uName == UnitName("party" .. i)) then
					unitID = "party" .. i;
				end
			end
		end

		if (not unitID) then
			local numPartyMembers = GetNumPartyMembers();

			for i = 1, numPartyMembers do
				if (uName == UnitName("partypet" .. i)) then
					unitID = "partypet" .. i;
				end
			end
		end
	end

	-- Return the unit id.
	return unitID;
end