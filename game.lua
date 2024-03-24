--- The `Game` class is responsible for managing the game's lifecycle, including initialization,
--- starting the game, managing saves, handling user input, and rendering. It extends the `Object` class,
--- leveraging its capabilities for object-oriented features. This class acts as the central hub for game
--- management tasks, including profile loading, rendering settings, and managing various game states like
--- the main menu, splash screen, and the main game loop.
Game = Object:extend()

function Game:Initialize()
    G = self

    self:SetGlobals()
end

function Game:Start()
    ---@todo Load the settings file .jkr
    ---@todo Create all sounds from resources and play one each to load into mem
    ---@todo Call the save manager to wait for any save requests
    ---@todo Call the http manager
    ---@todo Load all shaders from resources
    ---@todo Input handler/controller for game objects

    self:LoadProfile()
    self:SetRenderSettings()
    self:SetLocal()

    ---@todo Create sprite class
    ---@todo Create the event manager for the game
end

---@todo Implement Profiles
function Game:LoadProfile(_profile)

end

---@todo Implement Localization
function Game:SetLocal()

end

---@todo Implement Render Settings
function Game:SetRenderSettings()
    -- Set fiter to linear interpolation and nearest, best for pixel art
    love.graphics.setDefaultFilter() ---@todo
    -- Set Line style to rough for pixel art
    love.graphics.setLineStyle("rough")
    ---@todo Load spritesheets
end

---@todo Implement Window Setup
function Game:InitializeWindow(reset)

end

---@todo Implement Save Manager
function Game:SaveProgress()
end

function Game:SaveNotify(card)
end

function Game:SaveSettings()
end

function Game:SaveMetrics()
end

---@todo Implement Sandbox Mode to test game mechanics
function Game:Sandbox()

end

---@todo Implement Startup Splash Screen
function Game:SplashScreen()

end

---@todo Implement Main Menu
function Game:MainMenu(change_context) --True if main menu is accessed from the splash screen, false if it is skipped or accessed from the game

end

---@todo Implement Start Game
function Game:StartRun(args)

end

---@todo Implement Game Logic Loop
function Game:Update(dt)

end

---@todo Implement Game Draw Loop
function Game:Draw()

end
