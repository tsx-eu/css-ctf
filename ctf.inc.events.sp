#if defined _ctf_events_included
#endinput
#endif
#define _ctf_events_included

#include "ctf.sp"
#include "ctf.inc.const.sp"
#include "ctf.inc.events.sp"
#include "ctf.inc.functions.sp"
#include "ctf.inc.classes.sp"
#include "ctf.inc.weapons.sp"
#include "ctf.inc.sentry.sp"
#include "ctf.inc.grenades.sp"

// ------------------------------------------------------------------------------------------------------------------
//		Hooks -	Connexions Call
//
public OnThink(client) {
	
	if( g_iPlayerClass[client] == class_sniper && IsPlayerAlive(client) ) {

		CTF_SNIPER_dot(client);
		
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if( WeaponIndex > 0 ) {
			new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
			
			if( StrEqual(WeaponName, "weapon_awp", false) ) {
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_fAccuracyPenalty", 0.0);
				SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
			}
		}
	}
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage,	OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit,	OnSetTransmit);
	SDKHook(client, SDKHook_Touch, 			CTF_CLIENT_TOUCH);
	SDKHook(client,	SDKHook_PreThink,		OnThink);
	SDKHook(client,	SDKHook_PostThink,		OnThink);
	
	CTF_Reset_Player(client);
	
	g_iPlayerClass[client] = class_none;
	g_iPlayerArmor[client] = 0;
	g_fUlti_Cooldown[client] = 0.0;
	
	g_fCustomWeapon_NextShoot[client][0] = 0.0;
	g_fCustomWeapon_NextShoot[client][1] = 0.0;
	g_fCustomWeapon_NextShoot[client][2] = 0.0;
	
	g_iContaminated[client] = 0;
	g_fContaminate[client] = 0.0;
	
	g_iBurning[client] = 0;
	g_fBurning[client] = 0.0;
	
	g_fRestoreSpeed[client][0] = 0.0;
	g_fRestoreSpeed[client][1] = -1.0;
	
	g_flPrimedTime[client] = -1.0;
	
	if( IsFakeClient(client) )
		g_iPlayerClass[client] = enum_class_type:GetRandomInt(1, 9);
	
	
}
public Action:OnSetTransmit(entity, client) {
	if( entity == client )
		return Plugin_Continue;
	
	if( IsValidClient(entity) ) {
		if( g_iPlayerClass[entity] == class_spy ) {
			if( g_fUlti_Cooldown[entity] > (GetGameTime()+(50.0)) ) {
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
public Action:CTF_CLIENT_TOUCH(client, target) {
	if( !IsValidClient(client) )
		return Plugin_Continue;
	if( !IsValidEdict(target) )
		return Plugin_Continue;
	if( !IsValidEntity(target) )
		return Plugin_Continue;
	
	
	new String:classname[128], String:targetname[128];
	GetEdictClassname(target, classname, 127);
	GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if( StrEqual(classname, "trigger_multiple") ) {
		
		if( GetClientTeam(client) == CS_TEAM_CT ) {
			if( StrEqual(targetname, "red_respawndoor", false) ) {
				return Plugin_Stop;
			}
		}
		if( GetClientTeam(client) == CS_TEAM_T ) {
			if( StrEqual(targetname, "blue_respawndoor", false) ) {
				return Plugin_Stop;
			}
		}
		
		if( StrEqual(targetname, "ctf_capture_blue") || StrEqual(targetname, "ctf_capture_red") ) {
			
			for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
				if( IsValidClient(g_iFlags_Carrier[Flag_Type]) && g_iFlags_Carrier[Flag_Type] == client ) {
					new Reverse_Flag_Type = _:flag_red;
					if( Flag_Type == _:flag_red ) {
						Reverse_Flag_Type = _:flag_blue;
					}
					
					if( GetClientTeam(client) == CS_TEAM_CT && StrEqual(targetname, "ctf_capture_blue") ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
					}
					if( GetClientTeam(client) == CS_TEAM_T && StrEqual(targetname, "ctf_capture_red") ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}
public OnClientDisconnect(client) {
	CTF_DropFlag(client);
	
	if( g_iPlayerClass[client] == class_demoman ) 
		CTF_WEAPON_PIPE_PipeBomb_EXPL(client, true);
	
	if( g_iPlayerClass[client] == class_engineer )
		CTF_ENGINEER_DETALL(client);
	
	CTF_WEAPON_CUSTOM_CLEAN(client);
}

// ------------------------------------------------------------------------------------------------------------------
// 		Hooks - Event
//
public Action:EventPlayerTeam(Handle:Event, const String:name[], bool:dontBroadcast) {
	// Don't broadcast the player_team event to chat
	SetEventBroadcast(Event, true);
	
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	new team = GetEventInt(Event, "team");
	new oldteam = GetEventInt(Event, "oldteam");
	
	if( team != oldteam ) {
		CTF_ENGINEER_DETALL(client);
		CTF_WEAPON_PIPE_PipeBomb_EXPL(client, true);
	}
	
	g_iPlayerClass[client] = class_none;
	if( team == CS_TEAM_CT ) {
		CTF_PrintToChat(0, "%N a rejoint l'équipe bleue.", client);
	}
	else if( team == CS_TEAM_T ) {
		CTF_PrintToChat(0, "%N a rejoint l'équipe rouge.", client);
	}
	return Plugin_Continue;
}
public Action:EventRoundStart(Handle:Event, const String:Name[], bool:Broadcast) {
	
	CTF_LoadFlag();
	
	CTF_SpawnFlag(flag_red);
	CTF_SpawnFlag(flag_blue);
	
	ScheduleTargetInput("ctf_security_red_hurt", 0.5, "Enable");
	ScheduleTargetInput("ctf_security_blue_hurt", 0.5, "Enable");
	
	CTF_SpawnBackPack();
	return Plugin_Continue;
}
public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if( client == 0 )
		return Plugin_Continue;
	
	if( g_iLastTeam[client] != GetClientTeam(client) ) {
		if( GetClientTeam(client) == CS_TEAM_CT ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnBlue.mp3\"");
		}
		else if( GetClientTeam(client) == CS_TEAM_T ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnRed.mp3\"");
		}
	}
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		Colorize(client, 150, 150, 255, 255);
	}
	else if( GetClientTeam(client) == CS_TEAM_T ) {
		Colorize(client, 255, 150, 150, 255);
	}
	
	if( g_iPlayerClass[client] == class_none ) {
		
		g_flPlayerSpeed[client] = 0.0;
		
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
		SetEntityHealth(client, 100);
		
		g_iPlayerArmor[client] = 0;
	}
	
	g_iLastTeam[client] = GetClientTeam(client);
	
	CTF_WEAPON_CUSTOM_CLEAN(client);
	CTF_CLASS_init(client);
	
	return Plugin_Continue;
}
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	g_iRevieveTime[client] = (GetClientCount());
	if( g_iRevieveTime[client] < 5 )
		g_iRevieveTime[client] = 5;
	if( g_iRevieveTime[client] > 20 )
		g_iRevieveTime[client] = 20;
	
	CTF_DropFlag(client);
	
	CleanUp();
	
	CTF_WEAPON_CUSTOM_CLEAN(client);
	
	if( g_iPlayerClass[client] == class_demoman ) 
		CTF_WEAPON_PIPE_PipeBomb_EXPL(client, true);
	
	g_iContaminated[client] = 0;
	g_fContaminate[client] = 0.0;
	
	if( IsValidClient(g_iBurning[client]) && g_fBurning[client] > GetGameTime() ) {
		Client_SetScore(g_iBurning[client], Client_GetScore(g_iBurning[client])+1);	
		
		if( !IsValidClient(attacker) ) {
			
			SetEventBroadcast(Event, true);
			
			Client_SetScore(client, Client_GetScore(client)+1);
			
			
			new Handle:ev = CreateEvent("player_death");
			SetEventInt(ev, "userid", GetClientUserId(client));
			SetEventInt(ev, "attacker", GetClientUserId(g_iBurning[client]));
			SetEventString(ev, "weapon", "ctf_flame");
			SetEventBool(ev, "headshot", false);
			FireEvent(ev);
			if( ev != INVALID_HANDLE )
				CloseHandle(ev);
		}
	}
	g_iBurning[client] = 0;
	g_fBurning[client] = 0.0;
	
	return Plugin_Continue;
}
public EventBulletImpact(Handle:event,const String:name[],bool:dontBroadcast) {
	
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntProp(attacker, Prop_Send, "m_iShotsFired", 0);
	
	new Float:bulletDestination[3];
	bulletDestination[0] = GetEventFloat( event, "x" );
	bulletDestination[1] = GetEventFloat( event, "y" );
	bulletDestination[2] = GetEventFloat( event, "z" );
	
	if( g_iPlayerClass[attacker] == class_sniper && g_fUlti_Cooldown[attacker] > (GetGameTime()+ULTI_COOLDOWN-ULTI_DURATION) ) {
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, "weapon_awp", false) ) {
			
			new Float:vecOrigin[3], Float:vecAngles[3];
		
			GetClientEyePosition(attacker, vecOrigin);
			GetClientEyeAngles(attacker, vecAngles);
			
			new Float:rad = degrees_to_radians(vecAngles[1]);
			
			vecOrigin[0] = (vecOrigin[0] - (-10.0 * Sine(rad))   + (50.0 * Cosine(rad)) );
			vecOrigin[1] = (vecOrigin[1] + (-10.0 * Cosine(rad)) + (50.0 * Sine(rad)) );
			vecOrigin[2] = (vecOrigin[2] - 10.0);
			
			if( GetClientTeam( attacker ) == CS_TEAM_T ) {
				TE_SetupBeamPoints( vecOrigin, bulletDestination, g_cPhysicBeam, 0, 0, 0, 0.5, 3.0, 3.0, 1, 0.0, {250, 0, 0, 120}, 0);
			}
			else {
				TE_SetupBeamPoints( vecOrigin, bulletDestination, g_cPhysicBeam, 0, 0, 0, 0.5, 3.0, 3.0, 1, 0.0, {0, 0, 250, 120}, 0);
			}
			TE_SendToAll();
		}
	}
	
	for(new a=1; a<=GetMaxClients(); a++) {
		if( !IsValidClient(a) )
			continue;
		if( g_iPlayerClass[a] != class_engineer )
			continue;
		
		new Float:vecOrigin[3];
		
		
		if( IsValidTeleporter( g_iBuild[a][build_teleporter_in] ) ) {
			
			GetEntPropVector(g_iBuild[a][build_teleporter_in], Prop_Send, "m_vecOrigin", vecOrigin);
			
			if( GetVectorDistance(vecOrigin, bulletDestination) <= 16.0 ) {
				DealDamage(g_iBuild[a][build_teleporter_in], GetRandomInt(40, 60), a);
			}
		}
		
		if( IsValidTeleporter( g_iBuild[a][build_teleporter_out] ) ) {
			
			GetEntPropVector(g_iBuild[a][build_teleporter_out], Prop_Send, "m_vecOrigin", vecOrigin);
			
			if( GetVectorDistance(vecOrigin, bulletDestination) <= 16.0 ) {
				DealDamage(g_iBuild[a][build_teleporter_out], GetRandomInt(40, 60), a);
			}
		}
	}
}
// ------------------------------------------------------------------------------------------------------------------
//		Hooks - GameForwards
//
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	
	new bool:changed = false;
	
	new String:classname[128], String:targetname[128];
	GetEdictClassname(inflictor, classname, 127);
	GetEntPropString(inflictor, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if( StrEqual(classname, "entityflame") ) {
		changed = true;
		attacker = g_iBurning[victim];
		damage = GetRandomFloat(1.5, 3.0);
	}
	
	if( StrEqual(classname, "trigger_hurt") ) {
		
		new String:currentmap[64];
		GetCurrentMap(currentmap, sizeof(currentmap));
		if( StrEqual(currentmap, "ctf_schtop") ) {
			if( attacker == inflictor && attacker == (1172+GetMaxClients()) ) {
				Format(targetname, sizeof(targetname), "ctf_kill_red");
			}
		}
		if( GetClientTeam(victim) == CS_TEAM_CT ) {
			if( StrEqual(targetname, "ctf_kill_red", false) || StrEqual(targetname, "ctf_security_blue_hurt", false) )
				return Plugin_Handled;
		}
		if( GetClientTeam(victim) == CS_TEAM_T ) {
			if( StrEqual(targetname, "ctf_kill_blue", false)  || StrEqual(targetname, "ctf_security_red_hurt", false) )
				return Plugin_Handled;
		}
	}
	
	
	if( IsValidSentry(victim) || IsValidTeleporter(victim) ) {
		new owner, build_type;
		
		for(new i=0; i<=build_max; i++) {
			
			owner = CTF_SG_GetBuildingOwner(victim, i);
			build_type = i;
			
			if( owner != 0 )
				break;
		}
		new Float:vecPos[3];
		
		if( IsValidClient(owner) && IsValidClient(attacker) ) {
			if( GetClientTeam(owner) == GetClientTeam(attacker) ) {
				damage *= 0.2;
			}
		}
		
		if( g_flBuildHealth[victim][build_type] >= 200.0 && (g_flBuildHealth[victim][build_type]-damage) < 200.0 ) {
			
			new ent = AttachParticle(victim, "smoke_gib_01", -1.0);
			
			vecPos[2] += 50.0;
			TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
		}
		if(g_flBuildHealth[victim][build_type] >= 100.0 && (g_flBuildHealth[victim][build_type]-damage) < 100.0 ) {
			
			new ent = AttachParticle(victim, "burning_gib_01", -1.0);
			
			vecPos[2] += 50.0;
			TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
		}
		
		g_flBuildHealth[victim][build_type] -= damage;
		
		if( g_flBuildHealth[victim][build_type] <= 0.0 ) {
			
			new Float:vecAngl[3]; vecAngl[0] = 90.0;
			
			SheduleEntityInput(victim, 2.5, "KillHierarchy");
			
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vecPos);
			vecPos[2] += 10.0;
			
			ServerCommand("sm_effect_fading \"%i\" \"2.5\" \"1\"", victim);
			SetEntProp(victim, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
			
			TeleportEntity(victim, vecPos, vecAngl, NULL_VECTOR);
			
			EmitSoundFromOrigin("npc/turret_floor/die.wav", vecPos);
			
		}
		return Plugin_Handled;
	}
	
	if( attacker == 0 && inflictor == 0 && damagetype == DMG_FALL) {
		damage *= 0.25;
		damage -= 10.0;
		changed = true;
	}
	
	if( IsValidClient(attacker) ) {
		switch( g_iPlayerClass[attacker] ) {
			case class_scout: {
				damage *= 0.15;
				damagetype = DMG_PREVENT_PHYSICS_FORCE;
			}
			case class_sniper: {
				if( inflictor == attacker ) {
					new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					GetEdictClassname(WeaponIndex, classname, 127);
					
					if( StrEqual(classname, "weapon_awp") ) {
						damage *= 1.8;
						
						new Float:vecStart[3], Float:vecEnd[3], Float:vecPush[3];
						
						GetClientEyePosition(attacker, vecStart);
						GetClientEyePosition(victim, vecEnd);
						
						SubtractVectors(vecStart, vecEnd, vecPush);
						NormalizeVector(vecPush, vecPush);
						
						ScaleVector(vecPush, -750.0);
						TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecPush);
					}
				}
				damage *= 1.0;
			}
			case class_soldier: {
				damage *= 1.0;
			}
			case class_demoman: {
				damage *= 1.0;
			}
			case class_medic: {
				damage *= 0.20;
			}
			case class_hwguy: {
				damage *= 0.5;
			}
			case class_pyro: {
				damage *= 1.0;
			}
			case class_spy: {
				
				if( inflictor == attacker ) {
					new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					GetEdictClassname(WeaponIndex, classname, 127);
					
					if( StrEqual(classname, "weapon_knife") ) {
						
						if( damage > 150.0 ) {
							damage *= 10.0;
						}
						else {
							damage *= 4.0;
						}
					}
					else if( StrEqual(classname, "weapon_usp") ) {
						damage *= 0.0;
						
						g_fRestoreSpeed[victim][0] = (GetGameTime() + 2.5);
						if( g_fRestoreSpeed[victim][1] < 0.01 ) {
							g_fRestoreSpeed[victim][1] = g_flPlayerSpeed[victim];
						}
						g_flPlayerSpeed[victim] = 150.0;
					}
				}
			}
			case class_engineer: {
				
				if( inflictor == attacker ) {
					damage *= 0.25;
				}
				else {
					damage *= 1.0;
				}
			}
			case class_civilian: {
				damage *= 1.0;
			}
			default: {
				damage *= 0.0;
			}
		}
		changed = true;
		
		if( g_iPlayerClass[attacker] == class_hwguy ) {
			if( g_fUlti_Cooldown[attacker] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
				damage *= 0.2;
				changed = true;
			}
		}
		if( IsValidClient(victim) ) {
			
			if( attacker != victim && GetClientTeam(attacker) && GetClientTeam(victim) ) {
				damage *= 0.5;
				if( GetConVarInt(g_hFriendlyFire) == 0 ) {
					damage *= 0.0;
				}
				changed = true;
			}
			
			if( g_iPlayerArmor[victim] >= 1 ) {
				
				
				damage = damage * 0.8;
				
				new health = GetClientHealth(victim);
				
				g_iPlayerArmor[victim] = (g_iPlayerArmor[victim] - RoundToCeil(damage / 10.0 * 8.0));
				health = (health - RoundToCeil( damage / 10.0 * 6.0 ));
				
				while( g_iPlayerArmor[victim] < 0 ) {
					health -= GetRandomInt(1, 2);
					g_iPlayerArmor[victim]++;
					
					if( g_iPlayerArmor[victim] >= 0 )
						break;
				}
				
				
				if( health >= 1 ) {
					damage *= 0.0;
					changed = true;			
					SetEntityHealth(victim, health);
				}
			}
		}
	}
	if( changed )
		return Plugin_Changed;
	
	return Plugin_Continue;
}
// ------------------------------------------------------------------------------------------------------------------
//		Hooks - Think
//
public OnGameFrame() {
	
	for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
		if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
			if( g_fFlags_Respawn[Flag_Type] > 1.0 && g_fFlags_Respawn[Flag_Type] < GetGameTime() ) {
				
				for(new i=1; i<=GetMaxClients(); i++) {
					if( !IsValidClient(i) ) 
						continue;
					
					if( Flag_Type == 1 ) {
						ClientCommand(i, "play \"DeadlyDesire/ctf/BlueFlagReturned.mp3\"");
					}
					else if( Flag_Type == 0 ) {
						ClientCommand(i, "play \"DeadlyDesire/ctf/RedFlagReturned.mp3\"");
					}
				}
				CTF_SpawnFlag(Flag_Type);
			}
		}
	}
	
	for(new i=1; i<2048; i++) {
		if( g_flNailData[i][1] > 0.0 && g_flNailData[i][1] < GetGameTime() ) {
			
			if( !IsValidEdict(i) ) {
				g_flNailData[i][1] = -1.0;
				continue;
			}
			if( !IsValidEntity(i) ) {
				g_flNailData[i][1] = -1.0;
				continue;
			}
			
			CTF_NADE_NAIL_Shoot(i);
		}
		
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		if( g_iGrenadeType[i] != grenade_none && g_flPrimedTime[i] != -1.0 && (g_flPrimedTime[i]+3.55) <= GetGameTime() ) {
			CTF_NADE_EXPLODE(i);
			continue;
		}
		
		new String:classname[64];
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrEqual(classname, "env_particlesmokegrenade") ) {
			new Float:spawn = GetEntPropFloat(i, Prop_Send, "m_flSpawnTime");
			
			if( (GetGameTime()-spawn) >= 9.0 ) {
				SetEntPropFloat(i, Prop_Send, "m_FadeStartTime", 8.0);
				SetEntPropFloat(i, Prop_Send, "m_FadeEndTime", 10.0);
			}
			else {
				SetEntPropFloat(i, Prop_Send, "m_FadeStartTime", (GetGameTime()-spawn-1.50));
				SetEntPropFloat(i, Prop_Send, "m_FadeEndTime", (GetGameTime()-spawn+1.0));
			}
			
			new Float:vecOrigin[3], Float:vecOrigin2[3];
			GetEntPropVector(Entity_GetParent(i), Prop_Send, "m_vecOrigin", vecOrigin);
			
			for(new client=1; client<=GetMaxClients(); client++) {
				if( !IsValidClient(client) )
					continue;
				if( g_flGasLastDamage[client] > GetGameTime() )
					continue;
				
				GetClientEyePosition(client, vecOrigin2);
				if( GetVectorDistance(vecOrigin, vecOrigin2) >= 150.0 )
					continue;
				
				new owner = GetEntPropEnt(Entity_GetParent(i), Prop_Send, "m_hOwnerEntity");
				g_flGasLastDamage[client] = (GetGameTime() + 1.0);
				
				DealDamage(client, GetRandomInt(8, 12), owner);
				
				g_flCrazyTime[client] = (GetGameTime() + 20.0);
			}
		}
		if( StrContains(classname, "ctf_nade") == 0 ) {
			new Float:vecAngles[3];
			TeleportEntity(i, NULL_VECTOR, vecAngles, NULL_VECTOR);
		}
		if( StrContains(classname, "ctf_flame") == 0 ) {
			
			if( g_flCustomWeapon_Entity3[i] < GetGameTime() ) {
				
				if( GetEntProp(i, Prop_Data, "m_nWaterLevel") > 0 ) {
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
		}
	}
	
	for(new client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		
		new Float:vecOrigin[3], Float:vecOrigin2[3];
		GetClientAbsOrigin(client, vecOrigin);
		GetClientEyePosition(client, vecOrigin2);
		
		for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
			
			if( g_iFlags_Entity[Flag_Type] > 1 && IsValidEdict(g_iFlags_Entity[Flag_Type]) && IsValidEntity(g_iFlags_Entity[Flag_Type]) ) {
				new String:classname[128];
				GetEdictClassname(g_iFlags_Entity[Flag_Type], classname, 127);
				if( StrEqual(classname, "ctf_flag", false) ) {
					new Float:vecFlag[3];
					GetEntPropVector(g_iFlags_Entity[Flag_Type], Prop_Send, "m_vecOrigin", vecFlag);
					
					
					new Float:dist = GetVectorDistance(vecOrigin, vecFlag, false);
					if( dist <= 40.0 ) {
						CTF_FlagTouched(client, g_iFlags_Entity[Flag_Type], Flag_Type);
					}
				}
			}
		}
		
		if( g_bSecurity ) {
			for(new Flag_Type = 0; Flag_Type<=2; Flag_Type++) {
				
				new Float:dist = GetVectorDistance(g_vecSecu[Flag_Type], vecOrigin);
				new Float:dist2 = GetVectorDistance(g_vecSecu[Flag_Type], vecOrigin2);
				
				if( dist <= 40.0 || dist2 <= 40.0 ) {
					
					if( Flag_Type == _:flag_red && GetClientTeam(client) == CS_TEAM_CT ) {
						
						if( g_iSecu_Status[Flag_Type] )
							break;
						
						g_iSecu_Status[Flag_Type] = 1;
						
						ScheduleTargetInput("ctf_security_red_door", 0.0, "Open");
						ScheduleTargetInput("ctf_security_red_door", ((40.0)-(4.0)), "Close");
						
						ScheduleTargetInput("ctf_security_red_hurt", 0.0, "Disable");
						ScheduleTargetInput("ctf_security_red_hurt", 40.0, "Enable");
						
						ScheduleTargetInput("ctf_security_red_flame", 0.0, "Disable");
						ScheduleTargetInput("ctf_security_red_flame", 39.9, "Enable");
						ScheduleTargetInput("ctf_security_red_flame", 40.0, "StartFire");
						
						ScheduleTargetInput("ctf_security_red_sound", 0.0, "StopSound");
						ScheduleTargetInput("ctf_security_red_sound", 40.0, "PlaySound");
						
						CreateTimer( ((40.0) + (0.01)), SecuIsActivited, Flag_Type);
						
						CTF_PrintToChat(CTF_PRINT_RED, "Votre sécurité a été désactivée par l'ennemi.");
						CTF_PrintToChat(CTF_PRINT_BLU, "Votre équipe a désactivé la sécurité de l'ennemi.");
						
						for(new i=1; i<=GetMaxClients(); i++) {
							if( !IsValidClient(i) )
								continue;
							
							ClientCommand(i, "play \"DeadlyDesire/ctf/flagdrop.wav\"");
						}
						
						break;
					}
					if( Flag_Type == _:flag_blue && GetClientTeam(client) == CS_TEAM_T ) {
						
						if( g_iSecu_Status[Flag_Type] )
							break;
						
						g_iSecu_Status[Flag_Type] = 1;
						
						ScheduleTargetInput("ctf_security_blue_door", 0.0, "Open");
						ScheduleTargetInput("ctf_security_blue_door", ((40.0)-(4.0)), "Close");
						
						ScheduleTargetInput("ctf_security_blue_hurt", 0.0, "Disable");
						ScheduleTargetInput("ctf_security_blue_hurt", 40.0, "Enable");
						
						ScheduleTargetInput("ctf_security_blue_flame", 0.0, "Disable");
						ScheduleTargetInput("ctf_security_blue_flame", 39.9, "Enable");
						ScheduleTargetInput("ctf_security_blue_flame", 40.0, "StartFire");
						
						ScheduleTargetInput("ctf_security_blue_sound", 0.0, "StopSound");
						ScheduleTargetInput("ctf_security_blue_sound", 40.0, "PlaySound");
						
						CreateTimer( ((40.0) + (0.01)), SecuIsActivited, Flag_Type);
						
						CTF_PrintToChat(CTF_PRINT_BLU, "Votre sécurité a été désactivée par l'ennemi.");
						CTF_PrintToChat(CTF_PRINT_RED, "Votre équipe a désactivé la sécurité de l'ennemi.");
						
						for(new i=1; i<=GetMaxClients(); i++) {
							if( !IsValidClient(i) )
								continue;
							
							ClientCommand(i, "play \"DeadlyDesire/ctf/flagdrop.wav\"");
						}
						break;
					}
				}
			}
		}
		
		if( g_iPlayerClass[client] == class_sniper ) {
			
			CTF_SNIPER_dot(client);
			
			new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
			
			if( StrEqual(WeaponName, "weapon_awp", false) ) {
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_fAccuracyPenalty", 0.0);
			}
			
			if( g_fUlti_Cooldown[client] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
				
				
				
				if( StrEqual(WeaponName, "weapon_awp", false) ) {
					new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack");
					
					NextAttackTime -= GetGameTime();
					NextAttackTime *= 0.95;
					NextAttackTime += GetGameTime();
					
					SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
				}
			}
		}
		
		if( g_iPlayerClass[client] == class_soldier ) {
			if( g_fUlti_Cooldown[client] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
				
				new String:classname[128];
				Format(classname, sizeof(classname), "ctf_rocket_%i", client);
				
				for(new i=1; i<=2048; i++) {
					if( !IsValidEdict(i) )
						continue;
					if( !IsValidEntity(i) )
						continue;
					
					new String:classname2[128];
					
					GetEdictClassname(i, classname2, sizeof(classname));
					
					if( StrEqual(classname, classname2) ) {
						
						new Float:vecVelocity[3];
						Entity_GetAbsVelocity(i, vecVelocity);
						
						if( GetVectorLength(vecVelocity) > 1.0 ) {
							HomingMissle(client, i);
						}
					}
				}
			}
		}
		
		if( g_iPlayerClass[client] == class_medic ) {
			
			if( GetRandomInt(0, 150) == 100 ) {
				new current = Entity_GetHealth(client);
				
				if( current < Entity_GetMaxHealth(client) ) {
					Entity_SetHealth(client, current+1);
				}
			}
			
			if( IsValidClient(g_iCustomWeapon_Entity2[client][2]) ) {
				
				new target = g_iCustomWeapon_Entity2[client][2];
				
				new Float:fvecOrigin[3], Float:fvecOrigin2[3];
				GetClientAbsOrigin(client, fvecOrigin);
				GetClientAbsOrigin(target, fvecOrigin2);
				
				if( GetVectorDistance(fvecOrigin, fvecOrigin2) >= HEAL_DIST || !IsPlayerAlive(target) ) {
					CTF_WEAPON_MEDIC_link(client, 0, false);
				}
				else if( g_fCustomWeapon_NextShoot[client][0] <= (GetGameTime()-0.21) ) {
					CTF_WEAPON_MEDIC_link(client, 0, false);
				}
			}
		}
		
		if( g_iPlayerClass[client] == class_pyro ) {
			
			if( g_fCustomWeapon_NextShoot[client][0] <= (GetGameTime()-0.21) ) {
				CTF_WEAPON_FLAME_Fire(client, true);
			}
		}
		
		if( g_iPlayerClass[client] == class_spy ) {
			
			new Float:vecVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
			
			new Float:fSpeed = GetVectorLength(vecVelocity);			
			if( fSpeed > 250.0 )
				fSpeed = 250.0;
			
			if( fSpeed > 50.0 ) {
				g_fDelay[client][0] = GetGameTime() + ((fSpeed/50.0)*1.5);
			}
			
			new Float:fDelay = (g_fDelay[client][0]-GetGameTime())*255.0;
			if( fDelay < 1.0 )
				fDelay = 1.0;
			if( fDelay > 250.0 )
				fDelay = 250.0;
			
			if( fSpeed < 1.0 )
				fSpeed = 1.0;
			
			
			new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( WeaponIndex != -1 ) {
				new Float:fLastAttack = (GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")-GetGameTime()) * 800.0;
				if( fLastAttack < 1.0 )
					fLastAttack = 1.0;
				if( fLastAttack > 150.0 )
					fLastAttack = 150.0;
				
				if( fLastAttack > 50.0 ) {
					g_fDelay[client][1] = GetGameTime() + ((fLastAttack/50.0)*1.5);
				}
				
				new Float:fDelay2 = (g_fDelay[client][1]-GetGameTime())*150.0;
				if( fDelay2 < 1.0 )
					fDelay2 = 1.0;
				if( fDelay2 > 150.0 )
					fDelay2 = 150.0;
				
				new alpha = 100 + RoundToCeil( (fSpeed/250.0) * fDelay * fDelay2 * 150.0 );
				
				if( alpha > 200 )
					alpha = 200;
				
				if( alpha < 10 )
					alpha = 10;
				
				if( g_fUlti_Cooldown[client] > (GetGameTime()+(50.0)) ) {
					Colorize(client, 255, 255, 255, 0);
				}
				else {
					Colorize(client, 255, 255, 255, alpha);
				}
				
				new String:classname[128];
				GetEdictClassname(WeaponIndex, classname, 127);
				
				if( StrEqual(classname, "weapon_usp") ) {
					SetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn", 1);
				}
			}
		}
		
		for(new i=GetMaxClients(); i<2048; i++) {
			if( !g_C4_bIsActive[i] ) 
				continue;
			
			if( g_C4_fExplodeTime[i] <= GetGameTime() ) {
				ExplodeC4(i);
			}
			else {
				if( g_C4_fNextBeep[i] <= GetGameTime() ) {
					
					BeepC4(i);
					
					g_C4_fNextBeep[i] = (  ( g_C4_fExplodeTime[i]-GetGameTime() ) / (2.5*2.0)  );
					if( g_C4_fNextBeep[i] >= 2.5) {
						g_C4_fNextBeep[i] = 2.5;
					}
					g_C4_fNextBeep[i] += GetGameTime();
				}
			}
		}
		CTF_WEAPON_CUSTOM_FRAME(client);
		
		if( g_iContaminated[client] > 0 ) {
			if( g_fContaminate[client] < GetGameTime() ) {
				CTF_MEDIC_HURTS(client);
			}
		}		
		
		if( g_fRestoreSpeed[client][0] < GetGameTime() && g_fRestoreSpeed[client][1] > 0.01 ) {			
			g_flPlayerSpeed[client] = g_fRestoreSpeed[client][1];
			g_fRestoreSpeed[client][1] = -1.0;
		}
		
		SetClientSpeed(client, g_flPlayerSpeed[client]);
		CTF_TP_ACTION(client);
		
		if( g_flCrazyTime[client] > GetGameTime() ) {
			if( GetRandomInt(0, 15) == 1 ) {
				
				new Float:Origin[3];
				new Float:Direction[3];
				
				GetClientAbsOrigin(client, Origin);
				Origin[0] += GetRandomFloat(-255.0, 255.0);
				Origin[0] += GetRandomFloat(-255.0, 255.0);
				Origin[0] += GetRandomFloat( -50.0, 255.0);
				
				Direction[0] = GetRandomFloat();
				Direction[1] = GetRandomFloat();
				Direction[2] = GetRandomFloat();
				
				switch(GetRandomInt(1, 8)) {
					case 1: {
						new Model = PrecacheModel("materials/sprites/old_aexplo.vmt");
						TE_SetupExplosion(Origin, Model, GetRandomFloat(0.5, 2.0), 2, 1, GetRandomInt(25, 100) , GetRandomInt(25, 100) );
						TE_SendToClient(client);
					}
					case 2: {
						TE_SetupDust(Origin, Direction, GetRandomFloat(50.0, 100.0), 10.0);
						TE_SendToClient(client);
					}
					case 3: {
						TE_SetupEnergySplash(Origin, Direction, true);
						TE_SendToClient(client);
					}
					case 4: {
						TE_SetupMetalSparks(Origin, Direction);
						TE_SendToClient(client);
					}
					case 5: {
						TE_SetupSparks(Origin, Direction, GetRandomInt(1, 10), GetRandomInt(1, 10));
						TE_SendToClient(client);
					}
					case 6: {
						TE_SetupArmorRicochet(Origin, Direction);
						TE_SendToClient(client);
					}
					case 7: {
						TE_SetupArmorRicochet(Origin, Direction);
						TE_SendToClient(client);
					}
					case 8: {
						TE_SetupArmorRicochet(Origin, Direction);
						TE_SendToClient(client);
					}
					case 9: {
						TE_SetupMetalSparks(Origin, Direction);
						TE_SendToClient(client);
					}
					default: {
						TE_SetupSparks(Origin, Direction, GetRandomInt(1, 10), GetRandomInt(1, 10));
						TE_SendToClient(client);
					}
				}
			}
		}
		
		for(new i=0; i<MAX_BAGPACK; i++) {
			if( g_BagPack_Data[i][bagpack_data] == 0 )
				continue;
			if( !IsValidEdict( g_BagPack_Data[i][bagpack_ent] ) )
				continue;
			if( !IsValidEntity( g_BagPack_Data[i][bagpack_ent] ) )
				continue;			
			if( g_flBagPack_Last[i] >= GetGameTime() )
				continue;
			if( g_BagPack_Data[i][bagpack_team] != GetClientTeam(client) )
				continue;
			
			GetEntPropVector(g_BagPack_Data[i][bagpack_ent], Prop_Send, "m_vecOrigin", vecOrigin2);
			
			
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 50.0 ) {
				
				g_flBagPack_Last[i] = (GetGameTime() + 1.6);
				
				if( g_BagPack_Data[i][bagpack_type] == 1 ) {
					CTF_FillupAmmunition(client, g_BagPack_Data[i][bagpack_ent], false);
				}
				else {
					CTF_FillupAmmunition(client, g_BagPack_Data[i][bagpack_ent], true);
				}
				
				break;
			}
		}
		
	}
	
	for(new client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) )
			continue;
		
		if( g_iPlayerClass[client] == class_engineer ) {
			if( IsValidSentry( g_iBuild[client][build_sentry] ) ) {
				CTF_SG_Think(client, g_iBuild[client][build_sentry]);
			}
		}
	}
	CTF_FixAngles();
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	
	if( !IsPlayerAlive(client) )
		return Plugin_Continue;
	
	CTF_WEAPON_CUSTOM_ACTION(client, buttons);
	
	return Plugin_Continue;
}  
// ------------------------------------------------------------------------------------------------------------------
//		Hooks - Map Call
//
public AddFileToDownloadsTable2(String:file[1024]) {
	AddFileToDownloadsTable(file);
	ReplaceString(file, sizeof(file), "sound/", "", false);
	PrecacheSound(file);
}
public OnMapStart() {
	
	CTF_Reset_Global();
	
	g_hBDD = SQL_Connect("default", true, g_szError, sizeof( g_szError ));
	if( g_hBDD == INVALID_HANDLE ) {
		SetFailState("Connexion impossible: %s", g_szError);
	}
	
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.dx80.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.vvd");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.dx90.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/flag.sw.vtx");
	
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_blu.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_black.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_neutral.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_black.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_gold.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/chrome_gold.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_neutral.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_blu.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_red.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/tfcflag_red.vtf");
	
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/HumiliatingDefeat.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueFlagTaken.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedFlagDropped.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/YouHaveWonTheMatch.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/FlawlessVictory.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/YouHaveLostTheMatch.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamDominating.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedFlagTaken.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/YouHaveTheFlag.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/TheEnemyHasYourFlag.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamScores.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/FinalRound.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/YouAreOnRed.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/YouAreOnBlue.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamWinsTheRound.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedTeamWinsTheRound.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedTeamTakesTheLead.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueTeamTakesTheLead.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedTeamScores.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/RedFlagReturned.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueFlagReturned.mp3");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/BlueFlagDropped.mp3");
	
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/flagdrop.wav");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/flagreturn.wav");
	AddFileToDownloadsTable2("sound/DeadlyDesire/ctf/flagstolen.wav");
	
	
	AddFileToDownloadsTable("materials/models/weapons/w_rocketlauncher/w_rocketlauncher01_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_rocketlauncher/w_rocketlauncher01.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_rocketlauncher/w_rocketlauncher01.vtf");
	
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.mdl");
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.phy");
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.sw.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_rocketlauncher.vvd");
	
	AddFileToDownloadsTable("sound/weapons/rpg/rocket1.wav");
	
	AddFileToDownloadsTable("materials/models/effects/pyro/pilotlight.vmt");
	AddFileToDownloadsTable("materials/models/effects/pyro/pilotlight.vtf");

	AddFileToDownloadsTable("materials/models/weapons/c_items/c_flamethrower_blue.vmt");
	AddFileToDownloadsTable("materials/models/weapons/c_items/c_flamethrower_blue.vtf");
	AddFileToDownloadsTable("materials/models/weapons/c_items/c_flamethrower.vmt");
	AddFileToDownloadsTable("materials/models/weapons/c_items/c_flamethrower.vtf");
	
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.phy");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.sw.vtx");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.vvd");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.mdl");
	//
	//
	AddFileToDownloadsTable("materials/models/weapons/v_grenadelauncher/v_grenadelauncher.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_grenadelauncher/v_grenadelauncher.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_grenadelauncher/w_grenadelauncher.vmt");
	
	AddFileToDownloadsTable("materials/models/weapons/w_grenade_grenadelauncher/w_grenade_blue.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_grenade_grenadelauncher/w_grenade_blue.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_grenade_grenadelauncher/w_grenade_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_grenade_grenadelauncher/w_grenade_red.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_grenade_grenadelauncher/w_grenade_red.vtf");
	
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.mdl");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.phy");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.sw.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.vvd");
	//
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.sw.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.vvd");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.mdl");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenade_grenadelauncher.phy");
	//
	AddFileToDownloadsTable("materials/models/weapons/w_medigun/w_medigun01_blue.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_medigun/w_medigun01_Blue.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_medigun/w_medigun01.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_medigun/w_medigun01.vtf");
	//
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.mdl");
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.phy");
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.sw.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_medigun.vvd");
	//
	AddFileToDownloadsTable("particles/ctf_01.pcf");
	AddFileToDownloadsTable("particles/ctf_02.pcf");
	AddFileToDownloadsTable("particles/ctf_03.pcf");
	AddFileToDownloadsTable("particles/ctf_04.pcf");
	AddFileToDownloadsTable("particles/ctf_05.pcf");
	//
	AddFileToDownloadsTable("materials/effects/softglow.vtf");
	AddFileToDownloadsTable("materials/effects/medicbeam_curl.vmt");
	AddFileToDownloadsTable("materials/effects/medicbeam_curl.vtf");
	AddFileToDownloadsTable("materials/effects/healsign.vtf");
	AddFileToDownloadsTable("materials/effects/healsign.vmt");
	AddFileToDownloadsTable("materials/effects/sc_softglow.vmt");
	AddFileToDownloadsTable("materials/effects/sc_brightglow_y_nomodel.vmt");
	AddFileToDownloadsTable("materials/effects/brightglow_y.vtf");
	AddFileToDownloadsTable("materials/effects/singleflame.vtf");
	AddFileToDownloadsTable("materials/effects/brightglow_y.vmt");
	AddFileToDownloadsTable("materials/effects/softglow_translucent.vmt");
	AddFileToDownloadsTable("materials/effects/singleflame.vmt");
	AddFileToDownloadsTable("materials/effects/softglow_translucent.vtf");
	AddFileToDownloadsTable("materials/effects/brightglow_y_nomodel.vmt");
	AddFileToDownloadsTable("materials/particle/flameThrowerFire/flamethrowerfire102.vtf");
	AddFileToDownloadsTable("materials/particle/flameThrowerFire/flamethrowerfire102.vmt");
	//
	AddFileToDownloadsTable("materials/effects/circle1.vtf");
	AddFileToDownloadsTable("materials/effects/softglow.vtf");
	AddFileToDownloadsTable("materials/effects/circle1.vmt");
	AddFileToDownloadsTable("materials/effects/circle2.vtf");
	AddFileToDownloadsTable("materials/effects/softglow.vmt");
	AddFileToDownloadsTable("materials/effects/circle.vmt");
	AddFileToDownloadsTable("materials/effects/tp_floorglow.vmt");
	AddFileToDownloadsTable("materials/effects/tp_floorglow.vtf");
	AddFileToDownloadsTable("materials/effects/circle.vtf");
	AddFileToDownloadsTable("materials/effects/circle2.vmt");
	//
	AddFileToDownloadsTable("models/grenades/emp/emp.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/emp/emp.mdl");
	AddFileToDownloadsTable("models/grenades/emp/emp.sw.vtx");
	AddFileToDownloadsTable("models/grenades/emp/emp.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/emp/emp.vvd");
	AddFileToDownloadsTable("models/grenades/emp/emp.phy");
	AddFileToDownloadsTable("models/grenades/conc/conc.sw.vtx");
	AddFileToDownloadsTable("models/grenades/conc/conc.phy");
	AddFileToDownloadsTable("models/grenades/conc/conc.vvd");
	AddFileToDownloadsTable("models/grenades/conc/conc.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/conc/conc.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/conc/conc.mdl");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.sw.vtx");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.mdl");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.xbox.vtx");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.vvd");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/nailgren/nailgren.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.sw.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.mdl");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.vvd");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.phy");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.vvd");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.phy");
	AddFileToDownloadsTable("models/grenades/mirv/mirvlet.sw.vtx");
	AddFileToDownloadsTable("models/grenades/mirv/mirv.mdl");
	AddFileToDownloadsTable("models/grenades/frag/frag.phy");
	AddFileToDownloadsTable("models/grenades/frag/frag.sw.vtx");
	AddFileToDownloadsTable("models/grenades/frag/frag.vvd");
	AddFileToDownloadsTable("models/grenades/frag/frag.mdl");
	AddFileToDownloadsTable("models/grenades/frag/frag.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/frag/frag.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/frag/frag.xbox.vtx");
	AddFileToDownloadsTable("models/grenades/gas/gas.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/gas/gas.vvd");
	AddFileToDownloadsTable("models/grenades/gas/gas.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/gas/gas.phy");
	AddFileToDownloadsTable("models/grenades/gas/gas.mdl");
	AddFileToDownloadsTable("models/grenades/gas/gas.sw.vtx");
	AddFileToDownloadsTable("models/grenades/napalm/napalm.vvd");
	AddFileToDownloadsTable("models/grenades/napalm/napalm.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/napalm/napalm.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/napalm/napalm.sw.vtx");
	AddFileToDownloadsTable("models/grenades/napalm/napalm.mdl");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.phy");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.dx80.vtx");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.sw.vtx");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.vvd");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.xbox.vtx");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.dx90.vtx");
	AddFileToDownloadsTable("models/grenades/caltrop/caltrop.mdl");
	//
	AddFileToDownloadsTable("materials/models/grenades/emp/emp_map.vtf");
	AddFileToDownloadsTable("materials/models/grenades/emp/emp_map.vmt");
	AddFileToDownloadsTable("materials/models/grenades/conc/conc_map_medium.vmt");
	AddFileToDownloadsTable("materials/models/grenades/conc/conc_map_medium.vtf");
	AddFileToDownloadsTable("materials/models/grenades/conc/conc_map_strip.vmt");
	AddFileToDownloadsTable("materials/models/grenades/nailgren/nailgren.vmt");
	AddFileToDownloadsTable("materials/models/grenades/nailgren/nailgren.vtf");
	AddFileToDownloadsTable("materials/models/grenades/mirv/mirv_map.vtf");
	AddFileToDownloadsTable("materials/models/grenades/mirv/mirv_map.vmt");
	AddFileToDownloadsTable("materials/models/grenades/mirv/mirvlet_map.vtf");
	AddFileToDownloadsTable("materials/models/grenades/mirv/mirvlet_map.vmt");
	AddFileToDownloadsTable("materials/models/grenades/frag/fraggrenade.vtf");
	AddFileToDownloadsTable("materials/models/grenades/frag/fraggrenade.vmt");
	AddFileToDownloadsTable("materials/models/grenades/gas/gasgrenade.vtf");
	AddFileToDownloadsTable("materials/models/grenades/gas/gasgrenade.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalmbody.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalmgoo.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalm_dx60.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/naplamcylinder_envmapmask.vtf");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalm_glass.vtf");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalm_envmapmask.vtf");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalm.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalm.vtf");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalmcylinder.vmt");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalmcylinder.vtf");
	AddFileToDownloadsTable("materials/models/grenades/napalm/napalmbody.vtf");
	AddFileToDownloadsTable("materials/models/grenades/caltrop/caltrop.vtf");
	AddFileToDownloadsTable("materials/models/grenades/caltrop/caltrop.vmt");
	//
	AddFileToDownloadsTable("models/projectiles/nail/w_nail.vvd");
	AddFileToDownloadsTable("models/projectiles/nail/w_nail.dx80.vtx");
	AddFileToDownloadsTable("models/projectiles/nail/w_nail.mdl");
	AddFileToDownloadsTable("models/projectiles/nail/w_nail.sw.vtx");
	AddFileToDownloadsTable("models/projectiles/nail/w_nail.dx90.vtx");
	AddFileToDownloadsTable("materials/models/projectiles/nail/nail.vmt");
	AddFileToDownloadsTable("materials/models/projectiles/nail/nail.vtf");
	AddFileToDownloadsTable("materials/effects/fisheyelens_normal.vtf");
	AddFileToDownloadsTable("materials/effects/concrefract.vmt");
	AddFileToDownloadsTable("materials/effects/fisheyelens_dudv.vtf");
	AddFileToDownloadsTable("materials/effects/horizontalglow.vtf");
	AddFileToDownloadsTable("materials/effects/horizontalglow.vmt");

	//
	AddFileToDownloadsTable("sound/grenades/ax1.wav");
	AddFileToDownloadsTable("sound/grenades/conc1.wav");
	AddFileToDownloadsTable("sound/grenades/nail_shoot.wav");
	AddFileToDownloadsTable("sound/grenades/conc2.wav");
	AddFileToDownloadsTable("sound/grenades/emp_explosion.wav");
	AddFileToDownloadsTable("sound/grenades/timer.wav");
	AddFileToDownloadsTable("sound/grenades/gas_explode.wav");
	AddFileToDownloadsTable("sound/grenades/napalm_explode.wav");
	AddFileToDownloadsTable("sound/grenades/bounce.wav");
	//
	PrecacheModel("models/DeadlyDesire/ctf/flag.mdl", true);
	//
	PrecacheModel("models/weapons/w_models/w_rocketlauncher.mdl", true);
	PrecacheModel("models/weapons/w_missile_closed.mdl", true);
	//
	PrecacheModel("models/weapons/c_models/c_flamethrower/c_flamethrower.mdl", true);
	//
	PrecacheModel("models/weapons/w_models/w_grenadelauncher.mdl", true);
	PrecacheModel("models/weapons/w_models/w_grenade_grenadelauncher.mdl", true);
	//
	PrecacheModel("models/weapons/w_models/w_medigun.mdl", true);
	//
	PrecacheModel("models/Weapons/w_c4_planted.mdl", true);
	//
	PrecacheModel("models/grenades/emp/emp.mdl", true);
	PrecacheModel("models/grenades/conc/conc.mdl", true);
	PrecacheModel("models/grenades/nailgren/nailgren.mdl", true);
	PrecacheModel("models/grenades/mirv/mirvlet.mdl", true);
	PrecacheModel("models/grenades/mirv/mirv.mdl", true);
	PrecacheModel("models/grenades/frag/frag.mdl", true);
	PrecacheModel("models/grenades/gas/gas.mdl", true);
	PrecacheModel("models/grenades/napalm/napalm.mdl", true);
	PrecacheModel("models/grenades/caltrop/caltrop.mdl", true);
	PrecacheModel("models/projectiles/nail/w_nail.mdl", true);
	//

	AddFileToDownloadsTable("materials/models/buildables/sentry1/base1.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/base1.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/sentry1_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/Sentry1_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/Sentry1_exponent.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/Sentry1_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/Sentry1_normal.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/sentry1.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry1/Sentry1.vtf");

	AddFileToDownloadsTable("materials/models/buildables/sentry2/base1.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2_exponent.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2_normal.vtf");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2.vmt");
	AddFileToDownloadsTable("materials/models/buildables/sentry2/Sentry2.vtf");
	
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporter_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporter_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporterspin_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporterspin_red.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporter.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleporter.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleportspin_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/teleportspin_red.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_direction1.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_direction1.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_direction.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_direction.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_lights_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_lights_red.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet1.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet1.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet2.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet2.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet_red.vmt");
	AddFileToDownloadsTable("materials/models/buildables/teleporter/tp_sheet_red.vtf");

	AddFileToDownloadsTable("materials/models/buildables/toolbox/toolbox_blue.vmt");
	AddFileToDownloadsTable("materials/models/buildables/toolbox/toolbox_blue.vtf");
	AddFileToDownloadsTable("materials/models/buildables/toolbox/toolbox_red.vmt");
	AddFileToDownloadsTable("materials/models/buildables/toolbox/toolbox_red.vtf");
	
	AddFileToDownloadsTable("models/buildables/sentry1.dx80.vtx");
	AddFileToDownloadsTable("models/buildables/sentry1.dx90.vtx");
	AddFileToDownloadsTable("models/buildables/sentry1.mdl");
	AddFileToDownloadsTable("models/buildables/sentry1.phy");
	AddFileToDownloadsTable("models/buildables/sentry1.sw.vtx");
	AddFileToDownloadsTable("models/buildables/sentry1.vvd");
	AddFileToDownloadsTable("models/buildables/sentry2.dx80.vtx");
	AddFileToDownloadsTable("models/buildables/sentry2.dx90.vtx");
	AddFileToDownloadsTable("models/buildables/sentry2.mdl");
	AddFileToDownloadsTable("models/buildables/sentry2.phy");
	AddFileToDownloadsTable("models/buildables/sentry2.sw.vtx");
	AddFileToDownloadsTable("models/buildables/sentry2.vvd");
	AddFileToDownloadsTable("models/buildables/teleporter_light.dx80.vtx");
	AddFileToDownloadsTable("models/buildables/teleporter_light.dx90.vtx");
	AddFileToDownloadsTable("models/buildables/teleporter_light.mdl");
	AddFileToDownloadsTable("models/buildables/teleporter_light.phy");
	AddFileToDownloadsTable("models/buildables/teleporter_light.sw.vtx");
	AddFileToDownloadsTable("models/buildables/teleporter_light.vvd");

	PrecacheModel("models/buildables/sentry1.mdl", true);
	PrecacheModel("models/buildables/sentry2.mdl", true);
	PrecacheModel("models/buildables/teleporter_light.mdl", true);
	//
	PrecacheSound("weapons/rpg/rocket1.wav", true);
	PrecacheSound("weapons/rpg/rocketfire1.wav", true);
	
	PrecacheSound("weapons/explode3.wav");
	PrecacheSound("weapons/explode4.wav");
	PrecacheSound("weapons/explode5.wav");
	
	PrecacheSound("vo/npc/barney/ba_pain01.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain02.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain03.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain04.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain05.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain06.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain07.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain08.wav", true);
	PrecacheSound("vo/npc/barney/ba_pain09.wav", true);
	
	PrecacheModel("models/combine_turrets/floor_turret.mdl", true);
	PrecacheSound("weapons/c4/c4_beep1.wav", true);
	//
	PrecacheSound("grenades/ax1.wav", true);
	PrecacheSound("grenades/conc1.wav", true);
	PrecacheSound("grenades/nail_shoot.wav", true);
	PrecacheSound("grenades/conc2.wav", true);
	PrecacheSound("grenades/emp_explosion.wav", true);
	PrecacheSound("grenades/timer.wav", true);
	PrecacheSound("grenades/gas_explode.wav", true);
	PrecacheSound("grenades/napalm_explode.wav", true);
	PrecacheSound("grenades/bounce.wav", true);
	
	
	PrecacheSound("npc/turret_floor/shoot1.wav", true);
	PrecacheSound("npc/turret_floor/shoot2.wav", true);
	PrecacheSound("npc/turret_floor/shoot3.wav", true);
	PrecacheSound("npc/turret_floor/die.wav", true);
	PrecacheSound("npc/turret_floor/deploy.wav", true);
	PrecacheSound("npc/turret_floor/retract.wav", true);
	PrecacheSound("npc/turret_floor/alarm.wav", true);
	
	g_cPhysicBeam = PrecacheModel("materials/Sprites/physbeam.vmt");
	g_cShockWave = PrecacheModel("materials/effects/concrefract.vmt");
	g_cShockWave2 = PrecacheModel("materials/sprites/rollermine_shock.vmt");
	g_cSmokeBeam = PrecacheModel("materials/sprites/xbeam2.vmt");
	g_cExplode = PrecacheModel("materials/sprites/old_aexplo.vmt");
	g_cScorch = PrecacheModel("materials/decals/smscorch1.vmt", true);
	g_cGlow = PrecacheModel("sprites/redglow1.vmt");
	//
	//
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("sv_enablebunnyhopping 1");
	ServerCommand("sv_maxvelocity 100000");
	ServerCommand("mp_autokick 0");
	ServerCommand("mp_friendlyfire 1");
	
	CTF_WEAPON_init();
	CTF_LoadFlag();
	
	
	PrecacheParticleSystem("teleportedin_blue");
	PrecacheParticleSystem("teleportedin_red");
	
	g_cScorch = PrecacheDecal("decals/unburrow.vmt", true);
}
public OnMapEnd() {
	
	CloseHandle(g_hBDD);
}