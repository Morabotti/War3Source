/**
* File: War3Source_CustomRace_Witch_Doctor.sp
* Description: The Witch Doctor race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
// skill 1
new Float:GetSpellChance[9] = { 0.0, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33 };
new bool:bSmokeAttached[MAXPLAYERS];
new spells[MAXPLAYERS + 1];
new smoke[MAXPLAYERS];

// skill 2
#define MAXWARDS 64*5 //on map LOL
#define WARDDAMAGE 20
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 140.0
#define WARDHEALTH 1

new WardRadius[9] = { 60, 70, 80, 90, 100, 110, 120, 130, 140 };
new WardStartingArr[9] = { 1, 2, 2, 3, 3, 4, 5, 6, 6 };
new Float:LastThunderClap[MAXPLAYERS];
new Float:WardLocation[MAXWARDS][3];
new Float:LastWardRing[MAXWARDS];
new Float:LastWardClap[MAXWARDS];
new CurrentWardCount[MAXPLAYERS];
new WardOwner[MAXWARDS];
new WardType[MAXWARDS];

new String:WardSnd[] = "*mora-wcs/war3source/morabotti/hole_hit2.mp3";
new String:WardSnd_FullPath[] = "sound/mora-wcs/war3source/morabotti/hole_hit2.mp3";
new String:WardSnd2[] = "*mora-wcs/war3source/morabotti/wind_snippet2.mp3";
new String:WardSnd2_FullPath[] = "sound/mora-wcs/war3source/morabotti/wind_snippet2.mp3";

// skill 3
new Float:FlickChance[9] = { 0.0, 0.15, 0.17, 0.19, 0.21, 0.23, 0.25, 0.28, 0.30 };

// skill 4
new bool:bMagicAttached[MAXPLAYERS];
new ClientWardType[MAXPLAYERS];
new magic[MAXPLAYERS];

new BlueBlackLargeBeamSprite, LightningSprite, TPBeamSprite, PurpleGlowSprite, StriderBulgeSprite; 

new String:BlueBlackLargeBeamSprite_FullPath[] = "materials/mora-wcs/effects/blueblacklargebeam.vmt";
new String:BlueBlackLargeBeamSpriteVTF_FullPath[] = "materials/mora-wcs/effects/blueblacklargebeam.vtf";
new String:TPBeamSprite_FullPath[] = "materials/mora-wcs/sprites/tp_beam001.vmt";
new String:TPBeamSpriteVTF_FullPath[] = "materials/mora-wcs/sprites/tp_beam001.vtf";
new String:TPBeamSpriteVTF2_FullPath[] = "materials/mora-wcs/sprites/physbeam.vtf";
new String:PurpleGlowSprite_FullPath[] = "materials/mora-wcs/sprites/purpleglow1.vmt";
new String:PurpleGlowSpriteVTF_FullPath[] = "materials/mora-wcs/sprites/purpleglow1.vtf";
new String:StriderBulgeSprite_FullPath[] = "materials/mora-wcs/effects/strider_bulge_dudv_dx60.vmt";
new String:StriderBulgeSpriteVTF_FullPath[] = "materials/mora-wcs/effects/strider_pinch_dx70.vtf";
new SKILL_SPELL, SKILL_WARD, SKILL_FLICK, ULT_BOOK;

public Plugin:myinfo = 
{
	name = "War3Source Race - Witch Doctor",
	author = "xDr.HaaaaaaaXx",
	description = "The Witch Doctor race for War3Source.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	CreateTimer( 0.14, CalcWards, _, TIMER_REPEAT );
}

public OnMapStart()
{
	
	AddFileToDownloadsTable(BlueBlackLargeBeamSprite_FullPath);
	AddFileToDownloadsTable(BlueBlackLargeBeamSpriteVTF_FullPath);
	AddFileToDownloadsTable(TPBeamSprite_FullPath);
	AddFileToDownloadsTable(TPBeamSpriteVTF_FullPath);
	AddFileToDownloadsTable(TPBeamSpriteVTF2_FullPath);
	AddFileToDownloadsTable(PurpleGlowSprite_FullPath);
	AddFileToDownloadsTable(PurpleGlowSpriteVTF_FullPath);
	AddFileToDownloadsTable(StriderBulgeSprite_FullPath);
	AddFileToDownloadsTable(StriderBulgeSpriteVTF_FullPath);
	
	AddFileToDownloadsTable(WardSnd_FullPath);
	AddFileToDownloadsTable(WardSnd2_FullPath);
	
	StriderBulgeSprite = PrecacheModel( "materials/mora-wcs/effects/strider_bulge_dudv_dx60.vmt" );
	PurpleGlowSprite = PrecacheModel( "materials/mora-wcs/sprites/purpleglow1.vmt" );
	LightningSprite = PrecacheModel( "materials/mora-wcs/sprites/lgtning.vmt" );
	BlueBlackLargeBeamSprite = PrecacheModel( "materials/mora-wcs/effects/blueblacklargebeam.vmt" );
	TPBeamSprite = PrecacheModel( "materials/mora-wcs/sprites/tp_beam001.vmt" );
	PrecacheModel( "materials/mora-wcs/effects/combinemuzzle2.vmt", true);
	PrecacheSoundAny( WardSnd );
	PrecacheSoundAny( WardSnd2 );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==590){
	thisRaceID = War3_CreateNewRace( "Witch Doctor", "witchdoctor" );
	
	SKILL_SPELL = War3_AddRaceSkill( thisRaceID, "Spell Points", "12% - 33% chance to Gain Spell Points when killing an enemy.", false, 8 );
	SKILL_WARD = War3_AddRaceSkill( thisRaceID, "Spell Power", "(+ability)Radius and amount of your Spells.", false, 8 );
	SKILL_FLICK = War3_AddRaceSkill( thisRaceID, "Flickering Cloak", "Gain Invisibility that Flickers when hit. Chance: 12% - 33%.", false, 8 );
	ULT_BOOK = War3_AddRaceSkill( thisRaceID, "Book of Spells", "(+ultimate) Choose a spell that you cast (+ability)", false, 4 );
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public OnClientPutInServer( client )
{
	spells[client] = 1;
	ClientWardType[client] = 0;
}

public OnWar3PlayerAuthed( client )
{
	LastThunderClap[client] = 0.0;
}

public OnWar3EventSpawn( client )
{
	if( War3_GetRace( client ) == thisRaceID && War3_GetSkillLevel( client, thisRaceID, SKILL_WARD ) > 0 )
	{
		AttachSpawnEffect( client );
	}
	RemoveWards( client );
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3RaceSelected(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		RemoveWards( client );
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( victim ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_FLICK );
			if( !Hexed( victim, false ) && GetRandomFloat( 0.0, 1.0 ) <= FlickChance[skill_level] )
			{
				SetEntityRenderFx( victim, RENDERFX_FLICKER_FAST );
				CreateTimer( 5.0, StopFlick, victim );
			}
		}
	}
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_spell = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SPELL );
			if( !Hexed( attacker, false ) && W3Chance( GetSpellChance[skill_spell] * W3ChanceModifier( attacker ) ) )
			{
				spells[attacker]++;
				if( spells[attacker] > 20 )
				{
					spells[attacker] = 20;
				}
				else
				{
					PrintToChat( attacker, "\x03You have Gained\x04 1 \x03Spell Point! Now you have \x04%i \x03spells!", spells[attacker] );
				}
				AttachSmoke( attacker );
			}
		}
	}
}

public Action:StopFlick( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		SetEntityRenderFx( client, RENDERFX_NONE );
	}
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] && spells[client] > 0 )
			{
				spells[client]--;
				CreateWard( client );
				CurrentWardCount[client]++;
				W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
			}
			else
			{
				W3MsgNoWardsLeft( client );
			}
		}
	}
	if( War3_GetRace( client ) == thisRaceID && ability == 1 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			new Float:ClientPos[3];
			GetClientAbsOrigin( client, ClientPos );
			for( new i = 0; i < MAXWARDS; i++ )
			{
				if( WardOwner[i] == client )
				{
					if( GetVectorDistance( ClientPos, WardLocation[i] ) <= 60 )
					{
						LastWardClap[i] = 0.0;
						LastWardRing[i] = 0.0;
						WardOwner[i] = 0;
						WardType[i] = 0;
						CurrentWardCount[client]--;
					}
				}
			}
		}
	}
}

public CreateWard( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == 0 && ClientWardType[client] != 0 )
		{
			WardOwner[i] = client;
			GetClientAbsOrigin( client, WardLocation[i] );
			WardType[i] = ClientWardType[client];
			if( WardType[i] == 1 )
				PrintToChat( client, "\x03You planted \x05.:\x04True Sight Ward\x05:. \x03Now you have \x04%i \x03spells!", spells[client] );
			if( WardType[i] == 2 )
				PrintToChat( client, "\x03You planted \x05.:\x04Stasis Trap\x05:. \x03Now you have \x04%i \x03spells!", spells[client] );
			if( WardType[i] == 3 )
				PrintToChat( client, "\x03You planted \x05.:\x04Damage Trap\x05:. \x03Now you have \x04%i \x03spells!", spells[client] );
			if( WardType[i] == 4 )
				PrintToChat( client, "\x03You planted \x05.:\x04Healing Ward:.\x05 \x03Now you have \x04%i \x03spells!", spells[client] );
			break;
		}
	}
}

public RemoveWards( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == client )
		{
			LastWardClap[i] = 0.0;
			LastWardRing[i] = 0.0;
			WardOwner[i] = 0;
			WardType[i] = 0;
		}
	}
	CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
	new client;
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] != 0 )
		{
			client = WardOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				WardOwner[i] = 0;
				--CurrentWardCount[client];
				WardType[i] = 0;
			}
			else
			{
				WardEffectAndDamage( client, i );
			}
		}
	}
}

public WardEffectAndDamage( owner, wardindex )
{
	new WARDRADIUS = WardRadius[War3_GetSkillLevel( owner, thisRaceID, SKILL_WARD )];
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 25, 0, 255, 255 };
	if( ownerteam == 2 )
	{
		beamcolor[0] = 255;
		beamcolor[1] = 0;
		beamcolor[2] = 25;
		beamcolor[3] = 128;
	}
	
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };
	
	AddVectors( WardLocation[wardindex], tempVec1, start_pos );
	AddVectors( WardLocation[wardindex], tempVec2, end_pos );
	
	if( WardType[wardindex] == 1 )
	{
		if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
		{
			LastWardRing[wardindex] = GetGameTime();
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 255, 255, 255, 100 }, 5, FBEAM_ISACTIVE );
			TE_SendToAll();
		}
		
		TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
		TE_SendToAll();
		
		TE_SetupGlowSprite( end_pos, StriderBulgeSprite, 1.0, 1.0, 50 );
		TE_SendToAll();
	}
	if( WardType[wardindex] == 2 )
	{
		if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
		{
			LastWardRing[wardindex] = GetGameTime();
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 25, 25, 255, 100 }, 5, FBEAM_ISACTIVE );
			TE_SendToAll();
		}
		
		TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
		TE_SendToAll();
		
		TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
		TE_SendToAll();
	}
	if( WardType[wardindex] == 3 )
	{
		if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
		{
			LastWardRing[wardindex] = GetGameTime();
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 255, 25, 25, 100 }, 5, FBEAM_ISACTIVE );
			TE_SendToAll();
		}
		
		TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
		TE_SendToAll();
		
		TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
		TE_SendToAll();
	}
	if( WardType[wardindex] == 4 )
	{
		if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
		{
			LastWardRing[wardindex] = GetGameTime();
			TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 25, 255, 25, 255 }, 5, FBEAM_ISACTIVE );
			TE_SendToAll( 0.1 );
		}
		
		TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
		TE_SendToAll();

		TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
		TE_SendToAll();
	}
	
	new Float:BeamXY[3];
	for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
	new Float:BeamZ = BeamXY[2];
	BeamXY[2] = 0.0;
	
	new Float:VictimPos[3];
	new Float:tempZ;
	if( WardType[wardindex] == 1 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
			{
				GetClientAbsOrigin( i, VictimPos );
				tempZ = VictimPos[2];
				VictimPos[2] = 0.0;
				
				if( GetVectorDistance( BeamXY, VictimPos ) <= WARDRADIUS )
				{
					if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
					{
						if( !W3HasImmunity( i, Immunity_Skills ) )
						{
							War3_SetBuff( i, bInvisibilityDenyAll, thisRaceID, true );
						}
						else
						{
							War3_SetBuff( i, bInvisibilityDenyAll, thisRaceID, false );
						}
					}
					else
					{
						War3_SetBuff( i, bInvisibilityDenyAll, thisRaceID, false );
					}
				}
				else
				{
					War3_SetBuff( i, bInvisibilityDenyAll, thisRaceID, false );
				}
			}
		}
	}
	if( WardType[wardindex] == 2 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
			{
				GetClientAbsOrigin( i, VictimPos );
				tempZ = VictimPos[2];
				VictimPos[2] = 0.0;
				
				if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
				{
					if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
					{
						if( !W3HasImmunity( i, Immunity_Skills ) )
						{
							if( LastWardClap[wardindex] < GetGameTime() - 1.0 )
							{
								War3_SetBuff( i, fSlow, thisRaceID, 0.5 );
								
								CreateTimer( 2.0, StopSlow, i );
								
								LastWardClap[i] = GetGameTime();
							}
						}
					}
				}
			}
		}
	}
	if( WardType[wardindex] == 3 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
			{
				GetClientAbsOrigin( i, VictimPos );
				tempZ = VictimPos[2];
				VictimPos[2] = 0.0;
				
				if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
				{
					if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
					{
						if( !W3HasImmunity( i, Immunity_Skills ) )
						{
							if( LastWardClap[wardindex] < GetGameTime() - 1.0 )
							{
								new DamageScreen[4];
								new Float:pos[3];
								
								GetClientAbsOrigin( i, pos );
								
								DamageScreen[0] = beamcolor[0];
								DamageScreen[1] = beamcolor[1];
								DamageScreen[2] = beamcolor[2];
								DamageScreen[3] = 50;
								
								W3FlashScreen( i, DamageScreen );
								
								War3_DealDamage( i, WARDDAMAGE, owner, DMG_ENERGYBEAM, "wards", _, W3DMGTYPE_MAGIC );
								
								pos[2] += 40;
								
								TE_SetupBeamPoints( start_pos, pos, LightningSprite, LightningSprite, 0, 0, 1.0, 10.0, 20.0, 0, 0.0, { 255, 150, 70, 255 }, 0 );
								TE_SendToAll();
								
								LastWardClap[wardindex] = GetGameTime();
							}
						}
					}
				}
			}
		}
	}
	if( WardType[wardindex] == 4 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam(i) == ownerteam )
			{
				GetClientAbsOrigin( i, VictimPos );
				tempZ = VictimPos[2];
				VictimPos[2] = 0.0;
				
				if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
				{
					if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
					{
						if( GetClientHealth( i ) != War3_GetMaxHP( i ) )
						{							
							War3_HealToMaxHP( i, WARDHEALTH );
						}
					}
				}
			}
		}
	}
}

public Action:StopSlow( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( ValidPlayer( client, false ) && pressed && race == thisRaceID )
	{
		new skill_book = War3_GetSkillLevel( client, race, ULT_BOOK );
		if( skill_book > 0 )
		{
			DoSpellMenu( client );
			if( ValidPlayer( client, true ) )
			{
				AttachMagic( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public DoSpellMenu( client )
{
	new Handle:spellMenu = CreateMenu( War3Source_Spell_Selected );
	
	SetMenuExitButton( spellMenu, true );
	
	new String:title[64];
	
	Format( title, 64, ".:Book of Spells:.\n.:You have %i spells:.", spells[client] );
	
	SetMenuTitle( spellMenu, title );
	
	new level = War3_GetSkillLevel( client, thisRaceID, ULT_BOOK );
	
	new String:sight[32] = ".:True Sight Ward:.";
	new String:stasis[32] = ".:Stasis Trap:.";
	new String:damage[32] = ".:Damage Trap:.";
	new String:heal[32] = ".:Healing Ward:.";
	
	if( ClientWardType[client] == 1 )
	{
		sight = ">.:True Sight Ward:.";
	}
	if( ClientWardType[client] == 2 )
	{
		stasis = ">.:Stasis Trap:.";
	}
	if( ClientWardType[client] == 3 )
	{
		damage = ">.:Damage Trap:.";
	}
	if( ClientWardType[client] == 4 )
	{
		heal = ">.:Healing Ward:.";
	}
	
	AddMenuItem( spellMenu, "", sight,  ITEMDRAW_DEFAULT );
	AddMenuItem( spellMenu, "", stasis, ( level > 1 ) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
	AddMenuItem( spellMenu, "", damage, ( level > 2 ) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
	AddMenuItem( spellMenu, "", heal,   ( level > 3 ) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
	
	DisplayMenu( spellMenu, client, 15 );
}

public War3Source_Spell_Selected( Handle:menu, MenuAction:action, client, selection )
{
	if( action == MenuAction_Select )
	{
		if( selection == 0 )
		{
			ClientWardType[client] = 1;
			PrintToChat( client, "\x05.:\x04True Sight Ward\x05:." );
		}
		else if( selection == 1 )
		{
			ClientWardType[client] = 2;
			PrintToChat( client, "\x05.:\x04Stasis Trap\x05:." );
		}
		else if( selection == 2 )
		{
			ClientWardType[client] = 3;
			PrintToChat( client, "\x05.:\x04Damage Trap\x05:." );
		}
		else if( selection == 3 )
		{
			ClientWardType[client] = 4;
			PrintToChat( client, "\x05.:\x04Healing Ward:.\x05" );
		}
	}
	if( action == MenuAction_End )
	{
		CloseHandle( menu );
	}
}

stock AttachSmoke( client )
{
	if( !bSmokeAttached[client] )
	{
		smoke[client] = CreateEntityByName( "env_smokestack" );
		bSmokeAttached[client] = true;
		
		if( IsValidEdict( smoke[client] ) && IsClientInGame( client ) )
		{
			decl Float:fPos[3], Float:fAng[3] = { 0.0, 0.0, 0.0 };
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", fPos );
			fPos[2] += 38;
			//Set Key Values
			DispatchKeyValueVector( smoke[client], "Origin", fPos );
			DispatchKeyValueVector( smoke[client], "Angles", fAng );
			DispatchKeyValueFloat( smoke[client], "BaseSpread", 50.0 );
			DispatchKeyValueFloat( smoke[client], "StartSize", 5.0 );
			DispatchKeyValueFloat( smoke[client], "EndSize", 1.0 );
			DispatchKeyValueFloat( smoke[client], "Twist", 500.0 );
			
			DispatchKeyValue( smoke[client], "SmokeMaterial", "particle/fire.vmt" );
			DispatchKeyValue( smoke[client], "RenderColor", "100 100 220" );
			DispatchKeyValue( smoke[client], "SpreadSpeed", "10" );
			DispatchKeyValue( smoke[client], "RenderAmt", "100" );
			DispatchKeyValue( smoke[client], "JetLength", "100" );
			DispatchKeyValue( smoke[client], "RenderMode", "18" );
			DispatchKeyValue( smoke[client], "Initial", "0" );
			DispatchKeyValue( smoke[client], "Speed", "50" );
			DispatchKeyValue( smoke[client], "Rate", "200" );
			DispatchSpawn( smoke[client] );
			
			//Set Entity Inputs
			SetVariantString( "!activator" );
			AcceptEntityInput( smoke[client], "SetParent", client, smoke[client], 0 );
			AcceptEntityInput( smoke[client], "TurnOn" );
			CreateTimer( 3.0, StopSmoke, client );
		}
		else
		{
			LogError( "Failed to create env_smokestack!" );
		}
	}
}

public Action:StopSmoke( Handle:timer, any:client )
{
	bSmokeAttached[client] = false;
	AcceptEntityInput( smoke[client], "TurnOff" );
	AcceptEntityInput( smoke[client], "Kill" );
}

stock AttachMagic( client )
{
	if( !bMagicAttached[client] )
	{
		magic[client] = CreateEntityByName( "env_smokestack" );
		bMagicAttached[client] = true;
		
		if( IsValidEdict( magic[client] ) && IsClientInGame( client ) )
		{
			decl Float:fPos[3];
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", fPos );
			fPos[2] += 38;
			//Set Key Values
			DispatchKeyValueVector( magic[client], "Origin", fPos );
			DispatchKeyValueFloat( magic[client], "BaseSpread", 11.0 );
			DispatchKeyValueFloat( magic[client], "StartSize", 16.0 );
			DispatchKeyValueFloat( magic[client], "EndSize", 1.0 );
			DispatchKeyValueFloat( magic[client], "Twist", 50.0 );
			
			DispatchKeyValue( magic[client], "SpreadSpeed", "40" );
			DispatchKeyValue( magic[client], "Speed", "60" );
			DispatchKeyValue( magic[client], "Rate", "50" );
			DispatchKeyValue( magic[client], "JetLength", "150" );
			DispatchKeyValue( magic[client], "RenderColor", "115 79 183" );
			DispatchKeyValue( magic[client], "RenderAmt", "200" );
			DispatchKeyValue( magic[client], "SmokeMaterial", "materials/mora-wcs/effects/combinemuzzle2.vmt" );
			DispatchSpawn( magic[client] );
			
			//Set Entity Inputs
			SetVariantString( "!activator" );
			AcceptEntityInput( magic[client], "SetParent", client, magic[client], 0 );
			AcceptEntityInput( magic[client], "TurnOn" );
			CreateTimer( 8.0, StopMagic, client );
			EmitSoundToAllAny( WardSnd2, client );
		}
		else
		{
			LogError( "Failed to create env_smokestack!" );
		}
	}
}

public Action:StopMagic( Handle:timer, any:client )
{
	bMagicAttached[client] = false;
	AcceptEntityInput( magic[client], "TurnOff" );
	AcceptEntityInput( magic[client], "Kill" );
}

stock AttachSpawnEffect( client )
{
	new Float:pos1[3];
	new Float:pos2[3];
	
	GetClientAbsOrigin( client, pos1 );
	GetClientAbsOrigin( client, pos2 );
	
	pos2[2] += 1110;
	
	TE_SetupBeamPoints( pos1, pos2, LightningSprite, LightningSprite, 0, 100, 3.0, 1.0, 1.0, 10, 1.0, { 255, 255, 255, 255 }, 100 );
	TE_SendToAll();
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 2.2 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 2.2 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 2.0 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 2.0 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 1.8 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 1.8 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 1.4 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 1.4 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 1.2 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 1.2 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 1.0 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 1.0 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 0.8 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 0.8 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 0.6 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 0.6 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 0.4 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 0.4 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll( 0.2 );
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll( 0.2 );
	
	pos1[2] += 110;
	
	TE_SetupBeamRingPoint( pos1, 199.0, 150.0, TPBeamSprite, TPBeamSprite, 0, 0, 2.0, 23.0, 0.0, { 15, 5, 255, 255 }, 9, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	TE_SetupBeamPoints( pos1, pos2, BlueBlackLargeBeamSprite, BlueBlackLargeBeamSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 20, 15, 255, 255 }, 0 );
	TE_SendToAll();
	
	EmitSoundToAllAny( WardSnd, client );
}