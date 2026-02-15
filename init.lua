core.register_chatcommand("dump_globals", {
    params = "",
    description = "Dumps all global variable names to 'dumped_globals.txt' in the world folder",
    func = function(name, param)
        -- 1. Collect all keys from the global environment (_G)
        local keys = {}
        for k, _ in pairs(_G) do
            table.insert(keys, tostring(k))
        end

        -- 2. Sort them alphabetically to make them easy to find
        table.sort(keys)

        -- 3. Format the output (one per line)
        local output = {}
        for _, k in ipairs(keys) do
            table.insert(output, k)
        end

        local file_content = table.concat(output, "\n")

        -- 4. Write to a file in the world path
        local filepath = core.get_worldpath() .. "/dumped_globals.txt"
        local file, err = io.open(filepath, "w")

        if not file then
            return false, "Failed to open file: " .. tostring(err)
        end

        file:write("-- List of Global Objects in _G\n")
        file:write("-- Total Count: " .. #keys .. "\n\n")
        file:write(file_content)
        file:close()

        -- 5. Notify the player
        return true, "Successfully dumped " .. #keys .. " global objects to:\n" .. filepath
    end
})
