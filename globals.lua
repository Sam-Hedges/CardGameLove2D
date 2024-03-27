-- Release State, Update, Hotfix
local VERSION = '0.0.0' .. (_DEMO_MODE and '-DEMO' or '-FULL')

function Game:set_globals()
    self.VERSION = VERSION

    -------------------------------
    --         Debug Flags
    -------------------------------

    self.DEBUG_COLLIDERS = true


    -------------------------------
    --         Feature Flags
    -------------------------------


    -------------------------------
    --             Time
    -------------------------------

    self.SEED = os.time()
    self.TIMERS = {
        TOTAL = 0,
        REAL = 0,
        UPTIME = 0,
        BACKGROUND = 0
    }
    self.FRAMES = {
        DRAW = 0,
        MOVE = 0
    }
    self.exp_times = { xy = 0, scale = 0, r = 0 }


    -------------------------------
    --           SETTINGS
    -------------------------------

    self.SETTINGS = {
        ACHIEVEMENTS_EARNED = {},
        crashreports = false,
        language = 'en-us',
        GAMESPEED = 1,
        paused = false,
        SOUND = {
            volume = 50,
            music_volume = 100,
            game_sounds_volume = 100,
        },
        WINDOW = {
            screenmode = 'Borderless',
            vsync = 1,
            selected_display = 1,
            display_names = { '[NONE]' },
            DISPLAYS = {
                {
                    name = '[NONE]',
                    screen_res = { w = 1000, h = 650 },
                }
            },
        },
    }


    -------------------------------
    --        RENDER SCALE
    -------------------------------


    -------------------------------
    --        GAMESTATES
    -------------------------------

    self.STATES = {}
    self.STAGES = {
        MAIN_MENU = 1,
        RUN = 2,
        SANDBOX = 3
    }

    -------------------------------
    --          INSTANCES
    -------------------------------
    self.CONTROLLER = nil
    self.INSTANCES = {
        GAMEOBJECT = {},
        MOVEABLE = {},
        SPRITE = {},
        UIBOX = {},
        POPUP = {},
        CARD = {},
    }


    -------------------------------
    --        CONSTANTS
    -------------------------------


    -------------------------------
    --        COLOURS
    -------------------------------

    self.COLOURS = {
        MULT = HexToRGBA('FE5F55'),
        CHIPS = HexToRGBA("009dff"),
        MONEY = HexToRGBA('f3b958'),
        XMULT = HexToRGBA('FE5F55'),
        FILTER = HexToRGBA('ff9a00'),
        BLUE = HexToRGBA("009dff"),
        RED = HexToRGBA('FE5F55'),
        GREEN = HexToRGBA("4BC292"),
        PALE_GREEN = HexToRGBA("56a887"),
        ORANGE = HexToRGBA("fda200"),
        GOLD = HexToRGBA('eac058'),
        YELLOW = { 1, 1, 0, 1 },
        CLEAR = { 0, 0, 0, 0 },
        WHITE = { 1, 1, 1, 1 },
        PURPLE = HexToRGBA('8867a5'),
        BLACK = HexToRGBA("374244"), --4f6367"),
        L_BLACK = HexToRGBA("4f6367"),
        GREY = HexToRGBA("5f7377"),
        UI = {
            TEXT_LIGHT = { 1, 1, 1, 1 },
            TEXT_DARK = HexToRGBA("4F6367"),
            TEXT_INACTIVE = HexToRGBA("88888899"),
            BACKGROUND_LIGHT = HexToRGBA("B8D8D8"),
            BACKGROUND_WHITE = { 1, 1, 1, 1 },
            BACKGROUND_DARK = HexToRGBA("7A9E9F"),
            BACKGROUND_INACTIVE = HexToRGBA("666666FF"),
            OUTLINE_LIGHT = HexToRGBA("D8D8D8"),
            OUTLINE_LIGHT_TRANS = HexToRGBA("D8D8D866"),
            OUTLINE_DARK = HexToRGBA("7A9E9F"),
            TRANSPARENT_LIGHT = HexToRGBA("eeeeee22"),
            TRANSPARENT_DARK = HexToRGBA("22222222"),
            HOVER = HexToRGBA('00000055'),
        },
    }

    -------------------------------
    --        ENUMS
    -------------------------------
    self.button_mapping = {
        a = G.F_SWAP_AB_BUTTONS and 'b' or nil,
        b = G.F_SWAP_AB_BUTTONS and 'a' or nil,
        y = G.F_SWAP_XY_BUTTONS and 'x' or nil,
        x = G.F_SWAP_XY_BUTTONS and 'y' or nil,
    }
    self.keybind_mapping = { {
        a = 'dpleft',
        d = 'dpright',
        w = 'dpup',
        s = 'dpdown',
        x = 'x',
        c = 'y',
        space = 'a',
        shift = 'b',
        esc = 'start',
        q = 'triggerleft',
        e = 'triggerright',
    } }
end

G = Game()
