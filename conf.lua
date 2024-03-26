_RELEASE_MODE = false
_DEMO_MODE = false
_DEBUG_MODE = false

function love.conf(t)
    -- os.execute("set LOVE_GRAPHICS_USE_OPENGLES=1")

    t.console = not _DEBUG_MODE and not _RELEASE_MODE
    t.title = 'Card Game'
    t.version = '11.5'
    t.window.width = 0
    t.window.height = 0
    t.window.minwidth = 100
    t.window.minheight = 100
end
