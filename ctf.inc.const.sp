#if defined _ctf_consts_included
#endinput
#endif
#define _ctf_consts_included

#include "ctf.sp"

new Handle:g_hBDD;
new String:g_szQuery[1024];
new String:g_szError[1024];

// ------------------------------
// CTF-CONFIG
//
#define FLAG_SPEED		500.0
// ------------------------------
// ULTIMATE-CONFIG
//
#define ULTI_COOLDOWN	120.0
#define ULTI_DURATION	10.0


// ------------------------------
// DO NOT EDIT BELLOW!
//
#define WALL_FACTOR		1.25
#define CUSTOM_WEAPON	"weapon_tmp"
#define PI				3.141592653589793
#define SENTRY_ANGLES	(0.30)
#define SENTRY_VELOCITY	(0.0025)
#define SENTRY_PRECI	(0.998)
#define MAX_BAGPACK		250

#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT           0x0002        // Fade out (not in)
#define FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one

// ------------------------------
// Enum
//
enum enum_flag_type {
	flag_red = 0,
	flag_blue,
	flag_neutral,
	flag_max
};
enum enum_class_type {
	class_none = 0,
	class_scout,
	class_sniper,
	class_soldier,
	class_demoman,
	class_medic,
	class_hwguy,
	class_pyro,
	class_spy,
	class_engineer,
	class_civilian,
	class_max
}
enum enum_grenade_type {
	grenade_none,
	grenade_caltrop,
	grenade_concussion,
	grenade_frag,
	grenade_nail,
	grenade_mirv,
	grenade_mirvlet,
	grenade_napalm,
	grenade_gas,
	grenade_emp,
	
	grenade_max
}
enum enum_backpack_data {
	
	bagpack_data,
	bagpack_ent,
	bagpack_id,
	bagpack_team,
	bagpack_type,
	bagpack_origin_x,
	bagpack_origin_y,
	bagpack_origin_z,
	bagpack_angle,
	
	bagpack_max
}

new Handle:g_hClassRestriction[class_max];
new g_BagPack_Data[MAX_BAGPACK][bagpack_max];
new Float:g_flBagPack_Last[2048];
// ------------------------------
// FLAGS
//
new g_iFlags_Entity[flag_max];
new g_iFlags_Carrier[flag_max];
new Float:g_vecFlags[flag_max][3];
new Float:g_fFlags_Respawn[flag_max];
// ------------------------------
// SECU
//
new Float:g_vecSecu[flag_max][3];
new g_iSecu_Status[flag_max];
new bool:g_bSecurity = false;
// ------------------------------
// SCORES
//
new g_iScore[2];
// ------------------------------
// PLAYER
//
new g_iLastTeam[65];
new g_iRevieveTime[65];
new g_iPlayerArmor[65];
new enum_class_type:g_iPlayerClass[65];
new Float:g_fLastDrop[65];
new Float:g_fUlti_Cooldown[65];
new Float:g_flPlayerSpeed[65];
// ------------------------------
// Grenade
//
new g_iPlayerGrenadeAmount[65][2];
new Float:g_flPrimedTime[2048];
new enum_grenade_type:g_iGrenadeType[2048];
new Float:g_flNailData[2048][2];
new Float:g_flGasLastDamage[65];


// ------------------------------
// CUSTOM WEAPON
//
new g_iCustomWeapon_Entity[65][2];
new g_iCustomWeapon_Entity2[65][3];
new Float:g_flCustomWeapon_Entity3[2049];
new g_iCustomWeapon_Ammo[65][2];
new bool:g_bIsCustomWeapon[2049];
new Float:g_fCustomWeapon_NextShoot[65][3];
// ------------------------------
// OFFSET
//
new g_iOffset_armor = -1;
new g_iOffset_WeaponParent = -1;
new g_iOffset_money = -1;
// ------------------------------
// SDK-CALL HANDLE
//
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hPosition = INVALID_HANDLE;
// ------------------------------
// PRECACHE
//
new g_cPhysicBeam;
new g_cShockWave;
new g_cShockWave2;
new g_cSmokeBeam;
new g_cExplode;
new g_cScorch;
// ------------------------------
// Class: Artificier
//
new Float:g_C4_fExplodeTime[2048];
new Float:g_C4_fNextBeep[2048];
new bool:g_C4_bIsActive[2048];
// ------------------------------
// Class: Medic
//
new g_iContaminated[65];
new Float:g_fContaminate[65];
#define HEAL_DIST		300.0
// ------------------------------
// Class: Pyroman
//
new g_iBurning[65]; 
new Float:g_fBurning[65];
// ------------------------------
// Class: Espion
//
new Float:g_fDelay[65][2];
new Float:g_fRestoreSpeed[65][2];
new Float:g_flCrazyTime[65];
// ------------------------------
// Class: Ingenieur
//
// ---------- Sentry-Gun --------

#define build_sentry			0
#define	build_teleporter_in		1
#define build_teleporter_out	2
#define build_max				3

new g_iBuild[65][build_max];
new Float:g_flBuildHealth[2048][build_max];
new Float:g_flBuildThink[2048][build_max];
new Float:g_flBuildThink2[2048][build_max];

new Float:g_flSentryAngles[2048][2];
new g_iSentryAngles[2048][2];
new g_iSentryTarget[2048];
new g_iSentryLevel[2048];
new Float:g_flMetal[65];
