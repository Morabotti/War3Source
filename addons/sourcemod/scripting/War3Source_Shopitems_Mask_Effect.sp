#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#define Model "models/player/holiday/facemasks/facemask_devil_plastic.mdl"
new maskid;

public Plugin:myinfo = 
{
    name = "War3Source Shopitem Mask Effect",
    author = "SenatoR",
    description = "",
    version = "1.0",
};
new g_MyMask[MAXPLAYERS+1];


public OnMapStart() 
{ 
	PrecacheModel(Model);
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
    maskid = War3_GetItemIdByShortname("mask");
}

public OnWar3EventSpawn(client){
	if(War3_GetOwnsItem(client,maskid)) GiveMask(client);
}
public OnWar3EventDeath(client){
	if(g_MyMask[client] != -1) RemoveMask(client);
}

public OnItemLost(client, item)
{
	if(War3_GetOwnsItem(client,maskid)) RemoveMask(client);
}

public OnClientPostAdminCheck(client)
{
	g_MyMask[client] = -1;
}
public OnItemPurchase(client, item)
{
	if(ValidPlayer(client,true) && War3_GetOwnsItem(client,maskid)) GiveMask(client);
}

RemoveMask(client)
{
	if(g_MyMask[client] != -1)
	{
		if(ValidPlayer(client)) if(IsValidEdict(g_MyMask[client])) AcceptEntityInput(g_MyMask[client], "Kill");
		g_MyMask[client] = -1;
	}
}
GiveMask(client)
{
	if(ValidPlayer(client,true) && g_MyMask[client] == -1)
	{
		
		decl Float:or[3], Float:ang[3],
		Float:fForward[3],
		Float:fRight[3],
		Float:fUp[3];
		
		GetClientAbsOrigin(client, or);
		GetClientAbsAngles(client, ang);
		new Float:fPos[3]  = {0.0,0.5,0.0};		
		new Float:fAng[3]  = {0.0,0.0,0.0};
		ang[0] += fAng[0];
		ang[1] += fAng[1];
		ang[2] += fAng[2];
		
		GetAngleVectors(ang, fForward, fRight, fUp);
		
		or[0] += fRight[0]*fPos[0] + fForward[0]*fPos[1] + fUp[0]*fPos[2];
		or[1] += fRight[1]*fPos[0] + fForward[1]*fPos[1] + fUp[1]*fPos[2];
		or[2] += fRight[2]*fPos[0] + fForward[2]*fPos[1] + fUp[2]*fPos[2];
		
		new ent = CreateEntityByName("prop_dynamic_override");
		
		DispatchKeyValue(ent, "model",Model);
		
		DispatchKeyValue(ent, "spawnflags", "256");
		DispatchKeyValue(ent, "solid", "0");
		
		DispatchSpawn(ent);	
		AcceptEntityInput(ent, "TurnOn", ent, ent);
			
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
		TeleportEntity(ent, or, ang, NULL_VECTOR); 
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", client, ent);
		SetVariantString("facemask");
		AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent);
		g_MyMask[client] = ent;
	}
}


public Action:ShouldHide(ent, client)
{
	new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (owner == client)
	{
		return Plugin_Handled;
	}
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
	{
		if (owner == GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}