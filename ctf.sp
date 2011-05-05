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
//#include <tentdev>

public Plugin:myinfo = {
	name = "CTF",
	author = "KoSSoLaX`",
	description = "Capture The Flag System",
	version = "1.0",
	url = "http://www.ts-x.eu/"
}

// ------------------------------
// Enum
//
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
enum enum_grenade_type {
	grenade_none,
	grenade_caltrop,
	grenade_concussion,
	grenade_frag,
	grenade_nail,
	grenade_mirv,
	grenade_mirvlet,
	grenade_napalm,
	grenade_gas,
	grenade_emp,
	
	grenade_max
}
// ------------------------------
// FLAGS
//
new g_iFlags_Entity[flag_max];
new g_iFlags_Carrier[flag_max];
new Float:g_vecFlags[flag_max][3];
new Float:g_fFlags_Respawn[flag_max];
// ------------------------------
// SECU
//
new Float:g_vecSecu[flag_max][3];
new g_iSecu_Status[flag_max];
new bool:g_bSecurity = false;
// ------------------------------
// SCORES
//
new g_iScore[2];
// ------------------------------
// PLAYER
//
new g_iLastTeam[65];
new g_iRevieveTime[65];
new g_iPlayerArmor[65];
new enum_class_type:g_iPlayerClass[65];
new Float:g_fLastDrop[65];
new Float:g_fUlti_Cooldown[65];
// ------------------------------
// Grenade
//
new g_iPlayerGrenadeAmount[65][2];
new Float:g_flPrimedTime[2048];
new enum_grenade_type:g_iGrenadeType[2048];
new Float:g_flNailData[2048][2];
new Float:g_flGasLastDamage[65];


// ------------------------------
// CUSTOM WEAPON
//
new g_iCustomWeapon_Entity[65][2];
new g_iCustomWeapon_Entity2[65][3];
new g_iCustomWeapon_Ammo[65][2];
new bool:g_bIsCustomWeapon[2049];
new Float:g_fCustomWeapon_NextShoot[65][3];
// ------------------------------
// OFFSET
//
new g_iOffset_armor = -1;
new g_iOffset_WeaponParent = -1;
new g_iOffset_money = -1;
// ------------------------------
// SDK-CALL HANDLE
//
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hPosition = INVALID_HANDLE;
// ------------------------------
// PRECACHE
//
new g_cPhysicBeam;
new g_cShockWave;
new g_cShockWave2;
new g_cSmokeBeam;
new g_cExplode;
new g_cScorch;
// ------------------------------
// Class: Artificier
//
new Float:g_C4_fExplodeTime[2048];
new Float:g_C4_fNextBeep[2048];
new bool:g_C4_bIsActive[2048];
// ------------------------------
// Class: Medic
//
new g_iContaminated[65];
new Float:g_fContaminate[65];
#define HEAL_DIST		300.0
// ------------------------------
// Class: Pyroman
//
new g_iBurning[65];
new Float:g_fBurning[65];
// ------------------------------
// Class: Espion
//
new Float:g_fDelay[65][2];
new Float:g_fRestoreSpeed[65][2];
// ------------------------------
// Class: Ingenieur
//
new g_iSentry[65];
new Float:g_flSentryHealth[2048];
new Float:g_flSentryThink[2048];
new Float:g_flMetal[65];

// ------------------------------
// CTF-CONFIG
//
#define FLAG_SPEED		500.0
// ------------------------------
// ULTIMATE-CONFIG
//
#define ULTI_COOLDOWN	12.0
#define ULTI_DURATION	10.0


// ------------------------------
// DO NOT EDIT BELLOW!
//
#define WALL_FACTOR		1.25
#define CUSTOM_WEAPON	"weapon_tmp"
#define PI				3.141592653589793

#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"
#include "ctf.inc.sentry.sp"
#include "ctf.inc.grenades.sp"

// ------------------------------------------------------------------------------------------------------------------
// 		Forward: On...
//
public OnPluginStart() {
	RegConsoleCmd("drop",			Cmd_Drop);
	RegConsoleCmd("say",			Cmd_Say);
	RegConsoleCmd("ultimate",		Cmd_Ultimate);
	
	RegConsoleCmd("+gren1",			Cmd_PlusGren1);
	RegConsoleCmd("+gren2",			Cmd_PlusGren2);
	RegConsoleCmd("-gren1",			Cmd_MoinsGren);
	RegConsoleCmd("-gren2",			Cmd_MoinsGren);
	
	HookEvent("round_start", 	EventRoundStart, 	EventHookMode_Post);
	HookEvent("player_spawn", 	EventSpawn, 		EventHookMode_Post);
	HookEvent("player_death", 	EventDeath, 		EventHookMode_Pre);
	HookEvent("bullet_impact", 	EventBulletImpact);
	
	CreateTimer(1.0, HudDataTask, 0, TIMER_REPEAT);
	
	g_iOffset_armor 		= FindSendPropInfo("CCSPlayer", 		"m_ArmorValue");
	g_iOffset_WeaponParent 	= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_iOffset_money 		= FindSendPropOffs("CCSPlayer", 		"m_iAccount");
	
	g_hConfig = LoadGameConfigFile("phun");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hConfig, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	g_hPosition = EndPrepSDKCall();
	
	
	AddNormalSoundHook(NormalSHook:sound_hook);
}
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	
	if(StrEqual(sample,"weapons/flashbang/grenade_hit1.wav")) {
		
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == 0 )
			return Plugin_Stop;
		
		new String:classname[64];
		GetEdictClassname(entity, classname, 63);
		
		if( StrEqual(classname, "ctf_flag") )
			return Plugin_Stop;
		
		volume = 0.5;
		
		Format(sample, sizeof(sample), "grenades/bounce.wav");
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
				if( g_iRevieveTime[i] <= 0 && g_iPlayerClass[i] != class_none ) {
					CS_RespawnPlayer(i);
				}
			}
		}
		
		new String:szHUD[128];
		Format(szHUD, sizeof(szHUD), "Scores:\n");
		
		if( g_iScore[flag_red] > g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_T ) ) {
			Format(szHUD, sizeof(szHUD), "%s Equipe Rouge: %i\n Equipe Bleue: %i\n\n", szHUD, g_iScore[flag_red], g_iScore[flag_blue]);
			
		}
		else if( g_iScore[flag_red] < g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_CT ) ) {
			Format(szHUD, sizeof(szHUD), "%s Equipe Bleue: %i\n Equipe Rouge: %i\n\n", szHUD, g_iScore[flag_blue], g_iScore[flag_red]);
		}
		else {
			Format(szHUD, sizeof(szHUD), "%s Equipe Rouge: %i\n Equipe Bleue: %i\n\n", szHUD, g_iScore[flag_red], g_iScore[flag_blue]);
		}
		
		
		SetEntData(i, g_iOffset_armor, g_iPlayerArmor[i], 4, true);
		
		new String:money_nade[12];
		Format(money_nade, sizeof(money_nade), "%i%i", g_iPlayerGrenadeAmount[i][0], g_iPlayerGrenadeAmount[i][1]);
		
		if( g_iPlayerClass[i] == class_engineer ) {
			Format(money_nade, sizeof(money_nade), "%i%s", RoundFloat(g_flMetal[i]), money_nade);
			
			g_flMetal[i] += GetRandomFloat(1.0, 2.0);
			if( g_flMetal[i] > 200.0 ) {
				g_flMetal[i] = 200.0;
			}
			Format(szHUD, sizeof(szHUD), "%s\nMetal: %i", szHUD, RoundFloat(g_flMetal[i]));
			
			if( IsValidSentry(g_iSentry[i]) && g_flSentryHealth[ g_iSentry[i] ] > 0.0 ) {
				Format(szHUD, sizeof(szHUD), "%s - Tourelle: %.1f HP", szHUD, g_flSentryHealth[ g_iSentry[i] ] );
			}
			else {
				Format(szHUD, sizeof(szHUD), "%s - Tourelle: H/S", szHUD);
			}
		}
		
		Format(szHUD, sizeof(szHUD), "%s\nGrenade: %i - %i", szHUD, g_iPlayerGrenadeAmount[i][0], g_iPlayerGrenadeAmount[i][1]);
		
		new Handle:hBuffer = StartMessageOne("KeyHintText", i);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, szHUD);
		EndMessage();
		
		SetEntData(i, g_iOffset_money, StringToInt(money_nade), 4, true);
		
	}
	
	CleanUp();
}

// ------------------------------------------------------------------------------------------------------------------
// 		DataBase - Load&Store
//
public CTF_LoadFlag() {
	
	g_bSecurity = false;
	for(new i=1; i<GetMaxEntities(); i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		new String:classname[64], String:targetname[64];
		GetEdictClassname(i, classname, 63);
		
		if( StrEqual(classname, "info_target") ) {
			
			
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if( StrEqual(targetname, "ctf_flag_red") ) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", g_vecFlags[flag_red]);
				PrintToServer("[CTF] Flag Red Position Set.");
			}
			if( StrEqual(targetname, "ctf_flag_blue") ) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", g_vecFlags[flag_blue]);
				PrintToServer("[CTF] Flag Blue Position Set.");
			}
			
			if( StrEqual(targetname, "ctf_security_red_button") ) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", g_vecSecu[flag_red]);
				PrintToServer("[CTF] Security Red Position Set.");
				g_bSecurity = true;
			}
			if( StrEqual(targetname, "ctf_security_blue_button") ) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", g_vecSecu[flag_blue]);
				PrintToServer("[CTF] Security Blue Position Set.");
				g_bSecurity = true;
			}
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
// 		Commands
//
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
	return degreesGiven*(PI/180.0);
}
