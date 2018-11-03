/**
* File: War3Source_Spider_Man.sp
* Description: The Spider Man race for SourceCraft.
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
new Float:WebFreezeChance[9] = { 0.0, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26 };
new Float:EvadeChance[9] = { 0.0, 0.12, 0.13, 0.15, 0.16, 0.18, 0.19, 0.21, 0.22 };
new Float:JumpMultiplier[9] = { 1.0, 1.2, 1.23, 1.26, 1.29, 1.32, 1.35, 1.38, 1.41 };
new Float:SpiderSpeed[9] = { 1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.24 };
new Float:PushForce[9] = { 0.0, 1.0, 1.10, 1.13, 1.16, 1.19, 1.22, 1.24, 1.26 };

// Sounds
new String:ult_sound[] = "*mora-wcs/war3source/morabotti/spiderweb.mp3";
new String:ult_sound_FullPath[] = "sound/mora-wcs/war3source/morabotti/spiderweb.mp3";

// Other
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new EvadeSprite, FreezeSprite1, FreezeSprite2;

new SKILL_EVADE, SKILL_LONGJUMP, SKILL_FREEZE, ULT_WEB;

public Plugin:myinfo = 
{
	name = "War3Source Race - Spider Man",
	author = "xDr.HaaaaaaaXx",
	description = "The Spider Man race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnMapStart()
{
	AddFileToDownloadsTable(ult_sound_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/sprites/yellowflare.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/yellowflare.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combineshield/comshieldwall.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combineshield/comshieldwall.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combineshield/comshieldwall2.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combineshield/comshieldwall_close.vtf");
	//War3_PrecacheSound( ult_sound );
	//PrecacheSound( ult_sound );
	PrecacheSoundAny(ult_sound);
	EvadeSprite = PrecacheModel( "materials/mora-wcs/sprites/yellowflare.vmt" );
	FreezeSprite1 = PrecacheModel( "materials/mora-wcs/effects/combineshield/comshieldwall.vmt" );
	FreezeSprite2 = PrecacheModel( "materials/mora-wcs/effects/combineshield/comshieldwall2.vmt" );
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
	m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
	HookEvent( "player_jump", PlayerJumpEvent );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==600)
    {
	thisRaceID = War3_CreateNewRace( "Spider Man", "spider" );
	
	SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Spider sense", "Chance of evading shots", false, 8 );
	SKILL_LONGJUMP = War3_AddRaceSkill( thisRaceID, "Agility", "Long jump and Speed.", false, 8 );	
	SKILL_FREEZE = War3_AddRaceSkill( thisRaceID, "Web-shooters", "Shoot enemy and entagle them in your web", false, 8 );
	ULT_WEB = War3_AddRaceSkill( thisRaceID, "Weblines", "Use your Weblines to travel", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_WEB, 8.0 );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, SpiderSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_LONGJUMP )] );
	}
}

public OnRaceChanged( client,oldrace,newrace )
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
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= WebFreezeChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
				CreateTimer( 1.0, StopFreeze, victim );
				
				new Float:startpos[3];
				new Float:endpos[3];
				
				GetClientAbsOrigin( attacker, startpos );
				GetClientAbsOrigin( victim, endpos );
				
				TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 1.0, 1.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
				TE_SendToAll();
				
				TE_SetupBeamRingPoint( endpos, 40.0, 50.0, FreezeSprite2, FreezeSprite2, 0, 0, 1.0, 40.0, 0.0, { 10, 10, 10, 255 }, 0, FBEAM_ISACTIVE );
				TE_SendToAll();
				
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
	}
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
		if( skill_long > 0 )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= JumpMultiplier[skill_long];
			velocity[1] *= JumpMultiplier[skill_long];
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		new race_victim = War3_GetRace( victim );
		if( vteam != ateam && race_victim == thisRaceID )
		{
			new skill_evade = War3_GetSkillLevel( victim, thisRaceID, SKILL_EVADE );
			if( skill_evade > 0 && !Hexed( victim, false ) && GetRandomFloat( 0.0, 1.0 ) <= EvadeChance[skill_evade] && !W3HasImmunity( attacker, Immunity_Skills ) ) 
			{
				War3_DealDamage( victim, 0, attacker, DMG_BULLET, "Evade" );
				
				new Float:startpos[3];
				new Float:endpos[3];
				
				GetClientAbsOrigin( attacker, startpos );
				GetClientAbsOrigin( victim, endpos );
				
				TE_SetupBeamPoints( startpos, endpos, EvadeSprite, EvadeSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
				TE_SendToAll();
				
				W3FlashScreen( victim, RGBA_COLOR_BLUE );
				
				W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Enemy Evaded", attacker);
				W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "You Evaded a Shot", victim);
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_WEB );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_WEB, true ) )
			{
				TeleportPlayer( client );
				EmitSoundToAllAny( ult_sound, client );
				//ClientCommand(client,"play *war3source/morabotti/spiderweb.mp3"); Ei kuulu muille eikä erroria
				
				War3_CooldownMGR( client, 0.1, thisRaceID, ULT_WEB, true, false );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_WEB );
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		War3_GetAimTraceMaxLen(client, endpos, 2500.0);
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		
		TE_SetupBeamPoints( startpos, endpos, FreezeSprite1, FreezeSprite1, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 14, 41, 255 }, 0 );
		TE_SendToAll();
		
		TE_SetupBeamRingPoint( endpos, 11.0, 9.0, FreezeSprite1, FreezeSprite1, 0, 0, 2.0, 13.0, 0.0, { 255, 100, 100, 255 }, 0, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}