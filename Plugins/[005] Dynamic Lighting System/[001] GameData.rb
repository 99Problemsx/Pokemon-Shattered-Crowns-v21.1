# ===============================================================================
# Dynamic Lighting System for Pokémon Essentials v21.1
# ===============================================================================
# This plugin adds a dynamic lighting system with:
# - Circle and rectangular light sources
# - Bitmap-based custom light shapes
# - Pulsating animations
# - Day/Night conditional lighting
# - Event-attached lights (follow characters)
# - Multi-layer glow effects
# ===============================================================================

module GameData
  class LightEffect
    attr_reader :id
    attr_reader :type              # :circle, :rect, :bitmap
    attr_reader :tone              
    attr_accessor :map_x                 
    attr_accessor :map_y   
    attr_reader :map_id
    attr_accessor :radius
    attr_reader :color
    attr_reader :width
    attr_reader :height
    attr_reader :stop_anim
    attr_reader :hide
    attr_reader :day
    attr_writer :x                 
    attr_writer :y
    attr_writer :event

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def self.add(hash)
      hash[:id] = rand(1000000) unless hash[:id]
      hash[:map_id] = $game_map.map_id if !hash.key?(:map_id) && $game_map
      self.register(hash)
    end

    def self.bulk_add_circle(map_id, coords, radius = 64, day = false)
      coords.each do |coord|
        hash = {
          :id => rand(1000000),
          :map_id => map_id, 
          :type => :circle,
          :radius => radius,
          :map_x => coord[0], 
          :map_y => coord[1],
          :day => day
        }
        self.register(hash)
      end
    end

    def initialize(hash)
      @id           = hash[:id]         || nil
      @type         = hash[:type]
      @map_x        = hash[:map_x]
      @map_y        = hash[:map_y]
      @map_id       = hash[:map_id]
      @tone         = hash[:tone]       || nil
      @radius       = hash[:radius]     || 64
      @color        = hash[:color]      || nil
      @width        = hash[:width]      || 2
      @height       = hash[:height]     || 2
      @bitmap_path  = hash[:bitmap]     || nil
      @stop_anim    = hash[:stop_anim]  || false
      @hide         = hash[:hide]       || false
      @day          = hash[:day]        || false
      @x            = hash[:x]          || nil
      @y            = hash[:y]          || nil
      @event        = hash[:event]      || nil
    end

    def bitmap
      return @bitmap_path
    end

    def flick
      @hide = !@hide
      return @hide
    end

    def hide=(v)
      @hide = v
    end

    def x
      return (@x) ? @x : @map_x * Game_Map::TILE_WIDTH + Game_Map::TILE_WIDTH / 2 
    end

    def y 
      return (@y) ? @y : @map_y * Game_Map::TILE_HEIGHT + Game_Map::TILE_HEIGHT / 2 
    end

    def event
      return pbMapInterpreter.get_character(@event)
    end

    def width_px; return @width * Game_Map::TILE_WIDTH; end
    def height_px; return @height * Game_Map::TILE_HEIGHT; end
  end

  class LightMap
    attr_reader :id                # :map_id
    attr_reader :type              # :night, :cave, :forest, :custom
    attr_reader :tone                
    attr_reader :overlay           # [Color, radius, rings]
    attr_reader :spawn_proc

    DATA = {}

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id         = hash[:id]
      @type       = hash[:type]
      @tone       = hash[:tone]     || nil
      @overlay    = hash[:overlay]  || nil
      @spawn_proc = hash[:spawn_proc]
    end

    def call_spawn(*args)
      return (@spawn_proc) ? @spawn_proc.call(*args) : true
    end
  end
end
