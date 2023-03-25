

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
local draw = draw


local InventoryManager = sdk.get_managed_singleton("chainsaw.InventoryManager")
local function GetInventoryManager()
    if InventoryManager == nil then InventoryManager = sdk.get_managed_singleton("chainsaw.InventoryManager") end
	return InventoryManager
end

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

local function GetEnemyList()
    local cha = GetCharacterManager()
    if cha == nil then return nil end
    return cha:call("get_EnemyContextList")
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

local Config = json.load_file("RE4_Overlay/RE4_Overlay.json") or {}
if Config.Enabled == nil then
    Config.Enabled = true
end
if Config.StatsUI == nil then
    Config.StatsUI = {
        PosX = 1400,
        PosY = 200,
        RowHeight = 25,
        Width = 400,
        DrawPlayerHPBar = false,
    }
end
if Config.StatsUI.Enabled == nil then
    Config.StatsUI.Enabled = true
end

if Config.EnemyUI == nil then
    Config.EnemyUI = {
        PosX = 0,
        PosY = 200,
        RowHeight = 25,
        Width = 400,
        DrawEnemyHPBar = true,
        DrawPartHPBar = true,
        FilterMaxHPEnemy = true,
        FilterMaxHPPart = true,
        FilterUnbreakablePart = true,
    }
end
if Config.EnemyUI.Enabled == nil then
    Config.EnemyUI.Enabled = true
end
if Config.EnemyUI.DisplayPartHP == nil then
    Config.EnemyUI.DisplayPartHP = true
end
if Config.EnemyUI.FilterNoInSightEnemy == nil then
    Config.EnemyUI.FilterNoInSightEnemy = false
end

if Config.FloatingUI == nil then
    Config.FloatingUI = {
        Enabled = true,

        FilterMaxHPEnemy = false,
        FilterBlockedEnemy = true,
        MaxDistance = 15,
        IgnoreDistanceIfDamaged = true,
        IgnoreDistanceIfDamagedScale = 0.8,

        DisplayNumber = false,

        WorldPosOffsetX = 0,
        WorldPosOffsetY = 1.75,
        WorldPosOffsetZ = 0,

        ScreenPosOffsetX = -125,
        ScreenPosOffsetY = 0,

        Height = 14,
        Width = 200,
        MinScale = 0.3,
        ScaleHeightByDistance = true,
        ScaleWidthByDistance = false,
    }
end

if Config.CheatConfig == nil then
    Config.CheatConfig = {
        LockHitPoint = false,
    }
end
if Config.CheatConfig.NoHitMode == nil then
    Config.CheatConfig.NoHitMode = false
end

if Config.DebugMode == nil then
	Config.DebugMode = false
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
    -- TODO: Should check id?
    if playerBaseContext == nil then return end

    local hp = playerBaseContext:call("get_HitPoint")
    if Config.CheatConfig.LockHitPoint then
        hp:call("recovery", 99999)
    end

    if Config.CheatConfig.NoHitMode then
        -- shouldn't call Set_XXX in real life, it may break the save
        hp:call("set_Invincible", true)
        -- hp:call("set_NoDamage", true)
        -- hp:call("set_NoDeath", true)
        -- hp:call("set_Immortal", true)
    else
        hp:call("set_Invincible", false)
        -- hp:call("set_NoDamage", false)
        -- hp:call("set_NoDeath", false)
        -- hp:call("set_Immortal", false)
    end
end

-- ==== Hooks ====
local RETVAL_TRUE = sdk.to_ptr(1)

local TypedefPlayerBaseContext = sdk.find_type_definition("chainsaw.HitPoint")
local TypedefInventoryManager = sdk.find_type_definition("chainsaw.InventoryManager")
local TypedefItemUseManager = sdk.find_type_definition("chainsaw.ItemUseManager")
local TypedefInventoryControllerBase = sdk.find_type_definition("chainsaw.InventoryControllerBase")


-- sdk.hook(TypedefInventoryControllerBase:get_method("reduceItem(chainsaw.ItemID, System.Int32)"),
-- function (args)
--     return sdk.PreHookResult.SKIP_ORIGINAL
-- end, function (retval)
-- 	return retval
-- end)

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
    Width = 400,
}

function UI:new(o, posX, posY, rowHeight, width, font)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.Font = font
    self.Row = 0
    self.RowHeight = rowHeight
    self.PosX = posX
    self.PosY = posY
    self.Width = width
    return o
end

function UI:GetCurrentRowPosY()
    return self.PosY + self.Row * self.RowHeight + 10
end

function UI:NewRow(str)
    d2d.text(self.Font, str, self.PosX + 10, self:GetCurrentRowPosY(), 0xFFFFFFFF)
    self.Row = self.Row + 1
end

function UI:DrawBackground(rows)
    d2d.fill_rect(self.PosX, self.PosY, self.Width, rows * self.RowHeight + 20, 0x69000000)
end

local function FloatColumn(val)
	if val ~= nil then -- and val ~= 0 then
		return string.format("%.2f", val)
	end
	return ""
end

-- ==== Draw UI ====

-- drawHPBar, width, leftOffset are optional
local function DrawHP(ui, name, hp, drawHPBar, width, leftOffset)
    local current = hp:call("get_CurrentHitPoint")
    local max = hp:call("get_DefaultHitPoint")
    ui:NewRow(name .. tostring(current) .. "/" .. tostring(max))

    if drawHPBar then
        if leftOffset == nil then leftOffset = 0 end

        d2d.fill_rect(ui.PosX + 10 + leftOffset, ui:GetCurrentRowPosY() + 4, width - 20 - leftOffset, ui.RowHeight - 8, 0xFFCCCCCC)
        d2d.fill_rect(ui.PosX + 10 + leftOffset, ui:GetCurrentRowPosY() + 4, current/max*(width-20-leftOffset), ui.RowHeight - 8, 0xFF5c9e76)
        ui:NewRow("")
    end
end

local fontTable = {}
local function initFont(size)
    if size == nil then size = 24 end
    if fontTable[size] == nil then
        fontTable[size] = d2d.Font.new("Tahoma", size, true)
    end
    return fontTable[size]
end

d2d.register(function()
	initFont()
end,
	function()
        if not Config.Enabled then return end

        local StatsUI = UI:new(nil, Config.StatsUI.PosX, Config.StatsUI.PosY, Config.StatsUI.RowHeight, Config.StatsUI.Width, initFont())

        -- local posX = 1400
        -- local posY = 200
        -- local uiStep = 0

        -- d2d.fill_rect(posX, posY, 240, 220, 0x69000000)
        local gameRank = GetGameRankSystem()
        -- local gameRank
        if Config.StatsUI.Enabled and gameRank ~= nil then
            StatsUI:DrawBackground(17)

            StatsUI:NewRow("GameRank: " .. tostring(gameRank:get_field("_GameRank")))
            StatsUI:NewRow("ActionPoint: " .. FloatColumn(gameRank:get_field("_ActionPoint")))
            StatsUI:NewRow("ItemPoint: " .. FloatColumn(gameRank:get_field("_ItemPoint")))
            -- StatsUI:NewRow("BackupActionPoint: " .. FloatColumn(gameRank:get_field("BackupActionPoint")))
            -- StatsUI:NewRow("BackupItemPoint: " .. FloatColumn(gameRank:get_field("BackupItemPoint")))
            -- StatsUI:NewRow("FixItemPoint: " .. FloatColumn(gameRank:get_field("FixItemPoint")))
            StatsUI:NewRow("RetryCount: " .. tostring(gameRank:call("get_RankPointPlRetryCount")))
            StatsUI:NewRow("KillCount: " .. tostring(gameRank:call("get_RankPointKillCount")))

            StatsUI:NewRow("")
            StatsUI:NewRow("PlayerDamageRate: " .. FloatColumn(gameRank:call("getRankPlayerDamageRate", nil)))
            StatsUI:NewRow("-- Enemy --")
            StatsUI:NewRow("DamageRate: " .. FloatColumn(gameRank:call("getRankEnemyDamageRate")))
            StatsUI:NewRow("WinceRate: " .. FloatColumn(gameRank:call("getRankEnemyWinceRate")))
            StatsUI:NewRow("BreakRate: " .. FloatColumn(gameRank:call("getRankEnemyBreakRate")))
            StatsUI:NewRow("StoppingRate: " .. FloatColumn(gameRank:call("getRankEnemyStoppingRate")))

            StatsUI:NewRow("")
            StatsUI:NewRow("KnifeReduceRate: " .. FloatColumn(gameRank:call("getKnifeReduceRate")))
            StatsUI:NewRow("")
        end

        -- local attackPermit = GetEnemyAttackPermitManager()
        -- if attackPermit ~= nil then
        --     StatsUI:NewRow("NowGameRank: " .. tostring(attackPermit:get_field("NowGameRank")))
        -- end

        local masterPlayer = nil

        local character = GetCharacterManager()
        if character ~= nil then
            local players = character:call("get_PlayerAndPartnerContextList") -- List<chainsaw.CharacterContext>

            local playerLen = players:call("get_Count")
            for i = 0, playerLen - 1, 1 do
                local playerCtx = players:call("get_Item", i)
                local hp = playerCtx:call("get_HitPoint")

                if Config.StatsUI.Enabled then
                    DrawHP(StatsUI, "Player " .. tostring(i) .. " HP: ", hp, Config.StatsUI.DrawPlayerHPBar, Config.StatsUI.Width, 0)
                end
                -- StatsUI:NewRow("Player " .. tostring(i) .. " HP: " ..
                --     tostring(hp:call("get_CurrentHitPoint")) .. "/" ..
                --     tostring(hp:call("get_DefaultHitPoint"))
                -- )
                if i == 0 then
                    masterPlayer = playerCtx
                    SetInvincible(playerCtx)
                end
            end
        end

        local player = GetPlayerManager()
        if Config.StatsUI.Enabled and player ~= nil then
            -- StatsUI:NewRow("1P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_1P")))
            -- StatsUI:NewRow("2P HP: " .. FloatColumn(player:call("get_WwisePlayerHPRatio_2P")))
            StatsUI:NewRow("Player Distance: " .. FloatColumn(player:call("get_WwisePlayerDistance")))
            StatsUI:NewRow("")
        end

        local enemy = GetEnemyManager()
        if enemy ~= nil then
            local EnemyUI = UI:new(nil, Config.EnemyUI.PosX, Config.EnemyUI.PosY, Config.EnemyUI.RowHeight, Config.EnemyUI.Width, initFont())

            -- -- local list = enemy:call("get_LinkEnemyList") -- List<chainsaw.EnemeyHeadUpdater>

            -- local combatEnemyDB = enemy:call("get_CombatEnemyDB") -- Dict<chainsaw.CharacterKindID, Hashset<UInt32>> -- guid? pointer?

            -- local combatEnemy = enemy:get_field("_CombatEnemyCollection") -- Hashset<UInt32> -- GUID? pointer?

            EnemyUI:DrawBackground(40)
            EnemyUI:NewRow("-- Enemey UI --")

            local enemies
            if Config.EnemyUI.FilterNoInSightEnemy then
                enemies = enemy:call("get_CameraInsideEnemyContextRefs") -- chainsaw.EnemyBaseContext[]
            else
                enemies = GetEnemyList()
            end
            local enemyLen = enemies:call("get_Count")

            if Config.DebugMode then
                EnemyUI:NewRow("EnemyCount: " .. tostring(enemyLen))
            end

            for i = 0, enemyLen - 1, 1 do
                local enemyCtx = enemies:call("get_Item", i)

                local lively = enemyCtx:call("get_IsLively")
                local combatReady = enemyCtx:call("get_IsCombatReady")
                local hp = enemyCtx:call("get_HitPoint")
                if lively and combatReady and hp ~= nil then
                    local currentHP = hp:call("get_CurrentHitPoint")
                    local maxHP = hp:call("get_DefaultHitPoint")

                    -- Floating UI
                    if Config.FloatingUI.Enabled and masterPlayer ~= nil then
                        local allowFloating = true

                        local playerPos = masterPlayer:call("get_Position")
                        local worldPos = enemyCtx:call("get_Position")
                        local delta = playerPos - worldPos
                        local distance = math.sqrt(delta.x * delta.x + delta.y * delta.y)

                        if Config.FloatingUI.FilterMaxHPEnemy and currentHP >= maxHP then
                            allowFloating = false
                        end

                        if distance > Config.FloatingUI.MaxDistance then
                            if Config.FloatingUI.IgnoreDistanceIfDamaged and currentHP < maxHP then
                                allowFloating = true
                            else
                                allowFloating = false
                            end
                        end

                        if Config.FloatingUI.FilterBlockedEnemy then
                            allowFloating = allowFloating and enemyCtx:call("get_HasRayToPlayer")
                        end

                        if Config.DebugMode then
                            EnemyUI:NewRow("Enemy: " .. tostring(i) .. " Distance: ".. FloatColumn(distance))
                        end

                        if allowFloating then
                            local height = Config.FloatingUI.Height
                            local width = Config.FloatingUI.Width

                            local scale = (Config.FloatingUI.MaxDistance - distance) / Config.FloatingUI.MaxDistance
                            if distance > Config.FloatingUI.MaxDistance then
                                scale = Config.FloatingUI.IgnoreDistanceIfDamagedScale
                            end
                            if scale < Config.FloatingUI.MinScale then
                                scale = Config.FloatingUI.MinScale
                            end
                            if Config.FloatingUI.ScaleHeightByDistance then
                                height = height * scale
                            end
                            if Config.FloatingUI.ScaleWidthByDistance then
                                width = width * scale
                            end

                            if Config.DebugMode then
                                EnemyUI:NewRow("Enemy: " .. tostring(i) .. " Bar Scale: ".. FloatColumn(scale))
                            end

                            worldPos.x = worldPos.x + Config.FloatingUI.WorldPosOffsetX
                            worldPos.y = worldPos.y + Config.FloatingUI.WorldPosOffsetY
                            worldPos.z = worldPos.z + Config.FloatingUI.WorldPosOffsetZ
                            local screenPos = draw.world_to_screen(worldPos)

                            if Config.FloatingUI.DisplayNumber then
                                d2d.text(initFont(18), "HP: " .. tostring(currentHP) .. "/" .. tostring(maxHP), screenPos.x + Config.FloatingUI.ScreenPosOffsetX, screenPos.y + Config.FloatingUI.ScreenPosOffsetY - 24, 0xFFFFFFFF)
                            end
                            d2d.fill_rect(screenPos.x + Config.FloatingUI.ScreenPosOffsetX, screenPos.y + Config.FloatingUI.ScreenPosOffsetY, width, height, 0xFFCCCCCC)
                            d2d.fill_rect(screenPos.x + Config.FloatingUI.ScreenPosOffsetX, screenPos.y + Config.FloatingUI.ScreenPosOffsetY, currentHP / maxHP * width, height, 0xFF5c9e76)
                        end

                    end

                    -- Enemy UI Panel
                    local allowEnemy = currentHP > 0
                    if Config.EnemyUI.FilterMaxHPEnemy then
                        allowEnemy = allowEnemy and currentHP < maxHP
                    end
                    if Config.EnemyUI.Enabled and allowEnemy then
                        EnemyUI:NewRow("Enemy: " .. tostring(i))

                        local kindID = enemyCtx:call("get_KindID")
                        local kind = KindMap[kindID]
                        if Config.DebugMode then
                            -- kind
                            EnemyUI:NewRow(" KindID: ".. tostring(kindID) .. "/" .. kind)
                            EnemyUI:NewRow(" Lively: ".. tostring(enemyCtx:call("get_IsLively")))
                            EnemyUI:NewRow(" IsCombatReady: ".. tostring(enemyCtx:call("get_IsCombatReady")))
                        end

                        -- hp
                        DrawHP(EnemyUI, " HP: ", hp, Config.EnemyUI.DrawEnemyHPBar, Config.EnemyUI.Width, 0)
                        -- EnemyUI:NewRow(" HP: "
                        --     .. tostring(currentHP) .. "/"
                        --     .. tostring(maxHP)
                        -- )

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

                                local allow = true
                                if Config.EnemyUI.FilterMaxHPPart then
                                    allow = allow and partCurrentHP < partMaxHP
                                end
                                if Config.EnemyUI.FilterUnbreakablePart then
                                    allow = allow and partMaxHP < maxHP
                                end
                                if allow then
                                    if Config.EnemyUI.DisplayPartHP then
                                        DrawHP(EnemyUI, "  " .. BodyPartsMap[bodyParts] .. "("  .. BodyPartsSideMap[bodyPartsSide] .. "): ", partHP, Config.EnemyUI.DrawPartHPBar, Config.EnemyUI.Width, 20)
                                    end
                                    -- EnemyUI:NewRow("  " .. BodyPartsMap[bodyParts] .. "("  .. BodyPartsSideMap[bodyPartsSide] .. "): "
                                    --     .. tostring(partCurrentHP) .. "/"
                                    --     .. tostring(partMaxHP)
                                    -- )
                                end
                            end
                            j = j + 1
                        end

                        -- weakpoint

                        -- WeakPointData? WeakPointUnit?

                        if kind == "ch1_d6z0" then
                            -- chainsaw.Ch1d6z0Context
                            EnemyUI:NewRow(" WeakPointType: " .. tostring(enemyCtx:call("get_WeakPointType")))
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

-- === Menu ===

re.on_draw_ui(function()
	local configChanged = false
    if imgui.tree_node("RE4 Overlay") then
		local changed = false
		changed, Config.Enabled = imgui.checkbox("Enabled", Config.Enabled)
		configChanged = configChanged or changed

        if imgui.tree_node("Cheat Utils") then
            changed, Config.CheatConfig.LockHitPoint = imgui.checkbox("Full HitPoint (recovery 99999 hp every frame)", Config.CheatConfig.LockHitPoint)
            configChanged = configChanged or changed

            imgui.text("No Hit Mode (WARNING: may corrupt save or have unexpected bugs, I am not sure)")
            changed, Config.CheatConfig.NoHitMode = imgui.checkbox("No Hit Mode", Config.CheatConfig.NoHitMode)
            configChanged = configChanged or changed

            imgui.text("Set PTAS")
			local _, ptasValue = imgui.input_text("Set PTAS", "");
            local ptas = tonumber(ptasValue)
            if ptas ~= nil then
				local inventory = GetInventoryManager()
                if inventory ~= nil then
                    inventory:call("setPTAS", ptas)
                end
			end

            local gameRank = GetGameRankSystem()

            imgui.text("Set ActionPoint")
			local _, actionPointValue = imgui.input_text("Set ActionPoint", "");
            local actionPoint = tonumber(actionPointValue)
            if actionPoint ~= nil then
                if actionPoint > 5000 then actionPoint = 5000 end
                if actionPoint < -5000 then actionPoint = -5000 end
                if gameRank ~= nil then
                    gameRank:set_field("_ActionPoint", actionPoint)
                end
			end

            imgui.text("Set ItemPoint")
			local _, itemPointValue = imgui.input_text("Set ItemPoint", "");
            local itemPoint = tonumber(itemPointValue)
            if itemPoint ~= nil then
                if itemPoint > 100000 then itemPoint = 100000 end
                if itemPoint < 0 then itemPoint = 0 end
                if gameRank ~= nil then
                    gameRank:set_field("_ItemPoint", itemPoint)
                end
			end

            imgui.tree_pop()
        end

		if imgui.tree_node("Customize Stats UI") then
            changed, Config.StatsUI.Enabled = imgui.checkbox("Enabled", Config.StatsUI.Enabled)
            configChanged = configChanged or changed
            changed, Config.StatsUI.DrawPlayerHPBar = imgui.checkbox("Draw Player HP Bar", Config.StatsUI.DrawPlayerHPBar)
            configChanged = configChanged or changed

			_, Config.StatsUI.PosX = imgui.drag_int("PosX", Config.StatsUI.PosX, 20, 0, 4000)
			_, Config.StatsUI.PosY = imgui.drag_int("PosY", Config.StatsUI.PosY, 20, 0, 4000)
			_, Config.StatsUI.RowHeight = imgui.drag_int("RowHeight", Config.StatsUI.RowHeight, 1, 10, 100)
			_, Config.StatsUI.Width = imgui.drag_int("Width", Config.StatsUI.Width, 1, 10, 1000)

			imgui.tree_pop()
		end

		if imgui.tree_node("Customize Enemy UI") then
            changed, Config.EnemyUI.Enabled = imgui.checkbox("Enabled", Config.EnemyUI.Enabled)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.DrawEnemyHPBar = imgui.checkbox("Draw Enemy HP Bar", Config.EnemyUI.DrawEnemyHPBar)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.DisplayPartHP = imgui.checkbox("Dispaly Enemy Part HP Number", Config.EnemyUI.DisplayPartHP)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.DrawPartHPBar = imgui.checkbox("Draw Enemy Part HP Bar", Config.EnemyUI.DrawPartHPBar)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.FilterMaxHPEnemy = imgui.checkbox("Filter Max HP Enemy", Config.EnemyUI.FilterMaxHPEnemy)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.FilterMaxHPPart = imgui.checkbox("Filter Max HP Part", Config.EnemyUI.FilterMaxHPPart)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.FilterUnbreakablePart = imgui.checkbox("Filter Unbreakable Part", Config.EnemyUI.FilterUnbreakablePart)
            configChanged = configChanged or changed
            changed, Config.EnemyUI.FilterNoInSightEnemy = imgui.checkbox("Filter No In Sight Enemy (disable to show all enemey)", Config.EnemyUI.FilterNoInSightEnemy)
            configChanged = configChanged or changed

			_, Config.EnemyUI.PosX = imgui.drag_int("PosX", Config.EnemyUI.PosX, 20, 0, 4000)
			_, Config.EnemyUI.PosY = imgui.drag_int("PosY", Config.EnemyUI.PosY, 20, 0, 4000)
			_, Config.EnemyUI.RowHeight = imgui.drag_int("RowHeight", Config.EnemyUI.RowHeight, 1, 10, 100)
			_, Config.EnemyUI.Width = imgui.drag_int("Width", Config.EnemyUI.Width, 1, 10, 1000)

			imgui.tree_pop()
		end

		if imgui.tree_node("Customize Floating Enemy UI") then
            changed, Config.FloatingUI.Enabled = imgui.checkbox("Enabled", Config.FloatingUI.Enabled)
            configChanged = configChanged or changed
            changed, Config.FloatingUI.FilterMaxHPEnemy = imgui.checkbox("Filter Max HP Enemy", Config.FloatingUI.FilterMaxHPEnemy)
            configChanged = configChanged or changed
            changed, Config.FloatingUI.FilterBlockedEnemy = imgui.checkbox("Filter Blocked Enemy", Config.FloatingUI.FilterBlockedEnemy)
            configChanged = configChanged or changed

            changed, Config.FloatingUI.MaxDistance = imgui.drag_float("Max Display Distance", Config.FloatingUI.MaxDistance, 0.1, 0.1, 1000, "%.1f")
            configChanged = configChanged or changed
            changed, Config.FloatingUI.IgnoreDistanceIfDamaged = imgui.checkbox("Ignore Distance Limit If Damaged", Config.FloatingUI.IgnoreDistanceIfDamaged)
            configChanged = configChanged or changed

            changed, Config.FloatingUI.IgnoreDistanceIfDamagedScale = imgui.drag_float("Ignore Distance Limit If Damaged UI Scale", Config.FloatingUI.IgnoreDistanceIfDamagedScale, 0.01, 0.01, 10, "%.2f")
            configChanged = configChanged or changed

            changed, Config.FloatingUI.DisplayNumber = imgui.checkbox("Display Detailed Number", Config.FloatingUI.DisplayNumber)
            configChanged = configChanged or changed

            imgui.text("\nWorld pos offset in 3D game world")
			_, Config.FloatingUI.WorldPosOffsetX = imgui.drag_float("World Pos Offset X", Config.FloatingUI.WorldPosOffsetX, 0.01, -10, 10, "%.2f")
			_, Config.FloatingUI.WorldPosOffsetY = imgui.drag_float("World Pos Offset Y", Config.FloatingUI.WorldPosOffsetY, 0.01, -10, 10, "%.2f")
			_, Config.FloatingUI.WorldPosOffsetZ = imgui.drag_float("World Pos Offset Z", Config.FloatingUI.WorldPosOffsetZ, 0.01, -10, 10, "%.2f")

            imgui.text("\nWorld pos offset in 2d screen")
			_, Config.FloatingUI.ScreenPosOffsetX = imgui.drag_int("Screen Pos Offset X", Config.FloatingUI.ScreenPosOffsetX, 1, -4000, 4000)
			_, Config.FloatingUI.ScreenPosOffsetY = imgui.drag_int("Screen Pos Offset Y", Config.FloatingUI.ScreenPosOffsetY, 1, -4000, 4000)

            imgui.text("\nFloating HP bar height and width")
			_, Config.FloatingUI.Height = imgui.drag_int("Height", Config.FloatingUI.Height, 1, 10, 100)
			_, Config.FloatingUI.Width = imgui.drag_int("Width", Config.FloatingUI.Width, 1, 10, 1000)
            changed, Config.FloatingUI.ScaleHeightByDistance = imgui.checkbox("Scale Height By Distance", Config.FloatingUI.ScaleHeightByDistance)
            configChanged = configChanged or changed
            changed, Config.FloatingUI.ScaleWidthByDistance = imgui.checkbox("Scale Width By Distance", Config.FloatingUI.ScaleWidthByDistance)
            configChanged = configChanged or changed
            _, Config.FloatingUI.MinScale = imgui.drag_float("Min Scale", Config.FloatingUI.MinScale, 0.01, 0.1, 10, "%.2f")

			imgui.tree_pop()
		end

		changed, Config.DebugMode = imgui.checkbox("DebugMode", Config.DebugMode)
		configChanged = configChanged or changed

        imgui.tree_pop()

        if configChanged then
            json.dump_file("RE4_Overlay/RE4_Overlay.json", Config)
        end
    end
end)

re.on_config_save(function()
	json.dump_file("RE4_Overlay/RE4_Overlay.json", Config)
end)
