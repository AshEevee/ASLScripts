state("Flyn") {}

startup {
    refreshRate = 0.5;

    settings.Add("world1", true, "1 - Tricoton");
    settings.Add("world2", true, "2 - Tripatio");
    settings.Add("world3", true, "3 - Trilab");
    settings.Add("world4", true, "4 - Elektri");
    settings.Add("world5", true, "5 - Megaben");

    // Normal Levels
    for(int world = 1; world <= 5; world++) {
        settings.Add("levels"+world, true, "Levels", "world"+world);
        settings.CurrentDefaultParent = "levels"+world;
        var worldLvl = (world-1)*10;
        settings.Add("l"+(worldLvl+1), true, world+"-1");
        settings.Add("l"+(worldLvl+2), true, world+"-2");
        settings.Add("l"+(worldLvl+3), true, world+"-3");
        settings.Add("l"+(worldLvl+4), true, world+"-4");
        settings.Add("l"+(worldLvl+5), true, world+"-5");
        settings.Add("l"+(worldLvl+6), true, world+"-6");
        settings.Add("l"+(worldLvl+7), true, world+"-7");
        settings.Add("l"+(worldLvl+8), true, world+"-Boss");
        settings.Add("l"+(worldLvl+9), true, world+((world != 5)?"-Inside Boss":"-End"));
    }

    // Secret Levels
    settings.Add("secrets1", false, "Secrets", "world1");
    settings.CurrentDefaultParent = "secrets1";
    settings.Add("l50", true, "Graby");
    settings.Add("l51", true, "Astep_Ping");
    settings.Add("l52", true, "Salvay");

    settings.Add("secrets2", false, "Secrets", "world2");
    settings.CurrentDefaultParent = "secrets2";
    settings.Add("l53", true, "Ylona");
    settings.Add("l54", true, "AstralZ");
    settings.Add("l55", true, "Medy");

    settings.Add("secrets3", false, "Secrets", "world3");
    settings.CurrentDefaultParent = "secrets3";
    settings.Add("l56", true, "Safaway");
    settings.Add("l57", true, "Popaf");
    settings.Add("l58", true, "Ollon");

    settings.Add("secrets4", false, "Secrets", "world4");
    settings.CurrentDefaultParent = "secrets4";
    settings.Add("l59", true, "Korly");
    settings.Add("l60", true, "Plincty");
    settings.Add("l61", true, "Germion");

    settings.Add("secrets5", false, "Secrets", "world5");
    settings.CurrentDefaultParent = "secrets5";
    settings.Add("l62", true, "Buccoly");

    // 8D15????????E8????????8975E0A1
    vars.scanTargetGame = new SigScanTarget(2,
        "8D 15 ????????",   // lea edx,[XXXXXXXX]
        "E8 ????????",      // call ????????
        "89 75 E0",         // mov [ebp-20],esi
        "A1"                // mov eax,[????????]
    );
}

init {
    print("[Autosplitter] Scanning memory");

    IntPtr ptr = IntPtr.Zero;

    foreach (var page in game.MemoryPages()) {
        var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
        ptr = scanner.Scan(vars.scanTargetGame);
        if(ptr != IntPtr.Zero)
            break;
    }

    // Waiting for the game to have booted up
    if (ptr == IntPtr.Zero)
        throw new Exception("[Autosplitter] Can't find signature");

    vars.gameInstructionPtr = (int)ptr - (int)game.Modules[0].BaseAddress;
    
    vars.watchers = new MemoryWatcherList();
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(vars.gameInstructionPtr, 0x0, 0xEC)) {Name = "levelId"});
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(vars.gameInstructionPtr, 0x0, 0xC8, 0x1C)) {Name = "gameState"});

    refreshRate = 60;
}

update {
    vars.watchers.UpdateAll(game);
}

start {
    return vars.watchers["levelId"].Current == 1 || vars.watchers["levelId"].Current == 50;
}

split {
    // End Normal Levels
    if(vars.watchers["levelId"].Current == 49 && vars.watchers["gameState"].Current == 5) return settings["l49"];

    if(!vars.watchers["levelId"].Changed) return false;

    return settings.ContainsKey("l"+vars.watchers["levelId"].Old) && settings["l"+vars.watchers["levelId"].Old];
}

reset {
    return vars.watchers["levelId"].Current == 70;
}

isLoading {
    return vars.watchers["gameState"].Current == 2;
}