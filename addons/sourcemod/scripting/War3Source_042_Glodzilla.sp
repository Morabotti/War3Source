/*
* War3Source Race - Glodzilla
* 
* File: War3Source_Glodzilla.sp
* Description: The Glodzilla race for War3Source.
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Glodzilla",
	author = "M.A.C.A.B.R.A",
	description = "The Glodzilla race for War3Source. Especially for Masterczu³ek :D",
	version = "1.0.2",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_GLODNY, SKILL_NAJEDZONA, SKILL_GLODOMORRA, SKILL_OGON, ULT_CZEKOLADA;
new BeamSprite, HaloSprite;

// G³odny Potwór
new Float:GlodnySpeed[9]={1.0, 1.03, 1.06, 1.10, 1.13, 1.16, 1.20, 1.22, 1.25};

// Najedzona!
new NajedzonaHP[9] =  { 100, 115, 130, 145, 160, 175, 190, 205, 220 };

// G³odomorra
new Float:GlodomorraRange[9] =  { 0.0, 50.0, 70.0, 90.0, 110.0, 130.0, 150.0, 170.0, 200.0 };
new GlodomorraDamage[9] =  { 0, 1, 2, 2, 3, 3, 4, 4, 5 };
new GlodomorraMaxHP;

// Ogonowy Cios
new OgonDamage[9] = {0,5,8,11,14,17,20,23,25};
new Float:OgonCooldownTime = 20.0;
new Float:OgonRange[9] =  { 0.0, 50.0, 90.0, 130.0, 170.0, 210.0, 250.0, 290.0, 300.0  };

// Czekolaaaaaada
new CzekoladaDamage[9] =  { 0, 15, 19, 23, 27, 31, 35, 39, 43 };
new Float:CzekoladaCooldownTime = 25.0;
new Float:CzekoladaRange[9] =  {0.0, 80.0, 120.0, 160.0, 200.0, 240.0, 280.0, 320.0, 360.0};

// Soundy
new String:CzekoladaSnd_FullPath[]="sound/mora-wcs/war3source/glodzilla/czekolada.mp3";
new String:CzekoladaSnd[]="*mora-wcs/war3source/glodzilla/czekolada.mp3";
new String:OgonSnd_FullPath[]="sound/mora-wcs/war3source/glodzilla/ogon.mp3";
new String:OgonSnd[]="*mora-wcs/war3source/glodzilla/ogon.mp3";
new String:SpawnSnd_FullPath[]="sound/mora-wcs/war3source/glodzilla/spawn.mp3";
new String:SpawnSnd[]="*mora-wcs/war3source/glodzilla/spawn.mp3";
new String:DeadSnd_FullPath[]="sound/mora-wcs/war3source/glodzilla/dead.mp3";
new String:DeadSnd[]="*mora-wcs/war3source/glodzilla/dead.mp3";


/* *********************** OnWar3PluginReady *********************** */
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==420){
	thisRaceID = War3_CreateNewRace( "Glodzilla", "glodzilla" );
	
	SKILL_GLODNY = War3_AddRaceSkill( thisRaceID, "Glodny Potwor", "Glodzilla biega szybciej. (Movement speed increase)", false, 8 );
	SKILL_NAJEDZONA = War3_AddRaceSkill( thisRaceID, "Najedzona!", "Glodzilla jest silniejsza. (Health increase)", false, 8 );
	SKILL_GLODOMORRA = War3_AddRaceSkill( thisRaceID, "Glodomorra", "Glodzilla pozera wrogow znajdujacych siê blisko niej i staje siê silniejsza. (Deals DMG to enemies close)", false, 8 );
	SKILL_OGON = War3_AddRaceSkill( thisRaceID, "Ogonowy Cios", "Glodzilla wymachuje ogonem i rani wrogow. (+ability) (Deals DMG to enemies close)", false, 8 );
	ULT_CZEKOLADA = War3_AddRaceSkill( thisRaceID, "Czekolaaaaaada", "Topi przeciwnikow w fali czekolady.(+ultimate) (Deals DMG to enemies in front of him)", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_CZEKOLADA, 15.0, true );
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_OGON, 10.0, true);
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	BeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
	//Soundy
	AddFileToDownloadsTable(CzekoladaSnd_FullPath);
	AddFileToDownloadsTable(OgonSnd_FullPath);
	AddFileToDownloadsTable(SpawnSnd_FullPath);
	AddFileToDownloadsTable(DeadSnd_FullPath);
	
	PrecacheSoundAny(CzekoladaSnd);
	PrecacheSoundAny(OgonSnd);
	PrecacheSoundAny(SpawnSnd);
	PrecacheSoundAny(DeadSnd);
	
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{	
	CreateTimer( 1.0, CalcGlodomorra, _, TIMER_REPEAT );	
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
		GlodomorraMaxHP = 100;
		InitPassiveSkills(client);
		GivePlayerItem( client, "weapon_elite" );
		EmitSoundToAllAny(SpawnSnd,client);
	}
}

/* *********************** InitPassiveSkills *********************** */
public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_GLODNY);	
		if(skill_lvl > 0)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,GlodnySpeed[skill_lvl]);
		}
		
		new skill_lvl2 = War3_GetSkillLevel(client,thisRaceID,SKILL_NAJEDZONA);	
		if(skill_lvl2 > 0)
		{
			War3_SetMaxHP_INTERNAL(client,NajedzonaHP[skill_lvl2]);
			SetEntityHealth(client,NajedzonaHP[skill_lvl2]);
			War3_SetCSArmor(client,100);
			War3_SetCSArmorHasHelmet(client,true);
			GlodomorraMaxHP = NajedzonaHP[skill_lvl2];
		}
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetMaxHP_INTERNAL(client,100);
		War3_SetCSArmor(client,0);
		War3_SetCSArmorHasHelmet(client,false);
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife, weapon_elite" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_elite" );
			InitPassiveSkills( client );
		}
		EmitSoundToAllAny(SpawnSnd,client);
	}
}

/* *********************** OnWar3EventDeath *********************** */
public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	
	if(War3_GetRace(victim) == thisRaceID)
	{
		EmitSoundToAllAny(DeadSnd,victim);	
	}
}


/* *************************************** CalcGlodomorra *************************************** */
public Action:CalcGlodomorra( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID )
				{
					Glodomorra( i );					
				}
			}
		}
	}
}

/* *************************************** Glodomorra *************************************** */
public Glodomorra( client )
{
	new skill_glodomora = War3_GetSkillLevel( client, thisRaceID, SKILL_GLODOMORRA );
	if( skill_glodomora > 0 && !Hexed( client, false ) )
	{
		new Float:distance = GlodomorraRange[skill_glodomora];
		new damage = GlodomorraDamage[skill_glodomora];
		
		new AttackerTeam = GetClientTeam( client );
		new Float:AttackerPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, AttackerPos );
		
		AttackerPos[2] += 40.0;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 40.0;
				
				if( GetVectorDistance( AttackerPos, VictimPos ) <= distance )
				{
					War3_DealDamage(i,damage,client,DMG_BURN,"glodomorra",W3DMGORIGIN_SKILL);
					
					GlodomorraMaxHP += damage;
					War3_SetMaxHP_INTERNAL(client,GlodomorraMaxHP);
					War3_HealToBuffHP(client,damage);	
				}
			}
		}
	}
}


/* *************************************** OnAbilityCommand *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_OGON);
		if(skill > 0)
		{			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_OGON,true))
			{				
				new target=War3_GetTargetInViewCone(client,OgonRange[skill],false);
				if(ValidPlayer(target,true) && !W3HasImmunity(target,Immunity_Skills) && GetClientTeam(target)!= GetClientTeam(client))
				{
					new damage = OgonDamage[skill];
					
					War3_DealDamage(target,damage,client,DMG_BURN,"ogon",W3DMGORIGIN_SKILL);
					PrintHintText(target,"Zostales uderzony Ogonem Glodzilli");
					PrintHintText(client,"Uderzyles przeciwnika Ogonem Glodzilli");
					EmitSoundToAllAny(OgonSnd,client);
					War3_CooldownMGR(client,OgonCooldownTime,thisRaceID,SKILL_OGON,false,true);
					new Float:aPos[3];
					new Float:bPos[3];
					GetClientAbsOrigin(client, aPos);
					GetClientAbsOrigin(target, bPos);
					aPos[2] += 5;
					bPos[2] += 5;
					TE_SetupBeamPoints(aPos, bPos, BeamSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 255, 153, 51, 255 }, 0);
					TE_SendToAll();
				}
				else
				{
					PrintHintText(client, "There was no target available");
				}
			}
		}
		else
		{
			PrintHintText(client, "You need to level up +ability first.");
		}
	}
}


/* *************************************** OnUltimateCommand *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_CZEKOLADA);
		if(skill > 0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_CZEKOLADA,true))
			{
				new damage = CzekoladaDamage[skill];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true) && !W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos) < CzekoladaRange[skill])
						{
							if(GetClientTeam(i)!= AttackerTeam)
							{
								War3_DealDamage(i,damage,client,DMG_BURN,"czekolaada",W3DMGORIGIN_SKILL);
								PrintHintText(i,"Zostales zalany fala czekolady !");
								PrintHintText(client,"Zalales wrogow fala czekolady !");
							}
						}
					}
				}
				EmitSoundToAllAny(CzekoladaSnd,client);
				War3_CooldownMGR(client,CzekoladaCooldownTime,thisRaceID,ULT_CZEKOLADA,false,true);
			}
		}
		else
		{
			PrintHintText(client, "You need to level up ultimate first.");
		}
	}
}

