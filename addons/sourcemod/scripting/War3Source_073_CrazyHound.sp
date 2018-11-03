/**
* File: War3Source_Crazy_Hound.sp
* Description: The Crazy Hound race for SourceCraft.
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
new Float:HoundGravity[9] = { 1.0, 0.90, 0.85, 0.8, 0.75, 0.70, 0.65, 0.60, 0.55 };
new Float:HoundSpeed[9] = { 1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45 };
new Float:DamageMultiplier[9] = { 0.0, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85 };
new Float:HoundInvis[9] = { 1.0, 0.8, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.50};
new MaxHP[9] = { -10, 0, 10, 20, 30, 40, 50, 60 ,70 };

new GlowSprite;

new SKILL_GRAV, SKILL_SPEED, SKILL_DMG, SKILL_HP, SKILL_INVIS;

public Plugin:myinfo = 
{
	name = "War3Source Race - Crazy Hound",
	author = "xDr.HaaaaaaaXx",
	description = "The Crazy Hound race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/purpleglow1.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/purpleglow1.vtf");
	GlowSprite = PrecacheModel( "materials/mora-wcs/sprites/purpleglow1.vmt" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==730)
    {
	thisRaceID = War3_CreateNewRace( "Crazy Hound", "crhound" );
	
	SKILL_GRAV = War3_AddRaceSkill( thisRaceID, "Strong Legs", "Low Gravity", false, 8 );
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Four Legs", "More Speed", false, 8 );
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Claws of the Hound", "More Knife damage", false, 8 );
	SKILL_HP = War3_AddRaceSkill( thisRaceID, "Additional Blood", "More Health", false, 8 );
	SKILL_INVIS = War3_AddRaceSkill( thisRaceID, "Skills of the Chameleon", "Get a little Invis", false, 8 );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, HoundGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_GRAV )] );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, HoundSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,MaxHP[War3_GetSkillLevel( client, thisRaceID, SKILL_HP )]);	
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, HoundInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
	}
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife" );
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
			if( !Hexed( attacker, false ) && skill_level > 0 && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_level] ), attacker, DMG_BULLET, "crazy_hound_claws" );
				
				new Float:pos[3];
				
				GetClientAbsOrigin( victim, pos );
				
				pos[2] += 50;
				
				TE_SetupGlowSprite( pos, GlowSprite, 2.0, 4.0, 255 );
				TE_SendToAll();

				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}