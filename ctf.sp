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
new g_iFlags_Carrier[flag_max];
new g_iFlags_Physics[flag_max];

new Float:g_fCapMins[3] = { -80.0, -80.0, 0.0 };
new Float:g_fCapMaxs[3] = { 80.0, 80.0, 80.0 };

new g_iScore[2];

new g_iLastTeam[65];
new g_iRevieveTime[65];
new Float:g_fLastDrop[65];

// ------------------------------------------------------------------------------------------------------------------
// 		Forward: On...
//
public OnPluginStart() {
	RegAdminCmd("sm_ctf_mapconfig", Cmd_MapConfig, ADMFLAG_BAN, "Gestion de la config de la map pour un CTF");
	
	HookEvent("round_start", 	EventRoundStart, 	EventHookMode_Post);
	HookEvent("player_spawn", 	EventSpawn, 		EventHookMode_Post);
	HookEvent("player_death", 	EventDeath, 		EventHookMode_Pre);
	
	CreateTimer(1.0, HudDataTask, 0, TIMER_REPEAT);
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

	PrecacheModel("models/DeadlyDesire/ctf/flag.mdl", true);
	PrecacheModel("models/DeadlyDesire/ctf/cap_point_base.mdl", true);
	PrecacheModel("models/props/cs_assault/barrelwarning.mdl", true);
	
	ServerCommand("mp_ignore_round_win_conditions 1");
	BDD_LoadFlag();
	
}
public OnMapEnd() {
	CloseHandle(g_hBDD);
}
public OnGameFrame() {
	for(new client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		
		new Float:vecOrigin[3], Float:vecOrigin2[3];
		GetClientAbsOrigin(client, vecOrigin);
		GetClientEyePosition(client, vecOrigin2);
		
		for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
			
			if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
				new String:classname[128];
				GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
				if( StrEqual(classname, "ctf_flag", false) ) {
					new Float:vecFlag[3];
					GetEntPropVector(g_iFlags_Physics[Flag_Type], Prop_Send, "m_vecOrigin", vecFlag);
					
					
					new Float:dist = GetVectorDistance(vecOrigin, vecFlag, false);
					if( dist <= 32.0 ) {
						CTF_FlagTouched(client, g_iFlags_Entity[Flag_Type], Flag_Type);
					}
				}
				
				if( IsValidClient(g_iFlags_Carrier[Flag_Type]) && g_iFlags_Carrier[Flag_Type] == client ) {
					
					new Reverse_Flag_Type = 0;
					
					if( Flag_Type == 0 ) {
						Reverse_Flag_Type = 1;
					}
					
					new Float:vecMins[3], Float:vecMaxs[3];
					for(new i=0; i<=2; i++) {
						vecMins[i] = g_fCapMins[i] + g_vecFlags[Reverse_Flag_Type][i];
						vecMaxs[i] = g_fCapMaxs[i] + g_vecFlags[Reverse_Flag_Type][i];
						
					}
					
					if( PointInArea(vecOrigin, vecMins, vecMaxs) ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
					}
					else if( PointInArea(vecOrigin2, vecMins, vecMaxs) ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
					}
				}
			}
		}
	}
	
	CTF_FixAngles();
}
public CTF_FixAngle(ent) {
	new Float:fOrigin[3], Float:fAngle[3], Float:vecDest[3], Float:vecVelocity[3];

	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fOrigin);
	
	
	fAngle[0] = 90.0;
	fAngle[1] = 90.0;
	fAngle[2] = 0.0;
	
	vecVelocity[0] = 0.0;
	vecVelocity[1] = 0.0;
	vecVelocity[2] = -250.0;
	
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, fAngle, MASK_NPCWORLDSTATIC, RayType_Infinite, FilterToOne, ent);
	TR_GetEndPosition(vecDest, trace);
	CloseHandle(trace);
	
	GetEntPropVector(ent, Prop_Data, "m_angRotation", fAngle);
	fAngle[0] = 0.0;
	TeleportEntity(ent, NULL_VECTOR, fAngle, vecVelocity);
	
	if( GetVectorDistance(fOrigin, vecDest) <= 10.0 ) {
		AcceptEntityInput(ent, "DisableMotion");
	}
}
public CTF_FixAngles() {
		
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
			
			CTF_FixAngle(g_iFlags_Physics[Flag_Type]);
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
//		Task - Action Timer
//
public Action:HudDataTask(Handle:timer, any:zomg) {
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( !IsPlayerAlive(i) ) {
			new team = GetClientTeam(i);
			
			if( team == CS_TEAM_CT || team == CS_TEAM_T ) {
				g_iRevieveTime[i]--;
				if( g_iRevieveTime[i] <= 0 ) {
					CS_RespawnPlayer(i);
				}
			}
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
// 		Hooks - Event
//
public Action:EventRoundStart(Handle:Event, const String:Name[], bool:Broadcast) {
	
	CTF_SpawnFlag(flag_red);
	CTF_SpawnFlag(flag_blue);	
	
	return Plugin_Continue;
}
public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if( g_iLastTeam[client] != GetClientTeam(client) ) {
		if( GetClientTeam(client) == CS_TEAM_CT ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnBlue.mp3\"");
		}
		else if( GetClientTeam(client) == CS_TEAM_T ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnRed.mp3\"");
		}
	}
	
	g_iLastTeam[client] = GetClientTeam(client);
	return Plugin_Continue;
}
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	g_iRevieveTime[client] = (GetClientCount());
	CTF_DropFlag(client);
	
	return Plugin_Continue;
}

// ------------------------------------------------------------------------------------------------------------------
// 		DataBase - Load&Store
//
public BDD_LoadFlag() {
	new String:szCurrentMap[64], String:query[1024], Handle:hQuery;
	GetCurrentMap(szCurrentMap, 63);
	
	Format(query, sizeof(query), "SELECT `flag_red`, `flag_blue` FROM `ctf_map_config` WHERE `mapname`='%s' LIMIT 1;", szCurrentMap);
	if ((hQuery = SQL_Query(g_hBDD, query)) == INVALID_HANDLE) {
		Format(query, sizeof(query), "INSERT IGNORE INTO `ctf_map_config`( `mapname`, `flag_red`, `flag_blue`, `decals`) VALUES ('%s', '0.0:0.0:0.0', '0.0:0.0:0.0', '');", szCurrentMap);
		SQL_FastQuery(g_hBDD, query);
		return;
	}
	if (SQL_FetchRow(hQuery)) {
		new String:szFlag[128], String:szFlag2[3][32];
		SQL_FetchString(hQuery, 0, szFlag, sizeof(szFlag));
		ExplodeString(szFlag, ":", szFlag2, 3, 32);
		
		PrintToServer("%s", szFlag);
		for(new i=0; i<=2; i++) {
			g_vecFlags[0][i] = StringToFloat(szFlag2[i]);
		}
		SQL_FetchString(hQuery, 1, szFlag, sizeof(szFlag));
		ExplodeString(szFlag, ":", szFlag2, 3, 32);
		
		for(new i=0; i<=2; i++) {
			g_vecFlags[1][i] = StringToFloat(szFlag2[i]);
		}
	}
	else {
		Format(query, sizeof(query), "INSERT IGNORE INTO `ctf_map_config`( `mapname`, `flag_red`, `flag_blue`, `decals`) VALUES ('%s', '0.0:0.0:0.0', '0.0:0.0:0.0', '');", szCurrentMap);
		SQL_FastQuery(g_hBDD, query);
		return;
	}
}
public BDD_StoreFlag() {
	new String:szCurrentMap[64], String:query[1024];
	GetCurrentMap(szCurrentMap, 63);
	
	Format(query, sizeof(query), "UPDATE `ctf_map_config` SET `flag_red`='%f:%f:%f', `flag_blue`='%f:%f:%f' WHERE `mapname`='%s' LIMIT 1;", 
		g_vecFlags[0][0], g_vecFlags[0][1], g_vecFlags[0][2], 
		g_vecFlags[1][0], g_vecFlags[1][1], g_vecFlags[1][2], 
		szCurrentMap
	);
	SQL_FastQuery(g_hBDD, query);
}
// ------------------------------------------------------------------------------------------------------------------
// 		Commands
//
public Action:Cmd_MapConfig(client, args) {
	Menu_MapConfig(client);
	
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------------------------------------------
// 		Menu's
//
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
			BDD_StoreFlag();
		}
		else if( StrEqual( options, "spawn_blue", false) ) {
			GetClientAimLocation(client, g_vecFlags[flag_blue]);
			CTF_SpawnFlag(flag_blue);
			BDD_StoreFlag();
		}
		Menu_MapConfig(client);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(hMenu);
	}
}
// ------------------------------------------------------------------------------------------------------------------
// 		CTF GLOBAL FUNCTIONS
//
stock CTF_DropFlag(client) {
	new iFlagType = -1;
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		if( g_iFlags_Carrier[Flag_Type] == client ) {
			iFlagType = Flag_Type;
			g_iFlags_Carrier[Flag_Type] = 0;
			break;
		}
	}
	
	if( iFlagType == -1 )
		return;
	
	g_fLastDrop[client] = GetGameTime();
	
	new Float:vecFlag[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecFlag);
	
	vecFlag[2] += 10.0;
	
	TeleportEntity(g_iFlags_Physics[iFlagType], vecFlag, NULL_VECTOR, NULL_VECTOR);
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_drop_%i", GetRandomInt(11111, 99999) );
	DispatchKeyValue(g_iFlags_Physics[iFlagType], "targetname", ParentName);
	//
	SetVariantString(ParentName);
	AcceptEntityInput(g_iFlags_Entity[iFlagType], "SetParent");
	
	vecFlag[0] = 0.0;
	vecFlag[1] = 0.0;
	vecFlag[2] = 0.0;
	
	TeleportEntity(g_iFlags_Entity[iFlagType], vecFlag, vecFlag, NULL_VECTOR);
	AcceptEntityInput(g_iFlags_Physics[iFlagType], "EnableMotion");
}
public CTF_SpawnFlag(Flag_Type) {
	if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_flag", false) ) {
			AcceptEntityInput(g_iFlags_Entity[Flag_Type], "KillHierarchy");
		}
	}
	if( g_iFlags_Physics[Flag_Type] > 1 && IsValidEdict(g_iFlags_Physics[Flag_Type]) && IsValidEntity(g_iFlags_Physics[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_flag_physics", false) ) {
			AcceptEntityInput(g_iFlags_Entity[Flag_Type], "KillHierarchy");
		}
	}
	
	g_iFlags_Entity[Flag_Type] = 0;
	g_iFlags_Physics[Flag_Type] = 0;
	g_iFlags_Carrier[Flag_Type] = 0;
	
	new ent0 = CreateEntityByName("prop_physics");
	if( !IsValidEdict(ent0) )
		return;
	new ent1 = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent1) )
		return;
	new ent2 = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent2) )
		return;
	new ent3 = CreateEntityByName("light_dynamic");
	if( !IsValidEdict(ent3) )
		return;
	new ent4 = CreateEntityByName("env_spritetrail");
	if( !IsValidEdict(ent4) )
		return;
	
	SetEntityModel(ent0, "models/props/cs_assault/barrelwarning.mdl");
	DispatchKeyValue(ent0, "disableshadows", "1");
	DispatchKeyValue(ent0, "nodamageforces", "1");
	DispatchKeyValue(ent0, "spawnflags", "6");
	//
	SetEntityModel(ent1, "models/DeadlyDesire/ctf/flag.mdl");
	DispatchKeyValue(ent1, "solid", "0");
	DispatchKeyValue(ent1, "classname", "ctf_flag");
	//
	SetEntityModel(ent2, "models/DeadlyDesire/ctf/cap_point_base.mdl");
	DispatchKeyValue(ent2, "solid", "5");
	DispatchKeyValue(ent2, "classname", "ctf_base");
	//
	DispatchKeyValue(ent3, "brightness", "3");
	DispatchKeyValue(ent3, "distance", "128");
	//
	DispatchKeyValue(ent4, "lifetime", "3.0");
	DispatchKeyValue(ent4, "endwidth", "0.1");
	DispatchKeyValue(ent4, "startwidth", "5.0");
	DispatchKeyValue(ent4, "spritename", "materials/sprites/laserbeam.vmt");
	DispatchKeyValue(ent4, "renderamt", "255");
	DispatchKeyValue(ent4, "rendermode", "5");
	
	if( Flag_Type == 0 ) {
		DispatchKeyValue(ent1, "Skin", "0");
		DispatchKeyValue(ent2, "Skin", "1");
		DispatchKeyValue(ent3, "_light", "255 0 0");
		DispatchKeyValue(ent4, "rendercolor", "250 0 0");
	}
	else if( Flag_Type == 1 ) {
		DispatchKeyValue(ent1, "Skin", "1");
		DispatchKeyValue(ent2, "Skin", "2");
		DispatchKeyValue(ent3, "_light", "0 0 255");
		DispatchKeyValue(ent4, "rendercolor", "0 0 250");
	}
	else {
		DispatchKeyValue(ent1, "Skin", "2");
		DispatchKeyValue(ent2, "Skin", "0");
		DispatchKeyValue(ent4, "rendercolor", "10 10 10");
	}
	
	DispatchSpawn(ent0);
	DispatchSpawn(ent1);
	DispatchSpawn(ent2);
	DispatchSpawn(ent3);
	DispatchSpawn(ent4);
	
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent0, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent1, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent2, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent3, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent4, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	
	g_iFlags_Physics[Flag_Type] = ent0;
	g_iFlags_Entity[Flag_Type] = ent1;
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_physics_%i%i%i%i", ent0, ent1, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent0, "targetname", ParentName);
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent1, "SetParent");
	//
	//
	Format(ParentName, sizeof(ParentName), "ctf_parent_%i%i%i%i", ent0, ent1, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent1, "targetname", ParentName);	
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent3, "SetParent");
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent4, "SetParent");
	
	AcceptEntityInput(ent0, "DisableMotion");
	AcceptEntityInput(ent0, "DisablePuntSound");
	Colorize(ent0, 255, 255, 255, 0);
	
}
public CTF_Score(client, Flag_Type, Reverse_Flag_Type) {
	if( IsValidClient(g_iFlags_Carrier[Reverse_Flag_Type]) )
		return;
	
	g_iScore[Reverse_Flag_Type]++;
	
	CTF_SpawnFlag(Flag_Type);
	
	new String:szSound[128], String:szTeam[8];
	if( Reverse_Flag_Type == 0 ) {
		Format(szTeam, sizeof(szTeam), "Red");
	}
	else {
		Format(szTeam, sizeof(szTeam), "Blue");
	}
	
	Format(szSound, sizeof(szSound), "play \"DeadlyDesire/ctf/");
	
	PrintToChatAll("%N Capture le drapeau.", client);
	PrintToChatAll("*** Score: %i - %i", g_iScore[0], g_iScore[1]);
	
	// Si une équipe remporte la victoire:
	// --------------
	if( g_iScore[Flag_Type] == 0 && g_iScore[Reverse_Flag_Type] == 3 ) {
		for(new i=1; i<=GetMaxClients(); i++) {
			if( !IsValidClient(i) ) 
				continue;
			
			if( (GetClientTeam(i) == CS_TEAM_CT && g_iScore[0] == 3) || (GetClientTeam(i) == CS_TEAM_T && g_iScore[1] == 3) ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/HumiliatingDefeat.mp3\"");
			}
			else {
				ClientCommand(i, "play \"DeadlyDesire/ctf/FlawlessVictory.mp3\"");
			}
		}
		g_iScore[0] = 0;
		g_iScore[1] = 0;
		
		return;
	}
	if( g_iScore[Reverse_Flag_Type] == 3 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamWinsTheMatch.mp3\"", szSound, szTeam);
		for(new i=1; i<=GetMaxClients(); i++) {
			if( !IsValidClient(i) ) 
				continue;
			ClientCommand(i, szSound);
		}
		g_iScore[0] = 0;
		g_iScore[1] = 0;
		
		return;
	}
	//
	// --------------------
	if( g_iScore[Flag_Type] == 0 && g_iScore[Reverse_Flag_Type] == 2 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamIncreasesTheirLead.mp3\"", szSound, szTeam);
	}
	else if( g_iScore[Flag_Type] == 1 && g_iScore[Reverse_Flag_Type] == 2 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamTakesTheLead.mp3\"", szSound, szTeam);
	}
	else  {
		
		Format(szSound, sizeof(szSound), "%s%sTeamScores.mp3\"", szSound, szTeam);
	}
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		ClientCommand(i, szSound);
	}
}
public CTF_FlagTouched(toucher, flag, Flag_Type) {	
	if( IsValidClient(g_iFlags_Carrier[Flag_Type]) )
		return;
	
	new team = GetClientTeam(toucher);
	if( team == CS_TEAM_T && Flag_Type == 0 ) {
		return;
	}
	if( team == CS_TEAM_CT && Flag_Type == 1 ) {
		return;
	}
	
	if( (g_fLastDrop[toucher]+3.0) >= GetGameTime() ) {
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
// ------------------------------------------------------------------------------------------------------------------
// 		Stock
//
stock bool:PointInArea(Float:f_Points[3], Float:f_Mins[3], Float:f_Maxs[3]) {
	
	if(	f_Points[0] <= f_Maxs[0] && f_Points[1] <= f_Maxs[1] && f_Points[2] <= f_Maxs[2] &&
		f_Points[0] >= f_Mins[0] && f_Points[1] >= f_Mins[1] && f_Points[2] >= f_Mins[2] ) {
		return true;
	}
	
	return false;
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