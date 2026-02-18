--INIT
--PLATFORM

core.register_chatcommand("dump_globals", {
    params = "",
    description = "Dumps all global variable names to 'dumped_globals.txt' in the world folder",
    func = function(name, param)
        -- 1. Collect all keys from the global environment (_G)
        local out = "";
        for k, v in pairs(_G) do
            out = out .. tostring(k) .. ' : ';
            if type(v) == "string" or type(v) == "number" or type(v) == "function" then
                out = out .. tostring(v)
            else
                out = out .. type(v)
            end
            out = out .. '\n';
        end

        -- 4. Write to a file in the world path
        local filepath = core.get_worldpath() .. "/dumped_globals.txt"
        local file, err = io.open(filepath, "w")

        if not file then
            return false, "Failed to open file: " .. tostring(err)
        end

        file:write("-- List of Global Objects in _G\n\n")
        file:write(out)
        file:close()

        -- 5. Notify the player
        return true, "Successfully dumped global objects to:\n" .. filepath
    end
})

core.register_chatcommand("eval", {
    params = "<code>",
    description = "Executes Lua code and returns the result",
    func = function(name, param)
        -- 1. Check if code was provided
        if not param or param == "" then
            return false, "Usage: /eval <lua code>"
        end

        -- 2. Compile the code
        -- "=(eval)" is a pseudonym for error messages to look cleaner
        local func, err = loadstring(param, "=(eval)")

        if not func then
            return false, "Syntax Error: " .. tostring(err)
        end

        -- 3. Execute the code safely
        -- We use pcall to catch runtime errors without crashing the server
        local success, result = pcall(func)

        if not success then
            return false, "Runtime Error: " .. tostring(result)
        end

        -- 4. Format the output
        -- 'dump' is a built-in Minetest function that turns tables into strings
        local output_str
        if type(result) == "string" then
            output_str = result
        else
            output_str = dump(result)
        end

        -- Truncate if it's too long for chat (optional safety measure)
        if #output_str > 500 then
            output_str = output_str:sub(1, 500) .. "... (truncated)"
        end

        return true, "Result: " .. output_str
    end
})
