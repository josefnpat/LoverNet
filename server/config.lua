function love.conf(t)
    t.identity = nil                    -- The name of the save directory (string)
    t.version = "0.10.1"                -- The LÖVE version this game was made for (string)
    t.console = false                   -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = false      -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    t.externalstorage = false           -- True to save files (and read from the save directory) in external storage on Android (boolean) 
    t.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)

    t.window = false

    t.modules.audio = false              -- Enable the audio module (boolean)
    t.modules.event = false              -- Enable the event module (boolean)
    t.modules.graphics = false           -- Enable the graphics module (boolean)
    t.modules.image = false              -- Enable the image module (boolean)
    t.modules.joystick = false           -- Enable the joystick module (boolean)
    t.modules.keyboard = false           -- Enable the keyboard module (boolean)
    t.modules.math = false               -- Enable the math module (boolean)
    t.modules.mouse = false              -- Enable the mouse module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)
    t.modules.sound = false              -- Enable the sound module (boolean)
    t.modules.system = false             -- Enable the system module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = false              -- Enable the touch module (boolean)
    t.modules.video = false              -- Enable the video module (boolean)
    t.modules.window = false             -- Enable the window module (boolean)
    t.modules.thread = false             -- Enable the thread module (boolean)
end

