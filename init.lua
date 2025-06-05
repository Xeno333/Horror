horror = {}

local path = core.get_modpath("horror") .. "/"

dofile(path .. "mobs.lua")



local spooks = {
    {sound = {name = "horror_the_entity_attack", pitch = 1.5}, gain_range = {min = 0.2, max = 1}},
    {sound = {name = "horror_breaths_1"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "horror_breaths_2"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "horror_breaths_3"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "horror_whistle_1", pitch = 1.5}, gain_range = {min = 2, max = 4}},
    {sound = {name = "horror_whistle_2", pitch = 1.5}, gain_range = {min = 2, max = 4}},
    {sound = {name = "horror_whistle_2", pitch = 2}, gain_range = {min = 2, max = 4}},
}

local spook_mobs = {
    "horror:the_entity",
    "horror:chaser",
    "horror:reaper"
}

local players_to_spook = {}

function spook()
    for _, name in pairs(players_to_spook) do
        local num = math.random(1, 60)

        if num <= 20 then
            local player = core.get_player_by_name(name)
            local player_pos = player:get_pos()
            local pos = vector.new(math.random(-16, 16)+player_pos.x, math.random(-4, 16)+player_pos.y, math.random(-16, 16)+player_pos.z)

            if num < 3 then
                core.add_entity(pos, spook_mobs[math.random(1, #spook_mobs)])

            elseif num <= 5 then
                core.add_particlespawner({
                    amount = 64,
                    time = 6,
                    texture = "horror_particle_1.png",
                    glow = 14,

                    minpos = pos,
                    maxpos = pos,

                    minvel = vector.new(-2, -2, -2),
                    maxvel = vector.new(2, 2, 2),

                    minexptime = 0.1,
                    maxexptime = 0.5,

                    minsize = 10,
                    maxsize = 40
                })

                core.sound_play({name = "horror_the_entity_attack", gain = 2}, {pos = pos, max_hear_distance = 32}, true)

            elseif num <= 8 then
                local id = player:hud_add({
                    type = "image",
                    text = "horror_particle_1.png",
                    scale = {x = 256, y = 256},
                    alignment = {x = 0.5, y = 0.4}
                })
                core.sound_play({name = "horror_the_entity_attack", gain = 2}, {pos = player_pos, max_hear_distance = 32}, true)
                core.after(0.1, function()
                    if player:is_valid() then
                        player:hud_remove(id)
                    end
                end)

            else
                local spook_selected = spooks[math.random(1, #spooks)]
                local sound = spook_selected.sound
                sound.gain = math.random(10 * spook_selected.gain_range.min, 10 * spook_selected.gain_range.max) / 10
                core.sound_play(sound, {pos = pos, max_hear_distance = 32}, true)
            end
        end
    end

    core.after(5, spook)
end

core.after(5, spook)

core.register_globalstep(function(dtime)
    local connected = core.get_connected_players()
    local time = core.get_timeofday()

    players_to_spook = {}

    for _, player in pairs(connected) do
        if core.get_node(player:get_pos()).param1 < 2 or (time <= 0.2 or time >= 0.8) then
            players_to_spook[#players_to_spook] = player:get_player_name()
        end
    end
end)