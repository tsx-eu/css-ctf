#if defined _ctf_classes_included
#endinput
#endif
#define _ctf_classes_included

#include "ctf.sp"
#include "ctf.inc.const.sp"
#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"
#include "ctf.inc.sentry.sp"
#include "ctf.inc.grenades.sp"

public CTF_CLASS_init(client) {
	
	new wepIdx;
	
	for( new i = 0; i < 5; i++ ){
		
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ) {
			RemovePlayerItem( client, wepIdx );
		}
	}
	
	switch( g_iPlayerClass[client] ) {
		case class_scout: {
			CTF_SCOUT_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 4;
		}
		case class_sniper: {
			CTF_SNIPER_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 0;
		}
		case class_soldier: {
			CTF_SOLDIER_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 2;
		}
		case class_demoman: {
			CTF_DEMOMAN_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 2;
		}
		case class_medic: {
			CTF_MEDIC_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 4;
		}
		case class_hwguy: {
			CTF_HWGUY_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 2;
		}
		case class_pyro: {
			CTF_PYRO_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 0;
		}
		case class_spy: {
			CTF_SPY_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 4;
		}
		case class_engineer: {
			CTF_ENGINEER_init(client);
			
			g_iPlayerGrenadeAmount[client][0] = 4;
			g_iPlayerGrenadeAmount[client][1] = 4;
			
			g_fUlti_Cooldown[client] = 0.0;
		}
		case class_civilian: {
			CTF_CIVILIAN_init(client);
		}
		default: {
			CTF_NONE_init(client);
		}
	}
	
	g_flMetal[client] = 200.0;
}
public CTF_Ultimate(client) {
	if( g_fUlti_Cooldown[client] > GetGameTime() ) {
		PrintToChat(client, "[CTF] Vous ne pouvez pas utiliser votre ultimate pour encore %.2f secondes", (g_fUlti_Cooldown[client]-GetGameTime()));
		return;
	}
	if( !IsPlayerAlive(client) ) {
		return;
	}
	
	switch( g_iPlayerClass[client] ) {
		case class_scout: {
			CTF_SCOUT_ulti(client);
		}
		case class_sniper: {
			CTF_SNIPER_ulti(client);
		}
		case class_soldier: {
			CTF_SOLDIER_ulti(client);
		}
		case class_demoman: {
			CTF_DEMOMAN_ulti(client);
		}
		case class_medic: {
			CTF_MEDIC_ulti(client);
		}
		case class_hwguy: {
			CTF_HWGUY_ulti(client);
		}
		case class_pyro: {
			CTF_PYRO_ulti(client);
		}
		case class_spy: {
			CTF_SPY_ulti(client);
		}
		case class_engineer: {
			CTF_ENGINEER_ulti(client);
		}
	}
	
	return;
}

// ------------------------------------------------------------------------------------------------------------------
//		Classe: Scout
//
public CTF_SCOUT_init(client) {
	
	g_flPlayerSpeed[client] = 400.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 75, 4, true);
	SetEntityHealth(client, 75);
	
	g_iPlayerArmor[client] = 20;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_fiveseven");
	GivePlayerItem(client, "weapon_mac10");
}
public CTF_SCOUT_ulti(client) {
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_flPlayerSpeed[client] = 550.0;
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
	CreateTimer(ULTI_DURATION, CTF_SCOUT_ulti_Task, client);
	
	new Handle:dp;
	CreateDataTimer( 0.01, CTF_SCOUT_Energy, dp); 
	WritePackCell(dp, client);
	WritePackCell(dp, 0);
	
}
public Action:CTF_SCOUT_Energy(Handle:timer, Handle:dp1) {
	
	ResetPack(dp1);
	new client = ReadPackCell(dp1);
	new from_left = ReadPackCell(dp1);
	
	if( !IsPlayerAlive(client) )
		return Plugin_Handled;
	
	new Float:pos[3], Float:dir[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, dir);
	
	new Float:x = 0.0, Float:y = 10.0, Float:radian = degrees_to_radians(-dir[1]);
	
	if( from_left ) {
		y = -10.0;
		from_left = 0;
	}
	else {
		from_left = 1;
	}
	
	pos[0] = pos[0] + (x*Cosine(radian)) + (y*Sine(radian));
	pos[1] = pos[1] + (x*Sine(radian)) + (y*Cosine(radian));
	
	dir[0] = 0.0;
	dir[1] = 0.0;
	dir[2] = -1.0;
	
	TE_SetupEnergySplash(pos, dir, false);
	TE_SendToAll(0.0);
	
	if( g_fUlti_Cooldown[client] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
		
		new Handle:dp2;
		CreateDataTimer( 0.001, CTF_SCOUT_Energy, dp2); 
		WritePackCell(dp2, client);
		WritePackCell(dp2, from_left);
	}
	
	return Plugin_Handled;
}

public Action:CTF_SCOUT_ulti_Task(Handle:timer, any:client) {
	
	if( g_iPlayerClass[client] == class_scout ) {
		g_flPlayerSpeed[client] = 400.0;
		PrintToChat(client, "Votre ultimate a pris fin!");
	}
	
	return Plugin_Handled;
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Sniper
//
public CTF_SNIPER_init(client) {
	
	g_flPlayerSpeed[client] = 300.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 90, 4, true);
	SetEntityHealth(client, 90);
	
	g_iPlayerArmor[client] = 50;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_awp");
}
public CTF_SNIPER_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
	CreateTimer(ULTI_DURATION, CTF_SNIPER_ulti_Task, client);
}
public Action:CTF_SNIPER_ulti_Task(Handle:timer, any:client) {
	
	PrintToChat(client, "Votre ultimate a pris fin!");
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Soldier
//
public CTF_SOLDIER_init(client) {
	
	
	g_flPlayerSpeed[client] = 240.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
	SetEntityHealth(client, 100);
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_p228");
	GivePlayerItem(client, CUSTOM_WEAPON);
	
	g_iCustomWeapon_Ammo[client][0] = 4;
	g_iCustomWeapon_Ammo[client][1] = 50;
}
public CTF_SOLDIER_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
	CreateTimer(ULTI_DURATION, CTF_SOLDIER_ulti_Task, client);
}
public Action:CTF_SOLDIER_ulti_Task(Handle:timer, any:client) {
	
	PrintToChat(client, "Votre ultimate a pris fin!");
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Demoman
//
public CTF_DEMOMAN_init(client) {
	
	g_flPlayerSpeed[client] = 280.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 90, 4, true);
	SetEntityHealth(client, 90);
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_p228");
	GivePlayerItem(client, CUSTOM_WEAPON);
	GivePlayerItem(client, "weapon_hegrenade");
	
	g_iCustomWeapon_Ammo[client][0] = 6;
	g_iCustomWeapon_Ammo[client][1] = 50;
}
public CTF_DEMOMAN_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	new Float:vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	SpawnC4(client, vecOrigin, 10.0);
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Medic
//
public CTF_MEDIC_init(client) {
	
	g_flPlayerSpeed[client] = 320.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 90, 4, true);
	SetEntityHealth(client, 90);
	
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_p228");
	GivePlayerItem(client, CUSTOM_WEAPON);
	
	g_iCustomWeapon_Ammo[client][0] = 1;
	g_iCustomWeapon_Ammo[client][1] = 0;
}
public CTF_MEDIC_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	CTF_MEDIC_CONTA(client);
}
public CTF_MEDIC_CONTA(client) {
	
	new Float:vecOrigin[3], Float:vecOrigin2[3];
	GetClientEyePosition(client, vecOrigin);
	
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		
		GetClientEyePosition(i, vecOrigin2);
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) > HEAL_DIST )
			continue;
		
		if( GetClientTeam(client) == GetClientTeam(i) )
			continue;
		
		if( g_iPlayerClass[i] == class_medic )
			continue;
		
		g_iContaminated[i] = client;
		
		vecOrigin[2] -= 20.0;
		vecOrigin2[2] -= 20.0;
		
		TE_SetupBeamPoints(vecOrigin2, vecOrigin, g_cShockWave, 0, 0, 0, 0.4, 50.0, 50.0, 0, 0.0, {0, 250, 0, 250}, 20);
		TE_SendToAll();
		vecOrigin[2] += 5.0;
		vecOrigin2[2] += 5.0;
		TE_SetupBeamPoints(vecOrigin2, vecOrigin, g_cPhysicBeam, 0, 0, 0, 0.2, 20.0, 20.0, 0, 0.0, {0, 250, 0, 250}, 20);
		TE_SendToAll(0.1);
		
		vecOrigin[2] += 15.0;
		vecOrigin2[2] += 15.0;
		
	}
	
	g_fUlti_Cooldown[client] = (GetGameTime() + 5);
}
public CTF_MEDIC_HURTS(client) {
	
	g_fContaminate[client] = (GetGameTime() + GetRandomFloat(3.0, 5.0));
	
	new String:sound[128];
	Format(sound, sizeof(sound), "vo/npc/barney/ba_pain0%i.wav", GetRandomInt(1, 9));
	EmitSoundToAll(sound, client);
	
	new health = GetClientHealth(client);
	health -= GetRandomInt(3, 8);
	
	if( health <= 0 ) {
		SetEntityHealth(client, 1);
		DealDamage(client, 100, g_iContaminated[client]);
	}
	else {
		SetEntityHealth(client, health);
	}
	new Float:vecOrigin[3], Float:vecOrigin2[3], Float:vecNull[3];
	GetClientEyePosition(client, vecOrigin);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecNull);
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		
		GetClientEyePosition(i, vecOrigin2);
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) > (HEAL_DIST/2.0) )
			continue;
		
		if( GetClientTeam(client) != GetClientTeam(i) )
			continue;
		
		if( g_iPlayerClass[i] == class_medic )
			continue;
		
		g_iContaminated[i] = g_iContaminated[client];
	}
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: HWguy
//
public CTF_HWGUY_init(client) {
	
	g_flPlayerSpeed[client] = 230.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 150, 4, true);
	SetEntityHealth(client, 150);
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_deagle");
	GivePlayerItem(client, "weapon_m249");
}
public CTF_HWGUY_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_flPlayerSpeed[client] = 170.0;
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
	CreateTimer(ULTI_DURATION, CTF_HWGUY_ulti_Task, client);
}
public Action:CTF_HWGUY_ulti_Task(Handle:timer, any:client) {
	
	g_flPlayerSpeed[client] = 230.0;
	
	PrintToChat(client, "Votre ultimate a pris fin!");
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Pyro
//
public CTF_PYRO_init(client) {
	
	g_flPlayerSpeed[client] = 300.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
	SetEntityHealth(client, 100);
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_p228");
	GivePlayerItem(client, CUSTOM_WEAPON);
	
	g_iCustomWeapon_Ammo[client][0] = 100;
	g_iCustomWeapon_Ammo[client][1] = 5;
}
public CTF_PYRO_ulti(client) {
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Spy
//
public CTF_SPY_init(client) {
	
	g_flPlayerSpeed[client] = 300.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 90, 4, true);
	SetEntityHealth(client, 90);
	
	g_iPlayerArmor[client] = 50;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_usp");
}
public CTF_SPY_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_fUlti_Cooldown[client] = (GetGameTime()+60);
	g_flPlayerSpeed[client] = 350.0;
	
	CreateTimer(ULTI_DURATION, CTF_SPY_ulti_Task, client);
	
	new ent = CreateEntityByName("prop_ragdoll");
	
	new String:model[128];
	Entity_GetModel(client, model, sizeof(model));

	DispatchKeyValue(ent, "model", model);
	
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	new Float:vecOrigin[3], Float:vecAngles[3];
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	vecAngles[0] = 5.0;
	
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	g_iCustomWeapon_Entity2[client][0] = ent;
}
public Action:CTF_SPY_ulti_Task(Handle:timer, any:client) {
	
	if( g_iPlayerClass[client] == class_spy ) {
		PrintToChat(client, "Votre ultimate a pris fin!");
		g_flPlayerSpeed[client] = 300.0;
	}
	
	if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) ) {
		Desyntegrate(g_iCustomWeapon_Entity2[client][0]);
		g_iCustomWeapon_Entity2[client][0] = 0;
	}
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Engineer
//
public CTF_ENGINEER_init(client) {
	
	g_flPlayerSpeed[client] = 300.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 80, 4, true);
	SetEntityHealth(client, 80);
	
	g_iPlayerArmor[client] = 20;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_glock");
	GivePlayerItem(client, "weapon_ump45");
}
public CTF_ENGINEER_ulti(client) {
	
	new Handle:menu = CreateMenu(hMenu_Engineer);
	
	SetMenuTitle(menu, "Menu des constructions");
	
	if( !IsValidSentry(g_iBuild[client][build_sentry]) ) {
		AddMenuItem(menu, "build_sg", "Construire une tourelle [150]");
	}
	else {
		AddMenuItem(menu, "dis_sg", "Demonter la tourelle");
		AddMenuItem(menu, "det_sg", "Exploser la tourelle");
		
		if( g_iSentryLevel[ g_iBuild[client][build_sentry] ] == 1 ) {
			AddMenuItem(menu, "upg_sg", "Ameliorer la tourelle [150]");
		}
		else {
			AddMenuItem(menu, "upg_sg", "Ameliorer la tourelle [150]", ITEMDRAW_DISABLED);
		}
	}
	
	if( !IsValidTeleporter( g_iBuild[client][build_teleporter_in] ) ) {
		AddMenuItem(menu, "build_tp1", "Construire un teleporteur - entree [120]");
	}
	else {
		//AddMenuItem(menu, "dis_tp1", "Demonter le teleporteur - entree");
		AddMenuItem(menu, "det_tp1", "Exploser le teleporteur - entree");
	}
	
	if( !IsValidTeleporter( g_iBuild[client][build_teleporter_out] ) ) {
		AddMenuItem(menu, "build_tp2", "Construire un teleporteur - sortie [120]");
	}
	else {
		//AddMenuItem(menu, "dis_tp2", "Demonter le teleporteur - sortie");
		AddMenuItem(menu, "det_tp2", "Exploser le teleporteur - sortie");
	}
	
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	g_fUlti_Cooldown[client] = 0.0;
}
public hMenu_Engineer(Handle:hMenu, MenuAction:action, client, param2) {
	if( action == MenuAction_Select ) {
		
		if( !(GetEntityFlags(client) & FL_ONGROUND) ) {
			PrintToChat(client, "[CTF] Vous ne pouvez pas construire dans les aires.");
			
			CTF_ENGINEER_ulti(client);
			return;
		}
		if( !IsPlayerAlive(client) ) {
			
			PrintToChat(client, "[CTF] Vous devez etre en vie pour construire.");
			return;
		}
		new String:options[64];
		GetMenuItem(hMenu, param2, options, 63);
		
		// --------------------------------------------------------
		// 		Construire tourelle
		if( StrEqual(options, "build_sg") ) {
			
			if( IsValidSentry(g_iBuild[client][build_sentry]) ) {
				
				PrintToChat(client, "[CTF] Vous avez deja construit une tourelle.");
			}
			else {
				CTF_SG_Build(client);
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Demonter tourelle
		else if( StrEqual(options, "dis_sg") ) {
			
			if( !IsValidSentry(g_iBuild[client][build_sentry]) ) {
				
				PrintToChat(client, "[CTF] Vous n'avez pas de tourelle.");
			}
			else {
				
				if( !CTF_IsNear(client, g_iBuild[client][build_sentry]) ) {
					
					PrintToChat(client, "[CTF] Vous devez vous raprochez de votre tourelle pour la demonter.");
				}
				else {
					
					PrintToChat(client, "[CTF] Demontage en cours...");
					
					new ent = g_iBuild[client][build_sentry];
					ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"1\"", ent);
					
					g_flPlayerSpeed[client] = 0.0;
					
					g_iSentryLevel[ent] = 0;
					CreateTimer(2.0, CTF_SG_DismountPost, client);
					
				}
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Exploser tourelle
		else if( StrEqual(options, "det_sg") ) {
			
			if( !IsValidSentry(g_iBuild[client][build_sentry]) || g_flBuildHealth[ g_iBuild[client][build_sentry] ][build_sentry] <= 0.0 ) {
				
				PrintToChat(client, "[CTF] Vous n'avez pas de tourelle.");
			}
			else {
				
				g_flBuildHealth[ g_iBuild[client][build_sentry] ][build_sentry ] = 0.0;
				
				new Float:vecStart[3];
				GetEntPropVector(g_iBuild[client][build_sentry], Prop_Send, "m_vecOrigin", vecStart);
				
				ExplosionDamage(vecStart, 200.0, 200.0, client, g_iBuild[client][build_sentry]);
				DealDamage(g_iBuild[client][build_sentry], 1000, client);
				
				PrintToChat(client, "[CTF] Votre tourelle a ete detruite!");
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Ameliorer
		else if( StrEqual(options, "upg_sg") ) {
			if( !IsValidSentry(g_iBuild[client][build_sentry]) ) {
				
				PrintToChat(client, "[CTF] Vous n'avez pas de tourelle.");
			}
			else {
				
				if( g_iSentryLevel[ g_iBuild[client][build_sentry] ] != 1 ) {
					
					if( g_iSentryLevel[ g_iBuild[client][build_sentry] ] == 2 ) 
						PrintToChat(client, "[CTF] Votre tourelle est deja amelioree.");
					else
						PrintToChat(client, "[CTF] Impossible d'ameliorer votre tourelle pour le moment.");
				}
				else {
					if( !CTF_IsNear(client, g_iBuild[client][build_sentry]) ) {
						
						PrintToChat(client, "[CTF] Vous devez vous raprochez de votre tourelle pour l'ameliorer.");
					}
					else {
						
						if( g_flMetal[client] < 150.0 ) {
							PrintToChat(client, "[CTF] Vous n'avez pas assez de metal!");
						}
						else {
							PrintToChat(client, "[CTF] Amelioration en cours...");
							
							g_flMetal[client] -= 150.0;
							
							new ent = g_iBuild[client][build_sentry];
							ServerCommand("sm_effect_fading \"%i\" \"1.0\" \"1\"", ent);
							
							g_flPlayerSpeed[client] = 0.0;
							
							g_iSentryLevel[ent] = 0;
							CreateTimer(1.0, CTF_SG_UpgradeMiddle, client);
							CreateTimer(2.0, CTF_SG_UpgradePost, client);
							
							if( GetClientTeam(client) == CS_TEAM_CT ) {
								AttachParticle(ent, "blue_spikes2", 0.1);
							}
							else {
								AttachParticle(ent, "red_spikes2", 0.1);
							}
						}
					}
				}
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Construire TP Entrée
		else if( StrEqual(options, "build_tp1") ) {
			if( IsValidTeleporter(g_iBuild[client][build_teleporter_in]) ) {
				PrintToChat(client, "[CTF] Vous avez deja construit un teleporteur.");
			}
			else {
				CTF_TP_Build(client, build_teleporter_in);
			}
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Demonter TP Entrée
		else if( StrEqual(options, "dis_tp1") ) {
			if( !IsValidTeleporter(g_iBuild[client][build_teleporter_in]) ) {
				PrintToChat(client, "[CTF] Vous n'avez pas de teleporteur.");
			}
			else {
				
				if( !CTF_IsNear(client, g_iBuild[client][build_teleporter_in]) ) {
					PrintToChat(client, "[CTF] Vous devez vous raprochez de votre teleporteur pour le demonter.");
				}
				else {
					
					PrintToChat(client, "[CTF] Demontage en cours...");
					
					new ent = g_iBuild[client][build_teleporter_in];
					ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"1\"", ent);
					
					g_flPlayerSpeed[client] = 0.0;
					
					CreateTimer(2.0, CTF_TP1_DismountPost, client);
				}
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Exploser TP Entrée
		else if( StrEqual(options, "det_tp1") ) {
			if( !IsValidTeleporter(g_iBuild[client][build_teleporter_in]) ) {
				PrintToChat(client, "[CTF] Vous n'avez pas de teleporteur.");
			}
			else {
				
				g_flBuildHealth[ g_iBuild[client][build_teleporter_in] ][build_teleporter_in] = 0.0;
				
				new Float:vecStart[3];
				GetEntPropVector(g_iBuild[client][build_teleporter_in], Prop_Send, "m_vecOrigin", vecStart);
				
				ExplosionDamage(vecStart, 100.0, 100.0, client, g_iBuild[client][build_teleporter_in]);
				DealDamage(g_iBuild[client][build_teleporter_in], 1000, client);
				
				PrintToChat(client, "[CTF] Votre teleporteur a ete detruit!");
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Construire TP Sortie
		else if( StrEqual(options, "build_tp2") ) {
			if( IsValidTeleporter(g_iBuild[client][build_teleporter_out]) ) {
				PrintToChat(client, "[CTF] Vous avez deja construit un teleporteur.");
			}
			else {
				CTF_TP_Build(client, build_teleporter_out);
			}
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Demonter TP Sortie
		else if( StrEqual(options, "dis_tp2") ) {
			if( !IsValidTeleporter(g_iBuild[client][build_teleporter_out]) ) {
				PrintToChat(client, "[CTF] Vous n'avez pas de teleporteur.");
			}
			else {
				
				if( !CTF_IsNear(client, g_iBuild[client][build_teleporter_out]) ) {
					PrintToChat(client, "[CTF] Vous devez vous raprochez de votre teleporteur pour le demonter.");
				}
				else {
					
					PrintToChat(client, "[CTF] Demontage en cours...");
					
					new ent = g_iBuild[client][build_teleporter_out];
					ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"1\"", ent);
					
					g_flPlayerSpeed[client] = 0.0;
					
					CreateTimer(2.0, CTF_TP2_DismountPost, client);
				}
			}
			
			CTF_ENGINEER_ulti(client);
		}
		// --------------------------------------------------------
		// 		Exploser TP Sortie
		else if( StrEqual(options, "det_tp2") ) {
			if( !IsValidTeleporter(g_iBuild[client][build_teleporter_out]) ) {
				PrintToChat(client, "[CTF] Vous n'avez pas de teleporteur.");
			}
			else {
				
				g_flBuildHealth[ g_iBuild[client][build_teleporter_out] ][build_teleporter_out] = 0.0;
				
				new Float:vecStart[3];
				GetEntPropVector(g_iBuild[client][build_teleporter_out], Prop_Send, "m_vecOrigin", vecStart);
				
				ExplosionDamage(vecStart, 100.0, 100.0, client, g_iBuild[client][build_teleporter_out]);
				DealDamage(g_iBuild[client][build_teleporter_out], 1000, client);
				
				PrintToChat(client, "[CTF] Votre teleporteur a ete detruit!");
			}
			
			CTF_ENGINEER_ulti(client);
		}
	}
}
public Action:CTF_SG_DismountPost(Handle:timer, any:client) {
	
	if( IsValidSentry( g_iBuild[client][build_sentry] ) ) {
		g_iSentryLevel[ g_iBuild[client][build_sentry] ] = 0;
		
		g_flPlayerSpeed[client] = 300.0;
		
		g_flMetal[client] += 100.0;
		if( g_flMetal[client] >= 200.0 ) 
			g_flMetal[client] = 200.0;
		
		AcceptEntityInput(g_iBuild[client][build_sentry], "Kill");
		g_iBuild[client][build_sentry] = 0;
		
		PrintToChat(client, "[CTF] Votre tourelle a ete demontee!");
	}
}

public Action:CTF_TP1_DismountPost(Handle:timer, any:client) {
	
	if( IsValidSentry( g_iBuild[client][build_teleporter_in] ) ) {
		g_iSentryLevel[ g_iBuild[client][build_teleporter_in] ] = 0;
		
		g_flPlayerSpeed[client] = 300.0;
		
		g_flMetal[client] += 100.0;
		if( g_flMetal[client] >= 200.0 ) 
			g_flMetal[client] = 200.0;
		
		AcceptEntityInput(g_iBuild[client][build_teleporter_in], "Kill");
		g_iBuild[client][build_teleporter_in] = 0;
		
		PrintToChat(client, "[CTF] Votre teleporteur a ete demontee!");
	}
}
public Action:CTF_TP2_DismountPost(Handle:timer, any:client) {
	
	if( IsValidSentry( g_iBuild[client][build_teleporter_out] ) ) {
		g_iSentryLevel[ g_iBuild[client][build_teleporter_out] ] = 0;
		
		g_flPlayerSpeed[client] = 300.0;
		
		g_flMetal[client] += 100.0;
		if( g_flMetal[client] >= 200.0 ) 
			g_flMetal[client] = 200.0;
		
		AcceptEntityInput(g_iBuild[client][build_teleporter_out], "Kill");
		g_iBuild[client][build_teleporter_out] = 0;
		
		PrintToChat(client, "[CTF] Votre teleporteur a ete demontee!");
	}
}
public Action:CTF_SG_UpgradeMiddle(Handle:timer, any:client) {
	
	SetEntityModel(g_iBuild[client][build_sentry], "models/buildables/sentry2.mdl");
	SetEntProp(g_iBuild[client][build_sentry], Prop_Data, "m_nSolidType", 2);
	g_flBuildHealth[ g_iBuild[client][build_sentry] ][build_sentry] += 250.0;
	
	ServerCommand("sm_effect_fading \"%i\" \"1.0\" \"0\"", g_iBuild[client][build_sentry]);
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		DispatchKeyValue( g_iBuild[client][build_sentry] , "Skin", "1");
	}
}
public Action:CTF_SG_UpgradePost(Handle:timer, any:client) {
	
	g_iSentryLevel[ g_iBuild[client][build_sentry] ] = 2;
	
	g_flBuildHealth[ g_iBuild[client][build_sentry] ][build_sentry] += 250.0;
	
	g_flPlayerSpeed[client] = 300.0;
	
	PrintToChat(client, "[CTF] Votre tourelle a ete amelioree avec succes!");
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Civilian
//
public CTF_CIVILIAN_init(client) {
	
	g_flPlayerSpeed[client] = 280.0;
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 50, 4, true);
	SetEntityHealth(client, 50);
	
	g_iPlayerArmor[client] = 0;
	
	GivePlayerItem(client, "weapon_knife");
}

// ------------------------------------------------------------------------------------------------------------------
//		Classe: None -> Selection
//
public CTF_NONE_init(client) {
	
	new String:g_szClass[10][32] = { "Aucune", "Eclaireur", "Sniper", "Soldat", "Artificier", "Infirmier", "Mitrailleur", "Pyroman", "Espion", "Technicien" };
	
	new Handle:menu = CreateMenu(hMenu_SelectClass);	
	SetMenuTitle(menu, "CTF: Selectionner votre classe");
	
	for(new i=1; i<10; i++) {
		
		new max = GetConVarInt(g_hClassRestriction[i]);
		new amount = 0;
		
		for(new a=0; a<=GetMaxClients(); a++ ) {
			if( !IsValidClient(a) )
				continue;
			if( _:g_iPlayerClass[a] != i )
				continue;
			if( GetClientTeam(client) != GetClientTeam(a) )
				continue;
			
			amount++;			
		}
		new String:tmp1[32];
		new String:tmp2[32];
		
		Format(tmp1, 31, "%i", i);
		if( max < 0 ) {
			Format(tmp2, 31, "%s - [%i]", g_szClass[i], amount);
		}
		else {
			Format(tmp2, 31, "%s - [%i/%i]", g_szClass[i], amount, max);
		}
		
		AddMenuItem(menu, tmp1, tmp2);
		
	}
	
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	if( g_iPlayerClass[client] == class_none ) {
		SetMenuExitButton(menu, false);
	}
	else {
		SetMenuExitButton(menu, true);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public hMenu_SelectClass(Handle:hMenu, MenuAction:action, client, param2) {
	
	if( action == MenuAction_Select ) {
		
		new String:options[64];
		GetMenuItem(hMenu, param2, options, 63);
		
		new i = StringToInt(options);
		new max = GetConVarInt(g_hClassRestriction[i]);
		new amount = 0;
		
		for(new a=0; a<=GetMaxClients(); a++ ) {
			if( !IsValidClient(a) )
				continue;
			if( _:g_iPlayerClass[a] != i )
				continue;
			if( GetClientTeam(client) != GetClientTeam(a) )
				continue;
			
			amount++;			
		}
		
		if( !(max < 0 || amount<max) ) {
			PrintToChat(client, "[CTF] Il n'y a plus de place dans cette classe.");
			CTF_NONE_init(client);
			return;
		}
		
		if( g_iPlayerClass[client] == class_none && IsPlayerAlive(client)) {
			SetClientFrags(client, (GetClientFrags(client)+1));
			SetClientDeaths(client, (GetClientDeaths(client)-1));
		}
		g_iPlayerClass[client] = enum_class_type:i;
		DealDamage(client, (GetClientHealth(client)*100), client);
		
		CTF_WEAPON_PIPE_PipeBomb_EXPL(client, true);
		if( g_iPlayerClass[client] != class_engineer )
			CTF_ENGINEER_DETALL(client);
	}
}
public CTF_SNIPER_dot(client) {
	
	new String:weapon[32];
	GetClientWeapon(client, weapon, sizeof(weapon));
	
	if( !StrEqual(weapon, "weapon_awp", false) )
		return;
	
	new Float:vecTarget[3];
	GetPlayerEye(client, vecTarget);
	
	TE_SetupGlowSprite( vecTarget, g_cGlow, 0.1, 0.1, 255);
	TE_SendToAll();
}
public bool:GetPlayerEye(client, Float:pos[3]) {
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, FilterToOne, client);
	
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}
