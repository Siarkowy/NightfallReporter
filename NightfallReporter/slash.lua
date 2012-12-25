--------------------------------------------------------------------------------
--  Nightfall Reporter (c) 2012 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local NFR = NightfallReporter

function NFR:OnSlashCmd(msg)
    if msg == "on" then
        self.db.enabled = 1
        self:Enable()
        self:Print("Addon enabled.")

    elseif msg == "off" then
        self.db.enabled = nil
        self:Disable()
        self:Print("Addon disabled.")

    elseif msg == "ann on" then
        self.db.announce = 1
        self:Print("Announce enabled.")

    elseif msg == "ann off" then
        self.db.announce = nil
        self:Print("Announce disabled.")

    elseif msg == "report on" then
        self.db.reports = 1
        self:Print("Post-fight report enabled.")

    elseif msg == "report off" then
        self.db.reports = nil
        self:Print("Post-fight report disabled.")

    elseif msg:match("^gainmsg") then
        local msg = msg:match("gainmsg%s*(.*)")
        self.db.gainmsg = msg
        self:Print("Gain message set to %q.", msg)

    elseif msg:match("^fademsg") then
        local msg = msg:match("fademsg%s*(.*)")
        self.db.fademsg = msg
        self:Print("Fade message set to %q.", msg)

    else
        self:Print("Version %s usage info:", self.version)
        self:Echo("/nfr { on || off || ann <on || off> || report <on || off> || gainmsg <msg> || fademsg <msg> }")
        self:Echo("   on || off - Global addon on/off toggle.")
        self:Echo("   ann <on || off> - Group announcements on/off toggle.")
        self:Echo("   report <on || off> - Post-fight report on/off toggle.")
        self:Echo("   gainmsg <message> - Set message to display when gaining buff.")
        self:Echo("   fademsg <message> - Same as above but when buff fades.")
        self:Echo("<message> in gainmsg or fademsg can contain some variables:")
        self:Echo("   %%MOB - Affected mob's name.")
        self:Echo("   %%GUID - Affected mob's global unique indentifier.")
        self:Echo("   %%SPELL - Localised buff name.")
    end
end

function SlashCmdList.NIGHTFALLREPORTER(msg) NFR:OnSlashCmd(msg) end
SLASH_NIGHTFALLREPORTER1 = "/nightfallreporter"
SLASH_NIGHTFALLREPORTER2 = "/nfr"
