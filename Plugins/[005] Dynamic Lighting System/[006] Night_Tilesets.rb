# ===============================================================================
# Night Tileset System - Automatic _n tileset/autotile loading at night
# For Pokémon Essentials v21.1
# ===============================================================================

module GameData
  class MapMetadata
    # Add field to disable night tilesets for specific maps
    attr_accessor :disable_night_tileset
  end
end

# ===============================================================================
# Helper Module for Night Graphics
# ===============================================================================

module NightTilesetHelper
  def self.night_tileset_enabled?
    return false if !$game_map
    metadata = GameData::MapMetadata.try_get($game_map.map_id)
    return false if metadata&.disable_night_tileset
    return true
  end
  
  def self.get_night_variant(filename)
    return nil if !PBDayNight.isNight? || !night_tileset_enabled?
    return nil if filename.nil? || filename.empty?
    
    # Try _n variant (before extension)
    night_filename = filename.sub(/(\.\w+)$/, '_n\1')
    
    # Check if the night variant exists
    # Try with and without extension for pbResolveBitmap
    base_night = night_filename.sub(/\.\w+$/, '')
    return night_filename if pbResolveBitmap(base_night)
    
    # Debug output
    # echoln("[Night Tilesets] Checked for: #{base_night} - Not found") if $DEBUG
    
    return nil
  end
end

# ===============================================================================
# AnimatedBitmap Override - Load night variants
# ===============================================================================

class AnimatedBitmap
  alias night_tileset_initialize initialize
  
  def initialize(file, hue = 0)
    # Check for night variant
    if file.is_a?(String)
      night_file = NightTilesetHelper.get_night_variant(file)
      file = night_file if night_file
    end
    
    # Call original initialize
    night_tileset_initialize(file, hue)
  end
end

# ===============================================================================
# Tileset and Autotile Loading Functions Override
# ===============================================================================

# Override pbGetTileset to support night variants
alias night_pbGetTileset pbGetTileset
def pbGetTileset(name, hue = 0)
  # Check for night variant
  if PBDayNight.isNight? && NightTilesetHelper.night_tileset_enabled?
    # Handle name with or without extension
    base_name = name.sub(/\.\w+$/, '')  # Remove extension if present
    night_name = base_name + "_n"
    
    # echoln("[Night Tilesets] Checking for night tileset: Graphics/Tilesets/#{night_name}") if $DEBUG
    
    if pbResolveBitmap("Graphics/Tilesets/" + night_name)
      # echoln("[Night Tilesets] SUCCESS! Loading night tileset: #{night_name}")
      return AnimatedBitmap.new("Graphics/Tilesets/" + night_name, hue).deanimate
    else
      # echoln("[Night Tilesets] Not found, using day version: #{name}") if $DEBUG
    end
  end
  
  # Fall back to original
  return night_pbGetTileset(name, hue)
end

# Override pbGetAutotile to support night variants
alias night_pbGetAutotile pbGetAutotile
def pbGetAutotile(name, hue = 0)
  # Check for night variant
  if PBDayNight.isNight? && NightTilesetHelper.night_tileset_enabled?
    # Handle name with or without extension
    base_name = name.sub(/\.\w+$/, '')  # Remove extension if present
    night_name = base_name + "_n"
    
    # echoln("[Night Tilesets] Checking for night autotile: Graphics/Autotiles/#{night_name}") if $DEBUG
    
    if pbResolveBitmap("Graphics/Autotiles/" + night_name)
      # echoln("[Night Tilesets] SUCCESS! Loading night autotile: #{night_name}")
      return AnimatedBitmap.new("Graphics/Autotiles/" + night_name, hue).deanimate
    else
      # echoln("[Night Tilesets] Not found, using day version: #{name}") if $DEBUG
    end
  end
  
  # Fall back to original
  return night_pbGetAutotile(name, hue)
end

# Override pbGetTileBitmap to support night variants
alias night_pbGetTileBitmap pbGetTileBitmap
def pbGetTileBitmap(filename, tile_id, hue, width = 1, height = 1)
  # Check for night variant
  if PBDayNight.isNight? && NightTilesetHelper.night_tileset_enabled?
    # Handle filename with or without extension
    base_filename = filename.sub(/\.\w+$/, '')  # Remove extension if present
    night_filename = base_filename + "_n"
    
    # echoln("[Night Tilesets] Checking for night tile bitmap: Graphics/Tilesets/#{night_filename}") if $DEBUG
    
    if pbResolveBitmap("Graphics/Tilesets/" + night_filename)
      # echoln("[Night Tilesets] SUCCESS! Loading night tile bitmap: #{night_filename}")
      return RPG::Cache.tileEx(night_filename, tile_id, hue, width, height) do |f|
        AnimatedBitmap.new("Graphics/Tilesets/" + night_filename).deanimate
      end
    else
      # echoln("[Night Tilesets] Not found, using day version: #{filename}") if $DEBUG
    end
  end
  
  # Fall back to original
  return night_pbGetTileBitmap(filename, tile_id, hue, width, height)
end

# ===============================================================================
# Tilemap Integration - Refresh tilesets when day/night changes
# ===============================================================================

# ===============================================================================
# Global Day/Night State Tracker
# ===============================================================================

module NightTilesetTracker
  @last_night_state = nil
  
  def self.check_and_update
    return if !$scene.is_a?(Scene_Map)
    return if !$game_map
    
    current_night = PBDayNight.isNight?
    
    # Initialize on first check
    if @last_night_state.nil?
      @last_night_state = current_night
      return
    end
    
    # If state changed, trigger refresh
    if @last_night_state != current_night
      # echoln("[Night Tilesets] Day/Night changed! (Night: #{current_night})")
      @last_night_state = current_night
      refresh_map_graphics
    end
  end
  
  def self.refresh_map_graphics
    return if !$scene.is_a?(Scene_Map)
    
    # echoln("[Night Tilesets] Refreshing map graphics...")
    
    # Dispose old lighting system completely
    if $scene.spritesetGlobal && $scene.spritesetGlobal.lighting
      # echoln("[Night Tilesets] Disposing old lighting system...")
      $scene.spritesetGlobal.lighting.dispose
      $scene.spritesetGlobal.lighting = nil
    end
    
    # Dispose and recreate spriteset to reload tilesets
    if $scene.spriteset
      $scene.disposeSpritesets
      $scene.createSpritesets  # This will also recreate the lighting system
      # echoln("[Night Tilesets] Map graphics and lighting refreshed successfully")
    end
  end
  
  def self.reset
    @last_night_state = nil
  end
end

# Check for day/night changes every frame
EventHandlers.add(:on_frame_update, :night_tileset_tracker,
  proc {
    NightTilesetTracker.check_and_update
  }
)

# Reset tracker when entering a new map
EventHandlers.add(:on_enter_map, :night_tileset_reset,
  proc {
    NightTilesetTracker.reset
  }
)

# ===============================================================================
# Character Graphics with Night Variants (for Events)
# ===============================================================================

class Game_Event
  alias night_tileset_character_name character_name
  
  def character_name
    original_name = night_tileset_character_name
    
    # Check for _n variant at night
    if original_name && !original_name.empty? && PBDayNight.isNight?
      night_name = original_name + "_n"
      if pbResolveBitmap("Graphics/Characters/#{night_name}")
        return night_name
      end
    end
    
    return original_name
  end
end

# ===============================================================================
# Debug Commands
# ===============================================================================

EventHandlers.add(:on_frame_update, :night_tileset_debug,
  proc {
    # Ctrl+Shift+N = Toggle Night Tileset Debug Info
    if Input.press?(Input::CTRL) && Input.press?(Input::SHIFT) && Input.trigger?(Input::N)
      night_state = PBDayNight.isNight? ? "NIGHT" : "DAY"
      metadata = GameData::MapMetadata.try_get($game_map.map_id)
      disabled = metadata&.disable_night_tileset ? "YES" : "NO"
      
      msg = "Night Tileset System\\n"
      msg += "Map ID: #{$game_map.map_id}\\n"
      msg += "Time State: #{night_state}\\n"
      msg += "Disabled: #{disabled}\\n"
      msg += "\\nPlace _n variants of tilesets in:\\n"
      msg += "Graphics/Tilesets/\\n"
      msg += "Graphics/Autotiles/\\n"
      msg += "Graphics/Characters/"
      
      pbMessage(msg)
    end
  }
)
