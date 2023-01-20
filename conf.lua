function love.conf(t)
    t.version = "11.3"                  -- The LÖVE version this game was made for (string)
    t.gammacorrect = true               -- Enable gamma-correct rendering, when supported by the system (boolean)

    t.audio.mixwithsystem = true        -- Keep background music playing when opening LOVE (boolean, iOS and Android only)

    t.window.title = "LoveSweeper"      -- The window title (string)
    t.window.icon = "assets/icon.png"   -- Filepath to an image to use as the window's icon (string)
    t.window.width = 420                -- The window width (number)
    t.window.height = 420               -- The window height (number)
    t.window.resizable = true           -- Let the window be user-resizable (boolean)
    t.window.minwidth = 420             -- Minimum window width if the window is resizable (number)
    t.window.minheight = 420            -- Minimum window height if the window is resizable (number)
    t.window.vsync = 1                  -- Vertical sync mode (number)
    t.window.highdpi = true             -- Enable high-dpi mode for the window on a Retina display (boolean)
    t.window.usedpiscale = true         -- Enable automatic DPI scaling when highdpi is set to true as well (boolean)

    t.modules.physics = false           -- Enable the physics module (boolean)
end
