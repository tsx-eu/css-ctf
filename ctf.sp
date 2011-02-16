#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <phun>

public Plugin:myinfo = {
	name = "CTF",
	author = "KoSSoLaX`",
	description = "Capture The Flag System",
	version = "1.0",
	url = "http://www.ts-x.eu/"
}

enum enum_flag_type {
	flag_red = 0,
	flag_blue,
	flag_neutral,
	flag_max
};

new Handle:g_hBDD = INVALID_HANDLE;
new String:g_szError[1024];


new Float:g_vecFlags[flag_max][3];
new g_iFlags_Entity[flag_max];
new g_iFlags_Base[flag_max];
new g_iFlags_Carrier[flag_max];

public OnPluginStart() {
	RegAdminCmd("sm_ctf_mapconfig", Cmd_MapConfig, ADMFLAG_BAN, "Gestion de la config de la map pour un CTF");
	
	HookEvent("round_start", 	EventRoundStart, 	EventHookMode_Post);
}
public OnMapStart() {
	g_hBDD = SQL_Connect("default", true, g_szError, sizeof( g_szError ));
	if( g_hBDD == INVALID_HANDLE ) {
		SetFailState("Connexion impossible: %s", g_szError);
	}
	
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.dx80.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.vvd");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.dx90.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.sw.vtx");

	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_blu.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_black.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_neutral.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_black.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_gold.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_gold.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_neutral.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_blu.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_red.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_red.vtf");
	
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.sw.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.phy");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.vvd");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.dx80.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.dx90.vtx");
	
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_red.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_blue.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_normal.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_blue.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_red.vmt");
	
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/HumiliatingDefeat.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagTaken.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagDropped.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveWonTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/FlawlessVictory.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveLostTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamDominating.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagTaken.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveTheFlag.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/TheEnemyHasYourFlag.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamScores.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/FinalRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouAreOnRed.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouAreOnBlue.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamWinsTheRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamWinsTheRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamTakesTheLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamTakesTheLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamScores.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagReturned.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagReturned.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagDropped.mp3");

	PrecacheModel("models/DeadlyDesire/ctf/flag.mdl");
	PrecacheModel("models/DeadlyDesire/ctf/cap_point_base.mdl");
}
public OnMapEnd() {
	CloseHandle(g_hBDD);
}
public Action:EventRoundStart(Handle:Event, const String:Name[], bool:Broadcast) {
	
	CTF_SpawnFlag(flag_red);
	CTF_SpawnFlag(flag_blue);	
	
	return Plugin_Continue;
}
public Action:Cmd_MapConfig(client, args) {
	Menu_MapConfig(client);
	
	return Plugin_Handled;
}
public Menu_MapConfig(client) {
	
	new Handle:menu = CreateMenu(hMenu_MapConfig);
	
	SetMenuTitle(menu, "CTF: admin menu");
	
	AddMenuItem(menu, "spawn_red", "Spawn RED-FLAG");
	AddMenuItem(menu, "spawn_blue", "Spawn BLUE-FLAG");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	
	return;
}
public hMenu_MapConfig(Handle:hMenu, MenuAction:action, client, param2) {
	
	if( action == MenuAction_Select ) {
		
		new String:options[64];
		GetMenuItem(hMenu, param2, options, 63);
		
		if( StrEqual( options, "spawn_red", false) ) {
			
			GetClientAimLocation(client, g_vecFlags[flag_red]);
			CTF_SpawnFlag(flag_red);
		}
		else if( StrEqual( options, "spawn_blue", false) ) {
			GetClientAimLocation(client, g_vecFlags[flag_blue]);
			CTF_SpawnFlag(flag_blue);
		}
		Menu_MapConfig(client);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(hMenu);
	}
}
public CTF_SpawnFlag(Flag_Type) {
	if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_flag", false) ) {
			AcceptEntityInput(g_iFlags_Entity[Flag_Type], "KillHierarchy");
		}
	}
	if( g_iFlags_Base[Flag_Type] > 1 && IsValidEdict(g_iFlags_Base[Flag_Type]) && IsValidEntity(g_iFlags_Base[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Base[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_base", false) ) {
			AcceptEntityInput(g_iFlags_Base[Flag_Type], "Kill");
		}
	}
	
	g_iFlags_Base[Flag_Type] = 0;
	g_iFlags_Entity[Flag_Type] = 0;
	g_iFlags_Carrier[Flag_Type] = 0;
	
	new ent = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent) )
		return;
	new ent2 = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent2) )
		return;
	
	SetEntityModel(ent, "models/DeadlyDesire/ctf/flag.mdl");
	DispatchKeyValue(ent, "solid", "0");
	DispatchKeyValue(ent, "classname", "ctf_flag");
	//
	SetEntityModel(ent2, "models/DeadlyDesire/ctf/cap_point_base.mdl");
	DispatchKeyValue(ent2, "solid", "5");
	DispatchKeyValue(ent2, "classname", "ctf_base");
	
	if( Flag_Type == 0 ) {
		DispatchKeyValue(ent, "Skin", "0");
		DispatchKeyValue(ent2, "Skin", "1");
	}
	else if( Flag_Type == 1 ) {
		DispatchKeyValue(ent, "Skin", "1");
		DispatchKeyValue(ent2, "Skin", "2");
	}
	else {
		DispatchKeyValue(ent, "Skin", "2");
		DispatchKeyValue(ent2, "Skin", "0");
	}
	
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent2, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	DispatchSpawn(ent2);
	
	g_iFlags_Entity[Flag_Type] = ent;
	g_iFlags_Base[Flag_Type] = ent2;
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_trail_%i%i%i%i", ent, ent, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent, "targetname", ParentName);
	
	new trail = CreateEntityByName("env_spritetrail");
	DispatchKeyValue(trail, "lifetime", "5.0");
	DispatchKeyValue(trail, "endwidth", "0.1");
	DispatchKeyValue(trail, "startwidth", "5.0");
	DispatchKeyValue(trail, "spritename", "materials/sprites/laserbeam.vmt");
	DispatchKeyValue(trail, "renderamt", "255");
	if( Flag_Type == 1 ) {
		DispatchKeyValue(trail, "rendercolor", "0 0 250");
	}
	else if( Flag_Type == 0 ) {
		DispatchKeyValue(trail, "rendercolor", "250 0 0");
	}
	else {
		DispatchKeyValue(trail, "rendercolor", "10 10 10");
	}
	
	DispatchKeyValue(trail, "rendermode", "5");
	DispatchSpawn(trail);
	
	TeleportEntity(trail, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString(ParentName);
	AcceptEntityInput(trail, "SetParent");
	
}
public OnGameFrame() {
	for(new client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		
		
		new Float:vecOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
		
		for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
			
			if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
				new String:classname[128];
				GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
				if( StrEqual(classname, "ctf_flag", false) ) {
					new Float:vecFlag[3];
					GetEntPropVector(g_iFlags_Entity[Flag_Type], Prop_Send, "m_vecOrigin", vecFlag);
					
					
					new Float:dist = GetVectorDistance(vecOrigin, vecFlag, false);
					if( dist <= 25.0 ) {
						FlagGotTouch(client, g_iFlags_Entity[Flag_Type], Flag_Type);
					}
				}
			}
		}
	}
}
public FlagGotTouch(toucher, flag, Flag_Type) {	
	if( IsValidClient(g_iFlags_Carrier[Flag_Type]) )
		return;
	
	new team = GetClientTeam(toucher);
	if( team == CS_TEAM_T && Flag_Type == 0 ) {
		return;
	}
	if( team == CS_TEAM_CT && Flag_Type == 1 ) {
		return;
	}
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_%i%i%i%i", toucher, flag, Flag_Type, GetRandomInt(11111, 99999) );
	
	DispatchKeyValue(toucher, "targetname", ParentName);
	SetVariantString(ParentName);
	AcceptEntityInput(flag, "SetParent");
	
	SetVariantString("primary");
	AcceptEntityInput(flag, "SetParentAttachment");
	
	new Float:ang[3], Float:pos[3];
	ang[0] = -45.0;
	pos[0] += 10.0;
	pos[1] += 5.0;
	pos[2] -= 2.0;
	
	TeleportEntity(flag, pos, ang, NULL_VECTOR);
	
	g_iFlags_Carrier[Flag_Type] = toucher;
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		if( i == toucher ) {
			ClientCommand(i, "play \"DeadlyDesire/ctf/YouHaveTheFlag.mp3\"");
		}
		else {
			if( Flag_Type == 1 ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/BlueFlagTaken.mp3\"");
			}
			else if( Flag_Type == 0 ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/RedFlagTaken.mp3\"");
			}
		}
	}
}
stock GetClientAimLocation(client, Float:vecReturn[3]) {
	new Float:vecSrc[3], Float:vecAng[3];
	GetClientEyePosition(client, vecSrc);
	GetClientEyeAngles(client, vecAng);
	
	new Handle:trace = TR_TraceRayFilterEx(vecSrc, vecAng, MASK_SHOT, RayType_Infinite, FilterToOne, client);
	if( !TR_DidHit(trace) ) {
		return -1;
	}
	
	TR_GetEndPosition(vecReturn, trace);
	return 0;
}
public bool:FilterToOne(entity, mask, any:data) {
	return (data != entity);
}