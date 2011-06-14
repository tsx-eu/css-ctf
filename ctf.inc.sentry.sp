#if defined _ctf_sentry_included
#endinput
#endif
#define _ctf_sentry_included

#include "ctf.sp"
#include "ctf.inc.const.sp"
#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"
#include "ctf.inc.sentry.sp"
#include "ctf.inc.grenades.sp"

public CTF_ENGINEER_DETALL(client) {
	if( IsValidSentry(g_iBuild[client][build_sentry]) ) {
		
		g_flBuildHealth[client][ build_sentry ] = 0.0;
		
		new Float:vecStart[3];
		GetEntPropVector(g_iBuild[client][build_sentry], Prop_Send, "m_vecOrigin", vecStart);
		
		ExplosionDamage(vecStart, 200.0, 200.0, client);
		DealDamage(g_iBuild[client][build_sentry], 10000, client);
	}
	
	if( IsValidTeleporter(g_iBuild[client][build_teleporter_in]) ) {
		
		g_flBuildHealth[client][build_teleporter_in] = 0.0;
		
		new Float:vecStart[3];
		GetEntPropVector(g_iBuild[client][build_teleporter_in], Prop_Send, "m_vecOrigin", vecStart);
		
		ExplosionDamage(vecStart, 200.0, 200.0, client);
		DealDamage(g_iBuild[client][build_teleporter_in], 10000, client);
	}
	
	if( IsValidTeleporter(g_iBuild[client][build_teleporter_out]) ) {
		
		g_flBuildHealth[client][build_teleporter_out] = 0.0;
		
		new Float:vecStart[3];
		GetEntPropVector(g_iBuild[client][build_teleporter_out], Prop_Send, "m_vecOrigin", vecStart);
		
		ExplosionDamage(vecStart, 200.0, 200.0, client);
		DealDamage(g_iBuild[client][build_teleporter_out], 10000, client);
	}
}
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
public bool:IsValidTeleporter(ent) {
	if( ent <= 0 )
		return false;
	if( !IsValidEdict(ent) )
		return false;
	if( !IsValidEntity(ent) )
		return false;
	
	new String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	
	if( StrContains(classname, "ctf_tp_") == 0 )
		return true;
	
	return false;
}
public CTF_SG_GetBuildingOwner(ent, build_type) {
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( g_iBuild[i][build_type] == ent )
			return i;
	}
	
	return 0;
}
public CTF_SG_Build(client) {
	
	if( IsValidSentry(g_iBuild[client][build_sentry]) ) {
		return;
	}
	
	if( g_flMetal[client] < 150.0 ) {
		PrintToChat(client, "[CTF] Vous n'avez pas assez de metal!");
		return;
	}
	
	g_flMetal[client] -= 150.0;
	PrintToChat(client, "[CTF] Construction en cours...");
	
	new ent = CreateEntityByName("cycler");
	
	DispatchKeyValue(ent, "classname", "ctf_sentry");
	DispatchKeyValue(ent, "model", "models/buildables/sentry1.mdl");
	DispatchKeyValue(ent, "solid", "2");
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		DispatchKeyValue(ent, "Skin", "1");
	}
	
	DispatchSpawn(ent);
	//ActivateEntity(ent);
	
	SetEntityModel(ent, "models/buildables/sentry1.mdl");
	
	SetEntProp(ent, Prop_Data, "m_nSolidType", 2);
	
	//new Float:vecMins[3] = {-20.0, -10.0, 0.0}, Float:vecMaxs[3] = {20.0, 10.0, 60.0};
	//SetEntPropVector( ent, Prop_Send, "m_vecMins", vecMins);
	//SetEntPropVector( ent, Prop_Send, "m_vecMaxs", vecMaxs);
	
	SetEntProp( ent, Prop_Data, "m_takedamage", 1);
	SetEntProp( ent, Prop_Data, "m_iHealth", 1);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new Float:vecOrigin[3], Float:vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, vecAngles);
	
	vecOrigin[0] = (vecOrigin[0] + (45.0 * Cosine( degrees_to_radians(vecAngles[1]) ) ) );
	vecOrigin[1] = (vecOrigin[1] + (45.0 * Sine(  degrees_to_radians(vecAngles[1]) ) ) );
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		Colorize(ent, 0, 0, 255, 0);
	}
	else {
		Colorize(ent, 255, 0, 0, 0);
	}
	g_flSentryAngles[ent][0] = 0.5;
	g_flSentryAngles[ent][1] = 0.5;
	g_iSentryLevel[ent] = 0;
	
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	g_iBuild[client][build_sentry] = ent;
	g_flBuildHealth[ent][build_sentry] = 250.0;
	
	ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"0\"", ent);
	
	g_flBuildThink[ent][build_sentry] = GetGameTime() + (2.1);
	g_flBuildThink2[ent][build_sentry] = GetGameTime() + (2.1);
	
	g_flPlayerSpeed[client] = 0.0;
	
	CreateTimer(2.0, CTF_SG_BuildPost, client);
	
	SDKHook(ent, SDKHook_OnTakeDamage,	OnTakeDamage);
}
public Action:CTF_SG_BuildPost(Handle:timer, any:client) {
	
	if( !IsPlayerAlive(client) ) {
		
		new ent = g_iBuild[client][build_sentry];
		g_iBuild[client][build_sentry] = 0;
		
		ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"1\"", ent);
		SheduleEntityInput(ent, 0.5, "Kill");
		
		PrintToChat(client, "[CTF] La construction a ete interompue.");
		return;
	}
	g_iSentryLevel[ g_iBuild[client][build_sentry] ] = 1;
	
	g_flPlayerSpeed[client] = 300.0;
	
	PrintToChat(client, "[CTF] Votre tourelle a ete construite!");
}
public CTF_SG_FindTarget(client, ent) {
	
	if( g_iSentryAngles[ent][0] == 0 ) {
		g_flSentryAngles[ent][0] += SENTRY_VELOCITY;
		
		if( g_flSentryAngles[ent][0] >= (1.0-SENTRY_ANGLES) ) {
			g_iSentryAngles[ent][0] = 1;
			g_flSentryAngles[ent][0] = (1.0-SENTRY_ANGLES);
			
			new Float:vecOrigin[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
			EmitSoundFromOrigin("npc/turret_floor/retract.wav", vecOrigin);
		}
	}
	else {
		g_flSentryAngles[ent][0] -= SENTRY_VELOCITY;
		
		if( g_flSentryAngles[ent][0] <= SENTRY_ANGLES ) {
			g_iSentryAngles[ent][0] = 0;
			g_flSentryAngles[ent][0] = SENTRY_ANGLES;
			
			new Float:vecOrigin[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
			EmitSoundFromOrigin("npc/turret_floor/retract.wav", vecOrigin);
		}
	}
	
	g_flSentryAngles[ent][1] = 0.500;
	
	new minimapoffset = FindSendPropOffs("CAI_BaseNPC", "m_flPoseParameter");
	SetEntDataFloat(ent, minimapoffset+0, g_flSentryAngles[ent][1], true);
	SetEntDataFloat(ent, minimapoffset+4, g_flSentryAngles[ent][0], true);
	
	for(new target=1; target<=GetMaxClients(); target++) {
		if( !IsValidClient(target) )
			continue;
		if( !IsPlayerAlive(target) )
			continue;
		if( GetClientTeam(client) == GetClientTeam(target) )
			continue;
		
		if( ClientViews_LeftRight(ent, target, 1000.0, 0.25, g_flSentryAngles[ent][0]) ) {
			return target;
		}
	}
	
	return 0;
}
public CTF_SG_Think(client, ent) {
	
	if( g_flBuildThink2[ent][build_sentry] > GetGameTime() )
		return;
	if( !IsValidSentry(g_iBuild[client][build_sentry]) )
		return;
	if( g_flBuildHealth[ent][build_sentry] <= 0 )
		return;
	
	new target = g_iSentryTarget[ent];
	
	if( target == 0 || !IsValidClient(target) ) {
		
		target = CTF_SG_FindTarget(client, ent);
		
		if( IsValidClient(target) ) {
			g_iSentryTarget[ent] = target;
			g_flBuildThink[ent][build_sentry] = (GetGameTime() + 0.15);
			
			new Float:vecOrigin[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
			EmitSoundFromOrigin("npc/turret_floor/deploy.wav", vecOrigin);
		}
	}
	
	if( target > 0 && IsValidClient(target) ) {
		
		if( CTF_SG_AimToTarget(client, ent, target) ) {
			
			new minimapoffset = FindSendPropOffs("CAI_BaseNPC", "m_flPoseParameter");
			SetEntDataFloat(ent, minimapoffset+0, g_flSentryAngles[ent][1], true);
			SetEntDataFloat(ent, minimapoffset+4, g_flSentryAngles[ent][0], true);
			
			CTF_SG_Shoot(client, ent, target);
		}
		else {
			g_iSentryTarget[ent] = 0;
		}
	}
	else {
		g_iSentryTarget[ent] = 0;
	}
}
public bool:CTF_SG_AimToTarget(client, ent, target) {
	
	if( !IsValidClient(target) )
		return false;
	if( !IsPlayerAlive(target) )
		return false;
	
	
	new Float:fAngle1 = SENTRY_ANGLES;
	
	while( fAngle1 < (1.0-SENTRY_ANGLES) ) {
		
		fAngle1 += SENTRY_VELOCITY;
		
		if( !ClientViews_LeftRight(ent, target, 1000.0, SENTRY_PRECI, fAngle1) ) {
			continue;
		}
		else {
			
			//
			// Initialisation des variables
			// vecStart = coordonnée de la tourelle
			// vecEnd = coordonnée du joueur
			// vecResult = Vecteur directeur
			// vecAngles Angle résultant la direction correcte de la tourelle vers le joueur.
			new Float:vecStart[3], Float:vecEnd[3], Float:vecResult[3], Float:vecAngles[3];
			
			// on défini les coordonnées de la tourelle
			// +40 pour avoir la partie supérieur
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecStart);
			vecStart[2] += 40.0;
			
			// On défini les coordonnées du joueur
			GetClientEyePosition(target, vecEnd);
			
			// On converti les point en vecteur
			// vecResult[x] = vecStart[x] - vecEnd[x]
			MakeVectorFromPoints(vecStart, vecEnd, vecResult);
			// On transforme le vecteur en angle
			GetVectorAngles(vecResult, vecAngles);
			
			// On obtiens alors différent angle pour le pitch (haut-bas)
			// de 0 à 50 ... et de 310 à 360 
			// Les autres, on les utilises pas, hors de portée.
			
			new Float:fAngle2;
			if( vecAngles[0] >= 0.0 && vecAngles[0] <= 50.0 ) {
				// de 0 à 50...
				fAngle2 = 0.5 - ( vecAngles[0] / 100.0 );
				
			}
			else if( vecAngles[0] >= 310.0 && vecAngles[0] <= 360.0 ) {
				// de 310 à 360
				vecAngles[0] = (360.0 - vecAngles[0]);
				fAngle2 = 0.5 + ( vecAngles[0] / 100.0 );
			}
			else {
				// Et bien nous sommes hors de portée
				// pwned la tourelle
				continue;
			}
			
			
			g_flSentryAngles[ent][0] = fAngle1;
			g_flSentryAngles[ent][1] = fAngle2;
			g_iSentryAngles[ent][0] = 0;
			
			return true;
		}
	}
	
	return false;
}

public bool:CTF_SG_Shoot(client, ent, target) {
	
	if( g_iSentryLevel[ent] == 0 )
		return false;
	
	if( g_flBuildThink[ent][build_sentry] > GetGameTime() )
		return false;
	
	if( g_iSentryLevel[ent] == 1 ) {
		g_flBuildThink[ent][build_sentry] = (GetGameTime() + GetRandomFloat(0.15, 0.25) );
	}
	else if( g_iSentryLevel[ent] == 2 ) {
		g_flBuildThink[ent][build_sentry] = (GetGameTime() + GetRandomFloat(0.05, 0.15) );
	}
	
	new Float:x, Float:y, Float:z;
	
	if( g_iSentryLevel[ent] == 1 ) {
		x = 30.0;
		y = 4.0;
		z = 0.0;
	}
	else if( g_iSentryLevel[ent] == 2 ) {
		x = 35.0;
		
		if( GetRandomInt(0, 1) )
			y = 16.0;
		else
		y = -16.0;
		
		z = 10.0;
	}
	
	new Float:vecStart[3], Float:vecEnd[3], Float:vecResult[3], Float:vecAngles[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecStart);
	GetClientEyePosition(target, vecEnd);
	
	vecStart[2] += 34.0;
	
	MakeVectorFromPoints(vecStart, vecEnd, vecResult);
	GetVectorAngles(vecResult, vecAngles);
	
	new Float:yaw = degrees_to_radians( vecAngles[1] );
	new Float:fAngle2 = 0.0;
	
	// ------ Pitch --- H4X
	if( vecAngles[0] >= 0.0 && vecAngles[0] <= 50.0 ) {
		fAngle2 = 0.5 + ( vecAngles[0] / 100.0 );
		
		x -= 5.0 * fAngle2;
		z -= 5.0 * fAngle2;
	}
	else if( vecAngles[0] >= 310.0 && vecAngles[0] <= 360.0 ) {
		vecAngles[0] = (360.0 - vecAngles[0]);
		fAngle2 = 0.5 + ( vecAngles[0] / 100.0 );
		
		x -= 5.0 * fAngle2;
		z += 5.0 * fAngle2;
	}
	// ------ Yaw ---
	vecStart[0] = vecStart[0] + ( x*Cosine(yaw) ) - ( y*Sine(yaw) );
	vecStart[1] = vecStart[1] + ( x*Sine(yaw) ) + ( y*Cosine(yaw) );
	vecStart[2] = vecStart[2] + z;
	
	vecAngles[0] -= 180.0;
	
	TE_SetupMuzzleFlash(vecStart, vecAngles, 1.0, 1);
	TE_SendToAll();
	
	DealDamage(target, GetRandomInt(6, 10), client, DMG_BULLET, "ctf_sentry");
	
	new String:sound[128];
	Format(sound, sizeof(sound), "npc/turret_floor/shoot%i.wav", GetRandomInt(1, 3));
	EmitSoundFromOrigin(sound, vecStart);
	
	
	return true;
	
}
// ---------------------------------------------------------------------------------------------------------------------
//				BUILDING:
//					TELEPORTEUR

public CTF_TP_Build(client, build_teleporter) {
	
	if( IsValidTeleporter(g_iBuild[client][build_teleporter]) ) {
		return;
	}
	
	if( g_flMetal[client] < 120.0 ) {
		PrintToChat(client, "[CTF] Vous n'avez pas assez de metal!");
		return;
	}
	
	g_flMetal[client] -= 120.0;
	PrintToChat(client, "[CTF] Construction en cours...");
	
	new ent = CreateEntityByName("cycler");
	new Float:vecMins[3] = {-8.0, -32.0, 0.0};
	new Float:vecMaxs[3] = {8.0, 32.0, 12.0};
	
	if( build_teleporter == build_teleporter_in ) {
		DispatchKeyValue(ent, "classname", "ctf_tp_in");
	}
	else {
		DispatchKeyValue(ent, "classname", "ctf_tp_out");
	}
	DispatchKeyValue(ent, "model", "models/buildables/teleporter_light.mdl");
	DispatchKeyValue(ent, "solid", "2");
	//DispatchKeyValue(ent, "spawnflags", "1");
	
	DispatchKeyValueVector(ent, "mins", vecMins);
	DispatchKeyValueVector(ent, "maxs", vecMaxs);
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		DispatchKeyValue(ent, "Skin", "1");
	}
	
	DispatchSpawn(ent);
	//ActivateEntity(ent);
	
	SetEntityModel(ent, "models/buildables/teleporter_light.mdl");
	
	SetEntProp( ent, Prop_Data, "m_takedamage", 1);
	SetEntProp( ent, Prop_Data, "m_iHealth", 1);
	
	new Float:vecOrigin[3], Float:vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, vecAngles);
	
	vecOrigin[0] = (vecOrigin[0] + (45.0 * Cosine( degrees_to_radians(vecAngles[1]) ) ) );
	vecOrigin[1] = (vecOrigin[1] + (45.0 * Sine(  degrees_to_radians(vecAngles[1]) ) ) );
	
	Colorize(ent, 0, 0, 0, 255);
	
	vecAngles[2] = 90.0;
	
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	g_iBuild[client][build_teleporter] = ent;
	g_flBuildHealth[ent][build_teleporter] = 100.0;
	
	ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"0\"", ent);
	
	g_flBuildThink[ent][build_teleporter] = GetGameTime() + (2.0);
	g_flBuildThink2[ent][build_teleporter] = GetGameTime() + (2.0);
	
	g_flPlayerSpeed[client] = 0.0;
	
	if( build_teleporter == build_teleporter_in ) {
		CreateTimer(2.0, CTF_TP_BuildPost, client);
	}
	else {
		CreateTimer(2.0, CTF_TP_BuildPost2, client);
	}
	g_flBuildThink[ ent ][build_teleporter] = -1.0;
	
	Entity_SetMinSize(ent, vecMins);
	Entity_SetMaxSize(ent, vecMaxs);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	
	SDKHook(ent, SDKHook_OnTakeDamage,	OnTakeDamage);
	SDKHook(ent, SDKHook_ShouldCollide, ShouldCollide);
	
}
public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:result)
{
	result = false;
	return false;
}
public Action:CTF_TP_BuildPost(Handle:timer, any:client) {
	
	if( !IsPlayerAlive(client) ) {
		
		new ent = g_iBuild[client][build_teleporter_in];
		g_iBuild[client][build_sentry] = 0;
		
		ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"1\"", ent);
		SheduleEntityInput(ent, 0.5, "Kill");
		
		PrintToChat(client, "[CTF] La construction a ete interompue.");
		return;
	}
	g_flPlayerSpeed[client] = 300.0;
	
	PrintToChat(client, "[CTF] Votre teleporteur a ete construit!");
}
public Action:CTF_TP_BuildPost2(Handle:timer, any:client) {
	
	if( !IsPlayerAlive(client) ) {
		
		new ent = g_iBuild[client][build_teleporter_out];
		g_iBuild[client][build_sentry] = 0;
		
		ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"1\"", ent);
		SheduleEntityInput(ent, 0.5, "Kill");
		
		PrintToChat(client, "[CTF] La construction a ete interompue.");
		return;
	}
	g_flPlayerSpeed[client] = 300.0;
	
	PrintToChat(client, "[CTF] Votre teleporteur a ete construit!");
}
public CTF_TP_Links(client) {
	
	new in = g_iBuild[client][build_teleporter_in];
	new out = g_iBuild[client][build_teleporter_out];
	new Float:vecAngles[3];
	
	if( IsValidTeleporter(in) && IsValidTeleporter(out) ) {
		
		if( g_flBuildThink[ in ][build_teleporter_in] <= 0.0 && g_flBuildThink[ out ][build_teleporter_out] <= 0.0 ) {
			
			GetEntPropVector(in, Prop_Send, "m_angRotation", vecAngles);
			vecAngles[1] += 90.0;
			vecAngles[2] = 0.0;
			TeleportEntity(in, NULL_VECTOR, vecAngles, NULL_VECTOR);
			SetVariantString("1");
			AcceptEntityInput(in, "SetSequence");
			
			GetEntPropVector(out, Prop_Send, "m_angRotation", vecAngles);
			vecAngles[1] += 90.0;
			vecAngles[2] = 0.0;
			TeleportEntity(out, NULL_VECTOR, vecAngles, NULL_VECTOR);
			SetVariantString("1");
			AcceptEntityInput(out, "SetSequence");
			
			if( GetClientTeam(client) == CS_TEAM_CT ) {
				AttachParticle(in, "teleporter_blue_entrance_level2", -1.0);
				AttachParticle(out, "teleporter_blue_exit_level2", -1.0);
			}
			else {
				AttachParticle(in, "teleporter_red_entrance_level2", -1.0);
				AttachParticle(out, "teleporter_red_exit_level2", -1.0);
			}
			g_flBuildThink[ in ][build_teleporter_in] = 1.0;
			g_flBuildThink[ out][build_teleporter_out] = 1.0;
			
			
		}
		if( g_flBuildThink2[ in ][build_teleporter_in] <= GetGameTime() && g_flBuildThink2[ in ][build_teleporter_in] >= 0.0) {
			
			if( GetClientTeam(client) == CS_TEAM_CT ) {
				AttachParticle(in, "teleporter_blue_charged_level3", -1.0);
			}
			else {
				AttachParticle(in, "teleporter_red_charged_level3", -1.0);
			}
			g_flBuildThink2[ in ][build_teleporter_in] = -1.0;
		}
	}
	else if( g_flBuildThink[ in ][build_teleporter_in] >= 0.0 && g_flBuildThink[ out][build_teleporter_out] >= 0.0 ) {
		
		if( IsValidTeleporter(in) ) {
			
			GetEntPropVector(in, Prop_Send, "m_angRotation", vecAngles);
			vecAngles[1] -= 90.0;
			vecAngles[2] = 90.0;
			TeleportEntity(in, NULL_VECTOR, vecAngles, NULL_VECTOR);
			SetVariantString("0");
			AcceptEntityInput(in, "SetSequence");
			
			for(new i=1; i<=2048; i++) {
				if( !IsValidEdict(i) )
					continue;
				if( !IsValidEntity(i) )
					continue;
				
				if( Entity_GetParent(i) == in ) {
					AcceptEntityInput(i, "Kill");
				}
			}
			
			g_flBuildThink[ in ][build_teleporter_in] = -1.0;
			g_flBuildThink2[ in ][build_teleporter_in] = 1.0;
			
		}
		
		if( IsValidTeleporter(out) ) {
			
			GetEntPropVector(out, Prop_Send, "m_angRotation", vecAngles);
			vecAngles[1] -= 90.0;
			vecAngles[2] = 90.0;
			TeleportEntity(out, NULL_VECTOR, vecAngles, NULL_VECTOR);
			SetVariantString("0");
			AcceptEntityInput(out, "SetSequence");
			
			for(new i=1; i<=2048; i++) {
				if( !IsValidEdict(i) )
					continue;
				if( !IsValidEntity(i) )
					continue;
				
				if( Entity_GetParent(i) == out ) {
					AcceptEntityInput(i, "Kill");
				}
			}
			
			g_flBuildThink[ out ][build_teleporter_out] = -1.0;
			g_flBuildThink2[ out ][build_teleporter_out] = 1.0;
		}
	}
}
public CTF_TP_ACTION(client) {
	
	new in, out;
	
	new Float:vecOrigin[3], Float:vecOrigin2[3], Float:vecVelocity[3];
	
	for(new client2=1; client2<=GetMaxClients(); client2++) {
		if( !IsValidClient(client2) )
			continue;
		if( GetClientTeam(client) != GetClientTeam(client2) )
			continue;
		
		in = g_iBuild[client2][build_teleporter_in];
		out = g_iBuild[client2][build_teleporter_out];
		
		if( IsValidTeleporter(in) && IsValidTeleporter(out) ) {
			
			if( g_flBuildThink2[ in ][build_teleporter_in] <= 0.0 ) {
				
				GetClientAbsOrigin(client, vecOrigin);
				GetEntPropVector(in, Prop_Send, "m_vecOrigin", vecOrigin2);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
				
				if( GetVectorDistance(vecOrigin, vecOrigin2) <= 20.0 && GetVectorLength(vecVelocity) <= 50.0 ) {
					
					new iFlagType = -1;
					for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
						if( g_iFlags_Carrier[Flag_Type] == client ) {
							iFlagType = Flag_Type;
							break;
						}
					}
					
					if( iFlagType != -1 )
						continue;
					
					if( GetClientTeam(client) == CS_TEAM_CT ) {
						ShowParticle(vecOrigin2, "teleportedin_blue", 2.0);
						AttachParticle(out, "teleported_blue", 0.1);
					}
					else {
						ShowParticle(vecOrigin2, "teleportedin_red", 2.0);
						AttachParticle(out, "teleported_red", 0.1);
					}
					
					ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"1\"", client);
					g_fRestoreSpeed[client][0] = (GetGameTime() + 0.5);
					if( g_fRestoreSpeed[client][1] < 0.01 ) {
						
						g_fRestoreSpeed[client][1] = g_flPlayerSpeed[client];
					}
					g_flPlayerSpeed[client] = 0.0;
					
					new Handle:dp;
					CreateDataTimer(0.5, CTF_TP_ACTION_POST, dp);
					WritePackCell(dp, client);
					WritePackCell(dp, client2);
					
					g_flBuildThink2[ in ][build_teleporter_in] = (GetGameTime()+15.0);
					for(new i=1; i<=2048; i++) {
						if( !IsValidEdict(i) )
							continue;
						if( !IsValidEntity(i) )
							continue;
						
						if( Entity_GetParent(i) == in ) {
							AcceptEntityInput(i, "Kill");
						}
					}
					if( GetClientTeam(client) == CS_TEAM_CT ) {
						AttachParticle(in, "teleporter_blue_entrance_level2", -1.0);
					}
					else {
						AttachParticle(in, "teleporter_red_entrance_level2", -1.0);
					}
					break;
				}
			}
		}
	}
}

public Action:CTF_TP_ACTION_POST(Handle:timer, Handle:dp) {
	
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new client2 = ReadPackCell(dp);
	new in = g_iBuild[client2][build_teleporter_in];
	new out = g_iBuild[client2][build_teleporter_out];
	
	ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"0\"", client);
	
	if( IsValidTeleporter(in) && IsValidTeleporter(out) ) {
		
		new Float:vecOrigin[3];
		
		GetEntPropVector(out, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[2] += 12.0;
		
		TeleportEntity(client, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}
