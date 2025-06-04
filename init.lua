horror = {}



core.register_entity("horror:the_entity", {
    initial_properties = {
        visual = "sprite",
        textures = {
            "the_entity.png"
        },
        visual_size = {x = 2, y = 4, z = 2},

        pointable = false,
        physical = true,
        is_visible = false,

        collide_with_objects = false,
        collisionbox = {
            -0.5, -1, -0.5,
            0.5, 1, 0.5
        },
        stepheight = 2,

        glow = 14,
    },

    on_activate = function(self, staticdata, dtime_s)
        local pos = self.object:get_pos()
        local near_objects = core.get_objects_inside_radius(pos, 64)

        local player = nil
        for _, obj in pairs(near_objects) do
            if obj:is_valid() and obj:is_player() then
                player = obj
                break
            end
        end
        if player == nil then
            self.object:remove()
            return
        end

        self.player = player:get_player_name()

        core.sound_play({name = "the_entity_spawns", gain = 2}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
        self.sound = core.sound_play({name = "breaths_1", gain = 2}, {pos = self.object:get_pos(), max_hear_distance = 64, loop = true}, false)

        core.after(4, function()
            if self.object:is_valid() then
                local prop = self.object:get_properties()
                prop.is_visible = true
                core.after(1, function()
                    if self.object:is_valid() then
                        self.spawned = true
                    end
                end)
                self.object:set_properties(prop)
            end
        end)
    end,
    on_step = function(self, dtime, moveresult)
        if self.spawned then
            local player = core.get_player_by_name(self.player)
            if not player then
                if self.sound then
                    core.sound_stop(self.sound)
                end
                self.object:remove()
                return
            end

            local player_pos = player:get_pos() + player:get_look_dir()
            local pos = self.object:get_pos()

            local vel = player_pos - pos
            local dist = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)

            if dist > 1 then
                vel.x = math.min(math.max(vel.x, -1), 1) * 16
                vel.z = math.min(math.max(vel.z, -1), 1) * 16
                vel.y = math.min(math.max(vel.y, -1), 1) * 16

                self.object:set_velocity(vel)
            else
                self.spawned = false
                
                local player_lighting = player:get_lighting()
                local exposure = player_lighting.exposure.exposure_correction
                player_lighting.exposure.exposure_correction = -4
                player:set_lighting(player_lighting)

                self.object:set_velocity(vector.new(0, 0, 0))

                core.after(0.5, function()
                    if self.object:is_valid() then
                        if player:is_valid() then
                            if math.random(1, 3) ~= 1 then
                                core.sound_play({name = "the_entity_attack", gain = 2, pitch = 1.5}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                                player:set_hp(0, "slane")
                            else
                                core.sound_play({name = "the_entity_growl", gain = 2, pitch = 0.75}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                            end

                            core.after(0.5, function()
                                if player:is_valid() then
                                    local player_lighting = player:get_lighting()
                                    player_lighting.exposure.exposure_correction = exposure
                                    player:set_lighting(player_lighting)
                                end
                            end)
                        end

                        if self.sound then
                            core.sound_stop(self.sound)
                        end
                        self.object:remove()
                    end
                end)
            end
        end
    end,
    on_deactivate = function(self, removal)
        if self.sound then
            core.sound_stop(self.sound)
        end
    end,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    end,
})

local spooks = {
    {sound = {name = "the_entity_attack", pitch = 1.5}, gain_range = {min = 0.2, max = 1}},
    {sound = {name = "breaths_1"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "breaths_2"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "breaths_3"}, gain_range = {min = 1, max = 3}},
    {sound = {name = "whistle_1"}, gain_range = {min = 2, max = 4}},
    {sound = {name = "whistle_2"}, gain_range = {min = 2, max = 4}},
}


function spook()
    local time = core.get_timeofday()

    if time <= 0.2 or time >= 0.8 then
        local connected = core.get_connected_players()
        for _, player in pairs(connected) do
            local player_pos = player:get_pos()
            local pos = vector.new(math.random(-16, 16)+player_pos.x, math.random(-4, 16)+player_pos.y, math.random(-16, 16)+player_pos.z)

            local num = math.random(1, 20)

            if num < 3 then
                core.add_entity(pos, "horror:the_entity")

            elseif num <= 5 then
                core.add_particlespawner({
                    amount = 64,
                    time = 6,
                    texture = "particle_1.png",
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

                core.sound_play({name = "the_entity_attack", gain = 2}, {pos = pos, max_hear_distance = 32}, true)

            elseif num <= 7 then
                local id = player:hud_add({
                    type = "image",
                    text = "particle_1.png",
                    scale = {x = 256, y = 256},
                    alignment = {x = 0.5, y = 0.4}
                })
                core.sound_play({name = "the_entity_attack", gain = 2}, {pos = player_pos, max_hear_distance = 32}, true)
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

        core.after(5*math.random(1, 5), spook)

    else
        core.after(60, spook)
    end
end

core.after(1, spook)