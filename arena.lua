Arena = Object:extend()
Arena:implement(State)
Arena:implement(GameObject)
function Arena:init(name)
  self:init_state(name)
  self:init_game_object()
end


function Arena:on_enter(from, level, units, passives)
  self.hfx:add('condition1', 1)
  self.hfx:add('condition2', 1)
  self.level = level or 1
  self.units = units
  self.passives = passives

  trigger:tween(2, main_song_instance, {volume = 0.5, pitch = 1}, math.linear)

  steam.friends.setRichPresence('steam_display', '#StatusFull')
  steam.friends.setRichPresence('text', 'Arena - Level ' .. self.level)

  self.floor = Group()
  self.main = Group():set_as_physics_world(32, 0, 0, {'player', 'enemy', 'projectile', 'enemy_projectile'})
  self.post_main = Group()
  self.effects = Group()
  self.ui = Group()
  self.credits = Group()
  self.main:disable_collision_between('player', 'player')
  self.main:disable_collision_between('player', 'projectile')
  self.main:disable_collision_between('player', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'projectile')
  self.main:disable_collision_between('projectile', 'enemy_projectile')
  self.main:disable_collision_between('projectile', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy')
  self.main:disable_collision_between('enemy_projectile', 'enemy_projectile')
  self.main:enable_trigger_between('projectile', 'enemy')
  self.main:enable_trigger_between('enemy_projectile', 'player')
  self.main:enable_trigger_between('player', 'enemy_projectile')

  self.damage_dealt = 0
  self.damage_taken = 0
  self.main_slow_amount = 1
  self.enemies = {Seeker, EnemyCritter}
  self.color = self.color or fg[0]

  -- Spawn solids and player
  self.x1, self.y1 = gw/2 - 0.8*gw/2, gh/2 - 0.8*gh/2
  self.x2, self.y2 = gw/2 + 0.8*gw/2, gh/2 + 0.8*gh/2
  self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
  self.spawn_points = {
    {x = self.x1 + 32, y = self.y1 + 32, r = math.pi/4},
    {x = self.x1 + 32, y = self.y2 - 32, r = -math.pi/4},
    {x = self.x2 - 32, y = self.y1 + 32, r = 3*math.pi/4},
    {x = self.x2 - 32, y = self.y2 - 32, r = -3*math.pi/4},
    {x = gw/2, y = gh/2, r = random:float(0, 2*math.pi)}
  }
  self.spawn_offsets = {{x = -12, y = -12}, {x = 12, y = -12}, {x = 12, y = 12}, {x = -12, y = 12}, {x = 0, y = 0}}
  self.last_spawn_enemy_time = love.timer.getTime()

  Wall{group = self.main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  Wall{group = self.main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1]}
  WallCover{group = self.post_main, vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40), color = bg[-1]}

  for i, unit in ipairs(units) do
    if i == 1 then
      self.player = Player{group = self.main, x = gw/2, y = gh/2 + 16, leader = true, character = unit.character, level = unit.level, passives = self.passives, ii = i}
    else
      self.player:add_follower(Player{group = self.main, character = unit.character, level = unit.level, passives = self.passives, ii = i})
    end
  end

  local units = self.player:get_all_units()
  for _, unit in ipairs(units) do
    local chp = CharacterHP{group = self.effects, x = self.x1 + 8 + (unit.ii-1)*22, y = self.y2 + 14, parent = unit}
    unit.character_hp = chp
  end

  if self.level == 1000 then
    self.level_1000_text = Text2{group = self.ui, x = gw/2, y = gh/2, lines = {{text = '[fg, wavy_mid]SNKRX', font = fat_font, alignment = 'center'}}}
    -- self.level_1000_text2 = Text2{group = self.ui, x = gw/2, y = gh/2 + 64, lines = {{text = '[fg, wavy_mid]SNKRX', font = pixul_font, alignment = 'center'}}}
    -- Wall{group = self.main, vertices = math.to_rectangle_vertices(gw/2 - 0.45*self.level_1000_text.w, gh/2 - 0.3*self.level_1000_text.h, gw/2 + 0.45*self.level_1000_text.w, gh/2 - 3), snkrx = true, color = bg[-1]}
  
  elseif self.level == 6 or self.level == 12 or self.level == 18 or self.level == 24 or self.level == 25 then
    self.boss_level = true
    self.start_time = 3
    self.t:after(1, function()
      self.t:every(1, function()
        if self.start_time > 1 then alert1:play{volume = 0.5} end
        self.start_time = self.start_time - 1
        self.hfx:use('condition1', 0.25, 200, 10)
      end, 3, function()
        alert1:play{pitch = 1.2, volume = 0.5}
        camera:shake(4, 0.25)
        SpawnEffect{group = self.effects, x = gw/2, y = gh/2 - 48}
        SpawnEffect{group = self.effects, x = gw/2, y = gh/2, action = function(x, y)
          spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
          SpawnMarker{group = self.effects, x = x, y = y}
          self.t:after(0.75, function()
            self.boss = Seeker{group = self.main, x = x, y = y, character = 'seeker', level = self.level, boss = level_to_boss[self.level]}
          end)
        end}
        self.t:every(function()
          if self.boss and not self.boss.dead then
            return (#self.main:get_objects_by_classes(self.enemies) <= 1) and not self.spawning_enemies
          elseif self.boss and self.boss.dead then
            return (#self.main:get_objects_by_classes(self.enemies) <= 0) and not self.spawning_enemies
          end
        end, function()
          self.hfx:use('condition1', 0.25, 200, 10)
          self.hfx:pull('condition2', 0.0625)
          self.t:after(0.5, function()
            self.spawning_enemies = true
            self.t:after((8 + math.floor(self.level/2))*0.1 + 0.5 + 0.75, function() self.spawning_enemies = false end, 'spawning_enemies')
            local spawn_type = random:table{'left', 'middle', 'right'}
            local spawn_points = {left = {x = self.x1 + 32, y = gh/2}, middle = {x = gw/2, y = gh/2}, right = {x = self.x2 - 32, y = gh/2}}
            local p = spawn_points[spawn_type]
            SpawnMarker{group = self.effects, x = p.x, y = p.y}
            self.t:after(0.75, function() self:spawn_n_enemies(p, nil, 8 + math.floor(self.level/2)) end)
          end)
        end)
      end)
      self.t:every(function() return self.start_time <= 0 and (self.boss and self.boss.dead) and #self.main:get_objects_by_classes(self.enemies) <= 0 and not self.spawning_enemies and not self.quitting end, function()
        self:quit()
        if self.level == 6 then
          state.achievement_speed_booster = true
          system.save_state()
          steam.userStats.setAchievement('SPEED_BOOSTER')
          steam.userStats.storeStats()
        elseif self.level == 12 then
          state.achievement_exploder = true
          system.save_state()
          steam.userStats.setAchievement('EXPLODER')
          steam.userStats.storeStats()
        elseif self.level == 18 then
          state.achievement_swarmer = true
          system.save_state()
          steam.userStats.setAchievement('SWARMER')
          steam.userStats.storeStats()
        elseif self.level == 24 then
          state.achievement_forcer = true
          system.save_state()
          steam.userStats.setAchievement('FORCER')
          steam.userStats.storeStats()
        elseif self.level == 25 then
          state.achievement_cluster = true
          system.save_state()
          steam.userStats.setAchievement('CLUSTER')
          steam.userStats.storeStats()
        end
      end)
    end)
  else
    -- Set win condition and enemy spawns
    self.win_condition = 'wave'
    self.level_to_max_waves = {
      2, 3, 4,
      3, 4, 4, 5,
      5, 5, 5, 5, 7,
      6, 6, 7, 7, 7, 10,
      6, 8, 10, 12, 14, 16, 25,
    }
    self.level_to_distributed_enemies_chance = {
      0, 5, 10,
      10, 15, 15, 20,
      20, 20, 20, 20, 25,
      25, 25, 25, 25, 25, 30,
      20, 25, 30, 35, 40, 45, 50,
    }
    self.max_waves = self.level_to_max_waves[self.level]
    self.wave = 0
    self.start_time = 3
    self.t:after(1, function()
      self.t:every(1, function()
        if self.start_time > 1 then alert1:play{volume = 0.5} end
        self.start_time = self.start_time - 1
        self.hfx:use('condition1', 0.25, 200, 10)
      end, 3, function()
        alert1:play{pitch = 1.2, volume = 0.5}
        camera:shake(4, 0.25)
        SpawnEffect{group = self.effects, x = gw/2, y = gh/2 - 48}
        self.t:every(function() return #self.main:get_objects_by_classes(self.enemies) <= 0 and not self.spawning_enemies end, function()
          self.wave = self.wave + 1
          if self.wave > self.max_waves then return end
          self.hfx:use('condition1', 0.25, 200, 10)
          self.hfx:pull('condition2', 0.0625)
          self.t:after(0.5, function()
            if random:bool(self.level_to_distributed_enemies_chance[self.level]) then
              local n = math.ceil((8 + (self.wave-1)*2)/7)
              for i = 1, n do
                self.t:after((i-1)*2, function()
                  self:spawn_distributed_enemies()
                end)
              end
            else
              self.spawning_enemies = true
              self.t:after((8 + (self.wave-1)*2)*0.1 + 0.5 + 0.75, function() self.spawning_enemies = false end, 'spawning_enemies')
              local spawn_type = random:table{'left', 'middle', 'right'}
              local spawn_points = {left = {x = self.x1 + 32, y = gh/2}, middle = {x = gw/2, y = gh/2}, right = {x = self.x2 - 32, y = gh/2}}
              local p = spawn_points[spawn_type]
              SpawnMarker{group = self.effects, x = p.x, y = p.y}
              self.t:after(0.75, function() self:spawn_n_enemies(p, nil, 8 + (self.wave-1)*2) end)
            end
          end)
        end, self.max_waves+1)
      end)
      self.t:every(function() return #self.main:get_objects_by_classes(self.enemies) <= 0 and self.wave > self.max_waves and not self.quitting and not self.spawning_enemies end, function() self:quit() end)
    end)

    if self.level == 20 and self.trailer then
      Text2{group = self.ui, x = gw/2, y = gh/2 - 24, lines = {{text = '[fg, wavy]SNKRX', font = fat_font, alignment = 'center'}}}
      Text2{group = self.ui, x = gw/2, y = gh/2, sx = 0.5, sy = 0.5, lines = {{text = '[fg, wavy_mid]play now!', font = fat_font, alignment = 'center'}}}
      Text2{group = self.ui, x = gw/2, y = gh/2 + 24, sx = 0.5, sy = 0.5, lines = {{text = '[light_bg, wavy_mid]music: kubbi - ember', font = fat_font, alignment = 'center'}}}
    end
  end

  if self.level == 1 then
    local t1 = Text2{group = self.floor, x = gw/2, y = gh/2 + 2, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]<- or a         -> or d', font = fat_font, alignment = 'center'}}}
    local t2 = Text2{group = self.floor, x = gw/2, y = gh/2 + 18, lines = {{text = '[light_bg]turn left                                      turn right', font = pixul_font, alignment = 'center'}}}
    local t3 = Text2{group = self.floor, x = gw/2, y = gh/2 + 46, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]esc - options', font = fat_font, alignment = 'center'}}}
    local t4 = Text2{group = self.floor, x = gw/2, y = gh/2 + 68, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]n - mute sfx', font = fat_font, alignment = 'center'}}}
    local t5 = Text2{group = self.floor, x = gw/2, y = gh/2 + 90, sx = 0.6, sy = 0.6, lines = {{text = '[light_bg]m - mute music', font = fat_font, alignment = 'center'}}}
    t1.t:after(8, function() t1.t:tween(0.2, t1, {sy = 0}, math.linear, function() t1.sy = 0 end) end)
    t2.t:after(8, function() t2.t:tween(0.2, t2, {sy = 0}, math.linear, function() t2.sy = 0 end) end)
    t3.t:after(8, function() t3.t:tween(0.2, t3, {sy = 0}, math.linear, function() t3.sy = 0 end) end)
    t4.t:after(8, function() t4.t:tween(0.2, t4, {sy = 0}, math.linear, function() t4.sy = 0 end) end)
    t5.t:after(8, function() t4.t:tween(0.2, t5, {sy = 0}, math.linear, function() t5.sy = 0 end) end)
  end

  -- Calculate class levels
  local units = {}
  table.insert(units, self.player)
  for _, f in ipairs(self.player.followers) do table.insert(units, f) end

  local class_levels = get_class_levels(units)
  self.ranger_level = class_levels.ranger
  self.warrior_level = class_levels.warrior
  self.mage_level = class_levels.mage
  self.rogue_level = class_levels.rogue
  self.nuker_level = class_levels.nuker
  self.curser_level = class_levels.curser
  self.forcer_level = class_levels.forcer
  self.swarmer_level = class_levels.swarmer
  self.voider_level = class_levels.voider
  self.enchanter_level = class_levels.enchanter
  self.healer_level = class_levels.healer
  self.psyker_level = class_levels.psyker
  self.conjurer_level = class_levels.conjurer

  self.t:every(0.375, function()
    local p = random:table(star_positions)
    Star{group = star_group, x = p.x, y = p.y}
  end)
end


function Arena:on_exit()
  self.floor:destroy()
  self.main:destroy()
  self.post_main:destroy()
  self.effects:destroy()
  self.ui:destroy()
  self.credits:destroy()
  self.t:destroy()
  self.floor = nil
  self.main = nil
  self.post_main = nil
  self.effects = nil
  self.ui = nil
  self.credits = nil
  self.units = nil
  self.passives = nil
  self.player = nil
  self.t = nil
  self.springs = nil
  self.flashes = nil
  self.hfx = nil
end


function Arena:update(dt)
  if main_song_instance:isStopped() then
    main_song_instance = _G[random:table{'song1', 'song2', 'song3', 'song4', 'song5'}]:play{volume = 0.5}
  end

  if input.escape.pressed and not self.transitioning and not self.in_credits then
    if not self.paused then
      trigger:tween(0.25, _G, {slow_amount = 0}, math.linear, function()
        slow_amount = 0
        self.paused = true
        self.paused_t1 = Text2{group = self.ui, x = gw/2, y = gh/2 - 68, sx = 0.6, sy = 0.6, lines = {{text = '[bg10]<-, a or m1       ->, d or m2', font = fat_font, alignment = 'center'}}}
        self.paused_t2 = Text2{group = self.ui, x = gw/2, y = gh/2 - 52, lines = {{text = '[bg10]turn left                                            turn right', font = pixul_font, alignment = 'center'}}}

        self.resume_button = Button{group = self.ui, x = gw/2, y = gh - 160, force_update = true, button_text = 'resume game (esc)', fg_color = 'bg10', bg_color = 'bg', action = function(b)
          trigger:tween(0.25, _G, {slow_amount = 1}, math.linear, function()
            slow_amount = 1
            self.paused = false
            self.paused_t1.dead = true
            self.paused_t2.dead = true
            self.paused_t1 = nil
            self.paused_t2 = nil
            if self.resume_button then self.resume_button.dead = true; self.resume_button = nil end
            if self.restart_button then self.restart_button.dead = true; self.restart_button = nil end
            if self.sfx_button then self.sfx_button.dead = true; self.sfx_button = nil end
            if self.music_button then self.music_button.dead = true; self.music_button = nil end
            if self.video_button_1 then self.video_button_1.dead = true; self.video_button_1 = nil end
            if self.video_button_2 then self.video_button_2.dead = true; self.video_button_2 = nil end
            if self.video_button_3 then self.video_button_3.dead = true; self.video_button_3 = nil end
            if self.quit_button then self.quit_button.dead = true; self.quit_button = nil end
          end, 'pause')
        end}

        self.restart_button = Button{group = self.ui, x = gw/2, y = gh - 135, force_update = true, button_text = 'restart run (r)', fg_color = 'bg10', bg_color = 'bg', action = function(b)
          self.transitioning = true
          ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = fg[0], transition_action = function()
            slow_amount = 1
            gold = 2
            passives = {}
            main_song_instance:stop()
            run_passive_pool_by_tiers = {
              [1] = { 'wall_echo', 'wall_rider', 'centipede', 'temporal_chains', 'amplify', 'amplify_x', 'ballista', 'ballista_x', 'blunt_arrow', 'berserking', 'unwavering_stance', 'assassination', 'unleash', 'blessing',
                'hex_master', 'force_push', 'spawning_pool'}, 
              [2] = {'ouroboros_technique_r', 'ouroboros_technique_l', 'intimidation', 'vulnerability', 'resonance', 'point_blank', 'longshot', 'explosive_arrow', 'chronomancy', 'awakening', 'ultimatum', 'echo_barrage', 
                'reinforce', 'payback', 'whispers_of_doom', 'heavy_impact', 'immolation', 'call_of_the_void'},
              [3] = {'divine_machine_arrow', 'divine_punishment', 'flying_daggers', 'crucio', 'hive', 'void_rift'},
            }
            max_units = 7 + new_game_plus
            main:add(BuyScreen'buy_screen')
            main:go_to('buy_screen', 0, {}, passives)
          end, text = Text({{text = '[wavy, bg]restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
        end}

        self.sfx_button = Button{group = self.ui, x = gw/2, y = gh - 110, force_update = true, button_text = 'toggle sfx (n)', fg_color = 'bg10', bg_color = 'bg', action = function(b)
          ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          b.spring:pull(0.2, 200, 10)
          b.selected = true
          ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          if sfx.volume == 0.5 then
            sfx.volume = 0
          elseif sfx.volume == 0 then
            sfx.volume = 0.5
          end
        end}

        self.music_button = Button{group = self.ui, x = gw/2, y = gh - 85, force_update = true, button_text = 'toggle music (m)', fg_color = 'bg10', bg_color = 'bg', action = function(b)
          ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          b.spring:pull(0.2, 200, 10)
          b.selected = true
          ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          if music.volume == 0.5 then
            music.volume = 0
          elseif music.volume == 0 then
            music.volume = 0.5
          end
        end}

        self.video_button_1 = Button{group = self.ui, x = gw/2 - 86, y = gh - 60, force_update = true, button_text = 'window size-', fg_color = 'bg10', bg_color = 'bg', action = function()
          sx, sy = sx - 1, sy - 1
          love.window.setMode(480*sx, 270*sy)
          state.sx, state.sy = sx, sy
          state.fullscreen = false
        end}

        self.video_button_2 = Button{group = self.ui, x = gw/2, y = gh - 60, force_update = true, button_text = 'window size+', fg_color = 'bg10', bg_color = 'bg', action = function()
          sx, sy = sx + 1, sy + 1
          love.window.setMode(480*sx, 270*sy)
          state.sx, state.sy = sx, sy
          state.fullscreen = false
        end}

        self.video_button_3 = Button{group = self.ui, x = gw/2 + 79, y = gh - 60, force_update = true, button_text = 'fullscreen', fg_color = 'bg10', bg_color = 'bg', action = function()
          local _, _, flags = love.window.getMode()
          local window_width, window_height = love.window.getDesktopDimensions(flags.display)
          sx, sy = window_width/480, window_height/270
          ww, wh = window_width, window_height
          love.window.setMode(window_width, window_height, {fullscreen = true})
          state.fullscreen = true
        end}

        self.quit_button = Button{group = self.ui, x = gw/2, y = gh - 35, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function()
          system.save_state()
          steam.shutdown()
          love.event.quit()
        end}
      end, 'pause')
    else
      trigger:tween(0.25, _G, {slow_amount = 1}, math.linear, function()
        slow_amount = 1
        self.paused = false
        self.paused_t1.dead = true
        self.paused_t2.dead = true
        self.paused_t1 = nil
        self.paused_t2 = nil
        if self.resume_button then self.resume_button.dead = true; self.resume_button = nil end
        if self.restart_button then self.restart_button.dead = true; self.restart_button = nil end
        if self.sfx_button then self.sfx_button.dead = true; self.sfx_button = nil end
        if self.music_button then self.music_button.dead = true; self.music_button = nil end
        if self.video_button_1 then self.video_button_1.dead = true; self.video_button_1 = nil end
        if self.video_button_2 then self.video_button_2.dead = true; self.video_button_2 = nil end
        if self.video_button_3 then self.video_button_3.dead = true; self.video_button_3 = nil end
        if self.quit_button then self.quit_button.dead = true; self.quit_button = nil end
      end, 'pause')
    end
  end

  if self.paused or self.died or self.won and not self.transitioning then
    if input.r.pressed then
      self.transitioning = true
      ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = fg[0], transition_action = function()
        slow_amount = 1
        gold = 2
        passives = {}
        main_song_instance:stop()
        run_passive_pool_by_tiers = {
          [1] = { 'wall_echo', 'wall_rider', 'centipede', 'temporal_chains', 'amplify', 'amplify_x', 'ballista', 'ballista_x', 'blunt_arrow', 'berserking', 'unwavering_stance', 'assassination', 'unleash', 'blessing',
            'hex_master', 'force_push', 'spawning_pool'}, 
          [2] = {'ouroboros_technique_r', 'ouroboros_technique_l', 'intimidation', 'vulnerability', 'resonance', 'point_blank', 'longshot', 'explosive_arrow', 'chronomancy', 'awakening', 'ultimatum', 'echo_barrage', 
            'reinforce', 'payback', 'whispers_of_doom', 'heavy_impact', 'immolation', 'call_of_the_void'},
          [3] = {'divine_machine_arrow', 'divine_punishment', 'flying_daggers', 'crucio', 'hive', 'void_rift'},
        }
        max_units = 7 + new_game_plus
        main:add(BuyScreen'buy_screen')
        main:go_to('buy_screen', 0, {}, passives)
      end, text = Text({{text = '[wavy, bg]restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
    end

    if input.escape.pressed then
      self.in_credits = false
      if self.credits_button then self.credits_button:on_mouse_exit() end
      for _, object in ipairs(self.credits.objects) do
        object.dead = true
      end
      self.credits:update(0)
    end
  end

  self:update_game_object(dt*slow_amount)
  main_song_instance.pitch = math.clamp(slow_amount*self.main_slow_amount, 0.05, 1)

  star_group:update(dt*slow_amount)
  self.floor:update(dt*slow_amount)
  self.main:update(dt*slow_amount*self.main_slow_amount)
  self.post_main:update(dt*slow_amount)
  self.effects:update(dt*slow_amount)
  self.ui:update(dt*slow_amount)
  self.credits:update(dt)
end


function Arena:quit()
  self.quitting = true
  if self.level == 25 then
    if not self.win_text and not self.win_text2 then
      self.won = true
      trigger:tween(1, _G, {slow_amount = 0}, math.linear, function() slow_amount = 0 end, 'slow_amount')
      trigger:tween(4, camera, {x = gw/2, y = gh/2, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2, gh/2, 0 end)
      self.win_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 66, force_update = true, lines = {{text = '[wavy_mid, cbyc2]congratulations!', font = fat_font, alignment = 'center'}}}
      trigger:after(2.5, function()
        if new_game_plus == 5 then
          self.win_text2 = Text2{group = self.ui, x = gw/2, y = gh/2 + 30, force_update = true, lines = {
            {text = "[fg]now you've really beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]thanks a lot for playing it and completing it entirely!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]this game was inspired by:", font = pixul_font, alignment = 'center', height_multiplier = 4},
            {text = "[fg]so check those games out, they're fun!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]and to get more games like this in the future:", font = pixul_font, alignment = 'center', height_multiplier = 4},
            {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
          }}
          SteamFollowButton{group = self.ui, x = gw/2, y = gh/2 + 78, force_update = true}
          Button{group = self.ui, x = gw - 40, y = gh - 44, force_update = true, button_text = 'credits', fg_color = 'bg10', bg_color = 'bg', action = function() self:create_credits() end}
          Button{group = self.ui, x = gw - 32, y = gh - 20, force_update = true, button_text = 'quit', fg_color = 'bg10', bg_color = 'bg', action = function() love.event.quit() end}
          local open_url = function(b, url)
            ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
            b.spring:pull(0.2, 200, 10)
            b.selected = true
            ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
            system.open_url(url)
          end
          Button{group = self.ui, x = gw/2 - 50, y = gh/2 + 12, force_update = true, button_text = 'nimble quest', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/259780/Nimble_Quest/') end}
          Button{group = self.ui, x = gw/2 + 50, y = gh/2 + 12, force_update = true, button_text = 'dota underlords', fg_color = 'bluem5', bg_color = 'blue', action = function(b) open_url(b, 'https://store.steampowered.com/app/1046930/Dota_Underlords/') end}
        else
          self.win_text2 = Text2{group = self.ui, x = gw/2, y = gh/2 + 20, force_update = true, lines = {
            {text = "[fg]you've beaten the game!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]i made this game in 3 months as a dev challenge", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]and i'm happy with how it turned out!", font = pixul_font, alignment = 'center', height_multiplier = 1.24},
            {text = "[fg]if you liked it too and want to play more games like this:", font = pixul_font, alignment = 'center', height_multiplier = 4},
            {text = "[fg]i will release more games this year, so stay tuned!", font = pixul_font, alignment = 'center', height_multiplier = 1.4},
            {text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = 'center'},
          }}
          SteamFollowButton{group = self.ui, x = gw/2, y = gh/2 + 34, force_update = true}
          RestartButton{group = self.ui, x = gw - 40, y = gh - 20, force_update = true}
          trigger:after(8, function()
            self.try_ng_text = Text2{group = self.ui, x = gw - 220, y = gh - 20, force_update = true, lines = {
              {text = '[cbyc3]try a harder difficulty with +1 max snake size:', font = pixul_font},
            }}
          end)
          self.credits_button = Button{group = self.ui, x = gw - 40, y = gh - 44, force_update = true, button_text = 'credits', fg_color = 'bg10', bg_color = 'bg', action = function()
            self:create_credits()
          end}
          self.restart_button = Button{group = self.ui, x = gw - 40, y = gh - 68, force_update = true, button_text = 'restart', fg_color = 'bg10', bg_color = 'bg', action = function(b)
            self.transitioning = true
            ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
            ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
            ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
            TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = fg[0], transition_action = function()
              slow_amount = 1
              gold = 2
              passives = {}
              main_song_instance:stop()
              run_passive_pool_by_tiers = {
                [1] = { 'wall_echo', 'wall_rider', 'centipede', 'temporal_chains', 'amplify', 'amplify_x', 'ballista', 'ballista_x', 'blunt_arrow', 'berserking', 'unwavering_stance', 'assassination', 'unleash', 'blessing',
                  'hex_master', 'force_push', 'spawning_pool'}, 
                [2] = {'ouroboros_technique_r', 'ouroboros_technique_l', 'intimidation', 'vulnerability', 'resonance', 'point_blank', 'longshot', 'explosive_arrow', 'chronomancy', 'awakening', 'ultimatum', 'echo_barrage', 
                  'reinforce', 'payback', 'whispers_of_doom', 'heavy_impact', 'immolation', 'call_of_the_void'},
                [3] = {'divine_machine_arrow', 'divine_punishment', 'flying_daggers', 'crucio', 'hive', 'void_rift'},
              }
              max_units = 7 + new_game_plus
              main:add(BuyScreen'buy_screen')
              main:go_to('buy_screen', 0, {}, passives)
            end, text = Text({{text = '[wavy, bg]restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
          end}
        end
      end)

      if new_game_plus == 1 then
        state.achievement_new_game_1 = true
        system.save_state()
        steam.userStats.setAchievement('NEW_GAME_1')
        steam.userStats.storeStats()
      end

      if new_game_plus == 5 then
        state.achievement_new_game_5 = true
        system.save_state()
        steam.userStats.setAchievement('GAME_COMPLETE')
        steam.userStats.storeStats()
      end

      if self.ranger_level >= 2 then
        state.achievement_rangers_win = true
        system.save_state()
        steam.userStats.setAchievement('RANGERS_WIN')
        steam.userStats.storeStats()
      end

      if self.warrior_level >= 2 then
        state.achievement_warriors_win = true
        system.save_state()
        steam.userStats.setAchievement('WARRIORS_WIN')
        steam.userStats.storeStats()
      end

      if self.mage_level >= 2 then
        state.achievement_mages_win = true
        system.save_state()
        steam.userStats.setAchievement('MAGES_WIN')
        steam.userStats.storeStats()
      end

      if self.rogue_level >= 2 then
        state.achievement_rogues_win = true
        system.save_state()
        steam.userStats.setAchievement('ROGUES_WIN')
        steam.userStats.storeStats()
      end

      if self.healer_level >= 2 then
        state.achievement_healers_win = true
        system.save_state()
        steam.userStats.setAchievement('HEALERS_WIN')
        steam.userStats.storeStats()
      end

      if self.enchanter_level >= 2 then
        state.achievement_enchanters_win = true
        system.save_state()
        steam.userStats.setAchievement('ENCHANTERS_WIN')
        steam.userStats.storeStats()
      end

      if self.nuker_level >= 2 then
        state.achievement_nukers_win = true
        system.save_state()
        steam.userStats.setAchievement('NUKERS_WIN')
        steam.userStats.storeStats()
      end

      if self.conjurer_level >= 2 then
        state.achievement_conjurers_win = true
        system.save_state()
        steam.userStats.setAchievement('CONJURERS_WIN')
        steam.userStats.storeStats()
      end

      if self.psyker_level >= 2 then
        state.achievement_psykers_win = true
        system.save_state()
        steam.userStats.setAchievement('PSYKERS_WIN')
        steam.userStats.storeStats()
      end

      if self.curser_level >= 2 then
        state.achievement_cursers_win = true
        system.save_state()
        steam.userStats.setAchievement('CURSERS_WIN')
        steam.userStats.storeStats()
      end

      if self.forcer_level >= 2 then
        state.achievement_forcers_win = true
        system.save_state()
        steam.userStats.setAchievement('FORCERS_WIN')
        steam.userStats.storeStats()
      end

      if self.swarmer_level >= 2 then
        state.achievement_swarmers_win = true
        system.save_state()
        steam.userStats.setAchievement('SWARMERS_WIN')
        steam.userStats.storeStats()
      end

      if self.voider_level >= 2 then
        state.achievement_voiders_win = true
        system.save_state()
        steam.userStats.setAchievement('VOIDERS_WIN')
        steam.userStats.storeStats()
      end

      local units = self.player:get_all_units()
      local all_units_level_2 = true
      for _, unit in ipairs(units) do
        if unit.level ~= 2 then
          all_units_level_2 = false
          break
        end
      end
      if all_units_level_2 then
        state.achievement_level_2_win = true
        system.save_state()
        steam.userStats.setAchievement('LEVEL_2_WIN')
        steam.userStats.storeStats()
      end

      local units = self.player:get_all_units()
      local all_units_level_3 = true
      for _, unit in ipairs(units) do
        if unit.level ~= 3 then
          all_units_level_3 = false
          break
        end
      end
      if all_units_level_3 then
        state.achievement_level_3_win = true
        system.save_state()
        steam.userStats.setAchievement('LEVEL_3_WIN')
        steam.userStats.storeStats()
      end
    end

  else
    if not self.arena_clear_text then self.arena_clear_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 48, lines = {{text = '[wavy_mid, cbyc]arena clear!', font = fat_font, alignment = 'center'}}} end
    self.t:after(3, function()
      if self.level % 3 == 0 then
        self.arena_clear_text.dead = true
        trigger:tween(1, _G, {slow_amount = 0}, math.linear, function() slow_amount = 0 end, 'slow_amount')
        trigger:tween(4, camera, {x = gw/2, y = gh/2, r = 0}, math.linear, function() camera.x, camera.y, camera.r = gw/2, gh/2, 0 end)
        local card_w, card_h = 100, 100
        local w = 3*card_w + 2*20
        self.choosing_passives = true
        self.cards = {}
        local tier_1 = random:weighted_pick(unpack(level_to_passive_tier_weights[level or self.level]))
        local tier_2 = random:weighted_pick(unpack(level_to_passive_tier_weights[level or self.level]))
        local tier_3 = random:weighted_pick(unpack(level_to_passive_tier_weights[level or self.level]))
        local passive_1 = random:table_remove(run_passive_pool_by_tiers[tier_1])
        local passive_2 = random:table_remove(run_passive_pool_by_tiers[tier_2])
        local passive_3 = random:table_remove(run_passive_pool_by_tiers[tier_3])
        if passive_1 then
          table.insert(self.cards,
            PassiveCard{group = main.current.ui, x = gw/2 - w/2 + 0*(card_w + 20) + card_w/2, y = gh/2 - 6, w = card_w, h = card_h, card_i = 1, tier = tier_1, arena = self, passive = passive_1, force_update = true})
        end
        if passive_2 then
          table.insert(self.cards,
            PassiveCard{group = main.current.ui, x = gw/2 - w/2 + 1*(card_w + 20) + card_w/2, y = gh/2 - 6, w = card_w, h = card_h, card_i = 2, tier = tier_2, arena = self, passive = passive_2, force_update = true})
        end
        if passive_3 then
          table.insert(self.cards,
            PassiveCard{group = main.current.ui, x = gw/2 - w/2 + 2*(card_w + 20) + card_w/2, y = gh/2 - 6, w = card_w, h = card_h, card_i = 3, tier = tier_3, arena = self, passive = passive_3, force_update = true})
        end
        self.passive_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 65, lines = {{text = '[fg, wavy]choose one', font = fat_font, alignment = 'center'}}}
        if not passive_1 and not passive_2 and not passive_3 then
          self:transition()
        end
      else
        self:transition()
      end
    end, 'transition')
  end
end


function Arena:restore_passives_to_pool(j)
  for i = 1, 3 do
    if i ~= j then
      table.insert(run_passive_pool_by_tiers[self.cards[i].tier], self.cards[i].passive)
    end
  end
end


function Arena:draw()
  self.floor:draw()
  self.main:draw()
  self.post_main:draw()
  self.effects:draw()

  graphics.draw_with_mask(function()
    star_canvas:draw(0, 0, 0, 1, 1)
  end, function()
    camera:attach()
    graphics.rectangle(gw/2, gh/2, self.w, self.h, nil, nil, fg[0])
    camera:detach()
  end, true)

  camera:attach()
  if self.start_time and self.start_time > 0 and not self.choosing_passives then
    graphics.push(gw/2, gh/2 - 48, 0, self.hfx.condition1.x, self.hfx.condition1.x)
      graphics.print_centered(tostring(self.start_time), fat_font, gw/2, gh/2 - 48, 0, 1, 1, nil, nil, self.hfx.condition1.f and fg[0] or red[0])
    graphics.pop()
  end

  if self.boss_level then
    if self.start_time <= 0 then
      graphics.push(self.x2 - 106, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
        graphics.print_centered('kill the elite', fat_font, self.x2 - 106, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
      graphics.pop()
    end
  else
    if self.win_condition then
      if self.win_condition == 'wave' then
        if self.start_time <= 0 then
          graphics.push(self.x2 - 50, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
            graphics.print_centered('wave:', fat_font, self.x2 - 50, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
          graphics.pop()
          local wave = self.wave
          if wave > self.max_waves then wave = self.max_waves end
          graphics.push(self.x2 - 25 + fat_font:get_text_width(wave .. '/' .. self.max_waves)/2, self.y1 - 8, 0, self.hfx.condition1.x, self.hfx.condition1.x)
            graphics.print(wave .. '/' .. self.max_waves, fat_font, self.x2 - 25, self.y1 - 8, 0, 0.75, 0.75, nil, fat_font.h/2, self.hfx.condition1.f and fg[0] or yellow[0])
          graphics.pop()
        end
      end
    end
  end
  camera:detach()

  if self.level == 20 and self.trailer then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  if self.choosing_passives or self.won or self.paused or self.died then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  self.ui:draw()

  if self.in_credits then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent_2) end
  self.credits:draw()
end


function Arena:die()
  if not self.died_text and not self.won then
    self.died = true
    self.t:tween(2, self, {main_slow_amount = 0}, math.linear, function() self.main_slow_amount = 0 end)
    self.died_text = Text2{group = self.ui, x = gw/2, y = gh/2 - 32, lines = {
      {text = '[wavy_mid, cbyc]you died...', font = fat_font, alignment = 'center', height_multiplier = 1.25},
    }}
    self.t:after(2, function()
      self.death_info_text = Text2{group = self.ui, x = gw/2, y = gh/2, sx = 0.7, sy = 0.7, lines = {
        {text = '[wavy_mid, fg]level reached: [wavy_mid, yellow]' .. self.level, font = fat_font, alignment = 'center'},
      }}
      self.restart_button = Button{group = self.ui, x = gw/2, y = gh/2 + 24, force_update = true, button_text = 'restart run (r)', fg_color = 'bg10', bg_color = 'bg', action = function(b)
        self.transitioning = true
        ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = fg[0], transition_action = function()
          slow_amount = 1
          gold = 2
          passives = {}
          main_song_instance:stop()
          run_passive_pool_by_tiers = {
            [1] = { 'wall_echo', 'wall_rider', 'centipede', 'temporal_chains', 'amplify', 'amplify_x', 'ballista', 'ballista_x', 'blunt_arrow', 'berserking', 'unwavering_stance', 'assassination', 'unleash', 'blessing',
              'hex_master', 'force_push', 'spawning_pool'}, 
            [2] = {'ouroboros_technique_r', 'ouroboros_technique_l', 'intimidation', 'vulnerability', 'resonance', 'point_blank', 'longshot', 'explosive_arrow', 'chronomancy', 'awakening', 'ultimatum', 'echo_barrage', 
              'reinforce', 'payback', 'whispers_of_doom', 'heavy_impact', 'immolation', 'call_of_the_void'},
            [3] = {'divine_machine_arrow', 'divine_punishment', 'flying_daggers', 'crucio', 'hive', 'void_rift'},
          }
          max_units = 7 + new_game_plus
          main:add(BuyScreen'buy_screen')
          main:go_to('buy_screen', 0, {}, passives)
        end, text = Text({{text = '[wavy, bg]restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
      end}
    end)
  end
end


function Arena:create_credits()
  local open_url = function(b, url)
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    b.spring:pull(0.2, 200, 10)
    b.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url(url)
  end

  self.in_credits = true
  Text2{group = self.credits, x = 60, y = 20, lines = {{text = '[bg10]main dev: ', font = pixul_font}}}
  Button{group = self.credits, x = 117, y = 20, button_text = 'a327ex', fg_color = 'bg10', bg_color = 'bg', credits_button = true, action = function(b) open_url(b, 'https://store.steampowered.com/dev/a327ex/') end}
  Text2{group = self.credits, x = 60, y = 50, lines = {{text = '[blue]code: ', font = pixul_font}}}
  Button{group = self.credits, x = 102, y = 50, button_text = 'love2d', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://love2d.org') end}
  Button{group = self.credits, x = 159, y = 50, button_text = 'bakpakin', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/bakpakin/binser') end}
  Button{group = self.credits, x = 226, y = 50, button_text = 'davisdude', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/davisdude/mlib') end}
  Button{group = self.credits, x = 295, y = 50, button_text = 'tesselode', fg_color = 'bluem5', bg_color = 'blue', credits_button = true, action = function(b) open_url(b, 'https://github.com/tesselode/ripple') end}
  Text2{group = self.credits, x = 60, y = 80, lines = {{text = '[green]music: ', font = pixul_font}}}
  Button{group = self.credits, x = 100, y = 80, button_text = 'kubbi', fg_color = 'greenm5', bg_color = 'green', credits_button = true, action = function(b) open_url(b, 'https://kubbimusic.com/album/ember') end}
  Text2{group = self.credits, x = 60, y = 110, lines = {{text = '[yellow]sounds: ', font = pixul_font}}}
  Button{group = self.credits, x = 135, y = 110, button_text = 'sidearm studios', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://sidearm-studios.itch.io/ultimate-sound-fx-bundle') end}
  Button{group = self.credits, x = 217, y = 110, button_text = 'justinbw', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/JustinBW/sounds/80921/') end}
  Button{group = self.credits, x = 279, y = 110, button_text = 'jcallison', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/jcallison/sounds/258269/') end}
  Button{group = self.credits, x = 342, y = 110, button_text = 'hybrid_v', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/Hybrid_V/sounds/321215/') end}
  Button{group = self.credits, x = 427, y = 110, button_text = 'womb_affliction', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/womb_affliction/sounds/376532/') end}
  Button{group = self.credits, x = 106, y = 130, button_text = 'bajko', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/bajko/sounds/399656/') end}
  Button{group = self.credits, x = 157, y = 130, button_text = 'benzix2', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://freesound.org/people/benzix2/sounds/467951/') end}
  Button{group = self.credits, x = 204, y = 130, button_text = 'lord', fg_color = 'yellowm5', bg_color = 'yellow', credits_button = true, action = function(b)
    open_url(b, 'https://store.steampowered.com/developer/T_TGames') end}
  Text2{group = self.credits, x = 70, y = 160, lines = {{text = '[red]playtesters: ', font = pixul_font}}}
  Button{group = self.credits, x = 130, y = 160, button_text = 'Jofer', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/JofersGames') end}
  Button{group = self.credits, x = 172, y = 160, button_text = 'ekun', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/ekunenuke') end}
  Button{group = self.credits, x = 224, y = 160, button_text = 'cvisy_GN', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/cvisy_GN') end}
  Button{group = self.credits, x = 292, y = 160, button_text = 'Blue Fairy', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/blue9fairy') end}
  Button{group = self.credits, x = 362, y = 160, button_text = 'Phil Blank', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/PhilBlankGames') end}
  Button{group = self.credits, x = 440, y = 160, button_text = 'DefineDoddy', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/DefineDoddy') end}
  Button{group = self.credits, x = 140, y = 180, button_text = 'Ge0force', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/Ge0forceBE') end}
  Button{group = self.credits, x = 193, y = 180, button_text = 'Vlad', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/thecryru') end}
  Button{group = self.credits, x = 223, y = 180, button_text = 'F', fg_color = 'redm5', bg_color = 'red', credits_button = true, action = function(b) 
    open_url(b, 'https://twitter.com/notyps') end}
end


function Arena:transition()
  self.transitioning = true
  local gold_gained = random:int(level_to_gold_gained[self.level][1], level_to_gold_gained[self.level][2])
  local interest = math.min(math.floor(gold/5), 5)
  gold = gold + gold_gained + interest
  ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  TransitionEffect{group = main.transitions, x = self.player.x, y = self.player.y, color = self.color, transition_action = function(t)
    slow_amount = 1
    main:add(BuyScreen'buy_screen')
    main:go_to('buy_screen', self.level, self.units, passives)
    t.t:after(0.1, function()
      t.text:set_text({
        {text = '[nudge_down, bg]gold gained: ' .. tostring(gold_gained), font = pixul_font, alignment = 'center', height_multiplier = 1.5},
        {text = '[wavy_lower, bg]interest: 0', font = pixul_font, alignment = 'center', height_multiplier = 1.5},
        {text = '[wavy_lower, bg]total: 0', font = pixul_font, alignment = 'center'}
      })
      _G[random:table{'coins1', 'coins2', 'coins3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      t.t:after(0.2, function()
        t.text:set_text({
          {text = '[wavy_lower, bg]gold gained: ' .. tostring(gold_gained), font = pixul_font, alignment = 'center', height_multiplier = 1.5},
          {text = '[nudge_down, bg]interest: ' .. tostring(interest), font = pixul_font, alignment = 'center', height_multiplier = 1.5},
          {text = '[wavy_lower, bg]total: 0', font = pixul_font, alignment = 'center'}
        })
        _G[random:table{'coins1', 'coins2', 'coins3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        t.t:after(0.2, function()
          t.text:set_text({
            {text = '[wavy_lower, bg]gold gained: ' .. tostring(gold_gained), font = pixul_font, alignment = 'center', height_multiplier = 1.5},
            {text = '[wavy_lower, bg]interest: ' .. tostring(interest), font = pixul_font, alignment = 'center', height_multiplier = 1.5},
            {text = '[nudge_down, bg]total: ' .. tostring(gold_gained + interest), font = pixul_font, alignment = 'center'}
          })
          _G[random:table{'coins1', 'coins2', 'coins3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        end)
      end)
    end)
  end, text = Text({
    {text = '[wavy_lower, bg]gold gained: 0', font = pixul_font, alignment = 'center', height_multiplier = 1.5},
    {text = '[wavy_lower, bg]interest: 0', font = pixul_font, alignment = 'center', height_multiplier = 1.5},
    {text = '[wavy_lower, bg]total: 0', font = pixul_font, alignment = 'center'}
  }, global_text_tags)}
end


function Arena:spawn_distributed_enemies()
  self.spawning_enemies = true

  local t = {'4', '4+4', '4+4+4', '2x4', '3x4', '4x2'}
  local spawn_type = t[random:weighted_pick(20, 20, 10, 15, 10, 15)]
  local spawn_points = table.copy(self.spawn_points)
  if spawn_type == '4' then
    local p = random:table_remove(spawn_points)
    SpawnMarker{group = self.effects, x = p.x, y = p.y}
    self.t:after(0.75, function()
      self:spawn_n_enemies(p)
    end)
    self.t:after(1.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  elseif spawn_type == '4+4' then
    local p = random:table_remove(spawn_points)
    SpawnMarker{group = self.effects, x = p.x, y = p.y}
    self.t:after(0.75, function()
      self:spawn_n_enemies(p)
      self.t:after(2, function() self:spawn_n_enemies(p) end)
    end)
    self.t:after(3.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  elseif spawn_type == '4+4+4' then
    local p = random:table_remove(spawn_points)
    SpawnMarker{group = self.effects, x = p.x, y = p.y}
    self.t:after(0.75, function()
      self:spawn_n_enemies(p)
      self.t:after(1, function()
        self:spawn_n_enemies(p)
        self.t:after(1, function()
          self:spawn_n_enemies(p)
        end)
      end)
    end)
    self.t:after(3.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  elseif spawn_type == '2x4' then
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 1) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 2) end)
    end)
    self.t:after(1.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  elseif spawn_type == '3x4' then
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 1) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 2) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 3) end)
    end)
    self.t:after(1.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  elseif spawn_type == '4x2' then
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 1, 2) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 2, 2) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 3, 2) end)
    end)
    self.t:after({0, 0.2}, function()
      local p = random:table_remove(spawn_points)
      SpawnMarker{group = self.effects, x = p.x, y = p.y}
      self.t:after(0.75, function() self:spawn_n_enemies(p, 4, 2) end)
    end)
    self.t:after(1.5, function() self.spawning_enemies = false end, 'spawning_enemies')
  end
end


function Arena:spawn_n_enemies(p, j, n)
  if self.died then return end
  if self.arena_clear_text then return end
  if self.quitting then return end

  j = j or 1
  n = n or 4
  self.last_spawn_enemy_time = love.timer.getTime()
  self.t:every(0.1, function()
    local o = self.spawn_offsets[(self.t:get_every_iteration('spawn_enemies_' .. j) % 5) + 1]
    SpawnEffect{group = self.effects, x = p.x + o.x, y = p.y + o.y, action = function(x, y)
      spawn1:play{pitch = random:float(0.8, 1.2), volume = 0.15}
      if random:bool(table.reduce(level_to_elite_spawn_weights[self.level], function(memo, v) return memo + v end)) then
        local elite_type = level_to_elite_spawn_types[self.level][random:weighted_pick(unpack(level_to_elite_spawn_weights[self.level]))]
        Seeker{group = self.main, x = x, y = y, character = 'seeker', level = self.level,
          speed_booster = elite_type == 'speed_booster', exploder = elite_type == 'exploder', shooter = elite_type == 'shooter', headbutter = elite_type == 'headbutter', tank = elite_type == 'tank', spawner = elite_type == 'spawner'}
      else
        Seeker{group = self.main, x = x, y = y, character = 'seeker', level = self.level}
      end
    end}
  end, n, nil, 'spawn_enemies_' .. j)
end



CharacterHP = Object:extend()
CharacterHP:implement(GameObject)
function CharacterHP:init(args)
  self:init_game_object(args)
  self.hfx:add('hit', 1)
  self.cooldown_ratio = 0
end


function CharacterHP:update(dt)
  self:update_game_object(dt)
  local t, d = self.parent.t:get_timer_and_delay'shoot'
  if t and d then
    local m = self.parent.t:get_every_multiplier'shoot'
    self.cooldown_ratio = math.min(t/(d*m), 1)
  end
  local t, d = self.parent.t:get_timer_and_delay'attack'
  if t and d then
    local m = self.parent.t:get_every_multiplier'attack'
    self.cooldown_ratio = math.min(t/(d*m), 1)
  end
  local t, d = self.parent.t:get_timer_and_delay'heal'
  if t and d then self.cooldown_ratio = math.min(t/d, 1) end
  local t, d = self.parent.t:get_timer_and_delay'buff'
  if t and d then self.cooldown_ratio = math.min(t/d, 1) end
  local t, d = self.parent.t:get_timer_and_delay'spawn'
  if t and d then self.cooldown_ratio = math.min(t/d, 1) end
end


function CharacterHP:draw()
  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y - 2, 14, 4, 2, 2, self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or _G[character_color_strings[self.parent.character]][-2]), 2)
    if self.parent.hp > 0 then
      graphics.rectangle2(self.x - 7, self.y - 4, 14*(self.parent.hp/self.parent.max_hp), 4, nil, nil, self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or _G[character_color_strings[self.parent.character]][-2]))
    end
    if not self.parent.dead then
      graphics.line(self.x - 8, self.y + 5, self.x - 8 + 15.5*self.cooldown_ratio, self.y + 5, self.hfx.hit.f and fg[0] or _G[character_color_strings[self.parent.character]][-2], 2)
    end
  graphics.pop()
end


function CharacterHP:change_hp()
  self.hfx:use('hit', 0.5)
end
