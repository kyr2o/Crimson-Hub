-- This code is already in the full script from the last message.
-- You can find it inside the ui:LoadScripts function.

elseif modName == "Auto Knife Throw" then
    -- Create a vertical container for this feature's buttons, similar to Auto Shoot
    grid.CellSize = UDim2.new(0, 220, 0, 138) -- Increase cell height to fit both buttons

    local autoContainer = Instance.new("Frame", content)
    autoContainer.Size = UDim2.new(0, 220, 0, 0)
    autoContainer.AutomaticSize = Enum.AutomaticSize.Y
    autoContainer.BackgroundTransparency = 1
    local vList = Instance.new("UIListLayout", autoContainer)
    vList.Padding = UDim.new(0, 8)
    vList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Main Auto Knife Throw Toggle Button
    createScriptButton(autoContainer, "Auto Knife Throw", function(state)
        local G = (getgenv and getgenv()) or _G
        G.CRIMSON_AUTO_KNIFE = G.CRIMSON_AUTO_KNIFE or { enabled = false, silentKnifeEnabled = false }
        
        if state then
            G.CRIMSON_AUTO_KNIFE.enabled = true
            if G.CRIMSON_AUTO_KNIFE.enable then G.CRIMSON_AUTO_KNIFE.enable() end
            fn(true) -- This executes the script content
        else
            G.CRIMSON_AUTO_KNIFE.enabled = false
            if G.CRIMSON_AUTO_KNIFE.disable then G.CRIMSON_AUTO_KNIFE.disable() end
        end
    end).Size = UDim2.new(1, 0, 0, 60)

    -- New Silent Knife Toggle Button
    createScriptButton(autoContainer, "Silent Knife", function(state)
        local G = (getgenv and getgenv()) or _G
        if not G.CRIMSON_AUTO_KNIFE then 
            if G.CRIMSON_NOTIFY then G.CRIMSON_NOTIFY("Error", "Enable Auto Knife Throw first.", 2, "error") end
            return 
        end
        
        if state then
            if G.CRIMSON_AUTO_KNIFE.enableSilentKnife then pcall(G.CRIMSON_AUTO_KNIFE.enableSilentKnife) end
        else
            if G.CRIMSON_AUTO_KNIFE.disableSilentKnife then pcall(G.CRIMSON_AUTO_KNIFE.disableSilentKnife) end
        end
    end).Size = UDim2.new(1, 0, 0, 60)
