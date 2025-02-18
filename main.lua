require "engine/init"
require "game"
require "globals"

if _DEBUG_MODE then
    require("lldebugger").start()
end

math.randomseed(G.SEED)

function love.run()
    if love.load then love.load(arg) end

    if love.timer then love.timer.step() end

    local dt = 0
    local dt_smooth = 1 / 100
    local run_time = 0

    -- Main loop time.
    return function()
        run_time = love.timer.getTime()

        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end
        dt_smooth = math.min(0.8 * dt_smooth + 0.2 * dt, 0.1)
        -- Call update and draw
        if love.update then love.update(dt_smooth) end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        run_time = math.min(love.timer.getTime() - run_time, 0.1)
        G.FPS_CAP = G.FPS_CAP or 500
        if run_time < 1. / G.FPS_CAP then love.timer.sleep(1. / G.FPS_CAP - run_time) end
    end
end

function love.load()
    -- init something here ...
    love.window.setTitle("Card Game")

    Font = love.graphics.newFont("resources/fonts/m6x11plus.ttf", 50)
    love.graphics.setFont(Font)

    love.keyboard.keysPressed = {}

    G:start()
end

function love.update(dt)
    -- change some values based on your actions

    love.keyboard.keysPressed = {}

    G:update(dt)
    -- local joysticks = love.joystick.getJoysticks()
    -- if joysticks then
    --     if joysticks[1] then
    --     end
    -- end
end

function love.draw()
    -- draw your stuff here

    local backgroundColour = G.COLOURS.GREY
    love.graphics.setBackgroundColor(backgroundColour)

    local width, height = love.graphics.getDimensions()
    local fpsText = "FPS: " .. tostring(love.timer.getFPS())

    love.graphics.print(G.VERSION, width - Font:getWidth(G.VERSION) - 10, 0)
    love.graphics.print(fpsText, width - Font:getWidth(fpsText) - 10, 50)


    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(10)

    G:draw()
end

function love.errhand(msg)

end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)

end

function love.gamepadpressed(joystick, button)

end

function love.gamepadreleased(joystick, button)

end

function love.mousepressed(x, y, button, touch)

end

function love.mousereleased(x, y, button)

end

function love.mousemoved(x, y, dx, dy, istouch)

end

function love.joystickaxis(joystick, axis, value)

end
