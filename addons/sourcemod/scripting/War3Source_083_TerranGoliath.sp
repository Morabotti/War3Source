/**
* File: War3Source_Terran_Goliath.sp
* Description: The Terran Goliath race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID;
// Chance/Data Arrays
new Float:AbilityRadius[9] = { 0.0, 200.0, 220.0, 240.0, 260.0, 280.0, 300.0, 320.0, 350.0 };
new Float:DamageMultiplier[9] = { 0.0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5 };
new Float:GoliathSpeed[9] = { 1.0, 1.20, 1.23, 1.26, 1.29, 1.32, 1.35, 1.38, 1.41 };
// new Float:UltDelay[6] = { 0.0, 35.0, 33.0, 31.0, 27.0, 25.0 };
// new Float:UltDuration[6] = { 0.0, 1.0, 1.5, 2.0, 2.5, 3.0 };
// new String:ultimateSound[] = "war3source/divineshield.wav";

new UltHealth[9] = {0, 10, 17, 24, 31, 38, 45, 52, 60};
new AbilityHealth[9] = { 0, 1, 2, 3, 4, 5, 6, 7 ,8 };
new HaloSprite, BeamSprite, HealSprite;
new bool:bRegenActived[64];
// new bool:bGodActived[64];

new SKILL_DMG, SKILL_SPEED, SKILL_REGEN, ULT_GOD;

public Plugin:myinfo = 
{
	name = "War3Source Race - Terran Goliath",
	author = "xDr.HaaaaaaaXx",
	description = "Terran Goliath race for War3Source.",
	version = "1.0.1",
	url = ""
};

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/effects/hydraspinalcord.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/hydraspinalcord.vtf");
	
	HaloSprite = PrecacheModel( "materials/mora-wcs/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/mora-wcs/sprites/lgtning.vmt" );
	HealSprite = PrecacheModel( "materials/mora-wcs/effects/hydraspinalcord.vmt" );
// 	War3_PrecacheSound( ultimateSound );
}

public OnPluginStart()
{
	CreateTimer( 1.0, CalcHexHealWaves, _, TIMER_REPEAT );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==830)
    {
	thisRaceID = War3_CreateNewRace( "Terran Goliath", "terrgoliath" );
	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Charon Boosters", "You can do more dmg whit some boosters.", false, 8 );	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Walker Speed", "This will upgrade your speed.", false, 8 );	
	SKILL_REGEN = War3_AddRaceSkill( thisRaceID, "Repair/Medic", "You can repair your self and heal near by teammates.", false, 8 );
	ULT_GOD = War3_AddRaceSkill( thisRaceID, "Walker Plating", "Upgrade your plating for extra health (passive)", true, 8 );
	
// 	W3SkillCooldownOnSpawn( thisRaceID, ULT_GOD, 5.0 );
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_REGEN, 5.0 );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )	
{
	if( War3_GetRace( client ) == thisRaceID )
	{	
		War3_SetBuff( client, fMaxSpeed, thisRaceID, GoliathSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
		
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
			new hp_level = War3_GetSkillLevel( client, thisRaceID, ULT_GOD );
			if( hp_level > 0 )
			{
				War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,UltHealth[hp_level]);	
				
			}
		}
	}
	else
	{
		W3ResetAllBuffRace( client, thisRaceID );
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
		if(ValidPlayer(client,true))
		{
			InitPassiveSkills( client );	
			new hp_level = War3_GetSkillLevel( client, thisRaceID, ULT_GOD );
			if( hp_level > 0 )
			{
				War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,UltHealth[hp_level]);	
				
			}
		}
		
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	bRegenActived[victim] = false;
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.30 && !W3HasImmunity( victim, Immunity_Skills  ) )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "weapon_knife" ) )
				{
					new Float:start_pos[3];
					new Float:target_pos[3];
				
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
				
					start_pos[2] += 40;
					target_pos[2] += 40;
				
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "goliath_crit" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					W3FlashScreen( victim, RGBA_COLOR_RED );
				}
			}
		}
	}
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, SKILL_REGEN );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_REGEN, true ) && !bRegenActived[client] )
			{
				bRegenActived[client] = true;
				
				CreateTimer( 15.0, StopRegen, client );
				
				War3_CooldownMGR( client, 25.0, thisRaceID, SKILL_REGEN, _, _ );
				
				W3SetPlayerColor( client, thisRaceID, 100, 255, 100, _, GLOW_SKILL );
			}
		}
	}
}

public Action:StopRegen( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		bRegenActived[client] = false;
		
		W3ResetPlayerColor( client, thisRaceID );
	}
}

public Action:CalcHexHealWaves( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID && bRegenActived[i] )
				{
					HealWave( i );
				}
			}
		}
	}
}

public HealWave( client )
{
	new skill = War3_GetSkillLevel( client, thisRaceID, SKILL_REGEN );
	if( skill > 0 && !Hexed( client, false ) )
	{
		new Float:dist = AbilityRadius[skill];
		new HealerTeam = GetClientTeam( client );
		new Float:HealerPos[3];
		new Float:VecPos[3];
		
		GetClientAbsOrigin( client, HealerPos );
		
		HealerPos[2] += 40.0;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) == HealerTeam )
			{
				GetClientAbsOrigin( i, VecPos );
				VecPos[2] += 40.0;
				
				if( GetVectorDistance( HealerPos, VecPos ) <= dist && GetClientHealth( i ) != War3_GetMaxHP( i ) )
				{
					War3_HealToMaxHP( i, AbilityHealth[skill] );
					
					TE_SetupBeamPoints( HealerPos, VecPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					W3FlashScreen( i, RGBA_COLOR_GREEN );
				}
			}
		}
	}
}