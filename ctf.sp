#if defined _ctf_base_included
#endinput
#endif
#define _ctf_base_included

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <phun>
#include <smlib>

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

enum enum_class_type {
	class_none = 0,
	class_scout,
	class_sniper,
	class_soldier,
	class_demoman,
	class_medic,
	class_hwguy,
	class_pyro,
	class_spy,
	class_engineer,
	class_civilian,
	class_max
}

new Handle:g_hBDD = INVALID_HANDLE;
new String:g_szError[1024];

new Float:g_vecFlags[flag_max][3];
new g_iFlags_Entity[flag_max];
new g_iFlags_Base[flag_max];
new g_iFlags_Carrier[flag_max];
new g_iFlags_Physics[flag_max];

new g_iSecu_Status[flag_max];

new Float:g_fCapMins[3] = { -80.0, -80.0, 0.0 };
new Float:g_fCapMaxs[3] = { 80.0, 80.0, 80.0 };

new g_iScore[2];

new g_iLastTeam[65];
new g_iRevieveTime[65];
new Float:g_fLastDrop[65];

new enum_class_type:g_iPlayerClass[65];
new g_iPlayerArmor[65];
new Float:g_fUlti_Cooldown[65];

new bool:g_bIsCustomWeapon[2049];
new g_iCustomWeapon_Entity[65][2];
new g_iCustomWeapon_Entity2[65][3];
new Float:g_fCustomWeapon_NextShoot[65][3];
new g_iCustomWeapon_Ammo[65][2];

new g_iOffset_armor = -1;
new g_iOffset_WeaponParent = -1;

new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hPosition = INVALID_HANDLE;

new g_cPhysicBeam;
new g_cSmokeBeam;
new g_cExplode;

new Float:g_C4_fExplodeTime[2048];
new Float:g_C4_fNextBeep[2048];
new bool:g_C4_bIsActive[2048];

#define CUSTOM_WEAPON	"weapon_tmp"
#define ULTI_COOLDOWN	12.0
#define ULTI_DURATION	10.0

#define WALL_FACTOR		1.25
#define HEAL_DIST		300.0
#define FLAG_SPEED		5000.0

#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"

// ------------------------------------------------------------------------------------------------------------------
// 		Forward: On...
//
public OnPluginStart() {
	RegAdminCmd("sm_ctf_mapconfig", Cmd_MapConfig, ADMFLAG_BAN, "Gestion de la config de la map pour un CTF");
	RegConsoleCmd("drop",			Cmd_Drop);
	RegConsoleCmd("say",			Cmd_Say);
	RegConsoleCmd("ultimate",		Cmd_Ultimate);
	
	HookEvent("round_start", 	EventRoundStart, 	EventHookMode_Post);
	HookEvent("player_spawn", 	EventSpawn, 		EventHookMode_Post);
	HookEvent("player_death", 	EventDeath, 		EventHookMode_Pre);
	HookEvent("bullet_impact", 	EventBulletImpact);
	
	CreateTimer(1.0, HudDataTask, 0, TIMER_REPEAT);
	
	g_iOffset_armor 	= FindSendPropInfo("CCSPlayer", 		"m_ArmorValue");
	g_iOffset_WeaponParent 	= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	g_hConfig = LoadGameConfigFile("phun");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hConfig, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	g_hPosition = EndPrepSDKCall();
	
	
	AddNormalSoundHook(NormalSHook:sound_hook);
}

public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	
	if(StrEqual(sample,"weapons/flashbang/grenade_hit1.wav")) {
		
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == 0 ) {
			return Plugin_Stop;
		}
		
		volume = 0.5;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}  
public Action:SecuIsActivited(Handle:timer, any:zomg) {
	g_iSecu_Status[zomg] = 0;
}

public SheduleEntityInput( entity, Float:time, const String:input[]) {
	
	if( !IsValidEdict(entity) )
		return;
	if( !IsValidEntity(entity) )
		return;
	
	new Handle:dp;
	CreateDataTimer( time, ScheduleTargetInput_Task, dp); 
	WritePackCell(dp, entity);
	WritePackString(dp, input);
}
public ScheduleTargetInput( const String:targetname[], Float:time, const String:input[]) {
	for(new i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		new String:i_targetname[128];
		GetEntPropString(i, Prop_Data, "m_iName", i_targetname, sizeof(i_targetname));
		
		if( !StrEqual(targetname, i_targetname, false) )
			continue;
		
		new Handle:dp;
		CreateDataTimer( time, ScheduleTargetInput_Task, dp); 
		WritePackCell(dp, i);
		WritePackString(dp, input);
	}
}
public Action:ScheduleTargetInput_Task(Handle:timer, Handle:dp) {
	new entity, String:input[128];
	
	if( !IsValidEdict(entity) )
		return Plugin_Handled;
	if( !IsValidEntity(entity) )
		return Plugin_Handled;
	
	ResetPack(dp);
	
	entity = ReadPackCell(dp);
	ReadPackString(dp, input, 127);
	
	AcceptEntityInput(entity, input);
	
	return Plugin_Handled;
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
		
		new String:szHUD[128];
		Format(szHUD, sizeof(szHUD), "Scores:\n");
		
		if( g_iScore[flag_red] > g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_T ) ) {
			Format(szHUD, sizeof(szHUD), "%s Equipe Rouge: %i\n Equipe Bleue: %i", szHUD, g_iScore[flag_red], g_iScore[flag_blue]);
			
		}
		else if( g_iScore[flag_red] < g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_CT ) ) {
			Format(szHUD, sizeof(szHUD), "%s Equipe Bleue: %i\n Equipe Rouge: %i", szHUD, g_iScore[flag_blue], g_iScore[flag_red]);
		}
		
		new Handle:hBuffer = StartMessageOne("KeyHintText", i);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, szHUD);
		EndMessage();
		
		SetEntData(i, g_iOffset_armor, g_iPlayerArmor[i], 4, true);
	}
	
	CleanUp();
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
public Action:Cmd_Drop(client, args) {
	
	CTF_DropFlag(client, true);
	
	return Plugin_Handled;
}
public Action:Cmd_Say(client, args) {
	
	if( !IsValidClient(client) ) {
		return Plugin_Handled;
	}
	
	new String:szSayText[192];
	new String:szSayTrig[15];
	
	GetCmdArgString(szSayText, sizeof(szSayText));
	StripQuotes(szSayText);
	
	BreakString(szSayText, szSayTrig, sizeof(szSayTrig));
	
	if(	strcmp(szSayTrig, "!class", false) == 0		|| strcmp(szSayTrig, "/class", false) == 0	||
	strcmp(szSayTrig, "!classe", false) == 0	|| strcmp(szSayTrig, "/classe", false) == 0	||
	strcmp(szSayTrig, "!classes", false) == 0	|| strcmp(szSayTrig, "/classes", false) == 0	
	) {
		
		g_iPlayerClass[client] = class_none;
		CTF_NONE_init(client);
		return Plugin_Handled;
	}
	if(	strcmp(szSayTrig, "!ultimate", false) == 0		|| strcmp(szSayTrig, "/ultimate", false) == 0
	) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action:Cmd_Ultimate(client, args) {
	CTF_Ultimate(client);
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
public CleanUp() {  
	new String:name[64];
	for (new i=GetMaxClients();i<=GetMaxEntities();i++) {
		if ( IsValidEdict(i) && IsValidEntity(i) ) {
			GetEdictClassname(i, name, sizeof(name));
			if ( ( StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1 ) && GetEntDataEnt2(i, g_iOffset_WeaponParent) == -1 ) {
				RemoveEdict(i);
			}
		}
	}
}
stock Float:degrees_to_radians(Float:degreesGiven) {
	return degreesGiven*(3.141592653589793/180.0);
}
