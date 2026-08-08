return function(S, C, U, Teleport, Stockpile, KillAura)
    local Loopkill = {}

    -- Process all loopkill targets
    function Loopkill.run(initializedFn)
        while true do
            if initializedFn() then
                local targets = KillAura.getLoopkillTargets()
                
                -- Remove players who left
                for name, _ in pairs(targets) do
                    local found = false
                    for _, pl in ipairs(S.Players:GetPlayers()) do
                        if pl.Name == name and pl.Team ~= S.LocalPlayer.Team then
                            found = true
                            break
                        end
                    end
                    if not found then
                        targets[name] = nil
                        print("❌ Loopkill target left:", name)
                    end
                end
                
                -- Process each target
                for name, _ in pairs(targets) do
                    for _, pl in ipairs(S.Players:GetPlayers()) do
                        if pl.Name == name and pl.Team ~= S.LocalPlayer.Team then
                            if U.isEnemyAlive(pl) then
                                if U.hasForceField(pl) then
                                    U.equipTool("M1 Garand")
                                    task.wait(0.1)
                                    Teleport.toEnemy(pl)
                                    task.wait(0.2)
                                    KillAura.fireBurst(pl)
                                else
                                    Stockpile.teleportEnemy(pl)
                                end
                            end
                            break
                        end
                    end
                end
            end
            task.wait(C.TELEPORT_INTERVAL)
        end
    end

    return Loopkill
end
