#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Menu War3Menu",
    author = "War3Source Team",
    description = "Shows the war3menu"
};

public OnWar3Event(W3EVENT:event,client){
    if(event==DoShowWar3Menu){
        ShowWar3Menu(client);
    }
}

ShowWar3Menu(client){    
    new Handle:war3Menu=CreateMenu(War3Source_War3Menu_Select);
    SetSafeMenuTitle(war3Menu,"%T","[War3Source] Choose a task",client);
    new limit=10;
    new String:transbuf[32];
    new String:menustr[100];
    for(new i=0;i<=limit;i++)
    {
    
        Format(transbuf,sizeof(transbuf),"War3Menu_Item%d",i);
        Format(menustr,sizeof(menustr),"%T",transbuf,client);
        new String:numstr[4];
        Format(numstr,sizeof(numstr),"%d",i);
        
        AddMenuItem(war3Menu,numstr,menustr);
    }
    DisplayMenu(war3Menu,client,MENU_TIME_FOREVER);
}

public War3Source_War3Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        //decl String:SelectionInfo[4];
        //decl String:SelectionDispText[256];
        //new SelectionStyle;
    //    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        if(ValidPlayer(client))
        {
            switch(selection)
            {
                case 0: // shopmenu
                {
					W3CreateEvent(DoShowShopMenu,client);
                }
                case 1: // itemsinfo
                {
					W3CreateEvent(DoShowItemsInfoMenu,client);
                }
                case 2: // skillsinfo
                {
                    W3ShowSkillsInfo(client);
                }
                case 3: // resetskills
                {
					W3CreateEvent(DoResetSkills,client);
                }
                case 4: // spendskills
                {
					W3CreateEvent(DoShowSpendskillsMenu,client);
                }
                case 5: // changerace
                {
                    W3CreateEvent(DoShowChangeRaceMenu,client);
                }
                case 6: // raceinfo
                {        
                    W3CreateEvent(DoShowRaceinfoMenu,client);
                }
                case 7: // playerinfo
                {
                   W3CreateEvent(DoShowPlayerinfoMenu,client);
                }
                case 8: // war3help
                {
                    W3CreateEvent(DoShowHelpMenu,client);
                }
                case 9: // levebank
                {
                    W3CreateEvent(DoShowLevelBank,client);
                }
				case 10: // shopmenu2
                {
                    W3CreateEvent(DoShowShopMenu2,client);
                }
            }
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

