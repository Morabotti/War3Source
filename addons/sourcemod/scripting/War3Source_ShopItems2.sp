/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 *
 *-- Added mypiggybank  == Cash Regen for MVM
 *-- Uncomment line 143 in order to enable it.
 *--
 *-- El Diablo
 *-- www.war3evo.com
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <cstrike>

enum ITEMENUM{
  WEAPON_M4A4=0,
  WEAPON_M4A1_S,
  WEAPON_AK47,
  WEAPON_AUG,
  WEAPON_SG556,
  WEAPON_AWP,
  WEAPON_GALIL,
  WEAPON_FAMAS,
  WEAPON_SCOUT,
  WEAPON_MAG,
  WEAPON_DEAGLE,
  WEAPON_M249,
  WEAPON_NEGEV,
  WEAPON_P90,
  WEAPON_G3SG1,
  WEAPON_NADES,
  //CASH_REGEN,
  //DIE_LAUGHING,
  //SCROLL_OF_REVIVE,
  //SCROLL_OF_ESSENCE
  /*
  //basic "Accessories"
  striders
  
  soulscream ring , Alchemist's Bones, charged hammer
  Trinket of Restoration
  sustainer
  
  //support
  ring of the teacher
  Refreshing Ornament
  Shield of the Five
  helm
  headdress
  
  //protective
  Iron Shield
  daemonic breastplate
  frostfield plate  
  behe's heart
  snake bracelet
  barbed armor
  //combata
  spell shards??? needs some recoding
  thunderclaw
  modk of brilliance
  warclept - attack speed
  //morph 
  shiel dbreakder
  frostburn
  some leech 
  
  
  
  
  
  
  */
}

new ItemID[MAXITEMS];

public Plugin:myinfo = 
{
  name = "W3S - Shopitems2",
  author = "Ownz",
  description = "The shop items that come with War3Source.",
  version = "1.0.0.0",
  url = "http://war3source.com/"
};

public OnPluginStart()
{
  //RegConsoleCmd("+ability1",War3Source_AbilityCommand);
  //RegConsoleCmd("-ability1",War3Source_AbilityCommand);
    
  //CreateTimer(1.0,test,_,TIMER_REPEAT);
  W3CreateCvar("w3shop2items","loaded","is the shop2 loaded");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
  if(num==10){

    for(new x=0;x<MAXITEMS;x++)
      ItemID[x]=0;

    ItemID[WEAPON_M4A4]=War3_CreateShopItem2T("weaponm4a4",15);
    if(ItemID[WEAPON_M4A4]==0){
      DP("ERR ITEM ID RETURNED IS ZERO");
    }
    ItemID[WEAPON_M4A1_S]=War3_CreateShopItem2T("m4a1s",15);
    ItemID[WEAPON_AK47]=War3_CreateShopItem2T("ak47",15);
    ItemID[WEAPON_AUG]=War3_CreateShopItem2T("aug",15);
    ItemID[WEAPON_SG556]=War3_CreateShopItem2T("sg556",15);
    ItemID[WEAPON_AWP]=War3_CreateShopItem2T("awp",20);
    ItemID[WEAPON_GALIL]=War3_CreateShopItem2T("galilar",10);
    ItemID[WEAPON_FAMAS]=War3_CreateShopItem2T("famas",150);
    ItemID[WEAPON_SCOUT]=War3_CreateShopItem2T("scout",8);
    ItemID[WEAPON_MAG]=War3_CreateShopItem2T("mag7",8);
    ItemID[WEAPON_DEAGLE]=War3_CreateShopItem2T("deagle",5);
    ItemID[WEAPON_M249]=War3_CreateShopItem2T("m249",15);
    ItemID[WEAPON_NEGEV]=War3_CreateShopItem2T("negev",15);
    ItemID[WEAPON_P90]=War3_CreateShopItem2T("p90",10);
    ItemID[WEAPON_G3SG1]=War3_CreateShopItem2T("g3sg1",15);
    ItemID[WEAPON_NADES]=War3_CreateShopItem2T("nades",8);
  }
}

public OnItem2Purchase(client,item)
{
	//DP("purchase %d %d",client,item);
	if(item==ItemID[WEAPON_M4A4] )
	{
		GivePlayerItem(client, "weapon_m4a1");
	}
	if(item==ItemID[WEAPON_M4A1_S] ) 
	{
		GivePlayerItem(client, "weapon_m4a1_silencer");
	}
	if(item==ItemID[WEAPON_AK47] ) 
	{
		GivePlayerItem(client, "weapon_ak47");
	}
	if(item==ItemID[WEAPON_AUG]){
		GivePlayerItem(client, "weapon_aug");
	}
	if(item==ItemID[WEAPON_SG556] )
	{
		GivePlayerItem(client, "weapon_sg556");
	}
	if(item==ItemID[WEAPON_AWP] ) 
	{
		GivePlayerItem(client, "weapon_awp");
	}
	if(item==ItemID[WEAPON_GALIL] ) 
	{
		GivePlayerItem(client, "weapon_galilar");
	}
	if(item==ItemID[WEAPON_FAMAS]){
		GivePlayerItem(client, "weapon_famas");
	}
	if(item==ItemID[WEAPON_SCOUT]){
		GivePlayerItem(client, "weapon_ssg08");
	}
	if(item==ItemID[WEAPON_MAG]){
		GivePlayerItem(client, "weapon_mag7");
	}
	if(item==ItemID[WEAPON_DEAGLE]){
		GivePlayerItem(client, "weapon_deagle");
	}
	if(item==ItemID[WEAPON_M249]){
		GivePlayerItem(client, "weapon_m249");
	}
	if(item==ItemID[WEAPON_NEGEV]){
		GivePlayerItem(client, "weapon_negev");
	}
	if(item==ItemID[WEAPON_P90]){
		GivePlayerItem(client, "weapon_p90");
	}
	if(item==ItemID[WEAPON_G3SG1]){
		GivePlayerItem(client, "weapon_g3sg1");
	}
	if(item==ItemID[WEAPON_NADES]){
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}
