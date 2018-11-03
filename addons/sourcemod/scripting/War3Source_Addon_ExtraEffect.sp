#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo =
{
    name = "War3Source - Addon - Extra Effects",
    author = "MoravitunBotti",
    description = "",
    url = ":))"
};

public OnMapStart()
{
	AddFileToDownloadsTable("materials/mora-wcs/sprites/floorfire4_.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/floorfire4_.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/redglow3.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/sprites/redglow3.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/com_shield003a.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/Effects/combineshield/comshieldwall.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/Effects/Combineshield/comshieldwall_close.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fluttercore.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/fluttercore.vtf");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combinemuzzle2.vmt");
	AddFileToDownloadsTable("materials/mora-wcs/effects/combinemuzzle2.vtf");
}