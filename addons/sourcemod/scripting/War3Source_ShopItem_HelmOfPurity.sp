#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

#define PLUGIN_VERSION "1.0"

new shopItem;

new g_iFlashAlpha = -1;

#define ALPHA_SET 0.5

public Plugin:myinfo = {
	name = "Helm of Purity Shopmenu Item",
	author = "Voidless, SAMURAI",
	description = "Protects from flashbang",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=606623"
};

public OnPluginStart()
{
	// find offsets
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");

	// hook events
	HookEvent("player_blind",Event_Flashed);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10){
			shopItem=War3_CreateShopItem("Helm of Purity","helmpure","Protects from Flashbang",6,true);
		}
}
public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (client && g_iFlashAlpha != -1)
	{
		if(War3_GetOwnsItem(client,shopItem))
		{
			SetEntDataFloat(client,g_iFlashAlpha,ALPHA_SET);
		}
	}
}

public OnWar3EventDeath(client)
{
	if(War3_GetOwnsItem(client,shopItem))
		War3_SetOwnsItem(client,shopItem,false);
}
