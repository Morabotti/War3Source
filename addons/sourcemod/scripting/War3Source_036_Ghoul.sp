/**
* File: War3Source_Ghoul.sp
* Description: The Ghoul race for War3Source.
* Author(s): Cereal Killer 
*/

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Ghoul",
	author = "Cereal Killer",
	description = "Ghoul for War3Source.",
	version = "1.0.6.3",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

new BeamSprite,HaloSprite;

//Cannibalize
new String:Nom[]="*mora-wcs/war3source/morabotti/zombiealert3.mp3";
new String:Nom_FullPath[]="sound/mora-wcs/war3source/morabotti/zombiealert3.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[9] =  { 0, 10, 11, 12, 13, 14, 15, 16, 17};
new corpsehealth[MAXPLAYERS][20];
new bool:corpsedied[MAXPLAYERS][20];

//Frenzy
new Float:attspeed[9] =  { 1.0, 1.6, 1.63, 1.66, 1.69, 1.72, 1.75, 1.78, 1.81};
new Float:movespeed[9] =  { 1.0, 1.35, 1.38, 1.41, 1.44, 1.47, 1.50, 1.53, 1.56 };

//Unholy Strength
//new Float:unhsdamage[9] =  { 1.0, 1.2, 1.25, 1.30, 1.35, 1.4, 1.45, 1.50, 1.55 };
new Float:t_unhsdamage[9] =  { 1.0, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45 };

//Unholy Armor
new unholyarmor[9] =  { 20, 32, 44, 56, 68, 80, 92, 104, 115 };

//SKILLS and ULTIMATE
new SKILL_CANN, SKILL_FREN, SKILL_UNHS, ULT_UNHA;

public OnPluginStart()
{
	CreateTimer(0.5,nomnomnom,_,TIMER_REPEAT);
}

public OnMapStart()
{
	PrecacheModel("models/mora-wcs/player/zombie.mdl");
	AddFileToDownloadsTable("models/mora-wcs/player/zombie.vtx");
	AddFileToDownloadsTable("models/mora-wcs/player/zombie.mdl");
	AddFileToDownloadsTable("models/mora-wcs/player/zombie.phy");
	AddFileToDownloadsTable("models/mora-wcs/player/zombie.vvd");
	
	AddFileToDownloadsTable(Nom_FullPath);
	PrecacheSoundAny(Nom);
	BeamSprite=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/mora-wcs/sprites/halo01.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==360){
		thisRaceID=War3_CreateNewRace("Ghoul", "ghoul");
		SKILL_CANN=War3_AddRaceSkill(thisRaceID,"Cannibalize","Enables you to eat enemys body",false,8);
		SKILL_FREN=War3_AddRaceSkill(thisRaceID,"Frenzy","Increase the attack speed / movement speed",false,8);
		SKILL_UNHS=War3_AddRaceSkill(thisRaceID,"Unholy Strength","Lower the damage take",false,8);
		ULT_UNHA=War3_AddRaceSkill(thisRaceID,"Unholy Armor","Increase max health (passive)",true,8);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		decl Float:SpawnPos[3];
		GetClientAbsOrigin(client,SpawnPos);
		TE_SetupBeamRingPoint(SpawnPos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
		TE_SendToClient(client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true))
		{
			InitPassiveSkills( client );
			SetEntityModel(client, "models/mora-wcs/player/zombie.mdl");
		}
	}
	resetcorpses();
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, 1.0 );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills(client);
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public resetcorpses()
{
	for(new client=0;client<=MaxClients;client++){
		for(new deaths=0;deaths<=19;deaths++){
			corpselocation[0][client][deaths]=0.0;
			corpselocation[1][client][deaths]=0.0;
			corpselocation[2][client][deaths]=0.0;
			dietimes[client]=0;
			corpsehealth[client][deaths]=0;
			corpsedied[client][deaths]=false;
		}
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_AddSkillBuff(thisRaceID, SKILL_FREN, fMaxSpeed, movespeed);
		War3_AddSkillBuff(thisRaceID, SKILL_FREN, fAttackSpeed, attspeed);
		War3_AddSkillBuff(thisRaceID, ULT_UNHA, iAdditionalMaxHealth, unholyarmor);
	}
}


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_UNHS);
					if(skill_level>0){
						War3_DamageModPercent(t_unhsdamage[skill_level]);
					}
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new deaths=dietimes[victim];
	dietimes[victim]++;
	corpsedied[victim][deaths]=true;
	corpsehealth[victim][deaths]=60;
	new Float:pos[3];
	War3_CachedPosition(victim,pos);
	corpselocation[0][victim][deaths]=pos[0];
	corpselocation[1][victim][deaths]=pos[1];
	corpselocation[2][victim][deaths]=pos[2];
	for(new client=0;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
			TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
			TE_SendToClient(client);
		}
	}
}

public Action:nomnomnom(Handle:timer)
{
	for(new client=0;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_CANN);
			if(skill_level>0){
				for(new corpse=0;corpse<=MaxClients;corpse++){
					for(new deaths=0;deaths<=19;deaths++){
						if(corpsedied[corpse][deaths]==true){
							new Float:corpsepos[3];
							new Float:clientpos[3];
							GetClientAbsOrigin(client,clientpos);
							corpsepos[0]=corpselocation[0][corpse][deaths];
							corpsepos[1]=corpselocation[1][corpse][deaths];
							corpsepos[2]=corpselocation[2][corpse][deaths];
							
							if(GetVectorDistance(clientpos,corpsepos)<50){
								if(corpsehealth[corpse][deaths]>=0){
									EmitSoundToAllAny(Nom,client);
									W3FlashScreen(client,{155,0,0,40},0.1);
									corpsehealth[corpse][deaths]-=5;
									new addhp1=cannibal[skill_level];
									War3_HealToMaxHP(client,addhp1);
								}
							}
							else
							{
								corpsehealth[corpse][deaths]-=5;
							}
						}
					}
				}
			}
		}
	}
}