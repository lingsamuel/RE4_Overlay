

-- chainsaw.DynamicsSystem
-- chainsaw.DropItemManager
-- chainsaw.CharacterManager

-- chainsaw.EnemyAttackPermitManager
-- checkAttackPermit(chainsaw.CharacterContext, chainsaw.CharacterContext)  chainsaw.EnemyAttackPermitManager.AttackPermitResult

-- chainsaw.EnemyDropPartsManager

-- chainsaw.ExecutionPermitter


-- chainsaw.GameRankSystem
-- chainsaw.GameSituationManager
-- chainsaw.GameStatsManager

-- chainsaw.MaterialGroupManager
-- chainsaw.MaterialZoneManager

-- chainsaw.EnemyManager
-- chainsaw.PlayerManager
-- chainsaw.HitPoint
-- chainsaw.CharacterBackup

local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json


local GameRankSystem = sdk.get_managed_singleton("chainsaw.GameRankSystem")
local function GetGameRankSystem()
    if GameRankSystem == nil then GameRankSystem = sdk.get_managed_singleton("chainsaw.GameRankSystem") end
	return GameRankSystem
end

local EnemyAttackPermitManager = sdk.get_managed_singleton("chainsaw.EnemyAttackPermitManager")
local function GetEnemyAttackPermitManager()
    if EnemyAttackPermitManager == nil then EnemyAttackPermitManager = sdk.get_managed_singleton("chainsaw.EnemyAttackPermitManager") end
	return EnemyAttackPermitManager
end

local CharacterManager = sdk.get_managed_singleton("chainsaw.CharacterManager")
local function GetCharacterManager()
    if CharacterManager == nil then CharacterManager = sdk.get_managed_singleton("chainsaw.CharacterManager") end
	return CharacterManager
end

local EnemyManager = CharacterManager:call("get_EnemyManager")
local function GetEnemyManager()
    if EnemyManager == nil then EnemyManager = CharacterManager:call("get_EnemyManager") end
	return EnemyManager
end

local PlayerManager = CharacterManager:call("get_PlayerManager")
local function GetPlayerManager()
    if PlayerManager == nil then PlayerManager = CharacterManager:call("get_PlayerManager") end
	return PlayerManager
end

-- ==== Config ====

local LOAD_CONFIG_FILE = true

local Config = {}
Config.uiConfig = {}
Config.dingConfig = {}

local configPath = "RE4_Overlay/RE4_Overlay.json"

function Config.Init()
    local defaultUI = {}
    defaultUI.Font = nil
    defaultUI.Row = 0
    defaultUI.RowHeight = 25
    defaultUI.PosX = 1400
    defaultUI.PosY = 200

    local defaultDing = {}
    defaultDing.invincible = false

    Config.uiConfig = defaultUI
    Config.dingConfig = defaultDing
end

function Config.LoadConfig()
	local configFile = json.load_file(configPath)
	if configFile.dingConfig ~= nil then
		Config.uiConfig = configFile.uiConfig
        Config.dingConfig = configFile.dingConfig
	else
        local newConfig = {}
        newConfig.uiConfig = Config.uiConfig
        newConfig.dingConfig = Config.dingConfig
		json.dump_file(configPath, newConfig)
	end
end

function Config.SaveConfig()
    local newConfig = {}
    newConfig.uiConfig = Config.uiConfig
    newConfig.dingConfig = Config.dingConfig
	if json.load_file(configPath) ~= newConfig then
		json.dump_file(configPath, newConfig)
	end
end

function Config.SwitchDing(dingStr)
	if Config.dingConfig[dingStr] == nil then return end
    Config.dingConfig[dingStr] = not Config.dingConfig[dingStr]
end

function Config.BoolStateStr(stateStr)
	if Config.dingConfig[stateStr] == nil then return "error" end
    if Config.dingConfig[stateStr] then return "enabled" end
    return "disabled"
end

Config.Init()
if LOAD_CONFIG_FILE then
	Config.LoadConfig()
end

-- ==== Utils ====

local function SetInvincible(playerBaseContext)
    if playerBaseContext == nil then return end
    if Config.dingConfig.invincible == false then return end
    local hp = playerBaseContext:call("get_HitPoint")
    -- shouldn't call Set_XXX in real life, it may break the save
    -- hp:call("set_Invincible", true)
    -- hp:call("set_NoDamage", true)
    -- hp:call("set_NoDeath", true)
    -- hp:call("set_Immortal", true)
    hp:call("recovery", 99999)
end

-- ==== Hooks ====

-- ==== UI ====

local UI = {}
UI.Font = nil
UI.Row = 0
UI.RowHeight = 25
UI.PosX = 1400
UI.PosY = 200

function UI.Init(font)
    UI.Font = font
    UI.Row = 0
end

function UI.NewRow(str)
    d2d.text(UI.Font, str, UI.PosX + 10, UI.PosY + UI.Row * UI.RowHeight + 10, 0xFFFFFFFF)
    UI.Row = UI.Row + 1
end

function UI.DrawBackground(rows)
    d2d.fill_rect(UI.PosX, UI.PosY, 240, rows * UI.RowHeight + 20, 0x69000000)
end

local function FloatColumn(val)
	if val ~= nil then -- and val ~= 0 then
		return string.format("%.2f", val)
	end
	return ""
end

-- ==== Draw UI ====

re.on_draw_ui(function()
    if imgui.tree_node("RE4_Overlay") then
        if imgui.tree_node("Cheat Utils") then
            if imgui.button("Invincible") then
			    Config.SwitchDing("invincible")
		    end
            imgui.text(Config.BoolStateStr("invincible"))
            imgui.tree_pop()
        end
        if imgui.button("Save Config") then
			Config.SaveConfig()
		end
        if imgui.button("Reload Config") then
			Config.LoadConfig()
		end
        imgui.text("RE4_Overlay")
        imgui.tree_pop()
    end
end)

local font
local function initFont()
    if font == nil then
        font = d2d.Font.new("Tahoma", 24, true)
    end
    return font
end

d2d.register(function()
	initFont()
end,
	function()
        UI.Init(initFont())

        -- local posX = 1400
        -- local posY = 200
        -- local uiStep = 0

        -- d2d.fill_rect(posX, posY, 240, 220, 0x69000000)
        local gameRank = GetGameRankSystem()
        -- local gameRank
        if gameRank ~= nil then
            UI.DrawBackground(3)

            UI.NewRow("GameRank: " .. tostring(gameRank:get_field("_GameRank")))
            UI.NewRow("ActionPoint: " .. tostring(gameRank:get_field("_ActionPoint")))
            UI.NewRow("ItemPoint: " .. tostring(gameRank:get_field("_ItemPoint")))
            UI.NewRow("BackupActionPoint: " .. tostring(gameRank:get_field("BackupActionPoint")))
            UI.NewRow("BackupItemPoint: " .. tostring(gameRank:get_field("BackupItemPoint")))
            UI.NewRow("FixItemPoint: " .. tostring(gameRank:get_field("FixItemPoint")))
            UI.NewRow("RetryCount: " .. tostring(gameRank:call("get_RankPointPlRetryCount")))
            UI.NewRow("KillCount: " .. tostring(gameRank:call("get_RankPointKillCount")))
            
            UI.NewRow("")
            UI.NewRow("-- Enemy --")
            UI.NewRow("DamageRate: " .. FloatColumn(gameRank:call("getRankEnemyDamageRate")))
            UI.NewRow("WinceRate: " .. FloatColumn(gameRank:call("getRankEnemyWinceRate")))
            UI.NewRow("BreakRate: " .. FloatColumn(gameRank:call("getRankEnemyBreakRate")))
            UI.NewRow("StoppingRate: " .. FloatColumn(gameRank:call("getRankEnemyStoppingRate")))

            UI.NewRow("")
            UI.NewRow("KnifeReduceRate: " .. FloatColumn(gameRank:call("getKnifeReduceRate")))
            -- d2d.text(font, "GameRank: " .. tostring(gameRank:get_field("_GameRank")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            -- d2d.text(font, "ActionPoint: " .. tostring(gameRank:get_field("_ActionPoint")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            -- d2d.text(font, "ItemPoint: " .. tostring(gameRank:get_field("_ItemPoint")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            UI.NewRow("")
        else
            UI.DrawBackground(1)
            UI.NewRow("GameRankSystem is nil")
            -- d2d.text(font, "GameRankSystem is nil", posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
        end

        -- local attackPermit = GetEnemyAttackPermitManager()
        -- if attackPermit ~= nil then
        --     UI.NewRow("NowGameRank: " .. tostring(attackPermit:get_field("NowGameRank")))
        -- end

        local character = GetCharacterManager()
        if character ~= nil then
            local players = character:call("get_PlayerAndPartnerContextList") -- List<chainsaw.CharacterContext>
            
            local playerLen = players:call("get_Count")
            for i = 0, playerLen - 1, 1 do
                local playerCtx = players:call("get_Item", i)
                local hp = playerCtx:call("get_HitPoint")
                UI.NewRow(tostring(i) .. " HP: " .. 
                    tostring(hp:call("get_CurrentHitPoint")) .. "/" .. 
                    tostring(hp:call("get_DefaultHitPoint"))
                )
                if i == 0 then
                    SetInvincible(playerCtx)
                end
            end
        end

        local player = GetPlayerManager()
        if player ~= nil then
            -- UI.NewRow("1P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_1P")))
            -- UI.NewRow("2P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_2P")))
            UI.NewRow("Player Distance: " .. FloatColumn(player:call("get_WwisePlayerDistance")))
            UI.NewRow("")
        end

        local enemy = GetEnemyManager()
        if enemy ~= nil then
            -- UI.NewRow("EnemySpawnNumLimit: " .. tostring(enemy:get_field("EnemySpawnNumLimit")))

            -- -- local list = enemy:call("get_LinkEnemyList") -- List<chainsaw.EnemeyHeadUpdater>

            -- local combatEnemyDB = enemy:call("get_CombatEnemyDB") -- Dict<chainsaw.CharacterKindID, Hashset<UInt32>> -- guid? pointer?

            -- local combatEnemy = enemy:get_field("_CombatEnemyCollection") -- Hashset<UInt32> -- GUID? pointer?

            
            -- local inCameraEnemy = enemy:call("get_CameraInsideEnemyContextRefs") -- chainsaw.EnemyBaseContext[]
            -- chainsaw.EnemyBaseContext: GameRankAdd
            -- chainsaw.CharacterContext: KindID, SpawnerID (type is ContextID?), IsRespawn, BreakPartsHitPointList, _HitPointVital
            -- chainsaw.character.chxxxxx.WeakPointBackup
            -- chainsaw.chxxxxxWeakPoint.Info
            -- chainsaw.chxxxxxWeakPoint.DamageSetting
        end
	end
)


