/*
* War3Source Race - Dark Druid
* 
* File: War3Source_DarkDruid.sp
* Description: The Dark Druid race for War3Source.
* Author: M.A.C.A.B.R.A 
* 
* Special thanks to Remzo for finding bugs and help with removing them :)
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <sdktools_sound>

public Plugin:myinfo = 
{
	name = "War3Source Race - Dark Druid",
	author = "M.A.C.A.B.R.A",
	description = "The Dark Druid race for War3Source.",
	version = "1.1.1",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_INFERNAL, SKILL_SHADOW, SKILL_SLEEP,  ULT_WAREWOLF;

// Infernal Breath
new BreathFireEnt[MAXPLAYERS][25];
new Float:BreathFireEntPos[MAXPLAYERS][25][3];
new BreathFireEntCounter[MAXPLAYERS];
new BreathCounter[MAXPLAYERS];
new bool:bIsBreathActivated[MAXPLAYERS];
new BreathAmount[9] = {0, 1, 2, 2, 2, 3, 3, 4, 5};
new Float:BreathIgniteTime[9] = {0.0, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5};
new Float:BreathDistance[9] = {0.0, 200.0, 230.0, 260.0, 290.0, 320.0, 350.0, 380.0, 410.0};
new Float:BreathTime[9] = {0.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0};
new Float:InfernalBreathCooldown = 15.0;

// Shadow Aura
new Float:ShadowTime[9] = {0.0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 2.1, 2.4};
new Float:ShadowRadius[9] = {0.0, 80.0, 100.0, 120.0, 140.0, 160.0, 180.0, 200.0, 220.0};
new Float:ShadowSlow[9] = {0.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76};
new bool:bIsShadowed[MAXPLAYERS];
new Float:ShadowCooldown = 10.0;

// Sleep
new SleepHPRecover[9] = {0, 1, 2, 2, 3, 3, 4, 4, 5};
new bool:bIsSleeping[MAXPLAYERS];
new SleepDelayer[MAXPLAYERS];
new Float:SleepCooldown = 15.0;

// WareWolf Form
new WareWolfFormTime[9] = {0, 110, 140, 160, 180, 200, 220, 250, 300};
new WareWolfTime[MAXPLAYERS];
new bool:bIsWareWolfActivated[MAXPLAYERS];
new DruidWeapons[MAXPLAYERS][10];
new String:DruidModel[MAXPLAYERS][128];
new Float:WarewolfGravity[9] = {1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60};
new Float:WarewolfSpeed[9] = {1.0, 1.2, 1.25, 1.30, 1.35, 1.40, 1.45, 1.50, 1.55};
new Float:WarewolfAtkSpeed[9] = {1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.25};
new Float:WarewolfDMG[9] = {1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.25};
new Float:WareWolfCooldown = 20.0;

//ÄÄNET

new String:TransformationSnd[] = "*mora-wcs/war3source/darkdruid/transformation.mp3";
new String:TransformationSnd_FullPath[] = "sound/mora-wcs/war3source/darkdruid/transformation.mp3";
new String:Transformation2Snd[] = "*mora-wcs/war3source/darkdruid/transformation2.mp3";
new String:Transformation2Snd_FullPath[] = "sound/mora-wcs/war3source/darkdruid/transformation2.mp3";
new String:WareWolfHitSnd[] = "*mora-wcs/war3source/darkdruid/warewolfhit.mp3";
new String:WareWolfHitSnd_FullPath[] = "sound/mora-wcs/war3source/darkdruid/warewolfhit.mp3";
new String:WareWolfFatalitySnd[] = "*mora-wcs/war3source/darkdruid/warewolffatality.mp3";
new String:WareWolfFatalitySnd_FullPath[] = "sound/mora-wcs/war3source/darkdruid/warewolffatality.mp3";
new String:BreathSnd[] ="*mora-wcs/war3source/fire.mp3";
new String:BreathSnd_FullPath[] ="sound/mora-wcs/war3source/fire.mp3";
new String:SleepSnd[] ="*mora-wcs/war3source/morabotti/cave_hit2.mp3";
new String:SleepSnd_FullPath[] ="sound/mora-wcs/war3source/morabotti/cave_hit2.mp3";


/* *********************** OnWar3PluginReady *********************** */
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==350)
	{
	thisRaceID=War3_CreateNewRace("Dark Druid","darkdruid");
	
	SKILL_INFERNAL=War3_AddRaceSkill(thisRaceID,"Infernal Breath","Creates the wall of fire in front of you. (+ability)",false,8);
	SKILL_SHADOW=War3_AddRaceSkill(thisRaceID,"Shadow Aura","Allows you to cover your enemies eyes",false,8);
	SKILL_SLEEP=War3_AddRaceSkill(thisRaceID,"Sleep","Rest helps you to recover your energy. (+ability1)",false,8);
	ULT_WAREWOLF=War3_AddRaceSkill(thisRaceID,"WareWolf Form","You can use your magical powers and take animal form. (+ultimate)",true,8);
	
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_INFERNAL, InfernalBreathCooldown, _ );
	W3SkillCooldownOnSpawn( thisRaceID, ULT_WAREWOLF, WareWolfCooldown, _ );
	War3_CreateRaceEnd(thisRaceID);
	}
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	//Sounds
	AddFileToDownloadsTable(TransformationSnd_FullPath);
	AddFileToDownloadsTable(Transformation2Snd_FullPath);
	AddFileToDownloadsTable(WareWolfHitSnd_FullPath);
	AddFileToDownloadsTable(WareWolfFatalitySnd_FullPath);
	AddFileToDownloadsTable(BreathSnd_FullPath);
	AddFileToDownloadsTable(SleepSnd_FullPath);
	
	PrecacheSoundAny( TransformationSnd );
	PrecacheSoundAny( Transformation2Snd );
	PrecacheSoundAny( WareWolfHitSnd );
	PrecacheSoundAny( WareWolfFatalitySnd );
	PrecacheSoundAny( BreathSnd );
	PrecacheSoundAny( SleepSnd );

}


/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	CreateTimer(0.1,CalcShadow,_,TIMER_REPEAT);
	CreateTimer(0.1,BreathCheck,_,TIMER_REPEAT);
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{	
		
		GetEntPropString(client, Prop_Data, "m_ModelName", DruidModel[client], 128);
		
		WareWolfTime[client] = 0;
		bIsWareWolfActivated[client] = false;
		
		EmitSoundToAllAny(Transformation2Snd,client);
		
		BreathFireEntCounter[client] = 0;
		BreathCounter[client] = 0;
		bIsBreathActivated[client] = false;
		for(new i = 0; i <=24; i++)
		{
			BreathFireEnt[client][i] = -1;
		}
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				bIsShadowed[i] = false;
				W3ResetPlayerColor(i, War3_GetRace(i));
			}
		}
		
		StopSleep(client);
		bIsSleeping[client] = false;
		SleepDelayer[client] = 0;
		W3ResetPlayerColor(client, thisRaceID);
		
		SetEntityModel(client, DruidModel[client]);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0); 
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		if(bIsWareWolfActivated[client] == true)
		{
			for(new slot=0; slot<10; slot++)
			{
				if(DruidWeapons[client][slot] != -1)
				{
					EquipPlayerWeapon(client,DruidWeapons[client][slot]);						
				}
			}
		}
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetPlayerColor(client, thisRaceID);
		W3ResetAllBuffRace(client, thisRaceID);
	}
}

/* *************************************** Shadow Aura *************************************** */
/* *********************** CalcShadow *********************** */
public Action:CalcShadow(Handle:timer,any:userid)
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) )
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Shadow(i);
			}
		}
	}
}

/* *********************** Shadow *********************** */
public Shadow(any:client)
{
	new skill_lvl = War3_GetSkillLevel( client, thisRaceID, SKILL_SHADOW );
	if(skill_lvl > 0 && War3_SkillNotInCooldown(client,thisRaceID,SKILL_SHADOW,true) && bIsWareWolfActivated[client] == false)
	{
		new Float:DruidPos[3];
		GetClientAbsOrigin(client,DruidPos);
		for( new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if( ValidPlayer(i, true) && GetClientTeam(i) != GetClientTeam(client) && !W3HasImmunity(i, Immunity_Skills))
				{
					new Float:VictimPos[3];
					GetClientAbsOrigin(i,VictimPos);
					
					if(GetVectorDistance(DruidPos,VictimPos) < ShadowRadius[skill_lvl])
					{
						bIsShadowed[i] = true;
						W3FlashScreen(i,{0,0,0,225},_,_,FFADE_STAYOUT);
						W3SetPlayerColor(i,thisRaceID, 0,0,0,80); 
						War3_SetBuff(i,fSlow,thisRaceID,ShadowSlow[skill_lvl]);
						PrintHintText(i, "Shadow Aura has affected you.");
						PrintHintText(client, "Your Shadow Aura affected %N",i);
						EmitSoundToAllAny(SleepSnd,i);
						CreateTimer(ShadowTime[skill_lvl], StopShadow, i);
						War3_CooldownMGR(client,ShadowCooldown,thisRaceID,SKILL_SHADOW,_,_);
					}
				}
			}
		}
	}
}

/* **************** StopShadow **************** */
public Action:StopShadow( Handle:timer, any:client )
{
	if(bIsShadowed[client] == true)
	{
		bIsShadowed[client] = false;
		W3FlashScreen(client,{0,0,0,0}, _,_,(FFADE_IN|FFADE_PURGE));
		W3ResetPlayerColor(client, thisRaceID);
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		PrintHintText(client, "You have broken free from the influence of Shadow Aura.");
	}
}

/* *************************************** Infernal Breath & Sleep *************************************** */
/* *********************** OnAbilityCommand *********************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	/* ********** Infernal Breath ********** */
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_INFERNAL);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_INFERNAL,true))
			{
				if(bIsWareWolfActivated[client] == false)
				{
					if(BreathCounter[client] < BreathAmount[skill])
					{
						for(new Float:i = BreathDistance[skill]; i > 100.0; i-=50)
						{
							new fire = CreateEntityByName("env_fire");
							if(IsValidEdict(fire) && IsClientInGame(client))
							{
								BreathFireEntCounter[client]++;
								BreathFireEnt[client][BreathFireEntCounter[client]] = fire;
								decl String:Name[32];
								Format(Name, sizeof(Name), "Druid_Fire_%i", client);
								
								DispatchKeyValueFloat(fire, "damagescale", 0.0);
								DispatchKeyValueFloat(fire, "ignitionpoint", 0.0);
								DispatchKeyValue(fire, "Name", Name);
								DispatchKeyValue(fire, "fireattack", "0");
								DispatchKeyValue(fire, "firetype", "Natural");
								DispatchKeyValue(fire, "firesize", "100");
								DispatchSpawn(fire);
								ActivateEntity(fire);
								War3_GetAimTraceMaxLen(client,BreathFireEntPos[client][BreathFireEntCounter[client]],i);
								TeleportEntity(fire, BreathFireEntPos[client][BreathFireEntCounter[client]], NULL_VECTOR, NULL_VECTOR);
								AcceptEntityInput(fire, "StartFire");
								
								CreateTimer(BreathTime[skill], RemoveFire, fire);
							}
							PrintHintText(client, "Your Infernal Breath burns surroundings.");
							EmitSoundToAllAny(BreathSnd,client);
							War3_CooldownMGR(client,InfernalBreathCooldown,thisRaceID,SKILL_INFERNAL,_,_);
						}
						BreathCounter[client]++;
						bIsBreathActivated[client] = true;
						CreateTimer(BreathTime[skill], SwitchOffFire, client);
					}
					else
					{
						PrintHintText(client, "You cannot use Infernal Breath anymore.");
					}
				}
				else
				{
					PrintHintText(client, "You cannot use Infernal Breath in animal form.");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Infernal Breath first");
		}
	}
	/* ********** Sleep ********** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_SLEEP);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SLEEP,true))
			{
				if(bIsWareWolfActivated[client] == false)
				{
					if(bIsSleeping[client] == false)
					{
						new DruidHP = GetClientHealth(client);
						new DruidMaxHP = War3_GetMaxHP(client);
						if(DruidHP < DruidMaxHP)
						{
							W3FlashScreen(client,{0,0,0,255},_,_,FFADE_STAYOUT);
							W3SetPlayerColor(client,thisRaceID, 0,0,0,255); 
							War3_SetBuff(client,bStunned,thisRaceID,true);
							bIsSleeping[client] = true;
							SleepDelayer[client] = 0;
							EmitSoundToAllAny(SleepSnd,client);
							PrintHintText(client, "You have fallen asleep.");
							CreateTimer(0.1, CheckSleep, client, TIMER_REPEAT);
						}
						else
						{
							PrintHintText(client, "You do not need sleep. Your energy is fully regenerated.");
						}
					}
					else
					{
						StopSleep(client);
					}
				}
				else
				{
					PrintHintText(client, "You cannot sleep in animal form.");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Sleep first");
		}
	}
}

/* *********************** BreathCheck *********************** */
public Action:BreathCheck(Handle:timer,any:userid)
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) )
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				if(bIsBreathActivated[i] == true)
				{
					IgniteCheck(i);	
				}
			}
		}
	}
}

/* **************** IgniteCheck **************** */
public IgniteCheck(any:client)
{
	new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_INFERNAL);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i, true) && GetClientTeam(i) != GetClientTeam(client) && !W3HasImmunity(i, Immunity_Skills))
		{
			new Float:VictimPos[3];
			GetClientAbsOrigin(i,VictimPos);
			for(new j = 1; j <= BreathFireEntCounter[client]; j++)
			{
				if(GetVectorDistance(VictimPos, BreathFireEntPos[client][j]) < 100.0)
				{
					IgniteEntity(i, BreathIgniteTime[skill]);	
				}
			}
		}
	}	
}

/* **************** RemoveFire **************** */
public Action:RemoveFire(Handle:timer, any:fire)
{
	if(IsValidEdict(fire))
	{
		AcceptEntityInput(fire, "Kill");
	}
}

/* **************** SwitchOffFire **************** */
public Action:SwitchOffFire(Handle:timer, any:client)
{
	if(bIsBreathActivated[client] == true)
	{
		bIsBreathActivated[client] = false;
	}
}
/* **************** CheckSleep **************** */
public Action:CheckSleep( Handle:timer, any:client )
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(bIsSleeping[client] == true)
			{
				new DruidHP = GetClientHealth(client);
				new DruidMaxHP = War3_GetMaxHP(client);
				
				if(DruidHP < DruidMaxHP)
				{
					if(SleepDelayer[client] % 20 == 0)
					{
						if(DruidHP + SleepHPRecover[War3_GetSkillLevel(client,thisRaceID,SKILL_SLEEP)] > DruidMaxHP)
						{
							DruidHP += (DruidMaxHP-DruidHP);
						}
						else
						{
							DruidHP += SleepHPRecover[War3_GetSkillLevel(client,thisRaceID,SKILL_SLEEP)];
						}
						SetEntityHealth(client,DruidHP);
					}				
					SleepDelayer[client]++;
				}
				else
				{
					StopSleep(client);
					KillTimer(timer);
				}
			}
			else
			{
				StopSleep(client);
				KillTimer(timer);
			}
		}
		else
		{
			StopSleep(client);
			KillTimer(timer);
		}
	}
	else
	{
		KillTimer(timer);
	}
}

/* **************** StopSleep **************** */
public StopSleep(any:client)
{
	if(bIsSleeping[client] == true)
	{
		bIsSleeping[client] = false;
		W3FlashScreen(client,{0,0,0,0}, _,_,(FFADE_IN|FFADE_PURGE));
		W3ResetPlayerColor(client, thisRaceID);
		War3_SetBuff(client,bStunned,thisRaceID,false);
		PrintHintText(client, "You have woken up.");
		War3_CooldownMGR(client,SleepCooldown,thisRaceID,SKILL_SLEEP,_,_);
	}
}


/* *************************************** WareWolf Form *************************************** */
/* *********************** OnUltimateCommand *********************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_WAREWOLF);
		if(skill_ult > 0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_WAREWOLF,true ))
			{
				if(bIsWareWolfActivated[client] == false)
				{
					W3SetPlayerColor(client,thisRaceID,102,51,0,_,GLOW_ULTIMATE);
					
					new DruidHealthTMP = GetClientHealth(client) + 100;
					SetEntityHealth(client, DruidHealthTMP);
					War3_SetMaxHP_INTERNAL(client, DruidHealthTMP);
					
					War3_SetBuff(client,fLowGravitySkill,thisRaceID,WarewolfGravity[skill_ult]);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,WarewolfSpeed[skill_ult]);
					War3_SetBuff(client,fAttackSpeed,thisRaceID,WarewolfAtkSpeed[skill_ult]);
					
					for(new slot=0; slot<10; slot++) // Bronie
					{
						DruidWeapons[client][slot] = GetPlayerWeaponSlot(client,slot);
						if(DruidWeapons[client][slot] != -1)
						{
							if(slot == 4)
							{
								DruidWeapons[client][slot] = -1;
							}
							else
							{
								RemovePlayerItem(client,DruidWeapons[client][slot]);
							}
						}
					}
					War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
					GivePlayerItem( client, "weapon_knife");
					
					WareWolfTime[client] = WareWolfFormTime[skill_ult];
					bIsWareWolfActivated[client] = true;
					PrintHintText(client, "You have become a WareWolf. Kill an enemy to extend animal form time.");
					EmitSoundToAllAny(TransformationSnd,client);
					CreateTimer(0.1, WareWolfCheck, client,TIMER_REPEAT);
				}
				else
				{
					NormalForm(client);
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your WareWolf Form first");
		}
	}
}

/* **************** WareWolfCheck **************** */
public Action:WareWolfCheck( Handle:timer, any:client )
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(bIsWareWolfActivated[client] == true)
			{
				if(WareWolfTime[client] > 1)
				{
					if(WareWolfTime[client] % 10 == 0)
					{
						W3Hint(client,HINT_LOWEST,1.0,"WareWolf Form time left: %d",WareWolfTime[client]/10);
					}				
					WareWolfTime[client]--;
				}
				else
				{
					NormalForm(client);
					KillTimer(timer);
				}
			}
			else
			{
				KillTimer(timer);
			}
		}
		else
		{
			NormalForm(client);
			KillTimer(timer);
		}
	}
	else
	{
		KillTimer(timer);
	}
}

/* **************** NomalForm **************** */
public NormalForm(any:client)
{
	SetEntityModel(client, DruidModel[client]);
	W3ResetPlayerColor(client, thisRaceID);
	new DruidMaxHPTMP = War3_GetMaxHP(client) - 100;
	War3_SetMaxHP_INTERNAL(client, DruidMaxHPTMP);
	
	new DruidHealthTMP = GetClientHealth(client);
	if(DruidHealthTMP > DruidMaxHPTMP)
	{
		SetEntityHealth(client, DruidMaxHPTMP);
	}
	
	War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0); 
	
	War3_WeaponRestrictTo( client, thisRaceID, "" );
	if(bIsWareWolfActivated[client] == true && IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(new slot=0; slot<10; slot++)
		{
			if(DruidWeapons[client][slot] != -1)
			{
				EquipPlayerWeapon(client,DruidWeapons[client][slot]);						
			}
		}
		PrintHintText(client, "You are no longer a WareWolf.");
		EmitSoundToAllAny(Transformation2Snd,client);
		War3_CooldownMGR(client,WareWolfCooldown,thisRaceID,ULT_WAREWOLF,_,_);
	}
	bIsWareWolfActivated[client] = false;
}

/* **************** OnWar3EventDeath **************** */
public OnWar3EventDeath( victim, attacker )
{	
	bIsShadowed[victim] = false;
	W3FlashScreen(victim,{0,0,0,0}, _,_,(FFADE_IN|FFADE_PURGE));
	W3ResetPlayerColor(victim, thisRaceID);
	War3_SetBuff(victim,fSlow,thisRaceID,1.0);
		
	if(War3_GetRace(attacker) == thisRaceID && bIsWareWolfActivated[attacker] == true)
	{
		WareWolfTime[attacker] += 100;
		new WareWolfHP = GetClientHealth(attacker)+10;
		new WareWolfMaxHP = War3_GetMaxHP(attacker);
		if(WareWolfHP > WareWolfMaxHP)
		{
			WareWolfMaxHP += WareWolfHP-WareWolfMaxHP;
		}
		War3_SetMaxHP_INTERNAL(attacker, WareWolfMaxHP);
		SetEntityHealth(attacker,WareWolfHP);
		
		PrintHintText(attacker, "You have become stronger and your animal form has been extended.");
		EmitSoundToAllAny(WareWolfFatalitySnd,attacker);
	}
	
	if(War3_GetRace(victim) == thisRaceID)
	{
		bIsBreathActivated[victim] = false;
		for(new i = 1; i <= BreathFireEntCounter[victim]; i++)
		{
			if(IsValidEdict(BreathFireEnt[victim][i]))
			{
				AcceptEntityInput(BreathFireEnt[victim][i], "Kill");
			}
		}		
	}
}

/* *********************** OnW3TakeDmgBulletPre *********************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false))
	{
		if(War3_GetRace(attacker) == thisRaceID && bIsWareWolfActivated[attacker] == true)
		{
			new skill_lvl = War3_GetSkillLevel(attacker,thisRaceID,ULT_WAREWOLF);
			War3_DamageModPercent(WarewolfDMG[skill_lvl]);
			damage *= WarewolfDMG[skill_lvl];
			EmitSoundToAllAny(WareWolfHitSnd,attacker);
		}
	}
}
