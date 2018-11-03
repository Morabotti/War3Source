#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

//test commit
public Plugin:myinfo =
{
    name = "War3Source - Race - Undead Scourge",
    author = "War3Source Team",
    description = "The Undead Scourge race for War3Source"
};

new thisRaceID;
new HaloSprite, XBeamSprite;
new bool:UltStatus[66];

new bool:RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
    if(newrace==thisRaceID)
    {
        RaceDisabled=false;
    }
}
public OnWar3RaceDisabled(oldrace)
{
    if(oldrace==thisRaceID)
    {
        RaceDisabled=true;
    }
}

new Float:SuicideBomberRadius[9] = {0.0, 225.0, 250.0, 275.0, 300.0, 325.0, 333.0, 350.0, 350.0};
new Float:SuicideBomberDamage[9] = {0.0, 75.0, 100.0, 133.0, 166.0, 200.0, 233.0, 250.0, 300.0};
new Float:SuicideBomberDamageTF[9] = {0.0, 133.0, 175.0, 250.0, 300.0, 300.0, 300.0, 300.0, 300.0};

new Float:UnholySpeed[9] = {1.0, 1.03, 1.06, 1.10, 1.13, 1.16, 1.20, 1.22, 1.25};
new Float:LevitationGravity[9] = {1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.60, 0.50};
new Float:VampirePercent[9] = {0.0, 0.05, 0.07, 0.10, 0.13, 0.15, 0.17, 0.20, 0.25};

new SKILL_LEECH, SKILL_SPEED, SKILL_LOWGRAV, SKILL_SUICIDE;

public OnPluginStart()
{
    LoadTranslations("w3s.race.undead.phrases.txt");
}

public OnMapStart()
{
	XBeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
}

public OnWar3EventSpawn(client)
{
   new race = War3_GetRace(client);
   if(race == thisRaceID)
   {
		UltStatus[client]=false;
		decl Float:spawn_pos[3];
		GetClientAbsOrigin(client,spawn_pos);
		spawn_pos[2] = spawn_pos[2] + 10;
		TE_SetupBeamRingPoint(spawn_pos, 0.0, 50.0, XBeamSprite, HaloSprite, 2, 1, 3.0, 10.0, 2.0, {255,0,0,255}, 2, 0);
		TE_SendToAll(0.0);
		CreateTimer(10.0, UltAvailable, client);
   }
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 10)
    {
        thisRaceID = War3_CreateNewRaceT("undead");
        SKILL_LEECH = War3_AddRaceSkillT(thisRaceID, "VampiricAura", false, 8, "20%");
        SKILL_SPEED = War3_AddRaceSkillT(thisRaceID, "UnholyAura", false, 8, "20%");
        SKILL_LOWGRAV = War3_AddRaceSkillT(thisRaceID, "Levitation", false, 8, "0.5");
        SKILL_SUICIDE = War3_AddRaceSkillT(thisRaceID, "SuicideBomber", true, 8);
        W3SkillCooldownOnSpawn(thisRaceID,SKILL_SUICIDE,10.0,true);

        War3_CreateRaceEnd(thisRaceID);

        War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
        War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, UnholySpeed);
        War3_AddSkillBuff(thisRaceID, SKILL_LOWGRAV, fLowGravitySkill, LevitationGravity);
    }
}

public OnUltimateCommand(client, race, bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(pressed && War3_GetRace(client) == thisRaceID && IsPlayerAlive(client) && !Silenced(client) && UltStatus[client])
    {
        new ult_level = War3_GetSkillLevel(client, race, SKILL_SUICIDE);
        ult_level > 0 ? ForcePlayerSuicide(client) : W3MsgUltNotLeveled(client);
    }
}

public OnWar3EventDeath(victim, attacker)
{
    if(RaceDisabled)
    {
        return;
    }

    new race = W3GetVar(DeathRace);
    new skill = War3_GetSkillLevel(victim, thisRaceID, SKILL_SUICIDE);
    if(race == thisRaceID && skill > 0 && !Hexed(victim) && UltStatus[victim])
    {
        decl Float:fVictimPos[3];
        GetClientAbsOrigin(victim, fVictimPos);

        War3_SuicideBomber(victim, fVictimPos, GameTF() ? SuicideBomberDamageTF[skill] : SuicideBomberDamage[skill], SKILL_SUICIDE, SuicideBomberRadius[skill]);
    }
}

public Action:UltAvailable(Handle:timer, any:client)
{
	UltStatus[client]=true;
}