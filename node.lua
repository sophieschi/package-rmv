util.init_hosted()

local json = require "json"
local departures = {}

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
local transform = util.screen_transform(CONFIG.rotate)

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
    transform()
    CONFIG.background_color.clear()
    local now = unixnow()
    local y = 0

    for idx, dep in ipairs(departures) do
        if dep.date > now  - fadeout then
            if now > dep.date then
                y = y - 130 / fadeout * (now - dep.date)
            end
        end
    end
    for idx, dep in ipairs(departures) do
        if dep.date > now  - fadeout then
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
            elseif remaining < 10 then
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
                platform = " von " .. dep.stop
                if dep.platform ~= "" then
                    platform = platform .. ", Hst " .. dep.platform
                end
            else
                if dep.platform ~= "" then
                    platform = " von " .. dep.platform
                end
            end
            stop_r, stop_g, stop_b = 1,1,1

            if remaining < 10 then
                if CONFIG.showtype then
                    categories[tonumber(dep.category)]:draw(25, y, 125, y+100)
                    x = 150
                end

                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(x,y, x + 150,y + 100)
                colored:deactivate()
                local symbol_width = CONFIG.font:width(dep.symbol, 70)
                if symbol_width < 150 then
                    CONFIG.font:write(x + 75 - symbol_width/2, y+16, dep.symbol, 70, dep.font_r, dep.font_g, dep.font_b,1)
                else
                    size = 70
                    while CONFIG.font:width(dep.symbol, size) > 145 do
                        size = size - 2
                    end
                    symbol_width = CONFIG.font:width(dep.symbol, size)
                    CONFIG.font:write(x + 75 - symbol_width/2, y+50-size/2, dep.symbol, size, dep.font_r, dep.font_g, dep.font_b,1)
                end

                CONFIG.font:write(x + 180, y, dep.direction, 60, stop_r,stop_g,stop_b, 1)
                y = y + 60
                CONFIG.font:write(x + 180, y, time .. platform .. " " .. append , 45, 1,1,1,1)
                y = y + 70
            else
                if CONFIG.showtype then
                    categories[tonumber(dep.category)]:draw(120, y, 170, y+50)
                    x = 200
                end

                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(x,y, x + 100,y + 50)
                colored:deactivate()
                local symbol_width = CONFIG.font:width(dep.symbol, 40)
                if symbol_width < 100 then
                    CONFIG.font:write(x + 50 - symbol_width/2, y + 5, dep.symbol, 40, dep.font_r, dep.font_g, dep.font_b,1)
                else
                    size = 40
                    while CONFIG.font:width(dep.symbol, size) > 95 do
                        size = size - 2
                    end
                    symbol_width = CONFIG.font:width(dep.symbol, size)
                    CONFIG.font:write(x + 50 - symbol_width/2, y+25-size/2, dep.symbol, size, dep.font_r, dep.font_g, dep.font_b,1)
                end
                CONFIG.font:write(x + 120, y, time , 45, 1,1,1,1)
                CONFIG.font:write(x + 260, y, dep.direction, 30, stop_r,stop_g,stop_b,1)
                y = y + 30
                CONFIG.font:write(x + 260, y, append , 25, 1,1,1,1)
                y = y + 40
            end

            if y > HEIGHT - 50 then
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
