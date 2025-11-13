-- ====================================================================================================
-- =                                           Some locals.                                           =
-- ====================================================================================================

local AddonName = "PoisonReminder"              -- The name of the addon.

local KnowPoison = false                        -- A check to see if we know poison.

local lastMessageTime_mainHandExpiration = 0    -- Used for timer for last message.
local lastMessageTime_mainHandCharges = 0       -- Used for timer for last message.
local lastMessageTime_hasMainHandEnchant = 0    -- Used for timer for last message.
local lastMessageTime_offHandExpiration = 0     -- Used for timer for last message.
local lastMessageTime_offHandCharges = 0        -- Used for timer for last message.
local lastMessageTime_hasOffHandEnchant = 0     -- Used for timer for last message.

local intPoisonCharges = 10                     -- Warn when there is less then this amount of poison left.
local intPoisonTimeLeft = 180                   -- Warn when there is this amount of time (in sec) left on poison.
local intPoisonRemainder = 30                   -- How often we want the warning. (in sec)

local strPoisonLowColor = "ff8633"              -- Color for the low count or time on poison.
local strPoisonMissingColor = "ff3333"          -- Color for the missing poison.

local LogInTime = GetTime()                     -- Used for a timer for the welcome message.
local PoisonReminderWelcome = false             -- Used to see if we already have said "Welcome"
local legendaryColor = "|cffFF8000"             -- The color we use to mark addon name.
local RogueColor = "|cFFFFF468"                 -- Color my name Rogue color.
local resetColor = "|r"                         -- Stop the coloring of text.

-- ====================================================================================================
-- =                                 Create frame and register events                                 =
-- ====================================================================================================

local f = CreateFrame("Frame");
    f:RegisterEvent("ADDON_LOADED");

-- ====================================================================================================
-- =                                          Event handler.                                          =
-- ====================================================================================================

-- f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
f:SetScript("OnEvent", function()
    if (event == "ADDON_LOADED") and (arg1 == AddonName) then
        -- Just if we need it at some point.
        f:UnregisterEvent("ADDON_LOADED");
    end
end)

-- ====================================================================================================
-- =                                     OnUpdate on every frame.                                     =
-- ====================================================================================================

f:SetScript("OnUpdate", function()

    -- A delay for showing a welcome message.
    if ((LogInTime + 5) < GetTime()) and (not PoisonReminderWelcome) then
        DEFAULT_CHAT_FRAME:AddMessage(legendaryColor .. AddonName .. resetColor .. " by " .. RogueColor .. "Subby" .. resetColor .. " is loaded.");
        PoisonReminderWelcome = true
    end

end)

-- ====================================================================================================
-- =                                      Do we know the spell ?                                      =
-- ====================================================================================================

local function CheckIfSpellIsKnown(spellName, rank)
    local i = 1
    local SearchSpell = string.gsub(spellName, "%s+", "")
    local SearchRank = rank

    -- Did we get anything ?
    if (not SearchSpell) then
        return
    end
    if (not SearchRank) then
        return
    end

    -- Loop through our spell book to find the spell and rank we are looking for.
    while true do
        local currentSpellName, currentSpellRank = GetSpellName(i, "spell");
        if (not currentSpellName) then
            break
        end

        -- Remove stuff we are not looking for.
        currentSpellName = string.gsub(currentSpellName, "%s+", "")
        currentSpellRank = string.gsub(currentSpellRank, "Rank%s+", "")

        if (string.find(currentSpellName, SearchSpell)) then
            -- Did we get the currentSpellRank there was not nil ?
            if (currentSpellRank ~= nil) then
                -- Some spells don't have a rank, if that is the case here, then we change it to 0
                if (currentSpellRank == nil) or (currentSpellRank == "") or (currentSpellRank == "Shapeshift") then
                    currentSpellRank = 0
                end
                -- The reason we use <= and not == here is that if we know rank 4 we also know rank 2.
                if (tonumber(SearchRank) <= tonumber(currentSpellRank)) then
                    return true
                -- Rank we was looking for is to high, so we return false.
                else
                    return false
                end
                
            elseif (currentSpellRank == nil) or (currentSpellRank == "") then
                return true
            end
        end
        i = i + 1
    end
    return false
end

-- ====================================================================================================
-- =                                           Poison check                                           =
-- ====================================================================================================

function CheckForPoison()

    -- Do we even know poison yet ? No reason to spam that we need it, if we can't make it yet.
    if (not KnowPoison) then
        if (CheckIfSpellIsKnown("Poisons", 0) ~= true) then
            return;
        else
            KnowPoison = true
        end
    end

    -- Do we have poison on our weapons ?
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();

    -- Check main-hand enchant status
    if (hasMainHandEnchant) then
        -- Is it running out on time ?
        if ((mainHandExpiration / 1000) <= intPoisonTimeLeft) then
            if ((GetTime() - lastMessageTime_mainHandExpiration) >= intPoisonRemainder) then
                lastMessageTime_mainHandExpiration = GetTime()
                DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonLowColor .. "Main-hand poison is expiring. - Reapply soon." .. "|r")
                PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Poison_Is_Running_Out.mp3");
            end
        end
        -- Is it running out due to amount of charges ?
        if (mainHandCharges < intPoisonCharges) then
            if ((GetTime() - lastMessageTime_mainHandCharges) >= intPoisonRemainder) then
                lastMessageTime_mainHandCharges = GetTime()
                DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonLowColor .. "Main-hand poison is low on charges. - Reapply soon." .. "|r")
                PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Poison_Is_Running_Low.mp3");
            end
        end
    -- We are missing poison on Main-hand.
    else
        if ((GetTime() - lastMessageTime_hasMainHandEnchant) >= intPoisonRemainder) then
            lastMessageTime_hasMainHandEnchant = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonMissingColor .. ">> MISSING POISON - MAIN-HAND <<" .. "|r")
            PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Missing_Poison.mp3");
        end
    end

    -- Check off-hand enchant status
    if (hasOffHandEnchant) then
        -- Is it running out on time ?
        if ((offHandExpiration / 1000) <= intPoisonTimeLeft) then
            if ((GetTime() - lastMessageTime_offHandExpiration) >= intPoisonRemainder) then
                lastMessageTime_offHandExpiration = GetTime()
                DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonLowColor .. "Off-hand poison is expiring. - Reapply soon." .. "|r")
                PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Poison_Is_Running_Out.mp3");
            end
        end
        -- Is it running out due to amount of charges ?
        if (offHandCharges < intPoisonCharges) then
            if GetTime() - lastMessageTime_offHandCharges >= intPoisonRemainder then
                lastMessageTime_offHandCharges = GetTime()
                DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonLowColor .. "Off-hand poison is low on charges. - Reapply soon." .. "|r")
                PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Poison_Is_Running_Low.mp3");
            end
        end
    -- We are missing poison on Off-hand.
    else
        if ((GetTime() - lastMessageTime_hasOffHandEnchant) >= intPoisonRemainder) then
            lastMessageTime_hasOffHandEnchant = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage("|cff" .. strPoisonMissingColor .. ">> MISSING POISON - OFF-HAND <<" .. "|r")
            PlaySoundFile("Interface\\AddOns\\PoisonReminder\\Sounds\\Missing_Poison.mp3");
        end
    end

end