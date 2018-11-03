/**
* File: War3Source_ShopItem_CatFeet.sp
* Description: Shopmenu Item for war3source - silence player's footsteps.
* Author(s): Remy Lebeau
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="War3Source Shopitem - Cat's Feet",
	author="Remy Lebeau",
	description="War3Source",
	version="1.0.1",
	url="sevensinsgaming.com"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.catfeet.phrases");
}


public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==110)
	{
		thisItem=War3_CreateShopItemT("catfeet",5);
	}
}

public OnItemPurchase(client,item)
{
	if(item==thisItem&&ValidPlayer(client))
	{
		War3_SetOwnsItem(client,item,true);
		War3_ChatMessage(client,"%T","your_footsteps",client);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && !(buttons & IN_USE) && War3_GetOwnsItem(client, thisItem) && GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
        {
            SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_ONGROUND);
        }
    }
    return Plugin_Continue;
}


public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
	}
}
