#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <zombieplague>
#include <fun>
#include <fakemeta_util>

#define PLUGINNAME		"[ZP] Extra Item: Dynamite Zombie"
#define VERSION		   "0.1"
#define AUTHOR			"Zombie-rus"

new g_dynam,  g_maxplayers, 
spr_smoke_steam1,cvar_max_damage,cvar_damage_radius,mdl_gib_legbone,
mdl_gib_flesh,mdl_gib_meat,mdl_gib_head,spr_blood_drop,spr_blood_spray
new bool:lamuerteexplosiva[33] = false

new g_icon[33][16], g_status

new const beep_sound [ ] = "weapons/c4_beep5.wav"
new spr_zerogxplode
new gmsgDeathMsg,gmsgScoreInfo,mdl_gib_lung,mdl_gib_spine

public plugin_init()
{  
	register_plugin(PLUGINNAME, VERSION, AUTHOR)

	cvar_max_damage = register_cvar("zp_boomer_maxdmg","1000")
	cvar_damage_radius = register_cvar("zp_boomer_raius","500")

	register_event("DeathMsg", "boomer_death", "a")

	gmsgDeathMsg = get_user_msgid("DeathMsg")
	gmsgScoreInfo = get_user_msgid("ScoreInfo")

	g_maxplayers = get_maxplayers() 
	g_status = get_user_msgid("StatusIcon")
}
public plugin_precache() 
{
	g_dynam = zp_register_extra_item("Dynamite Zombie", 5000, ZP_TEAM_ZOMBIE)  

	//Models Precache
	//[RU] ������� �������
	mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
	mdl_gib_meat = precache_model("models/GIB_B_Gib.mdl")
	mdl_gib_head = precache_model("models/GIB_Skull.mdl")
	mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
	mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
	mdl_gib_legbone = precache_model("models/GIB_Legbone.mdl")

	//Sprites Precache
	//[RU] ������� ��������
	spr_blood_drop = precache_model("sprites/blood.spr")
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_zerogxplode = precache_model("sprites/zerogxplode.spr")
	spr_smoke_steam1 = precache_model("sprites/steam1.spr")

	//Sound Precache
	//[RU] ������� ������
	precache_sound ( beep_sound )
	precache_sound("weapons/mortarhit.wav")
}
public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_dynam)
	{
		lamuerteexplosiva[player] = true
		fm_set_rendering(player, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16);
		//Play beep c4 sound
		client_cmd ( player, "spk %s", beep_sound )

		//Added Icon
		set_icon(player)
	}
}

public zp_user_humanized_post(player)
{
	lamuerteexplosiva[player] = false
}

public boomer_death() 
{ 
	new attacker = read_data(1)
	new victim = read_data(2)

	if (lamuerteexplosiva[victim])
	{ 
		static victim_name[33]
		static attacker_name[33]

		get_user_name(victim, victim_name, sizeof victim_name -1)
		get_user_name(attacker, attacker_name, sizeof attacker_name -1)

		new Float:origin[3], origin2[3]
		entity_get_vector(victim,EV_VEC_origin,origin)

		origin2[0] = floatround(origin[0])
		origin2[1] = floatround(origin[1])
		origin2[2] = floatround(origin[2]) 

		for (new id2; id2 <= g_maxplayers; id2++)
		{
			if (zp_get_user_zombie(id2) && !zp_get_user_nemesis(id2))
			{ 
				emit_sound(victim, CHAN_WEAPON, "weapons/mortarhit.wav", 1.0, 0.5, 0, PITCH_NORM)
				emit_sound(victim, CHAN_VOICE, "weapons/mortarhit.wav", 1.0, 0.5, 0, PITCH_NORM) 

				for (new e = 1; e < 8; e++)
				{
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
					write_byte(TE_SPRITE)
					write_coord(origin2[0] + random_num(-60,60))
					write_coord(origin2[1] + random_num(-60,60))
					write_coord(origin2[2] +128)
					write_short(spr_zerogxplode)
					write_byte(random_num(30,65))
					write_byte(255)
					message_end()
				}

				for (new e = 1; e < 3; e++)
				{
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
					write_byte(TE_SMOKE)
					write_coord(origin2[0])
					write_coord(origin2[1])
					write_coord(origin2[2] + 256)
					write_short(spr_smoke_steam1)
					write_byte(random_num(80,150))
					write_byte(random_num(5,10))
					message_end()
				}
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_GUNSHOTDECAL)
				write_coord(origin2[0])
				write_coord(origin2[1])
				write_coord(origin2[2])
				write_short(0)			
				write_byte(random_num(46,48))  // decal
				message_end()
				
				new Max_Damage = get_pcvar_num(cvar_max_damage)
				new Damage_Radius = get_pcvar_num(cvar_damage_radius)  
				new PlayerPos[3], Distance, Damage

				for (new i = 1; i < 32; i++)
				{
					if (is_user_alive(i) == 1)
					{
						get_user_origin(i, PlayerPos)

						Distance = get_distance(PlayerPos, origin2)

						if (Distance <= Damage_Radius) {
							
							message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, i)
							write_short(1<<14)
							write_short(1<<14)
							write_short(1<<14)
							message_end()

							Damage = Max_Damage - floatround(floatmul(float(Max_Damage), floatdiv(float(Distance), float(Damage_Radius))))

							do_victim(i, victim, Damage, 0)
						}
					}
				}
			}
		}
		lamuerteexplosiva[victim] = false
	}
}
public do_victim (victim,attacker,Damage,team_kill)
{
	new namek[32],namev[32],authida[35],authidv[35],teama[32],teamv[32]
	
	get_user_name(victim,namev,31)
	get_user_name(attacker,namek,31)
	get_user_authid(victim,authidv,34)
	get_user_authid(attacker,authida,34)
	get_user_team(victim,teamv,31)
	get_user_team(attacker,teama,31)

	if (Damage >= get_user_health(victim))
	{

		if (get_cvar_num("mp_logdetail") == 3)
		{
			log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"bomber^" (hit ^"chest^") (Damage ^"%d^") (health ^"0^")",
			namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv,Damage)
		}

		if (team_kill == 0)
		{
			set_user_frags(attacker,get_user_frags(attacker) + 1 )
		}
		
		set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
		set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
		
		user_kill(victim, 1)
		
		replace_dm(attacker,victim,0)
		
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"bomber^"",
		namek,get_user_userid(attacker),authida,teama,namev,get_user_userid(victim),authidv,teamv)
		
		if (Damage > 100)
		{			
			new iOrigin[3]
			
			get_user_origin(victim, iOrigin)
			
			set_user_rendering(victim,kRenderFxNone,0,0,0,kRenderTransAlpha,0)
			
			fx_gib_explode(iOrigin,3)
			fx_blood_large(iOrigin,5)
			fx_blood_small(iOrigin,15)

			iOrigin[2] = iOrigin[2] - 20

			set_user_origin(victim, iOrigin)
		}
	}
	else 
	{
		set_user_health(victim,get_user_health(victim) - Damage )

		if (get_cvar_num("mp_logdetail") == 3)
		{
			log_message("^"%s<%d><%s><%s>^" attacked ^"%s<%d><%s><%s>^" with ^"bomber^" (hit ^"chest^") (Damage ^"%d^") (health ^"%d^")",
			namek, get_user_userid(attacker), authida, teama, namev, get_user_userid(victim), authidv, teamv, Damage, get_user_health(victim))
		}
	}
}
public client_disconnect(id) 
{
	lamuerteexplosiva[id] = false
}  

public client_putinserver(id) 
{
	lamuerteexplosiva[id] = false
}  

public replace_dm(id, tid, tbody)
{
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()
	
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(tid)
	write_short(get_user_frags(tid))
	write_short(get_user_deaths(tid))
	write_short(0)
	write_short(get_user_team(tid))
	message_end()
	
	if (tbody == 1)
	{
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(id)
		write_byte(tid)
		write_string(" missile")
		message_end()
	}
	else
	{
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(id)
		write_byte(tid)
		write_byte(0)
		write_string("missile")
		message_end()
	}
	return PLUGIN_CONTINUE
}
static fx_blood_small (origin[3],num)
{
	for (new j = 0; j < num; j++)
	{	
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-100,100))
		write_coord(origin[1]+random_num(-100,100))
		write_coord(origin[2]-36)

		write_byte(random_num(190,197)) // Blood decals

		message_end()	
	}
}
static fx_blood_large (origin[3],num)
{
	for (new i = 0; i < num; i++)
	{	
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0] + random_num(-50,50))
		write_coord(origin[1] + random_num(-50,50))
		write_coord(origin[2]-36)

		write_byte(random_num(204,205)) // Blood decals

		message_end()
	}
}
static fx_gib_explode (origin[3],num)
{	
	new flesh[3], x, y, z
	flesh[0] = mdl_gib_flesh
	flesh[1] = mdl_gib_meat
	flesh[2] = mdl_gib_legbone
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(random_num(-100,100))
	write_coord(random_num(-100,100))
	write_coord(random_num(100,200))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head)
	write_byte(0)
	write_byte(500)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(random_num(-100,100))
	write_coord(random_num(-100,100))
	write_coord(random_num(100,200))
	write_angle(random_num(0,360))
	write_short(mdl_gib_spine)
	write_byte(0)
	write_byte(500)
	message_end()
	
	for(new i = 0; i < random_num(1,2); i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(random_num(-100,100))
		write_coord(random_num(-100,100))
		write_coord(random_num(100,200))
		write_angle(random_num(0,360))
		write_short(mdl_gib_lung)
		write_byte(0)
		write_byte(500)
		message_end()
	}
	for(new i = 0; i < 5; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(random_num(-100,100))
		write_coord(random_num(-100,100))
		write_coord(random_num(100,200))
		write_angle(random_num(0,360))
		write_short(flesh[random_num(0,2)])
		write_byte(0)
		write_byte(500)
		message_end()
	}
	for(new i = 0; i < num; i++)
	{	
		x = random_num(-100,100)
		y = random_num(-100,100)
		z = random_num(0,100)
		
		for(new j = 0; j < 5; j++)
		{	
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(x*j))
			write_coord(origin[1]+(y*j))
			write_coord(origin[2]+(z*j))
			write_short(spr_blood_spray)
			write_short(spr_blood_drop)
			write_byte(248)
			write_byte(15)
			message_end()
		}
	}
}
public set_icon(player)
{
	static color[3], sprite[16]
	color = {255, 0, 0}
	sprite = "dmg_rad"
	g_icon[player] = sprite

	message_begin(MSG_ONE, g_status, {0, 0, 0}, player)
	write_byte(1)
	write_string(g_icon[player])
	write_byte(color[0])
	write_byte(color[1])
	write_byte(color[2])
	message_end()
}