#if defined _ctf_functions_included
#endinput
#endif
#define _ctf_functions_included

#include "ctf.sp"

// ------------------------------------------------------------------------------------------------------------------
// 		CTF GLOBAL FUNCTIONS
//

// ------------------------------------------------------------------------------------------------------------------
//	Utilisé pour drop un drapeau à partir d'un joueur à sa mort.
//

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
	
	g_fLastDrop[client] = GetGameTime();
	
	new Float:vecFlag[3], Float:vecNull[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecFlag);
	
	vecFlag[2] += 10.0;
	
	TeleportEntity(g_iFlags_Physics[iFlagType], vecFlag, vecNull, NULL_VECTOR);
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_drop_%i", GetRandomInt(11111, 99999) );
	DispatchKeyValue(g_iFlags_Physics[iFlagType], "targetname", ParentName);
	//
	SetVariantString(ParentName);
	AcceptEntityInput(g_iFlags_Entity[iFlagType], "SetParent");
	
	vecFlag[0] = 0.0;
	vecFlag[1] = 0.0;
	vecFlag[2] = 0.0;
	
	TeleportEntity(g_iFlags_Entity[iFlagType], vecFlag, vecFlag, NULL_VECTOR);
	AcceptEntityInput(g_iFlags_Physics[iFlagType], "EnableMotion");
	
	if( thrown ) {
		
		new Handle:dp;
		CreateDataTimer( 0.1, CTF_DropFlag_Task, dp); 
		WritePackCell(dp, client);
		WritePackCell(dp, iFlagType);
	}
}
public Action:CTF_DropFlag_Task(Handle:timer, Handle:dp) {
	
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new iFlagType = ReadPackCell(dp);
	
	AcceptEntityInput(g_iFlags_Physics[iFlagType], "EnableMotion");
	
	new Float:vecOrigin[3], Float:vecAngles[3], Float:vecPush[3], Float:vecNull[3];
	
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	vecAngles[0] += 10.0;
	
	vecOrigin[0] = (vecOrigin[0] + (50.0 * Cosine( degrees_to_radians( vecAngles[1] ) ) ) );
	vecOrigin[1] = (vecOrigin[1] + (50.0 * Sine( degrees_to_radians( vecAngles[1] ) ) ) );
	vecOrigin[2] = (vecOrigin[2] + 1.0);
	
	GetAngleVectors(vecAngles, vecPush, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecPush, 1000.0);
	
	TeleportEntity(g_iFlags_Physics[iFlagType], vecOrigin, vecNull, vecPush);
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
	if( g_iFlags_Base[Flag_Type] > 1 && IsValidEdict(g_iFlags_Base[Flag_Type]) && IsValidEntity(g_iFlags_Base[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Base[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_base", false) ) {
			AcceptEntityInput(g_iFlags_Base[Flag_Type], "KillHierarchy");
		}
	}
	if( g_iFlags_Physics[Flag_Type] > 1 && IsValidEdict(g_iFlags_Physics[Flag_Type]) && IsValidEntity(g_iFlags_Physics[Flag_Type]) ) {
		
		new String:classname[128];
		GetEdictClassname(g_iFlags_Physics[Flag_Type], classname, 127);
		if( StrEqual(classname, "ctf_flag_physics", false) ) {
			AcceptEntityInput(g_iFlags_Physics[Flag_Type], "KillHierarchy");
		}
	}
	
	g_iFlags_Entity[Flag_Type] = 0;
	g_iFlags_Physics[Flag_Type] = 0;
	g_iFlags_Carrier[Flag_Type] = 0;
	
	new ent0 = CreateEntityByName("prop_physics");
	if( !IsValidEdict(ent0) )
		return;
	new ent1 = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent1) )
		return;
	new ent2 = CreateEntityByName("prop_dynamic");
	if( !IsValidEdict(ent2) )
		return;
	new ent3 = CreateEntityByName("light_dynamic");
	if( !IsValidEdict(ent3) )
		return;
	new ent4 = CreateEntityByName("env_spritetrail");
	if( !IsValidEdict(ent4) )
		return;
	
	SetEntityModel(ent0, "models/props/cs_assault/barrelwarning.mdl");
	DispatchKeyValue(ent0, "disableshadows", "1");
	DispatchKeyValue(ent0, "nodamageforces", "1");
	DispatchKeyValue(ent0, "solid", "0");
	DispatchKeyValue(ent0, "spawnflags", "6");
	//
	SetEntityModel(ent1, "models/DeadlyDesire/ctf/flag.mdl");
	DispatchKeyValue(ent1, "solid", "0");
	DispatchKeyValue(ent1, "classname", "ctf_flag");
	//
	SetEntityModel(ent2, "models/DeadlyDesire/ctf/cap_point_base.mdl");
	DispatchKeyValue(ent2, "solid", "5");
	DispatchKeyValue(ent2, "classname", "ctf_base");
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
		DispatchKeyValue(ent2, "Skin", "1");
		DispatchKeyValue(ent3, "_light", "255 0 0");
		DispatchKeyValue(ent4, "rendercolor", "250 0 0");
	}
	else if( Flag_Type == 1 ) {
		DispatchKeyValue(ent1, "Skin", "1");
		DispatchKeyValue(ent2, "Skin", "2");
		DispatchKeyValue(ent3, "_light", "0 0 255");
		DispatchKeyValue(ent4, "rendercolor", "0 0 250");
	}
	else {
		DispatchKeyValue(ent1, "Skin", "2");
		DispatchKeyValue(ent2, "Skin", "0");
		DispatchKeyValue(ent4, "rendercolor", "10 10 10");
	}
	
	DispatchSpawn(ent0);
	DispatchSpawn(ent1);
	DispatchSpawn(ent2);
	DispatchSpawn(ent3);
	DispatchSpawn(ent4);
	
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent0, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent1, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent2, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] += 10.0;
	TeleportEntity(ent3, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	g_vecFlags[Flag_Type][2] -= 10.0;
	TeleportEntity(ent4, g_vecFlags[Flag_Type], NULL_VECTOR, NULL_VECTOR);
	
	g_iFlags_Physics[Flag_Type] = ent0;
	g_iFlags_Entity[Flag_Type] = ent1;
	g_iFlags_Base[Flag_Type] = ent2;
	
	new String:ParentName[128];
	Format(ParentName, sizeof(ParentName), "ctf_physics_%i%i%i%i", ent0, ent1, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent0, "targetname", ParentName);
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent1, "SetParent");
	//
	//
	Format(ParentName, sizeof(ParentName), "ctf_parent_%i%i%i%i", ent0, ent1, Flag_Type, GetRandomInt(11111, 99999) );
	DispatchKeyValue(ent1, "targetname", ParentName);	
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent3, "SetParent");
	//
	SetVariantString(ParentName);
	AcceptEntityInput(ent4, "SetParent");
	
	AcceptEntityInput(ent0, "DisableMotion");
	AcceptEntityInput(ent0, "DisablePuntSound");
	Colorize(ent0, 255, 255, 255, 0);
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
	}
	else {
		Format(szTeam, sizeof(szTeam), "Blue");
	}
	
	Format(szSound, sizeof(szSound), "play \"DeadlyDesire/ctf/");
	
	PrintToChatAll("%N Capture le drapeau.", client);
	PrintToChatAll("*** Score: %i - %i", g_iScore[0], g_iScore[1]);
	
	// Si une équipe remporte la victoire:
	// --------------
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
	//
	// --------------------
	if( g_iScore[Flag_Type] == 0 && g_iScore[Reverse_Flag_Type] == 2 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamIncreasesTheirLead.mp3\"", szSound, szTeam);
	}
	else if( g_iScore[Flag_Type] == 1 && g_iScore[Reverse_Flag_Type] == 2 ) {
		Format(szSound, sizeof(szSound), "%s%sTeamTakesTheLead.mp3\"", szSound, szTeam);
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
			
			CTF_FixAngle(g_iFlags_Physics[Flag_Type]);
		}
	}
}
public CTF_FixAngle(ent) {
	new Float:fOrigin[3], Float:fAngle[3], Float:vecDest[3], Float:vecVelocity[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fOrigin);
	
	
	fAngle[0] = 90.0;
	fAngle[1] = 90.0;
	fAngle[2] = 0.0;
	
	vecVelocity[0] = 0.0;
	vecVelocity[1] = 0.0;
	vecVelocity[2] = -250.0;
	
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, fAngle, MASK_NPCWORLDSTATIC, RayType_Infinite, FilterToOne, ent);
	TR_GetEndPosition(vecDest, trace);
	GetEntPropVector(ent, Prop_Data, "m_angRotation", fAngle);
	fAngle[0] = 0.0;
	TeleportEntity(ent, NULL_VECTOR, fAngle, vecVelocity);
	
	if( !IsValidClient(TR_GetEntityIndex(trace)) && GetVectorDistance(fOrigin, vecDest) <= 20.0 ) {
		
		AcceptEntityInput(ent, "DisableMotion");
	}
	
	CloseHandle(trace);
}
stock ExplosionDamage(Float:origin[3], Float:damage, Float:lenght, index) {
	
	new Float:vecStart[3], Float:PlayerVec[3], Float:distance, Float:falloff = (damage/lenght), entity_to_ignore = -1;
	
	for(new i=1; i<=GetMaxClients(); i++) {
		
		if( !IsValidClient(i) )
			continue;
		if( !IsPlayerAlive(i) ) 
			continue;
		
		GetClientAbsOrigin(i, PlayerVec);
		vecStart[0] = origin[0];
		vecStart[1] = origin[1];
		vecStart[2] = origin[2];
		
		distance = GetVectorDistance(origin, PlayerVec) * falloff;
		
		new Float:dmg = (damage - distance);		
		
		new Handle:trace = TR_TraceRayFilterEx(vecStart, PlayerVec, MASK_SHOT, RayType_EndPoint, FilterToOne, entity_to_ignore);
		if( !TR_DidHit(trace) ) {
			
			break;
		}
		new Float:fraction = (TR_GetFraction(trace) * 1.25);
		
		if( fraction >= 1.0 )
			fraction = 1.0;
		
		CloseHandle(trace);
		
		if( dmg < 0.0 )
			continue;
		
		if( i == index || GetClientTeam(i) == GetClientTeam(index) )
			dmg *= 0.25;
		
		DealDamage(i, RoundFloat(dmg), index);
	}
	
	origin[2] -= 10.0;
	MakeRadiusPush(origin, lenght, (damage * 10.0));
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
	ExplosionDamage(vecOrigin, 400.0, 600.0, GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity"));
	
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
