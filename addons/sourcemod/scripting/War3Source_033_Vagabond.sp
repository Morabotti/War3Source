/**
* File: War3Source_Vagabond.sp
* Description: The Vagabond race for SourceCraft.
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
new thisRaceID, SKILL_SPEED, SKILL_SCOUT, SKILL_LOWGRAV, ULT_INVIS_TELE;

// Chance/Data Arrays
new Float:VagabondGravity[9] =  { 1.0, 0.95, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.30 };
new Float:VagabondSpeed[9] = { 1.0, 1.04, 1.08, 1.12, 1.16, 1.20, 1.24, 1.28, 1.32 };
new Float:DamageChanse[9] = { 0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40};
new DamageScout[9] =  { 0 , 15, 20, 25, 30, 35, 40, 45, 50 };
new Float:PushForce[9] = { 0.0, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8 };
new Float:UltDelay[9] = { 0.0, 8.0, 7.5, 7.0, 6.5, 6.0, 5.5, 5.0, 4.0 };
new bool:bIsInvisible[MAXPLAYERS];

// Sounds
new String:UltOutstr[] = "*mora-wcs/weapons/physcannon/physcannon_claws_close.mp3";
new String:UltInstr[] = "*mora-wcs/weapons/physcannon/physcannon_claws_open.mp3";
new String:spawnsound[] = "*mora-wcs/ambient/cave_hit2.mp3";

new String:UltOutstr_FullPath[] = "sound/mora-wcs/weapons/physcannon/physcannon_claws_close.mp3";
new String:UltInstr_FullPath[] = "sound/mora-wcs/weapons/physcannon/physcannon_claws_open.mp3";
new String:spawnsound_FullPath[] = "sound/mora-wcs/ambient/cave_hit2.mp3";

// Other
new HaloSprite, BeamSprite, SteamSprite;
new m_vecBaseVelocity;

public Plugin:myinfo = 
{
	name = "War3Source Race - Vagabond",
	author = "xDr.HaaaaaaaXx",
	description = "The Vagabond race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/steam1.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/steam1-.vtf");
	
	HaloSprite = PrecacheModel( "materials/mora-wcs/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/mora-wcs/sprites/laser.vmt" );
	SteamSprite = PrecacheModel( "materials/mora-wcs/sprites/steam1.vmt" );
	
	AddFileToDownloadsTable(UltOutstr_FullPath);
	AddFileToDownloadsTable(UltInstr_FullPath);
	AddFileToDownloadsTable(spawnsound_FullPath);
	
	PrecacheSoundAny( UltInstr );
	PrecacheSoundAny( UltOutstr );
	PrecacheSoundAny( spawnsound );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==330){
	thisRaceID = War3_CreateNewRace( "Vagabond", "vagabond" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Adrinaline", "Speed", false, 8 );	
	SKILL_SCOUT = War3_AddRaceSkill( thisRaceID, "Scout", "Extra Damage", false, 8 );	
	SKILL_LOWGRAV = War3_AddRaceSkill( thisRaceID, "Levitation", "Levitation", false, 8 );
	ULT_INVIS_TELE = War3_AddRaceSkill( thisRaceID, "Complete Invisibility", "Teleport and Become Completly invisible when not moving(can't move)", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_INVIS_TELE, 8.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, VagabondSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, VagabondGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV )] );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_ssg08" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_ssg08" );
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
	StopInvis( client );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_ssg08" );
		InitPassiveSkills( client );
		EmitSoundToAllAny( spawnsound, client );
		new Float:fPos[3];
		GetClientAbsOrigin(client, fPos);
		for (new Float:i = 0.0; i < 2.1; i = i + 0.15)
		{
			TE_SetupGlowSprite( fPos, SteamSprite, 1.0, 2.5, 130 );
			TE_SendToAll(i);
			fPos[2] += 20;
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
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SCOUT );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChanse[skill_level] )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_ssg08" ) )
				{
					new Float:start_pos[3];
					new Float:target_pos[3];
					
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
					
					target_pos[2] += 40;
					
					// 1
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;
					
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, { 255, 0, 0, 255}, 40 );
					TE_SendToAll();
					
					// 2
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {0, 0, 255, 255}, 40 );
					TE_SendToAll();
					
					// 3
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {0, 255, 0, 255}, 40 );
					TE_SendToAll();
					
					// 4
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {255, 255, 0, 255}, 40 );
					TE_SendToAll();
					
					// 5
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {255, 0, 255, 255}, 40 );
					TE_SendToAll();
					
					// 6
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {255, 128, 0, 255}, 40 );
					TE_SendToAll();
					
					// 7
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {0, 255, 255, 255}, 40 );
					TE_SendToAll();
					
					// 8
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {255, 0, 191, 255}, 40 );
					TE_SendToAll();
					
					// 9
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[2] += 40;
					target_pos[2] += 5;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 6.0, 10.0, 10.0, 0, 0.0, {128, 0, 255, 255}, 40 );
					TE_SendToAll();
					
					if( !W3HasImmunity( victim, Immunity_Skills ) )
					{
						War3_DealDamage( victim, DamageScout[skill_level], attacker, DMG_BULLET, "Vagabond scout");
						W3FlashScreen( victim, RGBA_COLOR_RED );

					}
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	new userid = GetClientUserId( client );
	if( race == thisRaceID && pressed && userid > 1 && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_INVIS_TELE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_INVIS_TELE, true ) )
			{
				if( !bIsInvisible[client] )
				{
					ToggleInvisibility( client );
					TeleportPlayer( client );
					War3_CooldownMGR( client, 0.5, thisRaceID, ULT_INVIS_TELE, _, false );
				}
				else
				{
					ToggleInvisibility( client );
					War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_INVIS_TELE, _, false );
				}
				
				new Float:pos[3];
				
				GetClientAbsOrigin( client, pos );
				
				pos[2] += 50;
				
				TE_SetupGlowSprite( pos, SteamSprite, 1.0, 2.5, 130 );
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock StopInvis( client )
{
	if( bIsInvisible[client] )
	{
		bIsInvisible[client] = false;
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		EmitSoundToAllAny( UltOutstr, client );
	}
}

stock StartInvis( client )
{
	if ( !bIsInvisible[client] )
	{
		bIsInvisible[client] = true;
		CreateTimer( 1.0, StartStop, client );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
		EmitSoundToAllAny( UltInstr, client );
	}
}

public Action:StartStop( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
	}
}

stock ToggleInvisibility( client )
{
	if( bIsInvisible[client] )
	{
		StopInvis( client );
	}
	else
	{
		StartInvis( client );
	}
}

stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS_TELE );
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		War3_GetAimEndPoint( client, endpos );
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
	}
}