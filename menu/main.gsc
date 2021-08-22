#include scripts\codescripts\struct;
#include scripts\shared\callbacks_shared;
#include scripts\shared\clientfield_shared;
#include scripts\shared\math_shared;
#include scripts\shared\system_shared;
#include scripts\shared\util_shared;
#include scripts\shared\hud_util_shared;
#include scripts\shared\hud_message_shared;
#include scripts\shared\hud_shared;
#include scripts\shared\array_shared;
#include scripts\shared\aat_shared;
#include scripts\shared\rank_shared;
#include scripts\shared\ai\zombie_utility;
#include scripts\shared\ai\systems\gib;
#include scripts\shared\tweakables_shared;
#include scripts\shared\ai\systems\shared;
#include scripts\shared\ai\systems\blackboard;
#include scripts\shared\ai\systems\ai_interface;
#include scripts\shared\flag_shared;
#include scripts\shared\scoreevents_shared;
#include scripts\shared\lui_shared;
#include scripts\shared\scene_shared;
#include scripts\shared\vehicle_ai_shared;
#include scripts\shared\vehicle_shared;
#include scripts\shared\exploder_shared;
#include scripts\shared\ai_shared;
#include scripts\shared\doors_shared;
#include scripts\shared\gameskill_shared;
#include scripts\shared\spawner_shared;
#include scripts\shared\damagefeedback_shared;
#include scripts\shared\laststand_shared;
#include scripts\shared\visionset_mgr_shared;
#include scripts\shared\ai\systems\destructible_character;
#include scripts\shared\audio_shared;
#include scripts\shared\gameobjects_shared;

#include scripts\zm\gametypes\_hud_message;
#include scripts\zm\_util;
#include scripts\zm\_zm_zonemgr;
#include scripts\zm\_zm;
#include scripts\zm\_zm_bgb;
#include scripts\zm\_zm_score;
#include scripts\zm\_zm_stats;
#include scripts\zm\gametypes\_globallogic;
#include scripts\zm\gametypes\_globallogic_audio;
#include scripts\zm\gametypes\_globallogic_score;
#include scripts\zm\_zm_weapons;
#include scripts\zm\_zm_perks;
#include scripts\zm\_zm_equipment;
#include scripts\zm\_zm_utility;
#include scripts\zm\_zm_blockers;
#include scripts\zm\craftables\_zm_craftables;
#include scripts\zm\_zm_powerups;
#include scripts\zm\_zm_audio;
#include scripts\zm\_zm_spawner;
#include scripts\zm\_zm_playerhealth;
#include scripts\zm\_zm_magicbox;
#include scripts\zm\_zm_unitrigger;
#include scripts\zm\bgbs\_zm_bgb_reign_drops;
#include scripts\zm\_zm_lightning_chain;
#include scripts\zm\_zm_powerup_fire_sale;
#include scripts\zm\_zm_laststand;
#include scripts\zm\_zm_bgb_token;
#include scripts\zm\_zm_bgb_machine;

#include scripts\shared\weapons\replay_gun;

#namespace duplicate_render;

/*
    Hashed string needs a '#' symbol
    namespace needs to turn into 'hash'
*/

autoexec __init__sytem__()
{
    system::register("duplicate_render", ::__init__, undefined, undefined);
}

__init__()
{
    callback::on_start_gametype(::init);
    callback::on_connect(::onPlayerConnect);
    callback::on_spawned(::onPlayerSpawned);
    
    level thread FastQuitMonitor();
}

init()
{
    level loadarrays();
    level thread createRainbowColor();
    
    level.strings  = [];
    level.status   = strTok("None;VIP;Admin;Co-Host;Host", ";");
    level.menuName = "Sub Version 2.1.1";

    level.player_out_of_playable_area_monitor = 0;
}

onPlayerConnect()
{
    if(self isHost())
    {
        self FreezeControls( false );
        self thread initializeSetup( 4, self );
    }
}

onPlayerSpawned()
{    
    level flag::wait_till("initial_blackscreen_passed");
    self notify("stop_player_out_of_playable_area_monitor");

    if(IsDefined(self.overridePlayerDamage))
    {
        level._overridePlayerDamage = self.overridePlayerDamage;
        self.overridePlayerDamage  = ::_player_damage_override_wrapper;
    }    
    if(isDefined(level.gungame_active))
        self player_initialize_gungame();
}

print_stringtable()
{
    results = [];
    for(e=190;e<256;e++)
    {
        string = tableLookupIString( "gamedata/stats/zm/zm_statstable.csv", 0, e, 3 );
        iPrintLnBold(string);
        wait .2;
    }
}

get_zombie_health()
{
    while(true)
    {
        foreach( zombie in getAIArray() )
        {
            if(isdefined(zombie))
                zombie zombie_healthbar(self, self.origin, 360000);
        }
        wait .1;
    }
}

zombie_healthbar(player, pos, dsquared)
{
    if(DistanceSquared(pos, self.origin) > dsquared)
        return;
    
    rate = 1;
    if(isdefined(self.maxhealth))
        rate = self.health / self.maxhealth;
    
    text = "Current Zombies Health: " + Int(self.health);

    dx = worldToScreen( player getPlayerAngles(), self.origin )[0];
    dy = worldToScreen( player getPlayerAngles(), self.origin )[1];

    if(!isDefined(player.zombie_health_bar))
        player.zombie_health_bar = player createText("hudsmall", 1, "CENTER", "CENTER", dx, dy, 3, 1, text, (1 - rate, rate, 0));  
    else 
    {
        player.zombie_health_bar setText( text );
        player.zombie_health_bar.color = (1 - rate, rate, 0);
        player.zombie_health_bar hud::setPoint("CENTER", "CENTER", dx, dy);
    }
    iPrintLnBold( dx, " ", dy );
}

worldToScreen( camera, to )
{
    F = to[2] - camera[2];
    Z = to[2];

    X = to[0];
    Xc = camera[0];
    X = ((X - Xc) * (F/Z)) + Xc;
    
    Y = to[1];
    Yc = camera[1];
    Y = ((Y - Yc) * (F/Z)) + Yc;

    return array(X, Y);
}

FastQuitMonitor()
{
    level notify("fastquitmonitor");
    level endon("fastquitmonitor");
    level util::waittill_any("end_game", "game_ended");
    exitLevel(0);
}