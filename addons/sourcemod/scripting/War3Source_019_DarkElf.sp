#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Race - Dark Elf",
    author = "War3Source Team",
    description = "The Dark Elf race for War3Source."
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


new SKILL_FADE,SKILL_SLOWFALL,SKILL_TRIBUNAL,ULTIMATE_DARKORB;

new Float:FadeChance[9]={0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24};  //done
new Float:SlowfallGravity[9]={1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.60, 0.50};  //probably too much overhead lololol oh god
new Float:TribunalDecay[9]={0.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 9.0};    //simple
new Float:TribunalSpeed[9]={1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.325, 1.35}; //simple

new bool:IsInTribunal[MAXPLAYERSCUSTOM];

//new Float:TribunalDuration=3.5;
//new Float:TribunalCooldownTime=15.0;
new Float:DarkorbDistance=1000.0;
new Float:DarkorbDuration[9]={0.0, 1.10, 1.25, 1.40, 1.55, 1.70, 1.85, 2.0, 2.15};
new Float:DarkorbCooldownTime=10.0;

new Float:darkvec[3]={0.0,0.0,0.0};
new Float:prevdarkvec[3]={0.0,0.0,0.0};
new Float:victimvec[3]={0.0,0.0,0.0};

// Sounds
stock String:tribunal[] = "*mora-wcs/war3source/darkelf/tribunal.mp3";
stock String:darkorb[] = "*mora-wcs/war3source/darkelf/darkorb.mp3";
stock String:tribunal_FullPath[] = "sound/mora-wcs/war3source/darkelf/tribunal.mp3";
stock String:darkorb_FullPath[] = "sound/mora-wcs/war3source/darkelf/darkorb.mp3";

new HaloSprite; //BubbeEffect;

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==190)
    {
        thisRaceID=War3_CreateNewRaceT("darkelf_o");
        SKILL_FADE=War3_AddRaceSkillT(thisRaceID,"Fade",false,8);
        SKILL_SLOWFALL=War3_AddRaceSkillT(thisRaceID,"SlowFall",false,8);
        SKILL_TRIBUNAL=War3_AddRaceSkillT(thisRaceID,"Tribunal",false,8);
        ULTIMATE_DARKORB=War3_AddRaceSkillT(thisRaceID,"DarkOrb",true,8);
        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
    }
}

public OnPluginStart()
{
	//AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud1.vmt");
	//AddFileToDownloadsTable("materials/mora-wcs/effects/fire_cloud1.vtf");
	//BubbeEffect = PrecacheModel("materials/mora-wcs/effects/fire_cloud1.vmt");
	CreateTimer(0.1,SlowfallTimer,_,TIMER_REPEAT);
	HaloSprite = War3_PrecacheHaloSprite();
	LoadTranslations("w3s.race.darkelf_o.phrases.txt");
}

public OnMapStart()
{
    AddFileToDownloadsTable(tribunal_FullPath);
    AddFileToDownloadsTable(darkorb_FullPath);

    //Only precache them on TF2
    if(War3_GetGame()==Game_TF)
    {
        War3_PrecacheParticle("teleporter_red_entrance");
        War3_PrecacheParticle("teleporter_blue_entrance");
        War3_PrecacheParticle("ghost_smoke");
    }
    PrecacheSoundAny(tribunal);
    PrecacheSoundAny(darkorb);
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_DARKORB);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_DARKORB,true))
            {
                //War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
                new target = War3_GetTargetInViewCone(client,DarkorbDistance,false,23.0,DarkorbFilter);
                new Float:duration = DarkorbDuration[ult_level];
                if(target>0)
                {
					GetClientAbsOrigin(target,victimvec);
					//W3FlashScreen(target,RGBA_COLOR_BLACK,duration,0.5,FFADE_OUT); RGBA_COLOR_etc doesn't work.
					W3FlashScreen(target,{0,0,0,255},duration,0.5,FFADE_OUT);
					EmitSoundToAllAny(darkorb,target);
					EmitSoundToAllAny(darkorb,target);
					if(War3_GetGame()==Game_TF) {
					    AttachThrowAwayParticle(target, "ghost_smoke", victimvec, "", duration);
					}
					
					W3SetPlayerColor(target,thisRaceID,55, 55, 55,_,GLOW_ULTIMATE);
					decl Float:PlayerPos[3];
					GetClientAbsOrigin(target, PlayerPos);
					PlayerPos[2] += 35;
					TE_SetupSmoke(PlayerPos, HaloSprite, 200.0, 30);
					TE_SendToAll(0.0);
					CreateTimer(duration, ResetColor, target);
					
					War3_CooldownMGR(client,DarkorbCooldownTime,thisRaceID,ULTIMATE_DARKORB,_,_);
					W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"%T","You've been blinded by a Dark Elf!",target);
					W3Hint(client,HINT_COOLDOWN_NOTREADY,5.0,"%T","DarkOrb blinded Successfully",client);
                }
            }
        }
    }
}

public Action:ResetColor(Handle:timer,any:userid)
{
	W3ResetPlayerColor(userid, thisRaceID);
}

public bool:DarkorbFilter(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    return (!W3HasImmunity(client,Immunity_Ultimates));
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID)
            {
                new skill_level_fade=War3_GetSkillLevel(victim,thisRaceID,SKILL_FADE);
                if( skill_level_fade>0 &&!Hexed(victim,false) && GetRandomFloat(0.0,1.0)<=FadeChance[skill_level_fade] && !W3HasImmunity(attacker,Immunity_Skills))
                {

                    W3FlashScreen(victim,{244,244,244,50},0.2,0.2,FFADE_OUT);

                    War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.1);
                    CreateTimer(1.2,FadeTimer,victim);

                }
            }
        }
    }
}

public Action:FadeTimer(Handle:timer,any:victim)
{
    if(RaceDisabled)
    {
        return;
    }


    War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,1.0);

}

public OnWar3EventSpawn(client)
{
	if(RaceDisabled)
	{
		return;
	}
	
	StopTribunal(client);
	/*new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		decl Float:spawn_pos[3];
		GetClientAbsOrigin(client, spawn_pos);
		spawn_pos[2]+=20.0;
		//TE_SetupGlowSprite(spawn_pos, BubbeEffect, 3.0, 10.0, 255);
		//TE_SendToAll();
	}*/
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
    {
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_TRIBUNAL);
        if(skilllvl > 0)
        {
            new Float:speed = TribunalSpeed[skilllvl];
            new Float:decay = TribunalDecay[skilllvl];
            if(!Silenced(client))
            {    //W3SetPlayerColor(client,raceid,r,g,b,a=255,overridepriority=GLOW_DEFAULT)
                W3SetPlayerColor(client,thisRaceID,128,0,128,255); //purple:D not sure if works
                EmitSoundToAllAny(tribunal,client);
                if(IsInTribunal[client]){
                    StopTribunal(client);
                }
                else{
                    IsInTribunal[client]=true;
                    War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
                    War3_SetBuff(client,fHPDecay,thisRaceID,decay);

            //        CreateTimer(TribunalDuration,TribunalTimer,client);
                    W3Hint(client,HINT_NORMAL,5.0,"%T","You sacrificed for speed.",client);
                }
                //War3_CooldownMGR(client,TribunalCooldownTime,thisRaceID,SKILL_TRIBUNAL,_,_);
            }
        }
    }
}

/*
public Action:TribunalTimer(Handle:timer,any:client)
{
    War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
    War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
    W3ResetPlayerColor(client,thisRaceID);
}*/

public Action:SlowfallTimer(Handle:timer,any:zclient)
{
    if(RaceDisabled)
    {
        return;
    }

    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client, true))
        {
            if(War3_GetRace(client) == thisRaceID)
            {
                GetClientAbsOrigin(client,prevdarkvec);
                CreateTimer(0.1,Slowfall2Timer,client);
            }
        }

    }
}
public Action:Slowfall2Timer(Handle:timer,any:client)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(client, true)){
        GetClientAbsOrigin(client,darkvec);
        new flags = GetEntityFlags(client);
        if ( !(flags & FL_ONGROUND) )
        {

            if (darkvec[2]<prevdarkvec[2])
            {
                new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_SLOWFALL);
                new Float:gravity=SlowfallGravity[skilllevel_levi];
                //DP("set %f",gravity);
                War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
                if(!IsInvis(client)&&War3_GetGame()==Game_TF){
                    AttachThrowAwayParticle(client, GetApparentTeam(client)==TEAM_RED?"teleporter_red_entrance":"teleporter_blue_entrance", darkvec, "", 1.0);
                }
            }
            else
            {
                War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
                //DP("nograv2");
                //previousvec[2]=vec[2];
            }
        }
    }
}


public OnRaceChanged(client,oldrace,newrace)
{
    if(RaceDisabled)
    {
        return;
    }

    if(oldrace==thisRaceID)
    {
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
        //DP("nograv");
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        W3ResetPlayerColor(client,thisRaceID);
        IsInTribunal[client]=false;
    }
    if(IsInTribunal[client]){
        StopTribunal(client);
    }
}

StopTribunal(client)
{
	if(RaceDisabled)
	{
		return;
	}
	
	W3ResetPlayerColor(client,thisRaceID);
	IsInTribunal[client]=false;
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
}
