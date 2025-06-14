


core.register_entity("horror:lightning", {
    initial_properties = {
        visual = "upright_sprite",
        textures = {
            "horror_lightning.png",
            "horror_lightning.png"
        },
        visual_size = {x = 2, y = 64, z = 2},

        pointable = false,
        physical = false,
        is_visible = true,


        glow = 14,
    },

    on_activate = function(self, staticdata, dtime_s)
        self.object:set_rotation(vector.new(math.random(0, 50) / 100, math.random(0, 314) / 100, 0))
    
        core.sound_play({name = "horror_lightning", gain = 4, pitch = 0.2}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)

        core.after(0.5, function()
            core.sound_play({name = "horror_thunder", gain = 4, pitch = 0.5}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
            if self.object:is_valid() then
                self.object:remove()
            end
        end)
    end,
    on_deactivate = function(self, removal)
        if not removal then
            self.object:remove()
        end
    end,
})




core.register_entity("horror:the_entity", {
    initial_properties = {
        visual = "sprite",
        textures = {
            "horror_the_entity.png"
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

        core.sound_play({name = "horror_the_entity_spawns", gain = 2}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
        self.sound = core.sound_play({name = "horror_breaths_1", gain = 2}, {pos = self.object:get_pos(), max_hear_distance = 64, loop = true}, false)

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
                self.object:remove()
                return
            end

            local player_pos = player:get_pos() + player:get_look_dir()
            local pos = self.object:get_pos()

            local vel = player_pos - pos
            local dist = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)

            if dist > 1 and not self.attacking then
                local v = vector.new(vel.x / dist, vel.y / dist, vel.z / dist)
                self.object:set_velocity(v * 16)
            else
                self.attacking = true
                
                local player_lighting = player:get_lighting()
                local exposure = player_lighting.exposure.exposure_correction
                player_lighting.exposure.exposure_correction = -4
                player:set_lighting(player_lighting)

                self.object:set_velocity(vector.new(0, 0, 0))

                core.after(0.5, function()
                    if self.object:is_valid() then
                        if player:is_valid() then
                            if math.random(1, 3) ~= 1 then
                                core.sound_play({name = "horror_the_entity_attack", gain = 2, pitch = 1.5}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                                player:set_hp(0, "slane")
                            else
                                core.sound_play({name = "horror_the_entity_growl", gain = 2, pitch = 0.75}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                            end

                            core.after(0.5, function()
                                if player:is_valid() then
                                    local player_lighting = player:get_lighting()
                                    player_lighting.exposure.exposure_correction = exposure
                                    player:set_lighting(player_lighting)
                                end
                            end)
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
        if not removal then
            self.object:remove()
        end
    end,
})


core.register_entity("horror:chaser", {
    initial_properties = {
        visual = "sprite",
        textures = {
            "horror_chaser.png"
        },
        visual_size = {x = 2, y = 4, z = 2},

        pointable = false,
        physical = true,
        is_visible = true,

        collide_with_objects = false,
        collisionbox = {
            -0.5, -1, -0.5,
            0.5, 1, 0.5
        },
        stepheight = 2,
        makes_footstep_sound = true,

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

        core.after(4 * math.random(1, 4), function()
            if self.object:is_valid() then
                self.attacking = true
                self.object:set_velocity(vector.new(0, 0, 0))

                core.sound_play({name = "horror_the_entity_attack", gain = 2, pitch = 0.5}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                core.after(0.25, function()
                    if self.object:is_valid() then
                        self.object:set_pos(player:get_pos() + player:get_look_dir())
                    end
                end)
                core.after(1, function()
                    if self.object:is_valid() then
                        self.object:remove()
                    end
                end)
            end
        end)
    end,
    on_step = function(self, dtime, moveresult)
        if not self.attacking then
            local player = core.get_player_by_name(self.player)
            if not player then
                self.object:remove()
                return
            end

            if not self.whistled and math.random(1, 2) == 1 then
                core.sound_play({name = "horror_whistle_2", gain = 4, pitch = 2}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)
                self.whistled = true
            end

            local player_pos = player:get_pos() + player:get_look_dir()
            local pos = self.object:get_pos()

            local vel = player_pos - pos
            local dist = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)

            if dist > 10 then
                local v = vector.new(vel.x / dist, vel.y / dist, vel.z / dist)
                self.object:set_velocity(v * 4)
            else
                self.object:set_velocity(vector.new(0, -9, 0))
            end
        end
    end,
    on_deactivate = function(self, removal)
        if not removal then
            self.object:remove()
        end
    end,
})




core.register_entity("horror:reaper", {
    initial_properties = {
        visual = "sprite",
        textures = {
            "horror_reaper.png"
        },
        visual_size = {x = 2, y = 4, z = 2},

        pointable = false,
        physical = false,
        is_visible = true,

        collide_with_objects = false,
        collisionbox = {
            -0.5, -1, -0.5,
            0.5, 1, 0.5
        },

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
        if math.random(1, 2) == 1 then
            core.sound_play({name = "horror_chains_1", gain = 8, pitch = 0.5}, {pos = player:get_pos(), max_hear_distance = 16}, true)
        end

        core.after(16, function()
            if self.object:is_valid() then
                if math.random(1, 5) ~= 1 then
                    self.object:remove()

                else
                    core.sound_play({name = "horror_the_entity_attack", gain = 2, pitch = 0.5}, {pos = self.object:get_pos(), max_hear_distance = 64}, true)

                    core.after(0.25, function()
                        if self.object:is_valid() then
                            self.object:set_pos(player:get_pos() + player:get_look_dir())
                        end
                    end)
                    core.after(1, function()
                        if self.object:is_valid() then
                            self.object:remove()

                            if player:is_valid() then
                                player:set_hp(0, "reaped")
                            end
                        end
                    end)
                end
            end
        end)
    end,
    on_step = function(self, dtime, moveresult)
        local player = core.get_player_by_name(self.player)
        if not player then
            self.object:remove()
            return
        end

        local player_pos = player:get_pos() + player:get_look_dir()
        local pos = self.object:get_pos()

        local vel = player_pos - pos
        local dist = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)

        if dist > 16 then
            local v = vector.new(vel.x / dist, vel.y / dist, vel.z / dist)
            self.object:set_velocity(v * 4)
        else
            self.object:set_velocity(vector.new(0, 0, 0))
        end
    end,
    on_deactivate = function(self, removal)
        local pos = self.object:get_pos()
        core.add_entity(pos + vector.new(1, 0, 0), "horror:lightning")
        core.add_entity(pos, "horror:lightning")
        core.add_entity(pos + vector.new(0, 0, 1), "horror:lightning")

        if not removal then
            self.object:remove()
        end
    end,
})
