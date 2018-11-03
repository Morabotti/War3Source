/**
* File: War3Source_Aura_Master.sp
* Description: The Aura Master race for SourceCraft.
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
new Float:AuraSpeed[9] = { 1.0, 1.15, 1.18, 1.21, 1.24, 1.27, 1.30, 1.33, 1.36 };
new Float:AuraGravity[9] = { 1.0, 0.9, 0.8, 0.7, 0.6, 0.55, 0.50, 0.45, 0.40 };
new Float:AuraPushChance[9] = { 0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32 };
new m_vecBaseVelocity;
new HaloSprite, BeamSprite, LgtningSprite;

new SKILL_SPEED, SKILL_LOWGRAV, SKILL_PUSH, SKILL_LEECH;

public Plugin:myinfo = 
{
	name = "War3Source Race - Aura Master",
	author = "xDr.HaaaaaaaXx",
	description = "The Aura Master race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	BeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
	LgtningSprite = PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==340)
	{
		thisRaceID = War3_CreateNewRace( "Aura Master", "auramaster" );
		SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Unholy Aura", "Speed", false,8 );	
		SKILL_LOWGRAV = War3_AddRaceSkill( thisRaceID, "Gravity Aura", "Allows you jump higher.", false,8 );	
		SKILL_PUSH = War3_AddRaceSkill( thisRaceID, "Exellence Aura", "Push your enemy", false,8 );
		SKILL_LEECH = War3_AddRaceSkill( thisRaceID, "Ancient Aura", "Leeched enemy healt.", false,8 );
		War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, AuraSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, AuraGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV )] );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
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
		new Float:SpawnPos[3];
		GetClientAbsOrigin(client, SpawnPos);
		SpawnPos[2] += 20;
		new skill1 = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
		if(skill1 > 0)
		{
			TE_SetupBeamRingPoint(SpawnPos, 70.0, 75.0, BeamSprite, HaloSprite, 0, 35, 4.0, 7.0, 0.0, {0, 153, 51, 255}, 35, 0);
			TE_SendToAll();
		}
		SpawnPos[2] += 20;
		new skill2 = War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV );
		if(skill2 > 0)
		{
			TE_SetupBeamRingPoint(SpawnPos, 70.0, 75.0, BeamSprite, HaloSprite, 0, 35, 4.0, 7.0, 0.0, {102 ,  255 ,  102, 255}, 35, 0);
			TE_SendToAll();
		}
		SpawnPos[2] += 20;
		new skill3 = War3_GetSkillLevel( client, thisRaceID, SKILL_PUSH );
		if(skill3 > 0)
		{
			TE_SetupBeamRingPoint(SpawnPos, 70.0, 75.0, BeamSprite, HaloSprite, 0, 35, 4.0, 7.0, 0.0, {153, 255, 51, 255}, 35, 0);
			TE_SendToAll();
		}
		SpawnPos[2] += 20;
		new skill4 = War3_GetSkillLevel( client, thisRaceID, SKILL_LEECH );
		if(skill4 > 0)
		{
			TE_SetupBeamRingPoint(SpawnPos, 70.0, 75.0, BeamSprite, HaloSprite, 0, 35, 4.0, 7.0, 0.0, {204, 102, 0, 255}, 35, 0);
			TE_SendToAll();
		}
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt( victim, attacker, Float:damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_push = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PUSH );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= AuraPushChance[skill_push] && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				new Float:velocity[3];
				
				velocity[2] += 600.0;
				
				SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
				
				W3FlashScreen( victim, RGBA_COLOR_SKYBLUE );
			}

			new skill_leech = War3_GetSkillLevel( attacker, thisRaceID, SKILL_LEECH );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.45 && skill_leech > 0 && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				start_pos[2] += 10;
				GetClientAbsOrigin( victim, target_pos );
				target_pos[2] += 10;
				
				TE_SetupBeamPoints( start_pos, target_pos, LgtningSprite, 0, 0, 0, 0.5, 40.0, 40.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
				TE_SendToAll();
				
				War3_HealToBuffHP( attacker, RoundToFloor(damage / 2 ));
				W3FlashScreen(attacker, { 204, 0, 0, 35 } );
				
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}