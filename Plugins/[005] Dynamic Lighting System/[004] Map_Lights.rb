# Map lighting definitions
PURPLE_HOUSE_MAP_ID = 43
PURPLE_HOUSE_BASE_X = 9
PURPLE_HOUSE_BASE_Y = 18

def add_window_light(id, x_offset, y_offset)
  GameData::LightEffect.add({
    id: id,
    type: :rect,
    width: 1,
    height: 1,
    map_x: PURPLE_HOUSE_BASE_X + x_offset,
    map_y: PURPLE_HOUSE_BASE_Y + y_offset,
    map_id: PURPLE_HOUSE_MAP_ID,
    day: false,
    stop_anim: false
  })
end

add_window_light(:house_purple_window_top_left, 0, 0)
add_window_light(:house_purple_window_top_center_left, 1, 0)
add_window_light(:house_purple_window_top_center_right, 2, 0)
add_window_light(:house_purple_window_top_right, 3, 0)
add_window_light(:house_purple_window_mid_left, 0, 1)
add_window_light(:house_purple_window_mid_center_left, 1, 1)
add_window_light(:house_purple_window_mid_center_right, 2, 1)
add_window_light(:house_purple_window_mid_right, 3, 1)
add_window_light(:house_purple_window_bot_left, 0, 2)
add_window_light(:house_purple_window_bot_center_left, 1, 2)
add_window_light(:house_purple_window_bot_center_right, 2, 2)
add_window_light(:house_purple_window_bot_right, 3, 2)
