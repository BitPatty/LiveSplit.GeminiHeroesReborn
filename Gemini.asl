// Gemini.asl Version 1.2
//
// A load remover and autosplitter for Gemini: Heroes Reborn
// See https://www.speedrun.com/ghr
//
// To Dos:
//   - Splits if Cass dies and checkpoint is not manually reloaded;
//   - Skips split if manual checkpoint reset is selected but canceled out of
//   - Splits rarely on manual checkpoint reset for unknown reasons (maybe value flickering).
//
// Authors:
//   - Cadarev: Twitter: @CadarevElry, Twitch: twitch.tv/cadarev, Discord: cadarev
//   - Psychonauter: Twitch: twitch.tv/psychonauter, Discord: psychonauter
//
// Original author's note:
//   Special thanks to Toxic_TT (twitch.tv/toxic_tt) for mentoring and helping me out with everything.
//
// Changelog:
//   - v1.1 - Minor code cleanup
//   - v1.2 - Add double split prevention

state("TravelerGame-Win64-Shipping")
{
    // 3 while in a loading screen, 4 during normal gameplay, can flicker to 5 during gameplay and before starting a loading screen
    int scene_state: 0x022ACE70, 0x10, 0x0;

    // Counter keeping track of the amount of load prompts (from manual checkpoint resets, quit outs to main menu, and loads from main menu)
    int load_prompts: 0x0231E740, 0x3F8, 0x10, 0x58, 0x20, 0x528;

    // has a constant value within each level, then flickers as soon as going into a loading screen
    int active_level: 0x022AA380, 0x3A0, 0x88;

    // In level 1: 8 during intro until control, 10 after gaining control, sometimes flickers to 11, different values for later parts and loading screens
    int start: 0x022BE9F0, 0x0, 0x8;
}

init
{
    // Variable to track amount load prompts after last load screen
    vars.prompts_after_load = 0;
    // Variable containing a decrementing counter to prevent double splits
    vars.autosplit_cooldown = 0;
}

split
{
    // Save the amount of load prompts whenever exiting a loading screen to determine if the next load is a level transition or not
    if(current.scene_state == 4 && old.scene_state == 3)
    {
        vars.prompts_after_load = current.load_prompts;
    }

    // If still in autosplit cooldown, don't try to autosplit
    if(vars.autosplit_cooldown > 0) {
        vars.autosplit_cooldown -= 1;
        return false;
    }

    // Splits if loading screen starts and no additional manual loads have been triggered
    // Prevents splits from manual checkpoint resets and level loads from main menu
    // (splits on death reload though, and will skip split if manual reset was pressed but canceled out of)
    if(current.scene_state == 3 && old.scene_state != 3 && current.load_prompts == vars.prompts_after_load) {
        vars.autosplit_cooldown = 30;
        return true;
    }
}

start
{
    // Checks if in first level (462) and gaining first control
    if(current.active_level == 462 && current.start == 10 && old.start == 8)
    {
        return true;
    }
}

isLoading
{
    // Pause timer when in a loading screen
    return current.scene_state == 3;
}