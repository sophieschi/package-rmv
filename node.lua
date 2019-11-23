gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

util.init_hosted()

local json = require "json"

local departures = {}

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

function node.render()
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
            
            if dep.platform ~= "" then
                platform = " von " .. dep.platform
            end
            stop_r, stop_g, stop_b = 1,1,1

            if remaining < 10 then
                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(0,y, 150,y + 100)
                colored:deactivate()
                local symbol_width = CONFIG.font:width(dep.symbol, 70)
                CONFIG.font:write(75 - symbol_width/2, y+16, dep.symbol, 70, 1,1,1,1)

                CONFIG.font:write(170, y, dep.direction, 60, stop_r,stop_g,stop_b, 1)
                y = y + 60
                CONFIG.font:write(170, y, time .. platform .. " " .. append , 45, 1,1,1,1)
                y = y + 70
            else
                colored:use{color = {dep.color_r, dep.color_g, dep.color_b, 1}}
                white:draw(50,y, 150,y + 50)
                colored:deactivate()
                local symbol_width = CONFIG.font:width(dep.symbol, 40)
                CONFIG.font:write(100 - symbol_width/2, y + 5, dep.symbol, 40, 1,1,1,1)
                CONFIG.font:write(170, y, time , 45, 1,1,1,1)
                CONFIG.font:write(310, y, dep.direction, 30, stop_r,stop_g,stop_b,1)
                y = y + 30
                CONFIG.font:write(310, y, append , 25, 1,1,1,1)
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
