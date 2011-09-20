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
	
	if( !IsPlayerAlive(client) )
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
	
	if( !IsPlayerAlive(client) )
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
			g_iGrenadeType[client] = grenade_none;
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
			g_fRestoreSpeed[victim][1] = g_flPlayerSpeed[victim];
		}
		g_flPlayerSpeed[victim] = 100.0;
		
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
		
		new String:classname[64];
		GetEdictClassname(ent, classname, 63);
		
		if( StrContains(classname, "ctf_nade_") == 0 ) {
			client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
			entity = ent;
		}
		else {
			return;
		}
	}
	
	new Float:vecOrigin[3];
	
	if( entity != -1 ) {
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
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
		ConcExplode(client, entity, false);
	}
	else {
		ConcExplode(client, client, true);
	}
	vecOrigin[2] += 25.0;
	
	TE_SetupBeamRingPoint(vecOrigin, 1.0, 285.0, g_cShockWave, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 0.1, 288.0, g_cShockWave2, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 200}, 1, 0);
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
public ConcExplode(client, concId, bool:handHeld) {
	new Float:center[3];
	GetEntPropVector(concId, Prop_Send, "m_vecOrigin", center);
	
	for (new i=1; i<=GetMaxClients(); i++) {
		
		if( !IsValidClient(i) )
			continue;
		
		new Float:vecOrigin[3];
		GetClientAbsOrigin(i, vecOrigin);
		
		if( GetVectorDistance(vecOrigin, center) > 280.0 )
			continue;
		
		ConcPlayer(i, center, client, handHeld);
	}
}
public ConcPlayer(victim, Float:center[3], attacker, bool:hh) {
	
	if( victim != attacker ) {
		new Float:pSpd[3], Float:cPush[3], Float:pPos[3], Float:distance, Float:pointDist, Float:calcSpd, Float:baseSpd;
		
		GetClientAbsOrigin(victim, pPos);
		pPos[2] += 48.0;
		
		GetEntPropVector(victim, Prop_Data, "m_vecVelocity", pSpd);
		distance = GetVectorDistance(pPos, center);
		
		SubtractVectors(pPos, center, cPush);
		NormalizeVector(cPush, cPush);
		pointDist = FloatDiv(distance, 280.0);
		
		baseSpd = 650.0;
		
		if( 0.25 > pointDist ) {
			pointDist = 0.25;
		}
		
		calcSpd = baseSpd * pointDist;
		
		calcSpd = -1.0*Cosine( (calcSpd / baseSpd) * 3.141592 ) * ( baseSpd - (800.0 / 3.0) ) + ( baseSpd + (800.0 / 3.0) );
		
		if( GetClientTeam(victim) == GetClientTeam(attacker) ) {
			ScaleVector(cPush, (calcSpd*0.2));
		}
		else {
			ScaleVector(cPush, (calcSpd*0.8));
		}
		
		new bool:OnGround;
		if(GetEntityFlags(victim) & FL_ONGROUND) {
			OnGround = true;
		}
		else {
			OnGround = false;
		}
		if( (hh && victim != attacker) || !hh) {
			if( pSpd[2] < 0.0 && cPush[2] > 0.0 ) {
				pSpd[2] = 0.0;
			}
		}
		
		AddVectors(pSpd, cPush, pSpd);
		
		if(OnGround) {
			if(pSpd[2] < 800.0/3.0) {
				pSpd[2] = 800.0/3.0;
			}
		}
		
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, pSpd);
	}
	else {
		new Float:vecPlayerOrigin[3], Float:vecResult[3];
		GetClientAbsOrigin(victim, vecPlayerOrigin);
		
		new Float:vecDisplacement[3];
		vecDisplacement[0] = vecPlayerOrigin[0] - center[0];
		vecDisplacement[1] = vecPlayerOrigin[1] - center[1];
		vecDisplacement[2] = vecPlayerOrigin[2] - center[2];
		
		new Float:flDistance = GetVectorLength(vecDisplacement);
		
		if( hh && attacker == victim) {
			new Float:fLateral = 2.74;
			new Float:fVertical = 4.10;
			
			new Float:vecVelocity[3];
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vecVelocity);
			
			vecResult[0] = vecVelocity[0] * fLateral;
			vecResult[1] = vecVelocity[1] * fLateral;
			vecResult[2] = vecVelocity[2] * fVertical;
			
		}
		else {
			
			new Float:verticalDistance = vecDisplacement[2];
			vecDisplacement[2] = 0.0;
			new Float:horizontalDistance = GetVectorLength(vecDisplacement);
			
			vecDisplacement[0] /= horizontalDistance;
			vecDisplacement[1] /= horizontalDistance;
			vecDisplacement[2] /= horizontalDistance;
			
			vecDisplacement[0] *= (horizontalDistance * (8.4 - 0.015 * flDistance) );
			vecDisplacement[1] *= (horizontalDistance * (8.4 - 0.015 * flDistance) );
			vecDisplacement[2] = (verticalDistance * (12.6 - 0.0225 * flDistance) );
			
			vecResult[0] = vecDisplacement[0];
			vecResult[1] = vecDisplacement[1];
			vecResult[2] = vecDisplacement[2];		
		}
		
		new flags = GetEntityFlags(victim);
		if( flags & FL_ONGROUND ) {
			
			SetEntProp(victim, Prop_Data, "m_fFlags", flags&~FL_ONGROUND);
			SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", -1);
			
			vecPlayerOrigin[2] += 1.0;
			TeleportEntity(victim, vecPlayerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecResult);
		
	}
	
	new Float:vecAngles[3];
	vecAngles[0] = 50.0;
	vecAngles[1] = 50.0;
	vecAngles[2] = 50.0;
	
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", vecAngles);
	SetEntPropFloat(victim, Prop_Send, "m_flFlashDuration", 5.0);
	SetEntPropFloat(victim, Prop_Send, "m_flFlashMaxAlpha", 50.0);
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
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"1\"", entity);
	}
}
public CTF_NADE_EXPL_Nail(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity == -1 ) {
		CTF_NADE_Throw_Nail(client);
	}
	if( entity != -1 ) {
		
		SetEntityMoveType(ent, MOVETYPE_NONE);
		
		new Float:vecVelocity[3];
		vecOrigin[2] += 50.0;
		TeleportEntity(entity, vecOrigin, NULL_VECTOR, vecVelocity);
		
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
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecDest[3];
	
	new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	g_flNailData[entity][0] += GetRandomFloat(2.0, 4.0);
	g_flNailData[entity][1] = (GetGameTime() + GetRandomFloat(0.01, 0.02));
	
	vecAngles[1] = g_flNailData[entity][0];
	while( vecAngles[1] >= 360.0 ) {
		vecAngles[1] -= 360.0;
	}
	
	TeleportEntity(entity, NULL_VECTOR, vecAngles, NULL_VECTOR);
	
	new Float:old_angle = vecAngles[1];
	
	for(new i=1; i<=3; i++) {
		
		vecAngles[1] += 120.0;
		
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[0] = (vecOrigin[0] + (5.0 * Cosine( degrees_to_radians(vecAngles[1]) )) );
		vecOrigin[1] = (vecOrigin[1] + (5.0 * Sine( degrees_to_radians(vecAngles[1]))));
		
		TE_SetupMuzzleFlash(vecOrigin, vecAngles, 1.0, 1);
		TE_SendToAll();
		
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, FilterToOne, entity);
		if( !TR_DidHit(trace) ) {
			return;
		}
		
		new victim = TR_GetEntityIndex(trace);
		TR_GetEndPosition(vecDest, trace);
		
		CloseHandle(trace);
		
		if( IsValidClient(attacker) && GetClientTeam(attacker) == CS_TEAM_T ) {
			TE_SetupBeamPoints( vecOrigin, vecDest, g_cPhysicBeam, 0, 0, 0, 0.1, 3.0, 3.0, 1, 0.0, {250, 200, 200, 20}, 0);
		}
		else {
			TE_SetupBeamPoints( vecOrigin, vecDest, g_cPhysicBeam, 0, 0, 0, 0.1, 3.0, 3.0, 1, 0.0, {200, 200, 250, 20}, 0);
		}
		TE_SendToAll();
		
		if( IsValidClient(victim) ) {
			DealDamage(victim, GetRandomInt(4, 8), attacker);
		}
	}
	
	vecAngles[1] = old_angle;
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
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"1\"", entity);
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
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"1\"", entity);
	}
}
public CTF_NADE_EXPL_Napalm(client, entity, ent, Float:vecOrigin[3]) {
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"1\"", entity);
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
		
		g_iPlayerArmor[i] = RoundToCeil(float(g_iPlayerArmor[i]) * 0.5);
		
		TE_SetupExplosion(vecOrigin2, g_cExplode, 1.0, 0, 0, 25, 25);
		TE_SendToAll();
	}
	
	ExplosionDamage(vecOrigin, damage, 600.0, client);
	vecOrigin[2] += 25.0;
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 40, 40);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 1.0, 401.0, g_cShockWave, 0, 0, 20, 0.20, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 0.1, 400.0, g_cPhysicBeam, 0, 0, 10, 0.20, 50.0, 0.0, {255, 200, 50, 200}, 1, 0);
	TE_SendToAll();
	
	if( entity != -1 ) {
		SheduleEntityInput(entity, 0.25, "KillHierarchy");
		ServerCommand("sm_effect_fading \"%i\" \"0.25\" \"1\"", entity);
	}
}
