# ===============================================================================
# Debug Tools für Lighting System
# ===============================================================================

# Zeige Map-Koordinaten bei Tastendruck
EventHandlers.add(:on_frame_update, :lighting_debug,
  proc {
    if Input.press?(Input::CTRL) && Input.trigger?(Input::USE)
      x = $game_player.x
      y = $game_player.y
      pbMessage("Position: X=#{x}, Y=#{y}\\nMap ID: #{$game_map.map_id}")
    end
  }
)

# Debug-Menü für Lighting
MenuHandlers.add(:debug_menu, :lighting_system, {
  "name"        => _INTL("Lighting System"),
  "parent"      => :field_menu,
  "description" => _INTL("Add/remove lights at current position."),
  "effect"      => proc { |menu|
    commands = []
    commands.push(_INTL("Add Circle Light Here"))
    commands.push(_INTL("Add Rect Light Here"))
    commands.push(_INTL("List All Lights"))
    commands.push(_INTL("Remove Nearest Light"))
    commands.push(_INTL("Toggle All Lights"))
    commands.push(_INTL("Add Small Circle Light"))
    commands.push(_INTL("Add Red Circle Light"))
    commands.push(_INTL("Add Blue Circle Light"))
    commands.push(_INTL("Add Yellow Circle Light"))
    
    choice = pbMessage(_INTL("Lighting Debug"), commands, -1)
    
    case choice
    when 0  # Add Circle Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_circle_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :circle,
        :radius => 64,
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Circle light added at (#{x}, #{y})\\nID: #{id}")
      
    when 1  # Add Rect Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_rect_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :rect,
        :width => 1,
        :height => 1,
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Rect light added at (#{x}, #{y})\\nID: #{id}")
      
    when 2  # List All Lights
      lights = []
      GameData::LightEffect.each do |effect|
        next if effect.map_id != $game_map.map_id
        lights.push("#{effect.id}: (#{effect.map_x}, #{effect.map_y}) - #{effect.type}")
      end
      if lights.empty?
        pbMessage("No lights on this map.")
      else
        pbMessage("Lights on Map #{$game_map.map_id}:\\n" + lights.join("\\n"))
      end
      
    when 3  # Remove Nearest Light
      # TODO: Implementierung
      pbMessage("Not yet implemented")
      
    when 4  # Toggle All Lights
      if $scene.spritesetGlobal.lighting
        if $scene.spritesetGlobal.lighting.disposed?
          pbMessage("Lighting system is disposed")
        else
          GameData::LightEffect.each do |effect|
            next if effect.map_id != $game_map.map_id
            $scene.spritesetGlobal.lighting.flick(effect.id)
          end
          pbMessage("Toggled all lights on this map")
        end
      end
    when 5  # Add Small Circle Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_small_circle_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :circle,
        :radius => 32,
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Small circle light added at (#{x}, #{y})\\nID: #{id}")
      
    when 6  # Add Red Circle Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_red_circle_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :circle,
        :radius => 64,
        :color => Color.new(255, 0, 0),
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Red circle light added at (#{x}, #{y})\\nID: #{id}")

    when 7  # Add Blue Circle Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_blue_circle_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :circle,
        :radius => 64,
        :color => Color.new(0, 0, 255),
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Blue circle light added at (#{x}, #{y})\\nID: #{id}")

    when 8  # Add Yellow Circle Light
      x = $game_player.x
      y = $game_player.y
      id = "debug_yellow_circle_#{x}_#{y}_#{rand(1000)}".to_sym
      GameData::LightEffect.add({
        :id => id,
        :type => :circle,
        :radius => 64,
        :color => Color.new(255, 255, 0),
        :map_x => x,
        :map_y => y,
        :map_id => $game_map.map_id,
        :day => false
      })
      $scene.spritesetGlobal.lighting.refresh_all(true)
      pbMessage("Yellow circle light added at (#{x}, #{y})\\nID: #{id}")
    end
  }
})

# Schnellbefehl: Strg+L = Position anzeigen und Licht hinzufügen
EventHandlers.add(:on_frame_update, :quick_add_light,
  proc {
    if Input.press?(Input::CTRL) && Input.trigger?(Input::L)
      x = $game_player.x
      y = $game_player.y
      pbMessage("GameData::LightEffect.add({\\n" +
                "  :id => :light_#{x}_#{y},\\n" +
                "  :type => :rect,\\n" +
                "  :width => 1,\\n" +
                "  :height => 1,\\n" +
                "  :map_x => #{x},\\n" +
                "  :map_y => #{y},\\n" +
                "  :map_id => #{$game_map.map_id},\\n" +
                "  :day => false\\n" +
                "})")
    end
    
    # Strg+L = Lighting Info
    if Input.press?(Input::CTRL) && Input.trigger?(Input::L)
      if $scene.is_a?(Scene_Map) && $scene.instance_variable_get(:@spritesetGlobal)
        lighting = $scene.instance_variable_get(:@spritesetGlobal).lighting
        if lighting
          msg = "Lighting System Active\\n"
          msg += "Map ID: #{$game_map.map_id}\\n"
          msg += "Disposed: #{lighting.disposed?}\\n"
          msg += "Night: #{lighting.night?}\\n"
          msg += "Outside: #{lighting.outside?}\\n"
          effects_count = 0
          GameData::LightEffect.each { |e| effects_count += 1 if !e.map_id || e.map_id == $game_map.map_id }
          msg += "Effects on map: #{effects_count}"
          pbMessage(msg)
        else
          pbMessage("Lighting system not initialized!")
        end
      end
    end
  }
)
