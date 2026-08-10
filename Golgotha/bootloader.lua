local GITHUB_USER = "alta29169-dot"
local GITHUB_REPO = "Cerberus"
local GITHUB_BRANCH = "main"
local MODULES_PATH = "Golgotha"

local MODULE_NAMES = {
    "config", "services", "utils", "core",
    "guicore", "guitoggles", "main"
}

local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/refs/heads/%s/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, MODULES_PATH
)

_G._GolgothaModules = _G._GolgothaModules or {}

local function fetchModule(name, retries)
    retries = retries or 3
    local url = RAW_BASE .. name .. ".lua"
    for attempt = 1, retries do
        local ok, result = pcall(function() return request({ Url = url, Method = "GET" }) end)
        if ok and result and result.StatusCode == 200 then
            local fn, err = loadstring(result.Body, name)
            if fn then _G._GolgothaModules[name] = fn(); print("[Golgotha] Loaded:", name); return end
        else
            if attempt < retries then task.wait(1) end
        end
    end
end

for _, name in ipairs(MODULE_NAMES) do
    if name ~= "main" then fetchModule(name) end
end
fetchModule("main")
