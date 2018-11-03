/**
* File: War3Source_LuckyStrike.sp
* Description: The Lucky*Strike race for SourceCraft.
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
new Float:FreezeChance[9] = { 0.0, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24 };
new Float:DamageMultiplier[9] = { 0.0, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24 };
new Float:EvadeChance[9] = { 0.0, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24 };
new Float:AntiultChanse[9] = { 0.0, 0.35, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75 };
new StealMoney[9] = { 0, 40, 80, 120, 160, 200, 240, 280, 320};
new m_iAccount;
new Beam;
new Beam2;
new Beam3;
new SKILL_DMG, SKILL_EVADE, SKILL_STEAL, SKILL_ANTIULT, SKILL_FREEZE;

public Plugin:myinfo = 
{
	name = "War3Source Race - Lucky*Strike++[RF-SFX]",
	author = "xDr.HaaaaaaaXx & Revan",
	description = "The Lucky*Strike race for War3Source.[special sfx & balanced version]",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	m_iAccount = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==540){
	thisRaceID = War3_CreateNewRace( "Lucky Strike", "luckstruck" );
	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Lucky Strike", "Chance to deal extra damage on successfully attacks", false, 8 );	
	SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Wild Card", "Chance to avoid damage", false, 8 );	
	SKILL_STEAL = War3_AddRaceSkill( thisRaceID, "Strike Lucky", "Strike enemy and get Cash", false, 8 );
	SKILL_ANTIULT = War3_AddRaceSkill( thisRaceID, "Joker", "Chance to disables enemy ultimates", false, 8 );
	SKILL_FREEZE = War3_AddRaceSkill( thisRaceID, "Freeze", "You have a chance to freeze your target on attack", false, 8 );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ANTIULT );
	if( War3_GetRace( client ) == thisRaceID && GetRandomFloat( 0.0, 1.0 ) <= AntiultChanse[skill_level] )
	{
		War3_SetBuff( client, bImmunityUltimates, thisRaceID, true );
	}
}

public OnMapStart() {
	AddFileToDownloadsTable("materials/mora-wcs/effects/blueblacklargebeam.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/blueblacklargebeam.vtf");
	
	Beam=PrecacheModel("materials/mora-wcs/effects/blueblacklargebeam.vmt");
	Beam2=PrecacheModel("materials/mora-wcs/sprites/redglow3.vmt");
	Beam3=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
	else
	{
		War3_SetBuff( client, bImmunityUltimates, thisRaceID, false );
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
		decl Float:spawn_pos[3];
		GetClientAbsOrigin(client, spawn_pos);
		
		spawn_pos[2] += 20;
		TE_SetupBeamRingPoint( spawn_pos,74.0,75.0,Beam3,Beam3,0,15,5.0,10.0,3.0,{129,129,255,255},1,0);
		TE_SendToAll();
		
		spawn_pos[2] += 35;
		TE_SetupBeamRingPoint(spawn_pos,8.0,150.0,Beam3,Beam3,1,1,2.3,6.0,2.0,{255,255,20,180},0,0);
		TE_SendToAll();
	}
}

public OnWar3EventPostHurt( victim, attacker, Float:damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && skill_dmg > 0 )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "crit" );
				//DealDamageWrapper(victim,attacker,RoundToFloor(damage*DamageMultiplier[skill_dmg]),"crit");
				new Float:iVec[3];
				GetClientEyePosition(attacker,iVec);
				new Float:iVec2[3];
				GetClientEyePosition(victim,iVec2);
				iVec[2]+=45.0;
				TE_SetupBeamPoints(iVec,iVec2,Beam,Beam,0,41,1.6,6.0,15.0,0,4.5,{255,255,255,200},45);
				TE_SendToAll();
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.25 ) <= FreezeChance[skill_freeze] && skill_freeze > 0 )
			{
				new Float:duration = GetRandomFloat(0.15,0.35);
				War3_SetBuff( victim, bStunned, thisRaceID, true );
				CreateTimer( duration, StopFreeze, victim );
				W3FlashScreen( victim, RGBA_COLOR_BLUE );
				PrintHintText( attacker, "Freezed enemy for %f seconds!", duration );
				new Float:iVec[3];
				GetClientEyePosition(victim,iVec);
				iVec[2]+20.0;
				TE_SetupBeamRingPoint( iVec,74.0,75.0,Beam3,Beam3,0,15,5.0,10.0,3.0,{129,129,255,255},1,0);
				TE_SendToAll();
				TE_SetupBeamFollow(victim,Beam,0,0.65,10.0,20.0,20,{200,250,255,255});
				TE_SendToAll();
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	War3_SetBuff( client, bStunned, thisRaceID, false );
}

public OnW3TakeDmgBulletPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && victim != attacker && IsPlayerAlive( victim ) && IsPlayerAlive( attacker ) )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );

		new race_victim = War3_GetRace( victim );
		new race_attack = War3_GetRace( attacker );

		if( vteam != ateam )
		{
			new skill_steal = War3_GetSkillLevel( attacker, thisRaceID, SKILL_STEAL );
			if( race_attack == thisRaceID && skill_steal > 0 && !Hexed( attacker, false ) && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
				{
					new stolen = StealMoney[skill_steal];

					new dec_money = GetMoney( victim ) - stolen;
					new inc_money = GetMoney( attacker ) + stolen;

					if( dec_money < 0 ) dec_money = 0;
					if( inc_money > 16000 ) inc_money = 16000;

					SetMoney( victim, dec_money );
					SetMoney( attacker, inc_money );

					W3MsgStoleMoney( victim, attacker, StealMoney[skill_steal] );
					W3FlashScreen( attacker, RGBA_COLOR_BLUE );

					new Float:iVec[3];
					GetClientEyePosition(attacker,iVec);
					iVec[2]+20.0;
					TE_SetupBeamRingPoint(iVec,8.0,150.0,Beam3,Beam3,1,1,2.3,6.0,2.0,{255,255,20,180},0,0);
					TE_SendToAll();
				}
			}
			
			new skill_evade = War3_GetSkillLevel( victim, thisRaceID, SKILL_EVADE );
			if( race_victim == thisRaceID && skill_evade > 0 && !Hexed( victim, false ) && !W3HasImmunity( victim, Immunity_Skills ) ) 
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= EvadeChance[skill_evade] )
				{
					W3FlashScreen( victim, RGBA_COLOR_BLUE );
					War3_DamageModPercent( 0.0 );
					W3MsgEvaded( victim, attacker );
					new Float:spos[3];
					new Float:epos[3];
					GetClientAbsOrigin(victim,epos);
					GetClientAbsOrigin(attacker,spos);
					epos[2]+=40.0;
					spos[2]+=120.0;
					TE_SetupBeamPoints(spos, epos, Beam2, Beam2, 1, 5, 0.35, 1.0, 30.0, 2, 20.0, {255,120,120,190}, 10);
					TE_SendToAll();
				}
			}
		}
	}
}

stock GetMoney( player )
{
	return GetEntData( player, m_iAccount );
}

stock SetMoney( player, money )
{
	SetEntData( player, m_iAccount, money );
}