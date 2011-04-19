#if defined _ctf_events_included
#endinput
#endif
#define _ctf_events_included

#include "ctf.sp"

// ------------------------------------------------------------------------------------------------------------------
//		Hooks -	Connexions Call
//
public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage,	OnTakeDamage);
	
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
	
	SDKHook(client, SDKHook_Touch, CTF_CLIENT_TOUCH);	
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
	CTF_WEAPON_CUSTOM_CLEAN(client);
}

// ------------------------------------------------------------------------------------------------------------------
// 		Hooks - Event
//
public Action:EventRoundStart(Handle:Event, const String:Name[], bool:Broadcast) {
	
	CTF_LoadFlag();
	
	CTF_SpawnFlag(flag_red);
	CTF_SpawnFlag(flag_blue);	
	
	return Plugin_Continue;
}
public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if( g_iLastTeam[client] != GetClientTeam(client) ) {
		if( GetClientTeam(client) == CS_TEAM_CT ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnBlue.mp3\"");
		}
		else if( GetClientTeam(client) == CS_TEAM_T ) {
			ClientCommand(client, "play \"DeadlyDesire/ctf/YouAreOnRed.mp3\"");
		}
	}
	
	g_iLastTeam[client] = GetClientTeam(client);
	
	CTF_WEAPON_CUSTOM_CLEAN(client);
	CTF_CLASS_init(client);
	
	Colorize(client, 255, 255, 255, 255);
	return Plugin_Continue;
}
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast) {
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	g_iRevieveTime[client] = (GetClientCount()*2);
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
	
	g_iBurning[client] = 0;
	g_fBurning[client] = 0.0;
	
	return Plugin_Continue;
}
public EventBulletImpact(Handle:event,const String:name[],bool:dontBroadcast) {
	
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( g_fUlti_Cooldown[attacker] > (GetGameTime()+55.0) ) {
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
		
		if( StrEqual(WeaponName, "weapon_awp", false) ) {
			
			new Float:bulletOrigin[3];
			SDKCall( g_hPosition, attacker, bulletOrigin );
			
			new Float:bulletDestination[3];
			bulletDestination[0] = GetEventFloat( event, "x" );
			bulletDestination[1] = GetEventFloat( event, "y" );
			bulletDestination[2] = GetEventFloat( event, "z" );
			
			new Float:distance = GetVectorDistance( bulletOrigin, bulletDestination );
			
			new Float:percentage = 0.4 / ( distance / 100 );
			
			new Float:newBulletOrigin[3];
			newBulletOrigin[0] = bulletOrigin[0] + ( ( bulletDestination[0] - bulletOrigin[0] ) * percentage );
			newBulletOrigin[1] = bulletOrigin[1] + ( ( bulletDestination[1] - bulletOrigin[1] ) * percentage ) - 0.08;
			newBulletOrigin[2] = bulletOrigin[2] + ( ( bulletDestination[2] - bulletOrigin[2] ) * percentage );
			
			if( GetClientTeam( attacker ) == CS_TEAM_T ) {
				TE_SetupBeamPoints( newBulletOrigin, bulletDestination, g_cPhysicBeam, 0, 0, 0, 0.5, 3.0, 3.0, 1, 0.0, {250, 0, 0, 120}, 0);
			}
			else {
				TE_SetupBeamPoints( newBulletOrigin, bulletDestination, g_cPhysicBeam, 0, 0, 0, 0.5, 3.0, 3.0, 1, 0.0, {0, 0, 250, 120}, 0);
			}
			TE_SendToAll();
		}
	}
	
}
// ------------------------------------------------------------------------------------------------------------------
//		Hooks - GameForwards
//
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	
	new String:classname[128], String:targetname[128];
	GetEdictClassname(inflictor, classname, 127);
	GetEntPropString(inflictor, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if( StrEqual(classname, "trigger_hurt") ) {
		
		if( GetClientTeam(victim) == CS_TEAM_CT ) {
			if( StrEqual(targetname, "ctf_kill_red", false)  )
				return Plugin_Handled;
		}
		if( GetClientTeam(victim) == CS_TEAM_T ) {
			if( StrEqual(targetname, "ctf_kill_blue", false)  )
				return Plugin_Handled;
		}
	}
	
	if( IsValidSentry(victim) ) {
		
		new owner = CTF_SG_GetOwner(victim), Float:vecPos[3];
		
		if( IsValidClient(owner) && IsValidClient(attacker) ) {
			if( GetClientTeam(owner) == GetClientTeam(attacker) ) {
				damage *= 0.2;
			}
		}
		
		if( g_flSentryHealth[victim] >= 200 && (g_flSentryHealth[victim]-damage) < 200 ) {
			
			new ent = AttachParticle(victim, "smoke_gib_01", -1.0);
			
			vecPos[2] += 50.0;
			TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
		}
		if( g_flSentryHealth[victim] >= 100 && (g_flSentryHealth[victim]-damage) < 100 ) {
			
			new ent = AttachParticle(victim, "burning_gib_01", -1.0);
			
			vecPos[2] += 50.0;
			TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
		}
		
		g_flSentryHealth[victim] -= damage;
		
		if( g_flSentryHealth[victim] <= 0 ) {
			
			new Float:vecAngl[3]; vecAngl[0] = 90.0;
			
			SheduleEntityInput(victim, 2.5, "KillHierarchy");
			
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vecPos);
			vecPos[2] += 10.0;
			
			ServerCommand("sm_effect_fading \"%i\" \"2.5\" \"1\"", victim);
			SetEntProp(victim, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
			
			TeleportEntity(victim, vecPos, vecAngl, NULL_VECTOR);
			
		}
		return Plugin_Handled;
	}
	new bool:changed = false;
	
	if( IsValidClient(attacker) ) {
		switch( g_iPlayerClass[attacker] ) {
			case class_scout: {
				damage *= 0.20;
			}
			case class_sniper: {
				damage *= 2.0; 
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
					
					if( StrEqual(classname, "weapon_knife") )
						damage *= 4.0;
					else if( StrEqual(classname, "weapon_usp") ) {
						damage *= 0.0;
						
						g_fRestoreSpeed[victim][0] = (GetGameTime() + 2.0);
						if( g_fRestoreSpeed[victim][1] < 0.01 ) {
							g_fRestoreSpeed[victim][1] = GetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue");
						}
						SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 0.2);
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
		if( g_flNailData[i][1] > 0.0 && g_flNailData[i][1] > GetGameTime() ) {
			
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
				
				if( GetClientTeam(owner) == GetClientTeam(client) )
					continue;
				
				DealDamage(client, GetRandomInt(8, 12), owner);
			}
		}
		if( StrContains(classname, "ctf_nade") == 0 ) {
			new Float:vecAngles[3];
			TeleportEntity(i, NULL_VECTOR, vecAngles, NULL_VECTOR);
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
					if( dist <= 32.0 ) {
						CTF_FlagTouched(client, g_iFlags_Entity[Flag_Type], Flag_Type);
					}
				}
			}
		}
		for(new i=1; i<=2048; i++) {
			if( !IsValidEdict(i) )
				continue;
			if( !IsValidEntity(i) )
				continue;
			
			new String:targetname[128];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if( StrContains(targetname, "red_sec", false) != -1 || StrContains(targetname, "blue_sec", false) != -1 ) {
				
				
				new flag_type = flag_red;
				if( StrContains(targetname, "blue_sec", false) != -1 ) {
					flag_type = flag_blue;
				}
				
				
				new Float:vecSec[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecSec);
				vecSec[2] -= 80.0;
				new Float:dist = GetVectorDistance(vecOrigin, vecSec, false);
				new Float:dist2 = GetVectorDistance(vecOrigin2, vecSec, false);
				
				if( dist <= 32.0 || dist2 <= 32.0 ) {
					
					if( flag_type == 0 && GetClientTeam(client) == CS_TEAM_CT ) {
						
						if( g_iSecu_Status[flag_type] )
							break;
						
						g_iSecu_Status[flag_type] = 1;
						
						ScheduleTargetInput("red_secdoor", 0.0, "Open");
						ScheduleTargetInput("red_secdoor", ((40.0)-(6.0)), "Close");
						
						CreateTimer( ((40.0) + (0.01)), SecuIsActivited, flag_type);
						break;
					}
					if( flag_type == 1 && GetClientTeam(client) == CS_TEAM_T ) {
						
						if( g_iSecu_Status[flag_type] )
							break;
						
						g_iSecu_Status[flag_type] = 1;
						
						ScheduleTargetInput("blue_secdoor", 0.0, "Open");
						ScheduleTargetInput("blue_secdoor", ((40.0)-(6.0)), "Close");
						
						CreateTimer( ((40.0) + (0.01)), SecuIsActivited, flag_type);
						break;
					}
				}
			}
		}
		
		if( g_iPlayerClass[client] == class_sniper ) {
			if( g_fUlti_Cooldown[client] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
				new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				new String:WeaponName[64]; GetEdictClassname(WeaponIndex, WeaponName, 63);
				
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
			
			
			if( IsValidClient(g_iCustomWeapon_Entity2[client][2]) ) {
				
				new target = g_iCustomWeapon_Entity2[client][2];
				
				new Float:fvecOrigin[3], Float:fvecOrigin2[3];
				GetClientAbsOrigin(client, fvecOrigin);
				GetClientAbsOrigin(target, fvecOrigin2);
				
				if( GetVectorDistance(fvecOrigin, fvecOrigin2) >= HEAL_DIST || !IsPlayerAlive(target) ) {
					CTF_WEAPON_MEDIC_link(client, 0);
				}
				else if( g_fCustomWeapon_NextShoot[client][0] <= (GetGameTime()-0.21) ) {
					CTF_WEAPON_MEDIC_link(client, 0);
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
			new Float:fLastAttack = (GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")-GetGameTime()) * 800.0;
			if( fLastAttack < 1.0 )
				fLastAttack = 1.0;
			if( fLastAttack > 250.0 )
				fLastAttack = 250.0;
			
			if( fLastAttack > 50.0 ) {
				g_fDelay[client][1] = GetGameTime() + ((fLastAttack/50.0)*1.5);
			}
			
			new Float:fDelay2 = (g_fDelay[client][1]-GetGameTime())*255.0;
			if( fDelay2 < 1.0 )
				fDelay2 = 1.0;
			if( fDelay2 > 250.0 )
				fDelay2 = 250.0;
			
			new alpha = 100 + RoundToCeil( (fSpeed/250.0) * fDelay * fDelay2 * 155.0 );
			
			if( alpha > 240 )
				alpha = 240;
			
			if( alpha < 100 )
				alpha = 100;
			
			if( g_fUlti_Cooldown[client] > (GetGameTime()+(ULTI_COOLDOWN-ULTI_DURATION)) ) {
				Colorize(client, 255, 255, 255, 0);
			}
			else {
				Colorize(client, 255, 255, 255, alpha);
			}
			
			new String:classname[128];
			GetEdictClassname(WeaponIndex, classname, 127);
			
			if( StrEqual(classname, "weapon_usp") )
				SetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn", 1);
			
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
		
		if( g_iBurning[client] > 0 ) {
			if( g_fBurning[client] < GetGameTime() ) {
				DealDamage(client, GetRandomInt(2, 4), g_iBurning[client], DMG_BURN);
				g_fBurning[client] = (GetGameTime() + GetRandomFloat(0.5, 1.5));
			}
		}
		
		
		if( g_fRestoreSpeed[client][0] < GetGameTime() && g_fRestoreSpeed[client][1] > 0.01 ) {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fRestoreSpeed[client][1] );
			g_fRestoreSpeed[client][1] = -1.0;
		}
		
		if( g_iPlayerClass[client] == class_engineer ) {
			if( IsValidSentry(g_iSentry[client]) ) {
				CTF_SG_Think(client, g_iSentry[client]);
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
public OnMapStart() {
	
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
	
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/HumiliatingDefeat.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagTaken.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagDropped.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveWonTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/FlawlessVictory.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveLostTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamDominating.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagTaken.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouHaveTheFlag.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/TheEnemyHasYourFlag.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamIncreasesTheirLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamWinsTheMatch.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamScores.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/FinalRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouAreOnRed.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/YouAreOnBlue.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamWinsTheRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamWinsTheRound.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamTakesTheLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueTeamTakesTheLead.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedTeamScores.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/RedFlagReturned.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagReturned.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/ctf/BlueFlagDropped.mp3");
	
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
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.mdl");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.phy");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.sw.vtx");
	AddFileToDownloadsTable("models/weapons/c_models/c_flamethrower/c_flamethrower.vvd");
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
	AddFileToDownloadsTable("maps/ctf_schtop_particles.txt");
	AddFileToDownloadsTable("particles/ctf_01.pcf");
	AddFileToDownloadsTable("particles/ctf_02.pcf");
	AddFileToDownloadsTable("particles/ctf_03.pcf");
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
	
	g_cPhysicBeam = PrecacheModel("materials/Sprites/physbeam.vmt");
	g_cShockWave = PrecacheModel("materials/effects/concrefract.vmt");
	g_cShockWave2 = PrecacheModel("materials/sprites/rollermine_shock.vmt");
	g_cSmokeBeam = PrecacheModel("materials/sprites/xbeam2.vmt");
	g_cExplode = PrecacheModel("materials/sprites/old_aexplo.vmt");
	g_cScorch = PrecacheModel("materials/decals/smscorch1.vmt", true);
	//
	//
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("sv_enablebunnyhopping 1");
	ServerCommand("sv_maxvelocity 100000");
	ServerCommand("mp_autokick 0");
	ServerCommand("mp_friendlyfire 1");
	
	CTF_WEAPON_init();
	CTF_LoadFlag();
	
}
