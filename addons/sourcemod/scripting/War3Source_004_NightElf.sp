#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
new thisRaceID;

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

public Plugin:myinfo =
{
    name = "War3Source - Race - Night Elf",
    author = "War3Source Team",
    description = "The Night Elf race for War3Source."
};

new ClientTracer;
new BeamSprite, HaloSprite;
new bool:bIsEntangled[MAXPLAYERSCUSTOM];
new String:entangleSound[] = "*mora-wcs/war3source/entanglingrootsdecay1.mp3";
new String:entangleSound_FullPath[] = "sound/mora-wcs/war3source/entanglingrootsdecay1.mp3";
new Handle:EntangleCooldownCvar;

new SKILL_EVADE, SKILL_THORNS, SKILL_TRUESHOT, ULT_ENTANGLE;

// Chance/Data Arrays
new Float:fEvadeChance[9] = {0.0, 0.05, 0.07, 0.10, 0.13, 0.16, 0.20, 0.22, 0.25};
new Float:ThornsReturnDamage[9] = {0.0, 0.05, 0.09, 0.12, 0.15, 0.18, 0.20, 0.22, 0.25};
new Float:TrueshotDamagePercent[9] = {1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.20, 1.22};
new Float:EntangleDistance = 600.0;
new Float:EntangleDuration[9] = {0.0, 1.20, 1.35, 1.55, 1.70, 1.90, 2.00, 2.20, 2.35};

public OnPluginStart()
{
    EntangleCooldownCvar=CreateConVar("war3_nightelf_entangle_cooldown", "14", "Cooldown timer.");

    LoadTranslations("w3s.race.nightelf.phrases.txt");
}

public OnMapStart()
{
    AddFileToDownloadsTable(entangleSound_FullPath);
    PrecacheSoundAny(entangleSound);
	
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 40)
    {
        thisRaceID = War3_CreateNewRaceT("nightelf");
        SKILL_EVADE = War3_AddRaceSkillT(thisRaceID, "Evasion", false, 8);
        SKILL_THORNS = War3_AddRaceSkillT(thisRaceID, "ThornsAura", false, 8);
        SKILL_TRUESHOT = War3_AddRaceSkillT(thisRaceID, "TrueshotAura", false, 8);
        ULT_ENTANGLE = War3_AddRaceSkillT(thisRaceID, "EntanglingRoots", true, 8);

        War3_CreateRaceEnd(thisRaceID);

        War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, fEvadeChance);
    }
}

public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ClientTracer);
}

public bool:ImmunityCheck(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    if(bIsEntangled[client] || W3HasImmunity(client, Immunity_Ultimates))
    {
        return false;
    }

    return true;
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race == thisRaceID && ValidPlayer(client, true) && pressed)
    {
        new iEntangleLevel = War3_GetSkillLevel(client, race, ULT_ENTANGLE);
        if(iEntangleLevel > 0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, ULT_ENTANGLE, true))
            {
                new Float:distance = EntangleDistance;
                new target; // easy support for both

                new Float:fClientPos[3];
                GetClientAbsOrigin(client,fClientPos);

                target = War3_GetTargetInViewCone(client, distance, false, 23.0, ImmunityCheck);
                if(ValidPlayer(target, true))
                {
                    bIsEntangled[target] = true;

                    War3_SetBuff(target, bNoMoveMode, thisRaceID, true);
                    new Float:fEntangleTime = EntangleDuration[iEntangleLevel];
                    CreateTimer(fEntangleTime, StopEntangle, target);
                    new Float:fEffectPos[3];
                    GetClientAbsOrigin(target, fEffectPos);

                    for (new i=0; i <= 3; i++)
                    {
                        fEffectPos[2] += 15.0;
                        TE_SetupBeamRingPoint(fEffectPos, 45.0, 44.0, BeamSprite,
                                              HaloSprite, 0, 15, fEntangleTime,
                                              5.0, 0.0, {0, 255, 0, 255}, 10, 0);
                        TE_SendToAll();
                    }

                    fClientPos[2] += 25.0;
                    TE_SetupBeamPoints(fClientPos, fEffectPos, BeamSprite,
                                       HaloSprite, 0, 50, 3.0, 6.0, 25.0, 0,
                                       12.0, {80, 255, 90, 255}, 40);
                    TE_SendToAll();

                    EmitSoundToAllAny(entangleSound, target);
                    EmitSoundToAllAny(entangleSound, target);

                    W3MsgEntangle(target, client);
                    W3FlashScreen(target, RGBA_COLOR_GREEN);
                    War3_CooldownMGR(client, GetConVarFloat(EntangleCooldownCvar), thisRaceID, ULT_ENTANGLE, _, _);
                }
                else
                {
                    W3MsgNoTargetFound(client, distance);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

Untangle(client)
{
    bIsEntangled[client] = false;
    War3_SetBuff(client, bNoMoveMode, thisRaceID, false);
}

public Action:StopEntangle(Handle:timer, any:client)
{
    Untangle(client);
}

public OnWar3EventSpawn(client)
{
    if(RaceDisabled)
    {
        return;
    }

    if(bIsEntangled[client])
    {
        Untangle(client);
    }

    new currRace = War3_GetRace( client );
    if( currRace == thisRaceID )
    {
      decl Float:spawn_pos[3];
      GetClientAbsOrigin(client, spawn_pos);
      for (new i=0; i <= 3; i++)
      {
          spawn_pos[2] += 15.0;
          TE_SetupBeamRingPoint(spawn_pos, 45.0, 44.0, BeamSprite,
                                HaloSprite, 0, 15, 3.0,
                                5.0, 0.0, {0, 255, 0, 255}, 10, 0);
          TE_SendToAll();
      }
    }
}

public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(attacker != victim)
    {
        // Trueshot
        if(ValidPlayer(attacker) && War3_GetRace(attacker) == thisRaceID)
        {
            // Don't increase friendly fire damage
            if(ValidPlayer(victim) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }

            new iTrueshotLevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_TRUESHOT);
            if(iTrueshotLevel > 0 && !Hexed(attacker, false) && !W3HasImmunity(victim, Immunity_Skills))
            {
                War3_DamageModPercent(TrueshotDamagePercent[iTrueshotLevel]);
                W3FlashScreen(victim, RGBA_COLOR_RED);
            }
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(!isWarcraft && ValidPlayer(victim) && victim != attacker && War3_GetRace(victim) == thisRaceID)
    {
        new iThornsLevel = War3_GetSkillLevel(victim, thisRaceID, SKILL_THORNS );
        if(iThornsLevel > 0 && !Hexed(victim, false))
        {
            // Don't return friendly fire damage
            if(ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }

            if(!W3HasImmunity(attacker, Immunity_Skills))
            {
                new iDamage = RoundToFloor(damage * ThornsReturnDamage[iThornsLevel]);
                if(iDamage > 0)
                {
                    if(iDamage > 40)
                    {
                        iDamage = 40;
                    }

                    if (GAMECSANY)
                    {
                        // Since this is delayed we don't know if the damage actually went through
                        // and just have to assume... Stupid!
                        War3_DealDamageDelayed(attacker, victim, iDamage, "thorns", 0.1, true, SKILL_THORNS);
                        War3_EffectReturnDamage(victim, attacker, iDamage, SKILL_THORNS);
                    }
                    else
                    {
                        if(War3_DealDamage(attacker, iDamage, victim, _, "thorns", _, W3DMGTYPE_PHYSICAL))
                        {
                            War3_EffectReturnDamage(victim, attacker, War3_GetWar3DamageDealt(), SKILL_THORNS);
                        }
                    }
                }
            }
        }
    }

}
