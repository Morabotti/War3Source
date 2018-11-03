/*
* War3Source Race - Nomad [Crysis]
* 
* File: War3Source_War3Source_Nomad[Crysis].sp
* Description: The Nomad [Crysis] race for War3Source.
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source Race - Nomad [Crysis]",
    author = "M.A.C.A.B.R.A",
    description = "The Nomad [Crysis] race for War3Source.",
    version = "1.0.2",
	url = "http://strefagier.com.pl/"
}; 
   
new thisRaceID;
new SKILL_NANOSUIT, SKILL_ARMOR, SKILL_SPEED, SKILL_STRENGTH, SKILL_CLOAK;
  
/* ********** Modes ********** */
enum ACTIVEMODE
{
	None,
    Armor,
    Speed,
    Strength,
	Cloak,
}
new ACTIVEMODE:CurrentMode[MAXPLAYERS];
new RecoveryHP[9] = {0,1,2,2,3,3,4,4,5}; 
new RecoveryEnergy[9] = {0,1,2,3,4,5,6,7,8}; 
new ModeCounter[MAXPLAYERS];
new bool:CriticalStatus[MAXPLAYERS];

// Instructions
new bool:Instructions[MAXPLAYERS];
new InstructionCounter[MAXPLAYERS];

// Armor
new Float:ArmorDMG[9] = {1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76};

// Speed
new Float:SpeedSpeed[9] = {1.0, 1.12, 1.24, 1.36, 1.48, 1.60, 1.72, 1.84, 2.0};
new Float:SpeedAttack[9] = {1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.24};
new Float:SpeedMultiplier = 0.05;
new Float:lastLocation[MAXPLAYERS][3];

// Strength
new Float:StrengthDMG[9] = {1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4};
new Float:StrengthGravity[9] = {1.0, 0.9, 0.8, 0.7, 0.6, 0.55, 0.5, 0.45, 0.4};
new Float:StrengthPushForce[9] = {1.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0};
new m_vecBaseVelocity;

// Cloak
new CloakEnergyDrain[9] = {0, 10, 9, 8, 7, 6, 5, 4, 3};

// Sounds
new String:ArmorSnd[]="*mora-wcs/war3source/nomad/armor.mp3";
new String:ArmorSnd_FullPath[]="sound/mora-wcs/war3source/nomad/armor.mp3";
new String:SpeedSnd[]="*mora-wcs/war3source/nomad/speed.mp3";
new String:SpeedSnd_FullPath[]="sound/mora-wcs/war3source/nomad/speed.mp3";
new String:StrengthSnd[]="*mora-wcs/war3source/nomad/strength.mp3";
new String:StrengthSnd_FullPath[]="sound/mora-wcs/war3source/nomad/strength.mp3";
new String:CloakSnd[]="*mora-wcs/war3source/nomad/cloak.mp3";
new String:CloakSnd_FullPath[]="sound/mora-wcs/war3source/nomad/cloak.mp3";
new String:CriticalSnd[]="*mora-wcs/war3source/nomad/critical.mp3";
new String:CriticalSnd_FullPath[]="sound/mora-wcs/war3source/nomad/critical.mp3";
 
/* *********************** OnWar3PluginReady *********************** */
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==450){
	thisRaceID=War3_CreateNewRace("Nomad","nomad");
	
	SKILL_NANOSUIT=War3_AddRaceSkill(thisRaceID,"NanoSuit","Improves your nanosuit powers.",false,8);
	SKILL_ARMOR=War3_AddRaceSkill(thisRaceID,"Armor Mode","Allows you to absorb a part of taken damage.",false,8);
	SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed Mode","Increases your movement speed.",false,8);
	SKILL_STRENGTH=War3_AddRaceSkill(thisRaceID,"Strength Mode","Increases your damage and allows you to jump higher.",false,8);
	SKILL_CLOAK=War3_AddRaceSkill(thisRaceID,"Cloak Mode","Reduces your visibility.",false,8);
    
	War3_CreateRaceEnd(thisRaceID);
	}
}
 
/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	PrecacheModel("models/player/custom_player/kuristaja/nanosuit/nanosuitv3.mdl");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms_vmodel.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms2_vmodel.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands_vmodel.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands2_vmodel.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet_pt.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet3.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_legs.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_legs2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_legs3.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_torso.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_torso2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_visor.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_arms_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_hands_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_helmet_pt.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_legs.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_legs_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_torso.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_torso_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_visor.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/nanosuit/nanosuit_visor_normal.vtf");
	
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/nanosuit/nanosuitv3.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/nanosuit/nanosuitv3.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/nanosuit/nanosuitv3.phy");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/nanosuit/nanosuitv3.vvd");
	
	// Sounds
	AddFileToDownloadsTable(ArmorSnd_FullPath);
	AddFileToDownloadsTable(SpeedSnd_FullPath);
	AddFileToDownloadsTable(StrengthSnd_FullPath);
	AddFileToDownloadsTable(CloakSnd_FullPath);
	AddFileToDownloadsTable(CriticalSnd_FullPath);
	
	PrecacheSoundAny(ArmorSnd);
	PrecacheSoundAny(SpeedSnd);
	PrecacheSoundAny(StrengthSnd);
	PrecacheSoundAny(CloakSnd);
	PrecacheSoundAny(CriticalSnd);
	
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	CreateTimer(0.1,CalcMode,_,TIMER_REPEAT);
	HookEvent( "player_jump", PlayerJumpEvent );
	HookEvent("weapon_fire", Event_Fire, EventHookMode_Post);
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}

/* **************** OnRaceChanged **************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace == thisRaceID )
	{
		if(ValidPlayer(client,true))
		{
			
		}
	}
	else
	{
		W3ResetAllBuffRace(client, thisRaceID);
		Instructions[client] = false;
	}
}
 
/* **************** OnWar3EventSpawn **************** */
public OnWar3EventSpawn(client)
{    
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		
		ModeCounter[client] = 0;
		
		CriticalStatus[client] = false;
		CurrentMode[client] = None;
		Instructions[client] = true;
		InstructionCounter[client] = 0;
		
		CreateTimer( 0.1, Instruction, client);
		CreateTimer( 1.9, Instruction, client,TIMER_REPEAT);
		
		SetEntityModel(client, "models/player/custom_player/kuristaja/nanosuit/nanosuitv3.mdl");
		
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_NANOSUIT) > 0)
		{
			if(War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOR) > 0)
			{
				CurrentMode[client] = Armor;
			}
			War3_SetCSArmor(client,100);
			War3_SetCSArmorHasHelmet(client,true);
		}
	}
}

/* *************************************** OnAbilityCommand *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	new skill_nanosuit = War3_GetSkillLevel(client,thisRaceID,SKILL_NANOSUIT);
	new skill_armor = War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOR);
	new skill_speed = War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
	new skill_strength = War3_GetSkillLevel(client,thisRaceID,SKILL_STRENGTH);
	new skill_cloak = War3_GetSkillLevel(client,thisRaceID,SKILL_CLOAK);	

	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		if(skill_nanosuit == 0)
		{
			PrintHintText(client, "You are not wearing your nanosuit!");
		}
		else
		{
			if((skill_armor==0)&&(skill_speed==0)&&(skill_strength==0)&&(skill_cloak==0))
			{
				PrintHintText(client, "You have no modes yet!");
			}
			else
			{
				new Handle:menu = CreateMenu(SelectMode);
				SetMenuTitle(menu, "Which mode would you like to use?");
				if(skill_armor>0)
				{
					AddMenuItem(menu, "armor", "Armor");
				}
				if(skill_speed)
				{
					AddMenuItem(menu, "speed", "Speed");
				}
				if(skill_strength)
				{
					AddMenuItem(menu, "strength", "Strength");
				}
				if(skill_cloak)
				{
					AddMenuItem(menu, "cloak", "Cloak");
				}
				SetMenuExitButton(menu, false);
				DisplayMenu(menu, client, 20);
			}
        }
    }
}
 
/* *************************************** SelectMode *************************************** */
public SelectMode(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info,"armor"))
		{
			if(CurrentMode[client] != Armor)
			{
				CurrentMode[client] = Armor;
				EmitSoundToAllAny(ArmorSnd,client);
				PrintHintText(client, "Maximum Armor!");
				W3ResetAllBuffRace(client, thisRaceID);
			}
		}
		else if(StrEqual(info,"speed"))
		{
			if(CurrentMode[client] != Speed)
			{
				CurrentMode[client] = Speed;
				EmitSoundToAllAny(SpeedSnd,client);
				PrintHintText(client, "Maximum Speed!");
				W3ResetAllBuffRace(client, thisRaceID);
				GetClientAbsOrigin(client,lastLocation[client]);
			}
		}
		else if(StrEqual(info,"strength"))
		{
			if(CurrentMode[client] != Strength)
			{
				CurrentMode[client] = Strength;
				EmitSoundToAllAny(StrengthSnd,client);
				PrintHintText(client, "Maximum Strength!");
				W3ResetAllBuffRace(client, thisRaceID);
			}
		}
		else if(StrEqual(info,"cloak"))
		{
			if(CurrentMode[client] != Cloak)
			{
				CurrentMode[client] = Cloak;
				EmitSoundToAllAny(CloakSnd,client);
				PrintHintText(client, "Cloak Engaged!");
				W3ResetAllBuffRace(client, thisRaceID);
				GetClientAbsOrigin(client,lastLocation[client]);
			}
		}
	}
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

/* *************************************** CalcMode *************************************** */
public Action:CalcMode(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i) == thisRaceID)
			{
				new skill_nanosuit = War3_GetSkillLevel(i,thisRaceID,SKILL_NANOSUIT);
				if(skill_nanosuit > 0)
				{
					
					switch(CurrentMode[i])
					{
						/* **************** None **************** */
						case None:
						{
							W3ResetAllBuffRace(i, thisRaceID);
						}
						/* **************** Armor **************** */
						case Armor:
						{
							ArmorMode(i);
						}
						/* **************** Speed **************** */
						case Speed:
						{
							SpeedMode(i);
						}
						/* **************** Strength **************** */
						case Strength:
						{
							StrengthMode(i);
						}
						/* **************** Cloak **************** */
						case Cloak:
						{
							CloakMode(i);
						}
					}
					ModeCounter[i]++;
					if(ModeCounter[i] >= 10)
					{
						ModeCounter[i] = 0;
						new energy = War3_GetCSArmor(i);
						if(CurrentMode[i] == Cloak)
						{
							new energydrain = CloakEnergyDrain[War3_GetSkillLevel(i,thisRaceID,SKILL_CLOAK)];
							new tmpenergy = energy;
							if(tmpenergy - energydrain < 0)
							{
								energy = 0;
							}
							else
							{
								energy -= energydrain;
							}
							War3_SetCSArmor(i,energy);	
						}
						else
						{
							if(energy + RecoveryEnergy[skill_nanosuit] > 100)
							{
								energy += (100-energy);
							}
							else
							{
								energy += RecoveryEnergy[skill_nanosuit];
							}
							War3_SetCSArmor(i,energy);
						}
						
						new health = GetClientHealth(i);
						new maxhealth = War3_GetMaxHP(i);
						if(health < maxhealth)
						{
							if(health + RecoveryHP[War3_GetSkillLevel(i,thisRaceID,SKILL_NANOSUIT)] > maxhealth)
							{
								health += (maxhealth-health);
							}
							else
							{
								health += RecoveryHP[War3_GetSkillLevel(i,thisRaceID,SKILL_NANOSUIT)];
							}
							SetEntityHealth(i,health);
						}
					}
				}
			}
		}
	}
}

/* *********************** ArmorMode *********************** */
ArmorMode(any:client)
{
	new energy = War3_GetCSArmor(client);
	
	if(energy > 20)
	{
		CriticalStatus[client] = false;
	}
	else
	{
		if(CriticalStatus[client] == false)
		{
			EmitSoundToAllAny(CriticalSnd,client);
			PrintHintText(client, "Energy Critical!");
			CriticalStatus[client] = true;
		}
	}
}

/* *********************** SpeedMode *********************** */
SpeedMode(any:client)
{
	new skill_speed = War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
	new energy = War3_GetCSArmor(client);
	
	if(energy > 20)
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedSpeed[skill_speed]);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,SpeedAttack[skill_speed]);
		CriticalStatus[client] = false;
	}
	else
	{
		if(CriticalStatus[client] == false)
		{
			EmitSoundToAllAny(CriticalSnd,client);
			PrintHintText(client, "Energy Critical!");
			CriticalStatus[client] = true;
		}
		if(energy < 5)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		}
		else
		{
			if(energy >= 10)
			{
				War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedSpeed[skill_speed]);
				War3_SetBuff(client,fAttackSpeed,thisRaceID,SpeedAttack[skill_speed]);
			}
		}
	}
	
	new Float:origin[3];
	new Float:distance;
	
	GetClientAbsOrigin(client,origin);
	distance = GetVectorDistance(origin,lastLocation[client]);
	lastLocation[client][0]=origin[0];
	lastLocation[client][1]=origin[1];
	lastLocation[client][2]=origin[2];
	
	new energydrain = RoundFloat(FloatMul(distance,SpeedMultiplier));
	
	new tmpenergy = energy;
	if(tmpenergy - energydrain < 0)
	{
		energy = 0;
	}
	else
	{
		energy -= energydrain;
	}
	
	War3_SetCSArmor(client,energy);
}

/* *********************** StrengthMode *********************** */
StrengthMode(any:client)
{
	new skill_strength = War3_GetSkillLevel(client,thisRaceID,SKILL_STRENGTH);
	new energy = War3_GetCSArmor(client);
	
	if(energy > 20)
	{
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,StrengthGravity[skill_strength]);
		CriticalStatus[client] = false;
	}
	else
	{
		if(CriticalStatus[client] == false)
		{
			EmitSoundToAllAny(CriticalSnd,client);
			PrintHintText(client, "Energy Critical!");
			CriticalStatus[client] = true;
		}
		if(energy < 5)
		{
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		}
		else
		{
			if(energy >= 10)
			{
				War3_SetBuff(client,fLowGravitySkill,thisRaceID,StrengthGravity[skill_strength]);
			}
		}
	}
}


/* *************************************** PlayerJumpEvent *************************************** */
public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if(CurrentMode[client] == Strength)
			{
				new energy = War3_GetCSArmor(client);
				new energydrain = 10;
				if(energy - energydrain < 0)
				{
					energy = 0;
				}
				else
				{
					energy -= energydrain;
				}
				War3_SetCSArmor(client,energy);
			}
		}
	}
}

/* *********************** OnW3TakeDmgBulletPre *********************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(CurrentMode[attacker] == Strength) // Attacker's Strength
			{
				new energy = War3_GetCSArmor(attacker);
				new energydrain = 10;
				if(energy >= energydrain)
				{
					new skill_strength = War3_GetSkillLevel(attacker,thisRaceID,SKILL_STRENGTH);
					War3_DamageModPercent(StrengthDMG[skill_strength]);
					damage *= StrengthDMG[skill_strength];
					
					decl String:weapon[64];
					GetClientWeapon(attacker, weapon, sizeof(weapon));
					if(StrEqual(weapon, "weapon_knife"))
					{
						new Float:NomadPos[3];
						new Float:VictimPos[3];
						GetClientAbsOrigin(attacker,NomadPos);
						GetClientAbsOrigin(victim,VictimPos);
						
						new Float:velocity[3];
						velocity[0] = (VictimPos[0]-NomadPos[0]) * StrengthPushForce[skill_strength];
						velocity[1] = (VictimPos[1]-NomadPos[1]) * StrengthPushForce[skill_strength];
						velocity[2] = (VictimPos[2]-NomadPos[2]+50) * StrengthPushForce[skill_strength];
						SetEntDataVector(victim,m_vecBaseVelocity,velocity,true);
						PrintHintText(victim, "You have been punched by Nomad's fist!");
					}
					energy -= energydrain;
					War3_SetCSArmor(attacker,energy);
				}
			}	
		}
		if(War3_GetRace(victim)==thisRaceID)
		{
			if(CurrentMode[victim] == Armor) // Victim's Armor
			{
				new skill_armor = War3_GetSkillLevel(victim,thisRaceID,SKILL_ARMOR);
				War3_DamageModPercent(ArmorDMG[skill_armor]);
				damage *= ArmorDMG[skill_armor];
				
				new energy = War3_GetCSArmor(victim);
				new energydrain = RoundFloat(damage);
				
				new tmpenergy = energy;
				if(tmpenergy - energydrain > 0)
				{
					War3_DamageModPercent(0.0);
					damage *= 0.0;
					energy -= energydrain;
				}
				else
				{
					new tmpdmg = energydrain-energy;
					if(GetClientHealth(victim) > tmpdmg)
					{
						War3_DamageModPercent(0.0);
						damage *= 0.0;
						War3_DecreaseHP(victim, tmpdmg);
					}
					energy = 0;
				}
				War3_SetCSArmor(victim,energy);
			}	
		}
	}
}

/* *********************** CloakMode *********************** */
CloakMode(any:client)
{
	new energy = War3_GetCSArmor(client);
	
	if(energy > 20)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.1);
		CriticalStatus[client] = false;
	}
	else
	{
		if(CriticalStatus[client] == false)
		{
			EmitSoundToAllAny(CriticalSnd,client);
			PrintHintText(client, "Energy Critical!");
			CriticalStatus[client] = true;
		}
		if(energy < 5)
		{
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
			W3ResetAllBuffRace(client, thisRaceID);
			CurrentMode[client] = Armor;
			EmitSoundToAllAny(ArmorSnd,client);
			PrintHintText(client, "Maximum Armor!");
		}
		else
		{
			if(energy >= 10)
			{
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.1);
			}
		}
	}
	
	new Float:origin[3];
	new Float:distance;
	
	GetClientAbsOrigin(client,origin);
	distance = GetVectorDistance(origin,lastLocation[client]);
	lastLocation[client][0]=origin[0];
	lastLocation[client][1]=origin[1];
	lastLocation[client][2]=origin[2];
	
	new energydrain = RoundFloat(FloatMul(distance,SpeedMultiplier));
	
	new tmpenergy = energy;
	if(tmpenergy - energydrain < 0)
	{
		energy = 0;
	}
	else
	{
		energy -= energydrain;
	}
	
	War3_SetCSArmor(client,energy);
}

/* *********************** Event_Fire *********************** */
public Event_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if(CurrentMode[client] == Cloak)
			{
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
				W3ResetAllBuffRace(client, thisRaceID);
				CurrentMode[client] = Armor;
				EmitSoundToAllAny(ArmorSnd,client);
				PrintHintText(client, "Maximum Armor!");
				War3_SetCSArmor(client,0);			
			}
		}
	}
}

/* **************** Instruction **************** */
public Action:Instruction( Handle:timer, any:client )
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(ValidPlayer( client, true))
		{
			if(War3_GetRace(client)==thisRaceID && Instructions[client] == true)
			{
				PrintCenterText(client, "Press  -ability-  to select Nanosuit Mode."); 
				InstructionCounter[client]++;
				if(InstructionCounter[client] >= 11)
				{
					InstructionCounter[client] = 0;
					KillTimer(timer);
				}
			}
			else
			{
				InstructionCounter[client] = 0;
				KillTimer(timer);
			}
		}
		else
		{
			InstructionCounter[client] = 0;
			KillTimer(timer);
		}
	}
	else
	{
		InstructionCounter[client] = 0;
		KillTimer(timer);
	}
}