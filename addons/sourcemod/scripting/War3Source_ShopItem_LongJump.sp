#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include "sdkhooks"

#include <cstrike>

enum{
	JUMP,
}
new shopItem[MAXITEMS];//
new bool:bDidDie[65]; // did they die before spawning?
new Handle:JumpCvar;
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
// Offsets

public Plugin:myinfo =
{
	name = "War3Source Shopitem - Long Jump",
	author = "InsaNe",
	description = "Adds the Long Jump item to the War3Source shopmenu",
	version = "1.0.0.0",
	url = "http://surflords.net/"
};

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_spawn",PlayerSpawnEvent);
	HookEvent("player_death",PlayerDeathEvent);
	HookEvent("round_start",RoundStartEvent);
	HookEvent("player_jump",PlayerJumpEvent);
	JumpCvar=CreateConVar("war3_shop_jump_level","3.5","How far will you jump. The higher the number the further the player jumps.");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10){
		for(new x=0;x<MAXITEMS;x++)
			shopItem[x]=0;
		shopItem[JUMP] = War3_CreateShopItem("Boots of Bunny","longjump","Allows you to Long jump.",10,true);
		}
}
public OnItemPurchase(client,item)
{
	if(item==shopItem[JUMP])
	{
		if(IsPlayerAlive(client))
			War3_SetOwnsItem(client,item,true);
		if(IsPlayerAlive(client))
		{
			//War3_ChatMessage(client,"You have successfully purchased Boots of Bunny.");
		}
	}
}
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	for(new x=1;x<=MaxClients;x++)
	{
		bDidDie[client]=false;
		if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[JUMP]))
		{
			War3_SetOwnsItem(client,shopItem[JUMP],true);
		}
	}
}
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[JUMP]))
		{
            new Float:velocity[3]={0.0,0.0,0.0};
            velocity[0]= GetEntDataFloat(x,m_vecVelocity_0);
            velocity[1]= GetEntDataFloat(x,m_vecVelocity_1);
            velocity[0]*=GetConVarFloat(JumpCvar)*0.25;
            velocity[1]*=GetConVarFloat(JumpCvar)*0.25;
            SetEntDataVector(x,m_vecBaseVelocity,velocity,true);
        }
    }
}
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
	bDidDie[client]=false;
	if(War3_GetOwnsItem(client,shopItem[JUMP]))
        {
			War3_SetOwnsItem(client,shopItem[JUMP],false);
        }
	}
}
public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);

	if(client>0)
	{
		new deathFlags = GetEventInt(event, "death_flags");
		if (War3_GetGame()==Game_TF&&deathFlags & 32)
		{
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		}


		else{
			bDidDie[client]=true;
			if(War3_GetOwnsItem(client,shopItem[JUMP])) // long jump
			{
				War3_SetOwnsItem(client,shopItem[JUMP],false);
			}
		}
}
}
