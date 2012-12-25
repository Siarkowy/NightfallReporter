--------------------------------------------------------------------------------
--  Nightfall Reporter (c) 2012 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

NightfallReporter = {
    author  = GetAddOnMetadata("NightfallReporter", "Author"),
    frame   = CreateFrame("Frame", "NightfallReporterFrame"),
    name    = "Nightfall Reporter",
    version = GetAddOnMetadata("NightfallReporter", "Version")
}

local NFR           = NightfallReporter

local DB_VERSION    = 20121225
local Applies       = {}
local Uptimes       = {}
local CombatStart
local frame         = NFR.frame
local playerGUID    = UnitGUID("player")

-- Spell Vulnerability info stuff
local SPELL_VULNERABILITY       = "Spell Vulnerability"
local SPELL_VULNERABILITY_ID    = 23605
local SPELL_VULNERABILITY_TEX   = "Interface\\Icons\\Spell_Holy_ElunesGrace"

-- Utils -----------------------------------------------------------------------

function NFR:Print(fmt, ...)
    DEFAULT_CHAT_FRAME:AddMessage(format("|cffff3333Nightfall Reporter:|r " .. fmt, ...))
end

function NFR:Echo(...)
    DEFAULT_CHAT_FRAME:AddMessage(format(...))
end

function NFR:Announce(...)
    local channel = self.db.announce and (UnitInRaid("player") and "RAID"
    or GetNumPartyMembers() > 0 and "PARTY")

    if channel then
        SendChatMessage(format(...), channel)
    else
        self:Print(...)
    end
end

local function count(t)
    local num = 0
    for k, v in pairs(t) do num = num + 1 end
    return num
end

local function wipe(t)
    for k, v in pairs(t) do t[k] = nil end
end

-- Core ------------------------------------------------------------------------

function NFR:Enable()
    if InCombatLockdown() then
        self:PLAYER_REGEN_DISABLED()
    end

    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function NFR:Disable()
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
    frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    self:ClearData()
end

function NFR:ClearData()
    wipe(Applies)
    wipe(Uptimes)
end

function NFR:ADDON_LOADED(name)
    if name ~= "NightfallReporter" then return end

    frame:UnregisterEvent("ADDON_LOADED")

    NightfallReporterDB = NightfallReporterDB and NightfallReporterDB.version == DB_VERSION
    and NightfallReporterDB or {
        announce = 1,
        enabled = 1,
        reports = 1,
        gainmsg = "%MOB gained <%SPELL>.",
        fademsg = "<%SPELL> fades from %MOB.",
        version = DB_VERSION
    }

    self.db = NightfallReporterDB

    if self.db.enabled then
        self:Enable()
    end
end

function NFR:PLAYER_REGEN_DISABLED() -- got combat
    self:ClearData()
    CombatStart = GetTime()
end

function NFR:PLAYER_REGEN_ENABLED() -- left combat
    local duration = GetTime() - CombatStart -- combat duration

    -- count in unfinished applies as if they ended right now
    for name, time in pairs(Applies) do
        Uptimes[name] = (Uptimes[name] or 0) + GetTime() - (time or GetTime())
    end

    if self.db.reports and count(Uptimes) > 0 then
        self:Print("Post fight report:")
        self:Echo("   Combat duration: %.2f s %s", duration, duration > 60 and format("(%s)", SecondsToTime(duration)) or "")
        self:Echo("   Debuff uptime per target:")
        for name, uptime in pairs(Uptimes) do
            self:Echo("   - %s: %.2f s (%.2f%% of combat time)", name, uptime, uptime / duration * 100)
        end
    end

    self:ClearData()
end

local data = {}
function NFR:COMBAT_LOG_EVENT_UNFILTERED(time, type, sourceGUID, sourceName,
    sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool,
    auraType)

    if spellId == SPELL_VULNERABILITY_ID then
        data.MOB    = destName
        data.GUID   = destGUID
        data.SPELL  = spellName

        if type == "SPELL_AURA_APPLIED" then
            Applies[destName] = GetTime()
            self:Announce(gsub(self.db.gainmsg, "%%(%u+)", data))
        elseif type == "SPELL_AURA_REMOVED" then
            Uptimes[destName] = (Uptimes[destName] or 0) + GetTime() - (Applies[destName] or GetTime())
            Applies[destName] = nil
            self:Announce(gsub(self.db.fademsg, "%%(%u+)", data))
        end
    end
end

-- Init ------------------------------------------------------------------------

function NFR:Init()
    local frame = self.frame
    frame:SetScript("OnEvent", function(frame, event, ...) self[event](self, ...) end)
    frame:RegisterEvent("ADDON_LOADED")

    self:Print("Version %s loaded.", self.version)
end

NFR:Init()
