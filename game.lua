--- The `Game` class is responsible for managing the game's lifecycle, including initialization, starting the game, managing saves, handling user input, and rendering.
Game = Object:extend()

function Game:new()
    G = self

    self:set_globals()
end

function Game:start()
    ---@todo Load the settings file .jkr
    ---@todo Create all sounds from resources and play one each to load into mem
    ---@todo Call the save manager to wait for any save requests
    ---@todo Call the http manager
    ---@todo Load all shaders from resources
    ---@todo Input handler/controller for game objects
    self.CONTROLLER = Controller()

    -- self:LoadProfile()
    -- self:SetRenderSettings()
    -- self:SetLocal()

    ---@todo Create sprite class
    ---@todo Create the event manager for the game

    Game.DEBUG = true
    local args = {
        transform = Transform(0, 0, 100, 100, 0),
    }

    local body = Gameobject(args)

    print(tostring(body.transform.position))
    print(tostring(body.transform.scale))
end

---@todo Implement Game Logic Loop
function Game:update(dt)
    for k, value in pairs(self.INSTANCES.GAMEOBJECT) do
        value:update(dt)
    end
end

---@todo Implement Game Draw Loop
function Game:draw()
    for k, value in pairs(self.INSTANCES.GAMEOBJECT) do
        love.graphics.push()
        value:draw()
        love.graphics.pop()
    end
end

---@todo Implement Profiles
function Game:load_profile(_profile)

end

---@todo Implement Localization
function Game:set_local()

end

---@todo Implement Render Settings
function Game:set_render_settings()
    -- Set fiter to linear interpolation and nearest, best for pixel art
    love.graphics.setDefaultFilter() ---@todo
    -- Set Line style to rough for pixel art
    love.graphics.setLineStyle("rough")
    ---@todo Load spritesheets
end

---@todo Implement Window Setup
function Game:initialize_window(reset)

end

---@todo Implement Save Manager
function Game:save_progress()
end

function Game:save_notify(card)
end

function Game:save_settings()
end

function Game:save_metrics()
end

---@todo Implement Sandbox Mode to test game mechanics
function Game:sandbox()

end

---@todo Implement Startup Splash Screen
function Game:splash_screen()

end

---@todo Implement Main Menu
function Game:main_menu(change_context) --True if main menu is accessed from the splash screen, false if it is skipped or accessed from the game

end

---@todo Implement Start Game
function Game:start_run(args)

end
