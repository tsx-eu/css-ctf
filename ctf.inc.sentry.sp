#if defined _ctf_sentry_included
#endinput
#endif
#define _ctf_sentry_included

#include "ctf.sp"

public bool:IsValidSentry(ent) {
	if( ent <= 0 )
		return false;
	if( !IsValidEdict(ent) )
		return false;
	if( !IsValidEntity(ent) )
		return false;
	
	new String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	
	if( StrEqual(classname, "ctf_sentry") )
		return true;
	
	return false;
}
public CTF_SG_GetOwner(ent) {
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( g_iSentry[i] == ent )
			return i;
	}
	
	return 0;
}
public CTF_SG_Build(client) {
	
	if( IsValidSentry(g_iSentry[client]) ) {
		
		
		new Float:vecStart[3], Float:vecEnd[3];
		GetEntPropVector(g_iSentry[client], Prop_Send, "m_vecOrigin", vecStart);
		GetClientEyePosition(client, vecEnd);
		
		if( GetVectorDistance(vecStart, vecEnd) <= 100.0 ) {
			
		}
		else {
			
			g_flSentryHealth[g_iSentry[client]] = 0.0;
			
			ExplosionDamage(vecStart, 100.0, 400.0, client);
			DealDamage(g_iSentry[client], 1000, client);
			
			g_fUlti_Cooldown[client] = (GetGameTime() + 5.0);
			PrintToChat(client, "[CTF] Votre tourelle a ete detruite!");
		}
		return;
	}
	
	if( g_flMetal[client] < 150.0 ) {
		PrintToChat(client, "[CTF] Vous n'avez pas assez de metal!");
		return;
	}
	
	g_flMetal[client] -= 150.0;
	PrintToChat(client, "[CTF] Construction en cours...");
	
	new ent = CreateEntityByName("prop_dynamic");
	
	DispatchKeyValue(ent, "classname", "ctf_sentry");
	DispatchKeyValue(ent, "model", "models/combine_turrets/floor_turret.mdl");
	DispatchKeyValue(ent, "solid", "6");
	
	DispatchSpawn(ent);
	//ActivateEntity(ent);
	
	SetEntityModel(ent, "models/combine_turrets/floor_turret.mdl");
	
	new Float:vecMins[3] = {-20.0, -10.0, 0.0}, Float:vecMaxs[3] = {20.0, 10.0, 60.0};
	SetEntPropVector( ent, Prop_Send, "m_vecMins", vecMins);
	SetEntPropVector( ent, Prop_Send, "m_vecMaxs", vecMaxs);
	
	SetEntProp( ent, Prop_Data, "m_takedamage", 1);
	SetEntProp( ent, Prop_Data, "m_iHealth", 1);
	
	new Float:vecOrigin[3], Float:vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, vecAngles);
	
	vecOrigin[0] = (vecOrigin[0] + (45.0 * Cosine( degrees_to_radians(vecAngles[1]) ) ) );
	vecOrigin[1] = (vecOrigin[1] + (45.0 * Sine(  degrees_to_radians(vecAngles[1]) ) ) );
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		Colorize(ent, 0, 0, 255, 255);
	}
	else {
		Colorize(ent, 255, 0, 0, 255);
	}
	
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	g_iSentry[client] = ent;
	g_flSentryHealth[ent] = 250.0;
	
	ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"0\"", ent);
	
	g_flSentryThink[ent] = GetGameTime() + (2.1);
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityGravity(client, 0.0);
	
	CreateTimer(2.0, CTF_SG_BuildPost, client);
	
	SDKHook(ent, SDKHook_OnTakeDamage,	OnTakeDamage);
}
public Action:CTF_SG_BuildPost(Handle:timer, any:client) {
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.9);
	SetEntityGravity(client, 1.05);
	
	PrintToChat(client, "[CTF] Votre tourelle a ete construire!");
}
public CTF_SG_Think(client, ent) {
	
	if( g_flSentryThink[ent] > GetGameTime() )
		return;
	if( !IsValidSentry(g_iSentry[client]) )
		return;
	if( g_flSentryHealth[ent] <= 0 )
		return;
	
	g_flSentryThink[ent] = (GetGameTime() + GetRandomFloat(0.14, 0.26));
	
	new Float:vecStart[3], Float:vecEnd[3], Float:fViewAng[3], Float:fViewDir[3], Float:fTargetDir[3], Float:fDistance[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecStart);
	
	vecStart[2] += 55.0;
	
	GetEntPropVector(ent, Prop_Send, "m_angRotation", fViewAng);
	// Calculate view direction
	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
	
	new Float:fThreshold = (60.0 * PI/360.0);
	
	for(new target=1; target<=GetMaxClients(); target++) {
		if( !IsValidClient(target) )
			continue;
		if( !IsPlayerAlive(target) )
			continue;
		if( GetClientTeam(client) == GetClientTeam(target) )
			continue;
		
		if( ClientViews(ent, target, 1000.0, fThreshold) ) {
			
			GetClientEyePosition(target, vecEnd);
			vecEnd[2] -= 20.0;
			
			DealDamage(target, GetRandomInt(4, 8), client);
			
			if( GetClientTeam(client) == CS_TEAM_CT ) {
				TE_SetupBeamPoints(vecStart, vecEnd, g_cPhysicBeam, 0, 0, 0, 0.3, 2.0, 2.0, 0, 0.0, {50, 50, 250, 120}, 0);
				TE_SendToAll();
			}
			else {
				TE_SetupBeamPoints(vecStart, vecEnd, g_cPhysicBeam, 0, 0, 0, 0.3, 2.0, 2.0, 0, 0.0, {250, 50, 50, 120}, 0);
				TE_SendToAll();
			}
			
			
			fDistance[0] = vecEnd[0]-vecStart[0];
			fDistance[1] = vecEnd[1]-vecStart[1];
			fDistance[2] = 0.0;
			
			NormalizeVector(fDistance, fTargetDir);
			
			new Float:vecResult[3], Float:vecAngles[3];
			MakeVectorFromPoints(vecEnd, vecStart, vecResult);
			GetVectorAngles(vecResult, vecAngles);
			
			new Float:Angles = (180.0-(vecAngles[1]-fViewAng[1]));
			//if( Angles < 120.0 )
			//	Angles += 360.0;
			
			//PrintToChatAll("%.2f=(180.0-(%.2f-%.2f))", Angles, vecAngles[1], fViewAng[1]);
			
			
			
			new Float:vecPush[3];
			GetEntPropVector(target, Prop_Data, "m_vecVelocity", vecPush);
			ScaleVector(fTargetDir, 50.0);
			
			vecPush[0] += fTargetDir[0];
			vecPush[1] += fTargetDir[1];
			vecPush[2] += fTargetDir[2];
			
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, fTargetDir);
			break;
		}
	}
}

public Float:GetAngle (const Float:Pos1[3], const Float:Pos2[3]) {
	
	decl Float:Dir[3], Float:Angles[3];
	Dir[0] = Pos2[0] - Pos1[0];
	Dir[1] = Pos2[1] - Pos1[1];
	Dir[2] = Pos2[2] - Pos1[2];
	
	NormalizeVector(Dir, Dir);
	GetVectorAngles(Dir, Angles);
	
	return Angles[1];
} 
