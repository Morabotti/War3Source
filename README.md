# War3Source - MoraWCS #

This is very modded version of War3Source. This versio has 85 unique races with min-level of 32 each.

## Orginal README.me ##

War3Source brings the Warcraft 3 leveling style and races into the game. It is originally based on the amxmodx (AMX) version War3FT.

Each standard race has total of 16 levels, made up of 3 skills and 1 ultimate where each skill/ultimate can be leveled 4 times for a total of 16 levels.

War3Source features a modular design where races can be coded independently and loaded into the main plugin. Independent plugins (Addons) can be created to complement or change aspects War3Source.

There are also items in W3S as there are in all Warcraft mods.

War3Source is written in SourcePawn under the SourceMod extension.

War3Source is not WCS (warcraft-source), and we ask that you do not call it or refer to it as WCS (or even just "warcraft source") for any reason. W3S and WCS are similar such as they can feature the same races and they bring forth the same style of gameplay, but they are two completely different projects.

War3Source offers unbeatable performance and quality under SourcePawn and involves much more interaction between races. Procedural programming language easily allows for complex data interactions and pseudo-object oriented approach. Many subsystems are available to the coder that EventScripts does not offer, such as: A Cooldown System which simplifies skills and ultimate cooldowns A buff/debuff system where races are expected to respect other race's buffs and debuffs, resolves conflicts between races. A Aura tracking system which simplifies the coding and application of Auras. An internal event system for inter-plugin communication.

W3S came first to the source engine, WCS came later and matured faster under the nature of ES/Python prototyping languages, but reached its limit in performance and features compared to W3S.

The mod was originally founded by Anthony Iacono (AKA "pimpinjuice") who passed it on to Yi (Derek) Luo AKA Ownage | Ownz (DarkEnergy) who then passed it on to the community. To see a list of contributors since we've moved to Github check https://github.com/War3Source/War3Source/contributors

## Supported Games ##

The following games are currently supported by War3Source:

* Great support
 * Team Fortress 2
 * Counter-Strike Source
 * Counter-Strike: Global Offensive

* Engine support
 * Left 4 Dead
 * Left 4 Dead 2

If you plan to run War3Source with a Left4Dead game you will have to get custom tailored races and shopitems as the stock ones are not suited for Left4Dead gameplay

## Requirements ##

* A Gameserver with a supported game
 * A recent Sourcemod snapshot (http://www.sourcemod.net/snapshots.php, at least from the 1.5 branch)
 * A recent Metamod snapshot (http://www.sourcemm.net/snapshots, at least from the 1.10 branch)
 * Sourcemod configured to use a database (sqlite is fine)

## Installation guide ##

* If you don't know anything about compiling the source manually you can grab a compiled build from our build server at http://ownageclan.com/jenkins/job/War3Source-Default1/

* Simply put the addons folder into your game folder where Source- and Metamod should have already created a addons folder
* The sound folder belongs into your games sound folder as well as on your fastdl server
* The optional folder contains various things that are not necessary for a base installation

#test change 1
