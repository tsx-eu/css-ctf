#if defined _ctf_weapons_included
#endinput
#endif
#define _ctf_weapons_included

#include "ctf.sp"



new String:g_szCustomWeapon_model[ class_max ][256];

public CTF_WEAPON_init() {
	Format(g_szCustomWeapon_model[class_soldier], 255, "models/weapons/w_models/w_rocketlauncher.mdl");
	Format(g_szCustomWeapon_model[class_demoman], 255, "models/weapons/w_models/w_grenadelauncher.mdl");
	Format(g_szCustomWeapon_model[class_medic], 255, "models/weapons/w_models/w_medigun.mdl");
	Format(g_szCustomWeapon_model[class_pyro], 255, "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl");
}

// ------------------------------------------------------------------------------------------------------------------
//		Custom Weapon: Global - Prethink
//
public CTF_WEAPON_CUSTOM_FRAME(client) {
	
	new class = g_iPlayerClass[client];
	if( strlen(g_szCustomWeapon_model[class]) > 1 ) {
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		new ent = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		
		
		if( StrEqual(WeaponName, CUSTOM_WEAPON, false) ) {
			
			
			if( g_iCustomWeapon_Entity[client][1] == -1 || !g_bIsCustomWeapon[g_iCustomWeapon_Entity[client][1]] ) {
				
				g_iCustomWeapon_Entity[client][0] = ent;
				
				ent = CreateEntityByName("prop_dynamic");
				SetEntityModel(ent, g_szCustomWeapon_model[class]);
				
				if( GetClientTeam(client) == CS_TEAM_CT ) {
					DispatchKeyValue(ent, "Skin", "1");
				}
				
				DispatchKeyValue(ent, "disableshadows", "1");
				DispatchKeyValue(ent, "nodamageforces", "1");
				DispatchKeyValue(ent, "spawnflags", "6");
				
				DispatchSpawn(ent);
				
				new String:ParentName[128];
				Format(ParentName, sizeof(ParentName), "ctf_weapon_%i%i%i", ent, client, GetRandomInt(11111, 99999) );
				DispatchKeyValue(client, "targetname", ParentName);
				
				SetVariantString(ParentName);
				AcceptEntityInput(ent, "SetParent");
				
				SetVariantString("muzzle_flash");
				AcceptEntityInput(ent, "SetParentAttachment");
				
				new Float:pos[3], Float:dir[3];
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
				pos[0] = -5.0;	pos[1] = -20.0;	pos[2] = 5.0;
				dir[0] = 15.0;	dir[1] = 40.0;	dir[2] = -20.0;
				
				TeleportEntity(ent, pos, dir, NULL_VECTOR);
				
				g_iCustomWeapon_Entity[client][1] = ent;
				g_bIsCustomWeapon[g_iCustomWeapon_Entity[client][1]] = true;
				
			}
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
			
			SetEntityRenderMode(WeaponIndex, RENDER_TRANSCOLOR);
			SetEntityRenderColor(WeaponIndex, 0, 0, 0, 0);
			
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", (GetGameTime()+5.0));
			
			Client_SetWeaponAmmo(client, CUSTOM_WEAPON, g_iCustomWeapon_Ammo[client][1], g_iCustomWeapon_Ammo[client][1], g_iCustomWeapon_Ammo[client][0], g_iCustomWeapon_Ammo[client][0]);
			
		}
		else {
			
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			
			CTF_WEAPON_CUSTOM_CLEAN(client);
		}
	}
}
public CTF_WEAPON_CUSTOM_CLEAN(client) {
	if( IsValidEdict(g_iCustomWeapon_Entity[client][1]) && g_bIsCustomWeapon[g_iCustomWeapon_Entity[client][1]] ) {
		AcceptEntityInput(g_iCustomWeapon_Entity[client][1], "Kill");
		g_bIsCustomWeapon[g_iCustomWeapon_Entity[client][1]] = false;
		
		g_iCustomWeapon_Entity[client][1] = -1;
	}
	
	
	if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) )
		AcceptEntityInput(g_iCustomWeapon_Entity2[client][0], "Kill");
	if( g_iCustomWeapon_Entity2[client][1] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][1]) && IsValidEntity(g_iCustomWeapon_Entity2[client][1]) )
		AcceptEntityInput(g_iCustomWeapon_Entity2[client][1], "Kill");
	
	g_iCustomWeapon_Entity2[client][0] = -1;
	g_iCustomWeapon_Entity2[client][1] = -1;
	g_iCustomWeapon_Entity2[client][2] = -1;
	
}
public Action:CTF_WEAPON_CUSTOM_ACTION(client, &buttons) {
	if( !IsPlayerAlive(client) )
		return Plugin_Continue;
	
	if( g_iCustomWeapon_Entity[client][1] == -1 ) {
		return Plugin_Continue;
	}
	
	if( g_iPlayerClass[client] == class_soldier ) {
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, CUSTOM_WEAPON, false) && g_bIsCustomWeapon[ g_iCustomWeapon_Entity[client][1] ] ) {
			
			if( (buttons & IN_ATTACK) && g_fCustomWeapon_NextShoot[client][0] < GetGameTime() ) {
				
				CTF_WEAPON_RPG_Attack_1(client);
			}
			if( (buttons & IN_RELOAD) && g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
				
				CTF_WEAPON_RPG_Reload(client);
			}
		}
	}
	if( g_iPlayerClass[client] == class_demoman ) {
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, CUSTOM_WEAPON, false) && g_bIsCustomWeapon[ g_iCustomWeapon_Entity[client][1] ] ) {
			
			if( (buttons & IN_ATTACK) && g_fCustomWeapon_NextShoot[client][0] < GetGameTime() ) {
				
				CTF_WEAPON_PIPE_Attack_1(client);
			}
			if( (buttons & IN_ATTACK2) && g_fCustomWeapon_NextShoot[client][1] < GetGameTime() ) {
				
				CTF_WEAPON_PIPE_Attack_2(client);
			}
			if( (buttons & IN_RELOAD) && g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
				
				CTF_WEAPON_PIPE_Reload(client);
			}
		}
	}
	if( g_iPlayerClass[client] == class_medic ) {
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, CUSTOM_WEAPON, false) && g_bIsCustomWeapon[ g_iCustomWeapon_Entity[client][1] ] ) {
			
			if( (buttons & IN_ATTACK) && g_fCustomWeapon_NextShoot[client][0] < GetGameTime() ) {
				
				CTF_WEAPON_MEDIC_Attack_1(client);
			}
		}
	}
	if( g_iPlayerClass[client] == class_pyro ) {
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, CUSTOM_WEAPON, false) && g_bIsCustomWeapon[ g_iCustomWeapon_Entity[client][1] ] ) {
			
			if( (buttons & IN_ATTACK) && g_fCustomWeapon_NextShoot[client][0] < GetGameTime() ) {
				
				CTF_WEAPON_FLAME_Attack_1(client);
			}
			if( (buttons & IN_RELOAD) && g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
				
				CTF_WEAPON_FLAME_Reload(client);
			}
		}
	}
	return Plugin_Continue;
}
// ------------------------------------------------------------------------------------------------------------------
//		Custom Weapon - RPG
//
public CTF_WEAPON_RPG_Attack_1(client) {
	if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
		
		if( g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
			CTF_WEAPON_RPG_Reload(client);
		}
	}
	else {
		
		CTF_WEAPON_RPG_FireRocket(client);
		g_iCustomWeapon_Ammo[client][0]--;
		
		g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 0.75);
		g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.75);
		
		if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
			
			CreateTimer(1.0, CTF_WEAPON_RPG_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 1.0);
		}
	}
}
public CTF_WEAPON_RPG_Reload(client) {
	if( (g_fCustomWeapon_NextShoot[client][0]) < GetGameTime() ) {
		
		if( g_iCustomWeapon_Ammo[client][0] < 4 && g_iCustomWeapon_Ammo[client][1] > 1) {
			
			CreateTimer(0.5, CTF_WEAPON_RPG_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 1.0);
			g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 1.0);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.6);
		}
	}
}
public Action:CTF_WEAPON_RPG_Reload_Task(Handle:timer, any:client) {
	
	if( g_iCustomWeapon_Ammo[client][0] < 4 && g_iCustomWeapon_Ammo[client][1] > 1) {
		if( (g_fCustomWeapon_NextShoot[client][2]-0.2) < GetGameTime() ) {
			
			g_iCustomWeapon_Ammo[client][0]++;
			g_iCustomWeapon_Ammo[client][1]--;
			
			CreateTimer(0.5, CTF_WEAPON_RPG_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.6);
		}
	}
}
public CTF_WEAPON_RPG_FireRocket(client) {
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3];
	
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	new Float:rad = degrees_to_radians(vecAngles[1]);
	
	vecOrigin[0] = (vecOrigin[0] - (-7.0 * Sine(rad))   + (35.0 * Cosine(rad)) );
	vecOrigin[1] = (vecOrigin[1] + (-7.0 * Cosine(rad)) + (35.0 * Sine(rad)) );
	vecOrigin[2] = (vecOrigin[2] - 1.0);
	
	new String:classname[128];
	Format(classname, sizeof(classname), "ctf_rocket_%i", client);
	
	new ent = CreateEntityByName("flashbang_projectile");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetEntityModel(ent, "models/weapons/w_missile_closed.mdl");
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new Float:fMins[3] = {-1.0, -3.0, -1.0};
	new Float:fMaxs[3] = {1.0, 3.0, 1.0};
	
	SetEntPropVector( ent, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector( ent, Prop_Send, "m_vecMaxs", fMaxs);
	
	SetEntityMoveType(ent, MOVETYPE_FLY);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE);
	
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecVelocity, 1200.0);
	
	TeleportEntity(ent, vecOrigin, vecAngles, vecVelocity);
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", ent, 0, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.4);
	EmitSoundToAll("weapons/rpg/rocketfire1.wav", client, 1, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.2);
	
	if( GetClientTeam( client) == CS_TEAM_T ) {
		MakeSmokeFollow(ent, 3.0, {250, 50, 50, 200});
	}
	else {
		MakeSmokeFollow(ent, 3.0, {50, 50, 250, 200});
	}	
	
	SDKHook(ent, SDKHook_Touch, CTF_WEAPON_RPG_FireRocket_TOUCH);
	
}
public CTF_WEAPON_RPG_FireRocket_TOUCH(rocket, entity) {
	
	new String:classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if( StrContains(classname, "trigger_", false) == 0) 
		return;
	
	new Float:vecOrigin[3];
	
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", vecOrigin);
	
	if( g_fUlti_Cooldown[GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity")] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
		ExplosionDamage(vecOrigin, 80.0, 250.0, GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"), rocket);
	}
	else {
		ExplosionDamage(vecOrigin, 120.0, 250.0, GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"), rocket);
	}
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 250, 250);
	TE_SendToAll();
	
	StopSound(rocket, 0, "weapons/rpg/rocket1.wav");
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	EmitSoundToAll(sound, rocket, 0, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	
	Colorize(rocket, 255, 255, 255, 0);
	vecOrigin[0] = 0.0;
	vecOrigin[1] = 0.0;
	vecOrigin[2] = 0.0;
	
	TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, vecOrigin);
	
	SetEntProp(rocket, Prop_Data, "m_nSolidType", 0);
	SetEntProp(rocket, Prop_Data, "m_MoveCollide", 0);
	SetEntProp(rocket, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	DispatchKeyValue(rocket, "solid", "0");
	
	SDKUnhook(rocket, SDKHook_Touch, CTF_WEAPON_RPG_FireRocket_TOUCH);	
	SheduleEntityInput(rocket, 3.0, "KillHierarchy");
}
// ------------------------------------------------------------------------------------------------------------------
//		Custom Weapon - PIPE LAUNCHER
//
public CTF_WEAPON_PIPE_Attack_1(client) {
	if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
		
		if( g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
			CTF_WEAPON_PIPE_Reload(client);
		}
	}
	else {
		
		new String:classname[128];
		Format(classname, sizeof(classname), "ctf_pipe_%i", client);
		new iPipeAmount = 0, iPipeFirst = 0;
		for(new i=1; i<=2048; i++) {
			if( !IsValidEdict(i) )
				continue;
			if( !IsValidEntity(i) )
				continue;
			
			new String:classname2[128];
			
			GetEdictClassname(i, classname2, sizeof(classname));
			
			if( StrEqual(classname, classname2) ) {
				
				if( GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == 0 )
					continue;
				
				iPipeAmount++;
				
				if( iPipeFirst == 0 ) {
					iPipeFirst = i;
				}
			}
		}
		
		if( iPipeAmount >= 8 ) {
			CTF_WEAPON_PIPE_PipeBomb_EXPL(iPipeFirst);
		}
		
		CTF_WEAPON_PIPE_PipeBomb(client);
		g_iCustomWeapon_Ammo[client][0]--;
		
		g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 0.75);
		g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 0.40);
		g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.75);
		
		if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
			
			CreateTimer(1.0, CTF_WEAPON_PIPE_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 1.0);
		}
	}
}
public CTF_WEAPON_PIPE_Attack_2(client) {
	g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 0.4);
	
	CTF_WEAPON_PIPE_PipeBomb_EXPL(client, true);
}
public CTF_WEAPON_PIPE_Reload(client) {
	if( (g_fCustomWeapon_NextShoot[client][0]) < GetGameTime() ) {
		
		if( g_iCustomWeapon_Ammo[client][0] < 6 && g_iCustomWeapon_Ammo[client][1] > 1) {
			
			CreateTimer(0.5, CTF_WEAPON_PIPE_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 1.0);
			g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 1.0);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.6);
		}
	}
}
public Action:CTF_WEAPON_PIPE_Reload_Task(Handle:timer, any:client) {
	
	if( g_iCustomWeapon_Ammo[client][0] < 6 && g_iCustomWeapon_Ammo[client][1] > 1) {
		if( (g_fCustomWeapon_NextShoot[client][2]-0.2) < GetGameTime() ) {
			
			g_iCustomWeapon_Ammo[client][0]++;
			g_iCustomWeapon_Ammo[client][1]--;
			
			CreateTimer(0.5, CTF_WEAPON_PIPE_Reload_Task, client);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.6);
		}
	}
}
public CTF_WEAPON_PIPE_PipeBomb(client) {
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3];
	
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	new Float:rad = degrees_to_radians(vecAngles[1]);
	
	vecOrigin[0] = (vecOrigin[0] - (-7.0 * Sine(rad))   + (35.0 * Cosine(rad)) );
	vecOrigin[1] = (vecOrigin[1] + (-7.0 * Cosine(rad)) + (35.0 * Sine(rad)) );
	vecOrigin[2] = (vecOrigin[2] - 1.0);
	
	new String:classname[128];
	Format(classname, sizeof(classname), "ctf_pipe_%i", client);
	
	new ent = CreateEntityByName("flashbang_projectile");
	
	DispatchKeyValue(ent, "classname", classname);
	if( GetClientTeam(client) == CS_TEAM_T ) {
		DispatchKeyValue(ent, "Skin", "0");
	}
	else {
		DispatchKeyValue(ent, "Skin", "1");
	}
	
	DispatchKeyValue(ent, "model", "models/weapons/w_models/w_grenade_grenadelauncher.mdl");
	ActivateEntity(ent);
	DispatchSpawn(ent);
	
	SetEntityModel(ent, "models/weapons/w_models/w_grenade_grenadelauncher.mdl");
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.4);
	SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
//	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE);
	
	vecAngles[0]-=10.0;
	
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecVelocity, 1000.0);
	
	TeleportEntity(ent, vecOrigin, vecAngles, vecVelocity);
	
	if( GetClientTeam( client) == CS_TEAM_T ) {
		MakeSmokeFollow(ent, 3.0, {250, 50, 50, 200});
	}
	else {
		MakeSmokeFollow(ent, 3.0, {50, 50, 250, 200});
	}	
	
	SDKHook(ent, SDKHook_Touch, CTF_WEAPON_PIPE_PipeBomb_TOUCH);
	
}
public CTF_WEAPON_PIPE_PipeBomb_TOUCH(rocket, entity) {
	
	if( !IsValidClient(entity) ) {
		
		new String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if( Entity_IsSolid(entity) || StrContains(classname, "ctf_pipe_") == 0 ) {
			new Float:here[3];
			GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", here);
			
			if( GetVectorDistance(g_vecLastTouch[rocket], here) <= 0.0001 && g_flLastTouch[rocket] <= GetGameTime()+0.25 ) {
				
				
				TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, here);
				SetEntityMoveType(rocket, MOVETYPE_NONE);
			}
			g_flLastTouch[rocket] = GetGameTime();
			GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", g_vecLastTouch[rocket]);
		}
		
		return;
	}
	
	new Float:vecVelocity[3];
	Entity_GetAbsVelocity(rocket, vecVelocity);
	
	if( GetVectorLength(vecVelocity) > 1.0 ) {
		CTF_WEAPON_PIPE_PipeBomb_EXPL(rocket);
	}
}
stock CTF_WEAPON_PIPE_PipeBomb_EXPL(rocket, all=false) {
	
	if( all ) {
		new String:classname[128];
		Format(classname, sizeof(classname), "ctf_pipe_%i", rocket);
		
		for(new i=1; i<=2048; i++) {
			if( !IsValidEdict(i) )
				continue;
			if( !IsValidEntity(i) )
				continue;
			
			new String:classname2[128];
			
			GetEdictClassname(i, classname2, sizeof(classname));
			
			if( StrEqual(classname, classname2) ) {
				
				if( GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == 0 )
					continue;
				
				CTF_WEAPON_PIPE_PipeBomb_EXPL(i);
			}
		}
		return;
	}
	
	new Float:vecOrigin[3];
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", vecOrigin);
	
	ExplosionDamage(vecOrigin, 150.0, 200.0, GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"), rocket);
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	EmitSoundToAll(sound, rocket, 0, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	
	Colorize(rocket, 255, 255, 255, 0);
	vecOrigin[0] = 0.0;
	vecOrigin[1] = 0.0;
	vecOrigin[2] = 0.0;
	
	SetEntityMoveType(rocket, MOVETYPE_FLY);
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", 0);
	TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, vecOrigin);
	
	SetEntProp(rocket, Prop_Data, "m_nSolidType", 0);
	SetEntProp(rocket, Prop_Data, "m_MoveCollide", 0);
	SetEntProp(rocket, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	DispatchKeyValue(rocket, "solid", "0");
	
	SDKUnhook(rocket, SDKHook_Touch, CTF_WEAPON_PIPE_PipeBomb_TOUCH);	
	SheduleEntityInput(rocket, 3.0, "KillHierarchy");
}
// ------------------------------------------------------------------------------------------------------------------
//		Custom Weapon - Medi-Gun
//
public CTF_WEAPON_MEDIC_Attack_1(client) {
	
	g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 0.2);
	
	if( IsValidClient(g_iCustomWeapon_Entity2[client][2] ) ) {
		
		new target = g_iCustomWeapon_Entity2[client][2];
		
		new health = (GetClientHealth(target) + GetRandomInt(2, 3));
		
		if( Entity_GetMaxHealth(target) >= health ) {
			SetEntityHealth(target, health);
		}
		
		if( g_iContaminated[target] > 0 ) {
			if( g_fContaminate[target] < (GetGameTime() + 0.2) ) {
				g_iContaminated[target] = 0;
				g_fContaminate[target] = 0.0;
			}
		}
		return;
	}
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecTarget[3], Float:dist = 0.0;
	
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	while( dist<HEAL_DIST ) {
		dist += 10.0;
		
		vecTarget[0] = (vecOrigin[0] + (dist * Cosine(degrees_to_radians(vecAngles[1]))) );
		vecTarget[1] = (vecOrigin[1] + (dist * Sine(degrees_to_radians(vecAngles[1]))) );
		vecTarget[2] = (vecOrigin[2] + (-dist * Sine(degrees_to_radians(vecAngles[0]))) );
		
		new Float:Nearest_dist = (dist*2.0), Nearest_target = -1;
		
		for(new i=1; i<=GetMaxClients(); i++) {
			if( !IsValidClient(i) )
				continue;
			if( !IsPlayerAlive(i) )
				continue;
			if( client == i )
				continue;
			if( GetClientTeam(i) != GetClientTeam(client) )
				continue;
			
			new Float:vecOrigin2[3], Float:fDist;
			GetClientEyePosition(i, vecOrigin2);
			
			fDist = GetVectorDistance(vecTarget, vecOrigin2);
			
			if( fDist >= HEAL_DIST )
				continue;
			
			if( fDist < Nearest_dist ) {
				
				Nearest_dist = fDist;
				Nearest_target = i;
			}
		}
		
		if( !IsValidClient(Nearest_target) )
			continue;
		
		CTF_WEAPON_MEDIC_link(client, Nearest_target);
		break;
	}
}
public CTF_WEAPON_MEDIC_link(client, target) {
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecTarget[3], String:ParentName[64];
	GetClientAbsOrigin(client, vecOrigin);
	if( IsValidClient(target) ) {
		GetClientAbsOrigin(target, vecTarget);
	}
	else {
		
		if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) )
			AcceptEntityInput(g_iCustomWeapon_Entity2[client][0], "Kill");
		if( g_iCustomWeapon_Entity2[client][1] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][1]) && IsValidEntity(g_iCustomWeapon_Entity2[client][1]) )
			AcceptEntityInput(g_iCustomWeapon_Entity2[client][1], "Kill");
		
		g_iCustomWeapon_Entity2[client][0] = -1;
		g_iCustomWeapon_Entity2[client][1] = -1;
		g_iCustomWeapon_Entity2[client][2] = -1;
		
		return;
	}
	
	GetClientAbsAngles(client, vecAngles);
	
	Format(ParentName, sizeof(ParentName), "ctf_beam_%i", client);
	
	if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) &&
		g_iCustomWeapon_Entity2[client][1] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][1]) && IsValidEntity(g_iCustomWeapon_Entity2[client][1])
		) {
		
		new String:classname[64];
		GetEdictClassname( g_iCustomWeapon_Entity2[client][0], classname, 63);
		
		if( StrEqual(classname, ParentName) ) {
			
			if( g_iCustomWeapon_Entity2[client][2] == target )
				return;
			
			Format(ParentName, sizeof(ParentName), "ctf_link_2_%i%i%i", client, target, GetRandomInt(11111, 99999) );
			DispatchKeyValue(target, "targetname", ParentName);
			SetVariantString(ParentName);
			AcceptEntityInput(g_iCustomWeapon_Entity2[client][1], "SetParent");
			
			vecOrigin[0] = 0.0;
			vecOrigin[1] = 0.0;
			vecOrigin[2] = 50.0;
			
			TeleportEntity(g_iCustomWeapon_Entity2[client][1], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			
			g_iCustomWeapon_Entity2[client][2] = target;
			return;
		}
	}
	else {
		
		if( g_iCustomWeapon_Entity2[client][0] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][0]) && IsValidEntity(g_iCustomWeapon_Entity2[client][0]) )
			AcceptEntityInput(g_iCustomWeapon_Entity2[client][0], "Kill");
		if( g_iCustomWeapon_Entity2[client][1] > 0 && IsValidEdict(g_iCustomWeapon_Entity2[client][1]) && IsValidEntity(g_iCustomWeapon_Entity2[client][1]) )
			AcceptEntityInput(g_iCustomWeapon_Entity2[client][1], "Kill");
		
		g_iCustomWeapon_Entity2[client][0] = -1;
		g_iCustomWeapon_Entity2[client][1] = -1;
	}
	
	new ent = CreateEntityByName("info_particle_system");
	if( GetClientTeam(client) == CS_TEAM_T ) {
		DispatchKeyValue(ent, "effect_name", "medicgun_beam_red");
	}
	else {
		DispatchKeyValue(ent, "effect_name", "medicgun_beam_blue");
	}
	
	DispatchSpawn(ent);
	
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	DispatchKeyValue(ent, "classname", ParentName);
	DispatchKeyValue(ent, "start_active", "1");
	
	Format(ParentName, sizeof(ParentName), "ctf_link_1_%i%i%i", client, target, GetRandomInt(11111, 99999) );
	
	new ent2 = CreateEntityByName("env_sprite");
	DispatchSpawn(ent2);
	
	DispatchKeyValue(ent2, "targetname", ParentName);
	
	DispatchKeyValue(ent, "cpoint1", ParentName);
	TeleportEntity(ent2, vecTarget, NULL_VECTOR, NULL_VECTOR);
	Format(ParentName, sizeof(ParentName), "ctf_link_2_%i%i%i", client, target, GetRandomInt(11111, 99999) );
	DispatchKeyValue(target, "targetname", ParentName);
	SetVariantString(ParentName);
	AcceptEntityInput(ent2, "SetParent");
	
	Format(ParentName, sizeof(ParentName), "ctf_link_3_%i%i%i", client, target, GetRandomInt(11111, 99999) );
	DispatchKeyValue(client, "targetname", ParentName);
	SetVariantString(ParentName);
	AcceptEntityInput(ent, "SetParent");
	
	vecOrigin[0] = 0.0;
	vecOrigin[1] = 0.0;
	vecOrigin[2] = 50.0;
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent2, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent);
	
	g_iCustomWeapon_Entity2[client][0] = ent;
	g_iCustomWeapon_Entity2[client][1] = ent2;
	
	CTF_WEAPON_MEDIC_link(client, target);
}

// ------------------------------------------------------------------------------------------------------------------
//		Custom Weapon - FLAME THROWER
//
public CTF_WEAPON_FLAME_Attack_1(client) {
	if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
		
		if( g_fCustomWeapon_NextShoot[client][2] < GetGameTime() ) {
			CTF_WEAPON_FLAME_Reload(client);
		}
	}
	else {
		
		CTF_WEAPON_FLAME_Fire(client, false);
		g_iCustomWeapon_Ammo[client][0]--;
		
		g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 0.075);
		g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.075);
		
		if( g_iCustomWeapon_Ammo[client][0] <= 0 ) {
			
			CTF_WEAPON_FLAME_Reload(client);
		}
	}
}
public CTF_WEAPON_FLAME_Reload(client) {
	if( (g_fCustomWeapon_NextShoot[client][0]) < GetGameTime() ) {
		
		if( g_iCustomWeapon_Ammo[client][0] < 100 && g_iCustomWeapon_Ammo[client][1] > 1) {
			
			CreateTimer(1.5, CTF_WEAPON_FLAME_Reload_Task, client);
			
			CTF_WEAPON_FLAME_Fire(client, true);
			g_fCustomWeapon_NextShoot[client][0] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][1] = (GetGameTime() + 1.5);
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 1.5);
		}
	}
}
public Action:CTF_WEAPON_FLAME_Reload_Task(Handle:timer, any:client) {
	
	if( g_iCustomWeapon_Ammo[client][0] < 100 && g_iCustomWeapon_Ammo[client][1] > 1) {
		if( (g_fCustomWeapon_NextShoot[client][2]-0.2) < GetGameTime() ) {
			
			g_iCustomWeapon_Ammo[client][0] = 100;
			g_iCustomWeapon_Ammo[client][1]--;
			
			g_fCustomWeapon_NextShoot[client][2] = (GetGameTime() + 0.6);
		}
	}
}
public CTF_WEAPON_FLAME_Fire(client, shutdown) {
	
	if( GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 ) {
		return;
	}
	
	if( !shutdown ) {
		new Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3];
		
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client, vecAngles);
		
		new Float:rad = degrees_to_radians(vecAngles[1]);
		
		vecOrigin[0] = (vecOrigin[0] - (0.0 * Sine(rad))   + (50.0 * Cosine(rad)) );
		vecOrigin[1] = (vecOrigin[1] + (0.0 * Cosine(rad)) + (50.0 * Sine(rad)) );
		vecOrigin[2] = (vecOrigin[2] + 5.0);
		
		new String:classname[128];
		Format(classname, sizeof(classname), "ctf_flame_%i", client);
		
		new ent = CreateEntityByName("flashbang_projectile");
		
		DispatchKeyValue(ent, "classname", classname);
		DispatchKeyValue(ent, "solid", "0");
		DispatchSpawn(ent);
		ActivateEntity(ent);
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.2);
		
		new Float:fMins[3] = {-15.0, -15.0, -15.0};
		new Float:fMaxs[3] = {15.0, 15.0, 15.0};
		
		SetEntPropVector( ent, Prop_Send, "m_vecMins", fMins);
		SetEntPropVector( ent, Prop_Send, "m_vecMaxs", fMaxs);
		
		SetEntityMoveType(ent, MOVETYPE_FLY);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
		SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
		
		GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vecVelocity, 800.0);
		
		TeleportEntity(ent, vecOrigin, vecAngles, vecVelocity);
		Colorize(ent, 0, 0, 0, 0);
		
		SheduleEntityInput(ent, 0.3, "Kill");
		AttachParticle(ent, "fire_small_03", 0.40); // fire_medium_02 - fire_small_0£
		
		g_flCustomWeapon_Entity3[ent] = (GetGameTime() + 0.1);
		SDKHook(ent, SDKHook_Touch, CTF_WEAPON_FLAME_TOUCH);
		SDKHook(ent, SDKHook_ShouldCollide, ShouldCollide);
	}
	return;
}
public CTF_WEAPON_FLAME_TOUCH(rocket, entity) {
	
	if( !IsValidClient(entity) || !IsValidEdict(rocket) ) {
		return;
	}
	
	if( GetClientTeam( GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity") ) != GetClientTeam(entity) ) {
		IgniteEntity(entity, 5.0);
		g_fBurning[entity] = (GetGameTime() + 5.0);
		g_iBurning[entity] = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	}
	DealDamage(entity, GetRandomInt(8, 12), GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"), DMG_BURN);
	
	AcceptEntityInput(rocket, "Kill");
	SDKUnhook(entity, SDKHook_Touch, CTF_WEAPON_FLAME_TOUCH);
}