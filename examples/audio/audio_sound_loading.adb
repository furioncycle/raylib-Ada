--
--   raylib [audio] example - Sound loading and playing
--
--   Example originally created with raylib 1.1, last time updated with raylib 3.5
--
--   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
--   BSD-like license that allows static linking with closed source software
--
--   Copyright (c) 2014-2023 Ramon Santamaria (@raysan5)
--


with raylib;
with Interfaces.C.Strings;

procedure audio_sound_loading is
    package IC renames Interfaces.C;
    use raylib;

    screenWidth  : constant := 800;
    screenHeight : constant := 450;

    fxWav, fxOgg : raylib.Sound;

begin

    raylib.window.init (screenWidth, screenHeight, "raylib [audio] example - sound loading and playing");
    
    raylib.audio.init_audio_device;
    
    fxWav := raylib.audio.load_sound (IC.Strings.new_string ("audio/resources/sound.wav"));
    fxOgg := raylib.audio.load_sound (IC.Strings.new_string ("audio/resources/target.ogg"));

    raylib.set_target_FPS (60);

    while not raylib.window.should_close loop
        if raylib.core.is_key_pressed (KEY_SPACE) then raylib.audio.play_sound (fxWav); end if;
        if raylib.core.is_key_pressed (KEY_ENTER) then raylib.audio.play_sound (fxOgg); end if;

        begin_drawing;
        clear_background (raylib.RAYWHITE);

        raylib.text.draw ("Press SPACE to PLAY the WAV sound!", 200, 180, 20, LIGHTGRAY);
        raylib.text.draw ("Press ENTER to PLAY the OGG sound!", 200, 220, 20, LIGHTGRAY);

        end_drawing;
    end loop;

    raylib.audio.unload_sound (fxWav);
    raylib.audio.unload_sound (fxOgg);
    raylib.audio.close_audio_device;
    raylib.window.close;

end audio_sound_loading;
