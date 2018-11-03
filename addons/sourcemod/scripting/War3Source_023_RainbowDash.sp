#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Race - Rainbow Dash",
    author = "War3Source Team",
    description = "The Rainbow Dash race for War3Source."
};

new HaloSprite, XBeamSprite;
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

new Float:fEvadeChance[9]={0.0, 0.03, 0.05, 0.07, 0.10, 0.13, 0.15, 0.17, 0.20};
new Float:fSwiftASPDBuff[9]={1.0, 1.03, 1.05, 1.08, 1.10, 1.12, 1.15, 1.18, 1.20};
new Float:abilityspeed[9]={1.0, 1.050, 1.10, 1.15, 1.20, 1.25, 1.3, 1.35, 1.4};
new Float:rainboomradius[9]={0.0, 180.0, 225.0, 250.0, 275.0, 300.0, 333.0, 360.0, 400.0};
new RGBColor = 1;
new RGBColorValue[4];

new Float:LastDamageTime[MAXPLAYERSCUSTOM];
new Handle:speedendtimer[MAXPLAYERSCUSTOM];
new bool:inSpeed[MAXPLAYERSCUSTOM];

new SKILL_EVADE, SKILL_SWIFT, SKILL_SPEED, ULTIMATE;

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==230)
    {
        thisRaceID = War3_CreateNewRace("Rainbow Dash","rainbowdash");
        SKILL_EVADE = War3_AddRaceSkill(thisRaceID,"Evasion","Chance to evade shots.", false, 8);
        SKILL_SWIFT = War3_AddRaceSkill(thisRaceID,"Swiftness","Increase the attack speed", false, 8);
        SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Speed","(ability) Increases the speed of you.\nMust not be injured in the last 10 seconds.\nEnds if injured.", false, 8);
        ULTIMATE = War3_AddRaceSkill(thisRaceID,"Sonic Rainboom","Shakes enemy's screen.\nMust be in speed (ability) mode to cast.", true, 8);

        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!

        War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, fEvadeChance);
        War3_AddSkillBuff(thisRaceID, SKILL_SWIFT, fAttackSpeed, fSwiftASPDBuff);
    }
}

public OnMapStart()
{
    HaloSprite = War3_PrecacheHaloSprite();
    XBeamSprite = War3_PrecacheBeamSprite();
}

public OnPluginStart()
{
	CreateTimer(0.1,CalcRainbow,_,TIMER_REPEAT);
}

public Action:CalcRainbow(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
		{
			new skill_lvl = War3_GetSkillLevel(i,thisRaceID,SKILL_SPEED);
			if(skill_lvl > 0)
			{
				if(inSpeed[i] == true)
				{
					switch(RGBColor)
					{
						case 1:{RGBColorValue =  { 255, 0, 0, 225 };}
						case 2:{RGBColorValue =  { 255, 127, 0, 225 };}
						case 3:{RGBColorValue =  { 255, 255, 0, 225 };}
						case 4:{RGBColorValue =  { 127, 255, 0, 225 };}
						case 5:{RGBColorValue =  { 0, 255, 0, 225 };}
						case 6:{RGBColorValue =  { 0, 255, 127, 225 };}
						case 7:{RGBColorValue =  { 0, 255, 255, 225 };}
						case 8:{RGBColorValue =  { 0, 127, 255, 225 };}
						case 9:{RGBColorValue =  { 0, 0, 255, 225 };}
						case 10:{RGBColorValue =  { 127, 0, 255, 225 };}
						case 11:{RGBColorValue =  { 127, 0, 255, 225 };}
						case 12:{RGBColorValue =  { 255, 0, 255, 225 };}
						case 13:{RGBColorValue =  { 255, 0, 127, 225 };}
					}
					DrawShit(i, RGBColorValue);
					RGBColor++;
					if(RGBColor == 14)
					{
						RGBColor = 1;
					}
				}
			}
		}
	}
}

public Action:DrawShit(any:userid, any:colorf[4])
{
	decl Float:Pos[3];
	GetClientAbsOrigin(userid, Pos);
	TE_SetupBeamRingPoint(Pos, 0.0, 35.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 25.0, 0.0, colorf, 5, 0);
	TE_SendToAll();
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(client, true) && pressed)
    {
        new skill_level = War3_GetSkillLevel(client, thisRaceID, SKILL_SPEED);
        if(skill_level > 0)
        {
            if(SkillAvailable(client, thisRaceID, SKILL_SPEED))
            {
                inSpeed[client] = true;
                if(GAMETF)
                {
                    TF2_AddCondition(client, TFCond_SpeedBuffAlly, 6.0);
                    War3_SetBuff(client, fMaxSpeed, thisRaceID, abilityspeed[skill_level]);
                    War3_SetBuff(client, fSlow, thisRaceID, 0.740740741); //slow down by the factor of the SpeedBuffAlly (1.35)
                }
                else
                {
                    War3_SetBuff(client, fMaxSpeed, thisRaceID, abilityspeed[skill_level]);
                }
                speedendtimer[client] = CreateTimer(12.0, EndSpeed, client);
                War3_CooldownMGR(client, 20.0, thisRaceID, SKILL_SPEED, _, _);
            }
        }
    }
}

public Action:EndSpeed(Handle:t, any:client){
    if(RaceDisabled)
    {
        return;
    }

    if(GAMETF)
    {
        TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
    }

    War3_SetBuff(client, fMaxSpeed, thisRaceID, 1.0);
    War3_SetBuff(client, fSlow, thisRaceID, 1.0);

    speedendtimer[client] = INVALID_HANDLE;
    inSpeed[client] = false;
}

public OnWar3EventSpawn(client)
{
   if(War3_GetRace(client) == thisRaceID)
   {
      decl Float:spawn_pos[3];
      GetClientAbsOrigin(client,spawn_pos);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255,0,0,255}, 10,     0);
      TE_SendToAll(0.0);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255, 127, 0,255}, 10,     0);
      TE_SendToAll(0.05);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255, 255, 0,255}, 10,     0);
      TE_SendToAll(0.09);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0, 255, 0,255}, 10,     0);
      TE_SendToAll(0.11);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0, 127, 255,255}, 10,     0);
      TE_SendToAll(0.13);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0,0,255,255}, 10,     0);
      TE_SendToAll(0.15);
      TE_SetupBeamRingPoint(spawn_pos,                 20.0,            300.0*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {143, 0, 255,255}, 10,     0);
      TE_SendToAll(0.17);
   }
}

public OnWar3EventDeath(client)
{
    if(RaceDisabled)
    {
        return;
    }

    if(speedendtimer[client] != INVALID_HANDLE)
    {
        TriggerTimer(speedendtimer[client]);
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    LastDamageTime[victim] = GetEngineTime();
    if(speedendtimer[victim] != INVALID_HANDLE)
    {
        TriggerTimer(speedendtimer[victim]);
    }
    else if(War3_GetRace(victim)==thisRaceID)
    {
        War3_CooldownMGR(victim, 10.0, thisRaceID, SKILL_SPEED, _, _);
    }
}


public OnUltimateCommand(client, race, bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race == thisRaceID && pressed && ValidPlayer(client, true))
    {
        new skill = War3_GetSkillLevel(client, race, ULTIMATE);
        if(skill > 0)
        {
            if(SkillAvailable(client, thisRaceID, ULTIMATE))
            {
                if(!inSpeed[client])
                {
                    PrintHintText(client, "You must be in speed mode (ability)");
                }
                else{
                    War3_CooldownMGR(client, 20.0, thisRaceID, ULTIMATE, _, _);

                    decl Float:start_pos[3];
                    GetClientAbsOrigin(client,start_pos);

                    //TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255,0,0,255}, 10,     0);
                    TE_SendToAll(0.0);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255, 127, 0,255}, 10,     0);
                    TE_SendToAll(0.05);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {255, 255, 0,255}, 10,     0);
                    TE_SendToAll(0.09);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0, 255, 0,255}, 10,     0);
                    TE_SendToAll(0.11);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0, 127, 255,255}, 10,     0);
                    TE_SendToAll(0.13);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {0,0,255,255}, 10,     0);
                    TE_SendToAll(0.15);
                    TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,             XBeamSprite, HaloSprite,     0,         1,                 0.5,     30.0,         0.0,             {143, 0, 255,255}, 10,     0);
                    TE_SendToAll(0.17);

                    decl Float:TargetPos[3];
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if(ValidPlayer(i,true) && GetClientTeam(i) == GetClientTeam(client) && GetClientTeam(client) == GetApparentTeam(i))
                        {
                            GetClientAbsOrigin(i, TargetPos);
                            if (GetVectorDistance(start_pos, TargetPos) <= rainboomradius[skill])
                            {
                                if(GAMETF)
                                {
                                    TF2_AddCondition(i, TFCond_Buffed, 4.0);
                                }

                                War3_ShakeScreen(i, 0.5, 100.0, 80.0);
                            }
                        }
                    }
                }
            }

        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}
