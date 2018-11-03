 /**
* File: War3Source_NagaSeaWitch.sp
* Description: The Naga Sea Witch unit for War3Source.
* Author(s): [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new thisRaceID;

//new Handle:ultCooldownCvar;

//skill 1
new String:lightningSound[]="*mora-wcs/war3source/lightningbolt.mp3";
new String:lightningSound_FullPath[]="sound/mora-wcs/war3source/lightningbolt.mp3";
new bool:bForked[66];
new ForkedDamage[9]={0, 11, 13, 15, 17, 19, 21, 23, 25};

//skill 2
new Float:FrostArrow[9]={0.00,0.70,0.65,0.60,0.55,0.50,0.45,0.40,0.35};

//skill 3
new ShieldSprite;
new bool:bMShield[66];
new MoneyOffsetCS;
new MSmultiplier[9]={0,100,95,90,85,80,75,70,65};
new Float:MSreducer[9]={0.0,0.80, 0.70, 0.60, 0.50, 0.40, 0.30, 0.20, 0.10};

//skill 4
new m_vecBaseVelocity; //offsets
new TornadoSprite;
new String:Tornado[]="*mora-wcs/ambient/wind_moan1.mp3";
new String:Tornado_FullPath[]="sound/mora-wcs/ambient/wind_moan1.mp3";
new String:ShieldSprite_FullPath[] = "materials/mora-wcs/sprites/m_blackball.vmt";
new String:ShieldSpriteVTF_FullPath[] = "materials/mora-wcs/sprites/m_blackball.vtf";
new Float:Cooldown[9]={0.0, 30.0, 29.0, 28.0, 27.0, 26.0, 25.0, 24.0, 23.0};


new SKILL_FORKED, SKILL_FROSTARROW, SKILL_MANASHIELD, ULT_TORNADO;
new SpawnVMT;

public Plugin:myinfo = 
{
	name = "War3Source Race - Naga Sea Witch",
	author = "[Oddity]TeacherCreature",
	description = "The Naga Sea Witch race for War3Source.",
	version = "1.0.6.3",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	CreateTimer(1.0,mana,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	//ultCooldownCvar=CreateConVar("war3_naga_tornado_cooldown","30.0","Cooldown for Tornado");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==310)
	{
		thisRaceID=War3_CreateNewRace("Naga Sea Witch ","naga");
		SKILL_FORKED=War3_AddRaceSkill(thisRaceID,"Forked Lightning(+ability)","Target up to 3 people in your view",false,8);
		SKILL_FROSTARROW=War3_AddRaceSkill(thisRaceID,"Frost Arrows(attack)","Adds cold attack to arrows",false,8);
		SKILL_MANASHIELD=War3_AddRaceSkill(thisRaceID,"Mana Shield(+ability1)","Absorb all damage for mana (toggle on/off)",false,8);
		ULT_TORNADO=War3_AddRaceSkill(thisRaceID,"Tornado","Summon a tornado to attack enemies",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_ssg08");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client, "weapon_ssg08");
		}
	}
}

public OnMapStart()
{
	AddFileToDownloadsTable(Tornado_FullPath);
	AddFileToDownloadsTable(lightningSound_FullPath);
	AddFileToDownloadsTable(ShieldSprite_FullPath);
	AddFileToDownloadsTable(ShieldSpriteVTF_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blueglow2.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blueglow2.vtf");
	
	ShieldSprite=PrecacheModel("materials/mora-wcs/sprites/m_blackball.vmt");
	TornadoSprite=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	SpawnVMT = PrecacheModel("materials/mora-wcs/sprites/blueglow2.vmt");
	
	PrecacheSoundAny(Tornado);
	PrecacheSoundAny(lightningSound);

}

public OnWar3EventDeath(victim,attacker)
{
	new race=War3_GetRace(victim);
	if(race==thisRaceID)
	{
		SetMoney(victim,0);
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		new Float:Pos[3];
		GetClientAbsOrigin(client,Pos);
		GivePlayerItem(client, "weapon_ssg08");
		TE_SetupBeamRingPoint(Pos,200.0,325.0,SpawnVMT,0,0,0,5.0,399.0,0.0,{0, 153, 204,255},10,0);
		TE_SendToAll();
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i)&&War3_GetRace(i)==thisRaceID)
		{
			new skill=War3_GetSkillLevel(i,thisRaceID,SKILL_MANASHIELD);
			if(skill>0)
			{
				bMShield[i]=false;
			}
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTARROW);
			// Frost Arrow
			if(race_attacker==thisRaceID && skill_level>0 && !Silenced(attacker))
			{
				if(!Silenced(attacker)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_FROSTARROW) && !W3HasImmunity(victim,Immunity_Skills))
				{
					War3_CooldownMGR(attacker,5.0,thisRaceID,SKILL_FROSTARROW,_,_);
					War3_SetBuff(victim,fSlow,thisRaceID,FrostArrow[skill_level]);
					War3_SetBuff(victim,fAttackSpeed,thisRaceID,FrostArrow[skill_level]);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					CreateTimer(1.5,unfrost,victim);
					PrintHintText(attacker,"Frost Arrow!");
					PrintHintText(victim,"You have been hit by a Frost Arrow");
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			if(race_victim==thisRaceID && bMShield[victim])
			{	
				new Float:pos[3];
				GetClientAbsOrigin(victim,pos);
				pos[2]+=35;
				TE_SetupGlowSprite(pos, ShieldSprite, 0.1, 1.0, 130);
				TE_SendToAll(); 
				new skill_mana=War3_GetSkillLevel(victim,thisRaceID,SKILL_MANASHIELD);
				new money=GetMoney(victim);
				new ddamage=RoundFloat(damage*MSmultiplier[skill_mana]);
				if(money>=ddamage)
				{
					War3_DamageModPercent(0.0);
					new new_money;
					new_money=money-ddamage;
					SetMoney(victim,new_money);
				}
				else
				{
					War3_DamageModPercent(MSreducer[skill_mana]);
					bMShield[victim]=false;
					PrintHintText(victim,"Mana Shield: Depleted!");
				}
			}
		}
	}
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

public Action:unfrost(Handle:timer,any:client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

public bool:TargetCheck(client)
{
	if(bForked[client]||W3HasImmunity(client,Immunity_Skills))
	{
		return false;
	}
	return true;
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FORKED);
			if(skill_level>0)
			{
				if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_FORKED,true))
				{
					new targets;
					new targetlist[3];
					for(new i=0;i<3;i++){
						new target = War3_GetTargetInViewCone(client,800.0,false,23.0,TargetCheck);
						new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_FORKED);
						if(target>0&&!W3HasImmunity(target,Immunity_Skills))
						{
							bForked[target]=true;
							new Float:start_pos[3];
							GetClientAbsOrigin(client,start_pos);
							War3_DealDamage(target,ForkedDamage[skill],client,DMG_ENERGYBEAM,"chainlightning");
							PrintHintText(target,"Hit by Forked Lightning -%d HP",War3_GetWar3DamageDealt());
							new Float:target_pos[3];
							GetClientAbsOrigin(target,target_pos);
							start_pos[1]+=60.0;
							start_pos[2]+=60.0;
							target_pos[2] += 30.0;
							TE_SetupBeamPoints(start_pos, target_pos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60); 
							TE_SendToAll();
							start_pos[1]-=120.0;
							TE_SetupBeamPoints(start_pos, target_pos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60);
							TE_SendToAll();
							
							W3SetPlayerColor(target,thisRaceID, 0, 102, 204,255,GLOW_SKILL);
							CreateTimer(4.0, ColorCalc, target);
							
							//target_pos[2]+=30.0;
							//TE_SetupBeamPoints(start_pos,target_pos,TornadoSprite,TornadoSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
							//TE_SendToAll();
							EmitSoundToAllAny( lightningSound , target,_,SNDLEVEL_TRAIN);
							War3_CooldownMGR(client,11.0,thisRaceID,SKILL_FORKED,_,_);
							targetlist[targets]=target;
							targets++;
						}
					}
					if(targets==0){
						PrintHintText(client,"NO VALID TARGETS WITHIN %.1f FEET",80.0);
					}
					for(new i=0;i<3;i++){
						bForked[targetlist[i]]=false;
					}
				}
			}
			else
			{
				PrintHintText(client,"Level Forked Lightning First");
			}
		}
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
		{	
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_MANASHIELD);
			if(skill_level>0)
			{
				if(bMShield[client]==true)
				{
					PrintHintText(client,"Mana Shield: Deactivated");
					bMShield[client]=false;
				}
				else
				{
					PrintHintText(client,"Mana Shield: Activated");
					CreateTimer(1.2,shieldsoundloop,client);
					bMShield[client]=true;
				}
			}
		}
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
	}
}
public Action:ColorCalc(Handle:timer,any:client)
{
	 W3ResetPlayerColor(client,thisRaceID);
}

public Action:shieldsoundloop(Handle:timer,any:client)
{
	
}

public Action:mana(Handle:timer,any:client)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					if(!bMShield[i])
					{
						new money=GetMoney(i);
						if(money<16000)
						{
							SetMoney(i,money+200);
						}
					}
					if(bMShield[i])
					{
						new money=GetMoney(i);
						if(money>100)
						{
							SetMoney(i,money-100);
						}
						else
						{
							bMShield[i]=false;
							PrintHintText(i,"Mana Shield: Out of mana");
						}
					}
				}
			}
		}
	}
}



public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_TORNADO);
		if(ult_level>0)		
		{
			new target = War3_GetTargetInViewCone(client,300.0,false,20.0);
			if(target>0&&!W3HasImmunity(target,Immunity_Ultimates))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TORNADO,true)) 
				{
					if(!Silenced(client))
					{
						new Float:pos[3];
						new Float:lookpos[3];
						War3_GetAimEndPoint(client,lookpos);
						GetClientAbsOrigin(client,pos);
						pos[1]+=60.0;
						pos[2]+=60.0;
						TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60); 
						TE_SendToAll();
						pos[1]-=120.0;
						TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60);
						TE_SendToAll();
						new Float:targpos[3];
						GetClientAbsOrigin(target,targpos);
						TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 60.0, 120.0,TornadoSprite,TornadoSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 80.0, 140.0,TornadoSprite,TornadoSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 100.0, 160.0,TornadoSprite,TornadoSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 120.0, 180.0,TornadoSprite,TornadoSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 140.0, 200.0,TornadoSprite,TornadoSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 160.0, 220.0,TornadoSprite,TornadoSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 180.0, 240.0,TornadoSprite,TornadoSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						EmitSoundToAllAny(Tornado,client);
						EmitSoundToAllAny(Tornado,target);
						new Float:velocity[3];
						velocity[2]+=800.0;
						SetEntDataVector(target,m_vecBaseVelocity,velocity,true);
						CreateTimer(0.1,nado1,target);
						CreateTimer(0.4,nado2,target);
						CreateTimer(0.9,nado3,target);
						CreateTimer(1.4,nado4,target);
						War3_DealDamage(target,50,client,DMG_GENERIC,"Tornado");
						War3_CooldownMGR(client,Cooldown[ult_level],thisRaceID,ULT_TORNADO,_,_);
					}
					else
					{
						PrintHintText(client,"Silenced: Can not cast");
					}
				}
			}
			else
			{
				PrintHintText(client,"NO VALID TARGETS WITHIN %.1f FEET",30.0);
			}
		}
		else
		{
			PrintHintText(client,"Level Tornado First");
		}
	}
}

public Action:nado1(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
public Action:nado2(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado3(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado4(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
