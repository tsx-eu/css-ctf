#if defined _ctf_classes_included
#endinput
#endif
#define _ctf_classes_included

#include "ctf.sp"

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
		}
		case class_sniper: {
			CTF_SNIPER_init(client);
		}
		case class_soldier: {
			CTF_SOLDIER_init(client);
		}
		case class_demoman: {
			CTF_DEMOMAN_init(client);
		}
		case class_medic: {
			CTF_MEDIC_init(client);
		}
		case class_hwguy: {
			CTF_HWGUY_init(client);
		}
		case class_pyro: {
			CTF_PYRO_init(client);
		}
		case class_spy: {
			CTF_SPY_init(client);
		}
		case class_engineer: {
			CTF_ENGINEER_init(client);
		}
		case class_civilian: {
			CTF_CIVILIAN_init(client);
		}
		default: {
			CTF_NONE_init(client);
		}
	}
	
	g_iPlayerGrenadeAmount[client][0] = 4;
	g_iPlayerGrenadeAmount[client][1] = 4;
	g_flMetal[client] = 200.0;
}
public CTF_Ultimate(client) {
	if( g_fUlti_Cooldown[client] > GetGameTime() ) {
		PrintToChat(client, "[CTF] Vous ne pouvez pas utiliser votre ultimate pour encore %.2f secondes", (g_fUlti_Cooldown[client]-GetGameTime()));
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.75);
	SetEntityGravity(client, 0.60);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 75, 4, true);
	SetEntityHealth(client, 75);
	
	g_iPlayerArmor[client] = 20;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_fiveseven");
	GivePlayerItem(client, "weapon_mac10");
}
public CTF_SCOUT_ulti(client) {
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.10);
	SetEntityGravity(client, 0.50);
	
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
	
	
}

public Action:CTF_SCOUT_ulti_Task(Handle:timer, any:client) {
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.75);
	SetEntityGravity(client, 0.60);
	
	
	PrintToChat(client, "Votre ultimate a pris fin!");
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Sniper
//
public CTF_SNIPER_init(client) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.8);
	SetEntityGravity(client, 0.8);
	
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 150, 4, true);
	SetEntityHealth(client, 150);
	
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
	SetEntityGravity(client, 0.75);
	
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
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) > (HEAL_DIST/2.0) )
			continue;
		
		if( GetClientTeam(client) == GetClientTeam(i) )
			continue;
		
		if( g_iPlayerClass[i] == class_medic )
			continue;
		
		g_iContaminated[i] = client;
	}
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.8);
	SetEntityGravity(client, 1.1);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 200, 4, true);
	SetEntityHealth(client, 200);
	
	g_iPlayerArmor[client] = 100;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_deagle");
	GivePlayerItem(client, "weapon_m249");
}
public CTF_HWGUY_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.4);
	SetEntityGravity(client, 1.6);
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
	CreateTimer(ULTI_DURATION, CTF_HWGUY_ulti_Task, client);
}
public Action:CTF_HWGUY_ulti_Task(Handle:timer, any:client) {
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.8);
	SetEntityGravity(client, 1.1);
	
	PrintToChat(client, "Votre ultimate a pris fin!");
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Pyro
//
public CTF_PYRO_init(client) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	
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
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 90, 4, true);
	SetEntityHealth(client, 90);
	
	g_iPlayerArmor[client] = 50;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_usp");
}
public CTF_SPY_ulti(client) {
	
	PrintToChat(client, "Vous avez utilise votre ultimate!");
	
	g_fUlti_Cooldown[client] = (GetGameTime() + ULTI_COOLDOWN);
	
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
	
	vecAngles[0] = 0.0;
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	g_iCustomWeapon_Entity2[client][0] = ent;
}
public Action:CTF_SPY_ulti_Task(Handle:timer, any:client) {
	
	PrintToChat(client, "Votre ultimate a pris fin!");
	
	if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) ) {
		Desyntegrate(g_iCustomWeapon_Entity2[client][0]);
		g_iCustomWeapon_Entity2[client][0] = 0;
	}
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Engineer
//
public CTF_ENGINEER_init(client) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.9);
	SetEntityGravity(client, 1.05);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 80, 4, true);
	SetEntityHealth(client, 80);
	
	g_iPlayerArmor[client] = 20;
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_glock");
	GivePlayerItem(client, "weapon_ump45");
}
public CTF_ENGINEER_ulti(client) {
	
	CTF_SG_Build(client);
	
	g_fUlti_Cooldown[client] = (GetGameTime() + 0.5);
}
// ------------------------------------------------------------------------------------------------------------------
//		Classe: Civilian
//
public CTF_CIVILIAN_init(client) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 50, 4, true);
	SetEntityHealth(client, 50);
	
	g_iPlayerArmor[client] = 0;
	
	GivePlayerItem(client, "weapon_knife");
}

// ------------------------------------------------------------------------------------------------------------------
//		Classe: None -> Selection
//
public CTF_NONE_init(client) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityGravity(client, 0.0);
	
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
	SetEntityHealth(client, 100);
	
	g_iPlayerArmor[client] = 0;
	
	new Handle:menu = CreateMenu(hMenu_SelectClass);
	
	SetMenuTitle(menu, "CTF: Selectionner votre classe");
	
	AddMenuItem(menu, "1", "Eclaireur");
	AddMenuItem(menu, "2",	"Sniper");
	AddMenuItem(menu, "3", "Soldat");
	AddMenuItem(menu, "4", "Artificier");
	AddMenuItem(menu, "5", "Infirmier");
	AddMenuItem(menu, "6", "Mitrailleur");
	AddMenuItem(menu, "7", "Pyroman", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "8", "Espion");
	AddMenuItem(menu, "9", "Technicien");
	
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public hMenu_SelectClass(Handle:hMenu, MenuAction:action, client, param2) {
	
	if( action == MenuAction_Select ) {
		
		new String:options[64];
		GetMenuItem(hMenu, param2, options, 63);
		
		g_iPlayerClass[client] = enum_class_type:StringToInt(options);
		SlapPlayer(client, 50000);
	}
}
