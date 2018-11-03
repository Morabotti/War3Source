/**
* File: War3Source_Grunt.sp
* Description: The Grunt race for War3Source.
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
	name = "War3Source Race - Grunt",
	author = "Cereal Killer",
	description = "Grunt for War3Source.",
	version = "1.0.7.3",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

//Pillage
new Float:Pillagechance[9] =  { 0.0, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55 };

//Berserker Health
new BerserkerHP[9]={0,30,40,50,60,70,80,90,100};
new BerserkerARMOR[9]={0,30,40,50,60,70,80,90,100};

//Berserker Strength
new Float:bstdamage[9] =  { 0.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.25 };

//Arcanite Enchancement
new Float:arcenhdistance[9] =  { 0.0, 200.0, 230.0, 260.0, 290.0, 320.0, 350.0, 380.0, 450.0 };
new Float:arcenhdamage[9] =  { 0.0, 1.04, 1.08, 1.12, 1.18, 1.22, 1.26, 1.30, 1.35 };

new lgtningSprite;
new String:SpawnSND[] = "*mora-wcs/war3source/flint/chaching.mp3";
new String:SpawnSND_FullPath[] = "sound/mora-wcs/war3source/flint/chaching.mp3";

//SKILLS and ULTIMATE
new SKILL_PILLAGE, SKILL_BHP, SKILL_BST, ULT_ARCENH;

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==380){
		thisRaceID=War3_CreateNewRace("Grunt","grunt");
		SKILL_PILLAGE=War3_AddRaceSkill(thisRaceID,"Pillage (Attack)","Steal Gold",false,8);
		SKILL_BHP=War3_AddRaceSkill(thisRaceID,"Berserker Health (Passive)","More health",false,8);
		SKILL_BST=War3_AddRaceSkill(thisRaceID,"Berserker Strength (Attack)","More damage",false,8);
		ULT_ARCENH=War3_AddRaceSkill(thisRaceID,"Arcanite enhancement (Passive)","Alies close by do more damage",true,8);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	lgtningSprite = PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	AddFileToDownloadsTable(SpawnSND_FullPath);
	PrecacheSoundAny(SpawnSND);
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		GivePlayerItem(client,"weapon_fiveseven");
		HPbonus(client);
		EmitSoundToAllAny(SpawnSND, client);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		SetEntityHealth(client,100);
	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client,"weapon_fiveseven");
			HPbonus(client);
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BST);
			new level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_PILLAGE);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					if(skill_level>0){
						if(!W3HasImmunity(victim,Immunity_Skills)){
							War3_DamageModPercent(bstdamage[skill_level]);
						}
					}
					if(level>0){
						if(!W3HasImmunity(victim,Immunity_Skills)){
							if(GetRandomFloat(0.0,1.0)<=Pillagechance[level]){
								new gold=War3_GetGold(victim);
								if(gold>0){
									War3_SetGold(victim,War3_GetGold(victim)-1);
									War3_SetGold(attacker,War3_GetGold(attacker)+1);
									PrintHintText(victim,"Grunt stole some gold");
									PrintHintText(attacker,"Steal Gold");
									new Float:PosA[3];
									new Float:PosB[3];
									GetClientAbsOrigin(attacker, PosA);
									GetClientAbsOrigin(victim, PosB);
									PosA[2] += 10;
									PosB[2] += 10;
									TE_SetupBeamPoints(PosA, PosB, lgtningSprite, 0, 0, 60, 0.5, 15.0, 15.0, 0, 0.0, { 255, 255, 0, 255 }, 15);
									TE_SendToAll();
								}
								else
								{
									PrintHintText(attacker,"They have no gold.");
								}
							}
						}
					}
				}
			}

			for(new i=0;i<=MaxClients;i++){
				if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID){
					new iteam=GetClientTeam(i);
					if(iteam==ateam){
						if(i!=attacker){
							new skilllevel=War3_GetSkillLevel(i,thisRaceID,ULT_ARCENH);
							if(skilllevel>0){
								if(!W3HasImmunity(victim,Immunity_Skills)){
									new Float:ipos[3];
									new Float:attpos[3];
									GetClientAbsOrigin(i,ipos);
									GetClientAbsOrigin(attacker, attpos);
									if(GetVectorDistance(ipos,attpos)<arcenhdistance[skilllevel]){
										War3_DamageModPercent(arcenhdamage[skilllevel]);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public HPbonus(client)
{
	if(War3_GetRace(client)==thisRaceID){
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BHP);
		if(skill_level>0){
			new hpadd=BerserkerHP[skill_level];
			SetEntityHealth(client,GetClientHealth(client)+hpadd);
			War3_SetMaxHP_INTERNAL(client,War3_GetMaxHP(client)+hpadd);
			new armoradd=BerserkerARMOR[skill_level];
			War3_SetCSArmor(client,armoradd);
		}
	}
}