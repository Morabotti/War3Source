#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Race - Blood Hunter",
    author = "War3Source Team",
    description = "The Blood Hunter race for War3Source."
};

new thisRaceID;
new g_bloodModel, g_sprayModel;

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

new Handle:ultCooldownCvar;

new SKILL_CRAZY, SKILL_FEAST,SKILL_SENSE,ULT_RUPTURE;

new Float:CrazyDuration[9] = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
new Float:CrazyUntil[MAXPLAYERSCUSTOM];
new bool:bCrazyDot[MAXPLAYERSCUSTOM];
new CrazyBy[MAXPLAYERSCUSTOM];

new Float:FeastAmount[9]={0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24};

new Float:BloodSense[9]={0.0, 0.1, 0.13, 0.16, 0.19, 0.22, 0.25, 0.28};

new Float:ultRange = 500.0;
new Float:ultiDamageMultiPerDistance[9] = {0.0, 0.045, 0.055, 0.065, 0.075, 0.085, 0.095, 0.105, 0.115};
new Float:ultiDamageMultiPerDistanceCS[9] = {0.0, 0.045, 0.060, 0.075, 0.90, 1.05, 1.1, 1.2, 1.3};
new Float:lastRuptureLocation[MAXPLAYERSCUSTOM][3];
new Float:RuptureDuration = 8.0;
new Float:RuptureUntil[MAXPLAYERSCUSTOM];
new bool:bRuptured[MAXPLAYERSCUSTOM];
new RupturedBy[MAXPLAYERSCUSTOM];
new BeamSprite, HaloSprite;

new String:ultsnd_bh[]="*mora-wcs/war3source/bh/ult.mp3";
new String:ultsnd_bh_FullPath[]="sound/mora-wcs/war3source/bh/ult.mp3";

public OnPluginStart()
{
    ultCooldownCvar = CreateConVar("war3_bh_ult_cooldown", "20", "Cooldown time for Ultimate.");
    CreateTimer(0.1, RuptureCheckLoop, _, TIMER_REPEAT);
    CreateTimer(0.5, BloodCrazyDOTLoop, _, TIMER_REPEAT);

    LoadTranslations("w3s.race.bh.phrases.txt");
    
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==110)
    {
        thisRaceID = War3_CreateNewRaceT("bh");
        SKILL_CRAZY = War3_AddRaceSkillT(thisRaceID, "BloodCrazy", false, 8);
        SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false, 8);
        SKILL_SENSE = War3_AddRaceSkillT(thisRaceID, "BloodSense", false, 8);
        ULT_RUPTURE = War3_AddRaceSkillT(thisRaceID, "Hemorrhage", true, 8);
        War3_CreateRaceEnd(thisRaceID);
    }
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blood.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blood.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bloodspray.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bloodspray.vtf");
	g_bloodModel = PrecacheModel("materials/mora-wcs/sprites/blood.vmt", true);
	g_sprayModel = PrecacheModel("materials/mora-wcs/sprites/bloodspray.vmt", true);
	AddFileToDownloadsTable(ultsnd_bh_FullPath);
	PrecacheSoundAny(ultsnd_bh);
	BeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race == thisRaceID && pressed && ValidPlayer(client, true))
    {
        new skill = War3_GetSkillLevel(client, race, ULT_RUPTURE);
        if(skill > 0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, ULT_RUPTURE, true))
            {
                new target = War3_GetTargetInViewCone(client, ultRange, false);
                if(ValidPlayer(target, true) && !W3HasImmunity(target, Immunity_Ultimates))
                {
					bRuptured[target] = true;
					RupturedBy[target] = client;
					RuptureUntil[target] = GetGameTime() + RuptureDuration;
					GetClientAbsOrigin(target, lastRuptureLocation[target]);
					
					W3SetPlayerColor(target,thisRaceID,220,0,0,_,GLOW_ULTIMATE);
					
					War3_CooldownMGR(client, GetConVarFloat(ultCooldownCvar), thisRaceID, ULT_RUPTURE, true, true);
					
					EmitSoundToAllAny(ultsnd_bh, client);
					EmitSoundToAllAny(ultsnd_bh, target);
					EmitSoundToAllAny(ultsnd_bh, target);
					PrintHintText(target, "%T", "You have been ruptured! You take damage if you move!", target);
					PrintHintText(client, "%T", "Rupture!", client);
                }
                else
                {
                    W3MsgNoTargetFound(client, ultRange);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public OnWar3EventSpawn(client)
{
    if(RaceDisabled)
    {
        return;
    }
	bRuptured[client] = false;
	bCrazyDot[client] = false;
	W3ResetPlayerColor(client,thisRaceID);
	
	new race = War3_GetRace(client);
	if(race == thisRaceID)
	{
		decl Float:spawn_pos[3];
		new Float:upVec[3];
		new Float:rightVec[3];
		new Float:vec[3];
		static const color[] = {215,0,0,255};
		
		GetClientAbsOrigin(client,vec);
		GetClientAbsOrigin(client,spawn_pos);
		spawn_pos[2] += 8;
		vec[0] -= 10;
		vec[1] -= 10;
		GetVectorVectors(vec, rightVec, upVec);
		
		TE_SetupBeamRingPoint(spawn_pos, 140.0, 150.0, BeamSprite, HaloSprite, 0, 1, 1.0, 7.0, 0.0, {204, 51, 0, 215}, 0, 0);
		TE_SendToAll(0.0);
		
		//MiddlePOS
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.0);
		
		//FirstRow
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.2);
		spawn_pos[1] -= 60;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.2);
		spawn_pos[1] += 30;
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.2);
		spawn_pos[0] -= 60;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.2);
		
		//SecondRow
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] += 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[0] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		spawn_pos[1] -= 30;
		TE_SetupBloodSprite(spawn_pos, rightVec, color, 24, g_sprayModel, g_bloodModel);
		TE_SendToAll(0.5);
		
	}
}

public OnWar3EventDeath(victim, attacker)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(attacker,true))
    {
        if(War3_GetRace(attacker) == thisRaceID)
        {
            new skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
            if(skill > 0 && !Hexed(attacker, false))
            {
                War3_HealToMaxHP(attacker, RoundFloat(FloatMul(float(War3_GetMaxHP(victim)), FeastAmount[skill])));
                W3FlashScreen(attacker, RGBA_COLOR_GREEN, 0.3, _, FFADE_IN);
            }
        }
    }
}


public Action:RuptureCheckLoop(Handle:h, any:data)
{
    if(RaceDisabled)
    {
        return;
    }

    new Float:origin[3];
    new attacker;
    new skilllevel;
    new Float:dist;
    for(new i=1;i<=MaxClients;i++)
    {
        if(!ValidPlayer(i, true) || !bRuptured[i])
        {
            continue;
        }

        attacker = RupturedBy[i];
        if(ValidPlayer(attacker))
        {
            if(War3_GetGame() == Game_TF)
            {
                Gore(i);
            }
            skilllevel = War3_GetSkillLevel(attacker, thisRaceID, ULT_RUPTURE);
            GetClientAbsOrigin(i,origin);
            dist=GetVectorDistance(origin, lastRuptureLocation[i]);

            new damage = RoundFloat(FloatMul(dist, War3_GetGame() == CS ? ultiDamageMultiPerDistanceCS[skilllevel] : ultiDamageMultiPerDistance[skilllevel]));
            if(damage > 0)
            {
                if(War3_GetGame() == Game_TF)
                {
                    War3_DealDamage(i, damage, attacker, _, "rupture", _, W3DMGTYPE_TRUEDMG);
                }
                else
                {
                    if(GetClientHealth(i) > damage)
                    {
                        War3_DecreaseHP(i, damage);
                    }
                    else
                    {
                        War3_DealDamage(i, damage, attacker, _, "rupture", _, W3DMGTYPE_TRUEDMG);
                    }
                }
				War3_ShowHealthLostParticle(i);
				Gore(i);
				lastRuptureLocation[i][0] = origin[0];
				lastRuptureLocation[i][1] = origin[1];
				lastRuptureLocation[i][2] = origin[2];
				W3FlashScreen(i, RGBA_COLOR_RED, 1.0, _, FFADE_IN);
            }
        }

        if(GetGameTime() > RuptureUntil[i])
        {
            bRuptured[i] = false;
            W3ResetPlayerColor(i,thisRaceID);
        }
    }
}
public Action:BloodCrazyDOTLoop(Handle:h,any:data)
{
    if(RaceDisabled)
    {
        return;
    }

    new attacker;
    for(new i=1; i <= MaxClients; i++)
    {
        if(!ValidPlayer(i, true) || !bCrazyDot[i])
        {
            continue;
        }

        attacker = CrazyBy[i];
        if(ValidPlayer(attacker))
        {
            if(War3_GetGame() == Game_TF)
            {
                War3_DealDamage(i, 1, attacker, _, "bleed_kill");
            }
            else
            {
                if(War3_GetGame() == Game_CS && GetClientHealth(i) > 1)
                {
                    War3_DecreaseHP(i, 1);
                }
                else
                {
                    War3_DealDamage(i, 1, attacker, _, "bloodcrazy");
                }
            }
            War3_ShowHealthLostParticle(i);
        }

        if(GetGameTime() > CrazyUntil[i])
        {
            bCrazyDot[i] = false;
        }
    }
}

public OnW3EnemyTakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(!W3IsOwnerSentry(attacker) && War3_GetRace(attacker) == thisRaceID && !Hexed(attacker, false) && !W3HasImmunity(victim,Immunity_Skills))
    {
        new skilllevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_CRAZY);
        if(skilllevel > 0)
        {
            bCrazyDot[victim] = true;
            CrazyBy[victim] = attacker;
            CrazyUntil[victim] = GetGameTime() + CrazyDuration[skilllevel];
        }

        skilllevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_SENSE);
        if(skilllevel > 0)
        {
            if(FloatDiv(float(GetClientHealth(victim)), float(War3_GetMaxHP(victim))) < BloodSense[skilllevel])
            {
                W3FlashScreen(victim, RGBA_COLOR_RED, 0.3,_, FFADE_IN);
                War3_DamageModPercent(2.0);
                PrintToConsole(attacker, "%T", "Double Damage against low HP enemies!", attacker);
            }
        }
    }
}

public Gore(client)
{
	if(RaceDisabled)
	{
	    return;
	}
	
	new Float:upVec[3];
	new Float:rightVec[3];
	new Float:vec[3];
	static const color[] = {215,0,0,255};
	
	GetClientAbsOrigin(client,vec);
	vec[0] -= 10;
	vec[1] -= 10;
	vec[2] += 25;
	GetVectorVectors(vec, rightVec, upVec);
	
	TE_SetupBloodSprite(vec, rightVec, color, 23, g_sprayModel, g_bloodModel);
	
	TE_SendToAll(0.0);
}

/*
WriteParticle(client, String:ParticleName[])
{
    if(RaceDisabled)
    {
        return;
    }

    decl Float:fPos[3], Float:fAngles[3];

    fAngles[0] = GetRandomFloat(0.0, 360.0);
    fAngles[1] = GetRandomFloat(0.0, 15.0);
    fAngles[2] = GetRandomFloat(0.0, 15.0);

    GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
    fPos[2] += GetRandomFloat(35.0, 65.0);

    AttachThrowAwayParticle(client, ParticleName, fPos, "", 6.0, fAngles);
}
*/