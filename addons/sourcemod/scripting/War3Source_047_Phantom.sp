/*
* War3Source Race - Phantom
* 
* File: War3Source_Phantom.sp
* Description: The Phantom race for War3Source.
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Phantom",
	author = "M.A.C.A.B.R.A",
	description = "The Phantom race for War3Source.",
	version = "1.2.0",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_AURA, SKILL_ANATHEMA, SKILL_ESSENCE, ULT_REVENGE;

//Aura
new Float:AuraVisibility[9] =  { 1.0, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.01 };
new bool:AuraDirection[MAXPLAYERS];
new Float:PhantomVisibility[MAXPLAYERS];

//Anathema
new Float:AnathemaChance[9] =  { 0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32 };
new Float:AnathemaTime[9] = {0.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0};
new bool:Anathematized[MAXPLAYERS];
new AnathematizedBy[MAXPLAYERS];
new AnathemaType[MAXPLAYERS];
new BeamSprite,HaloSprite;

// Phantom Essence
new Float:EssenceTime[9] = {0.0, 2.3, 2.6, 2.9, 3.2, 3.5, 3.8, 4.1, 4.5}; 
new EssenceTimeLeft[MAXPLAYERS];
new EssenceCounter[MAXPLAYERS];
new Float:EssenceUsageTime[MAXPLAYERS];
new PhantomWeapons[MAXPLAYERS][10];
new bool:bIsNocliped[MAXPLAYERS];
new bool:bIsStucked[MAXPLAYERS];
new Float:oldpos[MAXPLAYERS][3];
new m_vecBaseVelocity;
new Float:EssenceCooldown[9] = {0.0, 50.0, 47.0, 44.0, 41.0, 38.0, 35.0, 32.0, 30.0};

// Phantom's Revenge
new Sphere[MAXPLAYERS];
new RevengeSphereHP[9] = {0, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900};
new Float:RevengeTime[9] = {0.0, 30.0, 27.5, 25.0, 22.5, 20.0, 17.5, 15.0, 12.5};
new RevengeBoomDMG[][] = {{0,0,0},{20,10,5},{30,15,7},{40,20,10},{50,25,12},{60,30,15},{70,35,17},{80,40,20},{100,50,25}};
new Float:RevengeBoomRadius[][] = {{0.0,0.0,0.0},{100.0,125.0,150.0},{125.0,150.0,175.0},{150.0,175.0,200.0},{175.0,200.0,225.0},{200.0,225.0,250.0},{225.0,250.0,275.0},{250.0,275.0,300.0},{300.0,325.0,350.0},{325.0,350.0,375.0}};
new bool:bRevengeUsed[MAXPLAYERS];
new Float:SpherePosition[MAXPLAYERS][3];
new bool:bIsSphereAlive[MAXPLAYERS];
new Float:BoomSphereRadius[MAXPLAYERS];
new BoomSphereEffectCT, BoomSphereEffectT;
new Glow, Glow2, Glow3, Glow4, Glow5;

new String:MaterializeSnd[]="*mora-wcs/war3source/phantom/materialize.mp3";
new String:MaterializeSnd_FullPath[]="sound/mora-wcs/war3source/phantom/materialize.mp3";
new String:BoomSnd[]="*mora-wcs/war3source/phantom/boom.mp3";
new String:BoomSnd_FullPath[]="sound/mora-wcs/war3source/phantom/boom.mp3";
new String:EssenceSnd[]="*mora-wcs/war3source/phantom/ghost.mp3";
new String:EssenceSnd_FullPath[]="sound/mora-wcs/war3source/phantom/ghost.mp3";
new String:InfectSnd[]="*mora-wcs/war3source/phantom/infect.mp3";
new String:InfectSnd_FullPath[]="sound/mora-wcs/war3source/phantom/infect.mp3";
new String:SlowSnd[]="*mora-wcs/war3source/phantom/slow.mp3";
new String:SlowSnd_FullPath[]="sound/mora-wcs/war3source/phantom/slow.mp3";
new String:ShockSnd[]="*mora-wcs/war3source/phantom/shock.mp3";
new String:ShockSnd_FullPath[]="sound/mora-wcs/war3source/phantom/shock.mp3";
new String:DemonsSnd[]="*mora-wcs/war3source/phantom/demons.mp3";
new String:DemonsSnd_FullPath[]="sound/mora-wcs/war3source/phantom/demons.mp3";


/* **************** OnWar3PluginReady **************** */
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==470){
	thisRaceID=War3_CreateNewRace("Phantom","phantom");
	
	SKILL_AURA=War3_AddRaceSkill(thisRaceID,"Ghostly Aura","Makes your visibility pulsating (passive)",false,8);
	SKILL_ANATHEMA=War3_AddRaceSkill(thisRaceID,"Anathema","You can push enemies under the influence of your Anathemas. (attack)",false,8); 
	SKILL_ESSENCE=War3_AddRaceSkill(thisRaceID,"Phantom Essence","Concentration of energy allows you to change your form of being and to walk through the objects. (+ability)",false,8);
	ULT_REVENGE=War3_AddRaceSkill(thisRaceID,"Phantom's Revenge","Condensed energy allows you to avenge your death. (death)",true,8);
	
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_ESSENCE, 30.0, _ );
	War3_CreateRaceEnd(thisRaceID);
	}
}

/* **************** OnMapStart **************** */
public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/effects/phantomvision.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/phantomvision.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_blueball.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_blueball.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_redball.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_redball.vmt");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.mdl");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.phy");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.dx90.vtx");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.dx80.vtx");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.sw.vtx");
	AddFileToDownloadsTable("models/mora-wcs/props/war3source/phantom/roller_spikes.vvd");
	
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud1b.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud2b.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers1b.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers2b.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers3b.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud1b.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud2b.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers1b.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers2b.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fire_embers3b.vtf");
	
	AddFileToDownloadsTable(MaterializeSnd_FullPath);
	AddFileToDownloadsTable(BoomSnd_FullPath);
	AddFileToDownloadsTable(EssenceSnd_FullPath);
	AddFileToDownloadsTable(InfectSnd_FullPath);
	AddFileToDownloadsTable(SlowSnd_FullPath);
	AddFileToDownloadsTable(ShockSnd_FullPath);
	AddFileToDownloadsTable(DemonsSnd_FullPath);
	
	PrecacheModel("materials/mora-wcs/effects/phantomvision.vmt"); // Phantom Essence effect
	PrecacheModel("models/mora-wcs/props/war3source/phantom/roller_spikes.mdl"); // Phantoms Revenge effects
	BoomSphereEffectCT=PrecacheModel("materials/mora-wcs/effects/strider_blueball.vmt");
	BoomSphereEffectT=PrecacheModel("materials/mora-wcs/effects/strider_redball.vmt");
	Glow=PrecacheModel("materials/mora-wcs/effects/fire_cloud1b.vmt"); 
	Glow2=PrecacheModel("materials/mora-wcs/effects/fire_cloud2b.vmt");
	Glow3=PrecacheModel("materials/mora-wcs/effects/fire_embers1b.vmt");
	Glow4=PrecacheModel("materials/mora-wcs/effects/fire_embers2b.vmt");
	Glow5=PrecacheModel("materials/mora-wcs/effects/fire_embers3b.vmt");
	BeamSprite=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/mora-wcs/sprites/halo01.vmt");
	
	//Sounds
	PrecacheSoundAny(EssenceSnd);
	PrecacheSoundAny(BoomSnd);
	PrecacheSoundAny(MaterializeSnd);
	PrecacheSoundAny(InfectSnd);
	PrecacheSoundAny(SlowSnd);
	PrecacheSoundAny(ShockSnd);
	PrecacheSoundAny(DemonsSnd);
}

/* **************** OnPluginStart **************** */
public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("round_start", RoundStartEvent);
	CreateTimer( 0.1, CalcAura, _, TIMER_REPEAT );
}

/* **************** OnRaceChanged **************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff(client,bNoClipMode,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		ClientCommand(client, "r_screenoverlay 0");
	}
}

/* **************** RoundStartEvent **************** */
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				EssenceCounter[i] = 0;
				EssenceTimeLeft[i] = 0;
				PhantomVisibility[i] = GetRandomFloat(AuraVisibility[War3_GetSkillLevel(i, thisRaceID, SKILL_AURA )],1.0);
				AuraDirection[i] = true;
				bIsNocliped[i] = false;
				bIsStucked[i] = false;
				War3_WeaponRestrictTo( i, thisRaceID, "" );
				War3_SetBuff(i,bNoClipMode,thisRaceID,false);
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0);
				ClientCommand(i, "r_screenoverlay 0");
			
				bIsSphereAlive[i] = false;
				bRevengeUsed[i] = false;
				BoomSphereRadius[i] = 0.5;
			}
			Anathematized[i] = false;
			AnathematizedBy[i] = -1;
			AnathemaType[i] = 0;
		}
	}
}

/* **************** OnWar3EventSpawn **************** */
public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		EssenceCounter[client] = 0;
		EssenceTimeLeft[client] = 0;
		PhantomVisibility[client] = GetRandomFloat(AuraVisibility[War3_GetSkillLevel(client, thisRaceID, SKILL_AURA )],1.0);
		AuraDirection[client] = true;
		bIsNocliped[client] = false;
		bIsStucked[client] = false;
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff(client,bNoClipMode,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		ClientCommand(client, "r_screenoverlay 0");
		
		bIsSphereAlive[client] = false;
		BoomSphereRadius[client] = 0.5;
		
		Anathematized[client] = false;
		AnathematizedBy[client] = -1;
		AnathemaType[client] = 0;
	}
}

/* *************************************** Ghostly Aura *************************************** */
/* **************** CalcAura **************** */
public Action:CalcAura( Handle:timer, any:userid )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Aura(i);
			}		
		}
	}	
}

/* **************** Aura **************** */
public Aura(any:client)
{
	new skill_lvl = War3_GetSkillLevel(client, thisRaceID, SKILL_AURA );
	if(skill_lvl > 0)
	{
		if(AuraDirection[client] == true)
		{
			if(PhantomVisibility[client] > AuraVisibility[skill_lvl])
			{
				PhantomVisibility[client] -= 0.01;
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,PhantomVisibility[client]);
			}
			else
			{
				AuraDirection[client] = false;
			}
		}
		else
		{
			if(PhantomVisibility[client] < AuraVisibility[0])
			{
				PhantomVisibility[client] += 0.01;
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,PhantomVisibility[client]);
			}
			else
			{
				AuraDirection[client] = true;
			}
		}
	}	
}


/* *************************************** Anathema *************************************** */
/* **************** OnWar3EventPostHurt **************** */
public OnWar3EventPostHurt( victim, attacker, Float:damage )
{
	if(ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_lvl = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ANATHEMA );
			if( !Hexed( attacker, false ) && Anathematized[victim] == false && skill_lvl  > 0 )
			{
				if(GetRandomFloat( 0.0, 1.0 ) <= AnathemaChance[skill_lvl ] && !W3HasImmunity( victim, Immunity_Skills ))
				{
					Anathema(victim, attacker, skill_lvl);
				}
			}
		}
	}
}

/* **************** Anathema **************** */
public Anathema(any:victim,any:client,any:skill_lvl)
{
	new ActiveAnathema  = GetRandomInt(1, skill_lvl);
	new String:NameVictim[64];
	GetClientName(victim, NameVictim, 64 );
	
	Anathematized[victim] = true;
	AnathematizedBy[victim] = client;
	
	new Float:start_pos[3];
	new Float:target_pos[3];
	
	GetClientAbsOrigin( client, start_pos );
	GetClientAbsOrigin( victim, target_pos );
	
	start_pos[2] += 40;
	target_pos[2] += 40;
	
	switch(ActiveAnathema)
	{
		case 1: // Fire
		{
			AnathemaType[victim] = 1;
			PrintHintText(client, "You've set %s on fire",NameVictim);
			PrintHintText(victim, "Phantom's Anathema has reached you. You've been set on fire.");
			
			TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {255,0,0,155}, 70 ); // czerwony
			TE_SendToAll();
			
			IgniteEntity(victim, AnathemaTime[skill_lvl]);
			CreateTimer(AnathemaTime[skill_lvl],StopFire,victim);
		}
		case 2: // Infect
		{
			AnathemaType[victim] = 2;
			PrintHintText(client, "You've infected %s",NameVictim);
			PrintHintText(victim, "Phantom's Anathema has reached you. You've been infected.");
			EmitSoundToAllAny(InfectSnd,client);
			EmitSoundToAllAny(InfectSnd,victim);
			
			TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, { 0, 255, 50, 255 }, 70 ); // zielony
			TE_SendToAll();
			
			CreateTimer(AnathemaTime[skill_lvl],StopInfect,victim);
			CreateTimer(1.0,Infect,victim,TIMER_REPEAT);
		}
		case 3: // Slow
		{
			AnathemaType[victim] = 3;
			PrintHintText(client, "You've slowed %s ",NameVictim);
			PrintHintText(victim, "Phantom's Anathema has reached you. You've been slowed.");
			EmitSoundToAllAny(SlowSnd,client);
			EmitSoundToAllAny(SlowSnd,victim);

			TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, { 255,255, 0, 255 }, 70 ); // zó³ty
			TE_SendToAll();
			
			War3_SetBuff(victim,fSlow,thisRaceID,0.75);
			CreateTimer(AnathemaTime[skill_lvl],StopSlow,victim);
		}
		case 4: //Shock
		{
			AnathemaType[victim] = 4;
			PrintHintText(client, "You've cought %s into electric field.",NameVictim);
			PrintHintText(victim, "Phantom's Anathema has reached you. You've been cought into electric field.");
			EmitSoundToAllAny(ShockSnd,client);
			EmitSoundToAllAny(ShockSnd,victim);
			
			TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {30,100,255,255}, 70); // niebieski
			TE_SendToAll();
			
			CreateTimer(AnathemaTime[skill_lvl],StopShock,victim);
			CreateTimer(1.0,Shock,victim,TIMER_REPEAT);
		}
		case 5: // Demons
		{
			AnathemaType[victim] = 5;
			PrintHintText(client, "You've pushed %s under the influence of demons.",NameVictim);
			PrintHintText(victim, "Phantom's Anathema has reached you. You've been pushed under the influence of demons.");
			EmitSoundToAllAny(DemonsSnd,client);
			EmitSoundToAllAny(DemonsSnd,victim);
			
			TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, { 155, 155, 155, 255 }, 70 ); // bia³y
			TE_SendToAll();
			
			CreateTimer(AnathemaTime[skill_lvl],StopDemons,victim);
			CreateTimer(1.0,Demons,victim,TIMER_REPEAT);	
		}
	}	
}

/* **************** StopFire **************** */
public Action:StopFire(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 1)
		{
			Anathematized[client] = false;
			AnathemaType[client] = 0;
			PrintHintText(client, "You have broken free from the influence of Phantom's Anathema.");
		}
	}
}

/* **************** StopInfect **************** */
public Action:StopInfect(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 2)
		{
			Anathematized[client] = false;
			AnathemaType[client] = 0;
			PrintHintText(client, "You have broken free from the influence of Phantom's Anathema.");
		}
	}
}

/* **************** Infect **************** */
public Action:Infect(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 2)
		{
			War3_DealDamage(client,2,AnathematizedBy[client],_,"anathemapoison",_,W3DMGTYPE_MAGIC);
		}
		else
		{
			KillTimer(t);
		}
	}
}

/* **************** StopSlow **************** */
public Action:StopSlow(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 3)
		{
			Anathematized[client] = false;
			AnathemaType[client] = 0;
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			PrintHintText(client, "You have broken free from the influence of Phantom's Anathema.");
		}
	}
}

/* **************** StopShock **************** */
public Action:StopShock(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 4)
		{
			Anathematized[client] = false;
			AnathemaType[client] = 0;
			PrintHintText(client, "You have broken free from the influence of Phantom's Anathema.");
		}
	}
}

/* **************** Shock **************** */
public Action:Shock(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 4)
		{
			EmitSoundToAllAny(ShockSnd,client);
			War3_DealDamage(client,3,AnathematizedBy[client],_,"anathemashock",_,W3DMGTYPE_MAGIC);
		}
		else
		{
			KillTimer(t);
		}
	}
}

/* **************** StopDemons **************** */
public Action:StopDemons(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 5)
		{
			Anathematized[client] = false;
			AnathemaType[client] = 0;
			PrintHintText(client, "You have broken free from the influence of Phantom's Anathema.");
		}
	}
}

/* **************** Demons **************** */
public Action:Demons(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(Anathematized[client] == true && AnathemaType[client] == 5)
		{
			War3_DealDamage(client,5,AnathematizedBy[client],_,"anathemademons",_,W3DMGTYPE_TRUEDMG);
		}
		else
		{
			KillTimer(t);
		}
	}
}


/* *************************************** Phantom Essence *************************************** */
/* **************** OnAbilityCommand **************** */
public OnAbilityCommand(client,ability,bool:pressed)
{		
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_ESSENCE);
		if(skill_lvl > 0)
		{	
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_ESSENCE,true ))
			{
				if(bIsNocliped[client] == false)
				{					
					for(new slot=0; slot<10; slot++) // Bronie
					{
						PhantomWeapons[client][slot] = GetPlayerWeaponSlot(client,slot);
						if(PhantomWeapons[client][slot] != -1)
						{
							if(slot == 4)
							{
								CS_DropWeapon(client, PhantomWeapons[client][slot], true, true );
								PhantomWeapons[client][slot] = -1;
							}
							else
							{
								RemovePlayerItem(client,PhantomWeapons[client][slot]);
							}
						}
					}
					War3_WeaponRestrictTo( client, thisRaceID, "Phantom_Essence" );
					
					EssenceTimeLeft[client] = RoundToZero(EssenceTime[skill_lvl]);
					EssenceCounter[client] = 0;
					War3_SetBuff(client,bNoClipMode,thisRaceID,true);			
					ClientCommand(client, "r_screenoverlay effects/phantomvision");
					PrintHintText(client, "You feel an energy of Phantom Essence");
					W3Hint(client,HINT_LOWEST,1.0,"Phantom Essence Time Left: %d",EssenceTimeLeft[client]);
					EmitSoundToAllAny(EssenceSnd,client); 
					EssenceUsageTime[client] = EssenceTime[skill_lvl];
					bIsNocliped[client] = true;
					CreateTimer(0.1,stopPhantom,client,TIMER_REPEAT);
				}
				else
				{					
					War3_WeaponRestrictTo( client, thisRaceID, "" ); // Bronie					
					for(new slot=0; slot<10; slot++)
					{
						if(PhantomWeapons[client][slot] != -1)
						{
							EquipPlayerWeapon(client,PhantomWeapons[client][slot]);						
						}
					}
					
					EssenceCounter[client] = 0;
					EssenceTimeLeft[client] = 0;
					War3_SetBuff(client,bNoClipMode,thisRaceID,false);
					ClientCommand(client, "r_screenoverlay 0");
					EmitSoundToAllAny(EssenceSnd,client);
					bIsNocliped[client] = false;
					CreateTimer(0.1,StuckCheck,client);
					War3_CooldownMGR(client,EssenceCooldown[skill_lvl],thisRaceID,SKILL_ESSENCE,_,_);
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Phantom Essence first");
		}
	}
}

/* **************** stopPhantom **************** */
public Action:stopPhantom(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(bIsNocliped[client] == true)
		{
			if(EssenceUsageTime[client] > 0.1)
			{
				EssenceUsageTime[client] -= 0.1;
				EssenceCounter[client]++;
				if(EssenceCounter[client] == 10)
				{
					EssenceCounter[client] = 0;
					EssenceTimeLeft[client]--;
					W3Hint(client,HINT_LOWEST,1.0,"Phantom Essence Time Left: %d",EssenceTimeLeft[client]);
				}
			}
			else
			{				
				War3_WeaponRestrictTo( client, thisRaceID, "" ); // Bronie
				EssenceCounter[client] = 0;
				EssenceTimeLeft[client] = 0;
				War3_SetBuff(client,bNoClipMode,thisRaceID,false);
				ClientCommand(client, "r_screenoverlay 0");
				EmitSoundToAllAny(EssenceSnd,client);
				bIsNocliped[client] = false;
				CreateTimer(0.1,StuckCheck,client);
				War3_CooldownMGR(client,EssenceCooldown[War3_GetSkillLevel(client,thisRaceID,SKILL_ESSENCE)],thisRaceID,SKILL_ESSENCE,_,_);
			}
		}
		else
		{			
			KillTimer(t);
		}
	}
}

/* **************** StuckCheck **************** */
public Action:StuckCheck(Handle:t,any:client)
{
	new Float:velocity[3];
	velocity[0] = 50.0;
	velocity[1] = 50.0;
	velocity[2] = 0.0;
	GetClientAbsOrigin(client,oldpos[client]);
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	
	new Float:newpos[3];
	GetClientAbsOrigin(client,newpos);
	
	CreateTimer(0.1, FinalCheck, client);
	CreateTimer(0.5, WeaponsBack, client);
}

/* **************** FinalCheck **************** */
public Action:FinalCheck(Handle:timer,any:client)
{
	new Float:newpos[3];
	GetClientAbsOrigin(client,newpos);
	
	if(GetVectorDistance(newpos,oldpos[client])<0.01)
	{
		bIsStucked[client] = true;
		PrintHintText(client, "You have stucked.");
		War3_DealDamage(client,99999,_,_,"sciana",_,W3DMGTYPE_TRUEDMG);
	}
	else
	{
		PrintHintText(client, "You feel sudden outflow of energy.");
	}
}

public Action:WeaponsBack(Handle:timer,any:client)
{
	for(new slot=0; slot<10; slot++)
	{
		if(PhantomWeapons[client][slot] != -1)
		{
			EquipPlayerWeapon(client,PhantomWeapons[client][slot]);						
		}
	}
}

/* *************************************** Phantom's Revenge *************************************** */
/* **************** OnWar3EventDeath **************** */
public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	Anathematized[victim] = false;
	AnathematizedBy[victim] = -1;
	AnathemaType[victim] = 0;
	
	if(War3_GetRace(victim) == thisRaceID && bRevengeUsed[victim] == false)
	{
		new ult_level = War3_GetSkillLevel( victim, thisRaceID, ULT_REVENGE );
		if( ult_level > 0  && bIsStucked[victim] == false)
		{
			PhantomVisibility[victim] = GetRandomFloat(AuraVisibility[War3_GetSkillLevel(victim, thisRaceID, SKILL_AURA )],1.0);
			AuraDirection[victim] = true;
			bIsNocliped[victim] = false;
			bIsStucked[victim] = false;
			War3_WeaponRestrictTo(victim, thisRaceID, "" );
			War3_SetBuff(victim,bNoClipMode,thisRaceID,false);
			ClientCommand(victim, "r_screenoverlay 0");
			
			GetClientAbsOrigin(victim,SpherePosition[victim]);
			
			Sphere[victim] = CreateEntityByName("prop_physics_override");
			if (Sphere[victim] > 0 && IsValidEntity(Sphere[victim]))
			{
				decl String:entname[16];
				Format(entname, sizeof(entname), "sphere%i",victim);
				SetEntityModel(Sphere[victim], "models/mora-wcs/props/war3source/phantom/roller_spikes.mdl");	
				ActivateEntity(Sphere[victim]);
				DispatchKeyValue(Sphere[victim], "StartDisabled", "false");
				DispatchKeyValue(Sphere[victim], "targetname", entname);
				DispatchSpawn(Sphere[victim]);				
				DispatchKeyValue(Sphere[victim], "disablereceiveshadows", "1");
				DispatchKeyValue(Sphere[victim], "disableshadows", "1");																	
				SetEntProp(Sphere[victim], Prop_Data, "m_nSolidType", 6);
				SetEntProp(Sphere[victim], Prop_Data, "m_CollisionGroup", 6);
				SetEntProp(Sphere[victim], Prop_Data, "m_usSolidFlags", 5);				
				SetEntityMoveType(Sphere[victim], MOVETYPE_NONE);
				SetEntProp(Sphere[victim], Prop_Data, "m_takedamage", 2);
				SetEntProp(Sphere[victim], Prop_Data, "m_iHealth", RevengeSphereHP[ult_level]);
				SetEntityFlags(Sphere[victim], 18);
				
				if(GetClientTeam(victim) == 3) 
				{
					SetEntityRenderColor(Sphere[victim], 105, 105, 190, 155);
				}
				else 
				{
					SetEntityRenderColor(Sphere[victim], 255, 0, 0, 155);
				}				
				AcceptEntityInput(Sphere[victim], "DisableMotion");
				TeleportEntity(Sphere[victim], SpherePosition[victim], NULL_VECTOR, NULL_VECTOR);
				
				bIsSphereAlive[victim] = true;
				EmitSoundToAllAny(MaterializeSnd,victim);
				PrintHintText(victim, "You are condensing energy to prepare your Revenge!");	
				CreateTimer( 0.1, SphereCheck, victim,TIMER_REPEAT);					
				CreateTimer( RevengeTime[ult_level]-1, SpawnPlayer, victim );
			}
		}
	}
}

/* **************** SpawnPlayer **************** */
public Action:SpawnPlayer( Handle:timer, any:client )
{
	if( ValidPlayer( client, false ) )
	{
		if(bIsSphereAlive[client] == true)
		{
			CreateTimer(0.05, BoomSphere, client, TIMER_REPEAT);
		}
	}
}

/* **************** BoomSphere **************** */
public Action:BoomSphere( Handle:timer, any:client )
{
	if( ValidPlayer( client, false ) )
	{
		if(bIsSphereAlive[client] == true)
		{
			if(BoomSphereRadius[client] <= 10)
			{
				if(GetClientTeam(client) == 3)
				{
					TE_SetupGlowSprite( SpherePosition[client], BoomSphereEffectCT, 0.06, BoomSphereRadius[client], 255 );
					TE_SendToAll();
					BoomSphereRadius[client] += 0.5;
				}
				else
				{
					TE_SetupGlowSprite( SpherePosition[client], BoomSphereEffectT, 0.06, BoomSphereRadius[client], 255 );
					TE_SendToAll();
					BoomSphereRadius[client] += 0.5;
				}
			}
			else
			{
				TE_SetupGlowSprite(SpherePosition[client],Glow,2.0,1.0,255);
				TE_SendToAll();				
				TE_SetupGlowSprite(SpherePosition[client],Glow2,2.0,1.0,255);
				TE_SendToAll();
				TE_SetupGlowSprite(SpherePosition[client],Glow3,2.0,1.0,255);
				TE_SendToAll();				
				TE_SetupGlowSprite(SpherePosition[client],Glow4,2.0,1.0,255);
				TE_SendToAll();				
				TE_SetupGlowSprite(SpherePosition[client],Glow5,1.0,1.0,255);
				TE_SendToAll();
				
				new skill_lvl = War3_GetSkillLevel(client,thisRaceID,ULT_REVENGE);
				
				new Float:VictimPos[3];
				for( new i = 1; i <= MaxClients; i++ )
				{
					if( ValidPlayer( i, true ) && !W3HasImmunity( i, Immunity_Ultimates ))
					{
						GetClientAbsOrigin( i, VictimPos );
						new Float:distance = GetVectorDistance( SpherePosition[client], VictimPos);
						if(distance <= RevengeBoomRadius[skill_lvl][0])
						{
							War3_DealDamage(i,RevengeBoomDMG[skill_lvl][0],client,_,"phantomssphere",_,W3DMGTYPE_TRUEDMG);
						}
						else if(distance > RevengeBoomRadius[skill_lvl][0] && distance <= RevengeBoomRadius[skill_lvl][1])
						{
							War3_DealDamage(i,RevengeBoomDMG[skill_lvl][1],client,_,"phantomssphere",_,W3DMGTYPE_TRUEDMG);
						}							
						else if(distance > RevengeBoomRadius[skill_lvl][1] && distance <= RevengeBoomRadius[skill_lvl][2])
						{
							War3_DealDamage(i,RevengeBoomDMG[skill_lvl][2],client,_,"phantomssphere",_,W3DMGTYPE_TRUEDMG);
						}
					}
				}
				
				AcceptEntityInput(Sphere[client], "Kill");
				bIsSphereAlive[client] = false;			 
				War3_SpawnPlayer(client);
				TeleportEntity(client, SpherePosition[client], NULL_VECTOR, NULL_VECTOR);
				bRevengeUsed[client] = true;
				
				EmitSoundToAllAny(BoomSnd,client); 
				PrintHintText(client, "You have come back to avenge your death!");	
				
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
		KillTimer(timer);
	}
}

/* **************** SphereCheck **************** */
public Action:SphereCheck( Handle:timer, any:client )
{
	if(!IsValidEdict(Sphere[client]))
	{
		bIsSphereAlive[client] = false;	
		KillTimer(timer);
	}
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(IsValidEdict(Sphere[client]))
			{
				AcceptEntityInput(Sphere[client], "Kill");
				bIsSphereAlive[client] = false;
				KillTimer(timer);
			}
			else
			{
				bIsSphereAlive[client] = false;
				KillTimer(timer);
			}			
		}
	}
	else
	{
		if(IsValidEdict(Sphere[client]))
		{
			AcceptEntityInput(Sphere[client], "Kill");
			bIsSphereAlive[client] = false;
			KillTimer(timer);
		}
		else
		{
			bIsSphereAlive[client] = false;
			KillTimer(timer);
		}	
	}
}