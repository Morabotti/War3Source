#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
	name = "Archmage Proudmoore",
	author = "Morabotti",
	description = "Reproduced from orginal WCS",
	version = "1.0.0.0"
};


new thisRaceID, SKILL_SHAKE, SKILL_SPEED, SKILL_WEAPON, ULT_LIFT;
new AttackSprite1;
new bool:bModeFlyOn[MAXPLAYERS];
new String:WeaponArray[9][] = {{"weapon_p250"}, {"weapon_fiveseven"}, {"weapon_nova"}, {"weapon_mp7"}, {"weapon_ump45"}, {"weapon_famas"}, {"weapon_sg556"}, {"weapon_ak47"}, {"weapon_awp"}};
new String:WeaponArrayNames[9][] = {{"P250"}, {"FiveSeven"}, {"Nova"}, {"Mp7"}, {"Ump45"}, {"Famas"}, {"Sg556"}, {"Ak47"}, {"AWP"}};
new Float:VelocityAmount[9] = {1.0, 1.04, 1.08, 1.12, 1.16, 1.20, 1.24, 1.28, 1.32};
new Float:EarthquakeChance[9] = {0.0, 0.05, 0.07, 0.09, 0.12, 0.15, 0.18, 0.21, 0.25};
new LiftCost[9] = {0, 35, 30, 25, 20, 15, 10, 5, 1};

new String:ult_sound1[] = "*mora-wcs/war3source/morabotti/rock5.mp3";
new String:ult_sound1_FullPath[] = "sound/mora-wcs/war3source/morabotti/rock5.mp3";
new String:ult_sound2[] = "*mora-wcs/war3source/morabotti/rock4.mp3";
new String:ult_sound2_FullPath[] = "sound/mora-wcs/war3source/morabotti/rock4.mp3";
new String:earthquakeSnd[] = "*mora-wcs/war3source/morabotti/machine1_hit1.mp3";
new String:earthquakeSnd_FullPath[] = "sound/mora-wcs/war3source/morabotti/machine1_hit1.mp3";

//new String:AttackSprite1_FullPath[] = "materials/effects/strider_pinch_dudv_dx60.vmt";
//new String:AttackSprite1VTF_FullPath[] = "materials/effects/strider_pinch_dx70.vtf";
//new String:AttackSprite1_FullPath[] = "materials/mora-wcs/effects/hydragutbeam.vmt";
//new String:AttackSprite1VTF_FullPath[] = "materials/mora-wcs/effects/hydragutbeam.vtf";


public OnMapStart()
{
	//AddFileToDownloadsTable(AttackSprite1_FullPath);
	//AddFileToDownloadsTable(AttackSprite1VTF_FullPath);
	AddFileToDownloadsTable(ult_sound1_FullPath);
	AddFileToDownloadsTable(ult_sound2_FullPath);
	AddFileToDownloadsTable(earthquakeSnd_FullPath);
	
	PrecacheSoundAny(ult_sound1);
	PrecacheSoundAny(ult_sound2);
	PrecacheSoundAny(earthquakeSnd);
	
	//AttackSprite1 = PrecacheModel( "materials/effects/strider_pinch_dudv_dx60.vmt" );
	AttackSprite1 = PrecacheModel( "materials/mora-wcs/sprites/lgtning.vmt" );
	//HaloSprite = PrecacheModel( "materials/mora-wcs/sprites/halo01.vmt" );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==570){
	thisRaceID = War3_CreateNewRace( "Archmage Proudmoore", "archproud" );
	
	SKILL_SHAKE = War3_AddRaceSkill( thisRaceID, "Earthquake", "Chance to shake victim", false, 8 );
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Broom of Velocity", "Increase speed", false, 8 );
	SKILL_WEAPON = War3_AddRaceSkill( thisRaceID, "Weapon of the Sorcerer", "Gives a random weapon on round start", false, 8 );
	ULT_LIFT = War3_AddRaceSkill( thisRaceID, "Lift off", "Enables you to fly, costs health", true, 8 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_LIFT, 8.0, true );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, VelocityAmount);
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		SetEntityMoveType(client,MOVETYPE_WALK);
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		bModeFlyOn[client]=false;
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	if(!bModeFlyOn[client])
	{
		InitPassiveSkills( client );
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
		GiveWeapon( client );
	}
}

public GiveWeapon(client)
{
	if(IsPlayerAlive(client))
	{
		new skill_weapon_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WEAPON);
		if(skill_weapon_level>0)
		{
			new weapon = GetRandomInt(0,skill_weapon_level);
			GivePlayerItem( client, WeaponArray[weapon]);
			PrintHintText(client, "You got %s", WeaponArrayNames[weapon]);
		}
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if(!isWarcraft&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
    	if(War3_GetRace(attacker)==thisRaceID)
        {
			new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SHAKE);
			if(skill_level>0&&!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=EarthquakeChance[skill_level])
			{
				if(W3HasImmunity(victim,Immunity_Skills))
				{
					PrintHintText(victim,"Blocked Earthquake");
					PrintHintText(attacker,"Enemy Blocked Earthquake");
				}
				else
				{
					War3_ShakeScreen(victim,2.0,50.0,40.0);
					PrintHintText(attacker,"You Earthquaked enemy");
					PrintHintText(victim,"You got Earthquaked by enemy");
					W3FlashScreen(victim,{0,0,128,80});
					EmitSoundToAllAny(earthquakeSnd, victim);
					EmitSoundToAllAny(earthquakeSnd, attacker);
					new Float:start_pos[3];
					new Float:target_pos[3];
					
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
	                
					start_pos[2] += 10;
					target_pos[2] += 10;
					
					TE_SetupBeamPoints( start_pos, target_pos, AttackSprite1, 0, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 0, 255, 0, 255}, 0 );
					TE_SendToAll();
				}
			}
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID)
	{
		new ult_level = War3_GetSkillLevel(client,thisRaceID,ULT_LIFT);
		if(ult_level>0)
		{
			if(!Silenced(client))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIFT,true))
				{
					War3_CooldownMGR(client,6.0,thisRaceID,ULT_LIFT,_,true);
					if(bModeFlyOn[client])
					{
						bModeFlyOn[client]=false;
						SetEntityMoveType(client,MOVETYPE_WALK);
						War3_SetBuff(client,bFlyMode,thisRaceID,false);
						PrintHintText(client,"Lift Off Deactivated!");
						War3HealToHP(client, LiftCost[ult_level], War3_GetMaxHP(client));
						W3FlashScreen(client,{51, 153, 51,50}, 0.1, 0.2);
						EmitSoundToAllAny(ult_sound2, client);
					}
					else
					{
						
						bModeFlyOn[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						PrintHintText(client,"Lift Off Activated!");
						War3_DealDamage(client, LiftCost[ult_level], _, DMG_SONIC, "LIFT OFF", _ , W3DMGTYPE_TRUEDMG );
						W3FlashScreen(client,{51, 153, 51,50}, 0.1, 0.2);
						EmitSoundToAllAny(ult_sound1, client);
					}
				}
			}
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}