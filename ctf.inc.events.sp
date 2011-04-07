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
		
		if( StrContains(targetname, "red", false) != -1 ) {
			if( GetClientTeam(victim) == CS_TEAM_T )
				return Plugin_Handled;
		}
		else if( StrContains(targetname, "blue", false) != -1 ) {
			if( GetClientTeam(victim) == CS_TEAM_CT )
				return Plugin_Handled;
		}
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
				damage *= 10.0;
			}
			case class_engineer: {
				damage *= 0.5;
			}
			case class_civilian: {
				damage *= 1.0;
			}
			default: {
				damage *= 0.0;
			}
		}
		changed = true;
	}
	if( g_iPlayerArmor[victim] >= 1 ) {
		
		
		damage = damage * 0.8;
		
		new health = GetClientHealth(victim);
		
		g_iPlayerArmor[victim] = (g_iPlayerArmor[victim] - RoundToFloor(damage / 10.0 * 8.0));
		health = (health - RoundToFloor( damage / 10.0 * 6.0 ));
		
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
	
	if( changed )
		return Plugin_Changed;
	
	return Plugin_Continue;
}
// ------------------------------------------------------------------------------------------------------------------
//		Hooks - Think
//
public OnGameFrame() {
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
					GetEntPropVector(g_iFlags_Physics[Flag_Type], Prop_Send, "m_vecOrigin", vecFlag);
					
					
					new Float:dist = GetVectorDistance(vecOrigin, vecFlag, false);
					if( dist <= 32.0 ) {
						CTF_FlagTouched(client, g_iFlags_Entity[Flag_Type], Flag_Type);
					}
				}
				
				if( IsValidClient(g_iFlags_Carrier[Flag_Type]) && g_iFlags_Carrier[Flag_Type] == client ) {
					
					new Reverse_Flag_Type = 0;
					
					if( Flag_Type == 0 ) {
						Reverse_Flag_Type = 1;
					}
					
					new Float:vecMins[3], Float:vecMaxs[3];
					for(new i=0; i<=2; i++) {
						vecMins[i] = g_fCapMins[i] + g_vecFlags[Reverse_Flag_Type][i];
						vecMaxs[i] = g_fCapMaxs[i] + g_vecFlags[Reverse_Flag_Type][i];
						
					}
					
					if( PointInArea(vecOrigin, vecMins, vecMaxs) ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
					}
					else if( PointInArea(vecOrigin2, vecMins, vecMaxs) ) {
						CTF_Score(client, Flag_Type, Reverse_Flag_Type);
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
	
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.sw.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.phy");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.vvd");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.dx80.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/ctf/cap_point_base.dx90.vtx");
	
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_red.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_blue.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_normal.vtf");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_blue.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/ctf/cap_point_base_red.vmt");
	
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
	
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.mdl");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.phy");
	AddFileToDownloadsTable("models/weapons/w_models/w_grenadelauncher.vtx");
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
	//
	PrecacheModel("models/DeadlyDesire/ctf/flag.mdl", true);
	PrecacheModel("models/DeadlyDesire/ctf/cap_point_base.mdl", true);
	PrecacheModel("models/props/cs_assault/barrelwarning.mdl", true);
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
	
	PrecacheSound("weapons/rpg/rocket1.wav", true);
	PrecacheSound("weapons/rpg/rocketfire1.wav", true);
	
	PrecacheSound("weapons/explode3.wav");
	PrecacheSound("weapons/explode4.wav");
	PrecacheSound("weapons/explode5.wav");
	
	PrecacheSound("weapons/c4/c4_beep1.wav", true);
	
	g_cPhysicBeam = PrecacheModel("materials/Sprites/physbeam.vmt");
	g_cSmokeBeam = PrecacheModel("materials/sprites/xbeam2.vmt");
	g_cExplode = PrecacheModel("materials/sprites/old_aexplo.vmt");
	//
	//
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("sv_enablebunnyhopping 1");
	ServerCommand("sv_maxvelocity 100000");
	ServerCommand("mp_autokick 0");
	ServerCommand("mp_friendlyfire 1");
	
	CTF_WEAPON_init();
	BDD_LoadFlag();
	
}
public OnMapEnd() {
	CloseHandle(g_hBDD);
}
