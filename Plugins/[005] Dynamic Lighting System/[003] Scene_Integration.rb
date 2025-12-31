# ===============================================================================
# Integration with Scene_Map
# ===============================================================================

class Scene_Map
  alias lighting_createSpritesets createSpritesets
  def createSpritesets
    lighting_createSpritesets
    # Get viewport from Spriteset_Map class (@@viewport1)
    viewport = Spriteset_Map.viewport
    if @spritesetGlobal && @spritesetGlobal.lighting && !@spritesetGlobal.lighting.disposed?
      @spritesetGlobal.lighting.dispose
    end
    @spritesetGlobal.lighting = Lighting.new($game_map, viewport) if @spritesetGlobal && viewport
  end
  
  alias lighting_transfer_player transfer_player
  def transfer_player(cancelVehicles = true)
    lighting_transfer_player(cancelVehicles)
    # Refresh lighting when changing maps
    if @spritesetGlobal && @spritesetGlobal.lighting && !@spritesetGlobal.lighting.disposed?
      @spritesetGlobal.lighting.refresh_all(true)
    end
  end
end

class Spriteset_Global
  attr_accessor :lighting
  
  alias lighting_update update
  def update
    lighting_update
    @lighting&.update
  end
  
  alias lighting_dispose dispose
  def dispose
    @lighting&.dispose
    lighting_dispose
  end
end

# ===============================================================================
# Default light map (fallback for maps without settings)
# ===============================================================================

GameData::LightMap.register({
  :id => 0,
  :type => :default
})
