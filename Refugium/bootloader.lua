--[[
    REFUGIUM SUITE BOOTLOADER
    Fetches all modules from Refugium/ folder, stores in _G._HarborModules, then runs main
]]

local GITHUB_USER = "alta29169-dot"
local GITHUB_REPO = "Cerberus"
local GITHUB_BRANCH = "main"
local MODULES_PATH = "Refugium"

local MODULE_NAMES = {
    "config",
    "services",
    "utils",
    "teleport",
    "stockpile",
    "killaura",
    "loopkill",
    "rpgblock",
    "guicore",
    "guitoggles",
    "guitargets",
    "main"
}

local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/refs/heads/%s/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, MODULES_PATH
)

_G._HarborModules = _G._HarborModules or {}

local function fetchModule(name, retries)
    retries = retries or 3
    local url = RAW_BASE .. name .. ".lua"
    print("[Boot] Fetching:", name)

    for attempt = 1, retries do
        local ok, result = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)

        if ok and result and result.StatusCode == 200 then
            local fn, err = loadstring(result.Body, name)
            if not fn then
                error("[Boot] Compile error in " .. name .. ": " .. tostring(err))
            end

            local mod = fn()
            _G._HarborModules[name] = mod
            print("[Boot] Loaded:", name)
            return
        else
            if attempt < retries then
                warn("[Boot] Attempt " .. attempt .. " failed for " .. name .. ", retrying...")
                task.wait(1)
            else
                error("[Boot] Failed to load " .. name .. " after " .. retries .. " attempts.")
            end
        end
    end
end

-- Fetch all modules except main.lua
for _, name in ipairs(MODULE_NAMES) do
    if name ~= "main" then
        local success, err = pcall(fetchModule, name, 3)
        if not success then
            warn("[Boot] FATAL: " .. tostring(err))
            return
        end
    end
end

-- Now run main.lua
print("[Boot] Starting Refugium...")
fetchModule("main", 3)
