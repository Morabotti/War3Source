/**
 * File: War3Source_Unholy_Entity.sp
 * Description: The Unholy Entity race for War3Source.
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
#include "W3SIncs/haaaxfunctions"
new thisRaceID;

//skill 1
new Float:EntSpeed[9] = { 1.0, 1.10, 1.13, 1.16, 1.19, 1.22, 1.25, 1.28, 1.32 };

//skill 2
new Float:BuryChance[9] = { 0.0, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24 };
new Float:BuryTime[9] =  { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };

//skill 3
new Float:AvangeChance[9] = { 0.0, 0.4, 0.45, 0.50, 0.55, 0.60, 0.65, 0.7, 0.75 };

//ultimate
new Float:UltDelay[9] = { 0.0, 50.0, 47.0, 44.0, 41.0, 38.0, 35.0, 32.0, 30.0 };

new SKILL_SPEED, SKILL_BURY, SKILL_AVENGE, ULT_TRADE;
new Float:Ult_ClientPos[64][3];
new Float:Ult_EnemyPos[64][3];
new Float:Client_Pos[64][3];
new Ult_BestTarget[64];
new BestTarget[64];

new String:Sound[] = { "*mora-wcs/war3source/morabotti/cave_hit5.mp3" };
new String:Sound_FullPath[] = { "sound/mora-wcs/war3source/morabotti/cave_hit5.mp3" };
new BeamSprite, HaloSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Unholy Entity",
	author = "xDr.HaaaaaaaXx",
	description = "The Unholy Entity race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_death", PlayerDeathEvent );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==530){
	thisRaceID = War3_CreateNewRace( "Unholy Entity", "unholyent" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Swift", "Run Fast", false, 8 );
	SKILL_BURY = War3_AddRaceSkill( thisRaceID, "Bury", "Bury your enemy Alive half way under ground", false, 8 );
	SKILL_AVENGE = War3_AddRaceSkill( thisRaceID, "Avenge", "Call apon a teammate to avenge your death", false, 8 );
	ULT_TRADE = War3_AddRaceSkill( thisRaceID,  "Possessor", "Trade places with a randome enemy", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_TRADE, 20.0, _);
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public OnMapStart()
{
	AddFileToDownloadsTable(Sound_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bluelight1.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bluelight1.vtf");
	
	BeamSprite = PrecacheModel( "materials/mora-wcs/sprites/bluelight1.vmt" );
	HaloSprite = PrecacheModel( "materials/mora-wcs/sprites/halo01.vmt" );
	PrecacheSoundAny( Sound );
}

public InitPassiveSkills( client )
{
	if( ValidPlayer( client, true ) )
	{
		if( War3_GetRace( client ) == thisRaceID )
		{
			War3_SetBuff( client, fMaxSpeed, thisRaceID, EntSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( ValidPlayer( client, true ) )
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
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	if( ValidPlayer( client, true ) )
	{
		InitPassiveSkills( client );
	}
}

public OnWar3EventSpawn( client )
{
	if( ValidPlayer( client, true ) )
	{
		new race = War3_GetRace( client );
		if( race == thisRaceID )
		{
			InitPassiveSkills(client);
			EmitSoundToAllAny( Sound, client );
			
			
			new Float:spawn_pos[3];
			GetClientAbsOrigin( client, spawn_pos );
			spawn_pos[2] += 20;
			TE_SetupBeamRingPoint(spawn_pos, 20.0, 300.0, BeamSprite, HaloSprite, 0, 1, 4.0, 10.0, 0.5, { 215, 11, 165, 255 }, 0, 0);
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
			new skill_bury = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BURY );
			if( !Hexed( attacker, false ) && skill_bury > 0 && GetRandomFloat( 0.0, 1.0 ) <= BuryChance[skill_bury] )
			{
				new Float:attacker_pos[3];
				new Float:victim_pos[3];

				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				victim_pos[2] -= 40;
				
				TeleportEntity( victim, victim_pos, NULL_VECTOR, NULL_VECTOR );

				victim_pos[2] += 40;
				
				CreateTimer(BuryTime[skill_bury],BuryBackUp, victim);

				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 165, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 70;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 70;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 40;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 50;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 50;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 140;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 170;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 170;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 1140;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 5;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 3;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 20;
				victim_pos[2] += 20;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 30;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 30;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
			}
		}
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( ValidPlayer( client, true ) )
	{
		if( War3_GetRace( client ) == thisRaceID )
		{
			new skill_avange = War3_GetSkillLevel( client, thisRaceID, SKILL_AVENGE );
			if( skill_avange > 0 && GetRandomFloat( 0.0, 1.0 ) <= AvangeChance[skill_avange] )
			{
				new Float:TeamMate_Pos[3];
				if( GetClientTeam( client ) == TEAM_T )
					BestTarget[client] = War3_GetRandomPlayer( client,"#ct", true, true );
				if( GetClientTeam( client ) == TEAM_CT )
					BestTarget[client] = War3_GetRandomPlayer( client,"#t", true, true );
				
				GetClientAbsOrigin( client, Client_Pos[client] );
				GetClientAbsOrigin( BestTarget[client], TeamMate_Pos );
				
				if( BestTarget[client] == 0 )
				{
					PrintHintText( client, "No Target Found" );
				}
				else
				{
					CreateTimer( 6.0, AvangeTeleport, client );
					
					new String:Name[64];
					GetClientName( BestTarget[client], Name, 64 );
					
					PrintToChat( client, "You call apon %s to Avenge your Death!", Name );
					PrintToChat( BestTarget[client], "A teammate has been slayed! You have been summuned to avenge his death!" );
					
					EmitSoundToAllAny( Sound, client );
					EmitSoundToAllAny( Sound, BestTarget[client] );
				}
			}
		}
	}
}

public Action:BuryBackUp(Handle:timer, any:client)
{
	new Float:victim_pos_under[3];
	GetClientAbsOrigin( client, victim_pos_under );
	victim_pos_under[2] += 45;
	TeleportEntity( client, victim_pos_under, NULL_VECTOR, NULL_VECTOR );
}

public Action:AvangeTeleport( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && ValidPlayer( BestTarget[client], true ))
	{
		TeleportEntity( BestTarget[client], Client_Pos[client], NULL_VECTOR, NULL_VECTOR );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( ValidPlayer( client, true ) && !Silenced(client) )
	{
		if( race == thisRaceID && pressed && IsPlayerAlive( client ) )
		{
			new ult_level = War3_GetSkillLevel( client, race, ULT_TRADE );
			if( ult_level > 0 )
			{
				if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TRADE, true ) )
				{
					Trade( client );
					War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_TRADE, _, false );
				}
			}
			else
			{
				W3MsgUltNotLeveled( client );
			}
		}
	}
}

stock Trade( client )
{
	if( GetClientTeam( client ) == TEAM_T )
		Ult_BestTarget[client] = War3_GetRandomPlayer( client,"#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		Ult_BestTarget[client] = War3_GetRandomPlayer( client,"#t", true, true );

	if( Ult_BestTarget[client] == 0 && W3HasImmunity(Ult_BestTarget[client], Immunity_Ultimates))
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		GetClientAbsOrigin( Ult_BestTarget[client], Ult_EnemyPos[client] );
		GetClientAbsOrigin( client, Ult_ClientPos[client] );
		
		new String:Name[64];
		GetClientName( Ult_BestTarget[client], Name, 64 );
	
		EmitSoundToAllAny( Sound, client );
		EmitSoundToAllAny( Sound, Ult_BestTarget[client] );
		
		PrintToChat( client, "You will trade places with %s in three seconds!", Name );
		
		CreateTimer( 3.0, TradeDelay, client );
		
		new Float:BeamPos[3];
		BeamPos[0] = Ult_ClientPos[client][0];
		BeamPos[1] = Ult_ClientPos[client][1];
		BeamPos[2] = Ult_ClientPos[client][2] + 20.0;
		
		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, BeamSprite, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();

		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, BeamSprite, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}

public Action:TradeDelay( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && Ult_BestTarget[client] )
	{
		TeleportEntity( Ult_BestTarget[client], Ult_ClientPos[client], NULL_VECTOR, NULL_VECTOR );
		TeleportEntity( client, Ult_EnemyPos[client], NULL_VECTOR, NULL_VECTOR );
	}
}