util.init_hosted()

local json = require "json"
local departures = {}
local stop_sign = resource.load_image("stvo_224.png")
local white = resource.create_colored_texture(1,1,1,1)
local gray = resource.create_colored_texture(0.8,0.8,0.8,1)
local accent_base = resource.create_colored_texture(0,0.4,0,5)
local base_time = N.base_time or 0

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

util.file_watch("departures.json", function(content)
    departures = json.decode(content)
end)

util.data_mapper{
    ["clock/set"] = function(time)
        base_time = tonumber(time) - sys.now()
        N.base_time = base_time
    end;
}

local function unixnow()
    return base_time + sys.now()
end

function node.render()
    gl.clear(0,0,0,1)
    local now = unixnow()
    local y = 240
    local color = 0

    stop_sign:draw(20, 20, 150, 150)

    time_string = os.date("%H:%M", now)
    time_width = CONFIG.font:width(time_string, CONFIG.font_size)
    time_x = NATIVE_WIDTH-20-time_width
    CONFIG.font:write(time_x, 20, time_string, CONFIG.font_size, 1,1,1,1)

    local divisor = #departures*CONFIG.duration
    local dep_step = math.floor((sys.now() % divisor)/CONFIG.duration)+1

    deps = departures[dep_step]

    stop_string = deps.name
    stop_width = CONFIG.font:width(stop_string, CONFIG.font_size_station)
    stop_x = ((NATIVE_WIDTH-190-time_width)/2)-(stop_width/2)
    stop_y = 95-(CONFIG.font_size_station/2)
    CONFIG.font:write(stop_x+160, stop_y, stop_string, CONFIG.font_size_station, 1,1,1,1)

    accent_base:draw(0, 190, NATIVE_WIDTH, 230)

    scheduled_width = CONFIG.font:width("Planmäßig", 30)
    actual_width = CONFIG.font:width("Heute", 30)
    track_width = CONFIG.font:width("Steig", 30)

    scheduled_x = 100-(scheduled_width/2)
    actual_x = 300-(actual_width/2)
    track_x = NATIVE_WIDTH-100-(track_width/2)

    CONFIG.font:write(scheduled_x, 195, "Planmäßig", 30, 1,1,1,1)
    CONFIG.font:write(actual_x, 195, "Heute", 30, 1,1,1,1)
    CONFIG.font:write(track_x, 195, "Steig", 30, 1,1,1,1)

    now_offset = now + (CONFIG.offset * 60)

    for idx, dep in ipairs(deps.departures) do
        if dep.timestamp > now_offset then
            if color == 0 then
                white:draw(0, y-10, NATIVE_WIDTH, y+10+CONFIG.font_size)
                color = 1
            else
                gray:draw(0, y-10, NATIVE_WIDTH, y+10+CONFIG.font_size)
                color = 0
            end

            scheduled_width = CONFIG.font:width(dep.scheduled, CONFIG.font_size)
            actual_width = CONFIG.font_actual:width(dep.actual, CONFIG.font_size)
            track_width = CONFIG.font:width(dep.track, CONFIG.font_size)

            scheduled_x = 100-(scheduled_width/2)
            actual_x = 300-(actual_width/2)
            track_x = NATIVE_WIDTH-100-(track_width/2)

            CONFIG.font:write(scheduled_x, y, dep.scheduled, CONFIG.font_size, 0,0,0,1)
            CONFIG.font_actual:write(actual_x, y, dep.actual, CONFIG.font_size, 0,0.4,0,5)
            CONFIG.font:write(450, y, dep.direction, CONFIG.font_size, 0,0,0,1)
            CONFIG.font:write(track_x, y, dep.track, CONFIG.font_size, 0,0,0,1)

            y = y+20+CONFIG.font_size

            if y > NATIVE_HEIGHT then
                break
            end
        end
    end
end
