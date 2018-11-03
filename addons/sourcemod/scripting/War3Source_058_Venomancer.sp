#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Race - Venomancer",
    author = "Aurora",
    description = "The Venomancer race for War3Source."
};

new String:daggersnd[] ="*mora-wcs/war3source/venom/dagger.mp3";
new String:ultsnd[] ="*mora-wcs/war3source/venom/ult.mp3";
new String:wardsnd[] ="*mora-wcs/war3source/venom/ward.mp3";
new String:stingsnd[] ="*mora-wcs/war3source/venom/sting.mp3";
new String:daggersnd_FullPath[] ="sound/mora-wcs/war3source/venom/dagger.mp3";
new String:ultsnd_FullPath[] ="sound/mora-wcs/war3source/venom/ult.mp3";
new String:wardsnd_FullPath[] ="sound/mora-wcs/war3source/venom/ward.mp3";
new String:stingsnd_FullPath[] ="sound/mora-wcs/war3source/venom/sting.mp3";

new thisRaceID;
new SKILL_PDAGGER, SKILL_PWARD, SKILL_APOISON, ULT_PNOVA;


// This skill does damage when the venomancer shoots someone. Initial damage followed by a DOT
new Float:DaggerFreq = 1.0; // How often the poison on the dagger deals damage
// Cooldown on Dagger
new Float:DaggerCooldown = 4.0;
// Dagger Initial Damage
new DaggerDamage[9] =  { 0, 5, 8, 11, 14, 17, 20, 23, 26 };
new DaggerDOT[] =  { 0, 1, 1, 2, 2, 3, 3, 4, 5 };
new VictimDaggerTicks[MAXPLAYERSCUSTOM];
new DaggeredBy[MAXPLAYERSCUSTOM];

// Same as shamans ward
// Max Wards
new MaximumWards[9]={0, 1, 1, 2, 2, 3, 3, 4, 4};
// Ward Damage
new WardDamage[9]={0, 1, 1, 2, 2, 3, 3, 4, 5};

// Poison stacking effect, applied on hit
new Float:PoisonFreq = 1.0; // How often the poison ticks per second
new PoisonDamage[9]={0, 1, 1, 2, 2, 3, 3, 4, 5}; // How much damage does a stack do?
new MaxPoisonStacks = 3; // How many stacks can the attacker dish out?
new VictimPoisonStacks[MAXPLAYERSCUSTOM]; // How many stacks does the victim have?
new VictimPoisonTicks[MAXPLAYERSCUSTOM];
new PoisonedBy[MAXPLAYERSCUSTOM]={-1, ...};// Who was the victim poisoned by?



new Float:PNovaFreq = 1.0;// How often the poison ticks per second
new PoisonNovaDamage[]={0, 5, 8, 11, 14, 17, 20, 23, 26};
new PoisonTicks[9]={0, 1, 1, 2, 2, 3, 3, 4, 5};
new VictimNovaTicks[MAXPLAYERSCUSTOM]={0, ...};
new PNovaBy[MAXPLAYERSCUSTOM]={-1, ...};

new BeamSprite,HaloSprite;

new Handle:ultCooldownCvar;
new ultmaxdistance[] = {0, 450, 500, 550, 600, 650, 700, 750, 800};
public OnPluginStart()
{
    CreateTimer(DaggerFreq, DaggerStackTimer , _, TIMER_REPEAT);  // Stacking Dagger DoT Timer
    CreateTimer(PoisonFreq, PoisonStackTimer , _, TIMER_REPEAT);  // Stacking Poison DoT Timer
    CreateTimer(PNovaFreq, PoisonNovaTimer, _, TIMER_REPEAT); // Poison Nova Timer
    //LoadTranslations("w3s.race.venom.phrases");
    ultCooldownCvar=CreateConVar("war3_venom_ult_cooldown","30","Cooldown time for ult.");
    HookEvent("round_start", Event_RoundStart);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==580){
        thisRaceID=War3_CreateNewRace("Venomancer","venom");
        SKILL_PDAGGER=War3_AddRaceSkill(thisRaceID,"PoisonDagger","Damages enemy and leaves DOT",false,8);
        SKILL_PWARD=War3_AddRaceSkill(thisRaceID,"PlagueWard","Release a powerful plague ward",false,8);
        SKILL_APOISON=War3_AddRaceSkill(thisRaceID,"PoisonSting","Your attacks have a stacking poison",false,8);
        ULT_PNOVA=War3_AddRaceSkill(thisRaceID,"PoisonNova","Releases a cloud of poison to enemies",true,8);
        War3_CreateRaceEnd(thisRaceID);
        W3SkillCooldownOnSpawn( thisRaceID, ULT_PNOVA, 8.0, true);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			VictimDaggerTicks[i]=0;
			VictimPoisonStacks[i]=0;
			VictimPoisonTicks[i]=0;
			VictimNovaTicks[i]=0;
			PoisonedBy[i]=-1;
			DaggeredBy[i]=-1;
			PNovaBy[i]=-1;
		}
	}
}


public OnMapStart()
{
	AddFileToDownloadsTable(daggersnd_FullPath);
	AddFileToDownloadsTable(ultsnd_FullPath);
	AddFileToDownloadsTable(wardsnd_FullPath);
	AddFileToDownloadsTable(stingsnd_FullPath);

	PrecacheSoundAny(daggersnd);
	PrecacheSoundAny(ultsnd);
	PrecacheSoundAny(wardsnd);
	PrecacheSoundAny(stingsnd);
    
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3EventSpawn(client)
{
   
    VictimPoisonStacks[client] = 0;  // Remove Poison Stacks
    VictimPoisonTicks[client] = 0;
}


public Action:PoisonStackTimer(Handle:h,any:data)
{
    new attacker;
    new damage;
    new skill;
    for(new i = 1; i <= MaxClients; i++) // Iterate over all clients
    {
        if(ValidPlayer(i, true))
        {
            if(VictimPoisonTicks[i] > 0)
            {
                attacker = PoisonedBy[i];
                skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_APOISON);
                damage = VictimPoisonStacks[i] * PoisonDamage[skill]; // Number of stacks on the client * damage of the attacker
                   
                if(War3_GetGame() == Game_TF)
                {
                    War3_DealDamage(i, damage, attacker, _, "bleed_kill"); // Bleeding Icon
                }
                else
                {
                    if(GameCS() && GetClientHealth(i) > damage){ //cs damages slows....
                        SetEntityHealth(i, GetClientHealth(i) - damage);
                    }
                    else{
                        War3_DealDamage(i, damage,attacker, _, "PoisonSting"); // Generic skill name
                    }
                }
                //War3_ChatMessage(attacker,"Poison Sting did %i damage", damage);
                //War3_ChatMessage(i,"Poison Sting did %i damage to you", damage);
                EmitSoundToAllAny(stingsnd,i);
                VictimPoisonTicks[i]--;
            }
        }
    }
}               


public Action:DaggerStackTimer(Handle:h,any:data)
{
    new attacker;
    new damage;
    new skill;
    for(new i = 1; i <= MaxClients; i++) // Iterate over all clients
    {
        if(ValidPlayer(i, true))
        {
            if(VictimDaggerTicks[i] > 0)
            {
                attacker = DaggeredBy[i];
                skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_PDAGGER);
                damage = DaggerDOT[skill];
                   
                if(War3_GetGame() == Game_TF)
                {
                    War3_DealDamage(i, damage, attacker, _, "bleed_kill"); // Bleeding Icon
                }
                else
                {
                    if(GameCS() && GetClientHealth(i) > damage){ //cs damages slows....
                        SetEntityHealth(i, GetClientHealth(i) - damage);
                    }
                    else{
                        War3_DealDamage(i, damage,attacker, _, "PoisonDagger"); // Generic skill name
                    }
                }
                VictimDaggerTicks[i]--;
            }
        }
    }
}   

public Action:PoisonNovaTimer(Handle:h,any:data)
{
	new attacker;
	new damage;
	new skill;
	for(new i = 1; i <= MaxClients; i++) // Iterate over all clients
	{
		if(ValidPlayer(i, true))
		{
			if(VictimNovaTicks[i] > 0)
			{
				attacker = PNovaBy[i];
				skill = War3_GetSkillLevel(attacker, thisRaceID, ULT_PNOVA);
				damage = PoisonNovaDamage[skill];
				   
				if(War3_GetGame() == Game_TF)
				{
					War3_DealDamage(i, damage, attacker, _, "bleed_kill"); // Bleeding Icon
				}
				else
				{
					if(GameCS() && GetClientHealth(i) > damage){ //cs damages slows....
						SetEntityHealth(i, GetClientHealth(i) - damage);
					}
					else{
						War3_DealDamage(i,damage,attacker,DMG_CRUSH,"poison nova",_,W3DMGTYPE_MAGIC);
					}
				}
				//War3_ChatMessage(attacker,"Poison Nova did %i damage",damage);
				VictimNovaTicks[i]--;
			}
		}
	}
}     


public OnW3TakeDmgBullet(victim,attacker,Float:damage){
    if(ValidPlayer(victim, true) && ValidPlayer(attacker, false) && GetClientTeam(victim) != GetClientTeam(attacker))
    {
        if(War3_GetRace(attacker) == thisRaceID)
        {
            // Apply Poison Sting
            new skilllvl = War3_GetSkillLevel(attacker, thisRaceID, SKILL_APOISON);
            if(skilllvl > 0 && !Hexed(attacker) && !W3HasImmunity(attacker, Immunity_Skills) && War3_SkillNotInCooldown(attacker, thisRaceID, SKILL_APOISON, true))
            {

                if(VictimPoisonStacks[victim] < MaxPoisonStacks)
                {
                    VictimPoisonStacks[victim]++; //stack if less than max stacks
                }
               
                VictimPoisonTicks[victim] = 3 ; //always three ticks               
                PoisonedBy[victim] = attacker;
            }
           
            // Apply Poison Dagger           
            if(War3_SkillNotInCooldown(attacker, thisRaceID, SKILL_PDAGGER, true))
            {
                new skilllvl2 = War3_GetSkillLevel(attacker, thisRaceID, SKILL_PDAGGER);
                if(skilllvl2 > 0 && !Hexed(attacker) && !W3HasImmunity(attacker,Immunity_Skills) && !Silenced(attacker))
                {
                    War3_CooldownMGR(attacker, DaggerCooldown, thisRaceID, SKILL_PDAGGER, true, true);
                   
                    // Initial Damage from dagger
                    new daggerDamage = DaggerDamage[skilllvl2];
                    EmitSoundToAllAny(daggersnd,victim);
                    War3_ChatMessage(attacker,"Dagger did %i damage and poisoned for %i seconds",daggerDamage, DaggerDOT[skilllvl2]);
                    War3_ChatMessage(victim,"Dagger hit you for %i damage and poisoned for %i seconds", daggerDamage, DaggerDOT[skilllvl2]);
                    if(War3_GetGame()==Game_TF)
                    {
                        War3_DealDamage(victim,daggerDamage,attacker,_,"bleed_kill"); // Bleeding Icon
                    }
                    else
                    {
                        if(GameCS() && GetClientHealth(victim) > daggerDamage){ //cs damages slows....
                            SetEntityHealth(victim, GetClientHealth(victim) - daggerDamage);
                        }
                        else{
                            War3_DealDamage(victim, daggerDamage, attacker, _, "PoisonDagger"); // Generic skill name
                        }
                    }
                   
                    // Dagger DOT damage               
                    VictimDaggerTicks[victim] = 3 ; //always three ticks               
                    DaggeredBy[victim] = attacker;
                   
                }
            }               
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client )== thisRaceID && ability == 0 && pressed && IsPlayerAlive(client))
    {
        new skill_level = War3_GetSkillLevel(client, thisRaceID, SKILL_PWARD);
        if(skill_level > 0)
        {
            if(!Silenced(client) && War3_GetWardCount(client) < MaximumWards[skill_level])
            {
                new iTeam=GetClientTeam(client);
                new bool:conf_found=false;
                if(War3_GetGame()==Game_TF)
                {
                    new Handle:hCheckEntities=War3_NearBuilding(client);
                    new size_arr=0;
                    if(hCheckEntities!=INVALID_HANDLE)
                        size_arr=GetArraySize(hCheckEntities);
                    for(new x=0;x<size_arr;x++)
                    {
                        new ent=GetArrayCell(hCheckEntities,x);
                        if(!IsValidEdict(ent)) continue;
                        new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
                        if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
                        {
                            EmitSoundToAllAny(wardsnd,client);
                            conf_found=true;
                            break;                           
                        }
                    }
                    if(size_arr>0)
                        CloseHandle(hCheckEntities);
                }
                if(conf_found)
                {
                    W3MsgWardLocationDeny(client);
                }
                else
                {
                    if(War3_IsCloaked(client))
                    {
                        W3MsgNoWardWhenInvis(client);
                        return;
                    }
                    new Float:location[3];
                    GetClientAbsOrigin(client, location);
                    War3_CreateWardMod(client, location, 60, 300.0, 0.5, "damage", SKILL_PWARD, WardDamage);
                    W3MsgCreatedWard(client,War3_GetWardCount(client),MaximumWards[skill_level]);
                    EmitSoundToAllAny(wardsnd,client);
                }
            }
            else
            {
                W3MsgNoWardsLeft(client);
            }   
        }
    }
}



public OnUltimateCommand(client,race,bool:pressed)
{
    if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new ult_level = War3_GetSkillLevel(client,race,ULT_PNOVA);
		if(ult_level > 0)       
		{
			if(SkillAvailable(client,thisRaceID,ULT_PNOVA,true,true,true))
			{
				new caster_team = GetClientTeam(client);
				new Float:start_pos[3];
				GetClientAbsOrigin(client,start_pos);
				start_pos[2] += 10;
				new distance = ultmaxdistance[ult_level] + 1;
				
				TE_SetupBeamRingPoint(start_pos, 1.0, 650.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {0, 204, 0,195}, 50, 0);
				TE_SendToAll();
			    
				for(new x = 1; x <= MaxClients; x++)
				{
					if(ValidPlayer(x,true) && caster_team != GetClientTeam(x) && !W3HasImmunity(x,Immunity_Ultimates))
					{
						new Float:this_pos[3];
						GetClientAbsOrigin(x, this_pos);
						new Float:dist_check = GetVectorDistance(start_pos, this_pos);
						if(dist_check <= distance)
						{
							EmitSoundToAllAny(ultsnd,client);
							VictimNovaTicks[x]=PoisonTicks[ult_level];
							//War3_ChatMessage(x,"Poison Nova has affected you!");
							PrintHintText(x,"Poison Nova has affected you!");
							PNovaBy[x]=client;							
						}
					}
				}

				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_PNOVA,true,true);
			}
		}
	}
}