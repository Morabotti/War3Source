#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>

public Plugin:myinfo =
{
    name = "War3Source - Race - Soul Reaper",
    author = "War3Source Team",
    description = "The Soul Reaper race for War3Source."
};

new thisRaceID;

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

new Handle:ultCooldownCvar;

new SpawnSprite, HaloSprite;

new SKILL_JUDGE, SKILL_PRESENCE,SKILL_INHUMAN, ULT_EXECUTE;


// Chance/Data Arrays
new JudgementAmount[9]={0,5,10,15,20,25,30,40,45};
new Float:JudgementCooldownTime=10.0;
new Float:JudgementRange=200.0;

new Float:PresenseAmount[9]={0.0, 0.3, 0.6, 1.0, 1.3, 1.6, 2.0, 2.2, 2.5};
new Float:PresenceRange=400.0;

new InhumanAmount[9]={0,3,6,9,12,15,18,21,24};
new Float:InhumanRange=400.0;

new Float:ultRange=500.0;
new Float:ultiDamageMulti[9]={0.0, 0.2, 0.4, 0.5, 0.7, 0.8, 1.0, 1.1, 1.2};

new String:judgesnd[]="*mora-wcs/war3source/sr/judgement.mp3";
new String:ultsnd[]="*mora-wcs/war3source/sr/ult.mp3";
new String:judgesnd_FullPath[]="sound/mora-wcs/war3source/sr/judgement.mp3";
new String:ultsnd_FullPath[]="sound/mora-wcs/war3source/sr/ult.mp3";

public OnPluginStart()
{
    HookEvent("player_death",PlayerDeathEvent);

    ultCooldownCvar=CreateConVar("war3_sr_ult_cooldown","20","Cooldown time for CD ult overload.");

    LoadTranslations("w3s.race.sr.phrases.txt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==100)
    {
        thisRaceID=War3_CreateNewRaceT("sr");
        SKILL_JUDGE=War3_AddRaceSkillT(thisRaceID,"Judgement",false,8);
        SKILL_PRESENCE=War3_AddRaceSkillT(thisRaceID,"WitheringPresence",false,8);
        SKILL_INHUMAN=War3_AddRaceSkillT(thisRaceID,"InhumanNature",false,8);
        ULT_EXECUTE=War3_AddRaceSkillT(thisRaceID,"DemonicExecution",true,8);
        War3_CreateRaceEnd(thisRaceID);

        War3_AddAuraSkillBuff(thisRaceID, SKILL_PRESENCE, fHPDecay, PresenseAmount,
                              "witheringpresense", PresenceRange,
                              true);

    }
}

public OnMapStart()
{
	//AddFileToDownloadsTable("materials/mora-wcs/effects/energysplash.vmt");
	//AddFileToDownloadsTable("materials/mora-wcs/effects/energysplash.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/slime1.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/slime1.vtf");
	AddFileToDownloadsTable(judgesnd_FullPath);
	AddFileToDownloadsTable(ultsnd_FullPath);
	PrecacheSoundAny(ultsnd);
	PrecacheSoundAny(judgesnd);
	//SpawnSprite = PrecacheModel("materials/mora-wcs/effects/energysplash.vmt");
	SpawnSprite = PrecacheModel("materials/mora-wcs/effects/slime1.vmt");
	HaloSprite = War3_PrecacheHaloSprite();
}

public OnWar3EventSpawn(client)
{
   new race = War3_GetRace(client);
   if(race == thisRaceID)
   {
		decl Float:spawn_pos[3];
		GetClientAbsOrigin(client,spawn_pos);
		spawn_pos[2] += 25;
		TE_SetupBeamRingPoint(spawn_pos, 200.0, 250.0, SpawnSprite, HaloSprite, 0, 10, 4.0, 70.0, 1.0, {215, 0, 0,255}, 5, FBEAM_ISACTIVE);
		TE_SendToAll();
   }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_JUDGE);
        if(skill_level>0)
        {

            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_JUDGE,true))
            {
                new amount=JudgementAmount[skill_level];

                new Float:playerOrigin[3];
                GetClientAbsOrigin(client,playerOrigin);

                new team = GetClientTeam(client);
                new Float:otherVec[3];
                for(new i=1;i<=MaxClients;i++){
                    if(ValidPlayer(i,true)){
                        GetClientAbsOrigin(i,otherVec);
                        if(GetVectorDistance(playerOrigin,otherVec)<JudgementRange)
                        {
                            if(GetClientTeam(i)==team){
                                War3_HealToMaxHP(i,amount);
                            }
                            else{
                                War3_DealDamage(i,amount,client,DMG_BURN,"judgement",W3DMGORIGIN_SKILL);
                            }

                        }
                    }
                }
                PrintHintText(client,"%T","+/- {amount} HP",client,amount);
                EmitSoundToAllAny(judgesnd,client);
                //EmitSoundToAll(judgesnd,client);
                War3_CooldownMGR(client,JudgementCooldownTime,thisRaceID,SKILL_JUDGE,true,true);

            }
        }
    }
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        //if(

        new skill=War3_GetSkillLevel(client,race,ULT_EXECUTE);
        if(skill>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_EXECUTE,true))
            {
                new target=War3_GetTargetInViewCone(client,ultRange,false);
                if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
                {

                    new hpmissing=War3_GetMaxHP(target)-GetClientHealth(target);

                    new dmg=RoundFloat(FloatMul(float(hpmissing),ultiDamageMulti[skill]));

                    if(War3_DealDamage(target,dmg,client,_,"demonicexecution"))
                    {
                        PrintToConsole(client,"T%","Executed for {amount} damage",client,War3_GetWar3DamageDealt());
                        War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_EXECUTE,true,true);

                        EmitSoundToAllAny(ultsnd,client);

                        EmitSoundToAllAny(ultsnd,target);
                    }
                }
                else
                {
                    W3MsgNoTargetFound(client,ultRange);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetEventInt(event,"userid");
    new victim=GetClientOfUserId(userid);

    if(victim>0)
    {
        new Float:deathvec[3];
        GetClientAbsOrigin(victim,deathvec);

        new Float:gainhpvec[3];

        for(new client=1;client<=MaxClients;client++)
        {
            if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
                GetClientAbsOrigin(client,gainhpvec);
                if(GetVectorDistance(deathvec,gainhpvec)<InhumanRange){
                    new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INHUMAN);
                    if(skilllevel>0&&!Hexed(client)){
                        War3_HealToMaxHP(client,InhumanAmount[skilllevel]);
                    }
                }
            }
        }
        //new deathFlags = GetEventInt(event, "death_flags");
    // where is the list of flags? idksee firefox
        //if (War3_GetGame()==Game_TF&&deathFlags & 32)
        //{
           //PrintToChat(client,"war3 debug: dead ringer kill");
        //}


    }
}
