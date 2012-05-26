#if defined _ctf_functions_included
#endinput
#endif
#define _ctf_functions_included

#include "ctf.sp"
#include "ctf.inc.const.sp"
#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"
#include "ctf.inc.sentry.sp"
#include "ctf.inc.grenades.sp"

// ------------------------------------------------------------------------------------------------------------------
// 		CTF GLOBAL FUNCTIONS
//

// ------------------------------------------------------------------------------------------------------------------
//	Utilisé pour drop un drapeau à partir d'un joueur à sa mort.
//
stock SetClientSpeed(client, Float:speed) {
	speed = (speed / 240.0);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
	
	if( speed == 0.0 ) {
		speed = 0.0001;
	}
	SetEntityGravity(client, (1.0/speed) );
}
stock CTF_DropFlag(client, thrown=false) {
	new iFlagType = -1;
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		if( g_iFlags_Carrier[Flag_Type] == client ) {
			iFlagType = Flag_Type;
			g_iFlags_Carrier[Flag_Type] = 0;
			break;
		}
	}
	
	if( iFlagType == -1 )
		return;
	
	AcceptEntityInput(g_iFlags_Entity[iFlagType], "ClearParent");
	g_fLastDrop[client] = GetGameTime();
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecPush[3], Float:vecNull[3];
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	vecAngles[0] += 10.0;
	
	if( thrown ) {
		
		vecOrigin[0] = (vecOrigin[0] + (60.0 * Cosine( degrees_to_radians( vecAngles[1] ) ) ) );
		vecOrigin[1] = (vecOrigin[1] + (60.0 * Sine( degrees_to_radians( vecAngles[1] ) ) ) );
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		
		vecPush[0] = ( FLAG_SPEED * Cosine( degrees_to_radians(vecAngles[1]) ) );
		vecPush[1] = ( FLAG_SPEED * Sine( degrees_to_radians(vecAngles[1]) ) );
		vecPush[2] = ( (FLAG_SPEED/2.0) * Cosine( degrees_to_radians( vecAngles[0] ) ) );
	}
	else {
		
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		vecPush[2] = 20.0;
	}
	
	vecPush[2] += 50.0;
	
	SetEntProp(g_iFlags_Entity[iFlagType], Prop_Send, "m_fFlags", 0);
	SetEntProp(g_iFlags_Entity[iFlagType], Prop_Send, "m_flSimulationTime", 0);
	SetEntProp(g_iFlags_Entity[iFlagType], Prop_Send, "movecollide", 2);
	
	SetEntityMoveType(g_iFlags_Entity[iFlagType], MOVETYPE_FLYGRAVITY);
	SetEntProp(g_iFlags_Entity[iFlagType], Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntPropFloat(g_iFlags_Entity[iFlagType], Prop_Send, "m_flElasticity", 0.1);
	
	TeleportEntity(g_iFlags_Entity[iFlagType], vecOrigin, vecNull, vecPush);
	
	g_fFlags_Respawn[iFlagType] = (GetGameTime() + 45.0);
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		if( iFlagType == 1 ) {
			ClientCommand(i, "play \"DeadlyDesire/ctf/BlueFlagDropped.mp3\"");
		}
		else if( iFlagType == 0 ) {
			ClientCommand(i, "play \"DeadlyDesire/ctf/RedFlagDropped.mp3\"");
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
// Utilisé pour spawn/respawn un drapeau
//
public CTF_SpawnFlag(Flag_Type) {
	if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_flag", false) ) {
			AcceptEntityInput(g_iFlags_Entity[Flag_Type], "KillHierarchy");
		}
	}
	
	g_iFlags_Entity[Flag_Type] = 0;
	g_iFlags_Carrier[Flag_Type] = 0;
	g_fFlags_Respawn[Flag_Type] = -1.0;
	
	new ent1 = CreateEntityByName("flashbang_projectile");
	if( !IsValidEdict(ent1) )
		return;
	new ent3 = CreateEntityByName("light_dynamic");
	if( !IsValidEdict(ent3) )
		return;
	new ent4 = CreateEntityByName("env_spritetrail");
	if( !IsValidEdict(ent4) )
		return;
	
	//
	DispatchKeyValue(ent1, "classname", "ctf_flag");
	//
	//
	DispatchKeyValue(ent3, "brightness", "3");
	DispatchKeyValue(ent3, "distance", "128");
	//
	DispatchKeyValue(ent4, "lifetime", "3.0");
	DispatchKeyValue(ent4, "endwidth", "0.1");
	DispatchKeyValue(ent4, "startwidth", "5.0");
	DispatchKeyValue(ent4, "spritename", "materials/sprites/laserbeam.vmt");
	DispatchKeyValue(ent4, "renderamt", "255");
	DispatchKeyValue(ent4, "rendermode", "5");
	
	if( Flag_Type == 0 ) {
		DispatchKeyValue(ent1, "Skin", "0");
		DispatchKeyValue(ent3, "_light", "255 0 0");
		DispatchKeyValue(ent4, "rendercolor", "250 0 0");
	}
	else if( Flag_Type == 1 ) {
		DispatchKeyValue(ent1, "Skin", "1");
		DispatchKeyValue(ent3, "_light", "0 0 255");
		DispatchKeyValue(ent4, "rendercolor", "0 0 250");
	}
	else {
		DispatchKeyValue(ent1, "Skin", "2");
		DispatchKeyValue(ent4, "rendercolor", "10 10 10");
	}
	
	DispatchSpawn(ent1);
	DispatchSpawn(ent3);
	DispatchSpawn(ent4);
	
	SetEntityModel(ent1, "models/DeadlyDesire/ctf/flag.mdl");
	SetEntityMoveType(ent1, MOVETYPE_FLYGRAVITY);
	
	SetEntProp(ent1, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
//	SetEntProp(ent1, Prop_Data, "m_nSolidType", SOLID_NONE);
	SetEntProp(ent1, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
	
	SetEntPropFloat(ent1, Prop_Send, "m_flElasticity", 0.1);
	
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent1, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent3, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent4, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	
	g_iFlags_Entity[Flag_Type] = ent1;
	//
	//
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_parent_%i%i%i%i", ent1, ent3, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent1, "targetname", ParentName);	
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent3, "SetParent");
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent4, "SetParent");
}
// ------------------------------------------------------------------------------------------------------------------
//	Utilisé lorsqu'un joueur marche sur son capture point avec un drapeau ennemi. Augmente le score, et fait gagné l'équipe si besoin est.
//
public CTF_Score(client, Flag_Type, Reverse_Flag_Type) {
	
	g_iScore[Reverse_Flag_Type]++;
	
	CTF_SpawnFlag(Flag_Type);
	
	new String:szSound[128], String:szTeam[8];
	if( Reverse_Flag_Type == 0 ) {
		Format(szTeam, sizeof(szTeam), "Red");
		//CS_TerminateRound(5.0, CSRoundEnd_TerroristWin, true);
	}
	else {
		Format(szTeam, sizeof(szTeam), "Blue");
		//CS_TerminateRound(5.0, CSRoundEnd_CTWin, true);
	}
	
	Format(szSound, sizeof(szSound), "play \"DeadlyDesire/ctf/");
	
	PrintToChatAll("[CTF] %N capture le drapeau.", client);
	PrintToChatAll("[CTF] Scores: %i - %i", g_iScore[0], g_iScore[1]);
	
	SetClientFrags(client, (GetClientFrags(client)+10) );
	SetTeamScore( GetClientTeam(client), g_iScore[Reverse_Flag_Type]);
	// Si une équipe remporte la victoire:
	// --------------
	/*
	if( g_iScore[Flag_Type] == 0 && g_iScore[Reverse_Flag_Type] == 3 ) {
		for(new i=1; i<=GetMaxClients(); i++) {
			if( !IsValidClient(i) ) 
				continue;
			
			if( (GetClientTeam(i) == CS_TEAM_CT && g_iScore[0] == 3) || (GetClientTeam(i) == CS_TEAM_T && g_iScore[1] == 3) ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/HumiliatingDefeat.mp3\"");
			}
			else {
				ClientCommand(i, "play \"DeadlyDesire/ctf/FlawlessVictory.mp3\"");
			}
		}
		g_iScore[0] = 0;
		g_iScore[1] = 0;
		
		return;
	}
	if( g_iScore[Reverse_Flag_Type] == 3 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamWinsTheMatch.mp3\"", szSound, szTeam);
		for(new i=1; i<=GetMaxClients(); i++) {
			if( !IsValidClient(i) ) 
				continue;
			ClientCommand(i, szSound);
		}
		g_iScore[0] = 0;
		g_iScore[1] = 0;
		
		return;
	}
	*/
	//
	// --------------------
	if( (g_iScore[Flag_Type]+1) == g_iScore[Reverse_Flag_Type] ) {
		Format(szSound, sizeof(szSound), "%s%sTeamTakesTheLead.mp3\"", szSound, szTeam);
	}
	else if( (g_iScore[Flag_Type]+2) == g_iScore[Reverse_Flag_Type] ) {
		Format(szSound, sizeof(szSound), "%s%sTeamIncreasesTheirLead.mp3\"", szSound, szTeam);
	}
	else  {
		Format(szSound, sizeof(szSound), "%s%sTeamScores.mp3\"", szSound, szTeam);
	}
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		ClientCommand(i, szSound);
	}
}
// ------------------------------------------------------------------------------------------------------------------
//	Lorsqu'un drapeau sur le sol, est touché.
//
public CTF_FlagTouched(toucher, flag, Flag_Type) {	
	if( IsValidClient(g_iFlags_Carrier[Flag_Type]) )
		return;
	
	new team = GetClientTeam(toucher);
	if( team == CS_TEAM_T && Flag_Type == 0 ) {
		return;
	}
	if( team == CS_TEAM_CT && Flag_Type == 1 ) {
		return;
	}
	
	if( (g_fLastDrop[toucher]+3.0) >= GetGameTime() ) {
		return;
	}
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_%i%i%i%i", toucher, flag, Flag_Type, GetRandomInt(11111, 99999) );
	
	DispatchKeyValue(toucher, "targetname", ParentName);
	SetVariantString(ParentName);
	AcceptEntityInput(flag, "SetParent");
	
	SetVariantString("primary");
	AcceptEntityInput(flag, "SetParentAttachment");
	
	new Float:ang[3], Float:pos[3];
	ang[0] = -45.0;
	pos[0] += 10.0;
	pos[1] += 5.0;
	pos[2] -= 2.0;
	
	TeleportEntity(flag, pos, ang, NULL_VECTOR);
	
	g_iFlags_Carrier[Flag_Type] = toucher;
	g_fFlags_Respawn[Flag_Type] = -1.0;
	
	for(new i=1; i<=GetMaxClients(); i++) {
		if( !IsValidClient(i) ) 
			continue;
		
		if( i == toucher ) {
			ClientCommand(i, "play \"DeadlyDesire/ctf/YouHaveTheFlag.mp3\"");
		}
		else {
			if( Flag_Type == 1 ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/BlueFlagTaken.mp3\"");
			}
			else if( Flag_Type == 0 ) {
				ClientCommand(i, "play \"DeadlyDesire/ctf/RedFlagTaken.mp3\"");
			}
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
//	Correction de la physic du drapeau
//
public CTF_FixAngles() {
	
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
			
			if( IsValidClient(g_iFlags_Carrier[Flag_Type]) )
				continue;
			
			new Float:vecAngles[3];
			TeleportEntity(g_iFlags_Entity[Flag_Type], NULL_VECTOR, vecAngles, NULL_VECTOR);
		}
	}
}
stock ExplosionDamage(Float:origin[3], Float:damage, Float:lenght, index, index2) {
	
	new Float:PlayerVec[3], Float:distance, Float:falloff = (damage/lenght);
	
	new Float:min[3] = { -8.0, -8.0, -8.0};
	new Float:max[3] = {  8.0,  8.0,  8.0};
	new Float:origin2[3], Float:normal[3];
	
	new Handle:tr = TR_TraceHullFilterEx(origin, origin, min, max, MASK_SHOT, TraceEntityFilterStuff2);
	TR_GetPlaneNormal(tr, normal);
	TR_GetEndPosition(origin2, tr);
	
	CloseHandle(tr);
	
	if( GetVectorDistance(origin, origin2) <= 32.0 ) {
		origin[0] = origin2[0];
		origin[1] = origin2[1];
		origin[2] = origin2[2];
	}
	
	TE_SetupExplosion(origin, g_cExplode, 1.0, 1, 0, RoundFloat(lenght), RoundFloat(lenght), normal);
	TE_SendToAll();
	
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", origin);
	TE_WriteNum("m_nIndex", g_cScorch);
	TE_SendToAll();
	
	
	for(new i=1; i<=GetMaxEntities(); i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		if( !IsMoveAble(i) && !IsValidSentry(i) && !IsValidTeleporter(i) )
			continue;
		
		if( IsValidClient(i) ) {
			GetClientEyePosition(i, PlayerVec);
		}
		else {
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", PlayerVec);
		}
		
		
		distance = GetVectorDistance(origin, PlayerVec) * falloff;
		
		new Float:dmg = (damage - distance);		
		
		TR_TraceRayFilter(origin, PlayerVec, MASK_SHOT, RayType_EndPoint, TraceEntityFilterStuff2);
		new Float:fraction = (TR_GetFraction()) * 1.5;
		
		if( TR_GetEntityIndex() == i )
			fraction = 1.0;
		
		if( fraction > 1.0 )
			fraction = 1.0;
		if( fraction < 0.0 )
			fraction = 0.0;
		
		dmg *= fraction;
		
		if( dmg < 0.0 )
			continue;
		
		if( IsValidClient(i) && i == index ) {
			dmg *= 0.65;
		}
		
		DealDamage(i, RoundFloat(dmg), index, DMG_GENERIC, "weapon_expl");
	}
	MakeRadiusPush2(origin, lenght, (damage * 10.0));
}
public bool:TraceEntityFilterStuff2(entity, mask) {

	if( IsValidClient(entity) || IsMoveAble(entity) )
		return false;
	
	if( entity > 0 && IsValidEdict(entity) && IsValidEntity(entity) ) {
		new String:classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		if( StrContains(classname, "ctf_") == 0 ) {
			return false;
		}
	}
	
	return true;
}
stock MakeRadiusPush2( Float:center[3], Float:lenght, Float:damage) {
	
	new Float:vecPushDir[3], Float:vecOrigin[3], Float:vecVelo[3], Float:FallOff = (damage/lenght);
	
	for(new i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		if( !IsMoveAble(i) )
			continue;
		
		if( IsValidClient(i) ) {
			GetClientEyePosition(i, vecOrigin);
		}
		else {
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
		}
		
		if( GetVectorDistance(vecOrigin, center) > lenght )
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVelo);
		
		vecPushDir[0] = vecOrigin[0] - center[0];
		vecPushDir[1] = vecOrigin[1] - center[1];
		vecPushDir[2] = vecOrigin[2] - center[2];
		
		NormalizeVector(vecPushDir, vecPushDir);
		new Float:dist = (lenght - GetVectorDistance(vecOrigin, center)) * FallOff;
		
		TR_TraceRayFilter(center, vecOrigin, MASK_SHOT, RayType_EndPoint, TraceEntityFilterStuff2);
		new Float:fraction = (TR_GetFraction()) * 1.5;
		
		if( fraction >= 1.0 )
			fraction = 1.0;
		
		dist *= fraction;
		
		new Float:vecPush[3];
		vecPush[0] = (dist * vecPushDir[0]) + vecVelo[0];
		vecPush[1] = (dist * vecPushDir[1]) + vecVelo[1];
		vecPush[2] = (dist * vecPushDir[2]) + vecVelo[2];
		
		new flags = GetEntityFlags(i);
		if( vecPush[2] > 0.0 && (flags & FL_ONGROUND) ) {
			
			SetEntityFlags(i, (flags&~FL_ONGROUND) );
			SetEntPropEnt(i, Prop_Send, "m_hGroundEntity", -1);
		}
		TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vecPush);
	}
	
}
stock MakeSmokeFollow(entity, Float:life, const color[4]) {
	
	new ent = CreateEntityByName("env_spritetrail");
	if( !IsValidEdict(ent) )
		return;
	
	if( g_cSmokeBeam ) {
		// Prevent Warning
	}
	
	new String:szColor[32], Float:vecOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	
	Format(szColor, sizeof(szColor), "%f", life);
	DispatchKeyValue(ent, "lifetime", szColor);
	DispatchKeyValue(ent, "endwidth", "5.0");
	DispatchKeyValue(ent, "startwidth", "5.0");
	DispatchKeyValue(ent, "spritename", "materials/sprites/xbeam2.vmt");
	DispatchKeyValue(ent, "rendermode", "5");
	
	Format(szColor, sizeof(szColor), "%i", color[3]);
	DispatchKeyValue(ent, "renderamt", szColor);
	Format(szColor, sizeof(szColor), "%i %i %i", color[0], color[1], color[2]);
	DispatchKeyValue(ent, "rendercolor", szColor);
	
	DispatchSpawn(ent);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	new String:ParentName[128];
	//
	Format(ParentName, sizeof(ParentName), "ctf_smoke_%i%i%i", ent, entity, GetRandomInt(11111, 99999) );
	DispatchKeyValue(entity, "targetname", ParentName);	
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent, "SetParent");
}

stock HomingMissle(client, entity) {
	
	new Float:vecOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	
	new Float:NearestDistance = 9999999.9, NearestEntity = -1;
	
	for(new i=1; i<= GetMaxClients(); i++) {
		if( !IsValidClient(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		
		new Float:vecOrigin2[3];
		GetClientEyePosition(i, vecOrigin2);
		
		if( GetClientTeam(client) != GetClientTeam(i) ) {
			
			new Float:dist = GetVectorDistance(vecOrigin, vecOrigin2);
			
			if( dist < NearestDistance ) {
				if( IsPointVisible(vecOrigin, vecOrigin2) ) {
					
					NearestDistance = dist;
					NearestEntity = i;
				}
			}
		}
	}
	
	if( !IsValidClient(NearestEntity) )
		return;
	
	new Float:vecOrigin2[3];
	GetClientEyePosition(NearestEntity, vecOrigin2);
	
	new Float:diff[3];
	diff[0] = vecOrigin2[0] - vecOrigin[0];
	diff[1] = vecOrigin2[1] - vecOrigin[1];
	diff[2] = vecOrigin2[2] - vecOrigin[2];
	
	new Float:lenght = SquareRoot( Pow(diff[0], 2.0) + Pow(diff[1], 2.0) + Pow(diff[2], 2.0) );
	
	new Float:vecVelocity[3];
	
	vecVelocity[0] = diff[0] * (800.0 / lenght);
	vecVelocity[1] = diff[1] * (800.0 / lenght);
	vecVelocity[2] = diff[2] * (800.0 / lenght);
	
	new Float:vecAngles[3];
	GetVectorAngles(vecVelocity, vecAngles);
	
	TeleportEntity(entity, NULL_VECTOR, vecAngles, vecVelocity);
}
public SpawnC4(client, Float:vecOrigin[3], Float:fTime) {
	
	new index = CreateEntityByName("prop_physics");
	if( !IsValidEdict(index) )
		return;
	
	SetEntityModel(index, "models/Weapons/w_c4_planted.mdl");
	
	DispatchKeyValue(index, "model", "models/Weapons/w_c4_planted.mdl");
	DispatchKeyValue(index, "solid", "0");
	DispatchKeyValue(index, "disableshadows", "0");
	
	ActivateEntity(index);
	DispatchSpawn(index);
	
	SetEntProp(index, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE);
	SetEntPropEnt(index, Prop_Send, "m_hOwnerEntity", client);
	
	TeleportEntity(index, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	g_C4_fExplodeTime[index] = (GetGameTime() + fTime);
	g_C4_bIsActive[index] = true;
}
public ExplodeC4(index) {
	g_C4_bIsActive[index] = false;
	
	new Float:vecOrigin[3];
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", vecOrigin);
	
	new String:sound[128];
	Format(sound, 127, "weapons/explode%i.wav", GetRandomInt(3, 5));
	
	EmitSoundFromOrigin(sound, vecOrigin);
	EmitSoundFromOrigin(sound, vecOrigin);
	EmitSoundFromOrigin(sound, vecOrigin);
	EmitSoundFromOrigin(sound, vecOrigin);
	EmitSoundFromOrigin(sound, vecOrigin);
	
	vecOrigin[2] -= 10.0;
	ExplosionDamage(vecOrigin, 800.0, 600.0, GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity"), index);
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 600, 600);
	TE_SendToAll();
	
	AcceptEntityInput(index, "Kill");
}
public BeepC4(index) {
	
	new Float:vecOrigin[3];
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", vecOrigin);
	
	EmitSoundFromOrigin("weapons/c4/c4_beep1.wav", vecOrigin);
	EmitSoundFromOrigin("weapons/c4/c4_beep1.wav",vecOrigin);
	
	new ent = CreateEntityByName("env_sprite");
	
	DispatchKeyValue(ent, "model",			"sprites/glow01.vmt");
	DispatchKeyValue(ent, "spawnflags",		"1");
	DispatchKeyValue(ent, "rendermode",		"5");
	DispatchKeyValue(ent, "renderamt",		"200");
	DispatchKeyValue(ent, "rendercolor",	"255 0 0");
	DispatchKeyValue(ent, "scale",			"1.0");
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchSpawn(ent);
	
	CreateTimer(0.1, RemoveBeepC4, ent);
}
public Action:RemoveBeepC4(Handle:Timer, any:ent) {
	AcceptEntityInput(ent, "Kill");
}

public ULTI_TraceDecal(Float:vecOrigin[3], decal) {
	
	new Float:vecOrigin2[3];
	new Float:vecAngles[3]; vecAngles[0] = -90.0;
	
	new Handle:trace = TR_TraceRayEx( vecOrigin, vecAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite);
	if( TR_DidHit( trace ) ) {
		
		TR_GetEndPosition( vecOrigin2, trace );
		
		new index = TR_GetEntityIndex( trace );
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) <= 100.0 ) {
			
			if( index > 0 ) {
				TE_SetupBSPDecal(vecOrigin2, index, decal);
				TE_SendToAll();
			}
		}
	}
	CloseHandle( trace );
	
	TE_SetupBSPDecal(vecOrigin2, 0, decal);
	TE_SendToAll();
}
stock bool:CTF_IsNear(client, target) {
	new Float:vecStart[3], Float:vecEnd[3];
	
	if( GetClientAimTarget(client, false) != target )
		return false;
	
	
	if( IsValidClient(client) ) 
		GetClientEyePosition(client, vecStart);
	else 
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecStart);
	
	
	if( IsValidClient(target) )
		GetClientEyePosition(target, vecStart);
	else
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vecEnd);
	
	
	if( GetVectorDistance(vecStart, vecEnd) >= 100.0 )
		return false;
	
	
	return true;
}
stock CTF_FillupAmmunition(client, entity, grenade = false) {
	
	SetVariantString("Open");
	AcceptEntityInput(entity, "SetAnimation");
	HookSingleEntityOutput(entity, "OnAnimationDone", CTF_FillupAmmunition2);
	
	if( !grenade ) {
		
		new health = GetClientHealth(client);
		new gren1 = g_iPlayerGrenadeAmount[client][0];
		new gren2 = g_iPlayerGrenadeAmount[client][1];
		
		CTF_CLASS_init(client);
		
		SetEntityHealth(client, health);
		g_iPlayerGrenadeAmount[client][0] = gren1;
		g_iPlayerGrenadeAmount[client][1] = gren2;		
	}
	else {
		
		switch( g_iPlayerClass[client] ) {
			case class_scout: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 4;
			}
			case class_sniper: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 0;
			}
			case class_soldier: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 2;
			}
			case class_demoman: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 2;
			}
			case class_medic: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 4;
			}
			case class_hwguy: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 2;
			}
			case class_pyro: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 0;
			}
			case class_spy: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 4;
			}
			case class_engineer: {
				g_iPlayerGrenadeAmount[client][0] = 4;
				g_iPlayerGrenadeAmount[client][1] = 4;
			}
		}
		
		EmitSoundToClient(client, "items/itempickup.wav");
	}
}
public CTF_FillupAmmunition2(const String:output[], caller, activator, Float:delay) {
	SetVariantString("Close");
	AcceptEntityInput(caller, "SetAnimation");
	
	HookSingleEntityOutput(caller, "OnAnimationDone", CTF_FillupAmmunition3);
}
public CTF_FillupAmmunition3(const String:output[], caller, activator, Float:delay) {
	SetVariantString("Idle");
	AcceptEntityInput(caller, "SetAnimation");
}