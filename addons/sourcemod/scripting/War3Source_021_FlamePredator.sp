#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Flame Predator",
	author = "Morabotti",
	description = "Reproduced from WCS",
	version = "1.0.0.0",
	url = ""
};

// W3S VARS
new thisRaceID, SKILL_BERSERK, SKILL_CLOAK, SKILL_LEVITATION, SKILL_CLAWS, SKILL_BLADE, ULT_INFERNO;
new FlameSprite;

// W3S SKILL VARS
new Float:BerserkSpeed[9] = {1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.40, 1.50};
new Float:CloakInvis[9]={1.0, 0.90, 0.80, 0.70, 0.60, 0.50, 0.45, 0.40, 0.35};
new Float:LevitationGravity[9]={1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.60, 0.50};
new Float:DisarmChance[9]={0.00, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24};

new Float:BurnTime[9] =  { 0.0, 3.0, 3.8, 4.6, 5.2, 5.8, 6.4, 7.0, 8.0 };
new BurnDMG[9] =  { 0, 20, 23, 26, 29, 32, 35, 38, 45 };
new Float:BurnRange[9] =  { 0.0, 150.0, 200.0, 250.0, 300.0, 350.0, 400.0, 450.0, 500.0 };


new BladeDMG[9] =  { 0 , 10, 15, 20, 25, 30, 35, 40, 45 };
new Float:BladeODDS = 0.35;

new bool:bIsDisarmed[MAXPLAYERS];

new String:clawsnd[] = "*mora-wcs/war3source/morabotti/blades.mp3";
new String:brnsnd[] = "*mora-wcs/war3source/fire.mp3";
new String:clawsnd_FullPath[] = "sound/mora-wcs/war3source/morabotti/blades.mp3";
new String:brnsnd_FullPath[] = "sound/mora-wcs/war3source/fire.mp3";


#define WEAPONS_ALLOWED "weapon_knife"

// W3S DEFINE SKILLS
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==210)
	{
	thisRaceID = War3_CreateNewRace( "Flame Predator", "flamepredator" );
	
	SKILL_BERSERK = War3_AddRaceSkill( thisRaceID, "Berserk", "Pump yourself with adrenaline", false, 8 );
	SKILL_CLOAK = War3_AddRaceSkill( thisRaceID, "Cloak of Invisibility", "Put on your cloak to be invisible", false, 8 );
	SKILL_LEVITATION = War3_AddRaceSkill( thisRaceID, "Levitation", "Reduce your gravity", false, 8 );
	SKILL_CLAWS = War3_AddRaceSkill( thisRaceID, "Claw Attack", "Chance to disarm enemy", false, 8 );
	SKILL_BLADE = War3_AddRaceSkill( thisRaceID, "Burning Blade", "Chance to light enemy on fire", false, 8 );
	ULT_INFERNO = War3_AddRaceSkill( thisRaceID, "Burning Inferno", "You deal great amount of DMG on target", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_INFERNO, 8.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public OnPluginStart()
{
	
	
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/lgtning.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/lgtning.vtf");
	FlameSprite=PrecacheModel("materials/mora-wcs/sprites/lgtning.vmt");
	War3_PrecacheParticle("molotov_explosion");
	
	AddFileToDownloadsTable(clawsnd_FullPath);
	AddFileToDownloadsTable(brnsnd_FullPath);
	
	PrecacheSoundAny(clawsnd);
	PrecacheSoundAny(brnsnd);
}

// ***
// PASSIVE SKILLIT
// ***

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_AddSkillBuff(thisRaceID, SKILL_BERSERK, fMaxSpeed, BerserkSpeed);
		War3_AddSkillBuff(thisRaceID, SKILL_CLOAK, fInvisibilitySkill, CloakInvis);
		War3_AddSkillBuff(thisRaceID, SKILL_LEVITATION, fLowGravitySkill, LevitationGravity);
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo(client, thisRaceID, WEAPONS_ALLOWED);
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

// ***
// PASSIVE SKILLIT LOPPUU
// ***

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
		decl Float:spawnpos[3];
		GetClientAbsOrigin(client, spawnpos);
		spawnpos[2] += 10.0;
		decl Float:spawnvec[3];
		GetClientEyeAngles(client, spawnvec);
		spawnvec[0]=-90.0;
		ThrowAwayParticle("molotov_explosion", spawnpos, 3.5, spawnvec);
		EmitSoundToAllAny(brnsnd,client);
		
	}
}

//**
//Damage skillit yms
//**

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_attacker = War3_GetRace( attacker );
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_CLAWS );
			new skill_level2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BLADE );
			if(race_attacker == thisRaceID && !Hexed(attacker))
			{
				
				if( !W3IsOwnerSentry(attacker) && skill_level > 0 && W3Chance(DisarmChance[skill_level]))
				{
					PrintHintText(attacker, "You disarmed your enemy!");
					PrintHintText(victim, "You've been disarmed!");
					bIsDisarmed[victim] = true;
					FakeClientCommand( victim, "drop" );
					EmitSoundToAllAny(clawsnd,attacker);
				}
				
				if( skill_level2 > 0 && W3Chance(BladeODDS))
				{
					decl Float:effect_vec[3];
					GetClientAbsOrigin(victim, effect_vec);
					effect_vec[2] += 10.0;
					decl Float:effect_angles[3];
					GetClientEyeAngles(victim, effect_angles);
					effect_angles[0]=-90.0;
					ThrowAwayParticle("molotov_explosion", effect_vec, 3.5, effect_angles);
					W3SetPlayerColor(victim,thisRaceID,255,128,0,_,GLOW_ULTIMATE);
					War3_DealDamage(victim, BladeDMG[skill_level2], attacker ,DMG_BURN, "Stabbed", _ ,W3DMGTYPE_MAGIC);
					W3PrintSkillDmgHintConsole(victim, attacker, War3_GetWar3DamageDealt(), SKILL_BLADE);
					CreateTimer(3.0, ResetBurnColor, GetClientUserId(victim));
					EmitSoundToAllAny(brnsnd,victim);
					
				}
			}
		}
	}
}

public Action:ResetBurnColor(Handle:timer,any:userid)
{
	new victim=GetClientOfUserId(userid);
	W3ResetPlayerColor(victim,thisRaceID);
}

//**
//Ultimate
//**

public bool:TargetCheck(client)
{
	if(W3HasImmunity(client,Immunity_Skills))
	{
		return false;
	}
	return true;
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if(!Silenced( client ))
	{
		
		if( race == thisRaceID && pressed && IsPlayerAlive( client ))
		{
			new ult_level = War3_GetSkillLevel( client, race, ULT_INFERNO );
			if( ult_level > 0 )
			{
				if( War3_SkillNotInCooldown( client, thisRaceID, ULT_INFERNO, true ) )
				{
					new target = War3_GetTargetInViewCone(client,BurnRange[ult_level],false,23.0,TargetCheck);
					if(target>0&&!W3HasImmunity(target,Immunity_Skills))
					{
						new Float:start_pos[3];
						GetClientAbsOrigin(client,start_pos);
						War3_DealDamage(target,BurnDMG[ult_level],client,DMG_BURN,"Burning Inferno ");
						PrintHintText(target,"Hit by Burning Inferno -%d HP",War3_GetWar3DamageDealt());
						PrintHintText(client,"You did -%d DMG with \n Burning Inferno",War3_GetWar3DamageDealt());
						new Float:target_pos[3];
						GetClientAbsOrigin(target,target_pos);
						start_pos[2]+=10.0;
						target_pos[2]+=10.0;
						TE_SetupBeamPoints(start_pos, target_pos, FlameSprite, FlameSprite, 0, 5, 1.0, 5.0, 5.0, 2, 10.0, { 255, 102, 0, 200 }, 60);
						TE_SendToAll();
						W3SetPlayerColor(target,thisRaceID, 255, 51, 0,255,GLOW_ULTIMATE);
						CreateTimer(BurnTime[ult_level], ColorCalc, target);
						War3_CooldownMGR(client,35.0,thisRaceID,ULT_INFERNO,_,true);
						IgniteEntity(target, BurnTime[ult_level]);
						EmitSoundToAllAny(brnsnd,target);
						EmitSoundToAllAny(brnsnd,client);
						W3FlashScreen(target,RGBA_COLOR_ORANGE);
					}
					if(target==0){
						PrintHintText(client,"No valid target within %.1f feet", BurnRange[ult_level]);
					}
				}
				
			}
			else
			{
				W3MsgUltNotLeveled( client );
			}
		}
	}
	else
	{
		PrintHintText(client,"You are silenced, you can't cast");
	}
}

public Action:ColorCalc(Handle:timer,any:client)
{
	 W3ResetPlayerColor(client,thisRaceID);
	 W3FlashScreen(client,RGBA_COLOR_ORANGE);
}