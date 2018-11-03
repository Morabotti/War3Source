/**
* File: War3Source_Panorama.sp
* Description: The Panorama race for SourceCraft.
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
new thisRaceID, SKILL_WALL, SKILL_DRUG, SKILL_REMATCH, ULT_ZOOM;

// Chance/Data Arrays
new Float:LevitationGravity[9] = {1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.60, 0.50};
new Float:RematchChance[9] = { 0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.42,};
new Float:DrugChance[9] = { 0.0, 0.075, 0.10, 0.15, 0.18, 0.23, 0.25, 0.27, 0.33 };
new Float:RematchDelay[9] = { 0.0, 2.0, 3.0, 4.0, 5.0, 5.0, 5.0, 5.0, 5.0 };
new Zoom[9] = { 0, 50, 45, 40, 35, 30, 25, 20, 15};
new Float:AttackerPos[64][3];
new Float:ClientPos[64][3];
new bool:Zoomed[64];

// Sounds
new String:spawn[] = "*mora-wcs/weapons/physcannon/superphys_launch2.mp3";
new String:spawn_FullPath[] = "sound/mora-wcs/weapons/physcannon/superphys_launch2.mp3";
new String:death[] = "*mora-wcs/weapons/physcannon/physcannon_drop.mp3";
new String:death_FullPath[] = "sound/mora-wcs/weapons/physcannon/physcannon_drop.mp3";
new String:spawn1[] = "*mora-wcs/ambient/cave_hit1.mp3";
new String:spawn1_FullPath[] = "sound/mora-wcs/ambient/cave_hit1.mp3";
new String:zoom[] = "*mora-wcs/weapons/zoom.mp3";
new String:zoom_FullPath[] = "sound/mora-wcs/weapons/zoom.mp3";
new String:on[] = "items/nvg_on.wav";
new String:off[] = "items/nvg_off.wav";
new String:attack[] = "*mora-wcs/ambient/wind_snippet2.mp3";
new String:attack_FullPath[] = "sound/mora-wcs/ambient/wind_snippet2.mp3";
new String:GlowSprite_FullPath[] = "materials/mora-wcs/sprites/blueglow2.vmt";
new String:GlowSpriteVTF_FullPath[] = "materials/mora-wcs/sprites/blueglow2.vtf";

// Other
new FOV;
new HaloSprite_030, XBeamSprite_030, GlowSprite_030;

public Plugin:myinfo =
{
	name = "Panorama",
	author = "xDr.HaaaaaaaXx -ZERO <ibis>",
	description = "Panorama race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	FOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
	HookEvent( "player_death", PlayerDeathEvent );
}

public OnMapStart()
{
	
	AddFileToDownloadsTable(GlowSprite_FullPath);
	AddFileToDownloadsTable(GlowSpriteVTF_FullPath);
	AddFileToDownloadsTable(spawn_FullPath);
	AddFileToDownloadsTable(spawn1_FullPath);
	AddFileToDownloadsTable(death_FullPath);
	AddFileToDownloadsTable(attack_FullPath);
	AddFileToDownloadsTable(zoom_FullPath);
	XBeamSprite_030 = War3_PrecacheBeamSprite();
	HaloSprite_030 = War3_PrecacheHaloSprite();
	PrecacheSoundAny( spawn );
	PrecacheSoundAny( death );
	PrecacheSoundAny( spawn1 );
	PrecacheSoundAny( zoom );
	War3_PrecacheSound( on ); 	// Didn't find orginal sound files so precache old way
	War3_PrecacheSound( off );	// same problem
	PrecacheSoundAny( attack );
	GlowSprite_030 = PrecacheModel( "materials/mora-wcs/sprites/blueglow2.vmt" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==460){
	thisRaceID = War3_CreateNewRace( "Panorama", "panorama" );

	SKILL_WALL = War3_AddRaceSkill( thisRaceID, "Low Gravity", "Jump higher", false, 8 );
	SKILL_DRUG = War3_AddRaceSkill( thisRaceID, "Flip View", "Flip the enemies View up side down", false, 8 );
	SKILL_REMATCH = War3_AddRaceSkill( thisRaceID, "Rematch", "Go back in time and Rematch your Enemy", false, 8 );
	ULT_ZOOM = War3_AddRaceSkill( thisRaceID, "Zoom", "Use a Scope on any weapon", true, 8 );

	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_AddSkillBuff(thisRaceID, SKILL_WALL, fLowGravitySkill, LevitationGravity);
	}
}

public OnRaceChanged( client,oldrace , newrace )
{
	if( newrace != thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
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
		decl Float:spawn_pos[3];
		GetClientAbsOrigin(client,spawn_pos);
		for (new i=0;i < 50;i=i+10)
		{
			TE_SetupBeamRingPoint(spawn_pos, 55.0, 60.0, XBeamSprite_030, HaloSprite_030, 2, 1, 3.0, 10.0, 2.0, {255,255,255,255}, 2, 0);
			TE_SendToAll(0.0);
			spawn_pos[2] = spawn_pos[2] + i;
		}

		InitPassiveSkills( client );
		EmitSoundToAllAny( spawn1, client );
	}
}

public OnWar3EventPostHurt( victim, attacker, Float:damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DRUG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DrugChance[skill_level] )
			{
				new Float:pos[3];
				GetClientAbsOrigin( victim, pos );
				TE_SetupGlowSprite( pos, GlowSprite_030, 3.0, 0.5, 255 );
				TE_SendToAll();
				Drug( victim, 1.0 );
				EmitSoundToAllAny( attack, attacker );
				EmitSoundToAllAny( attack, victim );
			}
		}
	}
}

Action:Drug( client, Float:duration )
{
	if( IsPlayerAlive( client ) )
	{
		new Float:pos[3];
		new Float:angs[3];
		GetClientAbsOrigin( client, pos );
		GetClientEyeAngles( client, angs );
		angs[2] = 180.0;
		TeleportEntity( client, pos, angs, NULL_VECTOR );
		SetEntData( client, FOV, 500 );
		CreateTimer( duration, StopDrug, client );
	}
}

public Action:StopDrug( Handle:timer, any:client )
{
	new Float:pos[3];
	new Float:angs[3];
	GetClientAbsOrigin( client, pos );
	GetClientEyeAngles( client, angs );
	angs[2] = 0.0;
	TeleportEntity( client, pos, angs, NULL_VECTOR );
	SetEntData( client, FOV, 0 );
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_ZOOM );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_ZOOM, true ) )
			{
				ToggleZoom( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock ToggleZoom( client )
{
	if( Zoomed[client] )
	{
		StopZoom( client );
	}
	else
	{
		StartZoom( client );
	}
	EmitSoundToAllAny( zoom, client );
}

stock StopZoom( client )
{
	if( Zoomed[client] )
	{
		SetEntData( client, FOV, 0 );
		EmitSoundToAll( off, client );
		Zoomed[client] = false;
	}
}

stock StartZoom( client )
{
	if ( !Zoomed[client] )
	{
		new zoom_level = War3_GetSkillLevel( client, thisRaceID, ULT_ZOOM );
		SetEntData( client, FOV, Zoom[zoom_level] );
		EmitSoundToAll( on, client );
		Zoomed[client] = true;
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	if( War3_GetRace( client ) == thisRaceID && attacker != client && attacker != 0 )
	{
		new skill_rematch = War3_GetSkillLevel( client, thisRaceID, SKILL_REMATCH );
		if( skill_rematch > 0 && GetRandomFloat( 0.0, 1.0 ) <= RematchChance[skill_rematch] )
		{
			GetClientAbsOrigin( client, ClientPos[client] );
			GetClientAbsOrigin( attacker, AttackerPos[attacker] );

			CreateTimer( RematchDelay[skill_rematch], SpawnClient, client );
			CreateTimer( RematchDelay[skill_rematch], SpawnAttacker, attacker );

			PrintToChat( client, ": In %f seconds you will re live your last Moment", RematchDelay[skill_rematch] );
			PrintToChat( attacker, ": In %f seconds you go back in time to this very moment", RematchDelay[skill_rematch] );

			EmitSoundToAllAny( death, client );
			EmitSoundToAllAny( death, attacker );
		}
	}
}

public Action:SpawnClient( Handle:timer, any:client )
{
	if( IsPlayerAlive( client ) )
	{
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		TeleportEntity( client, ClientPos[client], NULL_VECTOR, NULL_VECTOR );
		EmitSoundToAllAny( spawn, client );
	}
	else
	{
		War3_SpawnPlayer( client );
		CreateTimer( 0.2, TeleportClient, client );
	}
}

public Action:TeleportClient( Handle:timer, any:client )
{
	TeleportEntity( client, ClientPos[client], NULL_VECTOR, NULL_VECTOR );
	EmitSoundToAllAny( spawn, client );
}

public Action:SpawnAttacker( Handle:timer, any:attacker )
{
	if( IsPlayerAlive( attacker ) )
	{
		if( War3_GetMaxHP( attacker ) > GetClientHealth( attacker ) )
		{
			War3_HealToMaxHP( attacker, ( War3_GetMaxHP( attacker ) - GetClientHealth( attacker ) ) );
		}
		TeleportEntity( attacker, AttackerPos[attacker], NULL_VECTOR, NULL_VECTOR );
		EmitSoundToAllAny( spawn, attacker );
	}
	else
	{
		War3_SpawnPlayer( attacker );
		CreateTimer( 0.2, TeleportAttacker, attacker );
	}
}

public Action:TeleportAttacker( Handle:timer, any:attacker )
{
	TeleportEntity( attacker, AttackerPos[attacker], NULL_VECTOR, NULL_VECTOR );
	EmitSoundToAllAny( spawn, attacker );
}
