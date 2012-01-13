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

#include "ctf.sp"
#include "ctf.inc.const.sp"
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
	
	RegConsoleCmd("ctf_backpack_add",		CmdBackPack_add);
	RegConsoleCmd("ctf_backpack_delete",	CmdBackPack_remove);
	RegConsoleCmd("ctf_backpack_reload",	CmdBackPack_reload);
	RegConsoleCmd("ctf_backpack_id", 		CmdBackPack_id);
	
	g_hClassRestriction[1] 	= CreateConVar("ctf_cr_scout",		"-1", "Class restriction: scout");
	g_hClassRestriction[2]	= CreateConVar("ctf_cr_sniper",		"2", "Class restriction: sniper");
	g_hClassRestriction[3]	= CreateConVar("ctf_cr_soldier",	"-1", "Class restriction: soldier");
	g_hClassRestriction[4]	= CreateConVar("ctf_cr_demoman",	"2", "Class restriction: demoman");
	g_hClassRestriction[5]	= CreateConVar("ctf_cr_medic",		"-1", "Class restriction: medic");
	g_hClassRestriction[6]	= CreateConVar("ctf_cr_hwguy",		"2", "Class restriction: hwguy");
	g_hClassRestriction[7]	= CreateConVar("ctf_cr_pyro",		"1", "Class restriction: pyro");
	g_hClassRestriction[8]	= CreateConVar("ctf_cr_spy",		"2", "Class restriction: spy");
	g_hClassRestriction[9]	= CreateConVar("ctf_cr_engineer",	"1", "Class restriction: engineer");
	
	g_hFriendlyFire = FindConVar("mp_friendlyfire");
	
	HookEvent("round_start", 	EventRoundStart, 	EventHookMode_Post);
	HookEvent("player_spawn", 	EventSpawn, 		EventHookMode_Post);
	HookEvent("player_death", 	EventDeath, 		EventHookMode_Pre);
	HookEvent("bullet_impact", 	EventBulletImpact);
	HookEvent("player_team", 	EventPlayerTeam,	EventHookMode_Pre);
	
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
	
	CreateTimer(1.0, CTF_DUMP_CHECK, _, TIMER_REPEAT);
}
public Action:CTF_DUMP_CHECK(Handle:timer, any:zomg) {
	new amount = 0;
	for(new i=GetMaxClients(); i<2049; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		amount++;
	}
	
	if( amount > 1500 ) {
		CTF_DUMP();
		PrintToServer("[CTF] Le plugin a crashe, merci de prevenir KoSSoLaX` avec l'heure du crash.");
		LogToGame("[CTF] Le plugin a crashe, merci de prevenir KoSSoLaX` avec l'heure du crash.");
		ServerCommand("sm plugins unload ctf");
	}
}
public CTF_DUMP() {
	for(new i=GetMaxClients(); i<2049; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		new String:classname[128];
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrContains(classname, "prop_", false) == 0 )
			continue;
		
		Format(classname, sizeof(classname), "[DUMP] %i:%s", i, classname);
		LogToFile("ctf_fail.log", classname);
	}
}
public Action:OnGetGameDescription(String:gameDesc[64]) {
	Format(gameDesc, sizeof(gameDesc), "CSS-CTF");
	return Plugin_Changed;
}
public CTF_Reset_Player(i) {
	g_iLastTeam[i] = 0;
	g_iRevieveTime[i] = 0;
	g_iPlayerArmor[i] = 0;
	g_iPlayerClass[i] = class_none;
	g_fLastDrop[i] = 0.0;
	g_fUlti_Cooldown[i] = 0.0;
	g_flPlayerSpeed[i] = 0.0;
	
	g_iPlayerGrenadeAmount[i][0] = 0;
	g_iPlayerGrenadeAmount[i][1] = 0;
	
	g_flGasLastDamage[i] = 0.0;
	
	g_iCustomWeapon_Entity[i][0] = 0;
	g_iCustomWeapon_Entity[i][1] = 0;
	
	g_iCustomWeapon_Entity2[i][0] = 0;
	g_iCustomWeapon_Entity2[i][1] = 0;
	g_iCustomWeapon_Entity2[i][2] = 0;
	g_iCustomWeapon_Ammo[i][0] = 0;
	g_iCustomWeapon_Ammo[i][1] = 0;
	
	g_fCustomWeapon_NextShoot[i][0] = 0.0;
	g_fCustomWeapon_NextShoot[i][1] = 0.0;
	g_fCustomWeapon_NextShoot[i][2] = 0.0;
	
	g_iContaminated[i] = 0;
	g_fContaminate[i] = 0.0;
	
	g_iBurning[i] = 0;
	g_fBurning[i] = 0.0;
	
	g_fDelay[i][0] = 0.0;
	g_fDelay[i][1] = 0.0;
	g_fRestoreSpeed[i][0] = 0.0;
	g_fRestoreSpeed[i][1] = 0.0;
	
	g_flCrazyTime[i] = 0.0;
	
	g_iBuild[i][build_sentry] = 0;
	g_iBuild[i][build_teleporter_in] = 0;
	g_iBuild[i][build_teleporter_out] = 0;
	
	g_flMetal[i] = 0.0;
}
public CTF_Reset_Global() {
	
	for(new i=0; i<2048; i++) {
		
		g_flBagPack_Last[i] = 0.0;
		
		g_flPrimedTime[i] = 0.0;
		g_iGrenadeType[i] = grenade_none;
		g_flNailData[i][0] = 0.0;
		g_flNailData[i][1] = 0.0;
		
		g_flCustomWeapon_Entity3[i] = 0.0;
		g_bIsCustomWeapon[i] = false;
		
		
		g_C4_fExplodeTime[i] = 0.0;
		g_C4_fNextBeep[i] = 0.0;
		g_C4_bIsActive[i] = false;
		
		g_flBuildHealth[i][build_sentry] = 0.0;
		g_flBuildHealth[i][build_teleporter_in] = 0.0;
		g_flBuildHealth[i][build_teleporter_out] = 0.0;
		
		g_flBuildThink[i][build_sentry] = 0.0;
		g_flBuildThink[i][build_teleporter_in] = 0.0;
		g_flBuildThink[i][build_teleporter_out] = 0.0;
		
		g_flBuildThink2[i][build_sentry] = 0.0;
		g_flBuildThink2[i][build_teleporter_in] = 0.0;
		g_flBuildThink2[i][build_teleporter_out] = 0.0;
		
		g_flSentryAngles[i][0] = 0.0;
		g_flSentryAngles[i][1] = 0.0;
		
		g_iSentryAngles[i][0] = 0;
		g_iSentryAngles[i][1] = 0;
		
		g_iSentryTarget[i] = 0;
		g_iSentryLevel[i] = 0;
		
		g_flLastTouch[i] = 0.0;
		g_vecLastTouch[i][0] = 0.0;
		g_vecLastTouch[i][1] = 0.0;
		g_vecLastTouch[i][2] = 0.0;
	}
	
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		
		g_iFlags_Entity[Flag_Type] = 0;
		g_iFlags_Carrier[Flag_Type] = 0;
		g_fFlags_Respawn[Flag_Type] = 0.0;
		
		g_iSecu_Status[Flag_Type] = 0;
		g_bSecurity = false;
	}
	g_iScore[0] = 0;
	g_iScore[1] = 0;
	
	for(new i=0; i<65; i++) {
		
		CTF_Reset_Player(i);		
	}
}
public Action:CmdBackPack_add(client, args) {
	
	new String:mapname[64], Float:vecOrigin[3], Float:vecAngles[3];
	GetCurrentMap(mapname, sizeof(mapname));
	
	GetClientAbsOrigin(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	vecAngles[1] *= 0.1;
	vecAngles[1] = float(RoundFloat(vecAngles[1]));
	vecAngles[1] *= 10.0;
	
	Format(g_szQuery, sizeof(g_szQuery), "INSERT INTO `ctf_bagpack` VALUES ('', '%s', '%i', '1', '%i', '%i', '%i', '%i');", 
	mapname, GetClientTeam(client), RoundFloat(vecOrigin[0]), RoundFloat(vecOrigin[1]), RoundFloat(vecOrigin[2]), RoundFloat(vecAngles[1]));
	
	SQL_LockDatabase(g_hBDD);
	SQL_FastQuery(g_hBDD, g_szQuery);
	SQL_UnlockDatabase(g_hBDD);
	
	CTF_LoadFlag();
	CTF_SpawnBackPack();
	
	return Plugin_Handled;
}
public Action:CmdBackPack_remove(client, args) {
	
	new ent = GetClientAimTarget(client, false);
	
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
	
	new id = -1;
	
	for(new i=0; i<MAX_BAGPACK; i++) {
		if( g_BagPack_Data[i][bagpack_ent] == ent ) {
			id = g_BagPack_Data[i][bagpack_id];
			break;
		}
	}
	if( id >= 0 ) {
		
		Format(g_szQuery, sizeof(g_szQuery), "DELETE FROM `ctf_bagpack` WHERE `id`='%i' LIMIT 1;", id);
		SQL_FastQuery(g_hBDD, g_szQuery);
		AcceptEntityInput(ent, "Kill");
	}
	
	return Plugin_Handled;
}
public Action:CmdBackPack_reload(client, args) {
	
	CTF_LoadFlag();
	CTF_SpawnBackPack();
	return Plugin_Handled;
}
public Action:CmdBackPack_id(client, args) {
	
	new ent = GetClientAimTarget(client, false);
	
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
	
	new id = -1;
	
	for(new i=0; i<MAX_BAGPACK; i++) {
		if( g_BagPack_Data[i][bagpack_ent] == ent ) {
			id = g_BagPack_Data[i][bagpack_id];
			break;
		}
	}
	if( id >= 0 ) {
		
		PrintToChat(client, "id:%i", id);
	}
	
	return Plugin_Handled;
}
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	
	if(StrEqual(sample,"weapons/flashbang/grenade_hit1.wav")) {
		
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == 0 )
			return Plugin_Stop;
		
		new String:classname[64];
		GetEdictClassname(entity, classname, 63);
		
		if( StrEqual(classname, "ctf_flag") )
			return Plugin_Stop;
		
		if( StrContains(classname, "ctf_flame") == 0 )
			return Plugin_Stop;
		
		volume = 0.5;
		
		Format(sample, sizeof(sample), "grenades/bounce.wav");
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}  
public Action:SecuIsActivited(Handle:timer, any:zomg) {
	g_iSecu_Status[zomg] = 0;
	
	if( zomg == _:flag_blue ) {
		PrintToChatAll("[CTF] La securite blue a ete activee!");
	}
	else {
		PrintToChatAll("[CTF] La securite rouge a ete activee!");
	}
}

public SheduleEntityInput( entity, Float:time, const String:input[]) {
	
	if( !IsValidEdict(entity) )
		return;
	if( !IsValidEntity(entity) )
		return;
	
	new Handle:dp;
	CreateDataTimer( time, ScheduleTargetInput_Task, dp); 
	WritePackCell(dp, EntIndexToEntRef(entity));
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
		WritePackCell(dp, EntIndexToEntRef(i));
		WritePackString(dp, input);
	}
}
public Action:ScheduleTargetInput_Task(Handle:timer, Handle:dp) {
	new entity, String:input[128];
	
	ResetPack(dp);
	
	entity = EntRefToEntIndex(ReadPackCell(dp));
	ReadPackString(dp, input, 127);
	
	if( entity == INVALID_ENT_REFERENCE ) 
		return Plugin_Handled;
	if( entity <= 0 )
		return Plugin_Handled;
	if( !IsValidEdict(entity) )
		return Plugin_Handled;
	if( !IsValidEntity(entity) )
		return Plugin_Handled;
	
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
				
				if( g_iRevieveTime[i] > 1 ) {
					PrintHintText(i, "Vous allez revivre dans: %i secondes...", g_iRevieveTime[i]);
				}
				else {
					PrintHintText(i, "Vous allez revivre dans: 1 seconde...");
				}
				StopSound(i, SNDCHAN_STATIC, "UI/hint.wav");
				
				if( g_iRevieveTime[i] <= 0 && g_iPlayerClass[i] != class_none ) {
					CS_RespawnPlayer(i);
				}
				
				if( g_iPlayerClass[i] == class_none ) {
					CTF_NONE_init(i);
					
					PrintHintText(i, "Veuillez selectionner une classe...");
					StopSound(i, SNDCHAN_STATIC, "UI/hint.wav");
				}
			}
		}
		
		new String:g_szClass[10][32] = { "Aucune -", "Eclaireur -", "Sniper -", "Soldat -", "Artificier -", "Infirmier -", "Mitrailleur -", "Pyroman -", "Espion -", "Technicien -" };
		CS_SetClientClanTag(i, g_szClass[g_iPlayerClass[i]]);
		
		CTF_TP_Links(i);
		
		new String:szHUD[256];
		Format(szHUD, sizeof(szHUD), "Scores:\n");
		
		if( g_iScore[flag_red] > g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_T ) ) {
			Format(szHUD, sizeof(szHUD), "%s - Equipe Rouge: %i\n - Equipe Bleue: %i\n\n", szHUD, g_iScore[flag_red], g_iScore[flag_blue]);
		}
		else if( g_iScore[flag_red] < g_iScore[flag_blue] || (g_iScore[flag_red] == g_iScore[flag_blue] && GetClientTeam(i) == CS_TEAM_CT ) ) {
			Format(szHUD, sizeof(szHUD), "%s - Equipe Bleue: %i\n - Equipe Rouge: %i\n\n", szHUD, g_iScore[flag_blue], g_iScore[flag_red]);
		}
		else {
			Format(szHUD, sizeof(szHUD), "%s - Equipe Rouge: %i\n - Equipe Bleue: %i\n\n", szHUD, g_iScore[flag_red], g_iScore[flag_blue]);
		}
		
		if( g_bSecurity ) {
			
			Format(szHUD, sizeof(szHUD), "%s Securite:", szHUD);
			
			if( GetClientTeam(i) == CS_TEAM_CT ) {
				
				if( g_iSecu_Status[flag_blue] )
					Format(szHUD, sizeof(szHUD), "%s\n - Bleue: Desactivee", szHUD);
				else
					Format(szHUD, sizeof(szHUD), "%s\n - Bleue: Activee", szHUD);
				
				if( g_iSecu_Status[flag_red] )
					Format(szHUD, sizeof(szHUD), "%s\n - Rouge: Desactivee", szHUD);
				else
					Format(szHUD, sizeof(szHUD), "%s\n - Rouge: Activee", szHUD);
				
			}
			else {
				
				if( g_iSecu_Status[flag_red] )
					Format(szHUD, sizeof(szHUD), "%s\n - Rouge: Desactivee", szHUD);
				else
					Format(szHUD, sizeof(szHUD), "%s\n - Rouge: Activee", szHUD);
				
				if( g_iSecu_Status[flag_blue] )
					Format(szHUD, sizeof(szHUD), "%s\n - Bleue: Desactivee", szHUD);
				else
					Format(szHUD, sizeof(szHUD), "%s\n - Bleue: Activee", szHUD);
					
			}
			
			Format(szHUD, sizeof(szHUD), "%s\n\n", szHUD);
			
		}
		SetEntData(i, g_iOffset_armor, g_iPlayerArmor[i], 4, true);
		
		new String:money_nade[12];
		Format(money_nade, sizeof(money_nade), "%i%i", g_iPlayerGrenadeAmount[i][0], g_iPlayerGrenadeAmount[i][1]);
		
		Format(szHUD, sizeof(szHUD), "%sGrenade: %i - %i", szHUD, g_iPlayerGrenadeAmount[i][0], g_iPlayerGrenadeAmount[i][1]);
		
		if( g_iPlayerClass[i] == class_engineer ) {
			Format(money_nade, sizeof(money_nade), "%i%s", RoundFloat(g_flMetal[i]), money_nade);
			
			g_flMetal[i] += GetRandomFloat(1.0, 2.0);
			if( g_flMetal[i] > 200.0 ) {
				g_flMetal[i] = 200.0;
			}
			Format(szHUD, sizeof(szHUD), "%s\nMetal: %i \n\nConstruction:", szHUD, RoundFloat(g_flMetal[i]));
			
			if( IsValidSentry( g_iBuild[i][build_sentry]) && g_flBuildHealth[ g_iBuild[i][build_sentry] ][build_sentry] > 0.0 ) {
				Format(szHUD, sizeof(szHUD), "%s\n  - Tourelle: %.1f HP", szHUD, g_flBuildHealth[ g_iBuild[i][build_sentry] ][build_sentry] );
			}
			else {
				Format(szHUD, sizeof(szHUD), "%s\n  - Tourelle: H/S", szHUD);
			}
			
			if( IsValidTeleporter( g_iBuild[i][build_teleporter_in]) && g_flBuildHealth[ g_iBuild[i][build_teleporter_in] ][build_teleporter_in] > 0.0 ) {
				Format(szHUD, sizeof(szHUD), "%s\n  - Teleporteur E.: %.1f HP", szHUD, g_flBuildHealth[ g_iBuild[i][build_teleporter_in] ][build_teleporter_in] );
			}
			else {
				Format(szHUD, sizeof(szHUD), "%s\n  - Teleporteur E.: H/S", szHUD);
			}
			if( IsValidTeleporter( g_iBuild[i][build_teleporter_out]) && g_flBuildHealth[ g_iBuild[i][build_teleporter_out] ][build_teleporter_out] > 0.0 ) {
				Format(szHUD, sizeof(szHUD), "%s\n  - Teleporteur S.: %.1f HP", szHUD, g_flBuildHealth[ g_iBuild[i][build_teleporter_out] ][build_teleporter_out] );
			}
			else {
				Format(szHUD, sizeof(szHUD), "%s\n  - Teleporteur S.: H/S", szHUD);
			}
		}
		
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
	
	new String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	
	Format(g_szQuery, sizeof(g_szQuery), "SELECT `id`, `team`, `type`, `origin_x`, `origin_y`, `origin_z`, `angle_y` FROM `ctf_bagpack` WHERE `map`='%s';", mapname);
	
	SQL_LockDatabase(g_hBDD);
	new Handle:req = SQL_Query(g_hBDD, g_szQuery);
	
	if( req != INVALID_HANDLE ) {
		
		for(new i=0; i<MAX_BAGPACK; i++) {
			
			g_BagPack_Data[i][bagpack_data] = 0;
			if( g_BagPack_Data[i][bagpack_ent] >= 1 && IsValidEdict(g_BagPack_Data[i][bagpack_ent]) && IsValidEntity(g_BagPack_Data[i][bagpack_ent]) ) {
				new String:classname[64];
				GetEdictClassname(g_BagPack_Data[i][bagpack_ent], classname, 63);
				
				if( StrContains(classname, "ctf_backpack_") == 0 ) {
					AcceptEntityInput(g_BagPack_Data[i][bagpack_ent], "Kill");
				}
			}
		}
		
		new i = 0;
		while( SQL_FetchRow(req) ) {
			
			g_BagPack_Data[i][bagpack_id] = SQL_FetchInt(req, 0);
			g_BagPack_Data[i][bagpack_data] = 1;
			g_BagPack_Data[i][bagpack_team] = SQL_FetchInt(req, 1);
			g_BagPack_Data[i][bagpack_type] = SQL_FetchInt(req, 2);
			
			g_BagPack_Data[i][bagpack_origin_x] = SQL_FetchInt(req, 3);
			g_BagPack_Data[i][bagpack_origin_y] = SQL_FetchInt(req, 4);
			g_BagPack_Data[i][bagpack_origin_z] = SQL_FetchInt(req, 5);
			
			g_BagPack_Data[i][bagpack_angle] = SQL_FetchInt(req, 6);
			
			i++;
		}
	}
	
	SQL_UnlockDatabase(g_hBDD);
}
public CTF_SpawnBackPack() {
	
	for(new i=0; i<MAX_BAGPACK; i++) {
		
		if( g_BagPack_Data[i][bagpack_data] == 0 )
			continue;
		
		
		
		new ent = CreateEntityByName("prop_dynamic");
		new String:classname[64];
		Format(classname, 63, "ctf_backpack_%i", g_BagPack_Data[i][bagpack_team]);
		
		DispatchKeyValue(ent, "classname", classname);
		
		if( g_BagPack_Data[i][bagpack_type] == 1 ) {
			PrecacheModel("models/items/ammocrate_smg1.mdl");
			DispatchKeyValue(ent, "model", "models/items/ammocrate_smg1.mdl");
		}
		else if( g_BagPack_Data[i][bagpack_type] == 2 ) {
			PrecacheModel("models/items/ammocrate_grenade.mdl");
			DispatchKeyValue(ent, "model", "models/items/ammocrate_grenade.mdl");
		}
		
		SetEntProp(ent, Prop_Data, "m_nSolidType", 6 );
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6 );
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 5);
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
		
		DispatchSpawn(ent);
		ActivateEntity(ent);
		
		g_BagPack_Data[i][bagpack_ent] = ent;
		
		new Float:vecOrigin[3], Float:vecAngles[3];
		vecOrigin[0] = float(g_BagPack_Data[i][bagpack_origin_x]);
		vecOrigin[1] = float(g_BagPack_Data[i][bagpack_origin_y]);
		vecOrigin[2] = float(g_BagPack_Data[i][bagpack_origin_z]);
		vecAngles[1] = float(g_BagPack_Data[i][bagpack_angle]);
		
		vecOrigin[2] += 16.0;
		
		TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
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
		
		//g_iPlayerClass[client] = class_none;
		CTF_NONE_init(client);
		return Plugin_Handled;
	}
	if(	strcmp(szSayTrig, "!ultimate", false) == 0		|| strcmp(szSayTrig, "/ultimate", false) == 0
	) {
		return Plugin_Handled;
	}
	if(	strcmp(szSayTrig, "!help", false) == 0		|| strcmp(szSayTrig, "/help", false) == 0	||
	strcmp(szSayTrig, "!aide", false) == 0	|| strcmp(szSayTrig, "/aide", false) == 0	||
	strcmp(szSayTrig, "!aides", false) == 0	|| strcmp(szSayTrig, "/aides", false) == 0	
	) {
		ShowMOTDPanel(client, "Capture The Flag: Besoin d'aide?", "http://www.ts-x.eu/forum/viewtopic.php?p=116711#p116711", MOTDPANEL_TYPE_URL);
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
