 /**
* File: War3Source_TrollBatRider.sp
* Description: The Troll Bat Rider race for War3Source.
* Author(s): [Oddity]TeacherCreature
* Reupdated for b7
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
new Handle:FriendlyFireConcoctionCvar;
new Handle:ConcoctionDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bConcocted[65];
new String:explosionSound1[]="*mora-wcs/war3source/particle_suck1.mp3";
new String:ExpSnd_FullPath[]="sound/mora-wcs/weapons/morabotti/explode1.mp3";
new String:ExpSnd_FullPath2[]="sound/mora-wcs/weapons/morabotti/explode5.mp3";
new String:explosionSound1_FullPath[]="sound/mora-wcs/war3source/particle_suck1.mp3";

new BeamSprite;
new HaloSprite;

//skill 1
new RegenAmountArr[]={0,1,1,2,2,3,3,4,5};

//skill 2
//new Float:ArcaniteDamagePercent[9]={0.0,0.2,0.22,0.24,0.26,0.28,0.30,0.32,0.35};
new ArcaniteDamageMin[9]={0,10,15,20,25,30,35,40};
new ArcaniteDamageMax[9]={0, 15, 20,30,35,40,45,50};

new Float:ArcaniteChance[9]={0.0,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65};
//skill 3
new Float:LiquidFireArr[9]={1.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0};

//skill 4
new Float:ConcoctionRadius[]={0.0,280.0,290.0,300.0,310.0,320.0,330.0,340.0,350.0}; 
new Float:ConcoctionDamage[9]={0.0,60.0,80.0,100.0,120.0,140.0,160.0,180.0,200.0};
new Float:ConcoctionDamageTF[]={0.0,180.0,190.0,200.0,210.0,220.0,230.0,240.0,250.0};
new Float:ConcoctionLocation[MAXPLAYERS][3];
new SKILL_FLY;
new SKILL_REGEN, SKILL_ARCANITE, SKILL_LIQUIDFIRE, ULT_CONCOCTION;
new explosion;
new bool:bModeFlyOn[MAXPLAYERS];
public Plugin:myinfo = 
{
	name = "War3Source Race - Troll Bat Rider",
	author = "[Oddity]TeacherCreature",
	description = "The Troll Bat Rider race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	CreateTimer(1.0,CalcRegenWaves,_,TIMER_REPEAT);
	HookEvent("hegrenade_detonate", GrenadeDetonate);
	FriendlyFireConcoctionCvar=CreateConVar("war3_tbr_concoctionbomber_ff","0","Friendly fire for concoction bomb, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	ConcoctionDamageSentryCvar=CreateConVar("war3_tbr_concoctionbomber_sentry","1","Should concoction bomb damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
}

public OnRaceChanged( client, oldrace, newrace )
{
	//if(newrace!=thisRaceID){
	if(newrace!=thisRaceID) {
		SetEntityMoveType(client,MOVETYPE_WALK);
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		bModeFlyOn[client]=false;
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	else
	{
		bModeFlyOn[client]=true;
		bConcocted[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,true);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.6);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_hegrenade");
	}
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==560){
		thisRaceID=War3_CreateNewRace("Troll BatRider","tbr");
		SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Regenerate","Regenerate 1-7 health points per second!",false,8);
		SKILL_ARCANITE=War3_AddRaceSkill(thisRaceID,"Arcanite","You have a chance of doing 10-50 additional damage!",false,8);
		SKILL_LIQUIDFIRE=War3_AddRaceSkill(thisRaceID,"Liquid Fire","Flings a volatile liquid burning enemy",false,8);
		SKILL_FLY=War3_AddRaceSkill(thisRaceID,"Mount","Toggle movement mode!(Flying/Walking)",false,1);
		ULT_CONCOCTION=War3_AddRaceSkill(thisRaceID,"Unstable Concoction","You explode when you die, can be manually activated!",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

/*public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				if(bModeFlyOn[i])
					SetEntityMoveType(i,MOVETYPE_FLY);
				else
					SetEntityMoveType(i,MOVETYPE_WALK);
			}
		}
	
	}
}*/

public OnMapStart()
{
	AddFileToDownloadsTable(ExpSnd_FullPath2);
	AddFileToDownloadsTable(ExpSnd_FullPath);
	AddFileToDownloadsTable(explosionSound1_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/sprites/floorfire4_.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/floorfire4_.vtf");
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
	}
	else
	{
		AddFileToDownloadsTable("materials/mora-wcs/sprites/zerogxplode.vmt");
		AddFileToDownloadsTable("materials/mora-wcs/sprites/zerogxplode.vtf");
		ExplosionModel=PrecacheModel("materials/mora-wcs/sprites/zerogxplode.vmt",false);
	}
	
	PrecacheSoundAny("*mora-wcs/weapons/morabotti/explode1.mp3");
	PrecacheSoundAny("*mora-wcs/weapons/morabotti/explode5.mp3");
	explosion=PrecacheModel("materials/mora-wcs/sprites/floorfire4_.vmt");
	BeamSprite=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/mora-wcs/sprites/halo01.vmt");

	if(!PrecacheSoundAny(explosionSound1)){
		SetFailState("[War3Source TROLL_BAT_RIDER] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",explosionSound1);
	}
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && pressed && IsPlayerAlive( client ) )
	{
		new skilllevel = War3_GetSkillLevel( client, thisRaceID, SKILL_FLY );
		if( skilllevel > 0 )
		{
			if( !Silenced( client ) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_FLY,true))
			{
				War3_CooldownMGR(client,6.0,thisRaceID,SKILL_FLY,_,true);
				if(bModeFlyOn[client]) //fly mode on
				{
					bModeFlyOn[client]=false;
					SetEntityMoveType(client,MOVETYPE_WALK);
					War3_SetBuff(client,bFlyMode,thisRaceID,false);
					PrintHintText(client,"Fly Mode Deactivated!");
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
				}
				else //fly mode off
				{
					bModeFlyOn[client]=true;
					War3_SetBuff(client,bFlyMode,thisRaceID,true);
					PrintHintText(client,"Fly Mode Activated!");
					War3_SetBuff(client,fMaxSpeed,thisRaceID,2.5);
				}
				new Float:effect_vec[3];
				GetClientAbsOrigin(client,effect_vec);
				TE_SetupBeamRingPoint(effect_vec, 10.0, 500.0, BeamSprite, HaloSprite, 0, 15, 1.2, 10.0, 1.0, {255,220,220,255}, 5, 0);
				TE_SendToAll();
			}
		}
	}
}

public Action:CalcRegenWaves(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i))
			{
				if(ValidPlayer(i,true))
				{
					if(War3_GetRace(i)==thisRaceID)
					{
						Regen(i); //check leves later
					}
				}
			}
		}
	}
}

public Regen(client)
{
	//assuming client exists and has this race
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
	if(skill>0)
	{
		new Float:dist = 1.0;
		new RegenTeam = GetClientTeam(client);
		new Float:RegenPos[3];
		GetClientAbsOrigin(client,RegenPos);
		new Float:VecPos[3];

		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(client)&&IsClientInGame(i))
			{
				if(ValidPlayer(client,true)&&ValidPlayer(i,true)&&GetClientTeam(i)==RegenTeam)
				{
					GetClientAbsOrigin(i,VecPos);
					if(GetVectorDistance(RegenPos,VecPos)<=dist)
					{
						War3_HealToMaxHP(i,RegenAmountArr[skill] +2);
						W3FlashScreen(i,RGBA_COLOR_GREEN);
					}
				}
			}
		}
	}
}

public Action:DelayedItem(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		decl Float:spawnpos[3];
		GetClientAbsOrigin(client,spawnpos);
		TE_SetupBeamRingPoint(spawnpos, 10.0, 500.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,0,0,255}, 120, 0);
		TE_SendToAll(0.4);
		TE_SetupExplosion(spawnpos, explosion, 8.5, 1, 4, 0, 0);
		TE_SendToAll(0.4);
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

public Action:GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		new race=War3_GetRace(index);
		if(race==thisRaceID&&War3_GetGame()!=Game_TF)
		{
			if(StrEqual(name, "hegrenade_detonate"))
			{
				W3FlashScreen(index,RGBA_COLOR_RED);
				CreateTimer(1.0,DelayedItem,index);
				return Plugin_Continue;
			}
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
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
			new skill_level_liquidfire=War3_GetSkillLevel(attacker,thisRaceID,SKILL_LIQUIDFIRE);
			new skill_level_arcanite=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ARCANITE);
			new Float:chance_mod=1.0;
			// Arcanite
			if(race_attacker==thisRaceID && skill_level_arcanite>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=ArcaniteChance[skill_level_arcanite]*chance_mod && !W3HasImmunity(victim,Immunity_Skills))
				{
					//War3_DamageModPercent(ArcaniteDamagePercent[skill_level_arcanite]+1.0);
					//War3_DealDamage( victim, ArcaniteDamage[skill_level_arcanite], attacker, DMG_SLASH, "weapon_hegrenade", _, W3DMGTYPE_TRUEDMG );
					new random = GetRandomInt(ArcaniteDamageMin[skill_level_arcanite], ArcaniteDamageMax[skill_level_arcanite]);
					// OnW3TakeDmgBulletPre refuses to directly use War3_DealDamage, wait 0.1 seconds to make it work properly.
					DealDamageWrapper(victim,attacker,random,"weapon_hegrenade");
					//War3_DealDamage(victim,random,attacker,DMG_SLASH,"weapon_hegrade",_,W3DMGTYPE_TRUEDMG,true,false);
					W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_ARCANITE);
					EmitSoundToAllAny("*mora-wcs/weapons/morabotti/explode5.mp3",victim);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					new Float:effect_vec[3];
					GetClientAbsOrigin(victim,effect_vec);
					TE_SetupBeamRingPoint(effect_vec, 10.0, 700.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,0,0,255}, 120, 0);
					TE_SendToAll(0.4);
					TE_SetupExplosion(effect_vec, explosion, 8.5, 1, 4, 0, 0);
					TE_SendToAll(0.4);
					TE_SetupBeamRingPoint(effect_vec, 10.0, 700.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,0,0,255}, 120, 0);
					TE_SendToAll(0.6);
					TE_SetupExplosion(effect_vec, explosion, 8.5, 1, 4, 0, 0);
					TE_SendToAll(0.6);
					TE_SetupBeamRingPoint(effect_vec, 10.0, 700.0, explosion, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,0,0,255}, 120, 0);
					TE_SendToAll(0.8);
					TE_SetupExplosion(effect_vec, explosion, 8.5, 1, 4, 0, 0);
					TE_SendToAll(0.8);
					TE_SetupBeamRingPoint(effect_vec, 10.0, 700.0, explosion, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,0,0,255}, 120, 0);
				}
			}
			// Liquid Fire
			if(race_attacker==thisRaceID && skill_level_liquidfire>0)
			{
				if(GetRandomFloat(0.0,1.0)<=0.5 && !W3HasImmunity(victim,Immunity_Skills))
				{
					IgniteEntity(victim,LiquidFireArr[skill_level_liquidfire]);
					PrintToConsole(attacker,"[Notice] Liquid Fire burns your enemy");
					new Float:effect_vec[3];
					GetClientAbsOrigin(victim,effect_vec);
					TE_SetupBeamRingPoint(effect_vec, 200.0, 10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 15.0, {255,200,200,255}, 120, 0);
					TE_SendToAll();
					TE_SetupExplosion(effect_vec, explosion, 8.5, 1, 4, 0, 0);
					TE_SendToAll();
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}

public Concoction(client,level)
{
	new Float:radius=ConcoctionRadius[level];
	if(level<=0)
		return; // just a safety check
	new ss_ff=GetConVarInt(FriendlyFireConcoctionCvar);
	new bool:mp_ff=GetConVarBool(MPFFCvar);
	new our_team=GetClientTeam(client); 
	new Float:client_location[3];
	for(new i=0;i<3;i++){
		client_location[i]=ConcoctionLocation[client][i];
	}
	
	TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
	TE_SendToAll();
	
	if(War3_GetGame()==Game_TF){
		client_location[2]+=30.0;
	}
	else{
		client_location[2]-=40.0;
	}
	
	TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
	TE_SendToAll();
	
	new beamcolor[]={0,200,255,255}; //blue //secondary ring
	if(our_team==2)
	{ //TERRORISTS/RED in TF?
		beamcolor[0]=255;
		beamcolor[1]=0;
		beamcolor[2]=0;
		
	} //secondary ring
	TE_SetupBeamRingPoint(client_location, 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
	TE_SendToAll();

	if(War3_GetGame()==Game_TF){
		client_location[2]-=30.0;
	}
	else{
		client_location[2]+=40.0;
	}
	
	EmitSoundToAllAny(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		EmitSoundToAllAny("*mora-wcs/weapons/morabotti/explode1.mp3",client);
	}
	else{
		EmitSoundToAllAny("*mora-wcs/weapons/morabotti/explode5.mp3",client);
	}
	
	new Float:location_check[3];
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&client!=x)
		{
			new team=GetClientTeam(x);
			if(ss_ff==0 && team==our_team)
				continue;
			else if(ss_ff==2 && !mp_ff && team==our_team)
				continue;

			GetClientAbsOrigin(x,location_check);
			new Float:distance=GetVectorDistance(client_location,location_check);
			
			
			if(War3_GetGame()==Game_TF && GetConVarBool(ConcoctionDamageSentryCvar))
			{
				// Do they have a sentry that should get blasted too?
				new ent=0;
				while((ent = FindEntityByClassname(ent,"obj_sentrygun"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates)&&!W3HasImmunity(x,Immunity_Skills))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(ConcoctionDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Concoction BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
				while((ent = FindEntityByClassname(ent,"obj_teleport"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates)&&!W3HasImmunity(x,Immunity_Skills))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(ConcoctionDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Concoction BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
				while((ent = FindEntityByClassname(ent,"obj_dispenser"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates)&&!W3HasImmunity(x,Immunity_Skills))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(ConcoctionDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Concoction BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
			}
			if(distance>radius)
				continue;
			// TODO: Possible traceline for explosion?
			//new damage=RoundFloat(100*(1-FloatDiv(distance,radius)+0.40));
			if(!W3HasImmunity(x,Immunity_Ultimates)&&!W3HasImmunity(x,Immunity_Skills))
			{
				new Float:factor=(radius-distance)/radius;
				new damage;
				if(War3_GetGame()==Game_TF){
					damage=RoundFloat(ConcoctionDamageTF[level]*factor);
				}
				else{
					damage=RoundFloat(ConcoctionDamage[level]*factor);
				}
				PrintToConsole(client,"Concoction damage: %d at distance %f",damage,distance);
				
				War3_DealDamage(x,damage,client,DMG_BLAST,"Concoction");
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"Player %d has immunity",x);
			}
			
		}
	}
	//PrintCenterText(client,"BOMB DETONATED!");
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(!Silenced(client))
	{
		if(pressed)
		{
			if(race==thisRaceID&&IsPlayerAlive(client)&&!bConcocted[client])
			{
				new ult_level=War3_GetSkillLevel(client,race,ULT_CONCOCTION);
				if(ult_level>0)
				{
					ForcePlayerSuicide(client); //this causes them to die...
				}
				else
				{
					PrintHintText(client,"Level Your Ultimate First");
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	
	/*new uid_victim=GetEventInt(event,"userid");
	if(uid_victim>0)
	{
		new deathFlags = GetEventInt(event, "death_flags");
		if (War3_GetGame()==Game_TF&&deathFlags & 32)
		{
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		}
		else
		{
			new victim=GetClientOfUserId(uid_victim);*/
			
	if(!bConcocted[victim])
	{
		new race=War3_GetRace(victim);
		new skill=War3_GetSkillLevel(victim,thisRaceID,ULT_CONCOCTION);
		if(race==thisRaceID && skill>0)
		{
			bConcocted[victim]=true;
			GetClientAbsOrigin(victim,ConcoctionLocation[victim]);
			CreateTimer(0.15,DelayedBomber,victim);
		}
	}
	
	
	
		//}
	//}
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		Concoction(client,War3_GetSkillLevel(client,thisRaceID,ULT_CONCOCTION));
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		if(IsPlayerAlive(client)){
			bConcocted[client]=false;
		}
	}
}
/*
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		bConcocted[client]=false;
		GivePlayerItem(client, "weapon_hegrenade");
	}
	else{
		bConcocted[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}
public Action:OnWeaponCanUse(client, weapon)
{
	if (War3_GetRace(client)== thisRaceID)
	{
		decl String:name[64];
		GetEdictClassname(weapon, name, sizeof(name));
		//PrintToConsole(client,"OnWeaponCanUse GetEdictClassname(weapon %s ",name);
		//if(StrEqual(name, "weapon_hegrenade", false))
		//if (IsEquipment(name)||StrEqual(name,"weapon_c4")||StrEqual(name,"weapon_knife"))
		if (IsEquipmentAllowed(name))
			return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

#tryinclude <sc/weapons>
#if !defined _weapons_included
stock bool:IsEquipmentAllowed(const String:weapon[])
{
	switch (War3_GetGame())//this is zero, u never set it i thought w3s does cause headcrab works
	{
		case Game_CS:
		{
			return (StrEqual(weapon,"weapon_hegrenade") ||
			StrEqual(weapon,"weapon_knife") ||
			StrEqual(weapon,"weapon_c4"));			
		}
		case Game_DOD:
		{
			return (StrEqual(weapon,"weapon_amerknife") ||
			StrEqual(weapon,"weapon_spade"));
		}
		case Game_TF:
		{
			return (StrEqual(weapon,"tf_weapon_knife") ||
			StrEqual(weapon,"tf_weapon_shovel") ||
			StrEqual(weapon,"tf_weapon_wrench") ||
			StrEqual(weapon,"tf_weapon_bat") ||
			StrEqual(weapon,"tf_weapon_bat_wood") ||
			StrEqual(weapon,"tf_weapon_bonesaw") ||
			StrEqual(weapon,"tf_weapon_bottle") ||
			StrEqual(weapon,"tf_weapon_club") ||
			StrEqual(weapon,"tf_weapon_fireaxe") ||
			StrEqual(weapon,"tf_weapon_fists") ||
			StrEqual(weapon,"tf_weapon_sword"));
		}
	}
	return false;
}
#endif*/

//dirty dealdamage workaround.. tell me if you got another idea :o
stock DealDamageWrapper(victim,attacker,damage,String:classname[32],Float:delay=0.1) {
	new Handle:pack;
	CreateDataTimer(delay, Timer_DealDamageWrapper, pack);
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	WritePackCell(pack, damage);
	WritePackString(pack, classname);
}
public Action:Timer_DealDamageWrapper(Handle:timer, Handle:pack)
{
	ResetPack(pack); //resolve the package...
	new victim = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	decl String:classname[32];
	ReadPackString(pack,classname,sizeof(classname));
	War3_DealDamage(victim,damage,attacker,DMG_BULLET,classname);
}
