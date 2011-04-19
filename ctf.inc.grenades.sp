#if defined _ctf_grenades_included
#endinput
#endif
#define _ctf_grenades_included

#include "ctf.sp"

public Action:Cmd_PlusGren1(client, args) {
	if( g_flPrimedTime[client] != -1.0 )
		return Plugin_Handled;
	
	if( g_iPlayerGrenadeAmount[client][0] <= 0 )
		return Plugin_Handled;
	
	g_iGrenadeType[client] = grenade_none;
	
	switch( g_iPlayerClass[client] ) {
		case class_scout: {
			g_iGrenadeType[client] = grenade_caltrop;
		}
		case class_sniper: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_soldier: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_demoman: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_medic: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_hwguy: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_pyro: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_spy: {
			g_iGrenadeType[client] = grenade_frag;
		}
		case class_engineer: {
			g_iGrenadeType[client] = grenade_frag;
		}
	}
	
	if( g_iGrenadeType[client] == grenade_none )
		return Plugin_Handled;
	
	g_iPlayerGrenadeAmount[client][0]--;
	g_flPrimedTime[client] = GetGameTime();
	
	EmitSoundToClient(client, "grenades/timer.wav");
	EmitSoundToAll("grenades/ax1.wav", client);
	
	return Plugin_Handled;
}
public Action:Cmd_PlusGren2(client, args) {
	if( g_flPrimedTime[client] != -1.0 )
		return Plugin_Handled;
	
	if( g_iPlayerGrenadeAmount[client][1] <= 0 )
		return Plugin_Handled;
	
	g_iGrenadeType[client] = grenade_none;
	
	switch( g_iPlayerClass[client] ) {
		case class_scout: {
			g_iGrenadeType[client] = grenade_concussion;
		}
		case class_sniper: {
			g_iGrenadeType[client] = grenade_none;
		}
		case class_soldier: {
			g_iGrenadeType[client] = grenade_nail;
		}
		case class_demoman: {
			g_iGrenadeType[client] = grenade_mirv;
		}
		case class_medic: {
			g_iGrenadeType[client] = grenade_concussion;
		}
		case class_hwguy: {
			g_iGrenadeType[client] = grenade_mirv;
		}
		case class_pyro: {
			g_iGrenadeType[client] = grenade_napalm;
		}
		case class_spy: {
			g_iGrenadeType[client] = grenade_gas;
		}
		case class_engineer: {
			g_iGrenadeType[client] = grenade_emp;
		}
	}
	
	if( g_iGrenadeType[client] == grenade_none )
		return Plugin_Handled;
	
	g_iPlayerGrenadeAmount[client][1]--;
	g_flPrimedTime[client] = GetGameTime();
	
	
	if( g_iGrenadeType[client] == grenade_emp ) {
		g_flPrimedTime[client] = GetGameTime() - 0.65;
	}
	
	EmitSoundToClient(client, "grenades/timer.wav");
	EmitSoundToAll("grenades/ax1.wav", client);
	
	return Plugin_Handled;
}


public Action:Cmd_MoinsGren(client, args) {
	
	switch( g_iGrenadeType[client ] ) {
		case grenade_none: {
			return Plugin_Handled;
		}
		case grenade_caltrop: {
			CTF_NADE_Throw_Caltrop(client);
		}
		case grenade_concussion: {
			CTF_NADE_Throw_Conc(client);
		}
		case grenade_frag: {
			CTF_NADE_Throw_Frag(client);
		}
		case grenade_nail: {
			CTF_NADE_Throw_Nail(client);
		}
		case grenade_mirv: {
			CTF_NADE_Throw_Mirv(client);
		}
		case grenade_napalm: {
			CTF_NADE_Throw_Napalm(client);
		}
		case grenade_gas: {
			CTF_NADE_Throw_Gas(client);
		}
		case grenade_emp: {
			CTF_NADE_Throw_EMP(client);
		}
	}
	
	return Plugin_Handled;
}
public CTF_NADE_Throw_Caltrop(client) {
	
	for(new i=0; i<5; i++) {
		new ent = CTF_NADE_BASE(client, "ctf_nade_caltrop");
		SetEntityModel(ent, "models/grenades/caltrop/caltrop.mdl");
		CTF_NADE_THROW(client, ent, grenade_caltrop);
		
		SDKHook(ent, SDKHook_Touch, CTF_NADE_CaptropTouch);
	}
	g_flPrimedTime[client] = -1.0;
	g_iGrenadeType[client] = grenade_none;
}
public CTF_NADE_CaptropTouch(ent, victim) {
	
	new attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	
	if( IsValidClient(victim) && attacker != victim && GetClientTeam(attacker) != GetClientTeam(victim) ) {
		DealDamage(victim, GetRandomInt(14, 18), attacker);
		
		g_fRestoreSpeed[victim][0] = (GetGameTime() + 2.0);
		if( g_fRestoreSpeed[victim][1] < 0.01 ) {
			g_fRestoreSpeed[victim][1] = GetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue");
		}
		SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 0.25);
		
		AcceptEntityInput(ent, "KillHierarchy");
	}
}
public CTF_NADE_Throw_Conc(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_conc");
	SetEntityModel(ent, "models/grenades/conc/conc.mdl");
	CTF_NADE_THROW(client, ent, grenade_concussion);
}
public CTF_NADE_Throw_Frag(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_frag");
	SetEntityModel(ent, "models/grenades/frag/frag.mdl");
	CTF_NADE_THROW(client, ent, grenade_frag);
}
public CTF_NADE_Throw_Nail(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_nail");
	SetEntityModel(ent, "models/grenades/nailgren/nailgren.mdl");
	CTF_NADE_THROW(client, ent, grenade_nail);
}
public CTF_NADE_Throw_Mirv(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_mirv");
	SetEntityModel(ent, "models/grenades/mirv/mirv.mdl");
	CTF_NADE_THROW(client, ent, grenade_mirv);
}
public CTF_NADE_Throw_Napalm(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_napalm");
	SetEntityModel(ent, "models/grenades/napalm/napalm.mdl");
	CTF_NADE_THROW(client, ent, grenade_napalm);
}
public CTF_NADE_Throw_Gas(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_gas");
	SetEntityModel(ent, "models/grenades/gas/gas.mdl");
	CTF_NADE_THROW(client, ent, grenade_gas);
}
public CTF_NADE_Throw_EMP(client) {
	
	new ent = CTF_NADE_BASE(client, "ctf_nade_emp");
	SetEntityModel(ent, "models/grenades/emp/emp.mdl");
	CTF_NADE_THROW(client, ent, grenade_emp);
}

public CTF_NADE_BASE(client, const String:classname[]) {
	
	new ent = CreateEntityByName("flashbang_projectile");
	
	DispatchKeyValue(ent, "classname", classname);
	
	ActivateEntity(ent);
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.4);
	SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE);
	
	return ent;
}
public CTF_NADE_THROW(client, ent, enum_grenade_type:nade_type ) {
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecPush[3];
	
	if( IsValidClient(client) ) {
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client,vecAngles);
		vecOrigin[2] -= 25.0;
	}
	else {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[2] += 10.0;
	}	
	
	
	if( nade_type == grenade_caltrop ) {
		vecPush[0] = GetRandomFloat(-100.0, 100.0);
		vecPush[1] = GetRandomFloat(-100.0, 100.0);
		vecPush[2] = GetRandomFloat(10.0, 50.0);
		
	}
	else if( nade_type == grenade_mirvlet ) {
		while( GetVectorLength(vecPush) < 300.0 ) {
			vecPush[0] = GetRandomFloat(-400.0, 400.0);
			vecPush[1] = GetRandomFloat(-400.0, 400.0);
			vecPush[2] = GetRandomFloat(100.0, 200.0);
		}
	}
	else {
		GetAngleVectors(vecAngles, vecPush, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vecPush, 800.0);
	}
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, vecPush);
	
	if( IsValidClient(client) ) {
		if( GetClientTeam(client) == CS_TEAM_T ) {
			MakeSmokeFollow(ent, 3.0, {250, 50, 50, 250});
		}
		else {
			MakeSmokeFollow(ent, 3.0, {50, 50, 250, 250});
		}
	}
	
	g_flPrimedTime[ent] = g_flPrimedTime[client];
	g_iGrenadeType[ent] = g_iGrenadeType[client];
	
	if( nade_type != grenade_caltrop  && nade_type != grenade_mirvlet ) {
		g_flPrimedTime[client] = -1.0;
		g_iGrenadeType[client] = grenade_none;
	}
	
	if( nade_type == grenade_mirvlet ) {
		g_flPrimedTime[ent] = GetGameTime() + GetRandomFloat(0.0, 0.5);
		g_iGrenadeType[ent] = nade_type;
	}
}
public CTF_NADE_EXPLODE(ent) {
	
	new client, entity;
	
	if( IsValidClient(ent) ) {
		client = ent;
		entity = -1;
	}
	else {
		client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		entity = ent;
	}
	
	new Float:vecOrigin[3];
	
	if( entity != -1 ) {
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	}
	else {
		GetClientEyePosition(client, vecOrigin);
	}
	vecOrigin[2] -= 25.0;
	
	switch( g_iGrenadeType[ent] ) {
		case grenade_caltrop: {
			CTF_NADE_EXPL_Caltrop(client, entity, ent, vecOrigin);
		}
		case grenade_concussion: {
			CTF_NADE_EXPL_Conc(client, entity, ent, vecOrigin);
		}
		case grenade_frag: {
			CTF_NADE_EXPL_Frag(client, entity, ent, vecOrigin);
		}
		case grenade_nail: {
			CTF_NADE_EXPL_Nail(client, entity, ent, vecOrigin);
		}
		case grenade_mirv: {
			CTF_NADE_EXPL_Mirv(client, entity, ent, vecOrigin);
		}
		case grenade_mirvlet: {
			CTF_NADE_EXPL_MirvLet(client, entity, ent, vecOrigin);
		}
		case grenade_napalm: {
			CTF_NADE_EXPL_Napalm(client, entity, ent, vecOrigin);
		}
		case grenade_gas: {
			CTF_NADE_EXPL_Gas(client, entity, ent, vecOrigin);
		}
		case grenade_emp: {
			CTF_NADE_EXPL_EMP(client, entity, ent, vecOrigin);
		}
	}
	
	g_flPrimedTime[ent] = -1.0;
	g_iGrenadeType[ent] = grenade_none;
}
public CTF_NADE_EXPL_Caltrop(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity == -1 ) {
		CTF_NADE_Throw_Caltrop(client);
	}
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 10.0, "KillHierarchy");
	}
}
public CTF_NADE_EXPL_Conc(client, entity, ent, Float:vecOrigin[3]) {
	
	if( IsValidEntity(entity) ) {
		MakeRadiusPush(vecOrigin, 800.0, 800.0);
		
	}
	else {
		
		new Float:vecOrigin2[3], Float:vecAngles[3], Float:vecVelocity[3];
		GetClientEyePosition(client, vecOrigin2);
		GetClientEyeAngles(client, vecAngles);
		Entity_GetAbsVelocity(client, vecVelocity);
		
		new Float:dist = GetVectorLength(vecVelocity) * 0.1;
		
		vecOrigin2[0] = (vecOrigin[0] - (dist * Cosine(degrees_to_radians(vecAngles[1]))) );
		vecOrigin2[1] = (vecOrigin[1] - (dist * Sine(degrees_to_radians(vecAngles[1]))) );
		vecOrigin2[2] = (vecOrigin[2] - ((dist*-1.5) * Sine(degrees_to_radians(vecAngles[0]))) );
		
		MakeRadiusPush(vecOrigin2, 800.0, 800.0);
	}
	vecOrigin[2] += 25.0;
	
	TE_SetupBeamRingPoint(vecOrigin, 1.0, 601.0, g_cShockWave, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 0.1, 600.0, g_cShockWave2, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 200}, 1, 0);
	TE_SendToAll();
	
	new String:sound[128];
	Format(sound, sizeof(sound), "grenades/conc%i.wav", GetRandomInt(1, 2));
	
	EmitSoundFromOrigin(sound, vecOrigin);
	EmitSoundFromOrigin(sound, vecOrigin);
	
	if( entity != -1 ) {
		
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
public CTF_NADE_EXPL_Frag(client, entity, ent, Float:vecOrigin[3]) {
	
	ExplosionDamage(vecOrigin, 100.0, 400.0, client);
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 250, 250);
	TE_SendToAll();
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	EmitSoundFromOrigin(sound, vecOrigin);
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
public CTF_NADE_EXPL_Nail(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity == -1 ) {
		CTF_NADE_Throw_Nail(client);
	}
	if( entity != -1 ) {
		
		vecOrigin[2] += 50.0;
		TeleportEntity(entity, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
		g_flNailData[entity][0] = 0.0;
		g_flNailData[entity][1] = (GetGameTime() + 0.1);
		
		CreateTimer(5.0, CTF_NADE_EXPL_Nail_Task, entity);
		SheduleEntityInput(entity, 5.1, "KillHierarchy");
	}
}
public Action:CTF_NADE_EXPL_Nail_Task(Handle:timer, any:entity) {
	
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new Float:vecOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	
	ExplosionDamage(vecOrigin, 100.0, 400.0, client);
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
}
public CTF_NADE_NAIL_Shoot(entity) {
	
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	g_flNailData[entity][0] += GetRandomFloat(4.0, 6.0);
	g_flNailData[entity][1] += GetRandomFloat(0.08, 0.12);
	
	vecAngles[1] = g_flNailData[entity][0];
	while( vecAngles[1] >= 360.0 ) {
		vecAngles[1] -= 360.0;
	}
	
	vecOrigin[0] = (vecOrigin[0] + (5.0 * Cosine( degrees_to_radians(vecAngles[1]) )) );
	vecOrigin[1] = (vecOrigin[1] + (5.0 * Sine( degrees_to_radians(vecAngles[1]))));
	
	new ent = CreateEntityByName("flashbang_projectile");
	
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetEntityModel(ent, "models/projectiles/nail/w_nail.mdl");
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SetEntityMoveType(ent, MOVETYPE_FLY);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE);
	
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecVelocity, 1200.0);
	
	TeleportEntity(ent, vecOrigin, vecAngles, vecVelocity);
	
	SDKHook(ent, SDKHook_Touch, CTF_NADE_NAIL_Shoot_TOUCH);
	
	EmitSoundToAll("grenades/nail_shoot.wav", ent);
}
public CTF_NADE_NAIL_Shoot_TOUCH(entity, touched) {
	
	if( IsValidClient(touched) ) {
		DealDamage(touched, GetRandomInt(14, 16), GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
	}
	
	AcceptEntityInput(entity, "KillHierarchy");
}
public CTF_NADE_EXPL_Mirv(client, entity, ent, Float:vecOrigin[3]) {
	
	ExplosionDamage(vecOrigin, 100.0, 400.0, client);
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	EmitSoundFromOrigin(sound, vecOrigin);
	
	for(new i=0; i<4; i++) {
		new ent2 = CTF_NADE_BASE(client, "ctf_nade_mirvlet");
		SetEntityModel(ent2, "models/grenades/mirv/mirvlet.mdl");
		
		if( entity != -1 ) {
			CTF_NADE_THROW(entity, ent2, grenade_mirvlet);
		}
		else {
			CTF_NADE_THROW(client, ent2, grenade_mirvlet);
		}
	}
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
public CTF_NADE_EXPL_MirvLet(client, entity, ent, Float:vecOrigin[3]) {
	
	ExplosionDamage(vecOrigin, 80.0, 200.0, client);
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	EmitSoundFromOrigin(sound, vecOrigin);
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
public CTF_NADE_EXPL_Napalm(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
public CTF_NADE_EXPL_Gas(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity == -1 ) {
		CTF_NADE_Throw_Gas(client);
	}
	
	if( entity != -1 ) {
		
		vecOrigin[2] += 30.0;
		
		new ent1 = CreateEntityByName("env_particlesmokegrenade");
		
		DispatchSpawn(ent1);
		ActivateEntity(ent1);
		
		SetEntProp(ent1, Prop_Send, "m_CurrentStage", 1); 
		SetEntPropEnt(ent1, Prop_Send, "m_hOwnerEntity", client);
		
		TeleportEntity(ent1, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
		new String:ParentName[128];
		Format(ParentName, sizeof(ParentName), "ctf_nade_%i%i%i", ent1, entity, GetRandomInt(11111, 99999) );
		DispatchKeyValue(entity, "targetname", ParentName);
		
		SetVariantString(ParentName);
		AcceptEntityInput(ent1, "SetParent");
		
		SheduleEntityInput(entity, 10.0, "KillHierarchy");
	}
}
public CTF_NADE_EXPL_EMP(client, entity, ent, Float:vecOrigin[3]) {
	
	EmitSoundFromOrigin("grenades/emp_explosion.wav", vecOrigin);
	EmitSoundFromOrigin("grenades/emp_explosion.wav", vecOrigin);
	
	CreateTimer(0.65, CTF_NADE_EXPL_EMP_Task, ent);
}
public Action:CTF_NADE_EXPL_EMP_Task(Handle:timer, any:ent) {
	
	new client, entity;
	
	if( IsValidClient(ent) ) {
		client = ent;
		entity = -1;
	}
	else {
		client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		entity = ent;
	}
	
	new Float:vecOrigin[3];
	
	if( entity != -1 ) {
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	}
	else {
		GetClientEyePosition(client, vecOrigin);
	}
	vecOrigin[2] -= 25.0;
	
	new Float:damage = 10.0;
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		new Float:vecOrigin2[3];
		GetClientEyePosition(i, vecOrigin2);
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) > 400.0 )
			continue;
		
		damage += float(g_iPlayerArmor[i]);
		
		TE_SetupExplosion(vecOrigin2, g_cExplode, 1.0, 0, 0, 40, 40);
		TE_SendToAll();
	}
	
	ExplosionDamage(vecOrigin, damage, 600.0, client);
	
	vecOrigin[2] += 25.0;
	
	TE_SetupBeamRingPoint(vecOrigin, 1.0, 601.0, g_cShockWave, 0, 0, 10, 0.20, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 0.1, 600.0, g_cPhysicBeam, 0, 0, 10, 0.20, 50.0, 0.0, {255, 200, 50, 200}, 1, 0);
	TE_SendToAll();
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"0\"", entity);
	}
}
