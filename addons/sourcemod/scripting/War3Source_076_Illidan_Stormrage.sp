/**
* File: War3Source_Illidan_Stormrage.sp
* Description: Illidan Stormrage fixed for SSG
* Author(s): Corrupted/Scruffy The Janitor
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"


// War3Source stuff
new thisRaceID, SKILL_DMG, SKILL_RETURN, SKILL_SPEED, ULT_RAGE;

// Chance/Data Arrays
// skill 1
new String:AttackSound[] = "*mora-wcs/ambient/Morabotti/explode_9.mp3";
new String:AttackSound_FullPath[] = "sound/mora-wcs/ambient/Morabotti/explode_9.mp3";
new Float:DamageChance[9] = { 0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32 };
new Damage[9] =  { 0, 4, 6, 8, 10, 12, 14, 16, 18 };
new AttackSprite;

// skill 2
new Float:ReturnDamage[9] =  { 0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24 };
new VictimSprite;

// skill 3
new Float:IllidanSpeed[9] = { 1.0, 1.10, 1.13, 1.16, 1.19, 1.22, 1.25, 1.28, 1.31 };
new Float:IllidanGrav[9] = { 1.0, 0.94, 0.87, 0.80, 0.74, 0.66, 0.60, 0.54, 0.5 };
new SpawnSprite;

// skill 4
new UltDamage[9] = { 0, 8, 12, 16, 20, 24, 26, 28, 30 };
new Float:oldPos[MAXPLAYERS][3];


public Plugin:myinfo = 
{
    name = "War3Source Race - Illidan Stormrage",
    author = "Scruffy The Janitor",
    description = "The Illidan Stormrage race for War3Source. Fixed by Scruffy for SSG",
    version = "1.0.2",
    url = "www.sevensinsgaming.com"
};

public OnMapStart()
{
	AddFileToDownloadsTable(AttackSound_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/sprites/scanner.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/scanner.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/640hud9.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/640hud9.vtf");
	
	PrecacheSoundAny( AttackSound );
	AttackSprite = PrecacheModel( "materials/mora-wcs/sprites/scanner.vmt" );
	SpawnSprite = PrecacheModel( "materials/mora-wcs/sprites/lgtning.vmt" );
	VictimSprite = PrecacheModel( "materials/mora-wcs/sprites/640hud9.vmt" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==760)
    {
    thisRaceID = War3_CreateNewRace( "Stormrage", "IS" );
    
    SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Skull of Gul'dan", "Use your demonic powers to cause more damage", false, 8 );
    SKILL_RETURN = War3_AddRaceSkill( thisRaceID, "Return Fire", "Returns a small amount of damage done to your enemy", false, 8 );
    SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "King of The Black Temple", "Get more speed and higher jump", false, 8 );
    ULT_RAGE = War3_AddRaceSkill( thisRaceID, "Eye of Sargeras", "Cause pain to your enemies!", true, 8 );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_RAGE, 12.0, _);
    
    War3_CreateRaceEnd( thisRaceID );
   }
}

public InitPassiveSkills( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {
        if( War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED ) > 0 )
        {
			War3_SetBuff( client, fMaxSpeed, thisRaceID, IllidanSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
			War3_SetBuff( client, fLowGravitySkill, thisRaceID, IllidanGrav[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
			
			new Float:pos[3];
			
			GetClientAbsOrigin( client, pos );
			
			pos[2] += 50;
			
			TE_SetupBeamRingPoint( pos, 20.0, 500.0, SpawnSprite, SpawnSprite, 0, 0, 3.0, 10.0, 1.0, { 100, 0, 255, 255 }, 3, FBEAM_ISACTIVE );
			TE_SendToAll(); 
		}
	}
}

public OnRaceChanged ( client,oldrace,newrace )
{
    if( newrace != thisRaceID )
    {
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
        War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {    
        if( IsPlayerAlive( client ) )
        {
            InitPassiveSkills( client );
        }
    }
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
    InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        InitPassiveSkills( client );
    }
}

public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChance[skill_level] )
            {
                new Float:pos[3];
                
                GetClientAbsOrigin( victim, pos );
                
                TE_SetupBeamRingPoint( pos, 50.0, 350.0, AttackSprite, AttackSprite, 0, 0, 2.0, 90.0, 0.0, { 155, 155, 155, 155 }, 2, FBEAM_ISACTIVE );
                TE_SendToAll();
                
                EmitSoundToAllAny( AttackSound, victim );
                
                War3_DealDamage( victim, Damage[skill_level], attacker, DMG_BULLET, "illidan_crit" );
                W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
            }
        }
        if( War3_GetRace( victim ) == thisRaceID )
        {
            new skill_return=War3_GetSkillLevel(victim,thisRaceID,SKILL_RETURN);
            if( skill_return>0 && IsPlayerAlive( attacker ) && !Hexed ( victim, false ) )
                
            if(!W3HasImmunity(attacker,Immunity_Skills))
                {
                    new damage_i=RoundToFloor(damage*ReturnDamage[skill_return]);
                    if(damage_i>0)
                    {
                        if(damage_i>30) damage_i=30;
                        War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL);
                        W3PrintSkillDmgConsole(attacker,victim,War3_GetWar3DamageDealt(), SKILL_RETURN );
                    }
                }
            new Float:pos[3];
                
            GetClientAbsOrigin( victim, pos );
                
            pos[2] += 40;
                
            TE_SetupBeamRingPoint( pos, 950.0, 190.0, VictimSprite, VictimSprite, 0, 0, 3.0,150.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
            TE_SendToAll();
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_RAGE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_RAGE, true ) )
            {    
                Rage(client);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

Action:Rage( client )
{
    new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_RAGE );
    new target;
    
    if( GetClientTeam( client ) == TEAM_T )
        target = War3_GetRandomPlayer( client, "#ct", true, true );
    if( GetClientTeam( client ) == TEAM_CT )
        target = War3_GetRandomPlayer( client,  "#t", true, true );
    
    if( target == 0 )
    {
        PrintHintText( client, "No Target Found" );
    }
    else
    {
        if (!W3HasImmunity(target,Immunity_Ultimates))
        {
            
            new Float:client_pos[3];
            new Float:pos[3] = { 0.0, 0.0, 900.0 };
            
            GetClientAbsOrigin( client, client_pos );
            GetClientAbsOrigin( target, oldPos[target] );
            
            new iWeapon = GetPlayerWeaponSlot(target, CS_SLOT_C4); 

            if (iWeapon != -1) 
            { 
                W3DropWeapon(target, iWeapon);
                PrintToChat(target, "You leave the bomb behind");
                
            }
            
            War3_SetBuff( target, fInvisibilitySkill, thisRaceID, 0.0  );
            War3_SetBuff( target,bDoNotInvisWeapon,thisRaceID,false);
            
            TeleportEntity( target, pos, NULL_VECTOR, NULL_VECTOR );
            
            CreateTimer( 0.1, Freeze, target );
            
            
            War3_DealDamage( target, UltDamage[ult_level], client, DMG_BULLET, "illidan_ult" );
            W3PrintSkillDmgHintConsole( target, client, War3_GetWar3DamageDealt(), ULT_RAGE );
            
            CreateTimer( 1.5, UnFreeze, target );
            
            War3_CooldownMGR( client, 30.0, thisRaceID, ULT_RAGE);
        }
        else
        {
            W3MsgEnemyHasImmunity(client);
        }
        
    }
}

public Action:Freeze( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
    }
}

public Action:UnFreeze( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        
        TeleportEntity( client, oldPos[client], NULL_VECTOR, NULL_VECTOR );
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
        War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
    }
}