/**
* File: War3Source_Mr_Electric.sp
* Description: The Spider Man race for SourceCraft.
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
#include "W3SIncs/haaaxfunctions"
#include <sdktools_sound>



// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:ElectricGravity[9] = { 1.0, 0.95, 0.90, 0.85, 0.80, 0.77, 0.75, 0.73, 0.70 };
new Float:ShockChance[9] = { 0.0, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.43, 0.45 };
new Float:BounceChance[9] = { 0.0, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.43 };
new Float:BounceDuration[9] = { 0.0, 0.05, 0.1, 0.013, 0.016, 0.02, 0.023, 0.026, 0.03 };
new Float:JumpMultiplier[9] = { 1.0, 2.8, 2.9, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5 };
new StrikeDamage[9] = { 0, 5, 10, 15, 20, 25, 30, 35, 40 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new HaloSprite, BeamSprite, AttackSprite1, AttackSprite2, VictimSprite;

new String:lightningSound[] = "*mora-wcs/war3source/lightningbolt.mp3";
new String:lightningSound_FullPath[] = "sound/mora-wcs/war3source/lightningbolt.mp3";

new SKILL_ATTACK, SKILL_LONGJUMP, SKILL_BOUNCY, ULT_LSTRIKE;

public Plugin:myinfo =
{
    name = "War3Source Race - Mr Electric",
    author = "xDr.HaaaaaaaXx",
    description = "The Mr Electric race for War3Source.",
    version = "1.0.0.1",
    url = ""
};

public OnMapStart()
{
	AddFileToDownloadsTable(lightningSound_FullPath);
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_pinch_dudv_dx60.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/strider_pinch_dx70.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/models/airlock_laser.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/models/airlock_laser.vtf");
	
	HaloSprite = PrecacheModel( "materials/mora-wcs/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/mora-wcs/sprites/lgtning.vmt" );
	AttackSprite1 = PrecacheModel( "materials/mora-wcs/effects/strider_pinch_dudv_dx60.vmt" );
	AttackSprite2 = PrecacheModel( "materials/mora-wcs/models/airlock_laser.vmt" );
	VictimSprite = PrecacheModel( "materials/mora-wcs/sprites/crosshairs.vmt" );
	
	PrecacheSoundAny(lightningSound);
}

public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
    HookEvent( "player_jump", PlayerJumpEvent );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==440){
    thisRaceID = War3_CreateNewRace( "Mr Electric", "electric" );

    SKILL_ATTACK = War3_AddRaceSkill( thisRaceID, "Shocker", "Electric Blast into Enemies", false,8 );
    SKILL_LONGJUMP = War3_AddRaceSkill( thisRaceID, "Electricity Bounce", "Move at the speed of Electricity", false,8 );
    SKILL_BOUNCY = War3_AddRaceSkill( thisRaceID, "Unstable Electric Armor", "Electric Armor sends you bouncing", false,8 );
    ULT_LSTRIKE = War3_AddRaceSkill( thisRaceID, "Lightning Strike", "Lightning is the ultimate form of Natural Electricty", true,8 );

    War3_CreateRaceEnd( thisRaceID );

    W3SkillCooldownOnSpawn( thisRaceID, ULT_LSTRIKE, 5.0);
   }
}

public InitPassiveSkills( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {
        War3_SetBuff( client, fLowGravitySkill, thisRaceID, ElectricGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LONGJUMP )] );
        War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 100);
        SetEntityRenderFx( client, RENDERFX_FLICKER_FAST );
    }
}

public OnRaceChanged( client, oldrace, newrace )
{
    if( newrace != thisRaceID )
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {
        if( IsPlayerAlive( client ) )
        {
            InitPassiveSkills( client );
        }
    }
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
    InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        InitPassiveSkills( client );

        new Float:pos[3];
        GetClientAbsOrigin( client, pos );
        pos[2] += 40;
        TE_SetupBeamRingPoint( pos, 40.0, 90.0, VictimSprite, HaloSprite, 0, 0, 0.5, 50.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}

public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
            if( skill_level > 0 && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ShockChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new Float:velocity[3];

                velocity[0] += 0;
                velocity[1] += 0;
                velocity[2] += 300.0;

                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );

                War3_ShakeScreen( victim, 3.0, 50.0, 40.0 );

                W3FlashScreen( victim, RGBA_COLOR_RED );

                new Float:start_pos[3];
                new Float:target_pos[3];

                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );

                start_pos[2] += 20;
                target_pos[2] += 20;

                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite1, HaloSprite, 0, 0, 1.0, 10.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll();

                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite2, HaloSprite, 0, 0, 1.0, 15.0, 25.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll( 2.0 );
            }
        }
    }
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
        if( skill_long > 0 )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 0.25;
            velocity[1] *= JumpMultiplier[skill_long] * 0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        }
    }
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        if( vteam != ateam )
        {
            new race_victim = War3_GetRace( victim );
            new skill_bouncy = War3_GetSkillLevel( victim, thisRaceID, SKILL_BOUNCY );
            if( race_victim == thisRaceID && skill_bouncy > 0 && !Hexed( victim, false ) )
            {
                if( GetRandomFloat( 0.0, 1.0 ) <= BounceChance[skill_bouncy] && !W3HasImmunity( attacker, Immunity_Skills ) )
                {
                    new Float:pos1[3];
                    new Float:pos2[3];
                    new Float:localvector[3];
                    new Float:velocity1[3];
                    new Float:velocity2[3];

                    GetClientAbsOrigin( attacker, pos1 );
                    GetClientAbsOrigin( victim, pos2 );

                    localvector[0] = pos1[0] - pos2[0];
                    localvector[1] = pos1[1] - pos2[1];
                    localvector[2] = pos1[2] - pos2[2];

                    velocity1[0] += 0;
                    velocity1[1] += 0;
                    velocity1[2] += 300;

                    velocity2[0] = localvector[0] * ( 100 * 5 );
                    velocity2[1] = localvector[1] * ( 100 * 5 );

                    SetEntDataVector( victim, m_vecBaseVelocity, velocity1, true );
                    SetEntDataVector( victim, m_vecBaseVelocity, velocity2, true );

                    War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.0 );
                    War3_SetBuff( victim, bDoNotInvisWeapon, thisRaceID, true);

                    CreateTimer( BounceDuration[skill_bouncy], InvisStop, victim );

                    new Float:pos[3];

                    GetClientAbsOrigin( victim, pos );

                    pos[2] += 40;

                    TE_SetupBeamRingPoint( pos, 40.0, 90.0, VictimSprite, HaloSprite, 0, 0, 0.5, 50.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
                    TE_SendToAll();
                }
            }
        }
    }
}

public Action:InvisStop( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_LSTRIKE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_LSTRIKE, true ) )
            {
               new target=War3_GetTargetInViewCone(client,2000.0,false);
               if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
               {

                   new dmg=StrikeDamage[ult_level];

                   if( War3_DealDamage(target,dmg,client,DMG_GENERIC,"Electrocuted") )
                   {
						EmitSoundToAllAny(lightningSound,target);
						EmitSoundToAllAny(lightningSound,client);
						War3_CooldownMGR(client,20.0,thisRaceID,ULT_LSTRIKE);
						new Float:pos[3];
						GetClientAbsOrigin( client, pos );
						pos[2] += 40;
						TE_SetupBeamRingPoint( pos, 20.0, 50.0, BeamSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
						TE_SendToAll();
						W3FlashScreen( target, RGBA_COLOR_RED );
                   }
               }
               else
               {
                   W3MsgNoTargetFound(client,2000.0);
               }
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}
