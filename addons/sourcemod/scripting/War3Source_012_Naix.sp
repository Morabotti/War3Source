#include <sourcemod>
#include <sdktools_functions>    //For teleport
#include <sdktools_sound>        //For sound effect
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Race - Naix",
    author = "War3Source Team",
    description = "The Naix Mage race for War3Source."
};

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04 // DOD = Red //kinda already defiend in war3 interface

//Skills Settings

new Float:HPPercentHealPerKill[9] = { 0.0, 0.03,  0.06,  0.09,  0.12, 0.15, 0.18, 0.21, 0.24}; //SKILL_INFEST settings
//Skill 1_1 really has 5 settings, so it's not a mistake
new HPIncrease[9]       = { 0, 10, 15, 20, 25, 30, 35, 45, 50};     //Increases Maximum health

new Float:feastPercent[9] = { 0.0, 0.02,  0.04,  0.06,  0.08, 0.10, 0.12, 0.14, 0.15 };   //Feast ratio (leech based on current victim hp


new Float:RageAttackSpeed[9] = {1.0, 1.05,  1.10,  1.15,  1.20, 1.25, 1.30, 1.35, 1.45 };   //Rage Attack Rate
new Float:RageDuration[9] = {0.0, 2.0, 3.0, 4.0, 5.0, 6.0, 6.5, 7.0, 7.5 };   //Rage duration

new bool:bDucking[MAXPLAYERSCUSTOM];
//End of skill Settings

new Handle:ultCooldownCvar;

new thisRaceID, SKILL_INFEST, SKILL_BLOODBATH, SKILL_FEAST, ULT_RAGE;
new g_bloodModel, g_sprayModel;

new bool:RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
    if(newrace==thisRaceID)
    {
        RaceDisabled=false;
    }
}
public OnWar3RaceDisabled(oldrace)
{
    if(oldrace==thisRaceID)
    {
        RaceDisabled=true;
    }
}

new String:skill1snd_naix[]="*mora-wcs/war3source/naix/predskill1.mp3";
new String:ultsnd_naix[]="*mora-wcs/war3source/naix/predult.mp3";
new String:skill1snd_naix_FullPath[]="sound/mora-wcs/war3source/naix/predskill1.mp3";
new String:ultsnd_naix_FullPath[]="sound/mora-wcs/war3source/naix/predult.mp3";

public OnPluginStart()
{
    ultCooldownCvar=CreateConVar("war3_naix_ult_cooldown","20","Cooldown time for Rage.");

    LoadTranslations("w3s.race.naix.phrases.txt");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==120)
    {
        thisRaceID=War3_CreateNewRaceT("naix");


        SKILL_INFEST = War3_AddRaceSkillT(thisRaceID, "Infest", false,8,"5-20%");
        SKILL_BLOODBATH = War3_AddRaceSkillT(thisRaceID, "BloodBath", false,8,"10-50");
        SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false,8,"4-10%");
        ULT_RAGE = War3_AddRaceSkillT(thisRaceID, "Rage", true,8,"15-40%","3-6");

        War3_CreateRaceEnd(thisRaceID);
    }
}

stock bool:IsOurRace(client) {
    if(RaceDisabled)
    {
        return false;
    }

    return (War3_GetRace(client)==thisRaceID);
}


public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blood.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/blood.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bloodspray.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/bloodspray.vtf");
	g_bloodModel = PrecacheModel("materials/mora-wcs/sprites/blood.vmt", true);
	g_sprayModel = PrecacheModel("materials/mora-wcs/sprites/bloodspray.vmt", true);
	
	AddFileToDownloadsTable(skill1snd_naix_FullPath);
	AddFileToDownloadsTable(ultsnd_naix_FullPath);
	
	PrecacheSoundAny(skill1snd_naix);
	PrecacheSoundAny(ultsnd_naix);
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim)&&W3Chance(W3ChanceModifier(attacker))&&ValidPlayer(attacker)&&IsOurRace(attacker)&&victim!=attacker&&GetClientTeam(attacker)!=GetClientTeam(victim)){
        new level = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
        if(level>0&&!Hexed(attacker,false)&&W3Chance(W3ChanceModifier(attacker))){
            if(!W3HasImmunity(victim,Immunity_Skills)){
                new targetHp = GetClientHealth(victim)+ RoundToFloor(damage);
                new restore = RoundToNearest( float(targetHp) * feastPercent[level] );

                War3HealToHP(attacker,restore,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);

                PrintToConsole(attacker,"%T","Feast +{amount} HP",attacker,restore);
            }
        }
    }
}
public OnWar3EventSpawn(client){
	if(RaceDisabled)
	{
		return;
	}
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		decl Float:spawn_pos[3];
		decl Float:Vector[3] =  { 0.0, 0.0, 0.0 };
		GetClientAbsOrigin(client, spawn_pos);
		spawn_pos[2]+=45.0;
		new Float:value = 0.0;
		
		for (new i = 0; i < 50; i++)
		{
			TE_SetupBloodSprite(spawn_pos, Vector, {215,0,0,255}, 45, g_sprayModel, g_bloodModel);
			TE_SendToAll(value);
			value += 0.1;
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(RaceDisabled)
    {
        return Plugin_Continue;
    }


    bDucking[client]=(buttons & IN_DUCK)?true:false;
    return Plugin_Continue;
}
//new Float:teleportTo[66][3];
public OnWar3EventDeath(victim,attacker){
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&IsOurRace(attacker)){
        new iSkillLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_INFEST);
        if (iSkillLevel>0)
        {

            if (Hexed(attacker,false))
            {
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, you are hexed",attacker);
            }
            else if (W3HasImmunity(victim,Immunity_Skills))
            {
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, enemy immunity",attacker);
            }
            else{


                if(bDucking[attacker]){
                    decl Float:location[3];
                    GetClientAbsOrigin(victim,location);
                    //.PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
                    War3_CachedPosition(victim,location);
                    //PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);


                    //CreateTimer(0.1,setlocation,attacker);

                    TeleportEntity(attacker, location, NULL_VECTOR, NULL_VECTOR);
                }

                new addHealth = RoundFloat(FloatMul(float(War3_GetMaxHP(victim)),HPPercentHealPerKill[iSkillLevel]));

                War3HealToHP(attacker,addHealth,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
                //Effects?
                //EmitAmbientSound("npc/zombie/zombie_pain2.wav",location);
                EmitSoundToAllAny(skill1snd_naix, attacker);
            }
        }
    }
}
/*
public Action:setlocation(Handle:t,any:attacker){
    TeleportEntity(attacker, teleportTo[attacker], NULL_VECTOR, NULL_VECTOR);
}*/

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RAGE);
        if(ultLevel>0)
        {
            //PrintToChatAll("level %d %f %f",ultLevel,RageDuration[ultLevel],RageAttackSpeed[ultLevel]);
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_RAGE,true ))
            {
                War3_ChatMessage(client,"%T","You rage for {amount} seconds, {amount} percent attack speed",client,
                COLOR_LIGHTGREEN,
                RageDuration[ultLevel],
                COLOR_DEFAULT,
                COLOR_LIGHTGREEN,
                (RageAttackSpeed[ultLevel]-1.0)*100.0 ,
                COLOR_DEFAULT
                );

                War3_SetBuff(client,fAttackSpeed,thisRaceID,RageAttackSpeed[ultLevel]);
                W3SetPlayerColor(client,thisRaceID,128, 0, 0,_,GLOW_ULTIMATE);

                CreateTimer(RageDuration[ultLevel],stopRage,client);
                EmitSoundToAllAny(ultsnd_naix,client);
                EmitSoundToAllAny(ultsnd_naix,client);
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_RAGE,_,_);

            }


        }
        else{
            PrintHintText(client,"%T","No Ultimate Leveled",client);
        }

    }
}
public Action:stopRage(Handle:t,any:client){
    if(RaceDisabled)
    {
        return;
    }
	
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
    if(ValidPlayer(client,true)){
        PrintHintText(client,"%T","You are no longer in rage mode",client);
        W3ResetPlayerColor(client,thisRaceID);
    }
}
