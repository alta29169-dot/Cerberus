--[[
    BOOTLOADER
    Loads the GUI picker, which then loads individual suites
    DON'T TOUCH THIS
]]

local GITHUB_USER = "alta29169-dot"
local GITHUB_REPO = "Refugium"
local GITHUB_BRANCH = "main"

local function fetchAndRun(path)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/refs/heads/%s/%s",
        GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, path
    )
    print("[Boot] Fetching:", path)
    
    local result = request({ Url = url, Method = "GET" })
    if result.StatusCode == 200 then
        local fn, err = loadstring(result.Body, path)
        if fn then
            fn()
        else
            warn("[Boot] Compile error:", err)
        end
    else
        warn("[Boot] Failed to fetch:", path, "Status:", result.StatusCode)
    end
end

-- Load the GUI picker
fetchAndRun("guipicker.lua")
