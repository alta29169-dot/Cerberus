--[[
    HARBOR DEFENDER – Bootloader
    Fetches all modules from GitHub, stores in _G._Modules, then runs main
]]

local GITHUB_USER = "alta29169-dot"
local GITHUB_REPO = "Refugium"
local GITHUB_BRANCH = "main"
local MODULES_PATH = "harbor-defender"

local MODULE_NAMES = {
    "config",
    "services",
    "utils",
    "teleport",
    "stockpile",
    "killaura",
    "loopkill",
    "rpgblock",
    "gui",
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
            if type(mod) ~= "table" and name ~= "main" then
                -- main.lua doesn't return a table, it runs directly
            end

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

-- Now run main.lua (it uses _G._HarborModules)
print("[Boot] Starting Harbor Defender...")
local ok, result = pcall(fetchModule, "main", 3)
if not ok then
    warn("[Boot] Failed to start: " .. tostring(result))
end
