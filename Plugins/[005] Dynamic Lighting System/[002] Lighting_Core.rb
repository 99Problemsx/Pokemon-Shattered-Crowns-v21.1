# ===============================================================================
# Lighting Class - Main lighting engine
# ===============================================================================

class Lighting
  PADDING = 32
  
  def initialize(map, viewport)
    @bitmap = Bitmap.new(Graphics.width + PADDING * 2, Graphics.height + PADDING * 2)
    @sprite_add = Sprite.new(viewport)
    @sprite_add.blend_type = 0
    @sprite_add.x = -PADDING
    @sprite_add.y = -PADDING
    @sprite_add.z = 99997
    @sprite_sub = Sprite.new(viewport)
    @sprite_sub.blend_type = 2
    @sprite_sub.x = -PADDING
    @sprite_sub.y = -PADDING
    @sprite_sub.z = 99998
    @overlay = Sprite.new(viewport)
    @overlay.bitmap = Bitmap.new(Graphics.width + PADDING * 2, Graphics.height + PADDING * 2)
    @overlay.x = -PADDING
    @overlay.y = -PADDING
    @overlay.z = 99999
    @overlay.z = 99999
    @overlay.blend_type = 0
    @light_sprites = {}
    @numfades = 3
    @resolution = 2
    @fadefactor = 0.9
    @anim_mult = 0.05
    @disposed = false
    @viewport = viewport

    setup_map(map)
    setup_effects
    setup_overlay
    update
  end

  def setup_map(map = nil)
    @map_settings = nil
    @map = map ? map : $game_map
    @last_map_id = @map.map_id
    settings = GameData::LightMap.try_get(@map.map_id) || GameData::LightMap.get(0)
    return false if settings.type == :custom && !settings.call_spawn
    @map_settings = settings
    echoln("Lighting: Map #{@map.map_id} loaded (type: #{settings.type})")
  end

  def setup_effects
    # Clear and Dispose existing sprites (Force regeneration for new map/viewport)
    if @light_sprites
      @light_sprites.each_value { |s| s.dispose }
      @light_sprites.clear
    end
    


    @effects = {}
    @effects_bitmaps = {}
    @debug_logged = false
    count = 0
    GameData::LightEffect.each do |effect|
      next if effect.map_id && effect.map_id != @map.map_id
      @effects[effect.id] = effect
      @effects_bitmaps[effect.id] = pbBitmap(effect.bitmap) if effect.bitmap
      count += 1
    end
    echoln("Loaded #{count} light effects")
    echoln("Night? #{night?}")
    echoln("Outside? #{outside?}")
    echoln("========================================")
    

  end

  def setup_overlay
    bitmap = @overlay.bitmap
    bitmap.clear
    return if !@map_settings
    overlay_settings = nil
    blend_type = 0
    if @map_settings.overlay
      overlay_settings = @map_settings.overlay
    elsif @map.metadata&.has_flag?("Cave")
      overlay_settings = @map_settings.overlay || [Color.new(0, 0, 0, 150), Graphics.width / 2, 12]
    elsif canopy?
      overlay_settings = @map_settings.overlay || [Color.new(15, 38, 0, 200), Graphics.width / 2, 12]
      blend_type = 2
    end
    bitmap.clear
    return unless overlay_settings
    color  = overlay_settings[0]
    radius = overlay_settings[1]
    rings  = overlay_settings[2]
    bitmap.fill_rect(0, 0, bitmap.width, bitmap.height, color)
    cx = bitmap.width / 2
    cy = bitmap.height / 2
    cradius = radius
    for i in 1..rings
      for j in cx - cradius..cx + cradius
        diff2 = (cradius * cradius) - ((j - cx) * (j - cx))
        diff = Math.sqrt(diff2)
        bitmap.fill_rect(j, cy - diff, 1, diff * 2, Color.new(color.red, color.green, color.blue, color.alpha * (rings - i) / rings))
      end
      cradius = (cradius * 0.9).floor
    end
    @overlay.blend_type = blend_type
  end

  def add_effect(effect)
    @effects[effect.id] = effect if !disposed?
  end

  def remove_effect(key)
    @effects.delete(key) if !disposed?
  end

  def refresh_tone
    @tone = nil
    return if !@map_settings
    if @map_settings.type == :custom
      @tone = @map_settings.tone
    elsif @map.metadata&.has_flag?("Cave")
      @tone = @map_settings.tone || Tone.new(0, 0, 0, 150)
    elsif canopy? && !night?
      @tone = @map_settings.tone || Tone.new(-60, -60, -40, 0)
    elsif outside?
      @tone = PBDayNight.getTone
    end
  end

  def refresh_attached
    return if !@tone
    return if @effects.length == 0
    @effects.each do |key, effect|
      next if !effect.event
      next if !should_update?(effect)
      event = effect.event
      effect.x = (event.real_x / 4).round + (event.width * Game_Map::TILE_WIDTH / 2)
      effect.y = (event.real_y / 4).round + 32 - event.sprite_size[1] / 2
    end
  end

  # ============================================================================
  # ANIMATIONS: Saw wave function for smooth 0→1→0 cycles
  # ============================================================================
  def saw_wave(time, period)
    cycle_position = (time % period) / period.to_f
    if cycle_position < 0.5
      cycle_position * 2
    else
      (1 - cycle_position) * 2
    end
  end

  # ============================================================================
  # ANIMATIONS: Main bitmap refresh with pulsating lights
  # ============================================================================
  def refresh_bitmap
    @bitmap.clear
    return if !@tone
    @bitmap.fill_rect(0, 0, @bitmap.width, @bitmap.height, Color.black)
    return if @effects.length == 0
    
    # Calculate pulsating animation
    anim = (saw_wave(Graphics.frame_count, 2 * Graphics.frame_rate) * @anim_mult)
    
    # Multi-layer glow effect
    cmult = (1.0 / @fadefactor) ** (@numfades - 1)
    
    effects = @effects.filter { |key, effect| should_update?(effect) }
    
    # Draw multiple layers with decreasing opacity
    for j in 1..@numfades
      # Darkness: j=1→170 (Outer), j=3→0 (Center/Hole)
      base_opacity = 255.0 * (@numfades - j) / @numfades
      
      effects.each do |key, effect|
        center_x = effect.x - (@map.display_x / Game_Map::X_SUBPIXELS).round + PADDING
        center_y = effect.y - (@map.display_y / Game_Map::Y_SUBPIXELS).round + PADDING
        case effect.type
        when :circle
          radius = (effect.radius + [effect.radius, 160].min * (cmult - 1)).to_i
          radius += ([radius, 160].min * anim).to_i if !effect.stop_anim
          draw_circle(center_x, center_y, radius, base_opacity)
        when :rect
          expansion_multiplier = 2.0
          base_width  = (effect.width_px + [effect.width_px, 160].min * (cmult - 1) * expansion_multiplier).to_i
          base_height = (effect.height_px + [effect.height_px, 160].min * (cmult - 1) * expansion_multiplier).to_i
          if !effect.stop_anim
            anim_expansion = ([base_width, 160].min * anim).to_i
            width  = base_width + anim_expansion
            height = base_height + anim_expansion
          else
            width  = base_width
            height = base_height
          end
          
          # Center the rectangle symmetrically
          draw_x = center_x - (width / 2) - 16
          draw_y = center_y - (height / 2) - 16
          draw_rect(draw_x, draw_y, width, height, base_opacity)
        when :bitmap
          next if j > 1
          center_x = center_x - 16
          center_y = center_y - 16
          anim = 0 if effect.stop_anim
          draw_bitmap(center_x, center_y, @effects_bitmaps[key], anim)
        end
      end
      cmult = cmult * @fadefactor
    end
  end

  def refresh_sprite
    @sprite_add.bitmap = @bitmap
    @sprite_sub.bitmap = @bitmap
    @sprite_sub.bitmap = @bitmap
    if @tone
      add_red   = [@tone.red, 0].max
      add_green = [@tone.green, 0].max
      add_blue  = [@tone.blue, 0].max
      @sprite_add.tone = Tone.new(add_red, add_green, add_blue)
      @sprite_add.opacity = @tone.gray
      sub_red   = [@tone.red, 0].min * -1
      sub_green = [@tone.green, 0].min * -1
      sub_blue  = [@tone.blue, 0].min * -1
      @sprite_sub.tone = Tone.new(sub_red, sub_green, sub_blue)
    else
      @sprite_add.tone = Tone.new(0, 0, 0, 0)
      @sprite_sub.tone = Tone.new(0, 0, 0, 0)
      @sprite_add.opacity = 0
      @sprite_sub.opacity = 0
    end
  end

  def refresh_overlay; end
  def refresh_pattern; end

  def update_light_sprites
    # Remove sprites for deleted effects or effects that lost color
    @light_sprites.each_key do |id|
      if !@effects[id] || !@effects[id].color || !should_update?(@effects[id])
        @light_sprites[id].bitmap.dispose if @light_sprites[id].bitmap
        @light_sprites[id].dispose
        @light_sprites.delete(id)
      end
    end

    # Global animation calculation (same as refresh_bitmap)
    anim = (saw_wave(Graphics.frame_count, 2 * Graphics.frame_rate) * @anim_mult)
    # Scale factor: 1.0 + amount of expansion (e.g., 0.1 for 10% breathing)
    scale = 1.0 + (anim * 0.1)

    @light_sprites.each do |id, sprite|
       next if !@effects[id]
       effect = @effects[id]
       
       # Sync Position
       sprite.x = effect.x - (@map.display_x / Game_Map::X_SUBPIXELS).round
       sprite.y = effect.y - (@map.display_y / Game_Map::Y_SUBPIXELS).round
       
       # Apply Animation
       if !effect.stop_anim
         sprite.zoom_x = scale
         sprite.zoom_y = scale
       else
         sprite.zoom_x = 1.0
         sprite.zoom_y = 1.0
       end
    end

    # Create new sprites
    @effects.each do |id, effect|
      create_light_sprite(effect) if !@light_sprites[id]
    end
  end

  def create_light_sprite(effect)
    # Prevent duplication
    if @light_sprites[effect.id] && !@light_sprites[effect.id].disposed?
       return
    end

    # Use the main map viewport (Z=0) for proper layering with priority tile sprites
    target_viewport = @viewport
    
    sprite = Sprite.new(target_viewport)
    sprite.blend_type = 1 # Additive
    sprite.z = 2          # Ground layer - will be below priority tiles (Z=100+)
    
    radius = effect.radius
    # Expand radius to cover the "fades" halo and animation pulse
    # The hole logic expands up to ~1.3x so 1.5x is safe
    real_radius = (radius * 1.5).ceil
    diameter = real_radius * 2
    bitmap = Bitmap.new(diameter, diameter)
    
    # Draw Radial Gradient
    # Center: Color, Edge: Transparent
    color = effect.color
    
    # Optimized gradient drawing
    cx = real_radius
    cy = real_radius
    
    # Scanline approach for smooth gradient
    for y in 0...diameter
      for x in 0...diameter
        dx = x - cx
        dy = y - cy
        dist = Math.sqrt(dx*dx + dy*dy)
        if dist <= real_radius
           if effect.id == :follower_light
             # HOLLOW CENTER (Ring Effect)
             # 1. Inner Fade: 0 at center -> 1 at 16px (allows character to be seen)
             inner_fade = [dist / 16.0, 1.0].min
             
             # 2. Outer Fade: Normal falloff
             outer_fade = ((1.0 - (dist / real_radius)) ** 0.5)
             
             # Combine
             alpha = 255.0 * inner_fade * outer_fade
           else
             # Root falloff: Alpha 255 (Center) -> 0 (Edge of expanded radius)
             alpha = 255.0 * ((1.0 - (dist / real_radius)) ** 0.5)
           end
           
           bitmap.set_pixel(x, y, Color.new(color.red, color.green, color.blue, alpha))
        end
      end
    end
    
    sprite.bitmap = bitmap
    sprite.ox = real_radius
    sprite.oy = real_radius
    
    @light_sprites[effect.id] = sprite
  end

  def update
    # Debug: Print Map ID change
    if $game_map && $game_map.map_id != @last_map_id
      echoln("Lighting: Map Transition Detected! (Old: #{@last_map_id} -> New: #{$game_map.map_id})")
       @last_map_id = $game_map.map_id
       refresh_all(true)
    end
    
    return if !@map_settings
    # Follower light removed by user request
    # update_follower_light 

    refresh_all
  end

  # Follower light feature removed
  def update_follower_light
    return 
  end

  def refresh_all(force_new_setup = false)
    if force_new_setup
      setup_map
      setup_effects
      setup_overlay
    end
    refresh_tone
    refresh_attached
    # update_follower_light
    update_light_sprites
    refresh_bitmap
    refresh_sprite
    refresh_overlay
    refresh_pattern
  end

  # ============================================================================
  # DRAWING: Circle with mathematical calculation
  # ============================================================================
  def draw_circle(cx, cy, radius, opacity, target_bitmap = @bitmap, color = nil)
    for i in -radius..radius
      y = i + cy
      next if y < 0
      next if y > target_bitmap.height
      next if (y % @resolution) != 0
      diff2 = (radius * radius) - (i * i)
      diff = Math.sqrt(diff2)
      
      if color
        # Draw colored glow
        draw_col = Color.new(color.red, color.green, color.blue, opacity)
        target_bitmap.fill_rect(cx - diff, y, diff * 2, @resolution, draw_col)
      else
        # Draw darkness mask
        col = Color.black
        col.alpha = opacity
        target_bitmap.fill_rect(cx - diff, y, diff * 2, @resolution, col)
      end
    end
  end

  # ============================================================================
  # DRAWING: Rectangle with simple fill (no rounded corners)
  # ============================================================================
  def draw_rect(x, y, width, height, opacity, target_bitmap = @bitmap, color = nil, radius = 0)
    if color
       draw_col = Color.new(color.red, color.green, color.blue, opacity)
       target_bitmap.fill_rect(x, y, width, height, draw_col)
    else
      col = Color.black
      col.alpha = opacity
      # Simple filled rectangle - sharp corners create square light effect
      target_bitmap.fill_rect(x, y, width, height, col)
    end
  end

  # ============================================================================
  # DRAWING: Bitmap-based light with stretch animation
  # ============================================================================
  def draw_bitmap(x, y, bitmap, stretch = 1)
    return unless bitmap
    width = [bitmap.width, 96].min
    height = [bitmap.height, 96].min
    stretch_x = (width * stretch).abs
    stretch_y = (height * stretch).abs
    @bitmap.fill_rect(x - stretch_x, y - stretch_y, bitmap.width + stretch_x, bitmap.height + stretch_y, Color.new(0, 0, 0, 0))
    @bitmap.stretch_blt(Rect.new(x - stretch_x, y - stretch_y, bitmap.width + stretch_x, bitmap.height + stretch_y), 
      bitmap, Rect.new(0, 0, bitmap.width, bitmap.height))
  end

  def show_all
    @sprite_add.visible = true
    @sprite_sub.visible = true
    @light_sprites.each_value { |s| s.visible = true }
    @overlay.visible = true
  end

  def hide_all
    @sprite_add.visible = false
    @sprite_sub.visible = false
    @light_sprites.each_value { |s| s.visible = false }
    @overlay.visible = false
  end

  def outside?
    return GameData::MapMetadata.exists?(@map.map_id) && GameData::MapMetadata.get(@map.map_id).outdoor_map
  end

  def night?
    return PBDayNight.isNight?
  end

  def canopy?
    return @map.metadata&.has_flag?("Forest")
  end

  def should_update?(effect)
    return true if effect.id == :follower_light # ALWAYS UPDATE FOLLOWER LIGHT
    return false if effect.hide
    return false if outside? && night? && effect.day == true
    return false if outside? && !night? && effect.day == false
    return true
  end

  def flick(key)
    @effects[key].flick if @effects[key]
  end

  def hide(key)
    @effects[key].hide = true if @effects[key]
  end

  def show(key)
    @effects[key].hide = false if @effects[key]
  end

  def get(key)
    return @effects[key] if @effects[key]
  end

  def attach(key, event)
    event = event.id if !event.is_a?(Integer)
    @effects[key].event = event
  end

  def detach(key)
    @effects[key].event = nil
  end

  def dispose
    @bitmap.dispose
    @sprite_add.dispose
    @sprite_sub.dispose
    @light_sprites.each_value { |sprite| sprite.bitmap.dispose if sprite.bitmap; sprite.dispose }
    @light_sprites.clear

    @overlay.dispose
    @effects_bitmaps.each_value {|bitmap| bitmap.dispose if bitmap}
    @map_settings = nil
    @effects = nil
    @effects_bitmaps = nil
    @disposed = true
  end

  def disposed?
    return @disposed
  end

  def loaded?
    return !@disposed
  end
end
