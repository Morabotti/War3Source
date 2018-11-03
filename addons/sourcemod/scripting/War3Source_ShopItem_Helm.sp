#pragma semicolon 1

#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"

new thisItem;
new String:helmSound0[] = "*mora-wcs/war3source/helm/metal_solid_impact_bullet1.mp3";
new String:helmSound1[] = "*mora-wcs/war3source/helm/metal_solid_impact_bullet2.mp3";
new String:helmSound2[] = "*mora-wcs/war3source/helm/metal_solid_impact_bullet3.mp3";
new String:helmSound3[] = "*mora-wcs/war3source/helm/metal_solid_impact_bullet4.mp3";
new String:helmSound0_FullPath[] = "sound/mora-wcs/war3source/helm/metal_solid_impact_bullet1.mp3";
new String:helmSound1_FullPath[] = "sound/mora-wcs/war3source/helm/metal_solid_impact_bullet2.mp3";
new String:helmSound2_FullPath[] = "sound/mora-wcs/war3source/helm/metal_solid_impact_bullet3.mp3";
new String:helmSound3_FullPath[] = "sound/mora-wcs/war3source/helm/metal_solid_impact_bullet4.mp3";

public Plugin:myinfo = 
{
    name = "War3Source - Shopitem - Helm",
    author = "War3Source Team",
    description = "Become immune to headshots"
};

public OnMapStart()
{
	AddFileToDownloadsTable(helmSound0_FullPath);
	AddFileToDownloadsTable(helmSound1_FullPath);
	AddFileToDownloadsTable(helmSound2_FullPath);
	AddFileToDownloadsTable(helmSound3_FullPath);
	PrecacheSoundAny(helmSound0);
	PrecacheSoundAny(helmSound1);
	PrecacheSoundAny(helmSound2);
	PrecacheSoundAny(helmSound3);
    
    LoadTranslations("w3s.item.helm.phrases.txt");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
    if(num==100){
    
        thisItem = War3_CreateShopItemT("helm", 10, true);
    }    
}
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack); 
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
    if(hitgroup==1&&War3_GetOwnsItem(victim,thisItem)&&!Perplexed(victim)){
        damage=0.0;
        new random = GetRandomInt(0,3);
        if(random==0){
            EmitSoundToAllAny(helmSound0,victim);
        }else if(random==1){
            EmitSoundToAllAny(helmSound1,victim);
        }else if(random==2){
            EmitSoundToAllAny(helmSound2,victim);
        }else{
            EmitSoundToAllAny(helmSound3,victim);
        }
        if(War3_GetGame()==TF){
            decl Float:pos[3];
            GetClientEyePosition(victim, pos);
            pos[2] += 4.0;
            War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
        }
        return Plugin_Changed;
    }
    return Plugin_Continue;
}
