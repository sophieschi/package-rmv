util.init_hosted()

local json = require "json"
local departures = {}
local rotate_before = nil
local transform = nil

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

util.file_watch("departures.json", function(content)
    departures = json.decode(content)
end)

local white = resource.create_colored_texture(1,1,1,1)
local base_time = N.base_time or 0

util.data_mapper{
    ["clock/set"] = function(time)
        base_time = tonumber(time) - sys.now()
        N.base_time = base_time
    end;
}

local function unixnow()
    return base_time + sys.now()
end

local colored = resource.create_shader[[
    uniform vec4 color;
    void main() {
        gl_FragColor = color;
    }
]]

local fadeout = 5
local categories = {}
categories[0] = resource.load_image("fern.png")
categories[1] = resource.load_image("fern.png")
categories[2] = resource.load_image("regio.png")
categories[3] = resource.load_image("sbahn.png")
categories[4] = resource.load_image("ubahn.png")
categories[5] = resource.load_image("tram.png")
categories[6] = resource.load_image("bus.png")

function node.render()
    if rotate_before ~= CONFIG.rotate then
        transform = util.screen_transform(CONFIG.rotate)
        rotate_before = CONFIG.rotate
    end

    if rotate_before == 90 or rotate_before == 270 then
        real_width = NATIVE_HEIGHT
        real_height = NATIVE_WIDTH
    else
        real_width = NATIVE_WIDTH
        real_height = NATIVE_HEIGHT
    end
    transform()
    CONFIG.background_color.clear()
    local now = unixnow()
    local y = 0
    local now_for_fade = now + (CONFIG.offset * 60)

    local line_height = CONFIG.line_height
    local margin_bottom = CONFIG.line_height * 0.2

    for idx, dep in ipairs(departures) do
        if dep.date > now_for_fade - fadeout then
            if now_for_fade > dep.date then
                y = (y - line_height - margin_bottom) / fadeout * (now_for_fade - dep.date)
            end
        end
    end

    for idx, dep in ipairs(departures) do
        if dep.date > now_for_fade - fadeout then
            if y < 0 and dep.date >= now_for_fade then
                y = 0
            end

            local time = dep.nice_date

            local remaining = math.floor((dep.date - now) / 60)
            local append = ""
            local platform = ""
            local x = 0

            if remaining < 0 then
                time = "In der Vergangenheit"
                if dep.next_date then
                    append = string.format("und in %d min", math.floor((dep.next_date - now)/60))
                end
            elseif remaining < 1 then
                if now % 2 < 1 then
                    time = "*jetzt"
                else
                    time = "jetzt*"
                end
                if dep.next_date then
                    append = string.format("und in %d min", math.floor((dep.next_date - now)/60))
                end
            elseif remaining < 11 then
                time = string.format("in %d min", ((dep.date - now)/60))
                if dep.next_nice_date then
                    append = "und wieder " .. math.floor((dep.next_date - dep.date)/60) .. " min später"
                end
            else
                time = time -- .. " +" .. remaining
                if dep.next_nice_date then
                    append = "und wieder " .. dep.next_nice_date
                end
            end

            if string.match(CONFIG.stop, ',') then
                platform = "von " .. dep.stop
                if dep.platform ~= "" then
                    platform = platform .. ", Hst " .. dep.platform
                end
            else
                if dep.platform ~= "" then
                    platform = "von " .. dep.platform
                end
            end
            stop_r, stop_g, stop_b = 1,1,1

            if remaining < 11 then
                icon_size = line_height * 0.66
                text_upper_size = line_height * 0.5
                text_lower_size = line_height * 0.3
                symbol_height = text_upper_size + text_lower_size + margin_bottom

                if CONFIG.showtype then
                    categories[tonumber(dep.category)]:draw(0, y, icon_size, y+icon_size)
                    x = icon_size + 20
                end

                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(x,y, x + 150, y + symbol_height)
                colored:deactivate()

                local symbol_width = CONFIG.font:width(dep.symbol, icon_size)
                if symbol_width < 150 then
                    symbol_margin_top = (symbol_height - icon_size) / 2
                    CONFIG.font:write(x + 75 - symbol_width/2, y+symbol_margin_top, dep.symbol, icon_size, dep.font_r, dep.font_g, dep.font_b,1)
                else
                    size = icon_size
                    while CONFIG.font:width(dep.symbol, size) > 145 do
                        size = size - 2
                    end
                    symbol_margin_top = (symbol_height - size) / 2
                    symbol_width = CONFIG.font:width(dep.symbol, size)
                    CONFIG.font:write(x + 75 - symbol_width/2, y+symbol_margin_top, dep.symbol, size, dep.font_r, dep.font_g, dep.font_b,1)
                end

                text_y = y + (margin_bottom * 0.5)
                CONFIG.font:write(x + 170, text_y, dep.direction, text_upper_size, stop_r,stop_g,stop_b, 1)
                if CONFIG.large_minutes then
                    local time_width = CONFIG.font:width(time, text_upper_size)
                    CONFIG.font:write(real_width - time_width, text_y, time, text_upper_size, stop_r,stop_g,stop_b, 1)
                    text_y = text_y + text_upper_size
                    CONFIG.font:write(x + 170, text_y, platform .. " " .. append , text_lower_size, 1,1,1,1)
                else
                    text_y = text_y + text_upper_size
                    CONFIG.font:write(x + 170, text_y, time .. " " .. platform .. " " .. append , text_lower_size, 1,1,1,1)
                end
            else
                this_line_height = line_height * 0.8
                icon_size = this_line_height * 0.66
                text_upper_size = this_line_height * 0.5
                text_lower_size = this_line_height * 0.3
                symbol_height = text_upper_size + text_lower_size + margin_bottom

                x = 0 --line_height * 0.34

                if CONFIG.showtype then
                    categories[tonumber(dep.category)]:draw(0, y, icon_size, y+icon_size)
                    x = x + icon_size + 20
                end

                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(x, y, x + 100,y + symbol_height)
                colored:deactivate()
                local symbol_width = CONFIG.font:width(dep.symbol, icon_size)
                if symbol_width < 100 then
                    symbol_margin_top = (symbol_height - icon_size) / 2
                    CONFIG.font:write(x + 50 - symbol_width/2, y + symbol_margin_top, dep.symbol, icon_size, dep.font_r, dep.font_g, dep.font_b,1)
                else
                    size = icon_size
                    while CONFIG.font:width(dep.symbol, size) > 95 do
                        size = size - 2
                    end
                    symbol_margin_top = (symbol_height - size) / 2
                    symbol_width = CONFIG.font:width(dep.symbol, size)
                    CONFIG.font:write(x + 50 - symbol_width/2, y+symbol_margin_top, dep.symbol, size, dep.font_r, dep.font_g, dep.font_b,1)
                end

                CONFIG.font:write(x + 120, y + ((symbol_height - icon_size) / 2), time , icon_size, 1,1,1,1)

                time_width = icon_size * 3.5

                text_y = y + (margin_bottom * 0.5)
                CONFIG.font:write(x + 120 + time_width, text_y, dep.direction, text_upper_size, stop_r,stop_g,stop_b,1)
                text_y = text_y + text_upper_size
                CONFIG.font:write(x + 120 + time_width, text_y, append, text_lower_size, 1,1,1,1)
            end

            y = y + symbol_height + margin_bottom

            if y > real_height then
                break
            end
        end
    end

    --colored:use{color = {0, 0, 0, 1}}
    --white:draw(0, 0, NATIVE_WIDTH, 120)

    --time_string = os.date("%Y-%m-%d %H:%M:%S", now)
    --time_width = CONFIG.font:width(time_string, 100)
    --time_x = (NATIVE_WIDTH/2)-(time_width/2)
    --CONFIG.font:write(time_x, 10, time_string, 100, 1,1,1,1)
end
