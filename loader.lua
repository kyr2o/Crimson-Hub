local githubUsername = "kyr2o"
local repoName = "Crimson-Hub"
local branchName = "main"

local murderMystery2 = 142823291

local gameScripts = {
    [murderMystery2] = "MM2.lua"
}

local currentGameId = game.PlaceId
local scriptToRun = gameScripts[currentGameId]

if scriptToRun then
    local scriptUrl = "https://raw.githubusercontent.com/"..githubUsername.."/"..repoName.."/"..branchName.."/"..scriptToRun
    loadstring(game:HttpGet(scriptUrl))()
end
