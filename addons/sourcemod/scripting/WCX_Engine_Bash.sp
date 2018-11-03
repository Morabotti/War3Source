#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Warcraft Extended - Bash",
    author = "War3Source Team",
    description="Generic bash skill"
};

new BeamSprite,HaloSprite;
new g_iPlayerRace[MAXPLAYERSCUSTOM]; // So we unbash the right race

public OnPluginStart()
{
    LoadTranslations("w3s.race.human.phrases.txt");
}

public OnMapStart()
{
   BeamSprite=War3_PrecacheBeamSprite();
   HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    // not written to be compatible with left4dead
    if((victim == attacker) || (!ValidPlayer(victim) || !ValidPlayer(attacker)) || (GetClientTeam(victim) == GetClientTeam(attacker)))
    {
        return;
    }


    if(StrEqual(weapon, "crit", false) || StrEqual(weapon, "bash", false) ||
       StrEqual(weapon, "weapon_crit", false) || StrEqual(weapon, "weapon_bash", false))
    {
        return;
    }

    new Float:fChance = W3GetBuffSumFloat(attacker, fBashChance);
    new Float:fChanceModifier = W3ChanceModifier(attacker);
    if((fChance > 0.0) && !Hexed(attacker) && !W3HasImmunity(victim, Immunity_Skills))
    {
        if(War3_Chance(fChance * fChanceModifier) &&
           !W3GetBuffHasTrue(victim, bBashed))
		{
			new race = War3_GetRace(victim);
			g_iPlayerRace[victim] = race;
			War3_SetBuff(victim, bBashed, race, true);
			new newdamage = W3GetBuffSumInt(attacker, iBashDamage);
			if(newdamage > 0)
			{
				War3_DealDamage(victim, newdamage, attacker, _, "weapon_bash");
			}
			decl Float:enemy_pos[3];
			decl Float:enemy_pos2[3];
			GetClientAbsOrigin(victim, enemy_pos);
			enemy_pos2[0]=enemy_pos[0];
			enemy_pos2[1]=enemy_pos[1];
			enemy_pos2[2]=enemy_pos[2] + 60;
			TE_SetupBeamPoints(enemy_pos, enemy_pos2, BeamSprite, HaloSprite, 0, 0, 1.5, 30.0, 40.0, 0, 20.0, {255,255,255,120}, 0);
			TE_SendToAll(0.0);
			
			//TE_SetupGlowSprite( enemy_pos, BeamSprite, 1.0, 2.0, 90 );
			//TE_SendToAll();
			
			
			new Float:fDuration = W3GetBuffSumFloat(attacker, fBashDuration);
			CreateTimer(fDuration, Timer_UnfreezePlayer, victim);
			
			War3_BashEffect(victim, attacker);
		}
    }
}

public Action:Timer_UnfreezePlayer(Handle:h, any:victim)
{
    War3_SetBuff(victim, bBashed, g_iPlayerRace[victim], false);
}
