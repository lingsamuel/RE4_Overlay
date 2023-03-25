

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

-- ==== Utils ====

local function GetEnumMap(enumTypeName)
	local t = sdk.find_type_definition(enumTypeName)
	if not t then return {} end

	local fields = t:get_fields()
	local enum = {}

	for i, field in ipairs(fields) do
		if field:is_static() then
			local name = field:get_name()
			local raw_value = field:get_data(nil)
			enum[raw_value] = name
		end
	end

	return enum
end

local KindMap = GetEnumMap("chainsaw.CharacterKindID")
local BodyPartsMap = GetEnumMap("chainsaw.character.BodyParts")
local BodyPartsSideMap = GetEnumMap("chainsaw.character.BodyPartsSide")

local function SetInvincible(playerBaseContext)
    if playerBaseContext == nil then return end

    -- TODO: Should check id?

    local hp = playerBaseContext:call("get_HitPoint")
    -- shouldn't call Set_XXX in real life, it may break the save
    -- hp:call("set_Invincible", true)
    -- hp:call("set_NoDamage", true)
    -- hp:call("set_NoDeath", true)
    -- hp:call("set_Immortal", true)
    hp:call("recovery", 99999)
end

-- ==== Hooks ====
local invincibleMode = true
local RETVAL_TRUE = sdk.to_ptr(1)

local PlayerBaseContext = sdk.find_type_definition("chainsaw.HitPoint")

-- These hooks doesn't work

-- sdk.hook(PlayerBaseContext:get_method("get_Invincible"),
-- function (args)

-- end, function (retval)
--     if invincibleMode then
--         return RETVAL_TRUE
--     end
-- 	return retval
-- end)

-- sdk.hook(PlayerBaseContext:get_method("get_NoDamage"),
-- function (args)

-- end, function (retval)
--     if invincibleMode then
--         return RETVAL_TRUE
--     end
-- 	return retval
-- end)

-- sdk.hook(PlayerBaseContext:get_method("get_NoDeath"),
-- function (args)

-- end, function (retval)
--     if invincibleMode then
--         return RETVAL_TRUE
--     end
-- 	return retval
-- end)

-- sdk.hook(PlayerBaseContext:get_method("get_Immortal"),
-- function (args)

-- end, function (retval)
--     if invincibleMode then
--         return RETVAL_TRUE
--     end
-- 	return retval
-- end)

-- ==== UI ====

local UI = {
    Font = nil,
    Row = 0,
    RowHeight = 25,
    PosX = 1400,
    PosY = 200,
}

function UI:new(o, posX, posY, font)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.Font = font
    self.Row = 0
    self.RowHeight = 25
    self.PosX = posX
    self.PosY = posY
    return o
end

function UI:NewRow(str)
    d2d.text(self.Font, str, self.PosX + 10, self.PosY + self.Row * self.RowHeight + 10, 0xFFFFFFFF)
    self.Row = self.Row + 1
end

function UI:DrawBackground(rows, width)
    d2d.fill_rect(self.PosX, self.PosY, width, rows * self.RowHeight + 20, 0x69000000)
end

local function FloatColumn(val)
	if val ~= nil then -- and val ~= 0 then
		return string.format("%.2f", val)
	end
	return ""
end

-- ==== Draw UI ====

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
        local StatsUI = UI:new(nil, 1400, 200, initFont())

        -- local posX = 1400
        -- local posY = 200
        -- local uiStep = 0

        -- d2d.fill_rect(posX, posY, 240, 220, 0x69000000)
        local gameRank = GetGameRankSystem()
        -- local gameRank
        if gameRank ~= nil then
            StatsUI:DrawBackground(3, 240)

            StatsUI:NewRow("GameRank: " .. tostring(gameRank:get_field("_GameRank")))
            StatsUI:NewRow("ActionPoint: " .. FloatColumn(gameRank:get_field("_ActionPoint")))
            StatsUI:NewRow("ItemPoint: " .. FloatColumn(gameRank:get_field("_ItemPoint")))
            StatsUI:NewRow("BackupActionPoint: " .. FloatColumn(gameRank:get_field("BackupActionPoint")))
            StatsUI:NewRow("BackupItemPoint: " .. FloatColumn(gameRank:get_field("BackupItemPoint")))
            StatsUI:NewRow("FixItemPoint: " .. FloatColumn(gameRank:get_field("FixItemPoint")))
            StatsUI:NewRow("RetryCount: " .. tostring(gameRank:call("get_RankPointPlRetryCount")))
            StatsUI:NewRow("KillCount: " .. tostring(gameRank:call("get_RankPointKillCount")))

            StatsUI:NewRow("")
            StatsUI:NewRow("-- Enemy --")
            StatsUI:NewRow("DamageRate: " .. FloatColumn(gameRank:call("getRankEnemyDamageRate")))
            StatsUI:NewRow("WinceRate: " .. FloatColumn(gameRank:call("getRankEnemyWinceRate")))
            StatsUI:NewRow("BreakRate: " .. FloatColumn(gameRank:call("getRankEnemyBreakRate")))
            StatsUI:NewRow("StoppingRate: " .. FloatColumn(gameRank:call("getRankEnemyStoppingRate")))

            StatsUI:NewRow("")
            StatsUI:NewRow("KnifeReduceRate: " .. FloatColumn(gameRank:call("getKnifeReduceRate")))
            -- d2d.text(font, "GameRank: " .. tostring(gameRank:get_field("_GameRank")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            -- d2d.text(font, "ActionPoint: " .. tostring(gameRank:get_field("_ActionPoint")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            -- d2d.text(font, "ItemPoint: " .. tostring(gameRank:get_field("_ItemPoint")), posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
            StatsUI:NewRow("")
        else
            StatsUI:DrawBackground(1, 240)
            StatsUI:NewRow("GameRankSystem is nil")
            -- d2d.text(font, "GameRankSystem is nil", posX + 10, posY + uiStep * 25 + 10, 0xFFFFFFFF)
            -- uiStep = uiStep + 1
        end

        -- local attackPermit = GetEnemyAttackPermitManager()
        -- if attackPermit ~= nil then
        --     StatsUI:NewRow("NowGameRank: " .. tostring(attackPermit:get_field("NowGameRank")))
        -- end

        local character = GetCharacterManager()
        if character ~= nil then
            local players = character:call("get_PlayerAndPartnerContextList") -- List<chainsaw.CharacterContext>

            local playerLen = players:call("get_Count")
            for i = 0, playerLen - 1, 1 do
                local playerCtx = players:call("get_Item", i)
                local hp = playerCtx:call("get_HitPoint")
                StatsUI:NewRow(tostring(i) .. " HP: " ..
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
            -- StatsUI:NewRow("1P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_1P")))
            -- StatsUI:NewRow("2P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_2P")))
            StatsUI:NewRow("Player Distance: " .. FloatColumn(player:call("get_WwisePlayerDistance")))
            StatsUI:NewRow("")
        end

        local enemy = GetEnemyManager()
        if enemy ~= nil then
            local EnemyUI = UI:new(nil, 0, 200, initFont())

            -- -- local list = enemy:call("get_LinkEnemyList") -- List<chainsaw.EnemeyHeadUpdater>

            -- local combatEnemyDB = enemy:call("get_CombatEnemyDB") -- Dict<chainsaw.CharacterKindID, Hashset<UInt32>> -- guid? pointer?

            -- local combatEnemy = enemy:get_field("_CombatEnemyCollection") -- Hashset<UInt32> -- GUID? pointer?

            EnemyUI:DrawBackground(10, 600)
            EnemyUI:NewRow("-- Enemey UI --")
            local inCameraEnemy = enemy:call("get_CameraInsideEnemyContextRefs") -- chainsaw.EnemyBaseContext[]
            local enemyLen = inCameraEnemy:call("get_Count")
            EnemyUI:NewRow("EnemyCount: " .. tostring(enemyLen))
            for i = 0, enemyLen - 1, 1 do
                local enemyCtx = inCameraEnemy:call("get_Item", i)

                local hp = enemyCtx:call("get_HitPoint")
                if hp ~= nil then
                    local currentHP = hp:call("get_CurrentHitPoint")
                    local maxHP = hp:call("get_DefaultHitPoint")
                    if currentHP > 0 then
                        EnemyUI:NewRow("Enemy: " .. tostring(i))

                        -- kind
                        local kindID = enemyCtx:call("get_KindID")
                        local kind = KindMap[kindID]
                        EnemyUI:NewRow(" KindID: ".. tostring(kindID) .. "/" .. kind)

                        -- hp
                        EnemyUI:NewRow(" HP: "
                            .. tostring(currentHP) .. "/"
                            .. tostring(maxHP)
                        )

                        -- add rank
                        local addRank = enemyCtx:call("get_GameRankAdd")
                        if addRank ~= 0 then
                            EnemyUI:NewRow(" GameRankAdd: " .. tostring(addRank))
                        end

                        -- parts
                        local parts = enemyCtx:call("get_BreakPartsHitPointDict"):get_field('_entries') -- Dict<<BodyParts, BodyPartsSide>, HitPoint>

                        local j = 0
                        for _,k in pairs(parts) do
                            local key = k:get_field('key')
                            local bodyParts = key:get_field("Item1")
                            local bodyPartsSide = key:get_field("Item2")
                            local partHP = k:get_field('value')
                            if partHP ~= nil then
                                local partCurrentHP = partHP:call("get_CurrentHitPoint")
                                local partMaxHP = partHP:call("get_DefaultHitPoint")
                                if partMaxHP < 99998 then
                                    if partMaxHP ~= partCurrentHP then
                                        EnemyUI:NewRow("  " .. BodyPartsMap[bodyParts] .. "("  .. BodyPartsSideMap[bodyPartsSide] .. "): "
                                            .. tostring(partCurrentHP) .. "/"
                                            .. tostring(partMaxHP)
                                        )
                                    end
                                end
                            end
                            j = j + 1
                        end

                        -- weakpoint

                        -- WeakPointData? WeakPointUnit?

                        if kind == "ch1_d6z0" then
                            -- chainsaw.Ch1d6z0Context

                        end
                    end
                end
            end

            -- chainsaw.EnemyBaseContext: GameRankAdd
            -- chainsaw.CharacterContext: KindID, SpawnerID (type is ContextID?), IsRespawn, BreakPartsHitPointList, _HitPointVital
            -- chainsaw.character.chxxxxx.WeakPointBackup
            -- chainsaw.chxxxxxWeakPoint.Info
            -- chainsaw.chxxxxxWeakPoint.DamageSetting
        end
	end
)


