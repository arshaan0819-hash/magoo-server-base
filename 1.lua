local file_util = {}
local SavedFileUtil = nil
pcall(function() SavedFileUtil = import("SavedFileUtil") end)
function file_util.FindFiles(targetDir, extension, recursive, asTable)
  extension = extension or ""
  if recursive == nil then recursive = false end
  if SavedFileUtil and SavedFileUtil.FindFiles then
    local files = SavedFileUtil.FindFiles(targetDir, extension, recursive)
    if asTable then
      local fileList = {}
      for k, v in pairs(files) do fileList[k] = v end
      return fileList
    end
    return files
  end
  return asTable and {} or nil
end
function file_util.ReadFile(filePath)
  if not filePath or filePath == "" then return nil end
  local ok, content = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.ReadFile) == "function" then
      return SavedFileUtil.ReadFile(filePath)
    end
    local f = io.open(filePath, "r")
    if f then local data = f:read("*a"); f:close(); return data end
    return nil
  end)
  if ok and content ~= nil then return content end
  return nil
end
function file_util.WriteFile(filePath, content)
  if not filePath or content == nil then return false end
  local ok, result = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.WriteFile) == "function" then
      return SavedFileUtil.WriteFile(filePath, content)
    end
    local f = io.open(filePath, "w")
    if f then f:write(content); f:close(); return true end
    return false
  end)
  return ok and result or false
end
function file_util.FileExists(filePath)
  if not filePath or filePath == "" then return false end
  local ok, result = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.FileExists) == "function" then
      return SavedFileUtil.FileExists(filePath)
    end
    local f = io.open(filePath, "r")
    if f then f:close(); return true end
    return false
  end)
  return ok and result or false
end
pcall(function()
    local loadAttempts = 0
    local function loadMagooCore()
        if _G._MAGOO_FILEUTIL_MOD_LOADED then return end
        loadAttempts = loadAttempts + 1
        print("[MAGOO] file_util loading core (attempt " .. tostring(loadAttempts) .. ")")
        local function onError(err)
            local msg = "[MAGOO] LOAD ERROR: " .. tostring(err)
            print(msg)
            pcall(function()
                if debug and debug.traceback then
                    print(debug.traceback(tostring(err), 2))
                end
            end)
            _G._MAGOO_FILEUTIL_MOD_LOADED = false
        end
        local ok = xpcall(function()
            _G._MAGOO_FILEUTIL_MOD_LOADED = true
            local SUPPORTED_PACKAGES = {
                ["com.tencent.ig"]        = "Global",
                ["com.pubg.krmobile"]     = "Korea",
                ["com.vng.pubgmobile"]    = "Vietnam",
                ["com.rekoo.pubgm"]       = "Taiwan",
                ["com.pubg.imobile"]      = "BGMI",
                ["com.pubg.krmobile.ig"]  = "Korea-Alt",
                ["com.tencent.tmgp.pubgmhd"] = "CN",
                ["com.tencent.tmgp.pubgm"] = "CN-Alt",
            }
            local packageName = nil
            local gameRegion = "Unknown"
            pcall(function()
                local KSL = import("KismetSystemLibrary")
                if KSL and KSL.GetGameBundleId then
                    packageName = KSL:GetGameBundleId()
                end
            end)
            if not packageName then
                local probes = {
                    "com.tencent.ig", "com.pubg.krmobile", "com.vng.pubgmobile",
                    "com.rekoo.pubgm", "com.pubg.imobile", "com.tencent.tmgp.pubgmhd",
                    "com.tencent.tmgp.pubgm"
                }
                for _, pkg in ipairs(probes) do
                    local f = io.open("//storage/emulated/0/Android/data/" .. pkg .. "/", "r")
                    if f then f:close() packageName = pkg break end
                end
            end
            if not packageName then
                packageName = "com.tencent.ig"
            end
            gameRegion = SUPPORTED_PACKAGES[packageName] or "Unknown"
            print("[RJ MOD] Package: " .. packageName .. " (" .. gameRegion .. ")")
            local PATHS = {
                PubgData     = "//storage/emulated/0/Android/data/" .. packageName .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/",
                Paks         = nil,
                SaveGames    = nil,
                Cache        = nil,
                DataCache    = nil,
            }
            PATHS.Paks      = PATHS.PubgData .. "Paks/"
            PATHS.SaveGames = PATHS.PubgData .. "SaveGames/"
            PATHS.Cache     = PATHS.PubgData .. "image_download_mgr/temporary/Daliy/imgdownload_20713/"
            PATHS.DataCache = "//storage/emulated/0/Android/data/" .. packageName .. "/cache/"
            local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }
            pcall(function()
                local EPC = UEnums and UEnums.EPropertyClass
                BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
                if EPC then
                    BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { EPC.Object } }
                    BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { EPC.Int } }
                    BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { EPC.Int } }
                    BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { EPC.Bool } }
                    BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { EPC.UInt32, EPC.UInt32 } }
                end
            end)
            local ENetRole = import("ENetRole")
            local EPawnState = import("EPawnState")
            local GameplayData = nil
            pcall(function() GameplayData = require("GameLua.GameCore.Data.GameplayData") end)
            local GamePlayTools = nil
            pcall(function() GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") end)
            local function safeRequire(...)
                local ok, result = pcall(require, ...)
                if ok and result then return result end
                return nil
            end
            local function safeImport(name)
                local ok, result = pcall(import, name)
                if ok and result then return result end
                return nil
            end
            local IS_32BIT = false
            pcall(function()
                if jit and jit.arch then
                    IS_32BIT = (jit.arch == "x86" or jit.arch == "arm")
                else
                    local probe = collectgarbage("count")
                    IS_32BIT = (probe > 0 and tostring(2^31) ~= "2147483648")
                end
            end)
            local _ticker_cache = nil
            local function GetTicker()
                if _ticker_cache then return _ticker_cache end
                local ok, tk = pcall(require, "common.time_ticker")
                if ok and tk then _ticker_cache = tk end
                return _ticker_cache
            end
            pcall(function()
                local tk = nil
                local ok, t = pcall(require, "common.time_ticker")
                if ok then tk = t end
                if tk and tk.AddTimerOnce then
                    tk.AddTimerOnce(0.1, function()
                        pcall(function()
                            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                            if not pc then return end
                            if pc.HiggsBoson then
                                pc.HiggsBoson.bMHActive = false
                                pc.HiggsBoson.bCallPreReplication = false
                            end
                            if pc.HiggsBosonComponent then
                                pc.HiggsBosonComponent.bMHActive = false
                                pc.HiggsBosonComponent.bCallPreReplication = false
                            end
                        end)
                    end)
                    tk.AddTimerOnce(0.4, function()
                        pcall(function()
                            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                            if not pc then return end
                            if pc.HiggsBoson then
                                pc.HiggsBoson.bMHActive = false
                                pc.HiggsBoson.bCallPreReplication = false
                            end
                            if pc.HiggsBosonComponent then
                                pc.HiggsBosonComponent.bMHActive = false
                                pc.HiggsBosonComponent.bCallPreReplication = false
                            end
                        end)
                    end)
                end
            end)
            local LIMITS = {
                MAX_BOT_CACHE       = IS_32BIT and 120 or 400,
                MAX_VIS_CACHE       = IS_32BIT and 40  or 120,
                MAX_MID_CACHE       = IS_32BIT and 80  or 250,
                MAX_ENEMY_MARKS     = IS_32BIT and 16  or 32,
                MAX_TRACKED_MARKS   = IS_32BIT and 32  or 64,
                ESP_MAX_DISTANCE    = IS_32BIT and 200 or 350,
                BONE_ESP_MAX_DIST   = IS_32BIT and 80  or 200,
                AIMBOT_TICK         = IS_32BIT and 0.07  or 0.045,
                MAIN_TICK           = IS_32BIT and 2.20  or 1.80,
                CONFIG_SAVE_INTERVAL= IS_32BIT and 30    or 20,
                AUTO_HEAD_DEFAULT   = not IS_32BIT,
                ESP6_DEFAULT        = not IS_32BIT,
                ESPVIPPRO_DEFAULT   = not IS_32BIT,
                MAX_ESP_LINES       = IS_32BIT and 6   or 12,
                ESP_LINE_UPDATE     = IS_32BIT and 0.20  or 0.15,
                ESP_LINE_THICKNESS  = 0.8,
                ESP_LINE_MAX_DIST   = IS_32BIT and 250 or 500,
                ESP_LINE_SMOOTH     = 0.40,
                VIS_CACHE_TIME      = 0.35,
            }
            local isExpired = true
            _G._LICENSE_OK = _G._LICENSE_OK == true and true or false
            if _G._LICENSE_OK then isExpired = false end
            local function IsFeatureLocked()
                if _G._LICENSE_OK == true then
                    isExpired = false
                    _G._MOD_EXPIRED = false
                    return false
                end
                return isExpired == true
            end
            _G.IsFeatureLocked = IsFeatureLocked
            local LoginSystem = (function()
                local Config = {
                    LICENSE_URL  = "https://xswmygejlliwjgmeogrl.supabase.co/functions/v1/verify-license",
                    LOGIN_URL    = "https://xswmygejlliwjgmeogrl.supabase.co/functions/v1/verify-license",
                    GAME_NAME    = "pubg",
                    KEY_FILE     = "//storage/emulated/0/Android/data/" .. tostring(packageName or "com.tencent.ig") .. "/files/keys.txt",
                    UID_FILE     = "//storage/emulated/0/Android/data/" .. tostring(packageName or "com.tencent.ig") .. "/files/uid.txt",
                    BRAND_NAME   = "MAGOO",
                    BRAND_SUB    = "PUBLIC ACCESS",
                    SUPPORT_TEXT = "Get Key / Support : MAGOO",
                    TELEGRAM_URL = "https://t.me/THE_MAGOO",
                    DEBUG        = false,
                }
                local function getDeviceId()
                    local id = nil
                    pcall(function()
                        if Client and Client.GetPhoneDeviceID then
                            id = Client.GetPhoneDeviceID()
                        end
                    end)
                    pcall(function()
                        if not id or id == "" then
                            local ksl = import("KismetSystemLibrary")
                            if ksl then
                                if ksl.GetDeviceId then id = ksl.GetDeviceId() end
                                if (not id or id == "") and ksl.GetDeviceIdOS then
                                    id = ksl.GetDeviceIdOS()
                                end
                            end
                        end
                    end)
                    if not id or id == "" then return nil end
                    return id
                end
                local function getPlayerUid()
                    local uid = nil
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if pc then
                            if pc.UID then uid = tostring(pc.UID) end
                            if (not uid or uid == "" or uid == "0")
                               and pc.PlayerState and pc.PlayerState.UID then
                                uid = tostring(pc.PlayerState.UID)
                            end
                        end
                    end)
                    if uid == "" or uid == "0" then return nil end
                    return uid
                end
                local function getFileUid()
                    local uid = nil
                    pcall(function()
                        local f = io.open(Config.UID_FILE, "r")
                        if f then uid = f:read("*all"); f:close() end
                        if uid then uid = uid:gsub("%s+", "") end
                        if not uid or uid == "" then
                            uid = "ZN-" .. tostring(math.random(100000, 999999)) .. tostring(os.time())
                            local w = io.open(Config.UID_FILE, "w")
                            if w then w:write(uid); w:close() end
                        end
                        if uid == "" then uid = nil end
                    end)
                    return uid
                end
                local function getSerial()
                    return getDeviceId() or getPlayerUid() or getFileUid()
                end
                local function readKeyFile()
                    local key = nil
                    pcall(function()
                        local f = io.open(Config.KEY_FILE, "r")
                        if f then
                            local raw = f:read("*all") or ""
                            f:close()
                            local first = raw:match("^([^\r\n]+)") or raw
                            key = first and first:gsub("%s+", "") or nil
                            local exp = raw:match("\n([^\r\n]+)")
                            if exp and exp:gsub("%s+", "") ~= "" then
                                _G._LICENSE_EXPIRY = exp:gsub("%s+", "")
                            end
                        end
                        if key == "" then key = nil end
                    end)
                    if not _G._LICENSE_EXPIRY then
                        pcall(function()
                            local ef = io.open("//storage/emulated/0/Android/data/" .. tostring(packageName or "com.tencent.ig") .. "/files/key_expiry.txt", "r")
                            if ef then
                                local e = ef:read("*all"); ef:close()
                                if e then _G._LICENSE_EXPIRY = e:gsub("%s+", "") end
                            end
                        end)
                    end
                    return key
                end
                local function saveKey(key, expiry)
                    _G._LICENSE_KEY = key
                    if expiry and expiry ~= "" then
                        _G._LICENSE_EXPIRY = tostring(expiry)
                    end
                    pcall(function()
                        local f = io.open(Config.KEY_FILE, "w")
                        if f then
                            local line = tostring(key or "")
                            if _G._LICENSE_EXPIRY and _G._LICENSE_EXPIRY ~= "" then
                                line = line .. "\n" .. tostring(_G._LICENSE_EXPIRY)
                            end
                            f:write(line)
                            f:close()
                        end
                    end)
                    pcall(function()
                        if _G._LICENSE_EXPIRY and _G._LICENSE_EXPIRY ~= "" then
                            local ef = io.open("//storage/emulated/0/Android/data/" .. tostring(packageName or "com.tencent.ig") .. "/files/key_expiry.txt", "w")
                            if ef then ef:write(tostring(_G._LICENSE_EXPIRY)); ef:close() end
                        end
                    end)
                end
                local function getCurrentKey()
                    if _G._LICENSE_KEY and _G._LICENSE_KEY ~= "" then
                        return _G._LICENSE_KEY
                    end
                    return readKeyFile()
                end
                local function normalizeError(raw)
                    local v = tostring(raw or ""):lower()
                    if v == "invalid_key" or v == "invalid" or v == "key_not_found" then return "invalid" end
                    if v == "revoked" or v == "blocked" or v == "key_revoked" then return "blocked" end
                    if v == "expired" or v == "key_expired" then return "expired" end
                    if v == "device_limit_reached" or v == "device_limit" then return "device_limit" end
                    if v == "missing_key" or v == "missing_device_id" then return "missing" end
                    return "nonet"
                end
                local function esc(s)
                    return (tostring(s or "")
                        :gsub("\\", "\\\\")
                        :gsub('"', '\\"')
                        :gsub("\r", "\\r")
                        :gsub("\n", "\\n"))
                end
                local function checkLicense(key, uid, callback)
                    local http = nil
                    pcall(function()
                        http = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
                    end)
                    if not (http and http.Post) then
                        callback(false, "nonet", nil)
                        return
                    end
                    if not key or key == "" or not uid or uid == "" then
                        callback(false, "missing", nil)
                        return
                    end
                    local headers = {
                        ["Content-Type"] = "application/json",
                        ["Accept"]       = "application/json",
                    }
                    local body = '{"key":"' .. esc(key) .. '","device_id":"' .. esc(uid) .. '"}'
                    http:Post(Config.LOGIN_URL, headers, body, nil,
                        function(ok, response, status, err)
                            local code = tonumber(status) or 0
                            local resp = response and tostring(response) or ""
                            local errt = err and tostring(err) or ""
                            if ok then
                                if resp == "" then
                                    callback(false, "net:empty server response", nil)
                                    return
                                end
                                if resp:find('"ok"%s*:%s*true')
                                or resp:find('"valid"%s*:%s*true')
                                or resp:find('"success"%s*:%s*true') then
                                    local exp = resp:match('"expires_at"%s*:%s*"([^"]+)"')
                                             or resp:match('"expiry"%s*:%s*"([^"]+)"')
                                             or resp:match('"expires"%s*:%s*"([^"]+)"')
                                             or resp:match('"expire"%s*:%s*"([^"]+)"')
                                             or resp:match('"expire_date"%s*:%s*"([^"]+)"')
                                             or resp:match('"valid_until"%s*:%s*"([^"]+)"')
                                    local ein = resp:match('"expires_in"%s*:%s*(%d+)')
                                             or resp:match('"remaining_seconds"%s*:%s*(%d+)')
                                    local days = resp:match('"days_left"%s*:%s*(%d+)')
                                             or resp:match('"remaining_days"%s*:%s*(%d+)')
                                             or resp:match('"days"%s*:%s*(%d+)')
                                    if (not exp or exp == "") and ein then
                                        exp = tostring(os.time() + tonumber(ein))
                                    elseif (not exp or exp == "") and days then
                                        exp = tostring(os.time() + tonumber(days) * 86400)
                                    end
                                    if (not exp or exp == "") and (resp:find('"lifetime"%s*:%s*true') or resp:find("999")) then
                                        exp = "lifetime"
                                    end
                                    callback(true, nil, exp)
                                    return
                                end
                                local e = resp:match('"error"%s*:%s*"([^"]+)"')
                                       or resp:match('"code"%s*:%s*"([^"]+)"')
                                       or resp:match('"reason"%s*:%s*"([^"]+)"')
                                       or resp:match('"message"%s*:%s*"([^"]+)"')
                                callback(false, normalizeError(e), nil)
                                return
                            end
                            local msg = errt
                            if msg == "" and code > 0 then
                                msg = "HTTP " .. tostring(code)
                            end
                            callback(false, "net:" .. msg, nil)
                        end)
                end
                local function showMsg(title, body)
                    pcall(function()
                        local box = require("client.slua.logic.common.logic_common_msg_box")
                        if box and box.Show then box.Show(4, title, body) end
                    end)
                end
                local function explainError(code, expiry)
                    if code == "invalid" then
                        showMsg("INVALID KEY", "Your key is not valid.")
                    elseif code == "blocked" then
                        showMsg("KEY BLOCKED", "This key has been blocked.")
                    elseif code == "expired" then
                        local e = expiry and ("\n\nExpiry: " .. expiry) or ""
                        showMsg("KEY EXPIRED", "This key has expired." .. e)
                    elseif code == "device_limit" then
                        showMsg("DEVICE LIMIT", "This key is locked to another device.")
                    elseif code == "missing" then
                        showMsg("KEY ERROR", "Key or device ID missing.")
                    else
                        showMsg("CONNECTION ERROR", "Could not reach the license server.")
                    end
                end
                local function openTelegram()
                    pcall(function()
                        local ksl = import("KismetSystemLibrary")
                        if ksl and ksl.LaunchURL then ksl.LaunchURL(Config.TELEGRAM_URL) end
                    end)
                end
                local M = {}
            local function mkVec2(x, y)
                local ok, v = pcall(function()
                    local V = import("Vector2D")
                    if type(V) == "function" then return V(x, y) end
                    if V and V.New then return V:New(x, y) end
                    if V and V.new then return V.new(x, y) end
                    return FVector2D(x, y)
                end)
                return ok and v or FVector2D(x, y)
            end
            local function getCanvas()
                local canvas = nil
                pcall(function()
                    local ui = nil
                    pcall(function()
                        local tools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                        if tools and tools.GetMainControlBaseUI then
                            ui = tools.GetMainControlBaseUI()
                        end
                    end)
                    if not (ui and slua.isValid(ui)) then
                        pcall(function()
                            local hud = require("game_frontend_hud")
                            if hud and hud.GetMainControlBaseUI then
                                ui = hud.GetMainControlBaseUI()
                            end
                        end)
                    end
                    if not (ui and slua.isValid(ui)) then
                        pcall(function()
                            if slua_GameFrontendHUD and slua_GameFrontendHUD.GetMainControlUI then
                                ui = slua_GameFrontendHUD:GetMainControlUI()
                            end
                        end)
                    end
                    if ui and slua.isValid(ui) then
                        for _, name in ipairs({"CanvasPanel_0", "CanvasPanel_42", "CanvasPanel_Root", "CanvasPanel"}) do
                            local c = ui[name]
                            if c and slua.isValid(c) then
                                canvas = c
                                break
                            end
                        end
                    end
                end)
                return canvas
            end
            local function addText(parent, text, size, color, x, y)
                local tb = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
                if not (tb and slua.isValid(tb)) then return nil end
                pcall(function()
                    tb:SetText(tostring(text))
                    local SlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                    if SlateColor then
                        tb:SetColorAndOpacity(SlateColor(color))
                    else
                        tb:SetColorAndOpacity(color)
                    end
                    if tb.Font then
                        local f = tb.Font
                        f.Size = size
                        pcall(function() f.Typeface = "Bold" end)
                        tb.Font = f
                    end
                    tb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local slot = parent:AddChildToCanvas(tb)
                if slot then
                    pcall(function()
                        slot:SetAutoSize(true)
                        slot:SetAlignment(mkVec2(0.5, 0.5))
                        slot:SetPosition(mkVec2(x, y))
                        slot:SetZOrder(9999)
                    end)
                end
                return tb
            end
            local function addBorder(parent, color, x, y, w, h, z)
                local b = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
                if not (b and slua.isValid(b)) then return nil end
                pcall(function()
                    b:SetBrushColor(color)
                    b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local slot = parent:AddChildToCanvas(b)
                if slot then
                    pcall(function()
                        slot:SetAlignment(mkVec2(0.5, 0.5))
                        slot:SetPosition(mkVec2(x, y))
                        slot:SetSize(mkVec2(w, h))
                        slot:SetZOrder(z or 9999)
                    end)
                end
                return b
            end
            local function addButton(parent, x, y, w, h, label, r, g, b, onClick)
                local btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
                if not (btn and slua.isValid(btn)) then return nil end
                local slot = parent:AddChildToCanvas(btn)
                if slot then
                    pcall(function()
                        slot:SetAlignment(mkVec2(0.5, 0.5))
                        slot:SetPosition(mkVec2(x, y))
                        slot:SetSize(mkVec2(w, h))
                        slot:SetZOrder(9999)
                    end)
                end
                local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", btn)
                if txt and slua.isValid(txt) then
                    pcall(function()
                        txt:SetText(label)
                        local LC = import("LinearColor")
                        local SC = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                        local lin = LC(r, g, b, 1)
                        if SC then
                            txt:SetColorAndOpacity(SC(lin))
                        else
                            txt:SetColorAndOpacity(lin)
                        end
                        if txt.Font then
                            local f = txt.Font
                            f.Size = 24
                            txt.Font = f
                        end
                        txt:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
                        pcall(function() btn:AddChild(txt) end)
                    end)
                end
                pcall(function()
                    if btn.OnClicked and btn.OnClicked.Add then
                        btn.OnClicked:Add(function() onClick() end)
                    end
                end)
                return btn
            end
            local function addInput(parent, x, y, w, h)
                local box = CGame:NewObjectFromPath("/Script/UMG.EditableTextBox", parent)
                if not (box and slua.isValid(box)) then return nil end
                local slot = parent:AddChildToCanvas(box)
                if slot then
                    pcall(function()
                        slot:SetAlignment(mkVec2(0.5, 0.5))
                        slot:SetPosition(mkVec2(x, y))
                        slot:SetSize(mkVec2(w, h))
                        slot:SetZOrder(9999)
                    end)
                end
                pcall(function()
                    if box.SetHintText then box:SetHintText("Enter your key here") end
                    if box.SetKeyboardFocus then box:SetKeyboardFocus() end
                end)
                return box
            end
            local function getInputText(box)
                if not (box and slua.isValid(box) and box.GetText) then return nil end
                local txt = nil
                pcall(function()
                    local t = box:GetText()
                    if type(t) == "string" then
                        txt = t
                    elseif t and t.ToString then
                        txt = t:ToString()
                    else
                        txt = tostring(t)
                    end
                end)
                if txt == "" then return nil end
                return txt
            end
            local function setStatus(msg, isError)
                pcall(function()
                    if _G._LOGIN_STATUS and slua.isValid(_G._LOGIN_STATUS) then
                        _G._LOGIN_STATUS:SetText(tostring(msg))
                        local LC = import("LinearColor")
                        local SC = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                        local lin
                        if isError then
                            lin = LC(1.0, 0.28, 0.28, 1.0)
                        else
                            lin = LC(0.10, 0.45, 0.20, 1.0)
                        end
                        if SC then
                            _G._LOGIN_STATUS:SetColorAndOpacity(SC(lin))
                        else
                            _G._LOGIN_STATUS:SetColorAndOpacity(lin)
                        end
                    end
                end)
            end
            local function openTelegram()
                pcall(function()
                    local ksl = import("KismetSystemLibrary")
                    if ksl and ksl.LaunchURL then
                        ksl.LaunchURL(Config.TELEGRAM_URL)
                    end
                end)
            end
            local function destroyLoginUI()
                pcall(function()
                    if _G._LOGIN_UI and slua.isValid(_G._LOGIN_UI) then
                        _G._LOGIN_UI:RemoveFromParent()
                        if _G._LOGIN_UI.ConditionalBeginDestroy then
                            _G._LOGIN_UI:ConditionalBeginDestroy()
                        end
                    end
                end)
                _G._LOGIN_UI = nil
                _G._LOGIN_BOX = nil
                _G._LOGIN_BTN = nil
                _G._GETKEY_BTN = nil
                _G._LOGIN_STATUS = nil
                _G._LOGIN_TRYING = false
            end
            M.Build = function(pawn, hint, onSuccess)
                destroyLoginUI()
                local built = false
                pcall(function()
                    local canvas = getCanvas()
                    if not canvas then return end
                    local LC = import("LinearColor")
                    local SC = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                    local vw, vh = 1920, 1080
                    pcall(function()
                        local uu = require("client.common.ui_util")
                        if uu and uu.GetViewportSize then
                            local sz = uu.GetViewportSize()
                            if sz and sz.X and sz.X > 0 then
                                vw = sz.X
                                vh = sz.Y
                            end
                        end
                    end)
                    local cx, cy = vw * 0.47, vh * 0.42
                    local panelW = math.min(vw * 0.72, 640)
                    local panelH = math.min(vh * 0.62, 420)
                    panelW = math.max(panelW, 500)
                    panelH = math.max(panelH, 380)
                    local scale = math.max(0.85, math.min(panelW / 560, panelH / 400))
                    local VOID       = LC(0.01, 0.01, 0.012, 0.94)
                    local PANEL      = LC(0.025, 0.03, 0.035, 0.99)
                    local PANEL_IN   = LC(0.035, 0.04, 0.045, 1.00)
                    local EDGE       = LC(0.04, 0.14, 0.07, 0.90)
                    local GREEN      = LC(0.08, 0.42, 0.18, 1.00)
                    local GREEN_DIM  = LC(0.05, 0.22, 0.10, 1.00)
                    local GREEN_BTN  = LC(0.04, 0.28, 0.12, 1.00)
                    local WHITE      = LC(0.72, 0.74, 0.76, 1.00)
                    local WHITE_DIM  = LC(0.48, 0.50, 0.52, 1.00)
                    local GREY       = LC(0.28, 0.30, 0.32, 1.00)
                    local ERR        = LC(0.75, 0.18, 0.18, 1.00)
                    local CLEAR      = LC(0, 0, 0, 0)
                    local root = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
                    if not (root and slua.isValid(root)) then return end
                    local rootSlot = canvas:AddChildToCanvas(root)
                    if rootSlot then
                        pcall(function()
                            rootSlot:SetPosition(mkVec2(0, 0))
                            rootSlot:SetSize(mkVec2(vw, vh))
                            rootSlot:SetZOrder(9989)
                        end)
                    end
                    addBorder(root, VOID, cx, cy, vw, vh, 9989)
                    addBorder(root, EDGE, cx, cy, panelW + 2, panelH + 2, 9990)
                    addBorder(root, PANEL, cx, cy, panelW, panelH, 9991)
                    local tw, th = 18 * scale, 2 * scale
                    local hw, hh = panelW * 0.5, panelH * 0.5
                    local corners = {
                        {cx - hw + 10, cy - hh + 2}, {cx + hw - 10, cy - hh + 2},
                        {cx - hw + 10, cy + hh - 2}, {cx + hw - 10, cy + hh - 2},
                    }
                    for _, p in ipairs(corners) do
                        addBorder(root, GREEN_DIM, p[1], p[2], tw, th, 9998)
                    end
                    local ticksV = {
                        {cx - hw + 2, cy - hh + 12}, {cx + hw - 2, cy - hh + 12},
                        {cx - hw + 2, cy + hh - 12}, {cx + hw - 2, cy + hh - 12},
                    }
                    for _, p in ipairs(ticksV) do
                        addBorder(root, GREEN_DIM, p[1], p[2], th, tw, 9998)
                    end
                    addText(root, "MAGOO CORE", math.floor(11 * scale), GREY, cx, cy - panelH * 0.40)
                    addText(root, "SECURE ACCESS", math.floor(20 * scale), WHITE, cx, cy - panelH * 0.30)
                    addBorder(root, GREEN_DIM, cx, cy - panelH * 0.22, panelW * 0.22, 2 * scale, 9997)
                    local prompt = "ACCESS KEY"
                    if hint and tostring(hint):find("EXPIRED") then
                        prompt = "KEY EXPIRED — ENTER NEW KEY"
                    elseif hint and tostring(hint):find("Invalid") then
                        prompt = "INVALID KEY — TRY AGAIN"
                    elseif hint and tostring(hint):find("blocked") then
                        prompt = "KEY BLOCKED — ENTER NEW KEY"
                    end
                    addText(root, prompt, math.floor(12 * scale), GREEN, cx, cy - panelH * 0.12)
                    local inputW = panelW * 0.78
                    local inputH = 48 * scale
                    local inputY = cy + panelH * 0.02
                    addBorder(root, EDGE, cx, inputY, inputW + 2, inputH + 2, 9996)
                    addBorder(root, PANEL_IN, cx, inputY, inputW, inputH, 9997)
                    _G._LOGIN_BOX = addInput(root, cx, inputY - 28 * scale, inputW - 16 * scale, inputH - 8 * scale)
                    pcall(function()
                        if _G._LOGIN_BOX and _G._LOGIN_BOX.SetHintText then
                            _G._LOGIN_BOX:SetHintText("Enter license key")
                        end
                        if _G._LOGIN_BOX and _G._LOGIN_BOX.SetKeyboardFocus then
                            _G._LOGIN_BOX:SetKeyboardFocus()
                        end
                    end)
                    local nameY = inputY + 36 * scale
                    addBorder(root, EDGE, cx, nameY, inputW + 2, inputH + 2, 9996)
                    addBorder(root, PANEL_IN, cx, nameY, inputW, inputH, 9997)
                    _G._LOGIN_NAME_BOX = addInput(root, cx, nameY, inputW - 16 * scale, inputH - 8 * scale)
                    pcall(function()
                        if _G._LOGIN_NAME_BOX and _G._LOGIN_NAME_BOX.SetHintText then
                            _G._LOGIN_NAME_BOX:SetHintText("Enter your name (profile)")
                        end
                    end)
                    local statusSeed = "> awaiting key input_"
                    if hint and hint ~= "" and not tostring(hint):find("Enter your key") then
                        statusSeed = "> " .. tostring(hint)
                    end
                    _G._LOGIN_STATUS = addText(root, statusSeed, math.floor(12 * scale), GREEN_DIM,
                        cx, cy + panelH * 0.28)
                    local btnW = inputW * 0.48
                    local btnH = 44 * scale
                    local btnY = cy + panelH * 0.40
                    addBorder(root, EDGE, cx - inputW * 0.26, btnY, btnW + 2, btnH + 2, 9996)
                    addBorder(root, PANEL_IN, cx - inputW * 0.26, btnY, btnW, btnH, 9997)
                    addBorder(root, GREEN, cx + inputW * 0.26, btnY, btnW + 2, btnH + 2, 9996)
                    addBorder(root, GREEN_BTN, cx + inputW * 0.26, btnY, btnW, btnH, 9997)
                    local function closeWithAuthAnim(exp, key, uid, onSuccess)
                        setStatus("> AUTH OK · SESSION LIVE", false)
                        pcall(function()
                            if _G._LOGIN_STATUS and slua.isValid(_G._LOGIN_STATUS) then
                                local LC2 = import("LinearColor")
                                local SC2 = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                                local white = LC2(0.95, 0.97, 1.0, 1.0)
                                if SC2 then
                                    _G._LOGIN_STATUS:SetColorAndOpacity(SC2(white))
                                end
                            end
                        end)
                        local function finish()
                            destroyLoginUI()
                            pcall(function()
                                local body = "Your key is valid."
                                local e = exp or _G._LICENSE_EXPIRY
                                if e and e ~= "" then
                                    body = "Your key is valid.\nExpires: " .. tostring(e)
                                end
                                showMsg("KEY VERIFIED", body)
                            end)
                            pcall(function()
                                if type(_G.StartAuthenticatedRuntime) == "function" then
                                    _G.StartAuthenticatedRuntime()
                                end
                            end)
                            if onSuccess then onSuccess() end
                        end
                        -- no fade animation
                        finish()
                    end
                    local function doLogin()
                        local key = getInputText(_G._LOGIN_BOX)
                        local dispName = getInputText(_G._LOGIN_NAME_BOX)
                        if dispName and dispName ~= "" then
                            _G._MAGOO_PROFILE_NAME = tostring(dispName):sub(1, 24)
                            pcall(function()
                                local pkg = tostring(packageName or "com.tencent.ig")
                                local nf = "//storage/emulated/0/Android/data/" .. pkg .. "/files/magoo_name.txt"
                                local f = io.open(nf, "w")
                                if f then f:write(_G._MAGOO_PROFILE_NAME); f:close() end
                            end)
                        end
                        if not key or #key < 4 then
                            setStatus("> error: enter a valid key", true)
                            return
                        end
                        if _G._LOGIN_TRYING then return end
                        _G._LOGIN_TRYING = true
                        setStatus("> verifying credentials...", false)
                        local uid = getSerial()
                        checkLicense(key, uid, function(ok, err, exp)
                            _G._LOGIN_TRYING = false
                            if ok then
                                saveKey(key, exp)
                                _G._LICENSE_OK  = true
                                _G._LICENSE_KEY = key
                                _G._LICENSE_UID = uid
                                isExpired = false
                                _G._MOD_EXPIRED = false
                                if exp and exp ~= "" then _G._LICENSE_EXPIRY = tostring(exp) end
                                closeWithAuthAnim(exp, key, uid, onSuccess)
                            elseif err == "invalid" then
                                setStatus("> error: invalid key", true)
                            elseif err == "blocked" then
                                setStatus("> error: key blocked", true)
                            elseif err == "expired" then
                                setStatus("> error: key expired — enter new key", true)
                            elseif err == "device_limit" then
                                setStatus("> error: device limit reached", true)
                            elseif type(err) == "string" and err:sub(1, 4) == "net:" then
                                local detail = err:sub(5)
                                if #detail > 40 then detail = detail:sub(1, 40) .. "..." end
                                setStatus("> error: " .. detail, true)
                            else
                                setStatus("> error: connection failed — retry", true)
                            end
                        end)
                    end
                    _G._GETKEY_BTN = addButton(
                        root,
                        cx - inputW * 0.26,
                        btnY,
                        btnW,
                        btnH,
                        "GET KEY",
                        0.75, 0.90, 0.80,
                        function()
                            setStatus("> opening support channel...", false)
                            openTelegram()
                        end
                    )
                    _G._LOGIN_BTN = addButton(
                        root,
                        cx + inputW * 0.26,
                        btnY,
                        btnW,
                        btnH,
                        "AUTHENTICATE",
                        0.95, 1.00, 0.95,
                        doLogin
                    )
                    addText(root, "ENCRYPTED SESSION  ·  " .. tostring(Config.BRAND_NAME or "MAGOO"),
                        math.floor(10 * scale), GREY, cx, cy + panelH * 0.42)
                    _G._LOGIN_UI = root
                    pcall(function()
                        if root.SetRenderOpacity then root:SetRenderOpacity(1.0) end
                    end)
                    built = true
                end)
                return built
            end
            M.Start = function(pawn, onSuccess)
                if _G._LICENSE_OK == true then
                    pcall(function()
                        if type(_G.StartAuthenticatedRuntime) == "function" then
                            _G.StartAuthenticatedRuntime()
                        end
                    end)
                    if onSuccess then onSuccess() end
                    return
                end
                local function unlockWithKey(key, exp)
                    saveKey(key, exp)
                    _G._LICENSE_OK  = true
                    _G._LICENSE_KEY = key
                    _G._LICENSE_UID = getSerial()
                    isExpired = false
                    _G._MOD_EXPIRED = false
                    if exp and exp ~= "" then _G._LICENSE_EXPIRY = tostring(exp) end
                    pcall(function()
                        if type(_G.StartAuthenticatedRuntime) == "function" then
                            _G.StartAuthenticatedRuntime()
                        end
                    end)
                    if onSuccess then onSuccess() end
                end
                local function showLogin(hint)
                    local tries = 0
                    local function attempt()
                        tries = tries + 1
                        if _G._LICENSE_OK == true then
                            if onSuccess then pcall(onSuccess) end
                            return
                        end
                        if M.Build(pawn, hint or "Enter your key", onSuccess) then
                            return
                        end
                        if tries < 40 then
                            local tk = GetTicker and GetTicker() or nil
                            if not tk then
                                local ok, t = pcall(require, "common.time_ticker")
                                if ok then tk = t end
                            end
                            if tk and tk.AddTimerOnce then
                                tk.AddTimerOnce(2.0, attempt)
                            end
                        end
                    end
                    attempt()
                end
                local savedKey = getCurrentKey()
                if savedKey and savedKey ~= "" then
                    local uid = getSerial() or "unknown"
                    local answered = false
                    pcall(function()
                        local tk = GetTicker and GetTicker() or nil
                        if not tk then
                            local ok, t = pcall(require, "common.time_ticker")
                            if ok then tk = t end
                        end
                        if tk and tk.AddTimerOnce then
                            tk.AddTimerOnce(4.0, function()
                                if answered or _G._LICENSE_OK == true then return end
                                answered = true
                                unlockWithKey(savedKey, _G._LICENSE_EXPIRY)
                            end)
                        end
                    end)
                    checkLicense(savedKey, uid, function(ok, err, exp)
                        if answered or _G._LICENSE_OK == true then return end
                        answered = true
                        if ok then
                            unlockWithKey(savedKey, exp)
                            return
                        end
                        if type(err) == "string" and (err == "nonet" or err:sub(1,4) == "net:" or err == "missing") then
                            unlockWithKey(savedKey, _G._LICENSE_EXPIRY)
                            return
                        end
                        local hint = "Enter your key"
                        if err == "expired" then hint = "KEY EXPIRED - enter new key"
                        elseif err == "invalid" then hint = "Invalid key - enter a valid key"
                        elseif err == "blocked" then hint = "Key blocked - enter a new key"
                        elseif err == "device_limit" then hint = "Device limit - enter key for this device"
                        else hint = "Key check failed - enter key" end
                        showLogin(hint)
                    end)
                else
                    showLogin("Enter your key")
                end
            end
                M.StartPeriodicCheck = function(pawn)
                if _G._LOGIN_TIMER then return _G._LOGIN_TIMER end
                local timer = nil
                pcall(function()
                    local function tick()
                        if not slua.isValid(pawn.Object) then return end
                        if not _G._LICENSE_OK then return end
                        local key = getCurrentKey()
                        local uid = _G._LICENSE_UID or getSerial()
                        if not (key and uid) then return end
                        checkLicense(key, uid, function(ok, err)
                            if ok then return end
                            if err == "nonet" or (type(err) == "string" and err:sub(1,4) == "net:") then
                                return
                            end
                            _G._LICENSE_OK = false
                            pcall(function()
                                if _G.LoginSystem_OnRevoked then
                                    _G.LoginSystem_OnRevoked(err)
                                end
                            end)
                            local title = "LICENSE REVOKED"
                            local hint = "License revoked - re-enter key"
                            if err == "expired" then
                                title = "KEY EXPIRED"
                                hint = "KEY EXPIRED - enter new key"
                            elseif err == "invalid" then
                                title = "INVALID KEY"
                                hint = "Invalid key - enter a valid key"
                            end
                            showMsg(title, "Your key is no longer valid.")
                            pcall(function()
                                if M.Build then
                                    M.Build(pawn, hint, nil)
                                end
                            end)
                        end)
                    end
                    timer = pawn:AddGameTimer(180, true, tick)
                end)
                _G._LOGIN_TIMER = timer
                _G._LOGIN_CHAR  = pawn
                return timer
            end
                M.CheckLicense  = checkLicense
                M.GetSerial     = getSerial
                M.GetCurrentKey = getCurrentKey
                M.SaveKey       = saveKey
                M.Config        = Config
                M.IsLoggedIn    = function() return _G._LICENSE_OK == true end
                return M
            end)()
            _G.LoginSystem = LoginSystem
            -- skin system removed: hard-disable residual hooks
            _G.LexusConfig = _G.LexusConfig or {}
            _G.LexusConfig.ModSkin = false
            _G.LexusConfig.SkinDeadBox = false
            _G.LexusConfig.KillMessage = _G.LexusConfig.KillMessage or false
            _G.LexusConfig.KillCountUI = _G.LexusConfig.KillCountUI or false
            if _G.GTLMODConfig then
                _G.GTLMODConfig.ModSkin = false
                _G.GTLMODConfig.SkinDeadBox = false
                _G.GTLMODConfig.SkinPet = false
                _G.GTLMODConfig.SkinXSuit = false
            end

            function _G.LoginSystem_OnRevoked(errCode)
                _G._LICENSE_OK  = false
                _G._MOD_EXPIRED = true
                isExpired = true
                _G._MAGOO_RUNTIME_STARTED = false
                pcall(function()
                    if _G._LOGIN_TIMER and _G._LOGIN_CHAR and slua.isValid(_G._LOGIN_CHAR) and _G._LOGIN_CHAR.RemoveGameTimer then
                        _G._LOGIN_CHAR:RemoveGameTimer(_G._LOGIN_TIMER)
                    end
                end)
                _G._LOGIN_TIMER = nil
                _G._LOGIN_CHAR = nil
                pcall(function()
                    if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then
                        _G.PlayerMapMarker.Stop()
                    end
                end)
                pcall(function() if _G.StopEnemyCounter then _G.StopEnemyCounter() end end)
                pcall(function() if _G._GK_FeedbackStarted then _G._GK_FeedbackStarted = false end end)
            end
            local function ShowMagooVerifiedPopup()
                if _G._MAGOO_VERIFIED_SHOWN then return end
                _G._MAGOO_VERIFIED_SHOWN = true
                pcall(function()
                    local Msg = require("client.slua.logic.common.logic_common_msg_box")
                    if not Msg or not Msg.Show then return end
                    local body = table.concat({
                        "",
                        "══════════════════════════════════════",
                        "     KEY VERIFIED — ACCESS GRANTED",
                        "══════════════════════════════════════",
                        "",
                        "  Everything is ready. Play safely.",
                        "  Follow the rules at all times.",
                        "",
                        "  Original owner :  @THE_MAGOO",
                        "",
                        "  Stay natural. Stay undetected.",
                        "  Enjoy the game.",
                        "",
                        "══════════════════════════════════════",
                        "",
                    }, "\n")
                    Msg.Show(4, "MAGOO CORE — VERIFIED", body, function() end, nil, "  PLAY  ")
                end)
            end
            local function ShowRulesOnce(onDone)
                if onDone then pcall(onDone) end
                local function afterRules()
                    pcall(ShowMagooVerifiedPopup)
                end
                if _G._MAGOO_RULES_SHOWN then
                    afterRules()
                    return
                end
                local rulesAckPath = PATHS and PATHS.PubgData and (PATHS.PubgData .. "magoo_rules_ack.txt")
                    or ("//storage/emulated/0/Android/data/" .. tostring(packageName or "com.tencent.ig") .. "/files/magoo_rules_ack.txt")
                local alreadyAcked = false
                pcall(function()
                    local f = io.open(rulesAckPath, "r")
                    if f then
                        local v = f:read("*a") or ""
                        f:close()
                        alreadyAcked = v:match("^%s*1%s*$") ~= nil
                    end
                end)
                if alreadyAcked then
                    _G._MAGOO_RULES_SHOWN = true
                    afterRules()
                    return
                end
                pcall(function()
                    local Msg = require("client.slua.logic.common.logic_common_msg_box")
                    if not Msg or not Msg.Show then
                        _G._MAGOO_RULES_SHOWN = true
                        afterRules()
                        return
                    end
                    local body = table.concat({
                        "",
                        "════════════════════════════════════════════",
                        "          MAGOO CORE — RULES",
                        "════════════════════════════════════════════",
                        "",
                        "  READ CAREFULLY BEFORE YOU PLAY",
                        "",
                        "────────────────────────────────────────────",
                        "  PLAY STYLE",
                        "────────────────────────────────────────────",
                        "",
                        "  • Play SOLO vs SQUAD when possible.",
                        "  • Use LESS skills — do not over-aim.",
                        "  • Play NATURALLY, like a real pro.",
                        "  • Do NOT play like a hacker.",
                        "  • Hide your statistics when you can.",
                        "  • Avoid obvious tracking / snapping.",
                        "  • Take fights fair. Rotate smart.",
                        "",
                        "────────────────────────────────────────────",
                        "  ACCOUNT & SAFETY",
                        "────────────────────────────────────────────",
                        "",
                        "  • Do not share your license key.",
                        "  • Keep device / account info private.",
                        "  • If key expires or is revoked, re-login.",
                        "",
                        "────────────────────────────────────────────",
                        "  VERSION SAFETY",
                        "────────────────────────────────────────────",
                        "",
                        "  • ALL VERSIONS SAFE",
                        "  • GLOBAL SAFE",
                        "  • BGMI SAFE",
                        "  • KR / VN / TW SAFE",
                        "",
                        "════════════════════════════════════════════",
                        "  By continuing you accept these rules.",
                        "  Original owner : @THE_MAGOO",
                        "════════════════════════════════════════════",
                        "",
                        "",
                        "",
                    }, "\n")
                    Msg.Show(4, "MAGOO CORE — RULES & SAFETY", body, function()
                        _G._MAGOO_RULES_SHOWN = true
                        pcall(function()
                            local f = io.open(rulesAckPath, "w")
                            if f then f:write("1\n"); f:close() end
                        end)
                        afterRules()
                    end, nil, "  I UNDERSTAND  ")
                end)
            end
            _G.ShowRulesOnce = ShowRulesOnce
            _G.ShowMagooVerifiedPopup = ShowMagooVerifiedPopup
            local HackerWeaponFeatures = (function()
            local Weapon = {}
            Weapon.__index = Weapon
            local FIELDS = { 'RecoilKickADS', 'GameDeviationFactor', 'GameDeviationAccuracy' }
            local VALUE, INTERVAL = .01, .2
            local FIREARMS = {
                m416=true,akm=true,['scar-l']=true,m762=true,aug=true,groza=true,
                qbz=true,mk47=true,g36c=true,['honey badger']=true,famas=true,['asm abakan']=true,
                ace32=true,uzi=true,ump45=true,vector=true,thompson=true,['thompson smg']=true,
                bizon=true,['pp-19 bizon']=true,['pp-19']=true,mp5k=true,p90=true,
                kar98=true,kar98k=true,m24=true,awm=true,sks=true,vss=true,slr=true,mini14=true,
                mk14=true,amr=true,mk12=true,dsr=true,['m1 garand']=true,s686=true,s1897=true,
                s12k=true,dbs=true,ns2000=true,m249=true,dp28=true,['dp-28']=true,mg3=true
            }
            local function wfinite(v) return type(v)=='number' and v==v and v>-math.huge and v<math.huge end
            local function wsame(a,b) return wfinite(a) and wfinite(b) and math.abs(a-b)<.000001 end
            local function wread(o,k) if o==nil then return nil end local ok,v=pcall(function() return o[k] end) if ok then return v end end
            local function wcall(o,k,...) local fn=wread(o,k) if type(fn)~='function' then return nil end local ok,v=pcall(fn,o,...) if ok then return v end end
            function Weapon.new(env)
                return setmetatable({env=env or _G,enabled=false,active=false,disposed=false,
                    nextCheck=0,lastTime=nil,pawn=nil,weapon=nil,entry=nil,blockedEntity=nil,
                    restoring=false,smallCrosshairAvailable=nil,lastStatus='inactive'},Weapon)
            end
            function Weapon:_valid(o)
                if o==nil then return false end
                local fn=wread(wread(self.env,'slua'),'isValid')
                if type(fn)=='function' then local ok,v=pcall(fn,o) if ok and v==true then return true end end
                return wcall(wread(self.env,'Game'),'IsValid',o)==true
            end
            function Weapon:_currentWeapon(pawn)
                for _,key in ipairs({'GetCurrentWeapon','GetCurrentShootWeapon'}) do
                    local fn=wread(pawn,key)
                    if type(fn)=='function' then local ok,cur=pcall(fn,pawn) if ok then if self:_valid(cur) then return cur end end end
                end
                local mgr=wread(pawn,'WeaponManagerComponent')
                if self:_valid(mgr) then
                    local cur=wread(mgr,'CurrentWeapon') if self:_valid(cur) then return cur end
                    local rep=wread(mgr,'CurrentWeaponReplicated') if self:_valid(rep) then return rep end
                end
            end
            function Weapon:_firearm(weapon)
                local name=wcall(weapon,'GetWeaponName')
                if type(name)~='string' then return false end
                return FIREARMS[name:lower():match('^%s*(.-)%s*$')]==true
            end
            function Weapon:_ownedCount()
                local count=0
                if self.entry then for i=1,3 do if self.entry.owned[FIELDS[i]] then count=count+1 end end end
                return count
            end
            function Weapon:_restore()
                local entry=self.entry self.active=false
                if not entry then self.restoring=false return true end
                if not self:_valid(entry.entity) then self.entry=nil self.restoring=false return true end
                for i=1,3 do
                    local key=FIELDS[i]
                    if entry.owned[key] then
                        local value=wread(entry.entity,key)
                        if wsame(value,VALUE) then
                            pcall(function() entry.entity[key]=entry.original[key] end)
                            if wsame(wread(entry.entity,key),entry.original[key]) then entry.owned[key]=nil end
                        elseif wfinite(value) then entry.owned[key]=nil end
                    end
                end
                if self:_ownedCount()==0 then self.entry=nil self.restoring=false return true end
                self.restoring=true return false
            end
            function Weapon:_stop(reason)
                local restored=self:_restore()
                self.lastStatus=restored and reason or 'restore_pending' return false
            end
            function Weapon:_block(entity,reason)
                self.blockedEntity,self.blockedReason=entity,reason
                self.smallCrosshairAvailable=false return self:_stop(reason)
            end
            function Weapon:_isCurrent(pawn,weapon,entity,settings)
                return settings.smallCrosshair==true and self:_valid(pawn) and self:_valid(weapon)
                    and self:_valid(entity) and self:_currentWeapon(pawn)==weapon
                    and wread(weapon,'ShootWeaponEntityComp')==entity and self:_firearm(weapon)
            end
            function Weapon:_apply(pawn,weapon,entity,settings)
                local entry={entity=entity,original={},owned={}}
                for i=1,3 do
                    local key=FIELDS[i] local value=wread(entity,key)
                    if not wfinite(value) then self.smallCrosshairAvailable=false self.lastStatus='source_field_unavailable' return false end
                    entry.original[key]=value
                end
                self.entry=entry
                for i=1,3 do
                    local key=FIELDS[i]
                    if not self:_isCurrent(pawn,weapon,entity,settings) then self.smallCrosshairAvailable=false return self:_stop('context_changed') end
                    if not wsame(wread(entity,key),entry.original[key]) then return self:_block(entity,'external_value_changed') end
                    if not wsame(entry.original[key],VALUE) then
                        entry.owned[key]=true
                        local ok=pcall(function() entity[key]=VALUE end)
                        if not ok or not wsame(wread(entity,key),VALUE) then return self:_block(entity,'source_write_failed') end
                    end
                end
                for i=1,3 do if not wsame(wread(entity,FIELDS[i]),VALUE) then return self:_block(entity,'external_value_changed') end end
                if not self:_isCurrent(pawn,weapon,entity,settings) then self.smallCrosshairAvailable=false return self:_stop('context_changed') end
                self.active=true self.smallCrosshairAvailable=true self.lastStatus='source_values_verified' return true
            end
            function Weapon:update(pawn,settings,now)
                if self.disposed then return false end
                settings=type(settings)=='table' and settings or {}
                if settings.smallCrosshair~=true then
                    self.enabled=false self.blockedEntity=nil self.lastTime=nil self.nextCheck=0 self.pawn,self.weapon=nil,nil
                    return self:_stop('inactive')
                end
                if not wfinite(now) or now<0 then self.lastTime=nil self.nextCheck=0 self.weapon=nil return self:_stop('clock_unavailable') end
                if self.lastTime and now<self.lastTime then self.lastTime=now self.nextCheck=0 self.weapon=nil self.blockedEntity=nil return self:_stop('clock_changed') end
                self.lastTime=now
                if pawn~=self.pawn then
                    self.pawn=pawn self.weapon=nil self.blockedEntity=nil self.nextCheck=0
                    if not self:_restore() then self.nextCheck=now+INTERVAL self.lastStatus='restore_pending' return false end
                end
                if self.enabled and now<self.nextCheck then return self.active end
                self.enabled=true self.nextCheck=now+INTERVAL
                if not self:_valid(pawn) then self.weapon=nil return self:_stop('player_unavailable') end
                local weapon=self:_currentWeapon(pawn)
                if not self:_valid(weapon) or not self:_firearm(weapon) then
                    self.weapon=nil self.smallCrosshairAvailable=false return self:_stop('firearm_unavailable')
                end
                local entity=wread(weapon,'ShootWeaponEntityComp')
                if not self:_valid(entity) then self.weapon=nil self.smallCrosshairAvailable=false return self:_stop('shoot_entity_unavailable') end
                if weapon~=self.weapon then self.blockedEntity=nil end
                if self.restoring or (self.entry and self.entry.entity~=entity) then
                    if not self:_restore() then self.lastStatus='restore_pending' return false end
                end
                self.weapon=weapon
                if self.blockedEntity==entity then self.active=false self.lastStatus=self.blockedReason return false end
                if self.entry then
                    for i=1,3 do
                        local value=wread(entity,FIELDS[i])
                        if not wsame(value,VALUE) then return self:_block(entity,wfinite(value) and 'external_value_changed' or 'source_field_unavailable') end
                    end
                    self.active=true self.smallCrosshairAvailable=true self.lastStatus='source_values_verified' return true
                end
                return self:_apply(pawn,weapon,entity,settings)
            end
            function Weapon:dispose()
                self.disposed=true self.enabled=false self.blockedEntity=nil self.pawn,self.weapon,self.lastTime=nil,nil,nil
                return self:_stop('disposed')
            end
            return Weapon
            end)()
            _G.PrivWeaponInstance = nil
            _G.PrivAimInstance   = nil
            local _slua = rawget(_G, "slua")
            local function Valid(obj)
                if not obj then return false end
                if _slua and _slua.isValid then
                    local ok, v = pcall(_slua.isValid, obj)
                    if not ok or not v then return false end
                end
                return true
            end
            local _cached_FV2 = nil
            local _cached_KML = nil
            local _cached_UGS = nil
            local _cached_ui_util = nil
            local function GetFV2()     if not _cached_FV2     then _cached_FV2     = safeImport("Vector2D")          end; return _cached_FV2     end
            local function GetKML()     if not _cached_KML     then _cached_KML     = safeImport("KismetMathLibrary")  end; return _cached_KML     end
            local function GetUGS()     if not _cached_UGS     then _cached_UGS     = safeImport("GameplayStatics")    end; return _cached_UGS     end
            local function GetUIUtil()
                if not _cached_ui_util then
                    local ok, m = pcall(require, "client.common.ui_util")
                    if ok and m then _cached_ui_util = m end
                end
                return _cached_ui_util
            end
            local function HumanAimDelta(dx, dy, fraction)
                -- pure fraction scaling; no additive jitter (smoothness slider owns the curve)
                return dx * fraction, dy * fraction
            end
            local function PrivAimbotTick()
                local cfg = _G.GTLMODConfig or {}
                local hipOn = cfg.ForceAimbot == true or cfg.ForceAimbot == 1 or cfg.ForceAimbot == "true"
                    or _G._ForceAimbotWanted == true
                if not hipOn then return end
                local player = nil
                pcall(function() player = GameplayData.GetPlayerCharacter() end)
                if not (player and slua.isValid(player)) then return end
                local pc = nil
                pcall(function() pc = player:GetPlayerControllerSafety() end)
                if not (pc and slua.isValid(pc)) then return end
                local isFiring = false
                pcall(function()
                    isFiring = player.bIsWeaponFiring == true
                    if not isFiring then
                        local wepMgr = player.WeaponManagerComponent
                        if slua.isValid(wepMgr) then isFiring = wepMgr.bIsWeaponFiring == true end
                    end
                end)
                if not isFiring then return end
                local weapon = nil
                pcall(function()
                    local mgr = player.WeaponManagerComponent
                    if mgr and slua.isValid(mgr) then weapon = mgr.CurrentWeaponReplicated or mgr.CurrentWeapon end
                    if not (weapon and slua.isValid(weapon)) then
                        if type(player.GetCurrentShootWeapon) == 'function' then weapon = player:GetCurrentShootWeapon() end
                    end
                    if not (weapon and slua.isValid(weapon)) then
                        if type(player.GetCurrentWeapon) == 'function' then weapon = player:GetCurrentWeapon() end
                    end
                end)
                if not (weapon and slua.isValid(weapon)) then return end
                local myTeam = -1
                pcall(function() myTeam = player:GetTeamID() or player.TeamID or -1 end)
                local allChars = {}
                local seen = {}
                local function addChar(c)
                    if not c or not slua.isValid(c) then return end
                    local id = tostring(c)
                    if seen[id] then return end
                    seen[id] = true
                    allChars[#allChars + 1] = c
                end
                pcall(function()
                    if GameplayData and GameplayData.GetAllPlayerCharacters then
                        local list = GameplayData.GetAllPlayerCharacters()
                        if list then
                            for _, c in pairs(list) do addChar(c) end
                        end
                    end
                end)
                pcall(function()
                    if GameplayData and GameplayData.GameCharacters then
                        for _, c in pairs(GameplayData.GameCharacters) do addChar(c) end
                    end
                end)
                pcall(function()
                    if Game and Game.GetAllPlayerPawns then
                        local list = Game:GetAllPlayerPawns()
                        if list then
                            for _, c in pairs(list) do addChar(c) end
                        end
                    end
                end)
                pcall(function()
                    if _G.Game and _G.Game.GetAllPlayerPawns then
                        local list = _G.Game:GetAllPlayerPawns()
                        if list then
                            for _, c in pairs(list) do addChar(c) end
                        end
                    end
                end)
                local KismetMathLibrary = GetKML()
                local UGameplayStatics = GetUGS()
                if not KismetMathLibrary or not UGameplayStatics then return end
                local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
                if not (camManager and slua.isValid(camManager)) then return end
                local camLoc = camManager:GetCameraLocation()
                if not camLoc then return end
                local ui_util = GetUIUtil and GetUIUtil()
                if not ui_util then
                    pcall(function() ui_util = require("client.common.ui_util") end)
                end
                if not ui_util then return end
                local viewportSize = ui_util.GetViewportSize()
                if not viewportSize then return end
                local centerX = viewportSize.X * 0.5
                local centerY = viewportSize.Y * 0.5
                local FOV_RADIUS = 0.42 * (viewportSize.X / 2.0)
                local boneMap = {
                    [1] = "head",
                    [2] = "spine_02",
                    [3] = "spine_01",
                    [4] = "pelvis",
                }
                local boneIdx = tonumber(cfg.AimbotBone) or 1
                if boneIdx < 1 then boneIdx = 1 end
                if boneIdx > 4 then boneIdx = 4 end
                local TARGET_BONE = boneMap[boneIdx] or "spine_02"
                local isADS = false
                pcall(function()
                    if player.bIsGunADS or player.bIsADS or player.bInADS then isADS = true end
                    if type(player.IsGunADS) == "function" and player:IsGunADS() then isADS = true end
                    if type(player.GetIsADS) == "function" and player:GetIsADS() then isADS = true end
                end)
                -- keep selected bone in both hip and ADS; do not override to chest
                local bestTarget = nil
                local bestScore  = 99999999
                local now = os.clock()
                _G.PrivAimVisCache = _G.PrivAimVisCache or {}
                _G.PrivAimBotCache = _G.PrivAimBotCache or {}
                _G._PrivAimCacheLastFlush = _G._PrivAimCacheLastFlush or 0
                local _cacheNow = os.clock()
                if _cacheNow - _G._PrivAimCacheLastFlush > 30.0 then
                    _G.PrivAimVisCache = {}
                    _G.PrivAimBotCache = {}
                    _G._PrivAimCacheLastFlush = _cacheNow
                end
                local maxAimScan = (LIMITS and LIMITS.MAX_ENEMY_MARKS) or 40
                if maxAimScan > 20 then maxAimScan = 20 end
                local scanned = 0
                for _, actor in pairs(allChars) do
                    scanned = scanned + 1
                    if scanned > maxAimScan then break end
                    if slua.isValid(actor) and actor ~= player then
                        local alive = true
                        pcall(function()
                            if type(actor.IsAlive) == 'function' then alive = actor:IsAlive()
                            elseif actor.HealthStatus ~= nil then alive = (actor.HealthStatus ~= 2)
                            elseif actor.bIsDead ~= nil then alive = not actor.bIsDead end
                        end)
                        if not alive then goto priv_continue end
                        local teamId = -2
                        pcall(function()
                            if type(actor.GetTeamID) == 'function' then teamId = actor:GetTeamID()
                            elseif actor.TeamID ~= nil then teamId = actor.TeamID end
                        end)
                        if teamId == myTeam then goto priv_continue end
                        if cfg.AimTouchIgKnock == true then
                            local knocked = false
                            pcall(function()
                                if actor.HealthStatus == 1 then knocked = true end
                                if actor.bIsNearDeath or actor.NearDeath then knocked = true end
                            end)
                            if knocked then goto priv_continue end
                        end
                        local actorKey = type(actor.GetUniqueID)=='function' and tostring(actor:GetUniqueID()) or tostring(actor)
                        local isBot = _G.PrivAimBotCache[actorKey]
                        if isBot == nil then
                            isBot = false
                            pcall(function()
                                if actor.bIsAI==true or actor.IsAI==true or actor.bIsAIActor==true then isBot=true end
                                if not isBot then
                                    local ps = actor.PlayerState
                                    if slua.isValid(ps) and (ps.bIsABot==true or ps.bIsBot==true or ps.bIsAI==true) then isBot=true end
                                end
                                if not isBot and type(actor.IsBot)=='function' then
                                    local ok,r = pcall(actor.IsBot, actor) if ok and r then isBot=true end
                                end
                            end)
                            _G.PrivAimBotCache[actorKey] = isBot
                        end
                        if cfg.AimTouchIgBot == true and isBot then goto priv_continue end
                        local vcache = _G.PrivAimVisCache[actorKey]
                        if not vcache or (now - vcache.t) > 0.22 then
                            local hidden = false
                            local losOk = false
                            pcall(function()
                                if type(pc.LineOfSightTo) == "function" then
                                    hidden = not pc:LineOfSightTo(actor)
                                    losOk = true
                                end
                            end)
                            if not losOk then hidden = false end
                            _G.PrivAimVisCache[actorKey] = { hidden = hidden, t = now }
                            vcache = _G.PrivAimVisCache[actorKey]
                        end
                        if cfg.AimTouchVisCheck == true and vcache and vcache.hidden then goto priv_continue end
                        local tPos = nil
                        pcall(function()
                            local mesh = actor.Mesh
                            if slua.isValid(mesh) and type(mesh.GetSocketLocation)=='function' then
                                tPos = mesh:GetSocketLocation(TARGET_BONE)
                                if tPos and tPos.X==0 and tPos.Y==0 and tPos.Z==0 then tPos=nil end
                            end
                            if not tPos and type(actor.GetBonePos)=='function' then
                                tPos = actor:GetBonePos(TARGET_BONE, {X=0,Y=0,Z=0})
                                if tPos and tPos.X==0 and tPos.Y==0 and tPos.Z==0 then tPos=nil end
                            end
                            if not tPos then
                                local loc = actor:K2_GetActorLocation()
                                if loc then tPos = {X=loc.X, Y=loc.Y, Z=loc.Z+45} end
                            end
                        end)
                        if not tPos then goto priv_continue end
                        local FV2 = GetFV2()
                        local screen = FV2 and FV2(0,0) or {X=0,Y=0}
                        local onScreen = false
                        pcall(function() onScreen = pc:ProjectWorldLocationToScreen(tPos, screen, false) end)
                        if not onScreen then goto priv_continue end
                        local dx = screen.X - centerX
                        local dy = screen.Y - centerY
                        local dist2 = dx*dx + dy*dy
                        if dist2 <= FOV_RADIUS*FOV_RADIUS and dist2 < bestScore then
                            bestScore  = dist2
                            bestTarget = actor
                        end
                        ::priv_continue::
                    end
                end
                if not (bestTarget and slua.isValid(bestTarget)) then return end
                local finalPos = nil
                pcall(function()
                    local mesh = bestTarget.Mesh
                    if slua.isValid(mesh) and type(mesh.GetSocketLocation)=='function' then
                        finalPos = mesh:GetSocketLocation(TARGET_BONE)
                        if finalPos and finalPos.X==0 and finalPos.Y==0 and finalPos.Z==0 then finalPos=nil end
                    end
                    if not finalPos and type(bestTarget.GetBonePos)=='function' then
                        finalPos = bestTarget:GetBonePos(TARGET_BONE, {X=0,Y=0,Z=0})
                        if finalPos and finalPos.X==0 and finalPos.Y==0 and finalPos.Z==0 then finalPos=nil end
                    end
                    if not finalPos then
                        local loc = bestTarget:K2_GetActorLocation()
                        if loc then finalPos={X=loc.X,Y=loc.Y,Z=loc.Z+32} end
                    end
                end)
                if not finalPos then return end
                local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalPos)
                if not rot then return end
                local currentRot = pc:GetControlRotation()
                if not currentRot then return end
                local deltaYaw   = rot.Yaw   - currentRot.Yaw
                local deltaPitch = rot.Pitch - currentRot.Pitch
                if deltaYaw   >  180 then deltaYaw   = deltaYaw   - 360 end
                if deltaYaw   < -180 then deltaYaw   = deltaYaw   + 360 end
                if deltaPitch >  180 then deltaPitch = deltaPitch - 360 end
                if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
                local _smoothVal = tonumber(_G.GTLMODConfig.AimbotSmoothness) or 25
                if _smoothVal < 1 then _smoothVal = 1 end
                if _smoothVal > 100 then _smoothVal = 100 end
                -- restore strong lock: low smoothness = near-instant, high = gentle
                -- default 25 is close and responsive like original
                local fraction = 1.0 - (_smoothVal / 120.0)
                if fraction < 0.35 then fraction = 0.35 end
                if fraction > 0.95 then fraction = 0.95 end
                local humanDY, humanDP = HumanAimDelta(deltaYaw, deltaPitch, fraction)
                local adsBias = 0
                pcall(function()
                    local ads = false
                    if player.bIsGunADS or player.bIsADS or player.bInADS then ads = true end
                    if type(player.IsGunADS) == "function" and player:IsGunADS() then ads = true end
                    if ads then adsBias = -0.12 end
                end)
                local finalRot = {
                    Pitch = currentRot.Pitch + humanDP + adsBias,
                    Yaw   = currentRot.Yaw   + humanDY,
                    Roll  = 0
                }
                pcall(function()
                    local ok = pcall(function() pc:SetControlRotation(finalRot, "CircleAim") end)
                    if not ok then pcall(function() pc:SetControlRotation(finalRot) end) end
                end)
            end
            local C_GREEN = {R=0, G=255, B=0, A=255}
            local C_RED = {R=255, G=0, B=0, A=255}
            local C_CYAN = {R=0, G=255, B=255, A=255}
            local C_YELLOW = {R=255, G=255, B=0, A=255}
            local C_WHITE = {R=255, G=255, B=255, A=255}
            local C_BLUE = {R=0, G=0, B=255, A=255}
            _G.GTLMODConfig = _G.GTLMODConfig or {
                AutoHead = false,
                EspVip = false,
                EspDistance = false,
                EspVipPro = false,
                EspRadar = false,
                Esp5 = false,
                Esp6 = false,
                Esp7 = false,
                Esp8 = false,
                EspAntenna = false,
                EspName = false,
                EspOutline = false,
                OutlineThickness = 10,
                UnlockFPS = false,
                TargetFPS = 165,
                FPSStabilizer = false,
                PotatoGraphics = false,
                CleaningSpace = false,
                IpadView = false,
                CustomAimbot = false,
                CustomAimbotClose = false,
                CustomHRecoil = false,
                CustomVRecoil = false,
                LessShake = false,
                RemoveGrass = false,
                RemoveFog = false,
                WhiteBody = false,
                ColorBodyV2 = false,
                Crosshair = false,
                Accuracy = false,
                GodMode = false,
                AimTouchEnable = false,
                AimTouchIgKnock = false,
                AimTouchIgBot = false,
                AimTouchVisCheck = false, -- user toggle; LOS used when true
                ForceAimbot = false,
                AimbotBone = 1,
                AimbotSmoothness = 25,
                BlackSky = false,
                EspLoot = false,
                LootShowM416 = false, LootShowAUG = false, LootShowAKM = false, LootShowM24 = false,
                LootShowUMP = false, LootShowDBS = false, LootShowS12K = false,
                LootShowVest3 = false, LootShowHelmet3 = false, LootShowBag3 = false,
                LootColor_M416 = 4, LootColor_AUG = 4, LootColor_AKM = 4, LootColor_M24 = 4,
                LootColor_UMP = 4, LootColor_DBS = 4, LootColor_S12K = 4,
                LootColor_Vest3 = 4, LootColor_Helmet3 = 4, LootColor_Bag3 = 4,
                VehicleEnabled = false,
                VehicleShowDacia = true, VehicleShowUAZ = true, VehicleShowBuggy = true,
                VehicleShowCoupe = true, VehicleShowMirado = true, VehicleShowMotorcycle = true,
                VehicleShowOther = true,
                -- skins removed
                SkinSuit = 1,
                SkinBag = 1,
                SkinHelmet = 1,
                SkinGloves = 0,
                SkinGlider = 0,
                SkinParachute = 0,
                PrivSmallCrosshair = false, ForceAimbotScope = false,
                CounterEnabled = false,
                EspLine = false,
                AimDebug = false,
                WallhackSmart = false,
                EspLineThickness = 2,
                EspItem_Master = false,
                EspItem_AR = true,
                EspItem_Sniper = true,
                EspItem_SMG = true,
                EspItem_Shotgun = true,
                EspItem_LMG = true,
                EspItem_Pistol = true,
                EspItem_Scope = true,
                EspItem_Special = false,
                EspItem_Grenade = true,
                EspItem_Med = true,
                EspItem_Melee = false,
                EspModelName = false,
                EspShowDistance = false,
                EspShowHealthBar = false,
                EspTeamColorBox = false,
                EspWeaponIcon = false,
                EspActiveBom = false,
                ForceAimbotScope = false,
                LagFreeMode = false,
                WallhackThickness = 2.5,
                ColorEnemyWHVis = 3,
                ColorEnemyWHOcc = 0,
                ColorBotWHVis   = 2,
                ColorBotWHOcc   = 6,
                GlowIntensity   = 60,
            }
            _G.GTLMODState = _G.GTLMODState or {
                LoopToken = 0,
                NativeESPReady = false,
                GraphicsUnlocked = false,
                MenuStep = 0,
                TrackedMarks = {},
                EnemyMarks = {},
                CustomTextData = nil,
                PrevGraphicsState = {},
                MidCacheCount = 0,
                AimLastFail = "",
            }
            local function GetConfigPaths(fileName)
                return {
                    PATHS.DataCache .. fileName,
                    PATHS.Cache .. fileName,
                    PATHS.Paks .. "MAGOO/" .. fileName,
                    "ShadowTrackerExtra/Saved/Paks/MAGOO/" .. fileName,
                    "../../ShadowTrackerExtra/Saved/Paks/MAGOO/" .. fileName,
                    PATHS.SaveGames .. fileName,
                    PATHS.Paks .. fileName,
                    fileName
                }
            end
            local ConfigFileName = "RJ_settings.txt"
            _G.LastConfigSaveStr = ""
            _G.LastConfigSaveTime = 0
            _G.SaveModSettings = function()
                local now = os.time()
                if now - (_G.LastConfigSaveTime or 0) < LIMITS.CONFIG_SAVE_INTERVAL then return end
                _G.LastConfigSaveTime = now
                pcall(function()
                    local buf = { "return {\nGTLConfig = {\n" }
                    for k, v in pairs(_G.GTLMODConfig or {}) do
                        buf[#buf+1] = "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
                    end
                    buf[#buf+1] = "}\n}"
                    local data = table.concat(buf)
                    if data == _G.LastConfigSaveStr then return end
                    _G.LastConfigSaveStr = data
                    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
                        local file = io.open(path, "w")
                        if file then file:write(data); file:close(); break end
                    end
                end)
            end
            _G.LoadModSettings = function()
                local loaded = false
                pcall(function()
                    local content = nil
                    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
                        local file = io.open(path, "r")
                        if file then content = file:read("*a"); file:close(); break end
                    end
                    if content and content ~= "" then
                        local func = load(content)
                        if func then
                            local savedData = func()
                            if savedData and type(savedData) == "table" and savedData.GTLConfig then
                                for k, v in pairs(savedData.GTLConfig) do
                                    _G.GTLMODConfig[k] = v
                                end
                                loaded = true
                            end
                        end
                    end
                    _G.SaveModSettings()
                end)
                return loaded
            end
            local function AutoSaveLoop()
                pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
                pcall(function()
                    local ticker = GetTicker()
                    if ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(LIMITS.CONFIG_SAVE_INTERVAL, AutoSaveLoop)
                    end
                end)
            end
            if not _G.ModConfigLoaded then
                local hadSaved = _G.LoadModSettings()
                if not hadSaved then
                    local c = _G.GTLMODConfig
                    if c then
                        c.WallhackSmart      = false
                        c.Crosshair          = false
                        c.AimTouchEnable     = false
                        c.ForceAimbot        = false
                        c.PrivSmallCrosshair = false
                        c.EspVip             = false
                        c.EspVipPro          = false
                        c.EspRadar           = false
                        c.EspBox             = false
                        c.Esp5               = false
                        c.Esp6               = false
                        c.Esp7               = false
                        c.Esp8               = false
                        c.EspAntenna         = false
                        c.EspName            = false
                        c.EspDistance        = false
                        c.AutoHead           = false
                        c.UnlockFPS          = false
                        c.TargetFPS = 165
                        c.FPSStabilizer      = false
                        c.PotatoGraphics     = false
                        c.CleaningSpace      = false
                        c.IpadView           = false
                        c.LagFreeMode        = false
                        c.LessShake          = false
                        c.Accuracy           = false
                        c.CustomHRecoil      = false
                        c.CustomVRecoil      = false
                        c.GodMode            = false
                        c.EspItem_Master     = false
                        c.EspOutline         = false
                        c.WhiteBody          = false
                        c.ColorBodyV2        = false
                        c.RemoveGrass        = false
                        c.RemoveFog          = false
                        c.AimDebug           = false
                        c.ForceAimbotScope   = false
                        c.EspShowDistance    = false
                        c.EspShowHealthBar   = false
                        c.EspTeamColorBox    = false
                        c.EspLine            = false
                        c.CounterEnabled     = false
                        c.EspModelName       = false
                        c.EspWeaponIcon      = false
                    end
                end
                if _G.GTLMODConfig and _G.GTLMODConfig.EspActiveBom == nil then
                    _G.GTLMODConfig.EspActiveBom = false
                end
                if _G.GTLMODConfig and _G.GTLMODConfig.ForceAimbot == true then
                    _G._ForceAimbotWanted = true
                end
                -- keep wallhack colors consistent after load
                if _G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart and _G.RefreshWallhackColors then
                    pcall(_G.RefreshWallhackColors)
                end
                AutoSaveLoop()
                _G.ModConfigLoaded = true
            end
            local NewWallhack = {
                Active = false,
                WH_TIMER = nil,
                PROCESSED_PAWNS = {},
                TICK_COUNT = 0,
                CONSOLE_READY = false,
                TICK_INTERVAL = 2.80,
                MAX_PAWNS_PER_TICK = 5,
                RESET_PROCESSED_EVERY = 4,
                AVATAR_SLOTS = {0,1,2,3,4,5,6,7},
                colors = { vis = nil, occ = nil, bVis = nil, bOcc = nil }
            }
            pcall(function()
                local LC = safeImport("LinearColor")
                if LC then
                    NewWallhack.colors.vis = LC(0.0, 1.0, 0.0, 0.4)
                    NewWallhack.colors.occ = LC(1.0, 0.0, 0.0, 0.4)
                    NewWallhack.colors.bVis = LC(0.0, 0.8, 0.0, 0.4)
                    NewWallhack.colors.bOcc = LC(0.8, 0.0, 0.0, 0.4)
                end
            end)
            local function SetupConsole()
                pcall(function()
                    local KSL = safeImport("KismetSystemLibrary")
                    local world = slua.getWorld and slua.getWorld() or nil
                    if not KSL or not world then return end
                    KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                    KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                    KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                    KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                    NewWallhack.CONSOLE_READY = true
                end)
            end
            local function ApplyToMesh(mesh, visColor, occColor)
                if not mesh or not slua.isValid(mesh) then return end
                pcall(function()
                    if mesh.SetDrawDyeing then mesh:SetDrawDyeing(true) end
                    if mesh.SetDrawDyeingMode then mesh:SetDrawDyeingMode(1) end
                    if mesh.SetVisibleDyeingColor then mesh:SetVisibleDyeingColor(visColor) end
                    if mesh.SetOccludedDyeingColor then mesh:SetOccludedDyeingColor(occColor) end
                    if mesh.SetDyeingColorFadeDistance then mesh:SetDyeingColorFadeDistance(99999.0) end
                    if mesh.SetDyeingColorMinMaxDistance then mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0) end
                    if mesh.SetDrawHighlight then mesh:SetDrawHighlight(true) end
                    if mesh.OverrideHighlightColor then mesh:OverrideHighlightColor(visColor) end
                    if mesh.SetHighlightCanBeOccluded then mesh:SetHighlightCanBeOccluded(false) end
                    if mesh.SetDrawIdeaOutline then mesh:SetDrawIdeaOutline(true) end
                    if mesh.SetIdeaOutlineNew then mesh:SetIdeaOutlineNew(true) end
                    if mesh.SetIdeaOutlineOcclusionHighlight then mesh:SetIdeaOutlineOcclusionHighlight(true) end
                    if mesh.OverrideIdeaOutlineColor then mesh:OverrideIdeaOutlineColor(visColor) end
                    if mesh.SetIdeaOutlineOcclusionColor then mesh:SetIdeaOutlineOcclusionColor(occColor) end
                    if mesh.OverrideIdeaOutlineThickness then mesh:OverrideIdeaOutlineThickness(20.0) end
                    if mesh.SetIdeaOverrideOutlineAndOcclusion then mesh:SetIdeaOverrideOutlineAndOcclusion(true) end
                    if mesh.SetRenderCustomDepth then mesh:SetRenderCustomDepth(true) end
                    if mesh.SetCustomDepthStencilValue then mesh:SetCustomDepthStencilValue(255) end
                end)
            end
            local function IsPawnAlive(pawn)
                if not slua.isValid(pawn) then return false end
                if pawn.Health and pawn.Health > 0 then return true end
                return false
            end
            local function NewWallhackTick()
                pcall(function()
                    if not (_G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart == true) then
                        if NewWallhack.Active and _G.StopNewWallhack then pcall(_G.StopNewWallhack) end
                        return
                    end
                    local localPawn = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
                    if not slua.isValid(localPawn) then return end
                    if (NewWallhack.TICK_COUNT % 4) == 0 then
                        NewWallhack.CONSOLE_READY = false
                        SetupConsole()
                    elseif not NewWallhack.CONSOLE_READY then
                        SetupConsole()
                    end
                    if not NewWallhack.colors.vis then
                        pcall(function() if _G.RefreshWallhackColors then _G.RefreshWallhackColors() end end)
                        if not NewWallhack.colors.vis then return end
                    end
                    NewWallhack.TICK_COUNT = NewWallhack.TICK_COUNT + 1
                    if NewWallhack.TICK_COUNT % NewWallhack.RESET_PROCESSED_EVERY == 0 then
                        NewWallhack.PROCESSED_PAWNS = {}
                    end
                    local myTeamId = localPawn.TeamID or 0
                    local allPawns = Game:GetAllPlayerPawns() or {}
                    local processedCount = 0
                    for _, pawn in pairs(allPawns) do
                        if processedCount >= NewWallhack.MAX_PAWNS_PER_TICK then break end
                        if not slua.isValid(pawn) or pawn == localPawn then goto continue end
                        if pawn.PlayerKey and NewWallhack.PROCESSED_PAWNS[pawn.PlayerKey] then goto continue end
                        if not slua.isValid(pawn) then goto continue end
                        if IsPawnAlive(pawn) and pawn.TeamID and pawn.TeamID ~= myTeamId then
                            local isAI = pcall(Game.IsAI, pawn) and true or false
                            local vis = isAI and NewWallhack.colors.bVis or NewWallhack.colors.vis
                            local occ = isAI and NewWallhack.colors.bOcc or NewWallhack.colors.occ
                            pcall(function()
                                if slua.isValid(pawn.Mesh) then ApplyToMesh(pawn.Mesh, vis, occ) end
                                local avatarComp = pawn.CharacterAvatarComp2_BP or (pawn.getAvatarComponent2 and pawn:getAvatarComponent2())
                                if avatarComp and avatarComp.GetMeshCompBySlot then
                                    for _, slot in ipairs(NewWallhack.AVATAR_SLOTS) do
                                        local mesh = avatarComp:GetMeshCompBySlot(slot)
                                        if slua.isValid(mesh) then ApplyToMesh(mesh, vis, occ) end
                                    end
                                end
                                pcall(function()
                                    local SkeletalMeshComponent = safeImport("SkeletalMeshComponent")
                                    if SkeletalMeshComponent and pawn.GetComponentsByClass then
                                        local skComps = pawn:GetComponentsByClass(SkeletalMeshComponent)
                                        if skComps then
                                            local n = skComps:Num() or 0
                                            if n > 6 then n = 6 end
                                            for i = 0, n - 1 do
                                                local comp = skComps:Get(i)
                                                if slua.isValid(comp) and comp ~= pawn.Mesh then
                                                    ApplyToMesh(comp, vis, occ)
                                                end
                                            end
                                        end
                                    end
                                end)
                                if pawn.GetCurrentWeapon then
                                    local weapon = pawn:GetCurrentWeapon()
                                    if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                                        ApplyToMesh(weapon.Mesh, vis, occ)
                                    end
                                end
                            end)
                            if pawn.PlayerKey then NewWallhack.PROCESSED_PAWNS[pawn.PlayerKey] = true end
                            processedCount = processedCount + 1
                        end
                        ::continue::
                    end
                end)
            end
            _G.NewWallhack = NewWallhack
            function _G.StartNewWallhack()
                NewWallhack.CONSOLE_READY = false
                NewWallhack.PROCESSED_PAWNS = {}
                NewWallhack.TICK_COUNT = 0
                pcall(function() if _G.RefreshWallhackColors then _G.RefreshWallhackColors() end end)
                if NewWallhack.WH_TIMER then
                    pcall(function()
                        if _G.Game then _G.Game:RemoveGameTimer(NewWallhack.WH_TIMER) end
                    end)
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if slua.isValid(pc) and pc.RemoveGameTimer then
                            pc:RemoveGameTimer(NewWallhack.WH_TIMER)
                        end
                    end)
                    NewWallhack.WH_TIMER = nil
                end
                NewWallhack.Active = false
                SetupConsole()
                if not NewWallhack.colors.vis then
                    pcall(function() if _G.RefreshWallhackColors then _G.RefreshWallhackColors() end end)
                    if not NewWallhack.colors.vis then return false end
                end
                if _G.Game and _G.Game.AddGameTimer then
                    NewWallhack.WH_TIMER = _G.Game:AddGameTimer(NewWallhack.TICK_INTERVAL, true, NewWallhackTick)
                    NewWallhack.Active = true
                    NewWallhack.PROCESSED_PAWNS = {}
                    return true
                end
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                if slua.isValid(pc) and pc.AddGameTimer then
                    NewWallhack.WH_TIMER = pc:AddGameTimer(NewWallhack.TICK_INTERVAL, true, NewWallhackTick)
                    NewWallhack.Active = true
                    NewWallhack.PROCESSED_PAWNS = {}
                    return true
                end
                return false
            end
            function _G.StopNewWallhack()
                if NewWallhack.WH_TIMER then
                    pcall(function()
                        if _G.Game then _G.Game:RemoveGameTimer(NewWallhack.WH_TIMER) end
                    end)
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if slua.isValid(pc) and pc.RemoveGameTimer then
                            pc:RemoveGameTimer(NewWallhack.WH_TIMER)
                        end
                    end)
                    NewWallhack.WH_TIMER = nil
                end
                NewWallhack.Active = false
                NewWallhack.PROCESSED_PAWNS = {}
                NewWallhack.colors.vis = nil
                NewWallhack.colors.occ = nil
                NewWallhack.colors.bVis = nil
                NewWallhack.colors.bOcc = nil
                pcall(function()
                    local GD = GameplayData or package.loaded["GameLua.GameCore.Data.GameplayData"]
                    local chars = GD and GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters()
                    if chars then
                        for _, pawn in pairs(chars) do
                            if slua.isValid(pawn) then
                                pcall(function()
                                    local function ClearMesh(mesh)
                                        if not mesh or not slua.isValid(mesh) then return end
                                        pcall(function()
                                            if mesh.SetDrawDyeing then mesh:SetDrawDyeing(false) end
                                            if mesh.SetDrawHighlight then mesh:SetDrawHighlight(false) end
                                            if mesh.SetDrawIdeaOutline then mesh:SetDrawIdeaOutline(false) end
                                            if mesh.SetIdeaOutlineNew then mesh:SetIdeaOutlineNew(false) end
                                            if mesh.SetRenderCustomDepth then mesh:SetRenderCustomDepth(false) end
                                        end)
                                    end
                                    if pawn.Mesh then ClearMesh(pawn.Mesh) end
                                    if pawn.getAvatarComponent2 then
                                        local av = pawn:getAvatarComponent2()
                                        if slua.isValid(av) then
                                            for _, slot in ipairs(NewWallhack.AVATAR_SLOTS or {0,1,2,3,4,5,6,7}) do
                                                pcall(function()
                                                    local m = nil
                                                    if av.GetMeshCompBySlot then m = av:GetMeshCompBySlot(slot)
                                                    elseif av.GetMeshBySlot then m = av:GetMeshBySlot(slot) end
                                                    ClearMesh(m)
                                                end)
                                            end
                                        end
                                    end
                                    pcall(function()
                                        local SkeletalMeshComponent = safeImport("SkeletalMeshComponent")
                                        if SkeletalMeshComponent and pawn.GetComponentsByClass then
                                            local skComps = pawn:GetComponentsByClass(SkeletalMeshComponent)
                                            if skComps then
                                                for i = 0, skComps:Num() - 1 do
                                                    local comp = skComps:Get(i)
                                                    ClearMesh(comp)
                                                end
                                            end
                                        end
                                    end)
                                end)
                            end
                        end
                    end
                end)
                NewWallhack.PROCESSED_PAWNS = {}
                NewWallhack.Active = false
            end
            _G.WH_COLOR_PALETTE = {
                [0]  = {0.95, 0.05, 0.05},
                [1]  = {0.05, 0.95, 0.95},
                [2]  = {0.95, 0.95, 0.08},
                [3]  = {0.08, 0.95, 0.15},
                [4]  = {0.55, 0.10, 0.95},
                [5]  = {0.95, 0.95, 0.95},
                [6]  = {1.00, 0.20, 0.55},
                [7]  = {0.30, 1.00, 0.15},
                [8]  = {1.00, 0.45, 0.05},
                [9]  = {0.15, 0.35, 1.00},
                [10] = {1.00, 0.05, 0.85},
                [11] = {0.05, 0.85, 0.70},
                [12] = {1.00, 0.80, 0.15},
                [13] = {0.55, 0.55, 0.55},
            }
            local function _WH_MakeLC(idx, alpha)
                local LC = safeImport("LinearColor")
                if not LC then return nil end
                local c = _G.WH_COLOR_PALETTE[tonumber(idx) or 0] or _G.WH_COLOR_PALETTE[0]
                local intensity = tonumber((_G.GTLMODConfig and _G.GTLMODConfig.GlowIntensity) or 60) or 60
                if intensity < 10 then intensity = 10 end
                if intensity > 100 then intensity = 100 end
                local mult = 0.55 + (intensity / 100.0) * 0.70
                local a = alpha or 0.50
                return LC(c[1] * mult, c[2] * mult, c[3] * mult, a)
            end
            function _G.RefreshWallhackColors()
                local cfg = _G.GTLMODConfig or {}
                NewWallhack.colors.vis  = _WH_MakeLC(cfg.ColorEnemyWHVis or 3, 0.50)
                NewWallhack.colors.occ  = _WH_MakeLC(cfg.ColorEnemyWHOcc or 0, 0.50)
                NewWallhack.colors.bVis = _WH_MakeLC(cfg.ColorBotWHVis or 1, 0.45)
                NewWallhack.colors.bOcc = _WH_MakeLC(cfg.ColorBotWHOcc or 2, 0.45)
                NewWallhack.PROCESSED_PAWNS = {}
            end
            pcall(function()
                local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(4.0, function()
                        if _G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart and _G.StartNewWallhack then
                            _G.StartNewWallhack()
                        end
                    end)
                end
            end)
            function _G.InitModMenuTab()
                return
            end
            function _G.ApplyTargetFPS(fps)
                fps = tonumber(fps) or (_G.GTLMODConfig and _G.GTLMODConfig.TargetFPS) or 90
                if fps < 30 then fps = 30 end
                if fps > 165 then fps = 165 end
                if _G.GTLMODConfig then _G.GTLMODConfig.TargetFPS = fps end
                pcall(function()
                    _GfxExec("t.MaxFPS", tostring(fps))
                    _GfxExec("r.FrameRateLimit", tostring(fps))
                    _GfxExec("r.VSync", "0")
                end)
                local level = 6
                if fps >= 165 then level = 8
                elseif fps >= 144 then level = 8
                elseif fps >= 120 then level = 8
                elseif fps >= 90 then level = 7
                elseif fps >= 60 then level = 6
                else level = 5 end
                pcall(function()
                    local SettingCfg = require("client.logic.setting.setting_config")
                    local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                    if SettingCfg then
                        if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
                        if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
                    end
                    if GraphicSettingDB and GraphicSettingDB.TpViewValue then
                        GraphicSettingDB.TpViewValue.max = 160
                    end
                end)
                pcall(function()
                    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
                    local GSC_FPS  = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
                    local GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
                    local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                    if logic_setting_graphics and not logic_setting_graphics.__MAGOO_FPS_UNLOCK_PATCHED then
                        local old_SetFPS = logic_setting_graphics.SetFPS
                        logic_setting_graphics.__MAGOO_FPS_UNLOCK_PATCHED = true
                        logic_setting_graphics.__MAGOO_FPS_UNLOCK_ORIGINAL = old_SetFPS
                        function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
                            if old_SetFPS then return old_SetFPS(gameInstance, FPSLevel) end
                        end
                    end
                    pcall(function()
                        local gi = _GfxGetGI and _GfxGetGI() or nil
                        if gi and logic_setting_graphics and logic_setting_graphics.SetFPS then
                            logic_setting_graphics.SetFPS(gi, level)
                        end
                    end)
                    if GSC_FPS and GSC_FPS.__inner_impl then
                        local fps_impl = GSC_FPS.__inner_impl
                        function fps_impl:GetMaxFPSLevel() return 8, 8 end
                        function fps_impl:InitRealSupportFPS()
                            local RealSupportFPS = {}
                            for i = 1, 8 do RealSupportFPS[i] = {true, true} end
                            if GraphicSettingDB then
                                pcall(function()
                                    GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false)
                                end)
                            end
                            return RealSupportFPS
                        end
                        pcall(function()
                            if type(fps_impl.InitRealSupportFPS) == "function" then
                            end
                        end)
                    end
                    if GSC_FPSFT and GSC_FPSFT.__inner_impl then
                        local ft = GSC_FPSFT.__inner_impl
                        pcall(function()
                            if type(ft.GetMaxFPSLevel) == "function" or true then
                                function ft:GetMaxFPSLevel() return 8, 8 end
                            end
                        end)
                    end
                end)
                pcall(function()
                    _GfxExec("t.MaxFPS", tostring(fps))
                    _GfxExec("r.FrameRateLimit", tostring(fps))
                end)
                return true
            end
            function _G.ApplyFPSStabilizer(enable)
                local on = (enable == true)
                if _G.GTLMODConfig then _G.GTLMODConfig.FPSStabilizer = on end
                local function exec(cmd, arg)
                    pcall(function()
                        local ui_util = require("client.common.ui_util")
                        local gi = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
                        if gi and gi.ExecuteCMD then
                            if arg ~= nil then gi:ExecuteCMD(cmd, tostring(arg)) else gi:ExecuteCMD(cmd) end
                        end
                    end)
                    pcall(function()
                        local KSL = import("KismetSystemLibrary")
                        local world = slua and slua.getWorld and slua.getWorld()
                        if KSL and KSL.ExecuteConsoleCommand and world then
                            if arg ~= nil then KSL.ExecuteConsoleCommand(world, cmd .. " " .. tostring(arg))
                            else KSL.ExecuteConsoleCommand(world, cmd) end
                        end
                    end)
                end
                if on then
                    exec("a.ParallelAnimEvaluation", "1"); exec("r.GTSyncType", "1")
                    exec("r.OneFrameThreadLag", "1"); exec("r.FinishCurrentFrame", "0")
                    exec("r.EnableWeaponCompTickOptimise", "1")
                    exec("slate.SuperFrameMiniMapUpdateRate", "3")
                    exec("r.Streaming.PoolSize", "400"); exec("r.Streaming.LimitPoolSizeToVRAM", "1")
                end
                return true
            end
            function _G.ApplyPotatoGraphics(enable)
                local on = (enable == true)
                if _G.GTLMODConfig then _G.GTLMODConfig.PotatoGraphics = on end
                local function exec(cmd, arg)
                    pcall(function()
                        local ui_util = require("client.common.ui_util")
                        local gi = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
                        if gi and gi.ExecuteCMD then
                            if arg ~= nil then gi:ExecuteCMD(cmd, tostring(arg)) else gi:ExecuteCMD(cmd) end
                        end
                    end)
                    pcall(function()
                        local KSL = import("KismetSystemLibrary")
                        local world = slua and slua.getWorld and slua.getWorld()
                        if KSL and KSL.ExecuteConsoleCommand and world then
                            if arg ~= nil then KSL.ExecuteConsoleCommand(world, cmd .. " " .. tostring(arg))
                            else KSL.ExecuteConsoleCommand(world, cmd) end
                        end
                    end)
                end
                if on then
                    exec("sg.ViewDistanceQuality", "0"); exec("sg.ShadowQuality", "0")
                    exec("sg.PostProcessQuality", "0"); exec("sg.EffectsQuality", "0")
                    exec("sg.FoliageQuality", "0"); exec("r.ShadowQuality", "0")
                    exec("r.Shadow.CSM.MaxCascades", "0"); exec("r.BloomQuality", "0")
                    exec("r.MotionBlurQuality", "0"); exec("r.DefaultFeature.MotionBlur", "0")
                    exec("r.DepthOfFieldQuality", "0"); exec("r.AmbientOcclusionLevels", "0")
                    exec("foliage.LODDistanceScale", "0.5"); exec("r.Streaming.PoolSize", "250")
                else
                    exec("sg.ViewDistanceQuality", "2"); exec("sg.ShadowQuality", "2")
                    exec("sg.PostProcessQuality", "2"); exec("sg.EffectsQuality", "2")
                    exec("sg.FoliageQuality", "2"); exec("r.ShadowQuality", "2")
                    exec("foliage.LODDistanceScale", "1.0")
                end
                return true
            end
            function _G.ApplyCleaningSpace(enable)
                local on = (enable == true)
                if _G.GTLMODConfig then
                    _G.GTLMODConfig.CleaningSpace = on
                    _G.GTLMODConfig.RemoveGrass = on
                end
                local function exec(cmd, arg)
                    pcall(function()
                        local ui_util = require("client.common.ui_util")
                        local gi = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
                        if gi and gi.ExecuteCMD then
                            if arg ~= nil then gi:ExecuteCMD(cmd, tostring(arg)) else gi:ExecuteCMD(cmd) end
                        end
                    end)
                    pcall(function()
                        local KSL = import("KismetSystemLibrary")
                        local world = slua and slua.getWorld and slua.getWorld()
                        if KSL and KSL.ExecuteConsoleCommand and world then
                            if arg ~= nil then KSL.ExecuteConsoleCommand(world, cmd .. " " .. tostring(arg))
                            else KSL.ExecuteConsoleCommand(world, cmd) end
                        end
                    end)
                end
                if on then
                    exec("grass.DensityScale", "0"); exec("foliage.DensityScale", "0")
                    exec("r.Fog", "0"); exec("r.VolumetricFog", "0"); exec("grass.flush", "1")
                else
                    exec("grass.DensityScale", "1"); exec("foliage.DensityScale", "1")
                    exec("r.Fog", "1"); exec("r.VolumetricFog", "1"); exec("grass.flush", "1")
                end
                return true
            end
            local function InitializeGraphicsUnlock()
                if isExpired then return end
                if _G.GTLMODConfig and _G.GTLMODConfig.UnlockFPS == true
                    and not (_G.GTLMODState and _G.GTLMODState.GraphicsUnlocked == true) then
                    local fps = tonumber(_G.GTLMODConfig.TargetFPS) or 165
                    pcall(function() _G.ApplyTargetFPS(fps) end)
                end
                if _G.GTLMODConfig and _G.GTLMODConfig.FPSStabilizer == true then
                    pcall(function() _G.ApplyFPSStabilizer(true) end)
                end
                if _G.GTLMODConfig and _G.GTLMODConfig.PotatoGraphics then
                    pcall(function() _G.ApplyPotatoGraphics(true) end)
                end
                if _G.GTLMODConfig and _G.GTLMODConfig.CleaningSpace then
                    pcall(function() _G.ApplyCleaningSpace(true) end)
                end
                if _G.GTLMODState then _G.GTLMODState.GraphicsUnlocked = true end
            end
            local function SafeAddMark(id, pos, z, str, size, actor)
                if not _G.GTLMODState.TrackedMarks then _G.GTLMODState.TrackedMarks = {} end
                local count = 0
                for _ in pairs(_G.GTLMODState.TrackedMarks) do count = count + 1 end
                if count >= LIMITS.MAX_TRACKED_MARKS then return nil end
                local mark = nil
                pcall(function()
                    local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                    if not (InGameMarkTools and InGameMarkTools.ClientAddMapMark) then return end
                    local mid = id
                    if id == 8888 then mid = 9999 end
                    local usePos = pos
                    pcall(function()
                        if actor then
                            if actor.K2_GetActorLocation then usePos = actor:K2_GetActorLocation()
                            elseif actor.GetActorLocation then usePos = actor:GetActorLocation() end
                        end
                    end)
                    if not usePos then usePos = FVector(0, 0, 0) end
                    local m = InGameMarkTools.ClientAddMapMark(mid, usePos, z or 0, str or "", size or 4, actor)
                    if m then
                        mark = m
                        _G.GTLMODState.TrackedMarks[mark] = { id = mid, actor = actor }
                    end
                end)
                return mark
            end
            local function SafeRemoveMark(mark)
                if not mark then return end
                pcall(function()
                    local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                    if InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(mark) end
                    if InGameMarkTools and InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(mark) end
                end)
                if _G.GTLMODState.TrackedMarks then _G.GTLMODState.TrackedMarks[mark] = nil end
            end
            local function GetSafeEnemyKey(enemy)
                if Valid(enemy) then
                    if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
                    if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
                end
                return tostring(enemy)
            end
            local _MAGOO_MARK_INIT_DONE = false
            local function InitScreenMarkSystem()
                if _MAGOO_MARK_INIT_DONE then return true end
                local ok = false
                local configReady = false
                local managerReady = false
                pcall(function()
                    local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                    local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local FVec = FVector
                    pcall(function()
                        if not FVec then
                            local okv, V = pcall(import, "Vector")
                            if okv then FVec = V end
                        end
                    end)
                    local vOffHead = (FVec and FVec(0, 0, 40)) or { X = 0, Y = 0, Z = 40 }
                    local vOffMap  = (FVec and FVec(0, 0, 90)) or { X = 0, Y = 0, Z = 90 }
                    local function ApplyMarkConfigs(smc)
                        if not smc or type(smc) ~= "table" then return false end
                        smc[1006] = smc[1006] or {}
                        smc[1006].bBindBlocked = true
                        smc[1006].bBindOutScreen = true
                        smc[1006].MaxWidgetNum = 99
                        smc[1006].MaxShowDistance = 40000
                        smc[1006].bScaleByDistance = false
                        smc[1006].BindSocketName = "head"
                        smc[1006].bUseLuaWorldSocketName = true
                        smc[1006].WorldPositionOffset = vOffHead
                        smc[1006].bIsBindingActor = true
                        smc[1006].bNeedPreLoad = true
                        local mapMarkConfig = {
                            UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                            MaxWidgetNum = 64,
                            MaxShowDistance = 50000,
                            bBindOutScreen = true,
                            bBindBlocked = true,
                            bIsBindingActor = true,
                            BindSocketName = "head",
                            bUseLuaWorldSocketName = true,
                            WorldPositionOffset = vOffMap,
                            bNeedPreLoad = true,
                            Priority = 2,
                            bScaleByDistance = false,
                        }
                        local function forceRadarType(tid)
                            local t = smc[tid]
                            if type(t) == "table" then
                                t.MaxWidgetNum = 64
                                t.MaxShowDistance = 50000
                                t.bBindOutScreen = true
                                t.bBindBlocked = true
                                t.bIsBindingActor = true
                                t.BindSocketName = "head"
                                t.bUseLuaWorldSocketName = true
                                t.WorldPositionOffset = vOffMap
                                if not t.UIPathName then t.UIPathName = mapMarkConfig.UIPathName end
                            else
                                smc[tid] = mapMarkConfig
                            end
                        end
                        forceRadarType(9999)
                        forceRadarType(8888)
                        return true
                    end
                    if GamePlayTools and GamePlayTools.GetCurrentConfig then
                        local smc = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
                        if ApplyMarkConfigs(smc) then configReady = true end
                    end
                    pcall(function()
                        local CGM = package.loaded["GameLua.GameCore.Main.ClientGameMain"]
                        if CGM and CGM.CurrentConfig and CGM.CurrentConfig.ScreenMarkConfig then
                            if ApplyMarkConfigs(CGM.CurrentConfig.ScreenMarkConfig) then configReady = true end
                        end
                    end)
                    for mn, md in pairs(package.loaded) do
                        if type(mn) == "string" and string.find(mn, "ScreenMarkConfig", 1, true) and type(md) == "table" then
                            if ApplyMarkConfigs(md) then configReady = true end
                        end
                    end
                    if InGameMarkTools and InGameMarkTools.ScreenMarkManager
                        and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                        managerReady = true
                        pcall(InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData, InGameMarkTools.ScreenMarkManager, 1006)
                        pcall(InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData, InGameMarkTools.ScreenMarkManager, 9999)
                        pcall(InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData, InGameMarkTools.ScreenMarkManager, 8888)
                        pcall(InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData, InGameMarkTools.ScreenMarkManager, 9999)
                    end
                    ok = configReady and managerReady
                end)
                if ok then _MAGOO_MARK_INIT_DONE = true end
                return ok
            end
            _G.InitScreenMarkSystem = InitScreenMarkSystem
            _G.__CLEAR_VISION_V2_INIT_OK, _G.__CLEAR_VISION_V2_INIT_ERROR = pcall(function()
                local FVector2D = _G.FVector2D or import("Vector2D")
                local FLinearColor = _G.FLinearColor or import("LinearColor")
                local SlateBlueprintLibrary = nil
                local WidgetLayoutLibrary = nil
                pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
                pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
                local function IsValid(o)
                    if not o then return false end
                    local ok, value = pcall(function() return slua.isValid(o) end)
                    return ok and value == true
                end
                local function V2(x, y)
                    if FVector2D then return FVector2D(x, y) end
                    return {X=x, Y=y}
                end
                local function Color(r, g, b, a)
                    if FLinearColor then return FLinearColor(r, g, b, a or 1.0) end
                    return {R=r, G=g, B=b, A=a or 1.0}
                end
                local function CV2Flag(key, defaultValue)
                    local cfg = rawget(_G, "GTLMODConfig") or rawget(_G, "GTLModConfig")
                    if type(cfg) ~= "table" then return defaultValue == true end
                    if key == "EspV2Enabled" or key == "EspV2Bracket" or key == "EspV2Name" or key == "EspV2Health" then
                        return cfg.EspBox == true
                    end
                    if key == "EspV2Counter" then
                        return cfg.CounterEnabled == true
                    end
                    if key == "EspV2SnapLine" then
                        return cfg.EspLine == true
                    end
                    if key == "EspV2Distance" then
                        return cfg.EspBox == true
                    end
                    local v = cfg[key]
                    if v == nil then return defaultValue == true end
                    return v == true
                end
                local function CV2AnyFeatureOn()
                    return CV2Flag("EspV2Enabled", false)
                        or CV2Flag("EspV2Counter", false)
                        or CV2Flag("EspV2SnapLine", false)
                end
                local COLORS = {
                    Gold        = Color(1.00, 0.84, 0.42, 1.00),
                    GoldBright  = Color(1.00, 0.92, 0.62, 1.00),
                    GoldSoft    = Color(1.00, 0.90, 0.56, 0.42),
                    GoldDim     = Color(0.36, 0.25, 0.055, 0.96),
                    Navy        = Color(0.015, 0.10, 0.72, 1.00),
                    NavyBright  = Color(0.055, 0.32, 1.00, 1.00),
                    NavySoft    = Color(0.16, 0.46, 1.00, 0.38),
                    NavyDim     = Color(0.004, 0.018, 0.095, 0.97),
                    White       = Color(0.98, 0.98, 0.98, 1.00),
                    Dark        = Color(0.025, 0.025, 0.030, 0.94),
                    Dark2       = Color(0.045, 0.045, 0.055, 0.97),
                    Dark3       = Color(0.015, 0.015, 0.020, 0.98),
                    Gray        = Color(0.42, 0.42, 0.42, 1.00),
                    Red         = Color(0.86, 0.12, 0.12, 1.00),
                    RedBright   = Color(1.00, 0.28, 0.28, 1.00),
                    RedSoft     = Color(1.00, 0.28, 0.28, 0.30),
                    RedDim      = Color(0.25, 0.02, 0.02, 0.95),
                    Green       = Color(0.10, 0.84, 0.26, 1.00),
                    GreenBright = Color(0.38, 1.00, 0.50, 1.00),
                    GreenSoft   = Color(0.38, 1.00, 0.50, 0.28),
                    GreenDim    = Color(0.03, 0.20, 0.05, 0.96),
                    BloodRed       = Color(0.84, 0.010, 0.018, 1.00),
                    BloodRedBright = Color(1.00, 0.025, 0.040, 1.00),
                    BloodRedSoft   = Color(1.00, 0.24, 0.22, 0.46),
                    BloodRedDim    = Color(0.26, 0.002, 0.008, 0.98),
                    BloodRedShade  = Color(0.10, 0.000, 0.004, 0.66),
                    Yellow         = Color(0.05, 0.90, 0.25, 1.00),
                    YellowBright   = Color(0.95, 0.95, 0.95, 1.00),
                    YellowSoft     = Color(0.15, 0.85, 0.30, 0.48),
                    YellowDim      = Color(0.00, 0.25, 0.08, 0.98),
                    YellowShade    = Color(0.00, 0.10, 0.03, 0.66),
                    BotRedText     = Color(0.94, 0.010, 0.020, 1.00),
                    CtrBlack       = Color(0.06, 0.06, 0.06, 1.00),
                    CtrBlackBright = Color(0.95, 0.95, 0.95, 1.00),
                    CtrBlackSoft   = Color(0.18, 0.18, 0.18, 0.55),
                    CtrBlackDim    = Color(0.03, 0.03, 0.03, 0.98),
                    CtrBlackShade  = Color(0.00, 0.00, 0.00, 0.70),
                    CtrWhite       = Color(0.92, 0.92, 0.92, 1.00),
                    CtrWhiteBright = Color(0.08, 0.08, 0.08, 1.00),
                    CtrWhiteSoft   = Color(1.00, 1.00, 1.00, 0.50),
                    CtrWhiteDim    = Color(0.78, 0.78, 0.78, 0.98),
                    CtrWhiteShade  = Color(0.55, 0.55, 0.55, 0.66),
                    CtrBotText     = Color(0.05, 0.05, 0.05, 1.00),
                }
                local ClearVisionV2 = rawget(_G, "__CLEAR_VISION_ESP_V2")
                local CV2_BUILD = "cv-esp-v2-matchfix-r2-033"
                if type(ClearVisionV2) == "table" and ClearVisionV2.Build ~= CV2_BUILD
                    and type(ClearVisionV2.Stop) == "function" then
                    pcall(ClearVisionV2.Stop)
                end
                if type(ClearVisionV2) ~= "table" or ClearVisionV2.Build ~= CV2_BUILD then
                    ClearVisionV2 = {
                        Build = CV2_BUILD,
                        Active = false,
                        ESPCanvas = nil,
                        Controller = nil,
                        LocalPawn = nil,
                        EnemyCache = {},
                        EnemyWidgets = {},
                        MaxEnemies = 12,
                        RangeMeters = 250.0,
                        ScanInterval = 1.4,
                        DrawInterval = 0.04,
                        _CanvasScaleX = 1.0,
                        _CanvasScaleY = 1.0,
                        _CanvasOffsetX = 0.0,
                        _CanvasOffsetY = 0.0,
                        _CachedViewportW = 1920,
                        _CachedViewportH = 1080,
                        _CapsuleCache = setmetatable({}, {__mode="k"}),
                        _ProjectionCache = {},
                        EnemyMeta = {},
                        RealEnemyCount = 0,
                        BotEnemyCount = 0,
                        Counter = nil,
                        _FrameSerial = 0,
                        _TransformEveryNFrames = 6,
                        _CounterEveryNFrames = 6,
                        _TimerGeneration = 0,
                    }
                    _G.__CLEAR_VISION_ESP_V2 = ClearVisionV2
                else
                    ClearVisionV2.DrawInterval = 0.04
                    ClearVisionV2.ScanInterval = ClearVisionV2.ScanInterval or 1.4
                    ClearVisionV2._FrameSerial = ClearVisionV2._FrameSerial or 0
                    ClearVisionV2._TransformEveryNFrames = ClearVisionV2._TransformEveryNFrames or 14
                    ClearVisionV2._CounterEveryNFrames = ClearVisionV2._CounterEveryNFrames or 14
                    ClearVisionV2._TimerGeneration = ClearVisionV2._TimerGeneration or 0
                end
                local REF_W = 688.0
                local REF_H = 996.0
                local REF_BODY_TOP = 172.0
                local REF_BODY_BOTTOM = 900.0
                local REF_BODY_SPAN = REF_BODY_BOTTOM - REF_BODY_TOP
                local function SetVisible(widget, visible)
                    if not IsValid(widget) then return false end
                    local vis = visible and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed
                    local ok = pcall(function() widget:SetWidgetVisibility(vis) end)
                    return ok
                end
                local function SetTextColor(widget, linearColor)
                    if not IsValid(widget) then return false end
                    local ok = pcall(function()
                        local FSlateColor = nil
                        pcall(function()
                            FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                        end)
                        if FSlateColor then widget:SetColorAndOpacity(FSlateColor(linearColor))
                        else widget:SetColorAndOpacity(linearColor) end
                    end)
                    return ok
                end
                local function SetFontSize(widget, size)
                    if not IsValid(widget) then return false end
                    local ok = pcall(function()
                        if widget.Font then
                            local f = widget.Font
                            f.Size = math.max(5, math.floor(size + 0.5))
                            widget:SetFont(f)
                        end
                    end)
                    return ok
                end
                local function SetFontBold(widget)
                    if not IsValid(widget) then return false end
                    local ok = pcall(function()
                        if widget.Font then
                            local f = widget.Font
                            pcall(function() f.TypefaceFontName = "Bold" end)
                            pcall(function() f.FontName = "Bold" end)
                            widget:SetFont(f)
                        end
                    end)
                    return ok
                end
                local function DestroyWidget(widget)
                    if not widget then return end
                    pcall(function() widget:RemoveFromParent() end)
                    pcall(function() widget:ConditionalBeginDestroy() end)
                end
                local function GetWorldSafe()
                    local world=nil
                    pcall(function()
                        if slua and slua.getWorld then world=slua.getWorld() end
                    end)
                    return world
                end
                local function ResolveControllerFresh()
                    local pc=nil
                    pcall(function()
                        if GameplayData and GameplayData.GetPlayerController then
                            pc=GameplayData.GetPlayerController()
                        end
                    end)
                    if not IsValid(pc) then
                        pcall(function()
                            if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
                                pc=slua_GameFrontendHUD:GetPlayerController()
                            end
                        end)
                    end
                    return IsValid(pc) and pc or nil
                end
                local function GetController()
                    local fresh=ResolveControllerFresh()
                    if IsValid(fresh) then
                        if ClearVisionV2.Controller~=fresh then
                            ClearVisionV2.Controller=fresh
                            ClearVisionV2.LocalPawn=nil
                        end
                        return fresh
                    end
                    local cached=ClearVisionV2.Controller
                    return IsValid(cached) and cached or nil
                end
                local function ResolveLocalPawnFresh(pc)
                    local pawn=nil
                    pcall(function()
                        if GameplayData and GameplayData.GetPlayerCharacter then
                            pawn=GameplayData.GetPlayerCharacter()
                        end
                    end)
                    if not IsValid(pawn) then
                        pcall(function()
                            if GameplayData and GameplayData.GetLocalCharacter then
                                pawn=GameplayData.GetLocalCharacter()
                            end
                        end)
                    end
                    if not IsValid(pawn) and IsValid(pc) then
                        pcall(function()
                            if pc.GetPlayerCharacterSafety then pawn=pc:GetPlayerCharacterSafety() end
                        end)
                    end
                    if not IsValid(pawn) and IsValid(pc) then
                        pcall(function()
                            if pc.GetPawn then pawn=pc:GetPawn() end
                        end)
                    end
                    return IsValid(pawn) and pawn or nil
                end
                local function SameRuntimeObject(a, b)
                    if a == b then return true end
                    if not IsValid(a) or not IsValid(b) then return false end
                    local sa, sb = nil, nil
                    pcall(function() sa = tostring(a) end)
                    pcall(function() sb = tostring(b) end)
                    return sa ~= nil and sb ~= nil and sa ~= "" and sa == sb
                end
                local function GetLocalPawn(pc)
                    local fresh=ResolveLocalPawnFresh(pc)
                    if IsValid(fresh) then
                        ClearVisionV2.LocalPawn=fresh
                        return fresh
                    end
                    local cached=ClearVisionV2.LocalPawn
                    return IsValid(cached) and cached or nil
                end
                local function GetActorLocation(actor)
                    if not IsValid(actor) then return nil end
                    local loc = nil
                    pcall(function()
                        if actor.K2_GetActorLocation then loc = actor:K2_GetActorLocation()
                        elseif actor.GetActorLocation then loc = actor:GetActorLocation() end
                    end)
                    if not loc then
                        pcall(function()
                            if Game and Game.GetActorLocation then loc = Game:GetActorLocation(actor) end
                        end)
                    end
                    return loc
                end
                local function DistanceMeters(a, b)
                    if not a or not b then return math.huge end
                    local dx = (a.X or 0) - (b.X or 0)
                    local dy = (a.Y or 0) - (b.Y or 0)
                    local dz = (a.Z or 0) - (b.Z or 0)
                    return math.sqrt(dx*dx + dy*dy + dz*dz) / 100.0
                end
                local function GetPlayerState(character)
                    if not IsValid(character) then return nil end
                    local ps = nil
                    pcall(function()
                        if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end
                    end)
                    if not IsValid(ps) then pcall(function()
                        if character.GetPlayerState then ps = character:GetPlayerState() end
                    end) end
                    if not IsValid(ps) then pcall(function() ps = character.PlayerState end) end
                    return IsValid(ps) and ps or nil
                end
                local function GetTeamID(character)
                    if not IsValid(character) then return nil end
                    local team = nil
                    pcall(function()
                        if character.GetTeamID then team = character:GetTeamID() end
                    end)
                    if team == nil then
                        local ps = GetPlayerState(character)
                        if ps then
                            pcall(function() if ps.GetTeamID then team = ps:GetTeamID() end end)
                            if team == nil then pcall(function() team = ps.TeamID end) end
                        end
                    end
                    if team == nil then pcall(function() team = character.TeamID end) end
                    return team
                end
                local function IsAlive(character)
                    if not IsValid(character) then return false end
                    local ok, alive = pcall(function()
                        if type(character.IsAlive) == "function" then return character:IsAlive() end
                    end)
                    if ok and type(alive) == "boolean" then return alive end
                    local hp = nil
                    pcall(function()
                        if character.Health ~= nil then hp = character.Health
                        elseif character.HP ~= nil then hp = character.HP
                        elseif character.GetHealth then hp = character:GetHealth() end
                    end)
                    hp = tonumber(hp)
                    return hp ~= nil and hp == hp and hp > 0
                end
                local function GetHealthPercent(character)
                    local hp, maxHp = nil, nil
                    pcall(function()
                        if character.Health ~= nil then hp = character.Health
                        elseif character.HP ~= nil then hp = character.HP
                        elseif character.GetHealth then hp = character:GetHealth() end
                        if character.MaxHealth ~= nil then maxHp = character.MaxHealth
                        elseif character.HealthMax ~= nil then maxHp = character.HealthMax
                        elseif character.MaxHP ~= nil then maxHp = character.MaxHP
                        elseif character.GetHealthMax then maxHp = character:GetHealthMax()
                        elseif character.GetMaxHealth then maxHp = character:GetMaxHealth() end
                    end)
                    hp = tonumber(hp) or 0
                    maxHp = tonumber(maxHp) or 100
                    if maxHp <= 0 then maxHp = 100 end
                    local pct = hp / maxHp
                    if pct < 0 then pct = 0 end
                    if pct > 1 then pct = 1 end
                    return pct
                end
                local function GetPlayerKey(character)
                    local key = nil
                    pcall(function()
                        if character.GetPlayerKey then key = character:GetPlayerKey() end
                    end)
                    if key == nil then pcall(function() key = character.PlayerKey end) end
                    if key == nil then
                        local ps = GetPlayerState(character)
                        if ps then pcall(function() key = ps.PlayerKey end) end
                    end
                    return key
                end
                local function Clamp(v, lo, hi)
                    if v < lo then return lo end
                    if v > hi then return hi end
                    return v
                end
                local function GetPlayerName(character)
                    if not IsValid(character) then return "ENEMY", false end
                    local name = nil
                    local function accept(value)
                        if value == nil or value == false then return end
                        local ok, txt = pcall(tostring, value)
                        if ok and txt ~= "" and txt ~= "nil" and txt ~= "None" then name = txt end
                    end
                    pcall(function()
                        if type(character.GetPlayerNameSafety) == "function" then accept(character:GetPlayerNameSafety()) end
                    end)
                    if not name then
                        pcall(function()
                            if type(character.GetPlayerName) == "function" then accept(character:GetPlayerName()) end
                        end)
                    end
                    if not name then
                        local ps = GetPlayerState(character)
                        if ps then
                            pcall(function()
                                if type(ps.GetPlayerName) == "function" then accept(ps:GetPlayerName()) end
                            end)
                            if not name then pcall(function() accept(ps.PlayerName) end) end
                            if not name then pcall(function() accept(ps.PlayerNamePrivate) end) end
                        end
                    end
                    if name then return name, true end
                    return "ENEMY", false
                end
                local function IsAI(character)
                    if not IsValid(character) then return false end
                    local isAI, hasSignal = false, false
                    local function accept(v)
                        if v == true or v == 1 then isAI, hasSignal = true, true
                        elseif v == false or v == 0 then hasSignal = true end
                    end
                    local function field(obj, k)
                        if not obj then return end
                        pcall(function() accept(obj[k]) end)
                    end
                    local function method(obj, k)
                        if not obj then return end
                        pcall(function()
                            local fn = obj[k]
                            if type(fn) == "function" then accept(fn(obj)) end
                        end)
                    end
                    pcall(function() if Game and Game.IsAI then accept(Game:IsAI(character)) end end)
                    if not isAI then field(character, "bIsAI") end
                    if not isAI then field(character, "IsAI") end
                    if not isAI then method(character, "IsBot") end
                    if not isAI then
                        local ps = GetPlayerState(character)
                        if ps then
                            field(ps, "bIsABot")
                            if not isAI then field(ps, "bIsBot") end
                            if not isAI then field(ps, "bIsAI") end
                            if not isAI then method(ps, "IsBot") end
                        end
                    end
                    return isAI == true
                end
                local function GetViewportSize(pc)
                    local w, h = 0, 0
                    pcall(function()
                        if pc and pc.GetViewportSize then
                            local v = V2(0,0)
                            pc:GetViewportSize(v)
                            if v and type(v.X)=="number" and type(v.Y)=="number" then w,h=v.X,v.Y end
                        end
                    end)
                    if w <= 200 then
                        pcall(function()
                            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                                local v=WidgetLayoutLibrary.GetViewportSize(pc)
                                if v and type(v.X)=="number" and type(v.Y)=="number" then w,h=v.X,v.Y end
                            end
                        end)
                    end
                    if w <= 200 then w,h=ClearVisionV2._CachedViewportW or 1920,ClearVisionV2._CachedViewportH or 1080 end
                    ClearVisionV2._CachedViewportW,ClearVisionV2._CachedViewportH=w,h
                    return w,h
                end
                local function GetCharacterBounds(character)
                    if not IsValid(character) then return nil, nil end
                    local center, halfHeight = nil, nil
                    local capsule = ClearVisionV2._CapsuleCache[character]
                    if not IsValid(capsule) then
                        capsule = nil
                        pcall(function()
                            if character.GetCapsuleComponent then capsule = character:GetCapsuleComponent()
                            elseif character.CapsuleComponent then capsule = character.CapsuleComponent end
                        end)
                        if IsValid(capsule) then ClearVisionV2._CapsuleCache[character] = capsule end
                    end
                    if IsValid(capsule) then
                        pcall(function()
                            if capsule.K2_GetComponentLocation then center = capsule:K2_GetComponentLocation()
                            elseif capsule.GetComponentLocation then center = capsule:GetComponentLocation() end
                            if capsule.GetScaledCapsuleHalfHeight then halfHeight = capsule:GetScaledCapsuleHalfHeight()
                            elseif capsule.GetUnscaledCapsuleHalfHeight then halfHeight = capsule:GetUnscaledCapsuleHalfHeight()
                            elseif capsule.CapsuleHalfHeight then halfHeight = capsule.CapsuleHalfHeight end
                        end)
                    end
                    if not center then center = GetActorLocation(character) end
                    if not center then return nil, nil end
                    if type(halfHeight) ~= "number" or halfHeight < 10 or halfHeight > 200 then
                        halfHeight = 85
                        pcall(function()
                            if character.bIsCrouched then halfHeight = 60 end
                            if character.IsProne and character:IsProne() then halfHeight = 25 end
                        end)
                    end
                    local head = {X=center.X, Y=center.Y, Z=center.Z + halfHeight}
                    local feet = {X=center.X, Y=center.Y, Z=center.Z - halfHeight}
                    return head, feet
                end
                local function ResolveCanvasFresh()
                    local tools=nil
                    pcall(function() tools=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
                    if not tools then return nil end
                    local ui=nil
                    pcall(function()
                        if tools.GetMainControlBaseUI then ui=tools.GetMainControlBaseUI() end
                    end)
                    if not IsValid(ui) then return nil end
                    local canvas=nil
                    pcall(function()
                        if IsValid(ui.CanvasPanel_0) then canvas=ui.CanvasPanel_0 end
                    end)
                    if not IsValid(canvas) then
                        pcall(function()
                            if IsValid(ui.CanvasPanel_42) then canvas=ui.CanvasPanel_42 end
                        end)
                    end
                    return IsValid(canvas) and canvas or nil
                end
                function ClearVisionV2.InitCanvas(forceRefresh)
                    local old=ClearVisionV2.ESPCanvas
                    if IsValid(old) and not forceRefresh then return true end
                    local canvas=ResolveCanvasFresh()
                    if not IsValid(canvas) then return IsValid(old) end
                    if canvas~=old then
                        for key,data in pairs(ClearVisionV2.EnemyWidgets) do
                            if data then
                                if data.Root then DestroyWidget(data.Root) end
                                if data.SnapLine and data.SnapLine.Widget then DestroyWidget(data.SnapLine.Widget) end
                                if data.DistanceText and data.DistanceText.Widget then DestroyWidget(data.DistanceText.Widget) end
                                if data.DistanceTextBack and data.DistanceTextBack.Widget then DestroyWidget(data.DistanceTextBack.Widget) end
                            end
                            ClearVisionV2.EnemyWidgets[key]=nil
                        end
                        if ClearVisionV2.Counter and ClearVisionV2.Counter.Root then DestroyWidget(ClearVisionV2.Counter.Root) end
                        ClearVisionV2.Counter=nil
                        ClearVisionV2._CounterVisible=nil
                        ClearVisionV2._ProjectionCache={}
                    end
                    ClearVisionV2.ESPCanvas=canvas
                    return true
                end
                function ClearVisionV2.UpdateCanvasTransform(pc)
                    if not IsValid(ClearVisionV2.ESPCanvas) then return end
                    local success = false
                    pcall(function()
                        local sbl = SlateBlueprintLibrary
                        if sbl and sbl.AbsoluteToLocal then
                            local geometry = ClearVisionV2.ESPCanvas:GetCachedGeometry()
                            if geometry then
                                local p0 = sbl.AbsoluteToLocal(geometry, V2(0,0))
                                local p1 = sbl.AbsoluteToLocal(geometry, V2(100,100))
                                if p0 and p1 and type(p0.X)=="number" and type(p0.Y)=="number"
                                    and type(p1.X)=="number" and type(p1.Y)=="number"
                                    and p1.X ~= p0.X and p1.Y ~= p0.Y then
                                    ClearVisionV2._CanvasScaleX = (p1.X-p0.X)/100.0
                                    ClearVisionV2._CanvasScaleY = (p1.Y-p0.Y)/100.0
                                    ClearVisionV2._CanvasOffsetX = p0.X
                                    ClearVisionV2._CanvasOffsetY = p0.Y
                                    success = true
                                end
                            end
                        end
                    end)
                    if not success then
                        local scale = 1.0
                        pcall(function()
                            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
                                local candidate = WidgetLayoutLibrary.GetViewportScale(pc)
                                if type(candidate)=="number" and candidate > 0 then scale = candidate end
                            end
                        end)
                        ClearVisionV2._CanvasScaleX = 1.0 / scale
                        ClearVisionV2._CanvasScaleY = 1.0 / scale
                        ClearVisionV2._CanvasOffsetX = 0
                        ClearVisionV2._CanvasOffsetY = 0
                    end
                end
                local function ScreenToCanvas(p)
                    if not p then return nil end
                    return {
                        X = p.X * (ClearVisionV2._CanvasScaleX or 1.0) + (ClearVisionV2._CanvasOffsetX or 0.0),
                        Y = p.Y * (ClearVisionV2._CanvasScaleY or 1.0) + (ClearVisionV2._CanvasOffsetY or 0.0)
                    }
                end
                local function ProjectToCanvas(pc, worldLoc, cache)
                    cache = cache or {}
                    cache.Pix = cache.Pix or V2(0,0)
                    local pix = cache.Pix
                    pix.X, pix.Y = 0,0
                    local okProjection = false
                    pcall(function()
                        local result = pc:ProjectWorldLocationToScreen(worldLoc, pix, true)
                        okProjection = result == true or result == 1 or (pix.X ~= 0 or pix.Y ~= 0)
                    end)
                    if not okProjection then return false, nil end
                    return true, ScreenToCanvas(pix)
                end
                local function NewWidget(path, outer)
                    local obj = nil
                    pcall(function() obj = CGame:NewObjectFromPath(path, outer) end)
                    return IsValid(obj) and obj or nil
                end
                local function AddChild(parent, child, zOrder)
                    if not IsValid(parent) or not IsValid(child) then return nil end
                    local slot = nil
                    pcall(function()
                        slot = parent:AddChildToCanvas(child)
                        if slot then
                            slot:SetAutoSize(false)
                            if zOrder then slot:SetZOrder(zOrder) end
                        end
                    end)
                    return IsValid(slot) and slot or nil
                end
                local function CreateBorder(parent, color, z)
                    local widget = NewWidget("/Script/UMG.Border", parent)
                    if not widget then return nil end
                    pcall(function()
                        widget:SetBrushColor(color)
                        widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        widget:SetRenderTransformPivot(V2(0.0,0.5))
                    end)
                    local slot = AddChild(parent, widget, z or 1)
                    if not slot then DestroyWidget(widget) return nil end
                    return {Widget=widget, Slot=slot}
                end
                local function CreateText(parent, value, color, fontSize, z)
                    local widget = NewWidget("/Script/UMG.TextBlock", parent)
                    if not widget then return nil end
                    pcall(function()
                        widget:SetText(tostring(value or ""))
                        widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        if widget.SetJustification then widget:SetJustification(1) end
                        if widget.SetAutoWrapText then widget:SetAutoWrapText(false) end
                        if widget.SetClipping and UEnums and UEnums.EWidgetClipping and UEnums.EWidgetClipping.ClipToBounds then
                            widget:SetClipping(UEnums.EWidgetClipping.ClipToBounds)
                        end
                    end)
                    SetTextColor(widget, color or COLORS.White)
                    SetFontSize(widget, fontSize or 12)
                    local slot = AddChild(parent, widget, z or 5)
                    if not slot then DestroyWidget(widget) return nil end
                    return {Widget=widget, Slot=slot}
                end
                local function SetRect(item, x, y, w, h)
                    if not item or not IsValid(item.Slot) then return false end
                    local ok = pcall(function()
                        item.Slot:SetPosition(V2(x,y))
                        item.Slot:SetSize(V2(math.max(0.5,w), math.max(0.5,h)))
                    end)
                    return ok
                end
                local function SetLine(item, x1, y1, x2, y2, thickness)
                    if not item or not IsValid(item.Widget) or not IsValid(item.Slot) then return false end
                    local dx, dy = x2-x1, y2-y1
                    local length = math.sqrt(dx*dx + dy*dy)
                    if length < 0.2 then SetVisible(item.Widget, false) return false end
                    local angle = ((math.atan2 and math.atan2(dy,dx)) or math.atan(dy,dx)) * 180.0 / math.pi
                    local ok = pcall(function()
                        item.Slot:SetPosition(V2(x1, y1-thickness*0.5))
                        item.Slot:SetSize(V2(length, math.max(0.5,thickness)))
                        item.Widget:SetRenderAngle(angle)
                        item.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    return ok
                end
                local function SetBorderColor(item, color)
                    if item and IsValid(item.Widget) then
                        pcall(function() item.Widget:SetBrushColor(color) end)
                    end
                end
                local function SetTextValue(item, value)
                    if item and IsValid(item.Widget) then
                        pcall(function() item.Widget:SetText(tostring(value)) end)
                    end
                end
                local function ApplyEnemyTheme(data, isAI, teamId)
                    if not data then return end
                    local tid = tonumber(teamId) or 0
                    local useRed = (tid % 2) == 1 or tid == 0
                    -- brackets/box = BLACK only; plate bg = BLACK; name text = RED or WHITE by team
                    local black = COLORS.Dark2 or Color(0.02, 0.02, 0.02, 0.92)
                    local pureBlack = Color(0.0, 0.0, 0.0, 0.95)
                    local textColor = useRed and (COLORS.BloodRedBright or Color(1.0, 0.12, 0.12, 1.0)) or (COLORS.White or Color(0.95, 0.95, 0.95, 1.0))
                    for _,item in ipairs(data.Arc or {}) do SetBorderColor(item, pureBlack) end
                    for _,item in ipairs(data.PlateLines or {}) do SetBorderColor(item, pureBlack) end
                    for _,item in ipairs(data.StatusOuter or {}) do SetBorderColor(item, pureBlack) end
                    for _,item in ipairs(data.PlateCornerFill or {}) do SetBorderColor(item, pureBlack) end
                    if data.PlateBGCore then SetBorderColor(data.PlateBGCore, pureBlack) end
                    if data.PlateBGMid then SetBorderColor(data.PlateBGMid, pureBlack) end
                    if data.PlateTopGlow then SetBorderColor(data.PlateTopGlow, pureBlack) end
                    if data.PlateBottomShade then SetBorderColor(data.PlateBottomShade, pureBlack) end
                    -- snap line color set from EspLineColor at draw time
                    if false and data.SnapLine then SetBorderColor(data.SnapLine, pureBlack) end
                    if data.TitleText then SetTextColor(data.TitleText.Widget, textColor) end
                    if data.DistanceText then SetTextColor(data.DistanceText.Widget, textColor) end
                    if data.DistanceTextBack then SetTextColor(data.DistanceTextBack.Widget, textColor) end
                    if data.WeaponPlateBG then SetBorderColor(data.WeaponPlateBG, pureBlack) end
                    if data.WeaponText then SetTextColor(data.WeaponText.Widget, COLORS.White or Color(1,1,1,1)) end
                    data.LastThemeAI = isAI == true
                end
                local function ApplyV2FeatureVisibility(data)
                    if not data then return end
                    local showBracket = CV2Flag("EspV2Bracket", true)
                    local showName = CV2Flag("EspV2Name", true)
                    local showHealth = CV2Flag("EspV2Health", true)
                    local showSnap = CV2Flag("EspV2SnapLine", false)
                    if data.SnapLine then
                        if data._VisSnap ~= showSnap then
                            data._VisSnap = showSnap
                            pcall(function()
                                if SetSnapVisible then SetSnapVisible(data, showSnap)
                                elseif data.SnapLine.Widget then SetVisible(data.SnapLine.Widget, showSnap)
                                elseif data.SnapLine then SetVisible(data.SnapLine, showSnap) end
                            end)
                        end
                    end
                    if data._VisBracket ~= showBracket then
                        data._VisBracket = showBracket
                        for _,item in ipairs(data.Arc or {}) do
                            if item and item.Widget then SetVisible(item.Widget, showBracket) end
                        end
                    end
                    if data._VisName ~= showName then
                        data._VisName = showName
                        local nameItems = {
                            data.PlateBGCore, data.PlateBGMid, data.PlateTopGlow, data.PlateBottomShade,
                            data.TitleText
                        }
                        for _,item in ipairs(nameItems) do
                            if item and item.Widget then SetVisible(item.Widget, showName) end
                        end
                        for _,item in ipairs(data.PlateLines or {}) do
                            if item and item.Widget then SetVisible(item.Widget, showName) end
                        end
                        for _,item in ipairs(data.PlateCornerFill or {}) do
                            if item and item.Widget then SetVisible(item.Widget, showName) end
                        end
                    end
                    -- weapon icon uses PlayerMapMarker icons only (no text plate)
                    if data._VisWeapon ~= false then
                        data._VisWeapon = false
                        if data.WeaponPlateBG and data.WeaponPlateBG.Widget then SetVisible(data.WeaponPlateBG.Widget, false) end
                        if data.WeaponText and data.WeaponText.Widget then SetVisible(data.WeaponText.Widget, false) end
                    end
                    if data._VisHealth ~= showHealth then
                        data._VisHealth = showHealth
                        for _,item in ipairs(data.StatusOuter or {}) do
                            if item and item.Widget then SetVisible(item.Widget, showHealth) end
                        end
                        for _,item in ipairs(data.StatusInner or {}) do
                            if item and item.Widget then SetVisible(item.Widget, showHealth) end
                        end
                    end
                end
                local function SetRootVisible(data, visible)
                    if not data or not data.Root or data._RootVisible == visible then return end
                    data._RootVisible = visible
                    SetVisible(data.Root, visible)
                end
                local function SetSnapVisible(data, visible)
                    if not data or not data.SnapLine or not data.SnapLine.Widget or data._SnapVisible == visible then return end
                    data._SnapVisible = visible
                    SetVisible(data.SnapLine.Widget, visible)
                end
                local function SetDistanceVisible(data, visible)
                    if not data or data._DistanceVisible == visible then return end
                    data._DistanceVisible = visible
                    if data.DistanceText and data.DistanceText.Widget then SetVisible(data.DistanceText.Widget, visible) end
                    if data.DistanceTextBack and data.DistanceTextBack.Widget then SetVisible(data.DistanceTextBack.Widget, visible) end
                end
                local function CreateEnemyWidget(key)
                    if not ClearVisionV2.InitCanvas(false) then return nil end
                    local parent = ClearVisionV2.ESPCanvas
                    if not IsValid(parent) then return nil end
                    local root = NewWidget("/Script/UMG.CanvasPanel", parent)
                    if not root then return nil end
                    local rootSlot = AddChild(parent, root, 20)
                    if not rootSlot then DestroyWidget(root) return nil end
                    local data = {
                        Root=root,
                        RootSlot=rootSlot,
                        Arc={},
                        PlateLines={},
                        PlateCornerFill={},
                        StatusOuter={},
                        StatusInner={},
                        Key=key,
                        LastScale=nil,
                        LastX=nil,
                        LastY=nil,
                        LastDistance=nil,
                        LastHealth=nil,
                        LastName=nil,
                        LastThemeAI=nil,
                        LastDistanceFont=nil,
                        LastDistanceRenderedText=nil,
                        LastDistanceAppliedFont=nil,
                        _RootVisible=nil,
                        _SnapVisible=nil,
                        _DistanceVisible=nil,
                        _VisBracket=nil,
                        _VisName=nil,
                        _VisHealth=nil,
                    }
                    data.PlateBGCore = CreateBorder(root, COLORS.Dark2, 4)
                    data.PlateBGMid = CreateBorder(root, COLORS.Dark2, 4)
                    data.PlateTopGlow = CreateBorder(root, COLORS.Dark2, 5)
                    data.PlateBottomShade = CreateBorder(root, COLORS.Dark2, 5)
                    data.TitleText = CreateText(root, "", COLORS.White, 22, 7)
                    -- weapon icon plate: same black rectangle + white text as name plate
                    data.WeaponPlateBG = CreateBorder(root, COLORS.Dark2, 4)
                    data.WeaponText = CreateText(root, "", COLORS.White, 18, 8)
                    data.DistanceTextBack = CreateText(parent, "", COLORS.Gold, 20, 58)
                    data.DistanceText = CreateText(parent, "", COLORS.Gold, 20, 59)
                    SetFontBold(data.DistanceTextBack and data.DistanceTextBack.Widget)
                    SetFontBold(data.DistanceText and data.DistanceText.Widget)
                    for i=1,8 do data.PlateLines[i] = CreateBorder(root, COLORS.Gold, 6) end
                    for i=1,4 do data.PlateCornerFill[i] = CreateBorder(root, COLORS.GoldDim, 4) end
                    for i=1,4 do
                        data.StatusOuter[i] = CreateBorder(root, COLORS.Gold, 6)
                        data.StatusInner[i] = CreateBorder(root, COLORS.Gray, 7)
                    end
                    for i=1,22 do data.Arc[i] = CreateBorder(root, COLORS.Gold, 2) end
                    data.SnapLine = CreateBorder(parent, COLORS.Gold, 1)
                    if not data.PlateBGCore or not data.PlateBGMid or not data.PlateTopGlow or not data.PlateBottomShade or not data.TitleText or
                       not data.DistanceText or not data.DistanceTextBack or not data.SnapLine then
                        if data.SnapLine and data.SnapLine.Widget then DestroyWidget(data.SnapLine.Widget) end
                        if data.DistanceText and data.DistanceText.Widget then DestroyWidget(data.DistanceText.Widget) end
                        if data.DistanceTextBack and data.DistanceTextBack.Widget then DestroyWidget(data.DistanceTextBack.Widget) end
                        DestroyWidget(root)
                        return nil
                    end
                    ClearVisionV2.EnemyWidgets[key] = data
                    return data
                end
                local function LayoutEnemy(data, s, displayName)
                    if not data then return end
                    local function X(v) return v*s end
                    local function Y(v) return v*s end
                    pcall(function() data.RootSlot:SetSize(V2(REF_W*s, REF_H*s)) end)
                    local arcIndex = 1
                    local cx, cy = 343, 550
                    local rx, ry = 195.5, 356.0
                    local function drawTaperedArc(a0, a1, segments)
                        local px,py=nil,nil
                        for i=0,segments do
                            local t=i/segments
                            local a=a0+(a1-a0)*t
                            local xx=cx+math.cos(a)*rx
                            local yy=cy+math.sin(a)*ry
                            if px then
                                local mid=(i-0.5)/segments
                                local bell=math.sin(math.pi*mid)
                                if bell<0 then bell=0 end
                                local thin=Clamp(2.4*s,1.0,1.8)
                                local thick=Clamp(12.5*s,3.0,6.0)
                                local thickness=thin+(thick-thin)*(bell^1.45)
                                SetLine(data.Arc[arcIndex],X(px),Y(py),X(xx),Y(yy),thickness)
                                arcIndex=arcIndex+1
                            end
                            px,py=xx,yy
                        end
                    end
                    drawTaperedArc(math.pi*0.56,math.pi*1.44,7)
                    drawTaperedArc(-math.pi*0.44,math.pi*0.44,7)
                    local innerRX,innerRY=166.0,296.0
                    local function miniBracket(centerA, slot)
                        local d=math.pi*0.030
                        local p={}
                        for j=-1,1 do
                            local a=centerA+j*d
                            p[#p+1]={cx+math.cos(a)*innerRX,cy+math.sin(a)*innerRY}
                        end
                        local t=Clamp(7.0*s,1.6,3.8)
                        SetLine(data.Arc[slot],X(p[1][1]),Y(p[1][2]),X(p[2][1]),Y(p[2][2]),t)
                        SetLine(data.Arc[slot+1],X(p[2][1]),Y(p[2][2]),X(p[3][1]),Y(p[3][2]),t)
                    end
                    miniBracket(math.pi*0.84,15)
                    miniBracket(math.pi*1.16,17)
                    miniBracket(-math.pi*0.16,19)
                    miniBracket(math.pi*0.16,21)
                    displayName=tostring(displayName or "ENEMY")
                    local nameLen=#displayName
                    pcall(function() if utf8 and utf8.len then nameLen=utf8.len(displayName) or nameLen end end)
                    if nameLen < 1 then nameLen=1 end
                    local maxPlateW=420.0
                    local minPlateW=118.0
                    local padding=24.0
                    local nameFont=Clamp(58*s,13,44)
                    local estimated=nameLen*nameFont*0.60
                    if estimated+padding>maxPlateW then
                        nameFont=math.max(9.0,(maxPlateW-padding)/(nameLen*0.60))
                        estimated=nameLen*nameFont*0.60
                    end
                    local plateW=Clamp(estimated+padding,minPlateW,maxPlateW)
                    local plateH=Clamp(nameFont*1.50,28,64)
                    local q=Clamp(28*s,7,21)
                    local gap=Clamp(8*s,3,8)
                    local statusW=q*4+gap*3
                    local headLocalY=REF_BODY_TOP*s
                    local bodyGap=Clamp(18*s,8,18)
                    local statusGap=Clamp(7*s,3,8)
                    local statusY=headLocalY-bodyGap-q
                    local plateY=statusY-statusGap-plateH
                    local plateCX=X(343)
                    local plateX=plateCX-plateW*0.5
                    local cut=Clamp(plateH*0.24,6,16)
                    local pts={
                        {plateX+cut,plateY},
                        {plateX+plateW-cut,plateY},
                        {plateX+plateW,plateY+cut},
                        {plateX+plateW,plateY+plateH-cut},
                        {plateX+plateW-cut,plateY+plateH},
                        {plateX+cut,plateY+plateH},
                        {plateX,plateY+plateH-cut},
                        {plateX,plateY+cut},
                    }
                    SetRect(data.PlateBGCore,plateX+cut,plateY,math.max(1,plateW-cut*2),plateH)
                    SetRect(data.PlateBGMid,plateX,plateY+cut,plateW,math.max(1,plateH-cut*2))
                    local bandInset=math.max(2.0,cut*0.60)
                    local bandW=math.max(1,plateW-bandInset*2)
                    local bandH=math.max(1,plateH*0.18)
                    SetRect(data.PlateTopGlow,plateX+bandInset,plateY+plateH*0.12,bandW,bandH)
                    SetRect(data.PlateBottomShade,plateX+bandInset,plateY+plateH*0.70,bandW,bandH)
                    local fillT=math.max(1.0,cut*1.22)
                    SetLine(data.PlateCornerFill[1],plateX,plateY+cut,plateX+cut,plateY,fillT)
                    SetLine(data.PlateCornerFill[2],plateX+plateW-cut,plateY,plateX+plateW,plateY+cut,fillT)
                    SetLine(data.PlateCornerFill[3],plateX+plateW,plateY+plateH-cut,plateX+plateW-cut,plateY+plateH,fillT)
                    SetLine(data.PlateCornerFill[4],plateX+cut,plateY+plateH,plateX,plateY+plateH-cut,fillT)
                    local textPad=math.max(6.0,cut*0.60)
                    SetRect(data.TitleText,plateX+textPad,plateY+2,plateW-textPad*2,plateH-4)
                    SetFontSize(data.TitleText.Widget,nameFont)
                    -- weapon plate under name (black box + white text)
                    if data.WeaponPlateBG and data.WeaponText then
                        local wpnH = math.max(14, plateH * 0.85)
                        local wpnY = plateY + plateH + Clamp(4*s, 2, 6)
                        local wpnW = plateW * 0.92
                        local wpnX = plateX + (plateW - wpnW) * 0.5
                        SetRect(data.WeaponPlateBG, wpnX, wpnY, wpnW, wpnH)
                        SetRect(data.WeaponText, wpnX+textPad, wpnY+1, wpnW-textPad*2, wpnH-2)
                        SetFontSize(data.WeaponText.Widget, math.max(11, nameFont * 0.85))
                    end
                    for i=1,8 do
                        local a=pts[i]
                        local b=pts[(i%8)+1]
                        SetLine(data.PlateLines[i],a[1],a[2],b[1],b[2],Clamp(3.1*s,1.2,2.8))
                    end
                    local statusX=plateCX-statusW*0.5
                    for i=1,4 do
                        local bx=statusX+(i-1)*(q+gap)
                        SetRect(data.StatusOuter[i],bx,statusY,q,q)
                        local inset=math.max(2,q*0.14)
                        SetRect(data.StatusInner[i],bx+inset,statusY+inset,q-inset*2,q-inset*2)
                    end
                    data.LastScale=s
                    data._VisName=nil
                    data._VisBracket=nil
                    data._VisHealth=nil
                end
                local function UpdateHealthSegments(data, pct, isAI)
                    if not data then return end
                    local themeColor=COLORS.BloodRedBright
                    local progress=math.max(0,math.min(1,pct or 0))*4.0
                    for i=1,4 do
                        local c
                        if progress>=i then c=themeColor
                        elseif progress>(i-1) then c=COLORS.White
                        else c=COLORS.Gray end
                        SetBorderColor(data.StatusInner[i],c)
                    end
                end
                function ClearVisionV2.RemoveEnemy(key)
                    local data = ClearVisionV2.EnemyWidgets[key]
                    if data then
                        if data.Root then DestroyWidget(data.Root) end
                        if data.SnapLine and data.SnapLine.Widget then DestroyWidget(data.SnapLine.Widget) end
                        if data.DistanceText and data.DistanceText.Widget then DestroyWidget(data.DistanceText.Widget) end
                        if data.DistanceTextBack and data.DistanceTextBack.Widget then DestroyWidget(data.DistanceTextBack.Widget) end
                    end
                    ClearVisionV2.EnemyWidgets[key]=nil
                    ClearVisionV2.EnemyCache[key]=nil
                    ClearVisionV2.EnemyMeta[key]=nil
                    ClearVisionV2._ProjectionCache[key]=nil
                end
                local function CreateCounterOverlay()
                    if ClearVisionV2.Counter and IsValid(ClearVisionV2.Counter.Root) then return ClearVisionV2.Counter end
                    if not ClearVisionV2.InitCanvas(false) then return nil end
                    local parent=ClearVisionV2.ESPCanvas
                    if not IsValid(parent) then return nil end
                    local root=NewWidget("/Script/UMG.CanvasPanel",parent)
                    if not root then return nil end
                    local slot=AddChild(parent,root,60)
                    if not slot then DestroyWidget(root) return nil end
                    local c={
                        Root=root,Slot=slot,
                        LeftOuter={},RightOuter={},LeftInner={},RightInner={},LeftCornerFill={},RightCornerFill={},Diamond={},DiamondInner={},
                        Crown={},Helmet={},
                    }
                    c.LeftCore=CreateBorder(root,COLORS.CtrBlackDim,0)
                    c.LeftMid=CreateBorder(root,COLORS.CtrBlack,0)
                    c.RightCore=CreateBorder(root,COLORS.CtrWhiteDim,0)
                    c.RightMid=CreateBorder(root,COLORS.CtrWhite,0)
                    c.LeftTopGlow=CreateBorder(root,COLORS.CtrBlackSoft,1)
                    c.LeftBottomShade=CreateBorder(root,COLORS.CtrBlackShade,1)
                    c.RightTopGlow=CreateBorder(root,COLORS.CtrWhiteSoft,1)
                    c.RightBottomShade=CreateBorder(root,COLORS.CtrWhiteShade,1)
                    c.CenterRedCore=CreateBorder(root,COLORS.CtrBlackDim,1)
                    c.CenterRedGlow=CreateBorder(root,COLORS.CtrBlackSoft,2)
                    c.CenterGreenCore=CreateBorder(root,COLORS.CtrWhiteDim,3)
                    c.CenterGreenGlow=CreateBorder(root,COLORS.CtrWhiteSoft,4)
                    c.PlayerText=CreateText(root,"PLAYER: 0",COLORS.White,20,8)
                    c.BotText=CreateText(root,"BOT: 0",COLORS.CtrBotText,20,8)
                    for i=1,8 do c.LeftOuter[i]=CreateBorder(root,COLORS.CtrBlackBright,4) end
                    for i=1,8 do c.RightOuter[i]=CreateBorder(root,COLORS.CtrWhiteBright,4) end
                    for i=1,8 do c.LeftInner[i]=CreateBorder(root,COLORS.CtrBlack,3) end
                    for i=1,8 do c.RightInner[i]=CreateBorder(root,COLORS.CtrWhite,3) end
                    for i=1,4 do c.LeftCornerFill[i]=CreateBorder(root,COLORS.CtrBlackDim,1) end
                    for i=1,4 do c.RightCornerFill[i]=CreateBorder(root,COLORS.CtrWhiteDim,1) end
                    for i=1,4 do c.Diamond[i]=CreateBorder(root,COLORS.CtrBlackBright,6) end
                    for i=1,4 do c.DiamondInner[i]=CreateBorder(root,COLORS.CtrWhiteBright,7) end
                    for i=1,7 do c.Crown[i]=CreateBorder(root,COLORS.CtrBlackBright,7) end
                    for i=1,9 do c.Helmet[i]=CreateBorder(root,COLORS.CtrWhiteBright,7) end
                    c.LeftDivider=CreateBorder(root,COLORS.CtrBlackBright,5)
                    c.RightDivider=CreateBorder(root,COLORS.CtrWhiteBright,5)
                    c.StarH=CreateBorder(root,COLORS.GoldBright,7)
                    c.StarV=CreateBorder(root,COLORS.GoldBright,7)
                    if not c.LeftCore or not c.LeftMid or not c.RightCore or not c.RightMid or
                       not c.CenterRedCore or not c.CenterGreenCore or
                       not c.PlayerText or not c.BotText or not c.StarH or not c.StarV then
                        DestroyWidget(root)
                        return nil
                    end
                    ClearVisionV2.Counter=c
                    return c
                end
                local function UpdateCounterOverlay(pc)
                    local c=CreateCounterOverlay()
                    if not c then return end
                    local viewW,viewH=GetViewportSize(pc)
                    local screenW=Clamp(viewW*0.248,208,420)
                    local screenH=Clamp(screenW*0.105,24,42)
                    local top=Clamp(viewH*0.026,10,30)
                    local topLeft=ScreenToCanvas({X=(viewW-screenW)*0.5,Y=top})
                    local bottomRight=ScreenToCanvas({X=(viewW+screenW)*0.5,Y=top+screenH})
                    local w=bottomRight.X-topLeft.X
                    local h=bottomRight.Y-topLeft.Y
                    if w<=0 or h<=0 then return end
                    pcall(function()
                        c.Slot:SetPosition(V2(topLeft.X,topLeft.Y))
                        c.Slot:SetSize(V2(w,h))
                    end)
                    local half=w*0.5
                    local centerGap=Clamp(h*0.76,14,30)
                    local leftX0,leftX1=0,half-centerGap*0.5
                    local rightX0,rightX1=half+centerGap*0.5,w
                    local bevel=Clamp(h*0.22,5,10)
                    local thick=Clamp(h*0.045,1.0,2.2)
                    local function octagon(x0,x1,y0,y1,b)
                        return {
                            {x0+b,y0},{x1-b,y0},{x1,y0+b},{x1,y1-b},
                            {x1-b,y1},{x0+b,y1},{x0,y1-b},{x0,y0+b},
                        }
                    end
                    local function drawLoop(lines,pts,t)
                        for i=1,8 do
                            local a,b=pts[i],pts[(i%8)+1]
                            SetLine(lines[i],a[1],a[2],b[1],b[2],t)
                        end
                    end
                    local leftPts=octagon(leftX0,leftX1,0,h,bevel)
                    local rightPts=octagon(rightX0,rightX1,0,h,bevel)
                    drawLoop(c.LeftOuter,leftPts,thick)
                    drawLoop(c.RightOuter,rightPts,thick)
                    local inset=Clamp(h*0.105,2.2,4.6)
                    local leftInner=octagon(leftX0+inset,leftX1-inset,inset,h-inset,math.max(2,bevel-inset*0.35))
                    local rightInner=octagon(rightX0+inset,rightX1-inset,inset,h-inset,math.max(2,bevel-inset*0.35))
                    drawLoop(c.LeftInner,leftInner,math.max(0.8,thick*0.62))
                    drawLoop(c.RightInner,rightInner,math.max(0.8,thick*0.62))
                    SetRect(c.LeftCore,leftX0+bevel,0,math.max(1,(leftX1-leftX0)-bevel*2),h)
                    SetRect(c.LeftMid,leftX0,bevel,math.max(1,leftX1-leftX0),math.max(1,h-bevel*2))
                    SetRect(c.RightCore,rightX0+bevel,0,math.max(1,(rightX1-rightX0)-bevel*2),h)
                    SetRect(c.RightMid,rightX0,bevel,math.max(1,rightX1-rightX0),math.max(1,h-bevel*2))
                    local fillT=math.max(1.0,bevel*1.28)
                    SetLine(c.LeftCornerFill[1],leftX0,bevel,leftX0+bevel,0,fillT)
                    SetLine(c.LeftCornerFill[2],leftX1-bevel,0,leftX1,bevel,fillT)
                    SetLine(c.LeftCornerFill[3],leftX1,h-bevel,leftX1-bevel,h,fillT)
                    SetLine(c.LeftCornerFill[4],leftX0+bevel,h,leftX0,h-bevel,fillT)
                    SetLine(c.RightCornerFill[1],rightX0,bevel,rightX0+bevel,0,fillT)
                    SetLine(c.RightCornerFill[2],rightX1-bevel,0,rightX1,bevel,fillT)
                    SetLine(c.RightCornerFill[3],rightX1,h-bevel,rightX1-bevel,h,fillT)
                    SetLine(c.RightCornerFill[4],rightX0+bevel,h,rightX0,h-bevel,fillT)
                    local glowXPad=bevel+inset
                    local bandH=math.max(1,h*0.18)
                    SetRect(c.LeftTopGlow,leftX0+glowXPad,h*0.10,math.max(1,(leftX1-leftX0)-glowXPad*2),bandH)
                    SetRect(c.LeftBottomShade,leftX0+glowXPad,h*0.71,math.max(1,(leftX1-leftX0)-glowXPad*2),bandH)
                    SetRect(c.RightTopGlow,rightX0+glowXPad,h*0.10,math.max(1,(rightX1-rightX0)-glowXPad*2),bandH)
                    SetRect(c.RightBottomShade,rightX0+glowXPad,h*0.71,math.max(1,(rightX1-rightX0)-glowXPad*2),bandH)
                    local cx,cy=half,h*0.5
                    local diamondR=h*0.60
                    local innerR=diamondR*0.58
                    local d={{cx,cy-diamondR},{cx+diamondR,cy},{cx,cy+diamondR},{cx-diamondR,cy}}
                    local di={{cx,cy-innerR},{cx+innerR,cy},{cx,cy+innerR},{cx-innerR,cy}}
                    for i=1,4 do SetLine(c.Diamond[i],d[i][1],d[i][2],d[(i%4)+1][1],d[(i%4)+1][2],math.max(thick,1.1)) end
                    for i=1,4 do SetLine(c.DiamondInner[i],di[i][1],di[i][2],di[(i%4)+1][1],di[(i%4)+1][2],math.max(thick*0.78,1.0)) end
                    SetRect(c.CenterRedCore,cx-diamondR*0.38,cy-diamondR*0.68,diamondR*0.76,diamondR*1.36)
                    SetRect(c.CenterRedGlow,cx-diamondR*0.26,cy-diamondR*0.50,diamondR*0.52,diamondR*0.38)
                    SetRect(c.CenterGreenCore,cx-innerR*0.34,cy-innerR*0.62,innerR*0.68,innerR*1.24)
                    SetRect(c.CenterGreenGlow,cx-innerR*0.20,cy-innerR*0.40,innerR*0.40,innerR*0.28)
                    SetBorderColor(c.CenterRedCore,COLORS.CtrBlackDim)
                    SetBorderColor(c.CenterRedGlow,COLORS.CtrBlackSoft)
                    SetBorderColor(c.CenterGreenCore,COLORS.CtrWhiteDim)
                    SetBorderColor(c.CenterGreenGlow,COLORS.CtrWhiteSoft)
                    SetLine(c.StarH,cx-h*0.10,cy,cx+h*0.10,cy,math.max(1.0,thick*0.80))
                    SetLine(c.StarV,cx,cy-h*0.14,cx,cy+h*0.14,math.max(1.0,thick*0.80))
                    if c.StarH then SetVisible(c.StarH.Widget,false) end
                    if c.StarV then SetVisible(c.StarV.Widget,false) end
                    local lcx=leftX0+(leftX1-leftX0)*0.14
                    local ly=cy
                    local rw=h*0.23
                    local rh=h*0.24
                    local crownPts={
                        {lcx-rw,ly+rh*0.55},{lcx-rw*0.72,ly-rh*0.55},{lcx-rw*0.18,ly+rh*0.02},
                        {lcx,ly-rh*0.78},{lcx+rw*0.20,ly+rh*0.02},{lcx+rw*0.72,ly-rh*0.55},{lcx+rw,ly+rh*0.55}
                    }
                    for i=1,6 do SetLine(c.Crown[i],crownPts[i][1],crownPts[i][2],crownPts[i+1][1],crownPts[i+1][2],math.max(1,thick*1.05)) end
                    SetLine(c.Crown[7],lcx-rw,ly+rh*0.70,lcx+rw,ly+rh*0.70,math.max(1,thick*1.05))
                    local rcx=rightX1-(rightX1-rightX0)*0.14
                    local topY=ly-rh*0.75
                    local botY=ly+rh*0.75
                    local hw=rw*0.92
                    local hp={
                        {rcx-hw,ly-rh*0.40},{rcx-hw*0.62,topY},{rcx,topY-rh*0.10},{rcx+hw*0.62,topY},
                        {rcx+hw,ly-rh*0.40},{rcx+hw*0.76,botY},{rcx+hw*0.18,ly+rh*0.28},
                        {rcx,botY},{rcx-hw*0.18,ly+rh*0.28},{rcx-hw*0.76,botY}
                    }
                    for i=1,9 do SetLine(c.Helmet[i],hp[i][1],hp[i][2],hp[i+1][1],hp[i+1][2],math.max(1,thick*1.0)) end
                    local leftDivX=leftX0+(leftX1-leftX0)*0.25
                    local rightDivX=rightX1-(rightX1-rightX0)*0.25
                    SetLine(c.LeftDivider,leftDivX,h*0.20,leftDivX,h*0.80,math.max(1,thick*0.85))
                    SetLine(c.RightDivider,rightDivX,h*0.20,rightDivX,h*0.80,math.max(1,thick*0.85))
                    local font=Clamp(h*0.42,10,19)
                    SetRect(c.PlayerText,leftDivX+h*0.12,h*0.12,(leftX1-leftDivX)-h*0.20,h*0.76)
                    SetRect(c.BotText,rightX0+h*0.12,h*0.12,(rightDivX-rightX0)-h*0.20,h*0.76)
                    SetFontSize(c.PlayerText.Widget,font)
                    SetFontSize(c.BotText.Widget,font)
                    SetFontBold(c.PlayerText.Widget)
                    SetFontBold(c.BotText.Widget)
                    SetTextColor(c.PlayerText.Widget,COLORS.White)
                    SetTextColor(c.BotText.Widget,COLORS.CtrBotText)
                    SetTextValue(c.PlayerText,"PLAYER: "..tostring(ClearVisionV2.RealEnemyCount or 0))
                    SetTextValue(c.BotText,"BOT: "..tostring(ClearVisionV2.BotEnemyCount or 0))
                end
                local function AppendPawnCollection(out, seen, collection)
                    if collection==nil then return end
                    local addedByArray=false
                    pcall(function()
                        if type(collection.Num)=="function" and type(collection.Get)=="function" then
                            local n=tonumber(collection:Num()) or 0
                            for i=0,n-1 do
                                local pawn=collection:Get(i)
                                if IsValid(pawn) and not seen[pawn] then
                                    seen[pawn]=true
                                    out[#out+1]=pawn
                                end
                            end
                            addedByArray=true
                        end
                    end)
                    if addedByArray then return end
                    pcall(function()
                        for _,pawn in pairs(collection) do
                            if IsValid(pawn) and not seen[pawn] then
                                seen[pawn]=true
                                out[#out+1]=pawn
                            end
                        end
                    end)
                end
                local function CollectPlayerPawns()
                    local out,seen={},{}
                    pcall(function()
                        if Game and Game.GetAllPlayerPawns then
                            AppendPawnCollection(out,seen,Game:GetAllPlayerPawns())
                        end
                    end)
                    pcall(function()
                        if GameplayData and GameplayData.GetAllPlayerCharacters then
                            AppendPawnCollection(out,seen,GameplayData.GetAllPlayerCharacters())
                        end
                    end)
                    pcall(function()
                        if GameplayData and GameplayData.GameCharacters then
                            AppendPawnCollection(out,seen,GameplayData.GameCharacters)
                        end
                    end)
                    return out
                end
                function ClearVisionV2.RefreshEnemies()
                    if not ClearVisionV2.Active then return false end
                    local pc = GetController()
                    local me = GetLocalPawn(pc)
                    if not IsValid(pc) or not IsValid(me) then return false end
                    local myTeam = GetTeamID(me)
                    local myLoc = GetActorLocation(me)
                    if not myLoc then return false end
                    local pawns=CollectPlayerPawns()
                    if type(pawns)~="table" then return false end
                    local candidates = {}
                    local seen = {}
                    pcall(function()
                        for _,pawn in pairs(pawns) do
                            if IsValid(pawn) and pawn ~= me and IsAlive(pawn) then
                                local team=GetTeamID(pawn)
                                local sameTeam=false
                                if myTeam~=nil and team~=nil then
                                    local myNum,teamNum=tonumber(myTeam),tonumber(team)
                                    if myNum and teamNum then
                                        sameTeam=(myNum>0 and teamNum>0 and myNum==teamNum)
                                    else
                                        sameTeam=(tostring(myTeam)~="" and tostring(team)~="" and tostring(team)==tostring(myTeam))
                                    end
                                end
                                if not sameTeam then
                                    local loc = GetActorLocation(pawn)
                                    local d = DistanceMeters(myLoc,loc)
                                    if d <= ClearVisionV2.RangeMeters then
                                        local key = tostring(GetPlayerKey(pawn) or pawn)
                                        if not seen[key] then
                                            seen[key]=true
                                            local name,resolved=GetPlayerName(pawn)
                                            local bot=IsAI(pawn)
                                            local tid=0
                                            pcall(function()
                                                if type(pawn.GetTeamID)=="function" then tid=tonumber(pawn:GetTeamID()) or 0
                                                elseif pawn.TeamID~=nil then tid=tonumber(pawn.TeamID) or 0 end
                                            end)
                                            candidates[#candidates+1]={Key=key,Pawn=pawn,Distance=d,Name=name,NameResolved=resolved,IsAI=bot,TeamID=tid}
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    table.sort(candidates,function(a,b) return a.Distance < b.Distance end)
                    local selected, meta = {}, {}
                    local realCount, botCount = 0,0
                    local count = math.min(#candidates,ClearVisionV2.MaxEnemies)
                    for i=1,count do
                        local c=candidates[i]
                        selected[c.Key]=c.Pawn
                        meta[c.Key]={Name=c.Name,NameResolved=c.NameResolved,IsAI=c.IsAI,TeamID=c.TeamID or 0}
                        if c.IsAI then botCount=botCount+1 else realCount=realCount+1 end
                    end
                    local stale={}
                    for key in pairs(ClearVisionV2.EnemyCache) do
                        if selected[key]==nil or selected[key]~=ClearVisionV2.EnemyCache[key] then stale[#stale+1]=key end
                    end
                    for _,key in ipairs(stale) do ClearVisionV2.RemoveEnemy(key) end
                    local countChanged=(ClearVisionV2.RealEnemyCount~=realCount) or (ClearVisionV2.BotEnemyCount~=botCount)
                    ClearVisionV2.EnemyCache=selected
                    ClearVisionV2.EnemyMeta=meta
                    ClearVisionV2.RealEnemyCount=realCount
                    ClearVisionV2.BotEnemyCount=botCount
                    if CV2Flag("EspV2Counter", true) and (countChanged or not ClearVisionV2.Counter) then
                        UpdateCounterOverlay(pc)
                    end
                    return true
                end
                local function GetCameraContext(pc)
                    if not IsValid(pc) then return nil,nil end
                    local camLoc,camYaw=nil,nil
                    local mgr=nil
                    pcall(function()
                        if pc.GetPlayerCameraManager then mgr=pc:GetPlayerCameraManager() end
                        if not IsValid(mgr) then mgr=pc.PlayerCameraManager end
                    end)
                    if IsValid(mgr) then
                        pcall(function() if mgr.GetCameraLocation then camLoc=mgr:GetCameraLocation() end end)
                        pcall(function()
                            if mgr.GetCameraRotation then
                                local r=mgr:GetCameraRotation()
                                if r and r.Yaw~=nil then camYaw=math.rad(r.Yaw) end
                            end
                        end)
                    end
                    if camYaw==nil then
                        pcall(function()
                            if pc.GetControlRotation then
                                local r=pc:GetControlRotation()
                                if r and r.Yaw~=nil then camYaw=math.rad(r.Yaw) end
                            end
                        end)
                    end
                    if not camLoc then
                        local pawn=GetLocalPawn(pc)
                        camLoc=GetActorLocation(pawn)
                    end
                    return camLoc,camYaw
                end
                local function CanvasBounds(viewW,viewH)
                    local a=ScreenToCanvas({X=0,Y=0})
                    local b=ScreenToCanvas({X=viewW,Y=viewH})
                    return math.min(a.X,b.X),math.max(a.X,b.X),math.min(a.Y,b.Y),math.max(a.Y,b.Y)
                end
                local function IsCanvasOnScreen(p,viewW,viewH,margin,bounds)
                    if not p then return false end
                    margin=margin or 2
                    local minX,maxX,minY,maxY
                    if bounds then
                        minX,maxX,minY,maxY=bounds[1],bounds[2],bounds[3],bounds[4]
                    else
                        minX,maxX,minY,maxY=CanvasBounds(viewW,viewH)
                    end
                    return p.X>=minX+margin and p.X<=maxX-margin and p.Y>=minY+margin and p.Y<=maxY-margin
                end
                local function Get360Angle(pc,worldLoc,centerCanvas,camLoc,camYaw)
                    if not worldLoc or not centerCanvas then return nil end
                    local pix=V2(0,0)
                    local projected=false
                    pcall(function()
                        local res=pc:ProjectWorldLocationToScreen(worldLoc,pix,true)
                        projected=(res==true or res==1)
                    end)
                    if projected then
                        local cp=ScreenToCanvas(pix)
                        local dx,dy=cp.X-centerCanvas.X,cp.Y-centerCanvas.Y
                        if math.abs(dx)>0.05 or math.abs(dy)>0.05 then
                            return (math.atan2 and math.atan2(dy,dx)) or math.atan(dy,dx)
                        end
                    end
                    if not camLoc or camYaw==nil then camLoc,camYaw=GetCameraContext(pc) end
                    if not camLoc or camYaw==nil then return nil end
                    local dx=(worldLoc.X or 0)-(camLoc.X or 0)
                    local dy=(worldLoc.Y or 0)-(camLoc.Y or 0)
                    local cy,sy=math.cos(camYaw),math.sin(camYaw)
                    local forward=dx*cy+dy*sy
                    local right=-dx*sy+dy*cy
                    if math.abs(forward)<0.001 and math.abs(right)<0.001 then return nil end
                    return (math.atan2 and math.atan2(-forward,right)) or math.atan(-forward,right)
                end
                local function GetEdgePosition(angle,centerCanvas,viewW,viewH,margin,bounds)
                    if angle==nil then return nil end
                    local minX,maxX,minY,maxY
                    if bounds then
                        minX,maxX,minY,maxY=bounds[1],bounds[2],bounds[3],bounds[4]
                    else
                        minX,maxX,minY,maxY=CanvasBounds(viewW,viewH)
                    end
                    margin=margin or 42
                    local halfW=math.max(8,math.min(centerCanvas.X-minX,maxX-centerCanvas.X)-margin)
                    local halfH=math.max(8,math.min(centerCanvas.Y-minY,maxY-centerCanvas.Y)-margin)
                    local dx,dy=math.cos(angle),math.sin(angle)
                    local ax,ay=math.abs(dx),math.abs(dy)
                    local tx=ax>0.0001 and halfW/ax or 1e9
                    local ty=ay>0.0001 and halfH/ay or 1e9
                    local t=math.min(tx,ty)
                    return {X=centerCanvas.X+dx*t,Y=centerCanvas.Y+dy*t}
                end
                local function PlaceDistanceText(data,text,font,x,y,color)
                    if not data or not data.DistanceText or not data.DistanceTextBack then return end
                    text=tostring(text or "--m")
                    font=Clamp(font or 18,13,42)
                    local width=Clamp(#text*font*0.72+12,46,180)
                    local height=Clamp(font*1.35,24,58)
                    local drawX=x-width*0.5
                    local drawY=y-height*0.5
                    SetRect(data.DistanceTextBack,drawX+1.0,drawY+1.0,width,height)
                    SetRect(data.DistanceText,drawX,drawY,width,height)
                    if not data.LastDistanceAppliedFont or math.abs(data.LastDistanceAppliedFont-font) > 0.49 then
                        SetFontSize(data.DistanceTextBack.Widget,font)
                        SetFontSize(data.DistanceText.Widget,font)
                        data.LastDistanceAppliedFont=font
                    end
                    if data.LastDistanceRenderedText ~= text then
                        SetTextValue(data.DistanceTextBack,text)
                        SetTextValue(data.DistanceText,text)
                        data.LastDistanceRenderedText=text
                    end
                    SetDistanceVisible(data,true)
                end
                function ClearVisionV2.Update()
                    if not CV2AnyFeatureOn() then
                        if ClearVisionV2.Active then ClearVisionV2.Stop() end
                        return false
                    end
                    if not ClearVisionV2.Active then return false end
                    if not ClearVisionV2.InitCanvas(false) then return false end
                    local pc=GetController()
                    local me=GetLocalPawn(pc)
                    if not IsValid(pc) or not IsValid(me) then return false end
                    ClearVisionV2._FrameSerial=(ClearVisionV2._FrameSerial or 0)+1
                    local frameSerial=ClearVisionV2._FrameSerial
                    local needWidgets = CV2Flag("EspV2Enabled", false) or CV2Flag("EspV2SnapLine", false)
                    if frameSerial == 1 or (frameSerial % (ClearVisionV2._TransformEveryNFrames or 6)) == 0 then
                        ClearVisionV2.UpdateCanvasTransform(pc)
                    end
                    if CV2Flag("EspV2Counter", true) then
                        if not (ClearVisionV2.Counter and IsValid(ClearVisionV2.Counter.Root))
                            or (frameSerial % (ClearVisionV2._CounterEveryNFrames or 6)) == 0 then
                            ClearVisionV2.UpdateCanvasTransform(pc)
                            UpdateCounterOverlay(pc)
                        end
                        if ClearVisionV2.Counter and ClearVisionV2.Counter.Root and ClearVisionV2._CounterVisible ~= true then
                            SetVisible(ClearVisionV2.Counter.Root,true)
                            ClearVisionV2._CounterVisible=true
                        end
                    elseif ClearVisionV2.Counter and ClearVisionV2.Counter.Root and ClearVisionV2._CounterVisible ~= false then
                        SetVisible(ClearVisionV2.Counter.Root,false)
                        ClearVisionV2._CounterVisible=false
                    end
                    if not needWidgets then
                        for _, data in pairs(ClearVisionV2.EnemyWidgets) do
                            if data then
                                SetRootVisible(data, false)
                                if data.SnapLine then SetSnapVisible(data, false) end
                                SetDistanceVisible(data, false)
                            end
                        end
                    end
                    local myLoc=GetActorLocation(me)
                    if not myLoc then return false end
                    local viewW,viewH=GetViewportSize(pc)
                    local topOrigin=ScreenToCanvas({X=viewW*0.5,Y=0})
                    local centerCanvas=ScreenToCanvas({X=viewW*0.5,Y=viewH*0.5})
                    local frameBounds={CanvasBounds(viewW,viewH)}
                    local camLoc,camYaw=GetCameraContext(pc)
                    local camCos,camSin=nil,nil
                    if camYaw~=nil then camCos,camSin=math.cos(camYaw),math.sin(camYaw) end
                    for key,character in pairs(ClearVisionV2.EnemyCache) do
                        if not IsValid(character) or not IsAlive(character) then
                            ClearVisionV2.RemoveEnemy(key)
                        else
                            local headLoc,feetLoc=GetCharacterBounds(character)
                            local worldLoc=nil
                            if headLoc and feetLoc then
                                worldLoc={
                                    X=((headLoc.X or 0)+(feetLoc.X or 0))*0.5,
                                    Y=((headLoc.Y or 0)+(feetLoc.Y or 0))*0.5,
                                    Z=((headLoc.Z or 0)+(feetLoc.Z or 0))*0.5,
                                }
                            end
                            local data=ClearVisionV2.EnemyWidgets[key]
                            if needWidgets and not data then data=CreateEnemyWidget(key) end
                            if needWidgets and data and headLoc and feetLoc and worldLoc then
                                local meta=ClearVisionV2.EnemyMeta[key] or {}
                                local isAI=meta.IsAI==true
                                local tid=(meta.TeamID or 0)
                                if data.LastThemeAI~=isAI or data.LastThemeTeam~=tid then
                                    ApplyEnemyTheme(data,isAI,tid)
                                    data.LastThemeAI=isAI
                                    data.LastThemeTeam=tid
                                end
                                local themeColor=((tid % 2)==1 or tid==0) and COLORS.BloodRedBright or COLORS.White
                                local proj=ClearVisionV2._ProjectionCache[key]
                                if not proj then proj={Head={},Feet={}} ClearVisionV2._ProjectionCache[key]=proj end
                                local headOK,head=ProjectToCanvas(pc,headLoc,proj.Head)
                                local feetOK,feet=ProjectToCanvas(pc,feetLoc,proj.Feet)
                                local headInside=headOK and IsCanvasOnScreen(head,viewW,viewH,0,frameBounds)
                                local feetInside=feetOK and IsCanvasOnScreen(feet,viewW,viewH,0,frameBounds)
                                local bodyH=(headOK and feetOK and head and feet) and (feet.Y-head.Y) or nil
                                local inFront=true
                                if camLoc and camYaw~=nil and worldLoc then
                                    local dx=(worldLoc.X or 0)-(camLoc.X or 0)
                                    local dy=(worldLoc.Y or 0)-(camLoc.Y or 0)
                                    inFront=(dx*(camCos or math.cos(camYaw))+dy*(camSin or math.sin(camYaw)))>0
                                end
                                local onScreen=inFront and headInside and feetInside and bodyH and bodyH>12 and bodyH<3000
                                local lineOnScreen=inFront and headInside
                                local distance=DistanceMeters(myLoc,worldLoc)
                                local rounded=math.max(0,math.floor(distance+0.5))
                                if data and data.LastDistanceRounded ~= rounded then
                                    data.LastDistanceRounded=rounded
                                    data.LastDistanceText=tostring(rounded).."m"
                                end
                                local distText=(data and data.LastDistanceText) or (tostring(rounded).."m")
                                if onScreen then
                                    local s=bodyH/REF_BODY_SPAN
                                    local centerX=(head.X+feet.X)*0.5
                                    local rootX=centerX-(REF_W*s*0.5)
                                    local rootY=feet.Y-(REF_BODY_BOTTOM*s)
                                    local name=meta.Name
                                    if not name or name=="" then name=select(1,GetPlayerName(character)) end
                                    name=tostring(name or "ENEMY")
                                    if not data.LastScale or math.abs(data.LastScale-s)>0.025 or data.LastName~=name then
                                        LayoutEnemy(data,s,name)
                                        data.LastName=name
                                        ApplyEnemyTheme(data,isAI,meta.TeamID or 0)
                                    end
                                    if not data.LastX or math.abs(data.LastX-rootX)>0.35 or not data.LastY or math.abs(data.LastY-rootY)>0.35 then
                                        pcall(function() data.RootSlot:SetPosition(V2(rootX,rootY)) end)
                                        data.LastX,data.LastY=rootX,rootY
                                    end
                                    if data.LastRenderedName~=name then
                                        SetTextValue(data.TitleText,name)
                                        data.LastRenderedName=name
                                    end
                                    ApplyV2FeatureVisibility(data)
                                    local health=GetHealthPercent(character)
                                    if data.LastHealth==nil or math.abs(data.LastHealth-health)>0.01 or data.LastHealthAI~=isAI then
                                        UpdateHealthSegments(data,health,isAI)
                                        data.LastHealth=health
                                        data.LastHealthAI=isAI
                                    end
                                    local distFont=Clamp(60*s,13,42)
                                    local distGap=Clamp(16*s,8,16)
                                    local distanceTextColor=isAI and COLORS.BotRedText or COLORS.White
                                    if CV2Flag("EspV2Distance", true) then
                                        PlaceDistanceText(data,distText,distFont,feet.X,feet.Y+distGap+distFont*0.58,distanceTextColor)
                                    else
                                        SetDistanceVisible(data,false)
                                    end
                                    data.LastDistanceFont=distFont
                                    SetRootVisible(data,true)
                                else
                                    SetRootVisible(data,false)
                                    if data.SnapLine then SetSnapVisible(data,false) end
                                    local angle=Get360Angle(pc,worldLoc,centerCanvas,camLoc,camYaw)
                                    local edge=GetEdgePosition(angle,centerCanvas,viewW,viewH,48,frameBounds)
                                    if edge and CV2Flag("EspV2Distance", true) and CV2Flag("EspV2Offscreen", true) then
                                        local font=data.LastDistanceFont or 18
                                        local distanceTextColor=isAI and COLORS.BotRedText or COLORS.White
                                        PlaceDistanceText(data,distText,font,edge.X,edge.Y,distanceTextColor)
                                    else
                                        SetDistanceVisible(data,false)
                                    end
                                end
                                if data.SnapLine then
                                    if topOrigin and lineOnScreen and CV2Flag("EspV2SnapLine", false) then
                                        local lineCol = COLORS.GoldBright or COLORS.Gold or COLORS.White
                                        do
                                            local idx = tonumber(_G.GTLMODConfig and _G.GTLMODConfig.EspLineColor) or 6
                                            local pal = {
                                                Color(0.02, 0.02, 0.02, 1.0),
                                                Color(0.95, 0.95, 0.95, 1.0),
                                                Color(1.00, 0.12, 0.12, 1.0),
                                                Color(0.12, 0.90, 0.18, 1.0),
                                                Color(0.20, 0.45, 1.00, 1.0),
                                                Color(1.00, 0.85, 0.15, 1.0),
                                            }
                                            if idx < 1 then idx = 1 end
                                            if idx > 6 then idx = 6 end
                                            lineCol = pal[idx] or lineCol
                                        end
                                        SetBorderColor(data.SnapLine, lineCol)
                                        SetLine(data.SnapLine,topOrigin.X,topOrigin.Y,head.X,head.Y,2.0)
                                        SetSnapVisible(data,true)
                                    else
                                        SetSnapVisible(data,false)
                                    end
                                end
                            elseif data then
                                SetRootVisible(data,false)
                                if data.SnapLine then SetSnapVisible(data,false) end
                                SetDistanceVisible(data,false)
                            end
                        end
                    end
                    return true
                end
                function ClearVisionV2.RemoveTimers()
                    ClearVisionV2._TimerGeneration=(ClearVisionV2._TimerGeneration or 0)+1
                    local owner = ClearVisionV2.TimerOwner
                    if IsValid(owner) then
                        if ClearVisionV2.ScanTimer then pcall(function() owner:RemoveGameTimer(ClearVisionV2.ScanTimer) end) end
                        if ClearVisionV2.DrawTimer then pcall(function() owner:RemoveGameTimer(ClearVisionV2.DrawTimer) end) end
                    end
                    ClearVisionV2.ScanTimer=nil
                    ClearVisionV2.DrawTimer=nil
                    ClearVisionV2.TimerOwner=nil
                end
                function ClearVisionV2.Stop()
                    ClearVisionV2.Active=false
                    ClearVisionV2.RemoveTimers()
                    for key,data in pairs(ClearVisionV2.EnemyWidgets) do
                        if data then
                            if data.Root then DestroyWidget(data.Root) end
                            if data.SnapLine and data.SnapLine.Widget then DestroyWidget(data.SnapLine.Widget) end
                            if data.DistanceText and data.DistanceText.Widget then DestroyWidget(data.DistanceText.Widget) end
                            if data.DistanceTextBack and data.DistanceTextBack.Widget then DestroyWidget(data.DistanceTextBack.Widget) end
                        end
                        ClearVisionV2.EnemyWidgets[key]=nil
                    end
                    if ClearVisionV2.Counter and ClearVisionV2.Counter.Root then DestroyWidget(ClearVisionV2.Counter.Root) end
                    ClearVisionV2.Counter=nil
                    ClearVisionV2.EnemyCache={}
                    ClearVisionV2.EnemyMeta={}
                    ClearVisionV2._ProjectionCache={}
                    ClearVisionV2.RealEnemyCount=0
                    ClearVisionV2.BotEnemyCount=0
                    ClearVisionV2._FrameSerial=0
                    ClearVisionV2._CounterVisible=nil
                    ClearVisionV2.Controller=nil
                    ClearVisionV2.LocalPawn=nil
                    ClearVisionV2.ESPCanvas=nil
                    ClearVisionV2._SessionWorld=nil
                    ClearVisionV2._SessionController=nil
                    ClearVisionV2._SessionPawn=nil
                    ClearVisionV2._SessionCanvas=nil
                    local retryOwner=ClearVisionV2.StartRetryOwner
                    local retryTimer=ClearVisionV2.StartRetryTimer
                    ClearVisionV2.StartRetryOwner=nil
                    ClearVisionV2.StartRetryTimer=nil
                    if retryOwner and retryTimer and type(retryOwner.RemoveGameTimer)=="function" then
                        pcall(function() retryOwner:RemoveGameTimer(retryTimer) end)
                    end
                    return true
                end
                function ClearVisionV2.Start()
                    if not CV2AnyFeatureOn() then return false end
                    if ClearVisionV2.Active and ClearVisionV2.ScanTimer and ClearVisionV2.DrawTimer then return true end
                    local pc=ResolveControllerFresh() or GetController()
                    local me=ResolveLocalPawnFresh(pc) or GetLocalPawn(pc)
                    if not IsValid(pc) or not IsValid(me) then return false end
                    ClearVisionV2.Controller=pc
                    ClearVisionV2.LocalPawn=me
                    ClearVisionV2.ESPCanvas=nil
                    if not ClearVisionV2.InitCanvas(true) then return false end
                    if type(pc.AddGameTimer)~="function" then return false end
                    ClearVisionV2.RemoveTimers()
                    ClearVisionV2.Active=true
                    ClearVisionV2.TimerOwner=pc
                    ClearVisionV2._SessionWorld=GetWorldSafe()
                    ClearVisionV2._SessionController=pc
                    ClearVisionV2._SessionPawn=me
                    ClearVisionV2._SessionCanvas=ClearVisionV2.ESPCanvas
                    ClearVisionV2._FrameSerial=0
                    ClearVisionV2._CounterVisible=nil
                    ClearVisionV2._TimerGeneration=(ClearVisionV2._TimerGeneration or 0)+1
                    local timerGeneration=ClearVisionV2._TimerGeneration
                    pcall(ClearVisionV2.RefreshEnemies)
                    pcall(ClearVisionV2.Update)
                    local ok1,t1=pcall(function()
                        return pc:AddGameTimer(ClearVisionV2.ScanInterval,true,function()
                            if ClearVisionV2.Active and ClearVisionV2._TimerGeneration==timerGeneration then
                                pcall(ClearVisionV2.RefreshEnemies)
                            end
                        end)
                    end)
                    local ok2,t2=pcall(function()
                        return pc:AddGameTimer(ClearVisionV2.DrawInterval,true,function()
                            if ClearVisionV2.Active and ClearVisionV2._TimerGeneration==timerGeneration then
                                pcall(ClearVisionV2.Update)
                            end
                        end)
                    end)
                    if ok1 and t1 then ClearVisionV2.ScanTimer=t1 end
                    if ok2 and t2 then ClearVisionV2.DrawTimer=t2 end
                    if not ClearVisionV2.ScanTimer or not ClearVisionV2.DrawTimer then
                        ClearVisionV2.Stop()
                        return false
                    end
                    return true
                end
                function ClearVisionV2.ScheduleStart(owner)
                    if not CV2AnyFeatureOn() then return false end
                    if ClearVisionV2.Active then return true end
                    if ClearVisionV2.StartRetryTimer then return false end
                    if ClearVisionV2.Start() then return true end
                    if owner and type(owner.AddGameTimer)=="function" then
                        ClearVisionV2.StartRetryOwner=owner
                        local ok,timer=pcall(function()
                            return owner:AddGameTimer(1.0,true,function()
                                if ClearVisionV2.Start() then
                                    local o=ClearVisionV2.StartRetryOwner
                                    local h=ClearVisionV2.StartRetryTimer
                                    ClearVisionV2.StartRetryOwner=nil
                                    ClearVisionV2.StartRetryTimer=nil
                                    if o and h and type(o.RemoveGameTimer)=="function" then
                                        pcall(function() o:RemoveGameTimer(h) end)
                                    end
                                end
                            end)
                        end)
                        if ok and timer then
                            ClearVisionV2.StartRetryTimer=timer
                            return false
                        end
                    end
                    return false
                end
                function ClearVisionV2.SyncEnabled()
                    if not CV2AnyFeatureOn() then
                        if ClearVisionV2.Active or ClearVisionV2.StartRetryTimer then
                            ClearVisionV2.Stop()
                        end
                        return true
                    end
                    local currentWorld=GetWorldSafe()
                    local currentPC=ResolveControllerFresh()
                    local currentPawn=ResolveLocalPawnFresh(currentPC)
                    local currentCanvas=ResolveCanvasFresh()
                    if ClearVisionV2.Active then
                        local stale=false
                        if not IsValid(ClearVisionV2.TimerOwner) then stale=true end
                        if IsValid(currentPC) and not SameRuntimeObject(ClearVisionV2._SessionController, currentPC) then stale=true end
                        if IsValid(currentPawn) and not SameRuntimeObject(ClearVisionV2._SessionPawn, currentPawn) then stale=true end
                        if IsValid(currentCanvas) and not SameRuntimeObject(ClearVisionV2._SessionCanvas, currentCanvas) then stale=true end
                        if currentWorld~=nil and ClearVisionV2._SessionWorld~=nil
                            and not SameRuntimeObject(ClearVisionV2._SessionWorld, currentWorld) then stale=true end
                        if not stale then return true end
                        ClearVisionV2._LastRestartReason="MATCH_SESSION_CHANGED"
                        ClearVisionV2.Stop()
                    end
                    if IsValid(currentPC) then ClearVisionV2.Controller=currentPC end
                    if IsValid(currentPawn) then ClearVisionV2.LocalPawn=currentPawn end
                    if IsValid(currentCanvas) then ClearVisionV2.ESPCanvas=currentCanvas end
                    return ClearVisionV2.Start()
                end
                _G.ClearVisionV2Runtime = ClearVisionV2
                _G.ClearVisionV2Start = function() return ClearVisionV2.Start() end
                _G.ClearVisionV2Stop = function() return ClearVisionV2.Stop() end
                _G.ClearVisionV2Sync = function() return ClearVisionV2.SyncEnabled() end
                _G.ClearVisionV2Update = function() return ClearVisionV2.Update() end
                _G.GetClearVisionV2Status = function()
                    local pc=ResolveControllerFresh()
                    local pawn=ResolveLocalPawnFresh(pc)
                    local canvas=ResolveCanvasFresh()
                    return {
                        Build=ClearVisionV2.Build,
                        Enabled=CV2Flag("EspV2Enabled", false),
                        Active=ClearVisionV2.Active==true,
                        Controller=IsValid(pc),
                        Pawn=IsValid(pawn),
                        Canvas=IsValid(canvas),
                        TimerOwner=IsValid(ClearVisionV2.TimerOwner),
                        EnemyCount=(ClearVisionV2.RealEnemyCount or 0)+(ClearVisionV2.BotEnemyCount or 0),
                        LastRestartReason=ClearVisionV2._LastRestartReason,
                    }
                end
            end)
            local _BoxESPCache = {}
            local function ClearAllBoxESP()
                if _BoxESPCache then for k in pairs(_BoxESPCache) do _BoxESPCache[k] = nil end end
            end
            _G.ClearAllBoxESP = ClearAllBoxESP
            _G.Tick_BoxESP = function() end
            local function ClearAllRadarMarks()
                pcall(function()
                    if _G.GTLMODState and _G.GTLMODState.EnemyMarks then
                        for _, data in pairs(_G.GTLMODState.EnemyMarks) do
                            if data.radarMark then
                                pcall(function() SafeRemoveMark(data.radarMark) end)
                                data.radarMark = nil
                            end
                        end
                    end
                end)
                pcall(function()
                    local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                    if not InGameMarkTools then return end
                    local mgr = InGameMarkTools.GetMarkDispatchManager and InGameMarkTools.GetMarkDispatchManager()
                    if mgr and mgr.ClearMarkDataByTypeID then
                        local clearType = 0
                        pcall(function()
                            local E = import("EMarkTypeIDClearType")
                            if E and E.ETC_OWNER_ONLY then clearType = E.ETC_OWNER_ONLY end
                        end)
                        pcall(mgr.ClearMarkDataByTypeID, mgr, 9999, clearType, nil)
                        pcall(mgr.ClearMarkDataByTypeID, mgr, 8888, clearType, nil)
                    end
                    if _G.GTLMODState and _G.GTLMODState.TrackedMarks then
                        local drop = {}
                        for m, meta in pairs(_G.GTLMODState.TrackedMarks) do
                            if type(meta) == "table" and (meta.id == 9999 or meta.id == 8888) then
                                drop[#drop+1] = m
                            end
                        end
                        for _, m in ipairs(drop) do
                            pcall(function()
                                if InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(m) end
                                if InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(m) end
                            end)
                            _G.GTLMODState.TrackedMarks[m] = nil
                        end
                    end
                end)
            end
            _G.ClearAllRadarMarks = ClearAllRadarMarks
            local function Tick_RadarESP()
                if not (_G.GTLMODConfig and _G.GTLMODConfig.EspRadar == true) then
                    if _G.ClearAllRadarMarks then pcall(_G.ClearAllRadarMarks)
                    elseif _G.GTLMODState and _G.GTLMODState.EnemyMarks then
                        for _, data in pairs(_G.GTLMODState.EnemyMarks) do
                            if data.radarMark then
                                pcall(function() SafeRemoveMark(data.radarMark) end)
                                data.radarMark = nil
                            end
                        end
                    end
                    return
                end
                if IsFeatureLocked and IsFeatureLocked() then return end
                pcall(InitScreenMarkSystem)
                local localPlayer = nil
                pcall(function()
                    if GetLocalPlayer then localPlayer = GetLocalPlayer() end
                end)
                if not Valid(localPlayer) then
                    pcall(function()
                        if GameplayData and GameplayData.GetLocalCharacter then
                            localPlayer = GameplayData.GetLocalCharacter()
                        end
                    end)
                end
                if not Valid(localPlayer) then return end
                local myTeam = 0
                pcall(function() myTeam = localPlayer.TeamID or (localPlayer.GetTeamID and localPlayer:GetTeamID()) or 0 end)
                _G.GTLMODState = _G.GTLMODState or {}
                _G.GTLMODState.EnemyMarks = _G.GTLMODState.EnemyMarks or {}
                local pawns = {}
                pcall(function()
                    if GameplayData and GameplayData.GetAllPlayerCharacters then
                        local list = GameplayData.GetAllPlayerCharacters()
                        if list then for _, c in pairs(list) do pawns[#pawns + 1] = c end end
                    end
                    if #pawns == 0 and GameplayData and GameplayData.GameCharacters then
                        for _, c in pairs(GameplayData.GameCharacters) do pawns[#pawns + 1] = c end
                    end
                    if #pawns == 0 and Game and Game.GetAllPlayerPawns then
                        local list = Game:GetAllPlayerPawns()
                        if list then for _, c in pairs(list) do pawns[#pawns + 1] = c end end
                    end
                end)
                local alive = {}
                local n = 0
                local maxN = (LIMITS and LIMITS.MAX_ENEMY_MARKS) or 48
                for _, enemy in ipairs(pawns) do
                    if n >= maxN then break end
                    if Valid(enemy) and enemy ~= localPlayer then
                        local team = 0
                        pcall(function() team = enemy.TeamID or (enemy.GetTeamID and enemy:GetTeamID()) or 0 end)
                        if myTeam ~= 0 and team ~= 0 and team == myTeam then goto radar_cont end
                        local dead = false
                        pcall(function()
                            if enemy.bIsDead or enemy.bDead then dead = true end
                            if enemy.HealthStatus == 2 or enemy.HealthStatus == 3 then dead = true end
                            if type(enemy.IsDead) == "function" and enemy:IsDead() then dead = true end
                        end)
                        if dead then goto radar_cont end
                        local eKey = GetSafeEnemyKey(enemy)
                        alive[eKey] = true
                        n = n + 1
                        local markData = _G.GTLMODState.EnemyMarks[eKey]
                        if not markData then
                            markData = { enemy = enemy }
                            _G.GTLMODState.EnemyMarks[eKey] = markData
                        else
                            markData.enemy = enemy
                        end
                        if markData.radarMark and markData.radarMark ~= 0 then
                        else
                            local m = SafeAddMark(8888, nil, 0, "", 4, enemy)
                            if m then markData.radarMark = m end
                        end
                        ::radar_cont::
                    end
                end
                for key, data in pairs(_G.GTLMODState.EnemyMarks) do
                    if not alive[key] and data.radarMark then
                        pcall(function() SafeRemoveMark(data.radarMark) end)
                        data.radarMark = nil
                    end
                end
            end
            _G.Tick_RadarESP = Tick_RadarESP
            local function RadarESPTickLoop()
                pcall(Tick_RadarESP)
                local tk = GetTicker and GetTicker() or nil
                if not tk then
                    local ok, t = pcall(require, "common.time_ticker")
                    if ok then tk = t end
                end
                if tk and tk.AddTimerOnce then
                    local on = _G.GTLMODConfig and _G.GTLMODConfig.EspRadar == true
                    tk.AddTimerOnce(on and 0.45 or 3.0, RadarESPTickLoop)
                end
            end
            local RJCounter = {
                Canvas = nil, RealFrame = nil, RealBg = nil, RealDot = nil, RealLabel = nil, RealText = nil,
                BotFrame = nil, BotBg = nil, BotDot = nil, BotLabel = nil, BotText = nil,
                LastRealText = "", LastBotText = "", Created = false, BotCache = {}, Enabled = true,
            }
            _G.RJCounter = RJCounter
            function RJCounter.SetEnabled(on)
                RJCounter.Enabled = false
                if RJCounter.Created then
                    local Items = { RJCounter.RealFrame, RJCounter.RealBg, RJCounter.RealDot, RJCounter.RealLabel, RJCounter.RealText,
                                    RJCounter.BotFrame, RJCounter.BotBg, RJCounter.BotDot, RJCounter.BotLabel, RJCounter.BotText }
                    for _, w in ipairs(Items) do
                        if w and Valid(w) then pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
                    end
                end
            end
            local function CounterRainbowColor(t, phase)
                phase = phase or 0
                local r = math.sin(t * 1.8 + phase) * 0.5 + 0.5
                local g = math.sin(t * 1.8 + phase + 2.094) * 0.5 + 0.5
                local b = math.sin(t * 1.8 + phase + 4.188) * 0.5 + 0.5
                local FC = safeImport("LinearColor")
                if not FC then return {R=255, G=255, B=255, A=255} end
                return FC(0.25 + r * 0.75, 0.25 + g * 0.75, 0.25 + b * 0.75, 1.0)
            end
            local function CounterGetCanvas()
                local canvas = nil
                pcall(function()
                    local T = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                    local M = T.GetMainControlBaseUI()
                    if M then
                        if M.CanvasPanel_0 and Game:IsValid(M.CanvasPanel_0) then canvas = M.CanvasPanel_0
                        elseif M.CanvasPanel_42 and Game:IsValid(M.CanvasPanel_42) then canvas = M.CanvasPanel_42 end
                    end
                end)
                return canvas
            end
            local function CounterDetectBot(Character)
                if not Valid(Character) then return nil end
                local CacheKey = nil
                pcall(function()
                    if Character.PlayerKey then CacheKey = tostring(Character.PlayerKey)
                    elseif type(Character.GetUniqueID) == "function" then CacheKey = tostring(Character:GetUniqueID()) end
                end)
                if not CacheKey then CacheKey = tostring(Character) end
                if RJCounter.BotCache[CacheKey] ~= nil then return RJCounter.BotCache[CacheKey] end
                local IsBot = false
                local Checked = false
                pcall(function()
                    if Game and type(Game.IsAI) == "function" then
                        local NativeAI = Game:IsAI(Character)
                        if NativeAI ~= nil then Checked = true; if NativeAI == true then IsBot = true end end
                    end
                    if Character.bIsAI ~= nil then Checked = true; if Character.bIsAI == true then IsBot = true end end
                    if Character.IsAI ~= nil then Checked = true; if Character.IsAI == true then IsBot = true end end
                    if type(Character.IsBot) == "function" then
                        Checked = true
                        local Result = Character:IsBot()
                        if Result == true then IsBot = true end
                    end
                    local PS = Character.PlayerState or (type(Character.GetPlayerState) == "function" and Character:GetPlayerState())
                    if Valid(PS) then
                        Checked = true
                        if PS.bIsABot == true or PS.bIsBot == true then IsBot = true end
                        if type(PS.IsBot) == "function" and PS:IsBot() then IsBot = true end
                    end
                    if not IsBot then
                        local Name = Character.PlayerName or (type(Character.GetPlayerName) == "function" and Character:GetPlayerName()) or ""
                        if Name ~= "" and (Name:find("Cobra") or Name:find("Target") or Name:find("bot_") or Name:find("b_")) then
                            IsBot = true; Checked = true
                        end
                    end
                end)
                if IsBot then RJCounter.BotCache[CacheKey] = true; return true end
                if Checked then RJCounter.BotCache[CacheKey] = false; return false end
                return nil
            end
            local function CounterCreateUI()
                if RJCounter.RealText and Valid(RJCounter.RealText) then return true end
                local canvas = CounterGetCanvas()
                if not canvas or not Game:IsValid(canvas) then return false end
                RJCounter.Canvas = canvas
                local boxW, boxH, gap = 145, 36, 8
                local framePad = 2
                local vpW, vpH = 1920, 1080
                local centerX, topY = vpW * 0.5 - (boxW * 2 + gap) * 0.5, math.floor(vpH * 0.09)
                pcall(function()
                    local GS = safeImport("GameplayStatics")
                    local pc2 = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                    if false then
                        vpW = 1920
                        vpH = 1080
                        centerX = vpW * 0.5 - (boxW * 2 + gap) * 0.5
                        topY = math.max(55, math.floor(vpH * 0.09))
                    elseif GS and pc2 and GS.GetViewportSize then
                        local sx, sy = GS.GetViewportSize(pc2)
                        if type(sx) == "number" and sx > 10 then
                            centerX = sx * 0.5 - (boxW * 2 + gap) * 0.5
                            topY = math.max(55, math.floor((sy or 1080) * 0.09))
                        elseif type(sx) == "table" and sx.X and sx.X > 10 then
                            centerX = sx.X * 0.5 - (boxW * 2 + gap) * 0.5
                            topY = math.max(55, math.floor((sx.Y or 1080) * 0.09))
                        end
                    elseif pc2 and pc2.GetViewportSize then
                        local FVec2 = _G.FVector2D or safeImport("Vector2D")
                        local vs = FVec2 and FVec2(0,0) or {X=0,Y=0}
                        pc2:GetViewportSize(vs)
                        if vs and vs.X and vs.X > 10 then
                            centerX = vs.X * 0.5 - (boxW * 2 + gap) * 0.5
                            topY = math.max(55, math.floor(vs.Y * 0.09))
                        end
                    end
                end)
                local FLC = safeImport("LinearColor")
                local FSlate = safeImport("SlateColor") or safeImport("/Script/SlateCore.SlateColor")
                if not FLC then return false end
                pcall(function()
                    RJCounter.RealFrame = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.RealFrame) then
                        RJCounter.RealFrame:SetBrushColor(FLC(1.0, 0.2, 0.2, 1.0))
                        local s = canvas:AddChildToCanvas(RJCounter.RealFrame)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX - framePad, topY - framePad)); s:SetSize(FVector2D(boxW + framePad*2, boxH + framePad*2)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(4999) end
                    end
                    RJCounter.RealBg = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.RealBg) then
                        RJCounter.RealBg:SetBrushColor(FLC(0.05, 0.02, 0.02, 0.92))
                        local s = canvas:AddChildToCanvas(RJCounter.RealBg)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX, topY)); s:SetSize(FVector2D(boxW, boxH)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5000) end
                    end
                    RJCounter.RealDot = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.RealDot) then
                        RJCounter.RealDot:SetBrushColor(FLC(1.0, 0.2, 0.2, 1.0))
                        local s = canvas:AddChildToCanvas(RJCounter.RealDot)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + 10, topY + 13)); s:SetSize(FVector2D(10, 10)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5001) end
                    end
                    RJCounter.RealLabel = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                    if Valid(RJCounter.RealLabel) then
                        RJCounter.RealLabel:SetText("REAL")
                        if FSlate then RJCounter.RealLabel:SetColorAndOpacity(FSlate(FLC(0.85, 0.85, 0.9, 1.0))) else RJCounter.RealLabel:SetColorAndOpacity(FLC(0.85, 0.85, 0.9, 1.0)) end
                        local f = RJCounter.RealLabel.Font
                        if f then f.Size = 13; RJCounter.RealLabel:SetFont(f) end
                        RJCounter.RealLabel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local s = canvas:AddChildToCanvas(RJCounter.RealLabel)
                        if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(0, 0.5)); s:SetPosition(FVector2D(centerX + 28, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
                    end
                    RJCounter.RealText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                    if Valid(RJCounter.RealText) then
                        RJCounter.RealText:SetText("0")
                        if FSlate then RJCounter.RealText:SetColorAndOpacity(FSlate(FLC(1,1,1,1))) else RJCounter.RealText:SetColorAndOpacity(FLC(1,1,1,1)) end
                        local f = RJCounter.RealText.Font
                        if f then f.Size = 20; RJCounter.RealText:SetFont(f) end
                        RJCounter.RealText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local s = canvas:AddChildToCanvas(RJCounter.RealText)
                        if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(1, 0.5)); s:SetPosition(FVector2D(centerX + boxW - 12, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
                    end
                    RJCounter.BotFrame = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.BotFrame) then
                        RJCounter.BotFrame:SetBrushColor(FLC(0.2, 1.0, 0.2, 1.0))
                        local s = canvas:AddChildToCanvas(RJCounter.BotFrame)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap - framePad, topY - framePad)); s:SetSize(FVector2D(boxW + framePad*2, boxH + framePad*2)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(4999) end
                    end
                    RJCounter.BotBg = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.BotBg) then
                        RJCounter.BotBg:SetBrushColor(FLC(0.02, 0.05, 0.02, 0.92))
                        local s = canvas:AddChildToCanvas(RJCounter.BotBg)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap, topY)); s:SetSize(FVector2D(boxW, boxH)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5000) end
                    end
                    RJCounter.BotDot = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
                    if Valid(RJCounter.BotDot) then
                        RJCounter.BotDot:SetBrushColor(FLC(0.2, 1.0, 0.2, 1.0))
                        local s = canvas:AddChildToCanvas(RJCounter.BotDot)
                        if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap + 10, topY + 13)); s:SetSize(FVector2D(10, 10)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5001) end
                    end
                    RJCounter.BotLabel = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                    if Valid(RJCounter.BotLabel) then
                        RJCounter.BotLabel:SetText("BOT")
                        if FSlate then RJCounter.BotLabel:SetColorAndOpacity(FSlate(FLC(0.85, 0.85, 0.9, 1.0))) else RJCounter.BotLabel:SetColorAndOpacity(FLC(0.85, 0.85, 0.9, 1.0)) end
                        local f = RJCounter.BotLabel.Font
                        if f then f.Size = 13; RJCounter.BotLabel:SetFont(f) end
                        RJCounter.BotLabel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local s = canvas:AddChildToCanvas(RJCounter.BotLabel)
                        if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(0, 0.5)); s:SetPosition(FVector2D(centerX + boxW + gap + 28, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
                    end
                    RJCounter.BotText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
                    if Valid(RJCounter.BotText) then
                        RJCounter.BotText:SetText("0")
                        if FSlate then RJCounter.BotText:SetColorAndOpacity(FSlate(FLC(1,1,1,1))) else RJCounter.BotText:SetColorAndOpacity(FLC(1,1,1,1)) end
                        local f = RJCounter.BotText.Font
                        if f then f.Size = 20; RJCounter.BotText:SetFont(f) end
                        RJCounter.BotText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local s = canvas:AddChildToCanvas(RJCounter.BotText)
                        if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(1, 0.5)); s:SetPosition(FVector2D(centerX + boxW + gap + boxW - 12, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
                    end
                end)
                RJCounter.Created = true
                return RJCounter.RealText ~= nil
            end
            local function GetPlayerCharacterLocal()
                local p = nil
                pcall(function() p = GameplayData.GetPlayerCharacter() end)
                return p
            end
            local function RJCounterTick()
            end
            _G.GetEnemyTargetsFromActors = function(radius)
                local result = {}
                local player = GameplayData.GetPlayerCharacter()
                if not slua.isValid(player) then return result end
                local allCharacters = {}
                if GameplayData.GetAllPlayerCharacters then
                    allCharacters = GameplayData.GetAllPlayerCharacters()
                elseif GameplayData.GameCharacters then
                    for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
                end
                local myTeam = 0
                pcall(function() myTeam = player:GetTeamID() or player.TeamID or 0 end)
                for _, actor in pairs(allCharacters) do
                    if slua.isValid(actor) and actor ~= player then
                        local isAlive = true
                        pcall(function()
                            if type(actor.IsAlive) == "function" then
                                isAlive = actor:IsAlive()
                            elseif actor.HealthStatus ~= nil then
                                isAlive = (actor.HealthStatus ~= 2)
                            elseif actor.bIsDead ~= nil then
                                isAlive = not actor.bIsDead
                            end
                        end)
                        if isAlive then
                            local teamId = -1
                            pcall(function()
                                if type(actor.GetTeamID) == "function" then teamId = actor:GetTeamID()
                                elseif actor.TeamID ~= nil then teamId = actor.TeamID end
                            end)
                            if teamId ~= myTeam then
                                local dist = 999999
                                pcall(function() dist = player:GetDistanceTo(actor) end)
                                if dist <= radius then table.insert(result, actor) end
                            end
                        end
                    end
                end
                return result
            end
            local function GetTargetBonePos(target, boneName, fallbackZ)
                local pos = nil
                if type(target.GetBonePos) == "function" then
                    pcall(function() pos = target:GetBonePos(boneName, {X=0, Y=0, Z=0}) end)
                end
                if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                    pcall(function()
                        if slua.isValid(target.Mesh) and type(target.Mesh.GetSocketLocation) == "function" then
                            pos = target.Mesh:GetSocketLocation(boneName)
                        end
                    end)
                end
                if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                    pcall(function()
                        if type(target.GetSocketLocation) == "function" then
                            pos = target:GetSocketLocation(boneName)
                        end
                    end)
                end
                if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                    pcall(function()
                        if type(target.K2_GetActorLocation) == "function" then
                            pos = target:K2_GetActorLocation()
                            if pos then pos.Z = pos.Z + (fallbackZ or 70) end
                        end
                    end)
                end
                return pos
            end
            local function TrimCache(cache, maxSize, now)
                if not cache then return end
                local count = 0
                for _ in pairs(cache) do count = count + 1 end
                if count <= maxSize then return end
                local toRemove = {}
                for k, v in pairs(cache) do
                    if type(v) == "table" and v.time and (now - v.time) > 30 then
                        table.insert(toRemove, k)
                    end
                end
                for _, k in ipairs(toRemove) do cache[k] = nil end
                count = 0
                for _ in pairs(cache) do count = count + 1 end
                if count > maxSize then
                    for k in pairs(cache) do cache[k] = nil end
                end
            end
            _G.AimTouch = function()
                if not _G.GTLMODConfig.AimTouchEnable then return end
                if not _G.GTLMODState.AimDebugErr then _G.GTLMODState.AimDebugErr = "starting" end
                local player = GameplayData.GetPlayerCharacter()
                if not slua.isValid(player) then _G.GTLMODState.AimLastFail = "no player"; return end
                local pc = player:GetPlayerControllerSafety()
                if not slua.isValid(pc) then _G.GTLMODState.AimLastFail = "no pc"; return end
                local isFiring = player.bIsWeaponFiring
                local isADS = player.bIsGunADS
                local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
                if not weapon and type(player.GetCurrentShootWeapon) == "function" then
                    weapon = player:GetCurrentShootWeapon()
                end
                local isShotgun = false
                local isSniper = false
                local currentAmmo = 1
                if slua.isValid(weapon) then
                    local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
                    local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
                    if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                        isShotgun = true
                    end
                    if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                        isSniper = true
                    end
                    if type(weapon.GetCurrentAmmo) == "function" then
                        currentAmmo = weapon:GetCurrentAmmo()
                    elseif weapon.CurrentAmmo ~= nil then
                        currentAmmo = weapon.CurrentAmmo
                    end
                end
                if _G.GTLMODState.IsAutoFiring then
                    pcall(function()
                        player.bIsWeaponFiring = false
                        if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                        if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                        local wepMgr = player.WeaponManagerComponent
                        if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
                    end)
                    _G.GTLMODState.IsAutoFiring = false
                end
                if isShotgun and currentAmmo <= 0 then _G.GTLMODState.AimLastFail = "shotgun no ammo"; return end
                local cond = 2
                local boneIdx = 1
                local speedVal = 50
                local fovVal = 30
                local maxDistMeters = 50
                local useVisCheck = _G.GTLMODConfig.AimTouchVisCheck
                local igKnock = _G.GTLMODConfig.AimTouchIgKnock
                local igBot = _G.GTLMODConfig.AimTouchIgBot
                if isShotgun then
                    cond = 2; boneIdx = 2; speedVal = 90; fovVal = 32; maxDistMeters = 30
                elseif isADS then
                    if isSniper then
                        cond = 2; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 400
                    else
                        cond = 1; boneIdx = 2; speedVal = 85; fovVal = 28; maxDistMeters = 300
                    end
                else
                    cond = 1; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 250
                end
                if cond == 1 and not isFiring then _G.GTLMODState.AimLastFail = "not firing"; return end
                do
                    local sm = tonumber(_G.GTLMODConfig and _G.GTLMODConfig.AimbotSmoothness) or 45
                    sm = math.max(40, math.min(50, sm))
                    local factor = 0.35 + (sm / 100.0) * 0.90
                    speedVal = math.floor(speedVal * factor + 0.5)
                end
                local currentMaxDist = maxDistMeters * 100
                local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
                if not enemies or #enemies == 0 then _G.GTLMODState.AimLastFail = "no enemies"; return end
                local FVector2D = GetFV2()
                local UGameplayStatics = GetUGS()
                local KismetMathLibrary = GetKML()
                if not FVector2D or not UGameplayStatics or not KismetMathLibrary then return end
                local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
                if not slua.isValid(camManager) then _G.GTLMODState.AimLastFail = "no camManager"; return end
                local camLoc = camManager:GetCameraLocation()
                if not camLoc then _G.GTLMODState.AimLastFail = "no camLoc"; return end
                local ui_util = GetUIUtil()
                if not ui_util then _G.GTLMODState.AimLastFail = "no ui_util"; return end
                local viewportSize = ui_util.GetViewportSize()
                if not viewportSize then _G.GTLMODState.AimLastFail = "no viewport"; return end
                local centerX = viewportSize.X * 0.5
                local centerY = viewportSize.Y * 0.5
                local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
                local bestTarget = nil
                local bestScore = 99999999
                local selBoneName = "head"
                do
                    local ub = tonumber(_G.GTLMODConfig and _G.GTLMODConfig.AimbotBone)
                    if ub and ub >= 1 and ub <= 4 then boneIdx = ub end
                end
                if boneIdx == 2 then selBoneName = "spine_03"
                elseif boneIdx == 3 then selBoneName = "spine_01"
                elseif boneIdx == 4 then selBoneName = "pelvis" end
                local now = os.clock()
                _G.BotStatusCache = _G.BotStatusCache or {}
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.LastCacheTrim or (now - _G.LastCacheTrim) > 15 then
                    _G.LastCacheTrim = now
                    TrimCache(_G.BotStatusCache, LIMITS.MAX_BOT_CACHE, now)
                    TrimCache(_G.AimTouchVisCache, LIMITS.MAX_VIS_CACHE, now)
                end
                for i, target in ipairs(enemies) do
                    if slua.isValid(target) then
                        pcall(function()
                            if slua.isValid(target.Mesh) then target.Mesh.MeshComponentUpdateFlag = 0 end
                        end)
                        local skip = false
                        if igKnock and target.HealthStatus == 1 then skip = true end
                        if not skip and igBot then
                            local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                            local cachedBot = _G.BotStatusCache[tId]
                            if cachedBot == nil then
                                cachedBot = false
                                if target.bIsAI == true or target.IsAI == true or target.bIsAi == true then cachedBot = true end
                                if not cachedBot then
                                    if target.AIData ~= nil or target.AIController ~= nil or target.bIsAIActor == true then cachedBot = true end
                                    if not cachedBot and target.PlayerAIType ~= nil and target.PlayerAIType ~= 0 then cachedBot = true end
                                end
                                if not cachedBot then
                                    local pState = target.PlayerState
                                    if slua.isValid(pState) then
                                        if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI then cachedBot = true end
                                        if not cachedBot then
                                            local uid = pState.Uid or pState.UID or pState.PlayerId or pState.PlayerID
                                            if uid ~= nil and (uid == 0 or uid == "0") then cachedBot = true end
                                        end
                                    end
                                end
                                if not cachedBot and type(target.IsBot) == "function" then
                                    local ok, r = pcall(function() return target:IsBot() end)
                                    if ok and r then cachedBot = true end
                                end
                                _G.BotStatusCache[tId] = cachedBot
                            end
                            if cachedBot then skip = true end
                        end
                        if not skip and useVisCheck then
                            local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                            local cacheEntry = _G.AimTouchVisCache[tId]
                            if not cacheEntry or (now - cacheEntry.time) > 0.2 then
                                local isHidden = true
                                pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                                _G.AimTouchVisCache[tId] = { hidden = isHidden, time = now }
                                cacheEntry = _G.AimTouchVisCache[tId]
                            end
                            if cacheEntry.hidden then skip = true end
                        end
                        if not skip then
                            local fallbackZ = (boneIdx == 1) and 70 or (boneIdx == 2) and 40 or (boneIdx == 3) and 20 or 0
                            local tPos = GetTargetBonePos(target, selBoneName, fallbackZ)
                            if tPos and (tPos.X ~= 0 or tPos.Y ~= 0) then
                                local screen = FVector2D()
                                local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                                if success and screen.X > 0 and screen.Y > 0 then
                                    local dx = screen.X - centerX
                                    local dy = screen.Y - centerY
                                    local distScreen = math.sqrt(dx*dx + dy*dy)
                                    if distScreen <= FOV_RADIUS then
                                        if distScreen < bestScore then
                                            bestScore = distScreen
                                            bestTarget = target
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if not slua.isValid(bestTarget) then _G.GTLMODState.AimLastFail = "no best target in FOV"; return end
                local fallbackZ2 = (boneIdx == 1) and 70 or (boneIdx == 2) and 40 or (boneIdx == 3) and 20 or 0
                local finalBonePos = GetTargetBonePos(bestTarget, selBoneName, fallbackZ2)
                if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0) then _G.GTLMODState.AimLastFail = "no final bone pos"; return end
                local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
                if not rot then _G.GTLMODState.AimLastFail = "no rot"; return end
                local currentRot = pc:GetControlRotation()
                if not currentRot then _G.GTLMODState.AimLastFail = "no currentRot"; return end
                local deltaYaw = rot.Yaw - currentRot.Yaw
                local deltaPitch = rot.Pitch - currentRot.Pitch
                if isADS then
                    local camRot = nil
                    if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
                    if camRot then
                        deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                        deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
                    end
                end
                if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
                if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
                if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
                if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
                local smoothFactor = (speedVal >= 100) and 1.0 or math.max(0.03, (speedVal / 100.0) * 0.40)
                local dist2d = math.sqrt(deltaYaw*deltaYaw + deltaPitch*deltaPitch)
                if dist2d < 5.0 then
                    local fineTuneFactor = dist2d / 5.0
                    smoothFactor = smoothFactor * (0.35 + fineTuneFactor * 0.65)
                elseif dist2d > 40.0 then
                    smoothFactor = math.min(1.0, smoothFactor * 1.4)
                end
                local pitchFactor = smoothFactor
                if isADS then
                    local absDeltaPitch = math.abs(deltaPitch)
                    if absDeltaPitch < 20 then
                        pitchFactor = math.min(1.0, smoothFactor * 2.5)
                    elseif absDeltaPitch < 45 then
                        pitchFactor = math.min(1.0, smoothFactor * 1.6)
                    else
                        pitchFactor = smoothFactor
                    end
                else
                    pitchFactor = math.min(1.0, smoothFactor * 1.2)
                end
                local finalPitch = currentRot.Pitch + (deltaPitch * pitchFactor)
                local finalYaw   = currentRot.Yaw   + (deltaYaw   * smoothFactor)
                local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
                local okRot = pcall(function() pc:SetControlRotation(finalRot, "AimTouch") end)
                if not okRot then
                    pcall(function() pc:SetControlRotation(finalRot) end)
                end
                _G.GTLMODState.AimLastFail = "OK"
                if isShotgun then
                    pcall(function()
                        local distToTarget = player:GetDistanceTo(bestTarget) / 100
                        if distToTarget <= maxDistMeters then
                            player.bIsWeaponFiring = true
                            if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                            if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                            local wepMgr = player.WeaponManagerComponent
                            if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                            local currentWep = player:GetCurrentWeapon()
                            if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then currentWep:StartFire() end
                            _G.GTLMODState.IsAutoFiring = true
                        end
                    end)
                end
            end
            _G.AppliedItemESP = _G.AppliedItemESP or {}
            _G.CachedItems = _G.CachedItems or {}
            _G.LastScanItemTime = 0
            _G._ItemDyedActors = _G._ItemDyedActors or setmetatable({}, { __mode = "k" })
            _G._ItemESP_ConsoleReady = false
            local ITEM_NAME_MAP = {
                [101001] = {"AKM", {R=255,G=80,B=80}},
                [101002] = {"M16A4", {R=255,G=200,B=80}},
                [101003] = {"SCAR-L", {R=80,G=255,B=120}},
                [101004] = {"M416", {R=80,G=180,B=255}},
                [101005] = {"Groza", {R=255,G=50,B=50}},
                [101006] = {"AUG", {R=100,G=200,B=255}},
                [101007] = {"QBZ", {R=200,G=200,B=80}},
                [101008] = {"M762", {R=255,G=120,B=60}},
                [101009] = {"Mk47", {R=255,G=150,B=50}},
                [101010] = {"G36C", {R=150,G=255,B=150}},
                [101011] = {"Mk47 Mutant", {R=255,G=140,B=40}},
                [101012] = {"ACE32", {R=255,G=100,B=100}},
                [101001002] = {"M416", {R=80,G=180,B=255}},
                [101001003] = {"SCAR-L", {R=80,G=255,B=120}},
                [101001004] = {"AKM", {R=255,G=80,B=80}},
                [101001005] = {"M16A4", {R=255,G=200,B=80}},
                [101001007] = {"Groza", {R=255,G=50,B=50}},
                [101001008] = {"AUG", {R=100,G=200,B=255}},
                [101001009] = {"QBZ", {R=200,G=200,B=80}},
                [101001021] = {"M762", {R=255,G=120,B=60}},
                [101001023] = {"Mk47 Mutant", {R=255,G=140,B=40}},
                [101001024] = {"G36C", {R=150,G=255,B=150}},
                [101001027] = {"FAMAS", {R=180,G=220,B=100}},
                [101001031] = {"ACE32", {R=255,G=100,B=100}},
                [101001032] = {"Honey Badger", {R=200,G=160,B=80}},
                [907000010] = {"M416", {R=80,G=180,B=255}},
                [102001] = {"UZI", {R=180,G=255,B=80}},
                [102002] = {"UMP45", {R=180,G=200,B=255}},
                [102003] = {"Vector", {R=255,G=80,B=200}},
                [102004] = {"Thompson", {R=200,G=150,B=80}},
                [102005] = {"Bizon", {R=150,G=200,B=150}},
                [102007] = {"MP5K", {R=100,G=255,B=200}},
                [102105] = {"P90", {R=255,G=100,B=255}},
                [103001] = {"Kar98k", {R=255,G=60,B=60}},
                [103002] = {"M24", {R=255,G=40,B=40}},
                [103003] = {"AWM", {R=255,G=20,B=20}},
                [103004] = {"SKS", {R=255,G=120,B=80}},
                [103005] = {"VSS", {R=180,G=180,B=255}},
                [103006] = {"Mini14", {R=200,G=200,B=100}},
                [103007] = {"Mk14", {R=255,G=80,B=40}},
                [103008] = {"Win94", {R=200,G=160,B=80}},
                [103009] = {"SLR", {R=255,G=100,B=60}},
                [103010] = {"QBU", {R=180,G=220,B=100}},
                [103011] = {"Mosin", {R=255,G=50,B=50}},
                [103012] = {"AMR", {R=255,G=0,B=0}},
                [104001] = {"S686", {R=200,G=200,B=80}},
                [104002] = {"S1897", {R=180,G=180,B=60}},
                [104003] = {"S12K", {R=160,G=200,B=100}},
                [104004] = {"DBS", {R=255,G=180,B=40}},
                [105001] = {"M249", {R=255,G=140,B=40}},
                [105002] = {"DP-28", {R=255,G=160,B=60}},
                [106001] = {"P92", {R=200,G=200,B=200}},
                [106002] = {"P1911", {R=200,G=200,B=200}},
                [106003] = {"R1895", {R=200,G=180,B=100}},
                [106004] = {"P18C", {R=180,G=180,B=220}},
                [106005] = {"R45", {R=200,G=160,B=80}},
                [106006] = {"SawedOff", {R=180,G=140,B=60}},
                [106007] = {"Flare", {R=255,G=255,B=0}},
                [106008] = {"Skorpion", {R=180,G=220,B=180}},
                [203001] = {"Red Dot", {R=100,G=255,B=100}},
                [203002] = {"Holo", {R=100,G=255,B=150}},
                [203003] = {"2x", {R=80,G=200,B=255}},
                [203004] = {"4x", {R=80,G=150,B=255}},
                [203005] = {"8x", {R=255,G=80,B=80}},
                [203014] = {"3x", {R=80,G=180,B=255}},
                [203015] = {"6x", {R=255,G=120,B=80}},
                [203018] = {"Canted", {R=150,G=150,B=255}},
                [103001004] = {"4x", {R=80,G=150,B=255}},
                [103001005] = {"8x", {R=255,G=80,B=80}},
                [103001006] = {"3x", {R=80,G=180,B=255}},
                [103001007] = {"6x", {R=255,G=120,B=80}},
                [907000021] = {"3x", {R=80,G=180,B=255}},
                [907000022] = {"4x", {R=80,G=150,B=255}},
                [907000023] = {"6x", {R=255,G=120,B=80}},
                [907000024] = {"8x", {R=255,G=80,B=80}},
                [301001] = {"Bandage", {R=255,G=200,B=200}},
                [301002] = {"FirstAid", {R=255,G=100,B=100}},
                [301003] = {"MedKit", {R=255,G=40,B=40}},
                [301004] = {"EnergyDrink", {R=100,G=255,B=255}},
                [301005] = {"Painkiller", {R=255,G=200,B=50}},
                [301006] = {"Adrenaline", {R=255,G=50,B=255}},
                [104001001] = {"MedKit", {R=255,G=40,B=40}},
                [104001002] = {"FirstAid", {R=255,G=100,B=100}},
                [104001003] = {"Bandage", {R=255,G=200,B=200}},
                [104001004] = {"Adrenaline", {R=255,G=50,B=255}},
                [104001005] = {"Painkiller", {R=255,G=200,B=50}},
                [104001006] = {"EnergyDrink", {R=100,G=255,B=255}},
                [602001] = {"Frag", {R=255,G=80,B=40}},
                [602002] = {"Smoke", {R=180,G=180,B=180}},
                [602003] = {"Molotov", {R=255,G=120,B=0}},
                [602004] = {"Stun", {R=255,G=255,B=100}},
            }
            local CATEGORY_DEFAULT_COLOR = {
                AR = {R=80,G=180,B=255}, SMG = {R=180,G=255,B=120}, Sniper = {R=255,G=60,B=60},
                Shotgun = {R=255,G=180,B=40}, LMG = {R=255,G=140,B=40}, Pistol = {R=200,G=200,B=200},
                Scope = {R=80,G=200,B=255}, Med = {R=255,G=100,B=100}, Grenade = {R=255,G=80,B=40},
                Other = {R=200,G=200,B=200},
            }
            local function ItemCategory(id)
                id = tonumber(id) or 0
                if id <= 0 then return "Other" end
                if id >= 1000000 then
                    if id >= 101001000 and id < 101002000 then return "AR" end
                    if id >= 102001000 and id < 102002000 then return "SMG" end
                    if id >= 103001000 and id < 103002000 then return "Scope" end
                    if id >= 104001000 and id < 104002000 then return "Med" end
                    if id >= 907000000 and id < 907000020 then return "AR" end
                    if id >= 907000020 and id < 907000030 then return "Scope" end
                    local top = math.floor(id / 1000000)
                    if top == 101 then return "AR" end
                    if top == 102 then return "SMG" end
                    if top == 103 then return "Scope" end
                    if top == 104 then return "Med" end
                    if top == 203 then return "Scope" end
                    if top == 301 then return "Med" end
                    return "Other"
                end
                if id >= 101000 and id < 102000 then return "AR" end
                if id >= 102000 and id < 103000 then return "SMG" end
                if id >= 103000 and id < 104000 then return "Sniper" end
                if id >= 104000 and id < 105000 then return "Shotgun" end
                if id >= 105000 and id < 106000 then return "LMG" end
                if id >= 106000 and id < 107000 then return "Pistol" end
                if id >= 201000 and id < 205000 then return "Scope" end
                if id >= 301000 and id < 303000 then return "Med" end
                if id >= 601000 and id < 604000 then return "Grenade" end
                return "Other"
            end
            local function ItemCategoryFromName(item)
                local n = ""
                pcall(function()
                    if item.GetName then n = tostring(item:GetName() or "") end
                    if (n == "" or n == "None") and item.GetClass then
                        local c = item:GetClass()
                        if c and c.GetName then n = tostring(c:GetName() or "") end
                    end
                end)
                n = string.lower(n)
                if n == "" then return "Other" end
                if n:find("scope", 1, true) or n:find("sight", 1, true) or n:find("reddot", 1, true)
                    or n:find("holo", 1, true) or n:find("2x", 1, true) or n:find("3x", 1, true)
                    or n:find("4x", 1, true) or n:find("6x", 1, true) or n:find("8x", 1, true)
                    or n:find("canted", 1, true) or n:find("optics", 1, true) then
                    return "Scope"
                end
                if n:find("m416", 1, true) or n:find("scar", 1, true) or n:find("akm", 1, true)
                    or n:find("m16", 1, true) or n:find("groza", 1, true) or n:find("aug", 1, true)
                    or n:find("qbz", 1, true) or n:find("m762", 1, true) or n:find("mk47", 1, true)
                    or n:find("g36", 1, true) or n:find("famas", 1, true) or n:find("ace32", 1, true)
                    or n:find("honey", 1, true) or n:find("assault", 1, true) or n:find("rifle_ar", 1, true)
                    or n:find("bp_rifle", 1, true) or n:find("ar_", 1, true) then
                    return "AR"
                end
                if n:find("uzi", 1, true) or n:find("ump", 1, true) or n:find("vector", 1, true)
                    or n:find("bizon", 1, true) or n:find("mp5", 1, true) or n:find("p90", 1, true)
                    or n:find("thompson", 1, true) or n:find("smg", 1, true) then
                    return "SMG"
                end
                if n:find("kar98", 1, true) or n:find("m24", 1, true) or n:find("awm", 1, true)
                    or n:find("sks", 1, true) or n:find("mini14", 1, true) or n:find("slr", 1, true)
                    or n:find("mosin", 1, true) or n:find("sniper", 1, true) or n:find("dmr", 1, true) then
                    return "Sniper"
                end
                if n:find("medkit", 1, true) or n:find("firstaid", 1, true) or n:find("bandage", 1, true)
                    or n:find("painkiller", 1, true) or n:find("adrenaline", 1, true)
                    or n:find("energydrink", 1, true) or n:find("drink", 1, true) or n:find("pill", 1, true) then
                    return "Med"
                end
                if n:find("grenade", 1, true) or n:find("frag", 1, true) or n:find("molotov", 1, true)
                    or n:find("smoke", 1, true) or n:find("stun", 1, true) then
                    return "Grenade"
                end
                return "Other"
            end
            local function ItemShouldShow(id, item)
                local cfg = _G.GTLMODConfig
                if not cfg or not cfg.EspItem_Master then return false end
                id = tonumber(id) or 0
                local cat = "Other"
                if id > 0 then cat = ItemCategory(id) end
                if cat == "Other" and item then
                    cat = ItemCategoryFromName(item)
                end
                if cat == "AR" then return cfg.EspItem_AR == true end
                if cat == "SMG" then return cfg.EspItem_SMG == true end
                if cat == "Sniper" then return cfg.EspItem_Sniper == true end
                if cat == "Shotgun" then return cfg.EspItem_Shotgun == true end
                if cat == "LMG" then return cfg.EspItem_LMG == true end
                if cat == "Pistol" then return cfg.EspItem_Pistol == true end
                if cat == "Scope" then return cfg.EspItem_Scope == true end
                if cat == "Med" then return cfg.EspItem_Med == true end
                if cat == "Grenade" then return cfg.EspItem_Grenade == true end
                if cfg.EspItem_Special == true then return true end
                return false
            end
            local function UnDyeItemMesh(mesh)
                if not mesh or not slua.isValid(mesh) then return end
                pcall(function()
                    if mesh.SetDrawDyeing then mesh:SetDrawDyeing(false) end
                    if mesh.SetDrawHighlight then mesh:SetDrawHighlight(false) end
                    if mesh.SetDrawIdeaOutline then mesh:SetDrawIdeaOutline(false) end
                    if mesh.SetIdeaOutlineNew then mesh:SetIdeaOutlineNew(false) end
                    if mesh.OverrideIdeaOutlineThickness then mesh:OverrideIdeaOutlineThickness(0.0) end
                end)
            end
            local function ClearItemGlowOnActor(actor)
                if not actor or not slua.isValid(actor) then return end
                pcall(function()
                    if actor.Mesh then UnDyeItemMesh(actor.Mesh) end
                    if actor.StaticMesh then UnDyeItemMesh(actor.StaticMesh) end
                    if actor.SkeletalMesh then UnDyeItemMesh(actor.SkeletalMesh) end
                    local SkeletalMeshComponent = safeImport("SkeletalMeshComponent")
                    local StaticMeshComponent = safeImport("StaticMeshComponent")
                    if SkeletalMeshComponent and actor.GetComponentsByClass then
                        local sk = actor:GetComponentsByClass(SkeletalMeshComponent)
                        if sk then
                            local n = (type(sk.Num) == "function" and sk:Num()) or 0
                            for i = 0, math.min(n, 8) - 1 do
                                local c = sk:Get(i)
                                if slua.isValid(c) then UnDyeItemMesh(c) end
                            end
                        end
                    end
                    if StaticMeshComponent and actor.GetComponentsByClass then
                        local st = actor:GetComponentsByClass(StaticMeshComponent)
                        if st then
                            local n = (type(st.Num) == "function" and st:Num()) or 0
                            for i = 0, math.min(n, 8) - 1 do
                                local c = st:Get(i)
                                if slua.isValid(c) then UnDyeItemMesh(c) end
                            end
                        end
                    end
                end)
            end
            function _G.ClearAllItemESPGlow()
                local dyed = _G._ItemDyedActors
                if dyed then
                    for actor, _ in pairs(dyed) do
                        pcall(ClearItemGlowOnActor, actor)
                    end
                end
                _G._ItemDyedActors = setmetatable({}, { __mode = "k" })
                _G.CachedItems = {}
            end
            local function EnsureItemESPConsole()
                if _G._ItemESP_ConsoleReady then return end
                pcall(function()
                    local KSL = safeImport("KismetSystemLibrary")
                    local world = slua.getWorld and slua.getWorld()
                    if not KSL or not world then return end
                    KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                    KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                    KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                    KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                    _G._ItemESP_ConsoleReady = true
                end)
            end
            local function DyeItemMesh(mesh, col)
                if not mesh or not slua.isValid(mesh) then return end
                pcall(function()
                    if mesh.SetDrawDyeing then mesh:SetDrawDyeing(true) end
                    if mesh.SetDrawDyeingMode then mesh:SetDrawDyeingMode(1) end
                    if mesh.SetVisibleDyeingColor then mesh:SetVisibleDyeingColor(col) end
                    if mesh.SetOccludedDyeingColor then mesh:SetOccludedDyeingColor(col) end
                    if mesh.SetDyeingColorFadeDistance then mesh:SetDyeingColorFadeDistance(99999.0) end
                    if mesh.SetDyeingColorMinMaxDistance then mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0) end
                    if mesh.SetDrawHighlight then mesh:SetDrawHighlight(true) end
                    if mesh.OverrideHighlightColor then mesh:OverrideHighlightColor(col) end
                    if mesh.SetHighlightCanBeOccluded then mesh:SetHighlightCanBeOccluded(false) end
                    if mesh.SetDrawIdeaOutline then mesh:SetDrawIdeaOutline(true) end
                    if mesh.SetIdeaOutlineNew then mesh:SetIdeaOutlineNew(true) end
                    if mesh.SetIdeaOutlineOcclusionHighlight then mesh:SetIdeaOutlineOcclusionHighlight(true) end
                    if mesh.OverrideIdeaOutlineColor then mesh:OverrideIdeaOutlineColor(col) end
                    if mesh.SetIdeaOutlineOcclusionColor then mesh:SetIdeaOutlineOcclusionColor(col) end
                    if mesh.OverrideIdeaOutlineThickness then mesh:OverrideIdeaOutlineThickness(12.0) end
                end)
            end
            local function ApplyGlowToItemActor(item, col)
                if not item or not slua.isValid(item) then return end
                pcall(function()
                    if item.Mesh and slua.isValid(item.Mesh) then DyeItemMesh(item.Mesh, col) end
                    if item.StaticMesh and slua.isValid(item.StaticMesh) then DyeItemMesh(item.StaticMesh, col) end
                    if item.SkeletalMesh and slua.isValid(item.SkeletalMesh) then DyeItemMesh(item.SkeletalMesh, col) end
                    if item.RootComponent and slua.isValid(item.RootComponent) then
                        local rc = item.RootComponent
                        if rc.SetDrawDyeing or rc.SetDrawIdeaOutline then DyeItemMesh(rc, col) end
                    end
                    local SkeletalMeshComponent = safeImport("SkeletalMeshComponent")
                    local StaticMeshComponent = safeImport("StaticMeshComponent")
                    if SkeletalMeshComponent and item.GetComponentsByClass then
                        local sk = item:GetComponentsByClass(SkeletalMeshComponent)
                        if sk then
                            local n = (type(sk.Num) == "function" and sk:Num()) or 0
                            for i = 0, math.min(n, 8) - 1 do
                                local c = sk:Get(i)
                                if slua.isValid(c) then DyeItemMesh(c, col) end
                            end
                        end
                    end
                    if StaticMeshComponent and item.GetComponentsByClass then
                        local st = item:GetComponentsByClass(StaticMeshComponent)
                        if st then
                            local n = (type(st.Num) == "function" and st:Num()) or 0
                            for i = 0, math.min(n, 8) - 1 do
                                local c = st:Get(i)
                                if slua.isValid(c) then DyeItemMesh(c, col) end
                            end
                        end
                    end
                end)
                _G._ItemDyedActors[item] = true
            end
            local function ReadItemId(item)
                local itemId = nil
                pcall(function()
                    if item.DefineID then
                        local d = item.DefineID
                        itemId = d.TypeSpecificID or d.TypeSpecificId or d.TypeID
                        if (not itemId or itemId == 0) and d.ID then itemId = d.ID end
                    end
                    if (not itemId or itemId == 0) and item.ItemID then itemId = item.ItemID end
                    if (not itemId or itemId == 0) and item.GetItemID then itemId = item:GetItemID() end
                    if (not itemId or itemId == 0) and item.GetDefineID then
                        local d = item:GetDefineID()
                        if d then
                            itemId = d.TypeSpecificID or d.TypeSpecificId or d.TypeID or d.ID
                        end
                    end
                    if (not itemId or itemId == 0) and item.PickupData then
                        local pd = item.PickupData
                        if type(pd) == "table" or type(pd) == "userdata" then
                            itemId = pd.TypeSpecificID or pd.ItemID or pd.ID or pd.TypeID
                        end
                    end
                    if (not itemId or itemId == 0) and item.GetName then
                        local n = tostring(item:GetName() or "")
                        local m = n:match("(%d%d%d%d%d%d%d%d%d)") or n:match("(%d%d%d%d%d%d)")
                        if m then itemId = tonumber(m) end
                    end
                end)
                return tonumber(itemId) or 0
            end
            _G.RunOptimizedItemAndVehicleESP = function(pc)
                local cfg = _G.GTLMODConfig
                if not cfg or not cfg.EspItem_Master then
                    if _G.ClearAllItemESPGlow then _G.ClearAllItemESPGlow() end
                    return
                end
                EnsureItemESPConsole()
                local curTime = os.clock()
                local player = nil
                pcall(function()
                    local GD = GameplayData or package.loaded["GameLua.GameCore.Data.GameplayData"]
                    if GD and GD.GetPlayerCharacter then player = GD.GetPlayerCharacter() end
                    if not slua.isValid(player) then
                        local ctrl = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if slua.isValid(ctrl) and ctrl.GetPlayerCharacterSafety then
                            player = ctrl:GetPlayerCharacterSafety()
                        end
                    end
                end)
                if not slua.isValid(player) then return end
                if curTime - (_G.LastScanItemTime or 0) > 1.4 then
                    _G.LastScanItemTime = curTime
                    local newItems = {}
                    local seen = {}
                    local function consider(item)
                        if not item or not slua.isValid(item) or item.bHidden then return end
                        if seen[item] then return end
                        seen[item] = true
                        local dist = 0
                        pcall(function()
                            if player.GetDistanceTo then dist = player:GetDistanceTo(item) end
                        end)
                        if dist <= 0 or dist > 15000 then return end
                        local itemId = ReadItemId(item)
                        if not ItemShouldShow(itemId, item) then return end
                        local meta = ITEM_NAME_MAP[itemId]
                        local cat = ItemCategory(itemId)
                        local name = meta and meta[1] or (cat .. "#" .. tostring(itemId))
                        local color = (meta and meta[2]) or CATEGORY_DEFAULT_COLOR[cat] or CATEGORY_DEFAULT_COLOR.Other
                        newItems[#newItems + 1] = { act = item, data = { name = name, color = color, id = itemId, cat = cat } }
                    end
                    pcall(function()
                        local classNames = {
                            "PickUpWrapperActor",
                            "STExtraPickUpWrapperActor",
                            "STPickupWrapperActor",
                            "PickUpListWrapperActor",
                            "STExtraLobbyWeapon",
                        }
                        local GS = safeImport("GameplayStatics")
                        local world = slua.getWorld and slua.getWorld()
                        local maxScan = IS_32BIT and 220 or 500
                        local scanned = 0
                        for _, cn in ipairs(classNames) do
                            if scanned >= maxScan then break end
                            local APickUp = safeImport(cn)
                            if APickUp then
                                local actors = nil
                                pcall(function()
                                    if Game and Game.GetActorsByClass then
                                        actors = Game:GetActorsByClass(APickUp)
                                    end
                                end)
                                if not actors and GS and world then
                                    pcall(function()
                                        actors = GS.GetAllActorsOfClass(world, APickUp, nil)
                                    end)
                                end
                                if actors then
                                    local count = 0
                                    pcall(function()
                                        count = (type(actors.Num) == "function" and actors:Num()) or 0
                                    end)
                                    for i = 0, count - 1 do
                                        scanned = scanned + 1
                                        if scanned > maxScan then break end
                                        local item = nil
                                        pcall(function() item = actors:Get(i) end)
                                        consider(item)
                                    end
                                end
                            end
                        end
                    end)
                    local stillActive = {}
                    for _, entry in ipairs(newItems) do
                        stillActive[entry.act] = true
                    end
                    if _G._ItemDyedActors then
                        for actor, _ in pairs(_G._ItemDyedActors) do
                            if not stillActive[actor] then
                                pcall(ClearItemGlowOnActor, actor)
                                _G._ItemDyedActors[actor] = nil
                            end
                        end
                    end
                    _G.CachedItems = newItems
                end
                local LC = safeImport("LinearColor")
                if not LC or not _G.CachedItems then return end
                local now = os.clock()
                for _, entry in ipairs(_G.CachedItems) do
                    local item = entry.act
                    local itemData = entry.data
                    if item and itemData and slua.isValid(item) and not item.bHidden then
                        if not ItemShouldShow(itemData.id, itemData.actor) then
                            pcall(ClearItemGlowOnActor, item)
                            if _G._ItemDyedActors then _G._ItemDyedActors[item] = nil end
                        else
                            local dist = 0
                            pcall(function()
                                if player.GetDistanceTo then dist = player:GetDistanceTo(item) / 100 end
                            end)
                            if dist > 0 and dist <= 150 then
                                local phase = (now * 2.6 + (itemData.id or 0) * 0.17) % 6.28318
                                local shimmer = (math.sin(phase) + 1) * 0.5
                                local baseR = (itemData.color.R or 255) / 255
                                local baseG = (itemData.color.G or 255) / 255
                                local baseB = (itemData.color.B or 255) / 255
                                local r = baseR * (0.50 + 0.50 * shimmer)
                                local g = baseG * (0.50 + 0.50 * shimmer)
                                local b = baseB * (0.50 + 0.50 * shimmer)
                                local col = LC(r, g, b, 0.90)
                                ApplyGlowToItemActor(item, col)
                            end
                        end
                    end
                end
            end
            local _RunItemESP_LastRun = 0
            local _RunItemESP_WasOn = false
            function _G.RunItemESPLite()
                local on = (_G.GTLMODConfig and (_G.GTLMODConfig.EspLoot == true or _G.GTLMODConfig.EspItem_Master == true))
                if not on then
                    if _RunItemESP_WasOn then
                        pcall(function() if _G.ClearAllItemESPGlow then _G.ClearAllItemESPGlow() end end)
                    end
                    _RunItemESP_WasOn = false
                    return
                end
                _RunItemESP_WasOn = true
                local _now = os.clock()
                if _now - _RunItemESP_LastRun < 0.50 then return end
                _RunItemESP_LastRun = _now
                local pc = nil
                pcall(function()
                    pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                end)
                _G.RunOptimizedItemAndVehicleESP(pc)
            end
            local function ApplyIpadFOVState(pc, localPlayer)
                if not Valid(pc) or not Valid(localPlayer) then return end
                if not _G.GTLMODState.CachedIpadFOV then
                    _G.GTLMODState.CachedIpadFOV = {}
                end
                local state = _G.GTLMODState.CachedIpadFOV
                if not (_G.GTLMODConfig and _G.GTLMODConfig.IpadView == true) then
                    if state.lastAppliedFOV ~= nil and type(pc.FOV) == "function" then
                        pcall(function() pc:FOV(0) end)
                    end
                    state.lastAppliedFOV = nil
                    state.prevAiming = false
                    return
                end
                local isAiming = false
                pcall(function()
                    isAiming =
                        localPlayer.bIsWeaponAiming == true or
                        localPlayer.bIsGunADS == true
                end)
                local wasAiming = state.prevAiming == true
                if isAiming then
                    if not wasAiming then
                        if type(pc.FOV) == "function" and state.lastAppliedFOV ~= nil then
                            pcall(function() pc:FOV(0) end)
                        end
                        state.lastAppliedFOV = nil
                    end
                    state.prevAiming = true
                    return
                end
                state.prevAiming = false
                local targetFOV = nil
                local currentVehicle = nil
                pcall(function()
                    currentVehicle = localPlayer.CurrentVehicle
                    if not currentVehicle and type(localPlayer.GetVehicle) == "function" then
                        currentVehicle = localPlayer:GetVehicle()
                    end
                end)
                local isInVehicle =
                    Valid(currentVehicle) or localPlayer.bIsInVehicle == true
                local custom = _G.GTLMODState and _G.GTLMODState.CustomTextData
                if _G.GTLMODConfig and _G.GTLMODConfig.IpadView and custom then
                    targetFOV = tonumber(custom.IpadViewFOV) or 120
                end
                if type(pc.FOV) ~= "function" then return end
                if targetFOV and targetFOV > 0 then
                    targetFOV = math.max(40, math.min(160, targetFOV))
                    if wasAiming or state.lastAppliedFOV ~= targetFOV then
                        pcall(function() pc:FOV(targetFOV) end)
                        state.lastAppliedFOV = targetFOV
                    end
                elseif state.lastAppliedFOV ~= nil then
                    pcall(function() pc:FOV(0) end)
                    state.lastAppliedFOV = nil
                end
            end
            local function MainLoop()
                if isExpired then return end
                if _G.GTLMODState.CustomTextData == nil then
                    _G.GTLMODState.CustomTextData = { OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120 }
                end
                local pc = GameplayData.GetPlayerController()
                local localPlayer = nil
                if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end
                if not Valid(localPlayer) then
                    if _G.GTLMODState.TrackedMarks then
                        for markId, _ in pairs(_G.GTLMODState.TrackedMarks) do SafeRemoveMark(markId) end
                    end
                    _G.GTLMODState.TrackedMarks = {}
                    for key, data in pairs(_G.GTLMODState.EnemyMarks) do
                        if data and data.MIDs then
                            for meshStr, midTable in pairs(data.MIDs) do
                                for k in pairs(midTable) do midTable[k] = nil end
                            end
                            data.MIDs = nil
                        end
                    end
                    _G.GTLMODState.EnemyMarks = {}
                    _G.GTLMODState.PrevGraphicsState = {}
                    _G.BotStatusCache = {}
                    _G.AimTouchVisCache = {}
                    _G.GTLMODState.MidCacheCount = 0
                    _G._GTL_DistCache = {}
                    _G._GTL_LOSCache  = {}
                    _G.GTLMODState._LastHadPlayer = false
                    pcall(function()
                        if _G.PlayerMapMarker then
                            _G.PlayerMapMarker._ActiveTimerPC = nil
                            _G.PlayerMapMarker._ActiveTimerTick = 0
                            _G.PlayerMapMarker.ESPCanvas = nil
                            _G.PlayerMapMarker.bActive = false
                        end
                        if NewWallhack then
                            NewWallhack.WH_TIMER = nil
                            NewWallhack.Active = false
                            NewWallhack.PROCESSED_PAWNS = {}
                        end
                        if _G.RedBoxOverlay then
                            _G.RedBoxOverlay.bActive = false
                            _G.RedBoxOverlay.MainContainer = nil
                            _G.RedBoxOverlay.WidgetSlot = nil
                            _G.RedBoxOverlay.TextBlockPlayer = nil
                            _G.RedBoxOverlay.TextBlockBot = nil
                            pcall(function() _G.RedBoxOverlay._CachedPosVec = nil end)
                        end
                        if _G.GTLMODState.CachedIpadFOV then
                            _G.GTLMODState.CachedIpadFOV = {}
                        end
                    end)
                    return
                end
                if not _G.GTLMODState._LastHadPlayer then
                    _G.GTLMODState._LastHadPlayer = true
                    pcall(function()
                        local c = _G.GTLMODConfig or {}
                        if _G.LexusConfig then
                            _G.LexusConfig.EspLoai9 = (c.EspLine or c.CounterEnabled or c.EspModelName or c.EspWeaponIcon) and true or false
                        end
                        if c.TargetFPS or c.FPSStabilizer then _G.GTLMODState.GraphicsUnlocked = false end
                        if c.WallhackSmart and NewWallhack then
                            NewWallhack.WH_TIMER = nil
                            NewWallhack.Active = false
                        end
                        _G.GTLMODState.OrigAutoAimCompCached = nil
                        _G._SubsystemSpoofDone = false
                        _G.PrivAimVisCache = {}
                        _G.PrivAimBotCache = {}
                        _G.AimTouchVisCache = {}
                        _G._PrivAimCacheLastFlush = 0
                    end)
                end
                local Cached_MyHUD = pc and pc.MyHUD or nil
                if Cached_MyHUD then _G._MagooHUD = Cached_MyHUD end
                pcall(function()
                    local c = _G.GTLMODConfig or {}
                    local _syncFP = tostring(c.EspBox) .. tostring(c.EspLine) .. tostring(c.CounterEnabled) .. tostring(c.EspModelName)
                                 .. tostring(c.EspWeaponIcon) .. tostring(c.EspShowHealthBar) .. tostring(c.EspTeamColorBox)
                                 .. tostring(c.EspShowDistance) .. tostring(c.EspActiveBom) .. tostring(c.EspLoot) .. tostring(c.VehicleEnabled)
                    if _syncFP ~= _G._LexusSyncFP then
                        _G._LexusSyncFP = _syncFP
                        local L = _G.LexusConfig or {}
                        _G.LexusConfig = L
                        local any = c.EspModelName or c.EspWeaponIcon or c.EspBox
                        L.EspLoai9 = any and true or false
                        -- EspBox independent of weapon icon
                        L.Esp9_Count = false
                        L.Esp9_Line = false
                        pcall(function()
                            local cv = rawget(_G, "__CLEAR_VISION_ESP_V2")
                            if type(cv) ~= "table" then return end
                            local keep = (c.EspBox == true) or (c.CounterEnabled == true) or (c.EspLine == true) or (c.Esp5 == true)
                            if keep then
                                c.EspBox = true
                                c.EspV2Enabled = true
                                if type(cv.Start) == "function" then cv.Start() end
                                if type(cv.SyncEnabled) == "function" then cv.SyncEnabled() end
                            end
                            -- weapon icon never stops ClearVision
                        end)
                        L.Esp9_Name = c.EspModelName == true
                        L.Esp9_HP = (c.EspModelName == true) and (c.EspShowHealthBar ~= false)
                        L.Esp9_Team = (c.EspModelName == true) and (c.EspTeamColorBox ~= false)
                        L.Esp9_Weapon = c.EspWeaponIcon == true
                        L.Esp9_Distance = (c.EspModelName == true) and (c.EspShowDistance ~= false)
                        L.Esp9_Line = c.EspLine == true
                        L.EspActiveBom = c.EspActiveBom == true
                        L.EspBomMaster = c.EspActiveBom == true
                        if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive and L.EspLoai9 then
                            if _G.PlayerMapMarker.Start then pcall(_G.PlayerMapMarker.Start) end
                        end
                    end
                    if c.CounterEnabled then
                    elseif _G.RedBoxOverlay and _G.RedBoxOverlay.bActive and _G.RedBoxOverlay.Stop then
                        pcall(_G.RedBoxOverlay.Stop)
                    end
                    if c.WallhackSmart then
                        if not NewWallhack.Active or not NewWallhack.WH_TIMER then
                            NewWallhack.WH_TIMER = nil
                            NewWallhack.Active = false
                            pcall(_G.StartNewWallhack)
                        end
                    elseif NewWallhack.Active then
                        pcall(_G.StopNewWallhack)
                    end
                    if c.ForceAimbot then
                        _G._ForceAimbotWanted = true
                    else
                        _G._ForceAimbotWanted = false
                    end
                    if c.IpadView and not _G.GTLMODState.CustomTextData then
                        _G.GTLMODState.CustomTextData = { OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120 }
                    end
                    if _G.RJCounter and _G.RJCounter.SetEnabled then
                        pcall(function() _G.RJCounter.SetEnabled(false) end)
                    end
                end)
                if not _G._SubsystemSpoofDone then
                    _G._SubsystemSpoofDone = true
                    pcall(function()
                        local SubMgr = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]
                        if not SubMgr then return end
                        local targets = {
                            "AFKReportorSubsystem",
                            "SpeedCheckSubsystem",
                            "WallCheckSubsystem",
                            "ShootVerifySubSystemClient",
                        }
                        for _, subName in ipairs(targets) do
                            pcall(function()
                                local sub = SubMgr:Get(subName)
                                if not sub then return end
                                local reportFns = {
                                    "ReportSpeedCheatToServer",
                                    "ReportWallCheatToServer",
                                    "ReportShootVerifyFailed",
                                    "ReportAFKToServer",
                                    "SendReport",
                                    "DoReport",
                                    "Report",
                                }
                                for _, fnName in ipairs(reportFns) do
                                    if type(sub[fnName]) == "function" then
                                        sub[fnName] = function() end
                                    end
                                end
                            end)
                        end
                    end)
                end
                if _G.GTLMODConfig then InitializeGraphicsUnlock() end
                InitializeNativeESP()
                pcall(function()
                    ApplyIpadFOVState(pc, localPlayer)
                end)
                pcall(function()
                    if Valid(pc) then
                        if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
                        if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
                    end
                end)
                pcall(function()
                    local autoComp = localPlayer.AutoAimComp
                    if Valid(autoComp) then
                        if not _G.GTLMODState.OrigAutoAimCompCached then
                            _G.GTLMODState.OrigAutoAimCompCached = {
                                bOnlyHitHead = autoComp.bOnlyHitHead,
                                HeadBoneName = autoComp.HeadBoneName,
                                Bones = autoComp.Bones,
                                ChestBoneName = autoComp.ChestBoneName,
                                PelvisBoneName = autoComp.PelvisBoneName,
                                HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                                ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                                PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                            }
                        end
                        if _G.GTLMODConfig.AutoHead then
                            autoComp.bOnlyHitHead = true
                            autoComp.HeadBoneName = "Head"
                            pcall(function() autoComp.Bones = {"Head"} end)
                            autoComp.ChestBoneName = "Head"
                            autoComp.PelvisBoneName = "Head"
                            if autoComp.AimAssistConfig then
                                autoComp.AimAssistConfig.HeadPriority = 100
                                autoComp.AimAssistConfig.ChestPriority = 100
                                autoComp.AimAssistConfig.PelvisPriority = 100
                            end
                        else
                            local orig = _G.GTLMODState.OrigAutoAimCompCached
                            autoComp.bOnlyHitHead = orig.bOnlyHitHead
                            autoComp.HeadBoneName = orig.HeadBoneName
                            pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                            autoComp.ChestBoneName = orig.ChestBoneName
                            autoComp.PelvisBoneName = orig.PelvisBoneName
                            if autoComp.AimAssistConfig then
                                autoComp.AimAssistConfig.HeadPriority = orig.HeadPriority or 1
                                autoComp.AimAssistConfig.ChestPriority = orig.ChestPriority or 1
                                autoComp.AimAssistConfig.PelvisPriority = orig.PelvisPriority or 1
                            end
                        end
                    end
                end)
                if not _G._GTL_lsg_cache then
                    pcall(function() _G._GTL_lsg_cache = require("client.slua.logic.setting.logic_setting_graphics") end)
                end
                pcall(function()
                    local lsg = _G._GTL_lsg_cache
                    if not lsg then return end
                    local gi = lsg.GetGameInstance()
                    if gi then
                        local cleanOn = (_G.GTLMODConfig.CleaningSpace == true) or (_G.GTLMODConfig.RemoveGrass == true)
                        if cleanOn and not _G.GTLMODState.PrevGraphicsState.RemoveGrass then
                            if _G.ApplyCleaningSpace then pcall(_G.ApplyCleaningSpace, true)
                            else
                                gi:ExecuteCMD("grass.DensityScale", "0"); gi:ExecuteCMD("foliage.DensityScale", "0")
                                gi:ExecuteCMD("r.Fog", "0")
                            end
                            _G.GTLMODState.PrevGraphicsState.RemoveGrass = true
                        elseif not cleanOn and _G.GTLMODState.PrevGraphicsState.RemoveGrass then
                            if _G.ApplyCleaningSpace then pcall(_G.ApplyCleaningSpace, false)
                            else
                                gi:ExecuteCMD("grass.DensityScale", "1"); gi:ExecuteCMD("foliage.DensityScale", "1")
                                gi:ExecuteCMD("r.Fog", "1")
                            end
                            _G.GTLMODState.PrevGraphicsState.RemoveGrass = false
                        end
                        if _G.GTLMODConfig.ColorBodyV2 and not _G.GTLMODState.PrevGraphicsState.ColorBodyV2 then
                            gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                            gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                            gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                            _G.GTLMODState.PrevGraphicsState.ColorBodyV2 = true
                        elseif not _G.GTLMODConfig.ColorBodyV2 and _G.GTLMODState.PrevGraphicsState.ColorBodyV2 then
                            gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                            gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                            gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                            _G.GTLMODState.PrevGraphicsState.ColorBodyV2 = false
                        end
                    end
                end)
                pcall(function()
                    local weapon = nil
                    pcall(function()
                        local weaponManager = localPlayer.WeaponManagerComponent
                        if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then weapon = weaponManager:GetCurrentWeapon() end
                    end)
                    if not Valid(weapon) then
                        if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
                        elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
                    end
                    if Valid(weapon) then
                        local entities = {}
                        if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
                        if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
                        if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then
                            table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
                        end
                        for _, entity in ipairs(entities) do
                            local anyModOn = _G.GTLMODConfig.CustomHRecoil or _G.GTLMODConfig.CustomVRecoil
                                or _G.GTLMODConfig.LessShake or _G.GTLMODConfig.Accuracy
                                or _G.GTLMODConfig.Crosshair
                            if anyModOn then
                                if not entity.OriginalStatsCached then
                                    entity.OriginalStatsCached = {
                                        GameDeviationFactor      = entity.GameDeviationFactor,
                                        GameDeviationAccuracy    = entity.GameDeviationAccuracy,
                                        BulletFireSpeed          = entity.BulletFireSpeed,
                                        ShootInterval            = entity.ShootInterval,
                                        BaseDamage               = entity.BaseDamage,
                                        AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                                        AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                                        RecoilKick               = entity.RecoilKick,
                                        RecoilKickADS            = entity.RecoilKickADS,
                                        AnimationKick            = entity.AnimationKick,
                                    }
                                end
                                if _G.GTLMODConfig.Crosshair then
                                    entity.GameDeviationFactor = 0.0
                                else
                                    entity.GameDeviationFactor = entity.OriginalStatsCached.GameDeviationFactor
                                end
                                if _G.GTLMODConfig.Accuracy then
                                    entity.GameDeviationAccuracy = 0.0
                                else
                                    entity.GameDeviationAccuracy = entity.OriginalStatsCached.GameDeviationAccuracy
                                end
                                if _G.GTLMODConfig.CustomHRecoil then
                                    entity.AccessoriesHRecoilFactor = _G.GTLMODState.CustomTextData.HRecoil or 0.05
                                else
                                    entity.AccessoriesHRecoilFactor = entity.OriginalStatsCached.AccessoriesHRecoilFactor
                                end
                                if _G.GTLMODConfig.CustomVRecoil then
                                    entity.AccessoriesVRecoilFactor = _G.GTLMODState.CustomTextData.VRecoil or 0.05
                                else
                                    entity.AccessoriesVRecoilFactor = entity.OriginalStatsCached.AccessoriesVRecoilFactor
                                end
                                if _G.GTLMODConfig.LessShake then
                                    entity.RecoilKickADS  = 0.0
                                    entity.RecoilKick     = 0.0
                                    entity.AnimationKick  = 0.0
                                else
                                    entity.RecoilKickADS  = entity.OriginalStatsCached.RecoilKickADS
                                    entity.RecoilKick     = entity.OriginalStatsCached.RecoilKick
                                    entity.AnimationKick  = entity.OriginalStatsCached.AnimationKick
                                end
                                entity.GTLMODWeaponModsActive = true
                            elseif entity.GTLMODWeaponModsActive then
                                if entity.OriginalStatsCached then
                                    local orig = entity.OriginalStatsCached
                                    entity.GameDeviationFactor      = orig.GameDeviationFactor
                                    entity.GameDeviationAccuracy    = orig.GameDeviationAccuracy
                                    entity.BulletFireSpeed          = orig.BulletFireSpeed
                                    entity.ShootInterval            = orig.ShootInterval
                                    entity.BaseDamage               = orig.BaseDamage
                                    entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                                    entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                                    entity.RecoilKick               = orig.RecoilKick
                                    entity.RecoilKickADS            = orig.RecoilKickADS
                                    entity.AnimationKick            = orig.AnimationKick
                                end
                                entity.GTLMODWeaponModsActive = false
                            end
                        end
                    end
                end)
                pcall(function()
                    local allCharacters = {}
                    if GameplayData.GetAllPlayerCharacters then
                        allCharacters = GameplayData.GetAllPlayerCharacters()
                    elseif GameplayData.GameCharacters then
                        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
                    end
                    local currentValidKeys = {}
                    for _, enemy in pairs(allCharacters) do
                        if Valid(enemy) and enemy ~= localPlayer then
                            currentValidKeys[GetSafeEnemyKey(enemy)] = true
                        end
                    end
                    for key, data in pairs(_G.GTLMODState.EnemyMarks) do
                        if not currentValidKeys[key] then
                            SafeRemoveMark(data.radarMark)
                            SafeRemoveMark(data.hpMark)
                            SafeRemoveMark(data.distMark)
                            SafeRemoveMark(data.hpMark8)
                            if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then _G.AimTouchVisCache[key] = nil end
                            if _G.BotStatusCache and _G.BotStatusCache[key] then _G.BotStatusCache[key] = nil end
                            if data.MIDs then
                                for meshStr, midTable in pairs(data.MIDs) do
                                    for k in pairs(midTable) do midTable[k] = nil end
                                end
                                data.MIDs = nil
                            end
                            data.enemy = nil
                            data.CachedMeshes = nil
                            _G.GTLMODState.EnemyMarks[key] = nil
                        end
                    end
                    local localTeamID = -1
                    pcall(function()
                        localTeamID = localPlayer.TeamID
                            or (type(localPlayer.GetTeamID) == "function" and localPlayer:GetTeamID())
                            or -1
                    end)
                    for _, enemy in pairs(allCharacters) do
                        if not Valid(enemy) then goto enemyContinue end
                        local enemyTeamID = -2
                        pcall(function()
                            enemyTeamID = enemy.TeamID
                                or (type(enemy.GetTeamID) == "function" and enemy:GetTeamID())
                                or -2
                        end)
                        if Valid(enemy) and enemy ~= localPlayer and enemyTeamID ~= localTeamID then
                            local eKey = GetSafeEnemyKey(enemy)
                            _G.GTLMODState.EnemyMarks[eKey] = _G.GTLMODState.EnemyMarks[eKey] or { enemy = enemy }
                            local markData = _G.GTLMODState.EnemyMarks[eKey]
                            markData.enemy = enemy
                            local bIsReallyDead = false
                            pcall(function()
                                if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                                elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                                elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                                if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                            end)
                            if not bIsReallyDead then
                                local eMesh = nil
                                pcall(function() eMesh = enemy.Mesh end)
                                local aLoc = nil
                                pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)
                                local eKey2 = GetSafeEnemyKey(enemy)
                                local _now_ml = os.clock()
                                if not _G._GTL_DistCache then _G._GTL_DistCache = {} end
                                local _dc = _G._GTL_DistCache[eKey2]
                                local distM = 0
                                if _dc and (_now_ml - _dc.t) < 0.35 then
                                    distM = _dc.v
                                else
                                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)
                                    _G._GTL_DistCache[eKey2] = { v = distM, t = _now_ml }
                                end
                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) then
                                    if _G.GTLMODConfig.EspAntenna and distM <= 400 then
                                        pcall(function()
                                            local loopCount = IS_32BIT and 4 or 8
                                            local zStep = 1000
                                            for i = 1, loopCount do
                                                local zOffset = 105 + (i * zStep)
                                                MyHUD:AddDebugText("|", enemy, 0.65, {X=0,Y=0,Z=zOffset}, {X=0,Y=0,Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                            end
                                        end)
                                    end
                                    if _G.GTLMODConfig.EspDistance and distM <= LIMITS.ESP_MAX_DISTANCE then
                                        pcall(function()
                                            MyHUD:AddDebugText(string.format("%.0fm", math.floor(distM+0.5)), enemy, 0.65, {X=15,Y=15,Z=-15}, {X=15,Y=15,Z=-15}, C_WHITE, true, false, true, nil, 0.9, true)
                                        end)
                                    end
                                    if _G.GTLMODConfig.EspName and distM <= LIMITS.ESP_MAX_DISTANCE then
                                        pcall(function()
                                            local pName = enemy.PlayerName or "Enemy"
                                            local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                                            if not _G._GTL_LOSCache then _G._GTL_LOSCache = {} end
                                            local _lc = _G._GTL_LOSCache[eKey2]
                                            local bVis = true
                                            if _lc and (_now_ml - _lc.t) < 0.25 then
                                                bVis = _lc.v
                                            else
                                                pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bVis = pc:LineOfSightTo(enemy) end end)
                                                _G._GTL_LOSCache[eKey2] = { v = bVis, t = _now_ml }
                                            end
                                            local color = isKnock and C_BLUE or (bVis and C_GREEN or C_RED)
                                            MyHUD:AddDebugText(pName, enemy, 0.65, {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120}, color, true, false, true, nil, 1.0, true)
                                        end)
                                    end
                                end
                                if _G.GTLMODConfig.EspVip then
                                    if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                                    if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                                else
                                    if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                                    if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                                end
                                pcall(function()
                                    if _G.GTLMODConfig.EspBox == true then
                                        local hp = enemy.Health or 100
                                        local maxHp = enemy.HealthMax or enemy.MaxHealth or 100
                                        if maxHp <= 0 then maxHp = 100 end
                                        local hpRatio = math.max(0, math.min(1, hp / maxHp))
                                        if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then
                                            pcall(function() enemy:Replay_CreateEnemyFrameUI(true, true) end)
                                        end
                                        if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                        if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                                        local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                        if Valid(uiComp) then
                                            if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                            if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                                        end
                                    else
                                        if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                                        local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                        if Valid(uiComp) then
                                            if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                            if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                        end
                                    end
                                end)
                            end
                        end
                        ::enemyContinue::
                    end
                end)
                if _G.GTLMODConfig.AimDebug and Valid(Cached_MyHUD) then
                    pcall(function()
                        local status = _G.GTLMODState.AimLastFail or "?"
                        local enemies = _G.GetEnemyTargetsFromActors(25000)
                        local cnt = enemies and #enemies or 0
                        local txt = string.format("[AIM] %s | Enemies: %d", status, cnt)
                        Cached_MyHUD:AddDebugText(txt, localPlayer, 0.1, {X=0,Y=0,Z=200}, {X=0,Y=0,Z=200}, C_YELLOW, true, false, true, nil, 1.0, true)
                    end)
                end
            end
            _G.GTLMODState.LoopToken = (_G.GTLMODState.LoopToken or 0) + 1
            local myToken = _G.GTLMODState.LoopToken
            pcall(function()
                if _G.GTLMODState and _G.GTLMODState.EnemyMarks then
                    for k, data in pairs(_G.GTLMODState.EnemyMarks) do
                        if type(data) == "table" then
                            if data.radarMark then pcall(function() SafeRemoveMark(data.radarMark) end); data.radarMark = nil end
                            if data.hpMark then pcall(function() SafeRemoveMark(data.hpMark) end); data.hpMark = nil end
                            if data.distMark then pcall(function() SafeRemoveMark(data.distMark) end); data.distMark = nil end
                        end
                    end
                    _G.GTLMODState.EnemyMarks = {}
                end
            end)
            local function MainTick()
                if isExpired then
                    if not _G.GTLMODNotifiedExpire then
                        _G.GTLMODNotifiedExpire = true
                                                pcall(function() if _G.StopNewWallhack then _G.StopNewWallhack() end end)
                        pcall(function()
                            if _G.GTLMODConfig then
                                for k, v in pairs(_G.GTLMODConfig) do
                                    if type(v) == "boolean" then _G.GTLMODConfig[k] = false end
                                end
                            end
                        end)
                        pcall(function()
                            local sh = safeImport("ScriptHelperClient")
                            if sh and sh.AddOnScreenDebugMessage then
                                sh.AddOnScreenDebugMessage("[MAGOO CORE] ⛔ EXPIRED — ALL FEATURES DISABLED", -1, 8.0, {R=1,G=0,B=0,A=1}, {X=1.5,Y=1.5})
                            end
                        end)
                        Notify("MAGOO CORE EXPIRED — ALL FEATURES DISABLED")
                    end
                    return
                end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                pcall(MainLoop)
                pcall(RunItemESPLite)
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(LIMITS.MAIN_TICK, MainTick)
                end
            end
            local function IpadFOVTick()
                if isExpired then return end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                local ipadOn = _G.GTLMODConfig and _G.GTLMODConfig.IpadView == true
                pcall(function()
                    local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
                    if not Valid(pc) then return end
                    if ipadOn then
                        local localPlayer = pc.GetPlayerCharacterSafety and pc:GetPlayerCharacterSafety()
                        if Valid(localPlayer) then
                            ApplyIpadFOVState(pc, localPlayer)
                        end
                    else
                        local state = _G.GTLMODState and _G.GTLMODState.CachedIpadFOV
                        if state and state.lastAppliedFOV ~= nil then
                            if type(pc.FOV) == "function" then pcall(function() pc:FOV(0) end) end
                            state.lastAppliedFOV = nil
                            state.prevAiming = false
                        elseif type(pc.FOV) == "function" then
                            if not _G._IPAD_FOV_CLEARED then
                                pcall(function() pc:FOV(0) end)
                                _G._IPAD_FOV_CLEARED = true
                            end
                        end
                    end
                end)
                if ipadOn then _G._IPAD_FOV_CLEARED = false end
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(ipadOn and 0.033 or 0.50, IpadFOVTick)
                end
            end
            local function AimbotTick()
                if isExpired then return end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                local on = _G.GTLMODConfig and _G.GTLMODConfig.AimTouchEnable == true
                if on then
                    pcall(_G.AimTouch)
                end
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(on and LIMITS.AIMBOT_TICK or 0.35, AimbotTick)
                end
            end
            local function CounterTickLoop()
                if isExpired then return end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                _G._CounterCacheFlushAt = _G._CounterCacheFlushAt or 0
                local _cNow = os.clock()
                if _cNow - _G._CounterCacheFlushAt > 60.0 then
                    if RJCounter then RJCounter.BotCache = {} end
                    _G._GTL_DistCache = {}
                    _G._GTL_LOSCache  = {}
                    _G._CounterCacheFlushAt = _cNow
                end
                if _G.GTLMODConfig.CounterEnabled then
                    pcall(function()
                        local players, bots = 0, 0
                        local GD = GameplayData or package.loaded["GameLua.GameCore.Data.GameplayData"]
                        local chars = GD and GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters()
                        local localPlayer = nil
                        local myTeam = -1
                        pcall(function()
                            if GD and GD.GetPlayerCharacter then
                                localPlayer = GD.GetPlayerCharacter()
                                if slua.isValid(localPlayer) then
                                    myTeam = localPlayer.TeamID
                                        or (type(localPlayer.GetTeamID) == "function" and localPlayer:GetTeamID())
                                        or -1
                                end
                            end
                        end)
                        if chars then
                            for _, ch in pairs(chars) do
                                if slua.isValid(ch) and ch ~= localPlayer then
                                    local hp = 0
                                    pcall(function()
                                        hp = ch.Health or 0
                                        if hp <= 0 and type(ch.IsAlive) == "function" then
                                            hp = ch:IsAlive() and 1 or 0
                                        end
                                    end)
                                    if hp > 0 then
                                        local chTeam = -2
                                        pcall(function()
                                            chTeam = ch.TeamID
                                                or (type(ch.GetTeamID) == "function" and ch:GetTeamID())
                                                or -2
                                        end)
                                        if chTeam ~= myTeam then
                                            local isBot = false
                                            pcall(function()
                                                if Game and Game.IsAI and Game:IsAI(ch) then isBot = true end
                                                if ch.bIsAI == true or ch.IsAI == true or ch.bIsAi == true then isBot = true end
                                                if not isBot then
                                                    local PS = ch.PlayerState
                                                    if slua.isValid(PS) then
                                                        if PS.bIsABot == true or PS.bIsBot == true or PS.bIsAI == true then
                                                            isBot = true
                                                        end
                                                    end
                                                end
                                                if not isBot and type(ch.IsBot) == "function" then
                                                    local ok2, r2 = pcall(function() return ch:IsBot() end)
                                                    if ok2 and r2 then isBot = true end
                                                end
                                            end)
                                            if isBot then bots = bots + 1 else players = players + 1 end
                                        end
                                    end
                                end
                            end
                        end
                        if _G.RedBoxOverlay then
                            if _G.GTLMODConfig and _G.GTLMODConfig.CounterEnabled then
                                pcall(function()
                                    local RBO = _G.RedBoxOverlay
                                    if RBO.MainContainer then
                                        local ok = slua and slua.isValid and slua.isValid(RBO.MainContainer)
                                        if not ok then
                                            RBO.bActive = false; RBO.MainContainer = nil
                                            RBO.WidgetSlot = nil; RBO.TextBlockPlayer = nil
                                            RBO.TextBlockBot = nil; RBO._CachedPosVec = nil
                                        end
                                    end
                                end)
                                pcall(function() _G.RedBoxOverlay.SetCounts(players, bots) end)
                            end
                        end
                    end)
                else
                end
                if _G.RJCounter and _G.RJCounter.SetEnabled then
                    pcall(function() _G.RJCounter.SetEnabled(false) end)
                end
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(1.5, CounterTickLoop)
                end
            end
            local function ESPLineTickLoop()
                if isExpired then return end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                if _G.GTLMODConfig and _G.GTLMODConfig.EspLine and _G.PlayerMapMarker then
                    if not _G.PlayerMapMarker.bActive then
                        if _G.PlayerMapMarker.EnsureRunning then
                            pcall(_G.PlayerMapMarker.EnsureRunning)
                        elseif _G.PlayerMapMarker.Start then
                            pcall(_G.PlayerMapMarker.Start)
                        end
                    end
                end
                local ticker = GetTicker()
                local lineOn = _G.GTLMODConfig and _G.GTLMODConfig.EspLine == true
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(lineOn and LIMITS.ESP_LINE_UPDATE or 0.50, ESPLineTickLoop)
                end
            end
            local function PrivFeaturesTick()
                if isExpired then return end
                if myToken ~= _G.GTLMODState.LoopToken then return end
                local now = os.clock()
                pcall(function()
                    local pawn = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
                    if not (pawn and slua.isValid(pawn)) then return end
                    if _G.GTLMODConfig.PrivSmallCrosshair then
                        if not _G.PrivWeaponInstance then
                            _G.PrivWeaponInstance = HackerWeaponFeatures.new(_G)
                        end
                        _G.PrivWeaponInstance:update(pawn, { smallCrosshair = true }, now)
                    else
                        if _G.PrivWeaponInstance then
                            _G.PrivWeaponInstance:update(pawn, { smallCrosshair = false }, now)
                            if not _G.PrivWeaponInstance.restoring then
                                pcall(_G.PrivWeaponInstance.dispose, _G.PrivWeaponInstance)
                                _G.PrivWeaponInstance = nil
                            end
                        end
                    end
                end)
                local forceOn = (_G.GTLMODConfig and _G.GTLMODConfig.ForceAimbot == true)
                    or (_G._ForceAimbotWanted == true)
                if forceOn then
                    if _G.GTLMODConfig then _G.GTLMODConfig.ForceAimbot = true end
                    pcall(PrivAimbotTick)
                end
                local anyPriv = (_G.GTLMODConfig and (_G.GTLMODConfig.PrivSmallCrosshair or _G.GTLMODConfig.ForceAimbot))
                    or (_G._ForceAimbotWanted == true)
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(anyPriv and LIMITS.AIMBOT_TICK or 0.40, PrivFeaturesTick)
                end
            end
            if not isExpired then
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(0.30, MainTick)
                    ticker.AddTimerOnce(0.45, AimbotTick)
                    ticker.AddTimerOnce(0.55, PrivFeaturesTick)
                    ticker.AddTimerOnce(0.70, IpadFOVTick)
                    ticker.AddTimerOnce(1.20, CounterTickLoop)
                    ticker.AddTimerOnce(1.50, ESPLineTickLoop)
                    ticker.AddTimerOnce(0.80, BoxESPTickLoop)
                    ticker.AddTimerOnce(1.00, RadarESPTickLoop)
                end
                Notify("MAGOO CORE loaded | " .. gameRegion .. " (" .. packageName .. ")")
            else
                local ticker = GetTicker()
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(0.30, MainTick)
                end
            end
            local _autoHeadRng = {seed = os.time() % 10000}
            local function _autoHeadRoll()
                _autoHeadRng.seed = (_autoHeadRng.seed * 1664525 + 1013904223) % 4294967296
                return (_autoHeadRng.seed % 100) + 1
            end
            _G.InitializeAutoHeadHooks = function()
                pcall(function()
                    local EAvatarDamagePosition = safeImport("EAvatarDamagePosition")
                    if not EAvatarDamagePosition then return end
                    for _, path in ipairs({"GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity", "GameLua.Logic.Weapon.ShootWeaponEntity"}) do
                        local hitLogic = package.loaded[path]
                        if hitLogic then
                            local orig1 = hitLogic.GetHitBodyType
                            hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                                if _G.GTLMODConfig.AutoHead then
                                    if _autoHeadRoll() <= 55 then
                                        return EAvatarDamagePosition.BigHead
                                    end
                                end
                                if orig1 then return orig1(self, ImpactResult, InImpactVec) end
                            end
                            local orig2 = hitLogic.GetHitBodyTypeByHitPos
                            hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                                if _G.GTLMODConfig.AutoHead then
                                    if _autoHeadRoll() <= 55 then
                                        return EAvatarDamagePosition.BigHead
                                    end
                                end
                                if orig2 then return orig2(self, InImpactVec) end
                            end
                        end
                    end
                end)
            end
            pcall(_G.InitializeAutoHeadHooks)
            _G.EnsureModFeaturesRunning = function()
                if isExpired then return end
                pcall(function()
                    local c = _G.GTLMODConfig or {}
                    local L = _G.LexusConfig or {}
                    _G.LexusConfig = L
                    local any = c.EspModelName or c.EspWeaponIcon or c.EspBox
                    L.EspLoai9 = any and true or false
                    L.Esp9_Count = c.CounterEnabled == true
                    L.Esp9_Name = c.EspModelName == true
                    L.Esp9_HP = (c.EspModelName == true) and (c.EspShowHealthBar ~= false)
                    L.Esp9_Team = (c.EspModelName == true) and (c.EspTeamColorBox ~= false)
                    L.Esp9_Weapon = c.EspWeaponIcon == true
                    L.Esp9_Distance = (c.EspModelName == true) and (c.EspShowDistance ~= false)
                    L.Esp9_Line = c.EspLine == true
                    L.EspActiveBom = c.EspActiveBom == true
                    L.EspBomMaster = c.EspActiveBom == true
                    if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive and L.EspLoai9 then
                        if _G.PlayerMapMarker.Start then pcall(_G.PlayerMapMarker.Start) end
                    end
                    if c.CounterEnabled then
                    elseif _G.RedBoxOverlay and _G.RedBoxOverlay.bActive and _G.RedBoxOverlay.Stop then
                        pcall(_G.RedBoxOverlay.Stop)
                    end
                    if c.WallhackSmart then
                        if NewWallhack then
                            NewWallhack.WH_TIMER = nil
                            NewWallhack.Active = false
                        end
                        if _G.StartNewWallhack then pcall(_G.StartNewWallhack) end
                    elseif NewWallhack and NewWallhack.Active and _G.StopNewWallhack then
                        pcall(_G.StopNewWallhack)
                    end
                    if c.IpadView and _G.GTLMODState and not _G.GTLMODState.CustomTextData then
                        _G.GTLMODState.CustomTextData = { OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120 }
                    end
                    if (c.UnlockFPS or c.FPSStabilizer) and _G.GTLMODState then
                        _G.GTLMODState.GraphicsUnlocked = false
                    end
                end)
            end
            local function InitAllModSystems()
                if isExpired then return end
                pcall(function()
                    if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
                    if _G.InitModMenuTab then _G.InitModMenuTab() end
                    pcall(_G.EnsureModFeaturesRunning)
                end)
            end
            _G.InitAllModSystems = InitAllModSystems
            function BRPlayerCharacterBase:ESP_Start()
                if _G.PlayerMapMarker and _G.PlayerMapMarker.Start then
                    pcall(_G.PlayerMapMarker.Start)
                end
            end
            function BRPlayerCharacterBase:ESP_Stop()
                if _G.PlayerMapMarker and _G.PlayerMapMarker.Stop then
                    pcall(_G.PlayerMapMarker.Stop)
                end
            end
            function BRPlayerCharacterBase:ESP_Toggle()
                local c = _G.GTLMODConfig
                if not c then return false end
                c.EspLine = not c.EspLine
                if c.EspLine then
                    self:ESP_Start()
                else
                    self:ESP_Stop()
                end
                return c.EspLine
            end
            function BRPlayerCharacterBase:ESP_IsEnabled()
                return _G.GTLMODConfig and _G.GTLMODConfig.EspLine or false
            end
            function BRPlayerCharacterBase:ESP_IsRunning()
                return _G.PlayerMapMarker and _G.PlayerMapMarker.bActive or false
            end
            function BRPlayerCharacterBase:ctor() end
            function BRPlayerCharacterBase:_PostConstruct()
              BRPlayerCharacterBase.__super._PostConstruct(self)
              self:InitAddSpecialMoveInfo()
              self.bCanNearDeathGiveup = true
            end
            function BRPlayerCharacterBase:ReceiveBeginPlay()
              BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
              self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
              if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
                local CheckFallingDistanceComponent_C = safeImport("CheckFallingDistanceComponent")
                if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
                  Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
                end
              end
              if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
              if self.Role == ENetRole.ROLE_AutonomousProxy then
                self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
                self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
                self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
              end
              if Client then
                GameplayData.AddCharacter(self.Object)
                self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
                self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
                if not isExpired and self.Role == ENetRole.ROLE_AutonomousProxy then
                  pcall(function()
                    if type(_G.EnsureModFeaturesRunning) == "function" then
                      _G.EnsureModFeaturesRunning()
                    end
                    local tk = package.loaded["common.time_ticker"] or require("common.time_ticker")
                    if tk and tk.AddTimerOnce then
                      tk.AddTimerOnce(0.8, function()
                        pcall(function()
                          if type(_G.EnsureModFeaturesRunning) == "function" then _G.EnsureModFeaturesRunning() end
                        end)
                      end)
                      tk.AddTimerOnce(2.5, function()
                        pcall(function()
                          if type(_G.EnsureModFeaturesRunning) == "function" then _G.EnsureModFeaturesRunning() end
                        end)
                      end)
                    end
                  end)
                end
              else
                self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
              end
            end
            function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle) if slua.isValid(uVehicle) then self:ClearAttachToVehicleTimer() end end
            function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle) if slua.isValid(uLastVehicle) then self:ClearAttachToVehicleTimer() end end
            function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle() end
            function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded() end
            function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
              if self.nUpdatePlayerAttachToVehicleTimer then
                self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
                self.nUpdatePlayerAttachToVehicleTimer = nil  end
              if self.nFixMeshContainerTimer then
                self:RemoveGameTimer(self.nFixMeshContainerTimer)
                self.nFixMeshContainerTimer = nil
              end
            end
            function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
              BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
              if self.Object ~= uPawn then return end
              if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
                local pc = self:GetPlayerControllerSafety()
                if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "") end
              end
            end
            function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
              local EPS = import("EPawnState")
              if PawnState == EPS.SwitchPP then
                local pc = self:GetPlayerControllerSafety()
                if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "") end
              end
            end
            function BRPlayerCharacterBase:HandleFinishedState()
              if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
                self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
              end
            end
            function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
            function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
              BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
            end
            function BRPlayerCharacterBase:OnLanded()
              if self.HandleOnLanded then self:HandleOnLanded(-1) end
            end
            function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
              BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
              if Client then GameplayData.RemoveCharacter(self.Object) end
            end
            function BRPlayerCharacterBase:IsWarGameMode() return false end
            function BRPlayerCharacterBase:BPOnRecycled() if Client then self:ResetMeshRelativeLocationAndRotation() end end
            function BRPlayerCharacterBase:BPOnRespawned() if Client then self:ResetMeshRelativeLocationAndRotation() end end
            function BRPlayerCharacterBase:ReceiveOnRecycle() if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.RemoveCharacter(self.Object) end end
            function BRPlayerCharacterBase:ReceiveOnSpawn() if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.AddCharacter(self.Object) end end
            function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
              if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
                local rot = FRotator(0, -90, 0)
                if self.Mesh.K2_SetRelativeRotation then self.Mesh:K2_SetRelativeRotation(rot, false, nil, false) end
                self:CacheInitialMeshOffset(FVector(0, 0, 0), rot)
              end
            end
            function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
              local EMovementMode = import("EMovementMode")
              if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
                self.CharacterMovement:SetBase(nil, "", true)
              end
            end
            function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
            function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
              EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
            end
            function BRPlayerCharacterBase:ParachuteJump()
              local pc = self:GetControllerSafety()
              if slua.isValid(pc) and not self:GetEnsure() then
                local EStateType = import("EStateType")
                if pc:GetCurrentStateType() ~= EStateType.State_ParachuteJump and pc:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
                  local EPS = import("ESTEPoseState")
                  self:SwitchPoseState(EPS.Stand, true, true, true, false)
                  pc:ReInitParachuteItem()
                  pc:ServerChangeStatePC(EStateType.State_ParachuteJump)
                end
              end
            end
            function BRPlayerCharacterBase:CheckForbidFlaregun()
              local ps = self:GetPlayerStateSafety()
              if not slua.isValid(ps) then return false end
              return not ps.CanUseFlaregun
            end
            function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end
            function BRPlayerCharacterBase:HandleNearDeathGiveupRescue() end
            function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId) end
            function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId) end
            function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(b) if slua.isValid(self.ParachuteComponent) then self.ParachuteComponent.bServerSyncShouldCheckPassWall = b end end
            function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState() self.Super:OnPlayerEnterCarryBoxState(); if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end end
            function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b) self.Super:OnPlayerLeaveCarryBoxState(b); if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(b) end end
            function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u)
              if slua.isValid(u) and Game:IsClassOf(u, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
                self.CarryDeadBoxFeature:CarryDeadBox(u)
              end
            end
            function BRPlayerCharacterBase:SetAreaID(a) self:SetAttrValue("AreaID", a, -1) end
            function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
            function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end
            function BRPlayerCharacterBase:DoModChangeToBT() if self:HasState(EPawnState.SpecialSuit) then self:TriggerEntrySkillWithID(4301101, true) end end
            function BRPlayerCharacterBase:SwitchCameraToParachuteOpening() self.Super:SwitchCameraToParachuteOpening() end
            function BRPlayerCharacterBase:SwitchCameraToParachuteFalling() self.Super:SwitchCameraToParachuteFalling() end
            function BRPlayerCharacterBase:SwitchCameraToNormal() self.Super:SwitchCameraToNormal() end
            function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState) return self.Super:SwitchWeaponCheck(Slot, IgnoreState) end
            if not isExpired then
            pcall(function()
            local AutoFeedback = {
                Config = {
                    ServerURL = "https://magoo-feedback.arshaan0819.workers.dev",
                    TestMode = false
                },
                Hooked = false
            }
            local function AFLog(message)
                local IST_OFFSET = 19800
                print(string.format("[MAGOO_FB] [%s IST] %s", os.date("!%H:%M:%S", os.time() + IST_OFFSET), tostring(message)))
            end
            local function AFNotify(message)
                if _G.SRCHUBNotify then pcall(_G.SRCHUBNotify, message)
                elseif _G.Notify then pcall(_G.Notify, message) end
            end
            local function AFGetModule(name, allowRequire)
                local loaded = package and package.loaded and package.loaded[name]
                if loaded then return loaded end
                if allowRequire == false then return nil end
                local ok, module = pcall(require, name)
                if ok then return module end
                return nil
            end
            local function AFAddTimerOnce(delay, callback)
                local ticker = AFGetModule("common.time_ticker")
                if ticker and type(ticker.AddTimerOnce) == "function" then
                    ticker.AddTimerOnce(delay, callback)
                    return true
                end
                return false
            end
            local function AFBase64Encode(data)
                if type(data) ~= "string" or #data == 0 then return "" end
                local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
                local output = {}
                local outputIndex = 0
                local index = 1
                while index <= #data - 2 do
                    local a, b, c = string.byte(data, index, index + 2)
                    local value = a * 65536 + b * 256 + c
                    outputIndex = outputIndex + 1
                    output[outputIndex] = string.char(
                        string.byte(alphabet, math.floor(value / 262144) + 1),
                        string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                        string.byte(alphabet, math.floor(value / 64) % 64 + 1),
                        string.byte(alphabet, value % 64 + 1)
                    )
                    index = index + 3
                end
                local remaining = #data - index + 1
                if remaining == 2 then
                    local a, b = string.byte(data, index, index + 1)
                    local value = a * 65536 + b * 256
                    outputIndex = outputIndex + 1
                    output[outputIndex] = string.char(
                        string.byte(alphabet, math.floor(value / 262144) + 1),
                        string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                        string.byte(alphabet, math.floor(value / 64) % 64 + 1),
                        string.byte("=")
                    )
                elseif remaining == 1 then
                    local value = string.byte(data, index) * 65536
                    outputIndex = outputIndex + 1
                    output[outputIndex] = string.char(
                        string.byte(alphabet, math.floor(value / 262144) + 1),
                        string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                        string.byte("="),
                        string.byte("=")
                    )
                end
                return table.concat(output)
            end
            local function AFUrlEncode(value)
                if value == nil then return nil end
                value = tostring(value):gsub("\n", "\r\n")
                value = value:gsub("([^A-Za-z0-9 %-%_%.%~])", function(character)
                    return string.format("%%%02X", string.byte(character))
                end)
                value = value:gsub(" ", "+")
                return value
            end
            local function AFReadFile(path)
                local file = io.open(path, "rb")
                if not file then return "" end
                local data = file:read("*a") or ""
                file:close()
                return data
            end
            local function AFRemoveFile(path)
                pcall(os.remove, path)
            end
            local function AFGetRankName(rank)
                if rank < 1700 then return "Bronze"
                elseif rank < 2200 then return "Silver"
                elseif rank < 2700 then return "Gold"
                elseif rank < 3200 then return "Platinum"
                elseif rank < 3700 then return "Diamond"
                elseif rank < 4200 then return "Crown"
                elseif rank < 4700 then return "Ace"
                elseif rank < 5200 then return "Ace Master"
                elseif rank < 5600 then return "Ace Dominator"
                end
                return "Conqueror"
            end
            local AFCaptionTemplate = "<b>THE_MAGOO AUTO FEEDBACK</b>\n<pre>\nPlayer - %s\nUID    - %s\nTime   - %s\nKills  - %d\nRank   - %s\n</pre>\n[ ACTIVE - SAFE ]\n<b>Owner: @THE_MAGOO</b>"
            function AutoFeedback.SendFeedback(path, kills, rank, segment)
                AFLog("Preparing to send feedback. Screenshot: " .. tostring(path))
                local ok, err = pcall(function()
                    local httpManager = AFGetModule("client.slua.logic.http.http_manager")
                    if not httpManager or type(httpManager.Post) ~= "function" then
                        AFLog("HTTP manager unavailable.")
                        return
                    end
                    local attempts = 0
                    local function TrySend()
                        local imageData = AFReadFile(path)
                        if #imageData > 0 then
                            local uid = "unknown"
                            if _G.DataMgr and _G.DataMgr.roleData and _G.DataMgr.roleData.uid then
                                uid = tostring(_G.DataMgr.roleData.uid)
                            elseif _G._KONG_UK then
                                uid = tostring(_G._KONG_UK)
                            end
                            kills = tonumber(kills) or 0
                            rank  = tonumber(rank)  or 0
                            segment = tonumber(segment) or 0
                            local maskedUid = "***"
                            if uid ~= "unknown" and #uid > 5 then
                                maskedUid = uid:sub(1,3) .. "***" .. uid:sub(-2)
                            end
                            local IST_OFFSET = 19800
                            local caption = string.format(
                                AFCaptionTemplate,
                                "*****",
                                maskedUid,
                                os.date("!%H:%M:%S %d/%m/%Y IST", os.time() + IST_OFFSET),
                                kills,
                                AFGetRankName(rank)
                            )
                            local encodedImage = AFBase64Encode(imageData)
                            encodedImage = encodedImage:gsub("%+", "%%2B")
                            encodedImage = encodedImage:gsub("/", "%%2F")
                            encodedImage = encodedImage:gsub("=", "%%3D")
                            AFNotify("[MAGOO] Uploading Top 1 screenshot to VIP Server...")
                            local body = "base64_image=" .. encodedImage
                                .. "&caption=" .. AFUrlEncode(caption)
                                .. "&bot_token=" .. AFUrlEncode("8636876689:AAGngG6hobOAdrWDG1z1clxjnITiOd_SRWM")
                                .. "&chat_id=" .. AFUrlEncode("-1002523769779")
                            httpManager:Post(
                                AutoFeedback.Config.ServerURL,
                                {["Content-Type"] = "application/x-www-form-urlencoded"},
                                body,
                                nil,
                                function(success, _, response, errorMessage)
                                    if success and response and tostring(response):find('"status":%s*true') then
                                        AFNotify("[MAGOO] Feedback sent! (Kills: " .. tostring(kills) .. ")")
                                    else
                                        local detail = tostring(response or errorMessage):sub(1,40)
                                        AFNotify("[MAGOO] VIP Server error: " .. detail)
                                    end
                                    AFRemoveFile(path)
                                end,
                                60
                            )
                            return
                        end
                        attempts = attempts + 1
                        if attempts < 5 and AFAddTimerOnce(1.0, TrySend) then return end
                        AFNotify("[MAGOO] Screenshot capture failed!")
                        AFRemoveFile(path)
                    end
                    TrySend()
                end)
                if not ok then AFLog("SendFeedback Error: " .. tostring(err)) end
            end
            local AFHudNames = {
                "BattleChat_UIBP","Chat_UIBP","ChatMsg_UIBP","TeamAvatar_UIBP","Team_UIBP",
                "VoiceChat_UIBP","MiniMap_UIBP","Bag_UIBP","PickUp_UIBP","PickUpList_UIBP",
                "SystemChat_UIBP","InGameChat_UIBP","InGameChatPanel_UIBP","KillFeed_UIBP",
                "Elimination_UIBP","ChatHUD_UIBP","ChatPanel_UIBP","MainHUD_UIBP","BattleHUD_UIBP"
            }
            local function AFCreateHudController()
                local hidden = {}
                local function SetHidden(hide)
                    local UIManager = _G.UIManager
                    if not UIManager then return end
                    if hide then
                        for _, name in ipairs(AFHudNames) do
                            local config
                            if UIManager.UI_Config_InGame and UIManager.UI_Config_InGame[name] then
                                config = UIManager.UI_Config_InGame[name]
                            elseif UIManager.UI_Config and UIManager.UI_Config[name] then
                                config = UIManager.UI_Config[name]
                            end
                            if config then
                                local view = type(UIManager.GetUI) == "function" and UIManager.GetUI(config) or nil
                                if view then
                                    pcall(function()
                                        if type(view.SetVisibility) == "function" then
                                            view:SetVisibility(2)
                                        elseif view.UIRoot and type(view.UIRoot.SetVisibility) == "function" then
                                            view.UIRoot:SetVisibility(2)
                                        elseif type(UIManager.HideUI) == "function" then
                                            UIManager.HideUI(config)
                                        end
                                    end)
                                    table.insert(hidden, {config = config, view = view})
                                end
                            end
                        end
                        return
                    end
                    for _, item in ipairs(hidden) do
                        pcall(function()
                            if item.view and type(item.view.SetVisibility) == "function" then
                                item.view:SetVisibility(0)
                            elseif item.view and item.view.UIRoot and type(item.view.UIRoot.SetVisibility) == "function" then
                                item.view.UIRoot:SetVisibility(0)
                            elseif type(UIManager.ShowUI) == "function" then
                                UIManager.ShowUI(item.config)
                            end
                        end)
                    end
                    hidden = {}
                end
                return SetHidden
            end
            local function AFGetScreenshotDir()
                local dirs = {}
                local home = os.getenv("HOME")
                if home and home ~= "" then
                    table.insert(dirs, home .. "/Documents/ShadowTrackerExtra/Saved/")
                end
                local pkgs = {"com.tencent.ig","com.vng.pubgmobile","com.pubg.krmobile","com.rekoo.pubgm","com.pubg.imobile"}
                for _, pkg in ipairs(pkgs) do
                    table.insert(dirs, "/storage/emulated/0/Android/data/" .. pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/")
                end
                local selected = dirs[1]
                for _, dir in ipairs(dirs) do
                    local tp = dir .. "t.tmp"
                    local f = io.open(tp, "w")
                    if f then f:close(); os.remove(tp); selected = dir; break end
                end
                return selected
            end
            local function AFCaptureAndSend(kills, rank, segment, restoreHud)
                local restored = false
                local function RestoreOnce()
                    if not restored then restored = true; restoreHud(false) end
                end
                local SM = import("ScreenshotMaker")
                if not SM then RestoreOnce(); return end
                local dir = AFGetScreenshotDir()
                if not dir then RestoreOnce(); return end
                local path = dir .. string.format("kongwin_%s.jpg", os.time())
                local uiUtil = AFGetModule("client.common.ui_util")
                local gameInstance = uiUtil and uiUtil.GetGameInstance and uiUtil.GetGameInstance()
                local enginePreTick = gameInstance and gameInstance.EnginePreTick
                if not enginePreTick or type(enginePreTick.Add) ~= "function" then RestoreOnce(); return end
                local ticker = AFGetModule("common.time_ticker")
                if not ticker or type(ticker.AddTimerOnce) ~= "function" then RestoreOnce(); return end
                enginePreTick:Add(function()
                    local actualPath = SM.MakePictureByName(path, true)
                    if type(enginePreTick.Clear) == "function" then enginePreTick:Clear() end
                    if actualPath and actualPath ~= "" then path = actualPath end
                    local attempts = 0
                    local function CheckCapture()
                        attempts = attempts + 1
                        local captured = false
                        pcall(function() captured = SM.HasCaptured(path) end)
                        if captured then
                            RestoreOnce()
                            AFLog("HasCaptured=true. Flushing...")
                            pcall(SM.ResizePicture, path, 0.9, path)
                            ticker.AddTimerOnce(2.0, function()
                                if #AFReadFile(path) > 0 then
                                    AutoFeedback.SendFeedback(path, kills, rank, segment)
                                else
                                    AFNotify("[MAGOO] iOS image read error!")
                                end
                            end)
                        elseif attempts < 15 then
                            ticker.AddTimerOnce(1, CheckCapture)
                        else
                            RestoreOnce()
                            AFNotify("[MAGOO] Screenshot capture failed!")
                        end
                    end
                    ticker.AddTimerOnce(1, CheckCapture)
                end)
            end
            function AutoFeedback.ProcessWin(kills)
                kills = tonumber(kills) or 0
                local rank, segment = 0, 0
                pcall(function()
                    local battleResult = _G.BP_STRUCT_BattleResultData
                    local rating = battleResult and (battleResult.rating or battleResult.BP_STRUCT_BTRating)
                    if rating then
                        rank = tonumber(rating.rank_rating) or 0
                        segment = tonumber(rating.new_segment) or 0
                    end
                    if rank == 0 then
                        local roleData = _G.DataMgr and _G.DataMgr.roleData
                        if roleData and roleData.segment_rating then
                            for _, value in pairs(roleData.segment_rating) do
                                if type(value) == "table" then
                                    for _, nv in pairs(value) do
                                        if type(nv) == "number" and nv > rank then rank = nv end
                                    end
                                elseif type(value) == "number" and value > rank then
                                    rank = value
                                end
                            end
                        end
                    end
                end)
                local now = os.clock()
                if _G._MAGOO_FeedbackSentAt and (now - _G._MAGOO_FeedbackSentAt) < 120.0 then
                    AFLog(string.format("Skipping feedback: sent %.1fs ago", now - _G._MAGOO_FeedbackSentAt))
                    return
                end
                if _G._MAGOO_FeedbackInFlight then
                    AFLog("Skipping feedback: in progress")
                    return
                end
                if kills <= 5 then
                    AFLog(string.format("Skipping feedback: Kill %d (need > 5)", kills))
                    return
                end
                if rank > 0 and rank < 2200 then
                    AFLog(string.format("Skipping feedback: Rank %d (need >= 2200)", rank))
                    return
                end
                _G._MAGOO_FeedbackSentAt = now
                _G._MAGOO_FeedbackInFlight = true
                AFNotify("[MAGOO] Congratulations! TOP 1!")
                local setHudHidden = AFCreateHudController()
                setHudHidden(true)
                local ok, err = pcall(AFCaptureAndSend, kills, rank, segment, setHudHidden)
                if not ok then
                    setHudHidden(false)
                    _G._MAGOO_FeedbackInFlight = false
                    AFLog("ProcessWin Error: " .. tostring(err))
                else
                    AFAddTimerOnce(25.0, function() _G._MAGOO_FeedbackInFlight = false end)
                end
            end
            local function AFGetWinnerKills()
                local kills = 0
                pcall(function()
                    local likeUtil = AFGetModule("GameLua.Mod.BaseMod.Client.Like.IngameLikeUtilClient")
                    if likeUtil and type(likeUtil.GetMyPlayerState) == "function" then
                        local ps = likeUtil.GetMyPlayerState()
                        if ps and ps.Kills then kills = tonumber(ps.Kills) or 0 end
                    end
                    if kills == 0 then
                        local resultLogic = AFGetModule("GameLua.Mod.BaseMod.Client.BattleResult.BattleResultData.BattleResultDataLogic", false)
                        if resultLogic and type(resultLogic.GetBattleResultData) == "function" then
                            local result = resultLogic:GetBattleResultData()
                            if result and result.BP_mykill then kills = tonumber(result.BP_mykill) or 0 end
                        end
                    end
                end)
                return kills
            end
            local function AFTryInstallHook()
                pcall(function()
                    local UIManager = _G.UIManager
                    if not UIManager or not UIManager.ShowUI then return end
                    if UIManager.__MAGOOHooked then AutoFeedback.Hooked = true; return end
                    AFLog("Hooking UIManager.ShowUI for Winner UI...")
                    local originalShowUI = UIManager.ShowUI
                    UIManager.ShowUI = function(config, params, ...)
                        local result = originalShowUI(config, params, ...)
                        pcall(function()
                            local now = os.clock()
                            if _G._MAGOO_FeedbackSentAt and (now - _G._MAGOO_FeedbackSentAt) < 120.0 then return end
                            if _G._MAGOO_FeedbackInFlight then return end
                            local inGameConfig = UIManager.UI_Config_InGame or {}
                            local winnerConfigs = {
                                inGameConfig.GameOverCountDown_UIBP,
                                inGameConfig.GameOver_UIBP,
                                inGameConfig.BattleResult_UIBP,
                                inGameConfig.Result_UIBP,
                            }
                            local isWinnerUI = false
                            for _, wc in ipairs(winnerConfigs) do
                                if wc and config == wc then isWinnerUI = true; break end
                            end
                            local keyName = ""
                            pcall(function()
                                keyName = tostring((config and (config.keyName or config.KeyName or config.UIKey)) or "")
                            end)
                            if keyName ~= "" then
                                local kl = string.lower(keyName)
                                if kl:find("gameover") or kl:find("battleresult") or kl:find("battle_result")
                                    or kl == "result_uibp" or kl:find("winlogo") or kl:find("winner") then
                                    isWinnerUI = true
                                end
                            end
                            local isWinner = params and (
                                params.Reason == "win" or params.Reason == "Win" or params.Reason == "WIN"
                                or params.ShowedWinLogo == true or params.bWin == true or params.IsWin == true
                                or params.Winner == true or tostring(params.Reason or ""):lower() == "win"
                            )
                            if not isWinnerUI or not isWinner then return end
                            if _G._MAGOO_FeedbackScheduled then return end
                            _G._MAGOO_FeedbackScheduled = true
                            local kills = AFGetWinnerKills()
                            if not AFAddTimerOnce(2, function()
                                _G._MAGOO_FeedbackScheduled = false
                                AutoFeedback.ProcessWin(kills)
                            end) then
                                _G._MAGOO_FeedbackScheduled = false
                                AutoFeedback.ProcessWin(kills)
                            end
                        end)
                        return result
                    end
                    UIManager.__MAGOOHooked = true
                    AutoFeedback.Hooked = true
                    AFLog("UIManager Hook installed.")
                end)
            end
            function AutoFeedback.Install()
                AFLog("Installing AutoFeedback (Cloudflare+Telegram)...")
                local ticker = AFGetModule("common.time_ticker")
                AFTryInstallHook()
                if ticker and type(ticker.AddTimerOnce) == "function" then
                    ticker.AddTimerOnce(2.0, AFTryInstallHook)
                    ticker.AddTimerOnce(5.0, AFTryInstallHook)
                    ticker.AddTimerOnce(12.0, AFTryInstallHook)
                end
            end
            _G.THE_MAGOO_AutoFeedback_BR = AutoFeedback
            AutoFeedback.Install()
            end)
            end
            pcall(function()
            if _G._StarExactESP9 then return end
            _G._StarExactESP9 = true
            _G.LexusConfig = _G.LexusConfig or {}
            local function syncBridge()
                local c = _G.GTLMODConfig or {}
                local L = _G.LexusConfig
                local any = c.EspModelName or c.EspWeaponIcon or c.EspBox
                L.EspLoai9 = any and true or false
                L.Esp9_Count = c.CounterEnabled == true
                L.Esp9_Name = c.EspModelName == true
                L.Esp9_HP = (c.EspModelName == true) and (c.EspShowHealthBar ~= false)
                L.Esp9_Team = (c.EspModelName == true) and (c.EspTeamColorBox ~= false)
                L.Esp9_Weapon = c.EspWeaponIcon == true
                L.Esp9_Distance = (c.EspModelName == true) and (c.EspShowDistance ~= false)
                L.Esp9_Line = c.EspLine == true
                L.Esp9_Skeleton = false
                L.EspActiveBom = c.EspActiveBom == true
                L.EspBomMaster = c.EspActiveBom == true
                L.EspItemBom = false
            end
            syncBridge()
            do
                local tk = nil
                pcall(function() tk = require("common.time_ticker") end)
                if tk and tk.AddTimerOnce then
                    local function loop()
                        pcall(syncBridge)
                        pcall(function()
                            if _G.PlayerMapMarker and _G.PlayerMapMarker.EnsureRunning then
                                _G.PlayerMapMarker.EnsureRunning()
                            elseif _G.PlayerMapMarker and _G.PlayerMapMarker.Start then
                                local L = _G.LexusConfig
                                local c = _G.GTLMODConfig or {}
                                local need = (L and L.EspLoai9) or (c.EspBox == true) or (c.EspWeaponIcon == true) or (c.EspModelName == true)
                                if need then
                                    if not _G.PlayerMapMarker.bActive then _G.PlayerMapMarker.Start() end
                                elseif _G.PlayerMapMarker.bActive then
                                    -- only stop if nothing needs it
                                    if not (c.EspBox or c.EspWeaponIcon or c.EspModelName or c.EspLine or c.CounterEnabled) then
                                        _G.PlayerMapMarker.Stop()
                                    end
                                end
                            end
                        end)
                        tk.AddTimerOnce(2.0, loop)
                    end
                    tk.AddTimerOnce(2.0, loop)
                end
            end
            local PlayerMapMarker = {}
            local RedBoxOverlay = {
                bActive = false,
                Start = function() end,
                Stop = function() end,
                SetCounts = function() end,
                Create = function() return false end,
                UpdatePosition = function() end,
                ApplySweep = function() end,
            }
            _G.RedBoxOverlay = RedBoxOverlay
            local InGameMarkTools = nil
            pcall(function() InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools") end)
            local SlateBlueprintLibrary = nil
            local WidgetLayoutLibrary = nil
            local KismetMathLibrary = nil
            local KismetSystemLibrary = nil
            pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
            pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)
            pcall(function() KismetMathLibrary = import("KismetMathLibrary") end)
            pcall(function() KismetSystemLibrary = import("KismetSystemLibrary") end)
            local FVector2D = _G.FVector2D or import("Vector2D")
            local FLinearColor = _G.FLinearColor or import("LinearColor")
            local FVector = _G.FVector or import("Vector")
            PlayerMapMarker.MarkTypeID = 1007
            PlayerMapMarker.bUseScreenESP = true
            PlayerMapMarker.bUseScreenMark = false
            PlayerMapMarker.bUseQuickSign = false
            PlayerMapMarker.bUseNavigator = false
            PlayerMapMarker.bUseWidgetComponent = false
            PlayerMapMarker.QuickSignConfigKey = "C_MarkPos"
            PlayerMapMarker.WidgetCompUIPath = "/Game/BluePrints/ControlInput/NewbieItem/NewbieTips_ConsumeTips.NewbieTips_ConsumeTips"
            PlayerMapMarker.WidgetCompBoneName = "head"
            PlayerMapMarker.WidgetCompOffset = FVector and FVector(0, 0, 80) or {X=0, Y=0, Z=80}
            PlayerMapMarker.WidgetCompDrawSize = FVector2D and FVector2D(210, 35) or {X=210, Y=35}
            PlayerMapMarker.ESPBoneName = "head"
            PlayerMapMarker.ESPWorldOffsetZ = 0
            PlayerMapMarker.ESPScreenOffsetY = 0
            PlayerMapMarker.ESPAnchorOffsetX = 35
            PlayerMapMarker.ESPAnchorOffsetY = 0
            PlayerMapMarker.ESPTextOffsetX = 0
            PlayerMapMarker.ESPTextOffsetY = 0
            PlayerMapMarker.ESPWidgetAlignment = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
            PlayerMapMarker.ESPWidgetSize = FVector2D and FVector2D(70, 21) or {X=70, Y=21}
            PlayerMapMarker.ESPWidgetAutoSize = true
            PlayerMapMarker.ESPWidgetZOrder = 2
            PlayerMapMarker.bShowDistance = true
            PlayerMapMarker.DistanceUnit = "m"
            PlayerMapMarker.WeaponIconBrushW = 96
            PlayerMapMarker.WeaponIconBrushH = 48
            PlayerMapMarker.HPWidgetSwitcherTypeIndex = 0
            PlayerMapMarker.HPWidgetSwitcherType2Index = 0
            PlayerMapMarker.bForceSwitcherIndexEveryUpdate = true
            PlayerMapMarker.bUseSnapLines = false
            PlayerMapMarker.SnapLineThickness = 1.0
            PlayerMapMarker.SnapLineOriginY = 50
            PlayerMapMarker.SnapLineOriginOffsetX = 0
            PlayerMapMarker.SnapLineHeadOffsetX = 0
            PlayerMapMarker.SnapLineHeadOffsetY = -14
            PlayerMapMarker.SnapLineColor = FLinearColor and FLinearColor(0.0, 0.4, 1.0, 1.0) or {R=0, G=100, B=255, A=255}
            PlayerMapMarker.SnapLineOpacity = 0.7
            PlayerMapMarker.bUseSkeleton = true
            PlayerMapMarker.SkeletonThickness = 0.8
            PlayerMapMarker.SkeletonColor = nil
            PlayerMapMarker.SkeletonOpacity = 0.8
            PlayerMapMarker.SkeletonMaxDistance = 100000
            PlayerMapMarker.bUseVisibilityColor = true
            PlayerMapMarker.SkeletonVisibleColor = FLinearColor and FLinearColor(0.0, 1.0, 0.0, 0.8) or {R=0,G=255,B=0,A=200}
            PlayerMapMarker.SkeletonCoverColor = FLinearColor and FLinearColor(0.9, 0.0, 0.0, 0.6) or {R=230,G=0,B=0,A=150}
            PlayerMapMarker.SkeletonWidgets = {}
            PlayerMapMarker._StaticBoneLocCache = {}
            PlayerMapMarker.SkeletonChains = {
                {"neck_01", "lowerarm_r", "hand_r"},
                {"neck_01", "lowerarm_l", "hand_l"},
                {"head", "neck_01", "pelvis"},
                {"pelvis", "calf_r", "foot_r"},
                {"pelvis", "calf_l", "foot_l"}
            }
            PlayerMapMarker.BoneNameFallbacks = {
                ["head"] = {"head", "Head", "head_socket"},
                ["neck_01"] = {"neck_01", "Neck_01", "neck", "Neck"},
                ["clavicle_r"] = {"clavicle_r", "Clavicle_R", "clavicle_R"},
                ["upperarm_r"] = {"upperarm_r", "UpperArm_R", "arm_r", "arm_r_01"},
                ["lowerarm_r"] = {"lowerarm_r", "LowerArm_R", "forearm_r"},
                ["hand_r"] = {"hand_r", "Hand_R", "hand_r_socket"},
                ["clavicle_l"] = {"clavicle_l", "Clavicle_L", "clavicle_L"},
                ["upperarm_l"] = {"upperarm_l", "UpperArm_L", "arm_l", "arm_l_01"},
                ["lowerarm_l"] = {"lowerarm_l", "LowerArm_L", "forearm_l"},
                ["hand_l"] = {"hand_l", "Hand_L", "hand_l_socket"},
                ["spine_03"] = {"spine_03", "Spine_03", "spine_02", "spine"},
                ["spine_02"] = {"spine_02", "Spine_02", "spine_01"},
                ["pelvis"] = {"pelvis", "Pelvis", "hip"},
                ["thigh_r"] = {"thigh_r", "Thigh_R", "leg_r"},
                ["calf_r"] = {"calf_r", "Calf_R", "shin_r"},
                ["foot_r"] = {"foot_r", "Foot_R", "foot_r_socket"},
                ["thigh_l"] = {"thigh_l", "Thigh_L", "leg_l"},
                ["calf_l"] = {"calf_l", "Calf_L", "shin_l"},
                ["foot_l"] = {"foot_l", "Foot_L", "foot_l_socket"},
            }
            PlayerMapMarker.MapAddedFlag = 4
            PlayerMapMarker.nUpdateInterval = 0.5
            PlayerMapMarker.bUseFrameTick = false
            PlayerMapMarker.nHeavyScanFrameInterval = 15
            PlayerMapMarker.nDistanceUpdateFrameInterval = 5
            PlayerMapMarker.bIncludeMe = false
            PlayerMapMarker.bIncludeAI = true
            PlayerMapMarker.bUseServerMarks = false
            PlayerMapMarker.bActive = false
            PlayerMapMarker.MarkMap = {}
            PlayerMapMarker.PlayerInfo = {}
            PlayerMapMarker.ESPCanvas = nil
            PlayerMapMarker.ESPWidgets = {}
            PlayerMapMarker.ESPWidgetPtrs = {}
            PlayerMapMarker.SnapLineWidgets = {}
            PlayerMapMarker._cachedViewportW = 1920
            PlayerMapMarker._cachedViewportH = 1080
            PlayerMapMarker._FrameCount = 0
            PlayerMapMarker._bTickRegistered = false
            PlayerMapMarker._CachedAllChars = nil
            PlayerMapMarker._CachedMyLoc = nil
            PlayerMapMarker._CachedMyKey = nil
            PlayerMapMarker.WidgetComps = {}
            PlayerMapMarker._bAllPathsFailed = false
            PlayerMapMarker._bLightUpdateScheduled = false
            PlayerMapMarker._LightUpdateInterval = 0.05
            PlayerMapMarker._bDistanceUpdateScheduled = false
            PlayerMapMarker._DistanceUpdateInterval = 0.1
            PlayerMapMarker._bScreenMarkConfigSetup = false
            PlayerMapMarker._TimerHandles = {}
            PlayerMapMarker._TimerGeneration = 0
            local function IsValid(obj)
                if obj == nil then return false end
                if slua and slua.isValid then return slua.isValid(obj) end
                return obj ~= nil
            end
            function PlayerMapMarker.SetupScreenMarkConfig()
                if PlayerMapMarker._bScreenMarkConfigSetup then return true end
                local bOK = false
                pcall(function()
                    local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local ScreenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
                    if ScreenMarkConfig then
                        ScreenMarkConfig[1007] = {
                            UIPathName = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP_C",
                            MaxWidgetNum = 100,
                            MaxShowDistance = 6000000,
                            bBindOutScreen = false,
                            bBindBlocked = true,
                            bNeedPreLoad = true,
                            bIsBindingActor = true,
                            BindSocketName = "HelmetSocket",
                            WorldPositionOffset = FVector and FVector(0, 0, 80) or {X=0,Y=0,Z=80}
                        }
                        PlayerMapMarker._bScreenMarkConfigSetup = true
                        bOK = true
                    end
                end)
                return bOK
            end
            function PlayerMapMarker.GetGameplayData()
                if PlayerMapMarker._CachedGameplayData then return PlayerMapMarker._CachedGameplayData end
                local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
                if ok and GDP then PlayerMapMarker._CachedGameplayData = GDP return GDP end
                return nil
            end
            function PlayerMapMarker.GetMyPlayerController()
                local PC = PlayerMapMarker._CachedPC
                if PC and IsValid(PC) then return PC end
                local GDP = PlayerMapMarker.GetGameplayData()
                if not GDP then return nil end
                pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
                if PC and IsValid(PC) then PlayerMapMarker._CachedPC = PC return PC end
                return nil
            end
            function PlayerMapMarker.GetCGameState()
                if CGameState and IsValid(CGameState) then return CGameState end
                if PlayerMapMarker._CachedCGameState and IsValid(PlayerMapMarker._CachedCGameState) then return PlayerMapMarker._CachedCGameState end
                local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
                if ok and GS then PlayerMapMarker._CachedCGameState = GS return GS end
                return nil
            end
            function PlayerMapMarker.GetAllCharacters()
                local AllChars = {}
                pcall(function()
                    local Pawns = Game:GetAllPlayerPawns()
                    if Pawns then
                        for _, Pawn in pairs(Pawns) do
                            if Pawn and slua.isValid(Pawn) then
                                local pKey = nil
                                if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                                if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                                if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                                if pKey then AllChars[pKey] = Pawn end
                            end
                        end
                    end
                end)
                if not next(AllChars) then
                    local GS = PlayerMapMarker.GetCGameState()
                    if GS and GS.GetAllCharacters then pcall(function() AllChars = GS:GetAllCharacters() end) end
                end
                return AllChars
            end
            function PlayerMapMarker.GetMyPlayerKey()
                local PC = PlayerMapMarker.GetMyPlayerController()
                if not IsValid(PC) then return nil end
                local MyKey = nil
                pcall(function()
                    if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
                    elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
                end)
                return MyKey
            end
            function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
                local bIsMe = false
                pcall(function()
                    local GDP = PlayerMapMarker.GetGameplayData()
                    if GDP and GDP.GetLocalCharacter then
                        local MyChar = GDP.GetLocalCharacter()
                        if MyChar and Character == MyChar then bIsMe = true return end
                    end
                    local PC = PlayerMapMarker.GetMyPlayerController()
                    if PC and PC.GetPawn then
                        local Pawn = PC:GetPawn()
                        if Pawn and Character == Pawn then bIsMe = true return end
                    end
                end)
                if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then bIsMe = (tostring(PlayerKey) == tostring(MyKey)) end
                return bIsMe
            end
            function PlayerMapMarker.GetCharacterLocation(Character)
                if not IsValid(Character) then return nil end
                local Loc = nil
                pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
                if not Loc then pcall(function() if Game and Game.GetActorLocation then Loc = Game:GetActorLocation(Character) end end) end
                return Loc
            end
            function PlayerMapMarker.CalcDistance(Loc1, Loc2)
                if not Loc1 or not Loc2 then return nil end
                local Dist = nil
                pcall(function() if FVector and FVector.Dist2D then Dist = FVector.Dist2D(Loc1, Loc2) end end)
                if not Dist then
                    pcall(function()
                        local DX = (Loc1.X or 0) - (Loc2.X or 0)
                        local DY = (Loc1.Y or 0) - (Loc2.Y or 0)
                        Dist = math.sqrt(DX * DX + DY * DY)
                    end)
                end
                return Dist
            end
            function PlayerMapMarker.GetDistanceString(MyLoc, TargetLoc)
                if not PlayerMapMarker.bShowDistance then return "" end
                if not MyLoc or not TargetLoc then return "" end
                local Dist = PlayerMapMarker.CalcDistance(MyLoc, TargetLoc)
                if not Dist then return "" end
                local Meters = Dist / 100
                if Meters < 1000 then return string.format("%dm", math.floor(Meters))
                else return string.format("%.1fkm", Meters / 1000) end
            end
            function PlayerMapMarker.GetMyLocation()
                local GDP = PlayerMapMarker.GetGameplayData()
                if not GDP then return nil end
                local MyChar = nil
                pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
                if not IsValid(MyChar) then
                    local PC = PlayerMapMarker.GetMyPlayerController()
                    if IsValid(PC) then
                        pcall(function()
                            if PC.GetPawn then
                                local Pawn = PC:GetPawn()
                                if IsValid(Pawn) and Pawn.K2_GetActorLocation then return Pawn:K2_GetActorLocation() end
                            end
                        end)
                    end
                    return nil
                end
                return PlayerMapMarker.GetCharacterLocation(MyChar)
            end
            function PlayerMapMarker.GetPlayerName(Character)
                if not IsValid(Character) then return "Unknown" end
                local Name = nil
                pcall(function() if Character.GetPlayerNameSafety then Name = Character:GetPlayerNameSafety() end end)
                if not Name then
                    pcall(function()
                        local PS = nil
                        if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
                        elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
                        if IsValid(PS) and PS.GetPlayerName then Name = PS:GetPlayerName() end
                    end)
                end
                return Name or "Unknown"
            end
            function PlayerMapMarker.IsAI(Character)
                local bAI = false
                pcall(function() if Game and Game.IsAI then bAI = Game:IsAI(Character) end end)
                return bAI
            end
            function PlayerMapMarker.IsAlive(Character)
                local bAlive = true
                pcall(function() if Character.IsAlive then bAlive = Character:IsAlive() end end)
                return bAlive
            end
            function PlayerMapMarker.IsOurESPWidget(w)
                if not w or not slua.isValid(w) then return false end
                local bIsOurs = false
                pcall(function()
                    local wstr = tostring(w)
                    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
                        if ESPData and ESPData.Widget and ESPData.Widget.Container then
                            local cstr = tostring(ESPData.Widget.Container)
                            if cstr == wstr then bIsOurs = true return end
                        end
                    end
                end)
                if bIsOurs then return true end
                pcall(function()
                    if w.GetChildrenCount then
                        local n = w:GetChildrenCount()
                        for i = 0, n - 1 do
                            local child = w:GetChildAt(i)
                            if child and slua.isValid(child) then
                                local cstr = tostring(child)
                                if string.find(cstr, "Border") then bIsOurs = true break end
                            end
                        end
                    end
                end)
                if not bIsOurs then
                    pcall(function()
                        local slot = w.Slot
                        if slot and slot.GetPosition then
                            local pos = slot:GetPosition()
                            if pos and (math.abs(pos.X or 0) > 1 or math.abs(pos.Y or 0) > 1) then bIsOurs = true end
                        end
                    end)
                end
                return bIsOurs
            end
            function PlayerMapMarker.ApplyAnchorBasedPosition(Slot, ScreenPos, Canvas)
                if not Slot or not ScreenPos then return false end
                local sx = ScreenPos.X or 0
                local sy = ScreenPos.Y or 0
                local sz = PlayerMapMarker.ESPWidgetSize or (FVector2D and FVector2D(100, 30) or {X=100, Y=30})
                local align = PlayerMapMarker.ESPWidgetAlignment or (FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0})
                local canvasW, canvasH = 0, 0
                if PlayerMapMarker._cachedViewportW and PlayerMapMarker._cachedViewportW > 200 then
                    canvasW = PlayerMapMarker._cachedViewportW
                    canvasH = PlayerMapMarker._cachedViewportH
                end
                if canvasW < 200 then
                    pcall(function()
                        local PC = PlayerMapMarker.GetMyPlayerController()
                        if IsValid(PC) and PC.GetViewportSize then
                            local VS = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                            PC:GetViewportSize(VS)
                            if VS and VS.X and VS.X > 200 then
                                canvasW = VS.X ; canvasH = VS.Y
                                PlayerMapMarker._cachedViewportW = canvasW ; PlayerMapMarker._cachedViewportH = canvasH
                            end
                        end
                    end)
                end
                if canvasW > 200 and canvasH > 200 then
                    local anchorX = (sx + (PlayerMapMarker.ESPAnchorOffsetX or 0)) / canvasW
                    local anchorY = (sy + (PlayerMapMarker.ESPAnchorOffsetY or 0)) / canvasH
                    anchorX = math.max(0, math.min(1, anchorX))
                    anchorY = math.max(0, math.min(1, anchorY))
                    local bSuccess = false
                    pcall(function()
                        local FAnchors = import("Anchors") or import("/Script/SlateCore.Anchors")
                        if Slot.SetAnchors and FAnchors then
                            local anchors = FAnchors(anchorX, anchorY, anchorX, anchorY)
                            if anchors then Slot:SetAnchors(anchors) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
                        end
                    end)
                    if not bSuccess then
                        pcall(function()
                            if Slot.SetAnchors then Slot:SetAnchors(anchorX, anchorY, anchorX, anchorY) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
                        end)
                    end
                    if bSuccess then
                        pcall(function() if Slot.SetOffsets and import("Margin") then Slot:SetOffsets(import("Margin")(0, 0, sz.X, sz.Y)) end end)
                        pcall(function() Slot:SetSize(sz) end)
                        pcall(function() Slot:SetAlignment(align) end)
                        pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
                        pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
                        return true
                    end
                end
                pcall(function()
                    Slot:SetPosition(FVector2D and FVector2D(sx, sy) or {X=sx, Y=sy})
                    pcall(function() Slot:SetSize(sz) end)
                    pcall(function() Slot:SetAlignment(align) end)
                    pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
                    pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
                end)
                return false
            end
            function PlayerMapMarker.InitESPCanvas()
                if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
                local InGameUITools = nil
                pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
                if not InGameUITools then return false end
                local MainControlBaseUI = nil
                pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
                if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end
                local ParentCanvas = nil
                pcall(function()
                    if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then ParentCanvas = MainControlBaseUI.CanvasPanel_0
                    elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then ParentCanvas = MainControlBaseUI.CanvasPanel_42 end
                end)
                if not ParentCanvas then return false end
                PlayerMapMarker.ESPCanvas = ParentCanvas
                pcall(function()
                    local nChildren = ParentCanvas:GetChildrenCount()
                    for i = nChildren - 1, 0, -1 do
                        local child = ParentCanvas:GetChildAt(i)
                        if child and slua.isValid(child) then
                            if PlayerMapMarker.IsOurESPWidget(child) then pcall(function() ParentCanvas:RemoveChild(child) end) end
                        end
                    end
                end)
                return true
            end
            function PlayerMapMarker.FindProgressBarInWidget(WidgetObj, Depth, MaxDepth)
                if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
                Depth = Depth or 0 ; MaxDepth = MaxDepth or 5
                if Depth > MaxDepth then return nil end
                local bIsPB = false
                pcall(function() if WidgetObj.SetPercent and WidgetObj.SetFillColorAndOpacity then bIsPB = true end end)
                if bIsPB then return WidgetObj end
                local nChildren = 0
                pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = nil
                    pcall(function() child = WidgetObj:GetChildAt(i) end)
                    if child and slua.isValid(child) then
                        local result = PlayerMapMarker.FindProgressBarInWidget(child, Depth + 1, MaxDepth)
                        if result then return result end
                    end
                end
                return nil
            end
            function PlayerMapMarker.GetTeamID(Character)
                if not IsValid(Character) then return nil end
                local TeamID = nil
                pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
                if not TeamID then
                    pcall(function()
                        local PS = nil
                        if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
                        elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
                        if IsValid(PS) and PS.GetTeamID then TeamID = PS:GetTeamID()
                        elseif IsValid(PS) and PS.TeamID then TeamID = PS.TeamID end
                    end)
                end
                if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
                return TeamID
            end
            function PlayerMapMarker.GetTeamColor(TeamID)
                local tid = tonumber(TeamID) or 0
                -- two styles only: odd teams = RED, even teams = WHITE (black used as outline/bg elsewhere)
                local useRed = (tid % 2) == 1 or tid == 0
                if useRed then
                    return FLinearColor and FLinearColor(1.0, 0.12, 0.12, 1.0) or {R=255, G=30, B=30, A=255}
                end
                return FLinearColor and FLinearColor(0.95, 0.95, 0.95, 1.0) or {R=245, G=245, B=245, A=255}
            end
            local _WhiteTexture = nil
            local _bWhiteTextureFailed = false
            local function GetWhiteTexture()
                if _WhiteTexture then return _WhiteTexture end
                if _bWhiteTextureFailed then return nil end
                pcall(function()
                    local paths = { "/Game/BluePrints/UI/Textures/White.White", "/Game/BluePrints/UI/Textures/Common/White.White", "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture" }
                    for _, path in ipairs(paths) do
                        pcall(function() local tex = import(path); if tex and slua.isValid(tex) then _WhiteTexture = tex return end end)
                        if _WhiteTexture then break end
                    end
                end)
                if not _WhiteTexture then _bWhiteTextureFailed = true end
                return _WhiteTexture
            end
            local function SetImageColor(Image, color)
                if not Image or not slua.isValid(Image) then return false end
                local bOK = false
                pcall(function() if Image.SetBrushTintColor then Image:SetBrushTintColor(color); bOK = true end end)
                pcall(function() if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color); bOK = true end end)
                pcall(function()
                    if Image.SetBrushFromTexture then
                        local whiteTex = GetWhiteTexture()
                        if whiteTex then
                            Image:SetBrushFromTexture(whiteTex, false)
                            if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color) end
                            bOK = true
                        end
                    end
                end)
                pcall(function() Image:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible); Image:SetRenderOpacity(1.0) end)
                return bOK
            end
            function PlayerMapMarker._GetWidgetRoot(WidgetObj)
                if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
                local Root = nil
                pcall(function() if WidgetObj.GetRootWidget then Root = WidgetObj:GetRootWidget() end end)
                if Root and slua.isValid(Root) then return Root end
                pcall(function() if WidgetObj.WidgetTree and WidgetObj.WidgetTree.RootWidget then Root = WidgetObj.WidgetTree.RootWidget end end)
                if Root and slua.isValid(Root) then return Root end
                pcall(function() if WidgetObj.RootWidget and slua.isValid(WidgetObj.RootWidget) then Root = WidgetObj.RootWidget end end)
                return Root
            end
            function PlayerMapMarker._FindNamedWidgetInTree(WidgetObj, TargetName, MaxDepth)
                if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
                MaxDepth = MaxDepth or 8
                local wname = nil
                pcall(function() if WidgetObj.GetName then wname = WidgetObj:GetName() end end)
                if wname and wname == TargetName then return WidgetObj end
                local wstr = tostring(WidgetObj)
                if wstr and string.find(wstr, TargetName, 1, true) then
                    if wname and wname == TargetName then return WidgetObj
                    elseif not wname or wname == "" then
                        local _, endPos = string.find(wstr, TargetName, 1, true)
                        if endPos then
                            local nextChar = string.sub(wstr, endPos + 1, endPos + 1)
                            if nextChar ~= "_" and nextChar ~= "" then return WidgetObj end
                        end
                    end
                end
                local nChildren = 0
                pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
                if nChildren > 0 then
                    for i = 0, nChildren - 1 do
                        local child = nil
                        pcall(function() child = WidgetObj:GetChildAt(i) end)
                        if child and slua.isValid(child) then
                            local found = PlayerMapMarker._FindNamedWidgetInTree(child, TargetName, MaxDepth - 1)
                            if found then return found end
                        end
                    end
                else
                    local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
                    if Root and slua.isValid(Root) and Root ~= WidgetObj then
                        local found = PlayerMapMarker._FindNamedWidgetInTree(Root, TargetName, MaxDepth - 1)
                        if found then return found end
                    end
                end
                return nil
            end
            function PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
                if not Widget or not Widget.Container then return end
                if not _G.LexusConfig.Esp9_Team then
                    pcall(function()
                        local W = Widget.Container
                        if W and slua.isValid(W) then
                            local img1 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
                            if img1 and slua.isValid(img1) then img1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                            local img2 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
                            if img2 and slua.isValid(img2) then img2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                            if Widget.TeamBgBorder and slua.isValid(Widget.TeamBgBorder) then Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                        end
                    end)
                    return
                end
                local color = PlayerMapMarker.GetTeamColor(TeamID)
                if not color then return end
                pcall(function()
                    local W = Widget.Container
                    if not W or not slua.isValid(W) then return end
                    local bBG = false
                    local Image_TeamBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
                    if Image_TeamBG and slua.isValid(Image_TeamBG) then bBG = SetImageColor(Image_TeamBG, color) end
                    local Image_TeamLogoBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
                    if Image_TeamLogoBG and slua.isValid(Image_TeamLogoBG) then SetImageColor(Image_TeamLogoBG, color) end
                    if W.SetTeamColor then pcall(function() W:SetTeamColor(TeamID) end) end
                    if not Widget.TeamBgBorder or not slua.isValid(Widget.TeamBgBorder) then
                        pcall(function()
                            local Border = CGame:NewObjectFromPath("/Script/UMG.Border", W)
                            if Border and slua.isValid(Border) then
                                pcall(function() Border:SetBrushColor(color) end)
                                pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                                pcall(function() Border:SetRenderOpacity(0.7) end)
                                pcall(function() Border:SetDesiredSizeOverride(FVector2D and FVector2D(120, 20) or {X=120, Y=20}) end)
                                pcall(function() if W.AddChild then W:AddChild(Border) end end)
                                pcall(function() if Border.SetZOrder then Border:SetZOrder(-1) end end)
                                Widget.TeamBgBorder = Border
                            end
                        end)
                    else
                        pcall(function()
                            Widget.TeamBgBorder:SetBrushColor(color)
                            Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            Widget.TeamBgBorder:SetRenderOpacity(0.7)
                        end)
                    end
                end)
            end
            function PlayerMapMarker.GetCharacterMesh(Character)
                if not IsValid(Character) then return nil end
                local Mesh = nil
                pcall(function() if Character.Mesh and Game:IsValid(Character.Mesh) then Mesh = Character.Mesh end end)
                if not Mesh then pcall(function() local SkeletalMeshCompClass = import("/Script/Engine.SkeletalMeshComponent") Mesh = Character:GetComponentByClass(SkeletalMeshCompClass) end) end
                return Mesh
            end
            function PlayerMapMarker.GetESPLocation(Character)
                if not IsValid(Character) then return nil end
                local BoneLoc = PlayerMapMarker.GetCharacterLocation(Character)
                if BoneLoc then
                    local heightOffset = 85
                    pcall(function()
                        if Character.bIsCrouched then heightOffset = 60 end
                        if Character.IsProne and Character:IsProne() then heightOffset = 30 end
                    end)
                    pcall(function() BoneLoc.Z = BoneLoc.Z + heightOffset + (PlayerMapMarker.ESPWorldOffsetZ or 0) end)
                end
                return BoneLoc
            end
            function PlayerMapMarker.GetCharacterWeaponInfo(Character)
                if not IsValid(Character) then return nil end
                local WeaponID, WeaponName, WeaponIconPath, WeaponIconTexture, CurrentWeapon = nil, nil, nil, nil, nil
                pcall(function() if Character.GetCurrentWeapon then CurrentWeapon = Character:GetCurrentWeapon() end end)
                if not CurrentWeapon then pcall(function() CurrentWeapon = Character.CurrentWeapon end) end
                if not CurrentWeapon then pcall(function() if Character.GetWeaponManager then local WM = Character:GetWeaponManager() if WM and WM.GetCurrentWeapon then CurrentWeapon = WM:GetCurrentWeapon() end end end) end
                if CurrentWeapon and IsValid(CurrentWeapon) then
                    pcall(function() if CurrentWeapon.GetWeaponID then WeaponID = CurrentWeapon:GetWeaponID() end end)
                    if not WeaponID then pcall(function() WeaponID = CurrentWeapon.WeaponID end) end
                    if not WeaponID then pcall(function() if CurrentWeapon.GetItemID then WeaponID = CurrentWeapon:GetItemID() end end) end
                    pcall(function() if CurrentWeapon.GetWeaponName then WeaponName = CurrentWeapon:GetWeaponName() end end)
                    pcall(function() if CurrentWeapon.GetWeaponIconPath then WeaponIconPath = CurrentWeapon:GetWeaponIconPath() end end)
                    pcall(function() if CurrentWeapon.GetWeaponIcon then WeaponIconTexture = CurrentWeapon:GetWeaponIcon() end end)
                end
                if not WeaponID then
                    pcall(function()
                        local PS = nil
                        if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety() elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
                        if PS and IsValid(PS) then
                            if PS.GetCurrentWeaponID then WeaponID = PS:GetCurrentWeaponID() end
                            if not WeaponID and PS.CurWeaponID then WeaponID = PS.CurWeaponID end
                        end
                    end)
                end
                return { WeaponID = WeaponID, WeaponName = WeaponName, WeaponIconPath = WeaponIconPath, WeaponIconTexture = WeaponIconTexture, CurrentWeapon = CurrentWeapon }
            end
            function PlayerMapMarker.FindWeaponIconInWidget(WidgetObj, Depth, MaxDepth)
                if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
                Depth = Depth or 0 ; MaxDepth = MaxDepth or 8
                local propNames = { "Image_Weapon", "Image_WeaponIcon", "Image_Gun", "Image_Icon", "WeaponIcon", "WeaponImage", "Image_Equip" }
                for _, pname in ipairs(propNames) do
                    pcall(function()
                        local prop = WidgetObj[pname]
                        if prop and slua.isValid(prop) then
                            local hasBrush = false
                            pcall(function() if prop.Brush then hasBrush = true end end)
                            if hasBrush then return prop end
                        end
                    end)
                end
                if Depth >= MaxDepth then return nil end
                local nChildren = 0
                pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = nil
                    pcall(function() child = WidgetObj:GetChildAt(i) end)
                    if child and slua.isValid(child) then
                        local result = PlayerMapMarker.FindWeaponIconInWidget(child, Depth + 1, MaxDepth)
                        if result then return result end
                    end
                end
                if nChildren == 0 then
                    local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
                    if Root and slua.isValid(Root) and Root ~= WidgetObj then
                        local result = PlayerMapMarker.FindWeaponIconInWidget(Root, Depth + 1, MaxDepth)
                        if result then return result end
                    end
                end
                return nil
            end
            function PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, DefaultW, DefaultH)
                if not ImageWidget or not slua.isValid(ImageWidget) then return end
                DefaultW = DefaultW or 138 ; DefaultH = DefaultH or 69
                pcall(function()
                    local brush = ImageWidget.Brush
                    if brush then
                        brush.ImageSize = FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}
                        brush.DrawAs = 3
                        brush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                        if ImageWidget.SetBrush then ImageWidget:SetBrush(brush) end
                    end
                    if ImageWidget.SetDesiredSizeOverride then ImageWidget:SetDesiredSizeOverride(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
                    local slot = ImageWidget.Slot
                    if slot and slot.SetSize then slot:SetSize(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
                    ImageWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    ImageWidget:SetRenderOpacity(1.0)
                    ImageWidget:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1})
                end)
            end
            function PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
                -- Real black plate BEHIND white weapon icon (same idea as name plate)
                local fullIcon = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                local blackBg = FLinearColor and FLinearColor(0.0, 0.0, 0.0, 0.92) or {R=0,G=0,B=0,A=235}
                if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end
                pcall(function()
                    local function paintWhite(w)
                        if not w or not slua.isValid(w) then return end
                        if w.SetColorAndOpacity then pcall(function() w:SetColorAndOpacity(fullIcon) end) end
                        if w.SetBrushTintColor then pcall(function() w:SetBrushTintColor(fullIcon) end) end
                        if w.SetRenderOpacity then pcall(function() w:SetRenderOpacity(1.0) end) end
                        pcall(function()
                            local brush = w.Brush
                            if brush then brush.TintColor = fullIcon if w.SetBrush then w:SetBrush(brush) end end
                        end)
                    end
                    -- ensure / create black plate border under the icon
                    local plate = Container and Container._MagooWeaponBlackPlate
                    if (not plate or not slua.isValid(plate)) and Container and CGame and CGame.NewObjectFromPath then
                        pcall(function()
                            plate = CGame:NewObjectFromPath("/Script/UMG.Border", Container)
                            if plate and slua.isValid(plate) then
                                Container._MagooWeaponBlackPlate = plate
                                if plate.SetBrushColor then plate:SetBrushColor(blackBg) end
                                if plate.SetColorAndOpacity then plate:SetColorAndOpacity(blackBg) end
                                if plate.SetRenderOpacity then plate:SetRenderOpacity(1.0) end
                                -- insert as child of same parent as icon when possible
                                local parent = nil
                                pcall(function() if ourWeaponIcon.GetParent then parent = ourWeaponIcon:GetParent() end end)
                                if parent and slua.isValid(parent) and parent.AddChild then
                                    pcall(function() parent:AddChild(plate) end)
                                elseif Container.AddChild then
                                    pcall(function() Container:AddChild(plate) end)
                                end
                                if plate.SetWidgetVisibility then
                                    plate:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                end
                            end
                        end)
                    end
                    if plate and slua.isValid(plate) then
                        if plate.SetBrushColor then pcall(function() plate:SetBrushColor(blackBg) end) end
                        if plate.SetColorAndOpacity then pcall(function() plate:SetColorAndOpacity(blackBg) end) end
                        if plate.SetRenderOpacity then pcall(function() plate:SetRenderOpacity(1.0) end) end
                        if plate.SetWidgetVisibility then
                            pcall(function() plate:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        end
                        -- match icon size/slot if available
                        pcall(function()
                            local slot = ourWeaponIcon.Slot
                            local pslot = plate.Slot
                            if slot and pslot then
                                if slot.GetSize and pslot.SetSize then
                                    local sz = slot:GetSize()
                                    if sz then
                                        local pad = 6
                                        local w = (sz.X or 40) + pad * 2
                                        local h = (sz.Y or 20) + pad * 2
                                        pslot:SetSize(FVector2D and FVector2D(w, h) or {X=w,Y=h})
                                    end
                                end
                                if slot.GetPosition and pslot.SetPosition then
                                    local pos = slot:GetPosition()
                                    if pos then
                                        pslot:SetPosition(FVector2D and FVector2D((pos.X or 0) - 6, (pos.Y or 0) - 4) or {X=(pos.X or 0)-6,Y=(pos.Y or 0)-4})
                                    end
                                end
                                if pslot.SetZOrder then pslot:SetZOrder(-1) end
                            end
                        end)
                    end
                    -- also paint native BG borders black if present
                    local bgNames = {"Border_BG","Image_BG","Image_WeaponBG","Border_Root","Border_Weapon","Border_WeaponIcon","Border_Equip"}
                    if Container then
                        for _, bn in ipairs(bgNames) do
                            local b = Container[bn]
                            if b and slua.isValid(b) then
                                if b.SetBrushColor then pcall(function() b:SetBrushColor(blackBg) end) end
                                if b.SetRenderOpacity then pcall(function() b:SetRenderOpacity(1.0) end) end
                                if b.SetWidgetVisibility then pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
                            end
                        end
                    end
                    -- ICON must stay pure white
                    paintWhite(ourWeaponIcon)
                    if Container then
                        for _, n in ipairs({"WeaponIcon","Image_Weapon","Image_WeaponIcon","Image_Gun","Image_Icon","WeaponImage","Image_Equip"}) do
                            if Container[n] then paintWhite(Container[n]) end
                        end
                    end
                    -- hide name / gun-name text when weapon-icon-only
                    if not (_G.LexusConfig and _G.LexusConfig.Esp9_Name == true) and Container then
                        for _, tn in ipairs({"TextBlock_TeamName","TextBlock_PlayerName","TextBlock_Name","Text_Name","TextBlock_WeaponName","Text_Weapon","TextBlock_EquipName"}) do
                            local t = Container[tn]
                            if t and slua.isValid(t) and t.SetWidgetVisibility then
                                pcall(function() t:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            end
                        end
                    end
                end)
            end

            function PlayerMapMarker.ApplyWeaponIconToImage(ImageWidget, winfo)
                if not ImageWidget or not slua.isValid(ImageWidget) then return false, "no_widget" end
                if not winfo or not winfo.WeaponID then return false, "no_weapon_id" end
                local iconPath = nil
                local method = "none"
                local bHasAddKnownMissing = false
                local defaultW = 138
                local defaultH = 69
                pcall(function()
                    local itemRecord = CDataTable.GetTableData("Item", winfo.WeaponID)
                    if itemRecord and itemRecord.KillWhiteIcon and itemRecord.KillWhiteIcon ~= "" then iconPath = itemRecord.KillWhiteIcon method = "KillWhiteIcon" end
                    if (not iconPath or iconPath == "") and winfo.WeaponIconPath and winfo.WeaponIconPath ~= "" then iconPath = winfo.WeaponIconPath method = "WeaponIconPath" end
                    if (not iconPath or iconPath == "") and winfo.WeaponIconTexture and slua.isValid(winfo.WeaponIconTexture) then
                        if ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(winfo.WeaponIconTexture, true) method = "WeaponIconTexture" return end
                    end
                    if not iconPath or iconPath == "" then
                        local UIUtil = require("client.common.ui_util")
                        iconPath, bHasAddKnownMissing = UIUtil.GetItemBigIcon(winfo.WeaponID, ImageWidget)
                        if iconPath and iconPath ~= "" then method = "GetItemBigIcon" end
                    end
                    if not iconPath or iconPath == "" then
                        local UIUtil = require("client.common.ui_util")
                        iconPath = UIUtil.GetItemSmallIcon(winfo.WeaponID, ImageWidget, bHasAddKnownMissing)
                        if iconPath and iconPath ~= "" then method = "GetItemSmallIcon" end
                    end
                end)
                if method == "WeaponIconTexture" then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) return true, method end
                if not iconPath or iconPath == "" then return false, "no_path" end
                local bOK = false
                pcall(function()
                    if ImageWidget.SetBrushResourceFromPathSync then ImageWidget:SetBrushResourceFromPathSync(iconPath, true) bOK = true end
                    if not bOK then
                        local util = require("client.slua_ui_framework.util")
                        local result = util.SetTexture(ImageWidget, iconPath, { sync = true, bMatchSize = true, bIsInCombatState = true, bHasAddKnownMissing = bHasAddKnownMissing })
                        bOK = result ~= nil
                    end
                    if not bOK then
                        local tex = import(iconPath)
                        if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
                    end
                    if not bOK then
                        local LoadObject = import("LoadObject")
                        if LoadObject then
                            local tex = LoadObject(iconPath)
                            if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
                        end
                    end
                end)
                if bOK then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) end
                return bOK, method .. ":" .. tostring(iconPath)
            end
            function PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
                if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return false end
                if not nativeWeaponIcon or not slua.isValid(nativeWeaponIcon) then return false end
                local bCopied = false
                pcall(function()
                    local nBrush = nativeWeaponIcon.Brush
                    if nBrush then
                        local resObj = nil
                        pcall(function() resObj = nBrush.ResourceObject end)
                        if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                            ourWeaponIcon:SetBrushFromTexture(resObj, true)
                            bCopied = true
                        end
                        if bCopied then
                            local imgSize = nil
                            pcall(function() imgSize = nBrush.ImageSize end)
                            if imgSize then
                                local oBrush = ourWeaponIcon.Brush
                                if oBrush then oBrush.ImageSize = imgSize if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(oBrush) end end
                            end
                        end
                    end
                end)
                return bCopied
            end
            function PlayerMapMarker.AddWeaponIconToESP(WidgetData, Character)
                if not WidgetData or not WidgetData.Container then return end
                local Container = WidgetData.Container
                if not slua.isValid(Container) then return end
                if not _G.LexusConfig.Esp9_Weapon then
                    pcall(function()
                        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
                        for _, pname in ipairs(chainNames) do
                            local node = Container[pname]
                            if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                        end
                        local ourWeaponIcon = Container.WeaponIcon or PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8)
                        if ourWeaponIcon and slua.isValid(ourWeaponIcon) then ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                    end)
                    WidgetData._LastWeaponID = 0
                    WidgetData._WeaponIconApplied = false
                    return
                end
                pcall(function()
                    local ourWeaponIcon = Container.WeaponIcon
                    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then ourWeaponIcon = PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8) end
                    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end
                    local winfo = Character and PlayerMapMarker.GetCharacterWeaponInfo(Character) or nil
                    if not winfo or not winfo.WeaponID or winfo.WeaponID == 0 then
                        pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
                        for _, pname in ipairs(chainNames) do
                            pcall(function()
                                local node = Container and Container[pname]
                                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                            end)
                        end
                        WidgetData._LastWeaponID = 0
                        WidgetData._WeaponIconApplied = false
                        return
                    end
                    if WidgetData._LastWeaponID == winfo.WeaponID and WidgetData._WeaponIconApplied then
                        pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() ourWeaponIcon:SetRenderOpacity(1.0) end)
                        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
                        for _, pname in ipairs(chainNames) do
                            pcall(function()
                                local node = Container and Container[pname]
                                if node and slua.isValid(node) and node.SetWidgetVisibility then
                                    node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    pcall(function() if node.SetRenderOpacity then node:SetRenderOpacity(1.0) end end)
                                end
                            end)
                        end
                        pcall(function() PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon) end)
                        if WidgetData._CachedSwitcherIndexes then
                            for sName, idx in pairs(WidgetData._CachedSwitcherIndexes) do
                                pcall(function()
                                    local ws = Container[sName]
                                    if ws and slua.isValid(ws) and ws.SetActiveWidgetIndex then ws:SetActiveWidgetIndex(idx) end
                                end)
                            end
                        end
                        if WidgetData._CachedParentSwitchers then
                            for _, data in pairs(WidgetData._CachedParentSwitchers) do
                                pcall(function() if data.w and slua.isValid(data.w) and data.w.SetActiveWidgetIndex then data.w:SetActiveWidgetIndex(data.idx) end end)
                            end
                        end
                        return
                    end
                    local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
                    for _, pname in ipairs(chainNames) do
                        pcall(function()
                            local node = Container and Container[pname]
                            if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                        end)
                    end
                    local bCopied = false
                    if winfo and winfo.WeaponID then
                        local ok, method = PlayerMapMarker.ApplyWeaponIconToImage(ourWeaponIcon, winfo)
                        if ok then bCopied = true end
                    end
                    local bWeaponIconSet = false
                    if Character and winfo then
                        if winfo and winfo.WeaponID then
                            pcall(function() if Container.SetWeaponIcon then Container:SetWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end)
                            if not bWeaponIconSet then pcall(function() if Container.SetWeaponIconByID then Container:SetWeaponIconByID(winfo.WeaponID) bWeaponIconSet = true end end) end
                            if not bWeaponIconSet then pcall(function() if Container.UpdateWeaponIcon then Container:UpdateWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end) end
                            if not bWeaponIconSet then pcall(function() if Container.SetWeaponID then Container:SetWeaponID(winfo.WeaponID) bWeaponIconSet = true end end) end
                            pcall(function() if Container.SetData then Container:SetData(Character) end end)
                            pcall(function() if Container.SetPlayerInfo then Container:SetPlayerInfo(Character) end end)
                            if winfo.CurrentWeapon then pcall(function() if Container.SetCurrentWeapon then Container:SetCurrentWeapon(winfo.CurrentWeapon) end end) end
                        end
                    end
                    if bWeaponIconSet then
                        pcall(function()
                            local innerIcon = Container.Image_Icon
                            if not innerIcon or not slua.isValid(innerIcon) then if Container.CanvasPanel_Type1 then innerIcon = Container.CanvasPanel_Type1.Image_Icon end end
                            if not innerIcon or not slua.isValid(innerIcon) then
                                local function findImageIcon(w, depth)
                                    if not w or not slua.isValid(w) or depth > 8 then return nil end
                                    local prop = w.Image_Icon
                                    if prop and slua.isValid(prop) then return prop end
                                    local n = 0
                                    pcall(function() if w.GetChildrenCount then n = w:GetChildrenCount() end end)
                                    for i = 0, math.max(n - 1, 0) do
                                        local c = nil
                                        pcall(function() c = w:GetChildAt(i) end)
                                        if c then local r = findImageIcon(c, depth + 1) if r then return r end end
                                    end
                                    return nil
                                end
                                innerIcon = findImageIcon(Container, 0)
                            end
                            if innerIcon and slua.isValid(innerIcon) and innerIcon ~= ourWeaponIcon then
                                pcall(function()
                                    local ibrush = innerIcon.Brush
                                    if ibrush then
                                        local iresObj = nil
                                        pcall(function() iresObj = ibrush.ResourceObject end)
                                        if iresObj and slua.isValid(iresObj) then
                                            if ourWeaponIcon.SetBrushFromAsset then ourWeaponIcon:SetBrushFromAsset(iresObj) bCopied = true end
                                            if not bCopied and ourWeaponIcon.SetBrushFromTexture then ourWeaponIcon:SetBrushFromTexture(iresObj) bCopied = true end
                                        end
                                    end
                                end)
                                if not bCopied then
                                    pcall(function()
                                        local brush = innerIcon.Brush
                                        if brush then
                                            local iresObj = nil
                                            pcall(function() iresObj = brush.ResourceObject end)
                                            if iresObj and slua.isValid(iresObj) and ourWeaponIcon.SetBrushFromTexture then
                                                ourWeaponIcon:SetBrushFromTexture(iresObj, false)
                                                PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)
                                                bCopied = true
                                            end
                                        end
                                    end)
                                end
                            end
                        end)
                    end
                    if not bCopied then
                        local nativeWeaponIcon = nil
                        if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                            local nChildren = 0
                            pcall(function() nChildren = PlayerMapMarker.ESPCanvas:GetChildrenCount() end)
                            for i = 0, math.max(nChildren - 1, 0) do
                                local child = nil
                                pcall(function() child = PlayerMapMarker.ESPCanvas:GetChildAt(i) end)
                                if child and slua.isValid(child) then
                                    local cstr = tostring(child)
                                    if string.find(cstr, "OB_PlayerHeadHPItem") then
                                        if not PlayerMapMarker.IsOurESPWidget(child) then
                                            local nativeIcon = child.WeaponIcon
                                            if nativeIcon and slua.isValid(nativeIcon) then nativeWeaponIcon = nativeIcon break end
                                        end
                                    end
                                end
                            end
                        end
                        if nativeWeaponIcon and slua.isValid(nativeWeaponIcon) then
                            local okNative, nativeMethod = PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
                            if okNative then bCopied = true end
                        end
                    end
                    if not bCopied then
                        pcall(function()
                            local brush = ourWeaponIcon.Brush
                            if brush then
                                local resObj = nil
                                pcall(function() resObj = brush.ResourceObject end)
                                if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                                    ourWeaponIcon:SetBrushFromTexture(resObj)
                                    bCopied = true
                                end
                            end
                        end)
                    end
                    if not bCopied then
                        pcall(function()
                            local brush = ourWeaponIcon.Brush
                            if brush then
                                local imgSize = nil
                                pcall(function() imgSize = brush.ImageSize end)
                                local bZeroSize = false
                                if imgSize then
                                    local sx, sy = nil, nil
                                    pcall(function() sx = imgSize.X end)
                                    pcall(function() sy = imgSize.Y end)
                                    if (not sx or sx == 0) and (not sy or sy == 0) then bZeroSize = true end
                                end
                                if bZeroSize then
                                    pcall(function() brush.ImageSize = FVector2D and FVector2D(PlayerMapMarker.WeaponIconBrushW or 138, PlayerMapMarker.WeaponIconBrushH or 69) or {X=138, Y=69} end)
                                end
                                pcall(function() brush.DrawAs = 3 end)
                                if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end
                            end
                        end)
                    end
                    pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
                    PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)
                    pcall(function()
                        local function findWidgetInSwitcher(switcher, targetWidget)
                            if not switcher or not slua.isValid(switcher) then return nil end
                            if not switcher.GetChildrenCount or not switcher.GetChildAt then return nil end
                            local nChildren = switcher:GetChildrenCount()
                            for i = 0, math.max(nChildren - 1, 0) do
                                local child = switcher:GetChildAt(i)
                                if child and slua.isValid(child) then
                                    if child == targetWidget then return i end
                                    local function searchDescendant(w, target, depth)
                                        if depth > 5 then return false end
                                        if w == target then return true end
                                        if not w.GetChildrenCount or not w.GetChildAt then return false end
                                        local nc = w:GetChildrenCount()
                                        for j = 0, math.max(nc - 1, 0) do
                                            local c = w:GetChildAt(j)
                                            if c and slua.isValid(c) and searchDescendant(c, target, depth + 1) then return true end
                                        end
                                        return false
                                    end
                                    if searchDescendant(child, targetWidget, 0) then return i end
                                end
                            end
                            return nil
                        end
                        for _, switcherName in ipairs({"Switcher_WeaponIcon", "WidgetSwitcher_Type", "WidgetSwitcher_Type2"}) do
                            local ws = Container[switcherName]
                            if ws and slua.isValid(ws) and ws.GetChildrenCount and ws.GetChildAt then
                                local foundIdx = findWidgetInSwitcher(ws, ourWeaponIcon)
                                if foundIdx then
                                    if ws.SetActiveWidgetIndex then
                                        ws:SetActiveWidgetIndex(foundIdx)
                                        WidgetData._CachedSwitcherIndexes = WidgetData._CachedSwitcherIndexes or {}
                                        WidgetData._CachedSwitcherIndexes[switcherName] = foundIdx
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function()
                        local parent = ourWeaponIcon
                        for depth = 0, 8 do
                            if not parent or not slua.isValid(parent) then break end
                            if parent.GetParent then
                                local p = parent:GetParent()
                                if p and slua.isValid(p) then
                                    local pStr = tostring(p)
                                    if string.find(pStr, "WidgetSwitcher") then
                                        if p.GetChildrenCount and p.GetChildAt then
                                            local nCh = p:GetChildrenCount()
                                            for i = 0, math.max(nCh - 1, 0) do
                                                local child = p:GetChildAt(i)
                                                if child and slua.isValid(child) then
                                                    local function isDescendant(w, target, d)
                                                        if d > 5 then return false end
                                                        if w == target then return true end
                                                        if not w.GetChildrenCount or not w.GetChildAt then return false end
                                                        local nc = w:GetChildrenCount()
                                                        for j = 0, math.max(nc - 1, 0) do
                                                            local c = w:GetChildAt(j)
                                                            if c and slua.isValid(c) and isDescendant(c, target, d + 1) then return true end
                                                        end
                                                        return false
                                                    end
                                                    if isDescendant(child, ourWeaponIcon, 0) then
                                                        if p.SetActiveWidgetIndex then
                                                            p:SetActiveWidgetIndex(i)
                                                            WidgetData._CachedParentSwitchers = WidgetData._CachedParentSwitchers or {}
                                                            WidgetData._CachedParentSwitchers[tostring(p)] = {w = p, idx = i}
                                                        end
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    parent = p
                                else
                                    break
                                end
                            else
                                break
                            end
                        end
                    end)
                    pcall(function()
                        local parent = ourWeaponIcon
                        for depth = 0, 8 do
                            pcall(function()
                                if parent.GetParent then
                                    local p = parent:GetParent()
                                    if p and slua.isValid(p) then
                                        if p.SetWidgetVisibility then p:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                                        pcall(function() if p.SetRenderOpacity then p:SetRenderOpacity(1.0) end end)
                                        pcall(function() if p.SetContentColorAndOpacity then p:SetContentColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                                        pcall(function() if p.SetColorAndOpacity then p:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                                        pcall(function() if p.SetBrushTintColor then p:SetBrushTintColor(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                                        pcall(function()
                                            local pBrush = p.Brush
                                            if pBrush and pBrush.TintColor then
                                                pBrush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                                                if p.SetBrush then p:SetBrush(pBrush) end
                                            end
                                        end)
                                        pcall(function() if p.InvalidateLayout then p:InvalidateLayout() end end)
                                        parent = p
                                    end
                                end
                            end)
                        end
                    end)
                    pcall(function() if ourWeaponIcon.InvalidateLayout then ourWeaponIcon:InvalidateLayout() end end)
                    pcall(function() if Container.UpdateWeapon then Container:UpdateWeapon() end end)
                    pcall(function() if Container.RefreshWeapon then Container:RefreshWeapon() end end)
                    WidgetData._LastWeaponID = winfo.WeaponID
                    WidgetData._WeaponIconApplied = true
                end)
            end
            PlayerMapMarker._OBHeadWidgetClass = nil
            PlayerMapMarker._OBHeadWidgetLoadFailed = false
            PlayerMapMarker._bDumpedWidgetChildren = false
            function PlayerMapMarker.CreateESPWidget()
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
                if PlayerMapMarker._OBHeadWidgetLoadFailed then return nil end
                if not PlayerMapMarker._OBHeadWidgetClass then
                    pcall(function()
                        local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
                        local uClass = slua.loadClass(Path)
                        if uClass then PlayerMapMarker._OBHeadWidgetClass = uClass end
                    end)
                    if not PlayerMapMarker._OBHeadWidgetClass then
                        PlayerMapMarker._OBHeadWidgetLoadFailed = true
                        return nil
                    end
                else
                    local bValid = false
                    pcall(function() bValid = slua.isValid(PlayerMapMarker._OBHeadWidgetClass) end)
                    if not bValid then
                        PlayerMapMarker._OBHeadWidgetLoadFailed = true
                        PlayerMapMarker._OBHeadWidgetClass = nil
                        return nil
                    end
                end
                local Widget = nil
                pcall(function()
                    local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
                    local PC = PlayerMapMarker.GetMyPlayerController()
                    local OuterObj = IsValid(PC) and PC.Object or PlayerMapMarker.ESPCanvas
                    Widget = STExtraBlueprintFunctionLibrary.CreateWidgetByClass(PlayerMapMarker._OBHeadWidgetClass, OuterObj)
                end)
                if not Widget then return nil end
                pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                pcall(function() Widget:SetRenderOpacity(1.0) end)
                local NameText = nil
                local HealthFill = nil
                local bIsOriginalProgressBar = false
                pcall(function()
                    NameText = Widget.TextBlock_TeamName
                    if NameText and slua.isValid(NameText) then pcall(function() NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
                    if Widget.TextBlock_PlayerName and slua.isValid(Widget.TextBlock_PlayerName) then pcall(function() Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
                    local WS_Type = Widget.WidgetSwitcher_Type
                    local WS_Type2 = Widget.WidgetSwitcher_Type2
                    if WS_Type and slua.isValid(WS_Type) then pcall(function() if WS_Type.SetActiveWidgetIndex then WS_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
                    if WS_Type2 and slua.isValid(WS_Type2) then pcall(function() if WS_Type2.SetActiveWidgetIndex then WS_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end
                    local SizeBox_HP = Widget.SizeBox_HP
                    if SizeBox_HP and slua.isValid(SizeBox_HP) then
                        pcall(function() SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() SizeBox_HP:SetHeightOverride(6) end)
                        pcall(function() SizeBox_HP:SetWidthOverride(100) end)
                        local ExistingChild = nil
                        pcall(function() if SizeBox_HP.GetContent then ExistingChild = SizeBox_HP:GetContent() end end)
                        if not ExistingChild then pcall(function() if SizeBox_HP.GetChildAt then ExistingChild = SizeBox_HP:GetChildAt(0) end end) end
                        if ExistingChild and slua.isValid(ExistingChild) then
                            pcall(function() ExistingChild:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                            pcall(function() ExistingChild:SetRenderOpacity(1.0) end)
                            local FoundPB = PlayerMapMarker.FindProgressBarInWidget(ExistingChild, 0, 5)
                            if FoundPB and slua.isValid(FoundPB) then
                                HealthFill = FoundPB
                                bIsOriginalProgressBar = true
                                pcall(function() FoundPB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                                pcall(function() FoundPB:SetRenderOpacity(1.0) end)
                            else
                                local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", ExistingChild)
                                if PB then
                                    pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0, 1, 0, 1) or {R=0,G=1,B=0,A=1}) end)
                                    pcall(function() PB:SetPercent(1.0) end)
                                    pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                                    pcall(function() PB:SetRenderOpacity(1.0) end)
                                    pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)
                                    pcall(function() ExistingChild:AddChild(PB) end)
                                    HealthFill = PB
                                end
                            end
                        else
                            local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", SizeBox_HP)
                            if PB then
                                pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0, 1, 0, 1) or {R=0,G=1,B=0,A=1}) end)
                                pcall(function() PB:SetPercent(1.0) end)
                                pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                                pcall(function() PB:SetRenderOpacity(1.0) end)
                                pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)
                                local bUsedSetContent = false
                                pcall(function() if SizeBox_HP.SetContent then SizeBox_HP:SetContent(PB) bUsedSetContent = true end end)
                                if not bUsedSetContent then pcall(function() SizeBox_HP:AddChild(PB) end) end
                                HealthFill = PB
                            end
                        end
                    end
                end)
                local WidgetData = {
                    Container = Widget,
                    NameText = NameText,
                    HealthFill = HealthFill,
                    IsGameWidget = true,
                    IsOriginalProgressBar = bIsOriginalProgressBar,
                    HasChildren = (NameText ~= nil)
                }
                return WidgetData
            end
            PlayerMapMarker._CanvasScaleX = 1.0
            PlayerMapMarker._CanvasScaleY = 1.0
            PlayerMapMarker._CanvasOffsetX = 0.0
            PlayerMapMarker._CanvasOffsetY = 0.0
            function PlayerMapMarker.UpdateCanvasTransform(PC)
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
                local success = false
                pcall(function()
                    local SBL = SlateBlueprintLibrary
                    if SBL and SBL.AbsoluteToLocal then
                        local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
                        if cg then
                            local pt0 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0})
                            local pt1 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100})
                            if pt0 and pt1 then
                                PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                                PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                                PlayerMapMarker._CanvasOffsetX = pt0.X
                                PlayerMapMarker._CanvasOffsetY = pt0.Y
                                success = true
                            end
                        end
                    end
                end)
                if not success then
                    pcall(function()
                        local WLL = WidgetLayoutLibrary
                        if WLL and WLL.ScreenToWidgetLocal then
                            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
                            if cg then
                                local pt0 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                                local pt1 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                                WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0}, pt0)
                                WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100}, pt1)
                                PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                                PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                                PlayerMapMarker._CanvasOffsetX = pt0.X
                                PlayerMapMarker._CanvasOffsetY = pt0.Y
                                success = true
                            end
                        end
                    end)
                end
                if not success then
                    local scale = 1.0
                    local WLL = WidgetLayoutLibrary
                    if WLL and WLL.GetViewportScale then scale = WLL.GetViewportScale(PC) or 1.0 end
                    PlayerMapMarker._CanvasScaleX = 1.0 / scale
                    PlayerMapMarker._CanvasScaleY = 1.0 / scale
                    PlayerMapMarker._CanvasOffsetX = 0
                    PlayerMapMarker._CanvasOffsetY = 0
                end
            end
            function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
                if not ScreenPixelPos then return FVector2D and FVector2D(0, 0) or {X=0, Y=0} end
                local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
                local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
                local offsetX = PlayerMapMarker._CanvasOffsetX or 0
                local offsetY = PlayerMapMarker._CanvasOffsetY or 0
                return (FVector2D and FVector2D(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)) or {X = ScreenPixelPos.X * scaleX + offsetX, Y = ScreenPixelPos.Y * scaleY + offsetY}
            end
            function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
                if not IsValid(PC) or not WorldLoc then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
                local ScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                local bOK = false
                pcall(function()
                    local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
                    if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then bOK = true end
                end)
                if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
                local CanvasLocalPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
                return true, CanvasLocalPos
            end
            function PlayerMapMarker.GetDynamicViewportSize(PC)
                local width, height = 0, 0
                if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                    pcall(function()
                        local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
                        if cg and cg.GetLocalSize then
                            local sz = cg:GetLocalSize()
                            if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
                        end
                    end)
                end
                if width > 200 then return width, height end
                pcall(function()
                    local WLL = WidgetLayoutLibrary
                    if WLL and WLL.GetViewportSize then
                        local sz = WLL.GetViewportSize(PC or PlayerMapMarker.GetMyPlayerController())
                        if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
                    end
                end)
                if width > 200 then
                    pcall(function()
                        local WLL = WidgetLayoutLibrary
                        if WLL and WLL.GetViewportScale then
                            local scale = WLL.GetViewportScale(PC or PlayerMapMarker.GetMyPlayerController())
                            if scale and type(scale) == "number" and scale > 0 and scale ~= 1.0 then width = width / scale height = height / scale end
                        end
                    end)
                    return width, height
                end
                return PlayerMapMarker._cachedViewportW or 1920, PlayerMapMarker._cachedViewportH or 1080
            end
            function PlayerMapMarker.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
                if not Widget or not IsValid(PC) then return false end
                local Container = Widget.Container or Widget
                local bOnScreen = true
                if not CanvasPos then
                    if not WorldLoc then return false end
                    bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
                end
                if not bOnScreen then pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) return false end
                pcall(function()
                    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                        local ptr = tostring(Container)
                        local Slot = PlayerMapMarker.ESPWidgetPtrs[ptr]
                        if not Slot or not slua.isValid(Slot) or type(Slot) == "boolean" then
                            local addedSlot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Container)
                            if addedSlot and slua.isValid(addedSlot) then
                                Slot = addedSlot
                                PlayerMapMarker.ESPWidgetPtrs[ptr] = addedSlot
                                if type(Widget) == "table" then Widget.Slot = addedSlot end
                                pcall(function() Slot:SetAutoSize(true) end)
                                pcall(function() Slot.bAutoSize = true end)
                                local align = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
                                pcall(function() Slot.Alignment = align end)
                                pcall(function() Slot:SetAlignment(align) end)
                                pcall(function() Slot:SetAlignment(0.5, 1.0) end)
                                pcall(function() Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 20) end)
                            end
                        end
                        local bShowAnyUI = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
                        if bShowAnyUI then
                            Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        else
                            Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        end
                        if not Widget._OffsetResetDone then
                            pcall(function() Container:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end)
                            pcall(function() Container:SetRenderScale(FVector2D and FVector2D(0.90, 0.90) or {X=0.90, Y=0.90}) end)
                            if Widget and type(Widget) == "table" then
                                if Widget.NameText and slua.isValid(Widget.NameText) then pcall(function() Widget.NameText:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                                if Widget.HealthFill and slua.isValid(Widget.HealthFill) then pcall(function() Widget.HealthFill:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                            end
                            pcall(function() Container.RenderTransformPivot = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0} end)
                            pcall(function() Container:SetRenderTransformPivot(FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}) end)
                            Widget._OffsetResetDone = true
                        end
                        if not Slot or not slua.isValid(Slot) or Slot == PlayerMapMarker.ESPCanvas then
                            if Widget and type(Widget) == "table" and Widget.Slot and slua.isValid(Widget.Slot) then Slot = Widget.Slot
                            elseif Container.Slot and slua.isValid(Container.Slot) then Slot = Container.Slot end
                        end
                        if Slot and slua.isValid(Slot) and Slot ~= PlayerMapMarker.ESPCanvas then
                            local targetX = CanvasPos.X + (PlayerMapMarker.ESPAnchorOffsetX or 0)
                            local targetY = CanvasPos.Y + (PlayerMapMarker.ESPAnchorOffsetY or 0)
                            if Widget and type(Widget) == "table" then
                                local sx = Widget._SmoothX
                                local sy = Widget._SmoothY
                                if sx == nil or sy == nil then
                                    sx, sy = targetX, targetY
                                else
                                    local dx = targetX - sx
                                    local dy = targetY - sy
                                    if dx * dx + dy * dy > 40000 then
                                        sx, sy = targetX, targetY
                                    else
                                        local a = 0.42
                                        sx = sx + dx * a
                                        sy = sy + dy * a
                                    end
                                end
                                Widget._SmoothX, Widget._SmoothY = sx, sy
                                local cached = Widget._CachedPosVec
                                if not cached then
                                    Widget._CachedPosVec = FVector2D and FVector2D(sx, sy) or {X=sx, Y=sy}
                                    cached = Widget._CachedPosVec
                                else
                                    cached.X = sx
                                    cached.Y = sy
                                end
                                pcall(function() Slot:SetPosition(cached) end)
                            else
                                pcall(function() Slot:SetPosition(FVector2D and FVector2D(targetX, targetY) or {X=targetX, Y=targetY}) end)
                            end
                        end
                    end
                end)
                return true
            end
            function PlayerMapMarker.UpdateESPText(Widget, Text)
                if not Widget then return end
                if Widget._LastESPText == Text then return end
                Widget._LastESPText = Text
                local function applyTextAndCenter(w, txt)
                    if not w or not slua.isValid(w) then return end
                    if txt == "" then
                        pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        return
                    else
                        pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    end
                    pcall(function() w:SetText(txt) end)
                    pcall(function()
                        local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
                        local orangeColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=255, G=255, B=255, A=255}
                        if w.SetColorAndOpacity then
                            if FSlateColor then w:SetColorAndOpacity(FSlateColor(orangeColor)) else w:SetColorAndOpacity(orangeColor) end
                        end
                    end)
                    pcall(function() if w.SetJustification then w:SetJustification(1) end end)
                    pcall(function() local slot = w.Slot if slot and slot.SetHorizontalAlignment then slot:SetHorizontalAlignment(1) end end)
                    pcall(function() w:SetRenderTranslation(FVector2D and FVector2D(PlayerMapMarker.ESPTextOffsetX or 0, PlayerMapMarker.ESPTextOffsetY or 0) or {X=PlayerMapMarker.ESPTextOffsetX or 0, Y=PlayerMapMarker.ESPTextOffsetY or 0}) end)
                end
                if Widget.NameText and slua.isValid(Widget.NameText) then applyTextAndCenter(Widget.NameText, Text) end
                if Widget.IsGameWidget and Widget.Container then
                    pcall(function()
                        local W = Widget.Container
                        if W and slua.isValid(W) then
                            if W.SetPlayerName then
                                local Name = Text
                                local idx = string.find(Text, " %[")
                                if idx then Name = string.sub(Text, 1, idx - 1) end
                                W:SetPlayerName(Name)
                            end
                            applyTextAndCenter(W.TextBlock_TeamName, Text)
                            applyTextAndCenter(W.TextBlock_PlayerName, Text)
                            pcall(function()
                                if not Widget._CachedVBChildren then
                                    local list = {}
                                    local VB = PlayerMapMarker._FindNamedWidgetInTree(W, "VerticalBox_0", 8)
                                    if VB and slua.isValid(VB) and VB.GetChildrenCount then
                                        local nChildren = VB:GetChildrenCount()
                                        for i = 0, nChildren - 1 do
                                            local child = VB:GetChildAt(i)
                                            if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                                        end
                                    end
                                    Widget._CachedVBChildren = list
                                end
                                for _, child in ipairs(Widget._CachedVBChildren) do applyTextAndCenter(child, Text) end
                            end)
                            pcall(function()
                                if not Widget._CachedHBChildren then
                                    local list = {}
                                    local HB = PlayerMapMarker._FindNamedWidgetInTree(W, "HorizontalBox_TeamName", 8)
                                    if HB and slua.isValid(HB) and HB.GetChildrenCount then
                                        local nChildren = HB:GetChildrenCount()
                                        for i = 0, nChildren - 1 do
                                            local child = HB:GetChildAt(i)
                                            if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                                        end
                                    end
                                    Widget._CachedHBChildren = list
                                end
                                for _, child in ipairs(Widget._CachedHBChildren) do applyTextAndCenter(child, Text) end
                            end)
                        end
                    end)
                end
            end
            function PlayerMapMarker.UpdateESPHealth(Widget, pct)
                if not Widget then return end
                local bShowHP = _G.LexusConfig.Esp9_HP == true
                local hpVisibilityChanged = Widget._LastHPVisibility ~= bShowHP
                local pctChanged = Widget.LastPct ~= pct
                Widget.LastPct = pct
                if not hpVisibilityChanged and not pctChanged and not PlayerMapMarker.bForceSwitcherIndexEveryUpdate then return end
                if PlayerMapMarker.bForceSwitcherIndexEveryUpdate and Widget.Container then
                    pcall(function()
                        local W = Widget.Container
                        if W and slua.isValid(W) then
                            if W.WidgetSwitcher_Type and slua.isValid(W.WidgetSwitcher_Type) then pcall(function() if W.WidgetSwitcher_Type.SetActiveWidgetIndex then W.WidgetSwitcher_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
                            if W.WidgetSwitcher_Type2 and slua.isValid(W.WidgetSwitcher_Type2) then pcall(function() if W.WidgetSwitcher_Type2.SetActiveWidgetIndex then W.WidgetSwitcher_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end
                            if W.SizeBox_HP and slua.isValid(W.SizeBox_HP) then
                                if bShowHP then
                                    W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                else
                                    W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                end
                            end
                        end
                    end)
                end
                Widget._LastHPVisibility = bShowHP
                if not bShowHP then return end
                if Widget.HealthFill then
                    local bValid = false
                    pcall(function() bValid = slua.isValid(Widget.HealthFill) end)
                    if bValid then
                        local bHasSetPercent = false
                        pcall(function() bHasSetPercent = (Widget.HealthFill.SetPercent ~= nil) end)
                        if not bHasSetPercent then
                            local PB = PlayerMapMarker.FindProgressBarInWidget(Widget.HealthFill, 0, 5)
                            if PB and slua.isValid(PB) then Widget.HealthFill = PB else return end
                        end
                        pcall(function()
                            if Widget.HealthFill.SetWidgetVisibility then Widget.HealthFill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                            if Widget.HealthFill.SetRenderOpacity then Widget.HealthFill:SetRenderOpacity(1.0) end
                            if Widget.HealthFill.SetPercent then
                                Widget.HealthFill:SetPercent(pct)
                                local color
                                if pct > 0.5 then
                                    color = FLinearColor and FLinearColor(0.0, 1.0, 0.0, 1.0) or {R=0,G=255,B=0,A=255}
                                elseif pct > 0.25 then
                                    color = FLinearColor and FLinearColor(1.0, 0.5, 0.0, 1.0) or {R=255,G=128,B=0,A=255}
                                else
                                    color = FLinearColor and FLinearColor(1.0, 0.0, 0.0, 1.0) or {R=255,G=0,B=0,A=255}
                                end
                                if Widget.HealthFill.SetFillColorAndOpacity then
                                    Widget.HealthFill:SetFillColorAndOpacity(color)
                                end
                                pcall(function()
                                    if Widget.IsOriginalProgressBar then
                                        local style = Widget.HealthFill.WidgetStyle
                                        if style and style.FillImage then
                                            style.FillImage.TintColor = color
                                            Widget.HealthFill:SetWidgetStyle(style)
                                        end
                                    end
                                end)
                            end
                        end)
                    end
                    return
                end
            end
            function PlayerMapMarker.RemoveESPWidget(Widget, KeyStr)
                if not Widget then return end
                local Container = Widget.Container or Widget
                pcall(function()
                    local ptr = tostring(Container)
                    PlayerMapMarker.ESPWidgetPtrs[ptr] = nil
                    Container:RemoveFromParent()
                    Container:ConditionalBeginDestroy()
                end)
                if KeyStr then
                    PlayerMapMarker.RemoveSnapLine(KeyStr)
                    if PlayerMapMarker.RemoveSkeletonLines then
                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                    end
                end
            end
            function PlayerMapMarker.CreateSnapLine()
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
                local Border = nil
                pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
                if not Border or not slua.isValid(Border) then return nil end
                local color = PlayerMapMarker.SnapLineColor or (FLinearColor and FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=1,G=1,B=1,A=PlayerMapMarker.SnapLineOpacity or 0.7})
                pcall(function() Border:SetBrushColor(color) end)
                pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
                pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)
                local Slot = nil
                pcall(function()
                    Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
                    if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(1) end
                end)
                return { Widget = Border, Slot = Slot }
            end
            function PlayerMapMarker.GetSnapLineStartPos(PC)
                local screenPixelW, screenPixelH = 0, 0
                local scale = 1.0
                pcall(function()
                    if PC and PC.GetViewportSize then
                        local vs = FVector2D and FVector2D(0, 0) or {X=0,Y=0}
                        PC:GetViewportSize(vs)
                        if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
                    end
                end)
                if screenPixelW <= 200 then
                    pcall(function()
                        local WLL = WidgetLayoutLibrary
                        if WLL and WLL.GetViewportSize then
                            local vs = WLL.GetViewportSize(PC)
                            if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
                        end
                    end)
                end
                pcall(function()
                    local WLL = WidgetLayoutLibrary
                    if WLL and WLL.GetViewportScale then
                        local s = WLL.GetViewportScale(PC)
                        if s and type(s) == "number" and s > 0 then scale = s end
                    end
                end)
                if screenPixelW <= 200 then
                    screenPixelW = (PlayerMapMarker._cachedViewportW or 1920) * scale
                    screenPixelH = (PlayerMapMarker._cachedViewportH or 1080) * scale
                end
                if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D and FVector2D(0, 0) or {X=0,Y=0} end
                PlayerMapMarker._CachedTopCenterPixel.X = screenPixelW / 2.0
                PlayerMapMarker._CachedTopCenterPixel.Y = (PlayerMapMarker.SnapLineOriginY or 50) * scale
                local fromCanvasPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
                local fromX = fromCanvasPos.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0)
                local fromY = fromCanvasPos.Y
                return fromX, fromY
            end
            function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                if not PlayerMapMarker.bUseSnapLines then return end
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
                local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
                if not bOnScreen or not CanvasPos then
                    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                        pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                    end
                    return
                end
                local bIsNew = false
                if not LineData then
                    LineData = PlayerMapMarker.CreateSnapLine()
                    if not LineData or not LineData.Widget or not LineData.Slot then return end
                    PlayerMapMarker.SnapLineWidgets[KeyStr] = LineData
                    bIsNew = true
                end
                local Widget = LineData.Widget
                local Slot = LineData.Slot
                pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                if not LineData._PivotSet then
                    pcall(function() Widget.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
                    pcall(function() Widget:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)
                    LineData._PivotSet = true
                end
                local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
                local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)
                local dx = toX - fromX
                local dy = toY - fromY
                local length = math.sqrt(dx * dx + dy * dy)
                local thickness = PlayerMapMarker.SnapLineThickness or 1.5
                local angle_rad = 0
                if math.atan2 then angle_rad = math.atan2(dy, dx) else angle_rad = math.atan(dy, dx) end
                local angle = angle_rad * (180.0 / math.pi)
                if not LineData._CachedPosVec then
                    LineData._CachedPosVec = FVector2D and FVector2D(fromX, fromY - thickness / 2.0) or {X=fromX, Y=fromY - thickness / 2.0}
                    LineData._CachedSizeVec = FVector2D and FVector2D(length, thickness) or {X=length, Y=thickness}
                else
                    LineData._CachedPosVec.X = fromX ; LineData._CachedPosVec.Y = fromY - thickness / 2.0
                    LineData._CachedSizeVec.X = length ; LineData._CachedSizeVec.Y = thickness
                end
                pcall(function()
                    Slot:SetPosition(LineData._CachedPosVec)
                    Slot:SetSize(LineData._CachedSizeVec)
                    if bIsNew then Slot:SetZOrder(1) end
                end)
                pcall(function() Widget:SetRenderAngle(angle) end)
            end
            function PlayerMapMarker.RemoveSnapLine(KeyStr)
                local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                    pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
                    PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
                end
            end
            function PlayerMapMarker.ClearAllSnapLines()
                for KeyStr, LineData in pairs(PlayerMapMarker.SnapLineWidgets) do
                    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                        pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
                    end
                end
                PlayerMapMarker.SnapLineWidgets = {}
            end
            function PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, screenX, screenY)
                local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
                local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
                local offsetX = PlayerMapMarker._CanvasOffsetX or 0
                local offsetY = PlayerMapMarker._CanvasOffsetY or 0
                return screenX * scaleX + offsetX, screenY * scaleY + offsetY
            end
            function PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, WorldLoc)
                if not IsValid(PC) or not WorldLoc then return false, 0, 0 end
                if not PlayerMapMarker._tempScreenPixelPos then
                    PlayerMapMarker._tempScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                end
                local tempPos = PlayerMapMarker._tempScreenPixelPos
                local bOK = false
                pcall(function()
                    local res = PC:ProjectWorldLocationToScreen(WorldLoc, tempPos, true)
                    if res == true or res == 1 then bOK = true end
                end)
                if not bOK or (tempPos.X == 0 and tempPos.Y == 0) then return false, 0, 0 end
                local canvasX, canvasY = PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, tempPos.X, tempPos.Y)
                return true, canvasX, canvasY
            end
            function PlayerMapMarker.GetBoneLocationWithFallback(Character, PrimaryBoneName)
                if not IsValid(Character) or not PrimaryBoneName then return nil end
                if Character._cachedBoneNames and Character._cachedBoneNames[PrimaryBoneName] then
                    local cachedName = Character._cachedBoneNames[PrimaryBoneName]
                    local loc = nil
                    pcall(function()
                        local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
                        if Mesh and Game:IsValid(Mesh) then
                            if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(cachedName)
                            elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(cachedName) end
                        end
                    end)
                    if loc then return loc end
                end
                local fallbacks = PlayerMapMarker.BoneNameFallbacks[PrimaryBoneName] or {PrimaryBoneName}
                for _, bname in ipairs(fallbacks) do
                    local loc = nil
                    pcall(function()
                        local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
                        if Mesh and Game:IsValid(Mesh) then
                            if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(bname)
                            elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(bname) end
                        end
                    end)
                    if loc then
                        if not Character._cachedBoneNames then Character._cachedBoneNames = {} end
                        Character._cachedBoneNames[PrimaryBoneName] = bname
                        return loc
                    end
                end
                return nil
            end
            function PlayerMapMarker.IsPlayerVisible(PC, Character)
                if not IsValid(PC) or not IsValid(Character) then return false end
                local now = os.clock()
                if Character._lastVisTime and (now - Character._lastVisTime) < 0.15 then
                    return Character._cachedIsVisible or false
                end
                Character._lastVisTime = now
                local bVis = false
                pcall(function()
                    if PC.LineOfSightTo then
                        if not PlayerMapMarker._ZeroVector then
                            local VT = FVector or import("/Script/CoreUObject.Vector")
                            if VT then PlayerMapMarker._ZeroVector = VT(0, 0, 0) end
                        end
                        bVis = PC:LineOfSightTo(Character, PlayerMapMarker._ZeroVector, false)
                    end
                end)
                if not bVis then
                    local KismetSystemLibrary = import("KismetSystemLibrary")
                    if KismetSystemLibrary and KismetSystemLibrary.LineTraceSingle then
                        pcall(function()
                            local camMgr = nil
                            local GameplayStatics = import("GameplayStatics")
                            if GameplayStatics and GameplayStatics.GetPlayerCameraManager then
                                camMgr = GameplayStatics.GetPlayerCameraManager(PC, 0)
                            end
                            local startLoc = camMgr and camMgr:GetCameraLocation() or PlayerMapMarker.GetMyLocation()
                            local headLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, "head")
                            if startLoc and headLoc then
                                if not PlayerMapMarker._CachedHitResult then
                                    local HitResultClass = import("HitResult") or import("/Script/Engine.HitResult")
                                    PlayerMapMarker._CachedHitResult = HitResultClass and HitResultClass() or {}
                                end
                                local bHit = KismetSystemLibrary.LineTraceSingle(PC, startLoc, headLoc, 0, false, nil, 0, PlayerMapMarker._CachedHitResult, true)
                                if bHit then
                                    local hitActor = nil
                                    if type(PlayerMapMarker._CachedHitResult.GetActor) == "function" then hitActor = PlayerMapMarker._CachedHitResult:GetActor()
                                    elseif PlayerMapMarker._CachedHitResult.Actor then hitActor = PlayerMapMarker._CachedHitResult.Actor end
                                    if hitActor and (hitActor == Character or (type(hitActor.IsChildOf) == "function" and hitActor:IsChildOf(Character))) then
                                        bVis = true
                                    end
                                else
                                    bVis = true
                                end
                            end
                        end)
                    end
                end
                Character._cachedIsVisible = bVis
                return bVis
            end
            function PlayerMapMarker.CreateSkeletonLineWidget()
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
                local Border = nil
                pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
                if not Border or not slua.isValid(Border) then return nil end
                pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5} end)
                pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5}) end)
                local Slot = nil
                pcall(function()
                    Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
                    if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(5) end
                end)
                return {
                    Widget = Border, Slot = Slot,
                    posVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
                    sizeVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
                    lastFromX = -99999, lastFromY = -99999,
                    lastToX = -99999, lastToY = -99999
                }
            end
            function PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, bVisible, TeamColor, bPlayerOnScreen, charLoc)
                if not PlayerMapMarker.bUseSkeleton then return end
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
                local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
                if not bVisible or not IsValid(Character) or not IsValid(PC) then
                    if PlayerBones then
                        for _, LineData in ipairs(PlayerBones) do
                            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                                LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                LineData.Widget._isSelfHitTestVisible = false
                            end
                        end
                    end
                    return
                end
                if not charLoc then charLoc = PlayerMapMarker.GetESPLocation(Character) end
                if not charLoc then return end
                if bPlayerOnScreen == nil then
                    local bOnScreen, _, _ = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, charLoc)
                    bPlayerOnScreen = bOnScreen
                end
                if not bPlayerOnScreen then
                    if PlayerBones then
                        for _, LineData in ipairs(PlayerBones) do
                            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                                LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                LineData.Widget._isSelfHitTestVisible = false
                            end
                        end
                    end
                    return
                end
                local dist = 0
                local myLoc = PlayerMapMarker._CachedMyLoc or PlayerMapMarker.GetMyLocation()
                if myLoc and charLoc then
                    local dx = (charLoc.X or 0) - (myLoc.X or 0)
                    local dy = (charLoc.Y or 0) - (myLoc.Y or 0)
                    local dz = (charLoc.Z or 0) - (myLoc.Z or 0)
                    dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                end
                if PlayerMapMarker.SkeletonMaxDistance and PlayerMapMarker.SkeletonMaxDistance > 0 then
                    if dist > PlayerMapMarker.SkeletonMaxDistance then
                        if PlayerBones then
                            for _, LineData in ipairs(PlayerBones) do
                                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                                    LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                    LineData.Widget._isSelfHitTestVisible = false
                                end
                            end
                        end
                        return
                    end
                end
                if not PlayerBones then
                    PlayerBones = {}
                    PlayerMapMarker.SkeletonWidgets[KeyStr] = PlayerBones
                end
                local lineColor = nil
                if PlayerMapMarker.bUseVisibilityColor then
                    local bTargetVisible = PlayerMapMarker.IsPlayerVisible(PC, Character)
                    if bTargetVisible then lineColor = PlayerMapMarker.SkeletonVisibleColor or FLinearColor(0.0, 1.0, 0.0, 0.8)
                    else lineColor = PlayerMapMarker.SkeletonCoverColor or FLinearColor(0.9, 0.0, 0.0, 0.6) end
                else
                    lineColor = PlayerMapMarker.SkeletonColor or TeamColor or FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SkeletonOpacity or 0.8)
                end
                local cache = PlayerMapMarker._StaticBoneLocCache
                for k in pairs(cache) do cache[k] = nil end
                local lineIndex = 0
                local thickness = PlayerMapMarker.SkeletonThickness or 1.2
                if not Character._cachedBones3D then Character._cachedBones3D = {} end
                for _, chain in ipairs(PlayerMapMarker.SkeletonChains) do
                    local lastCanvasX, lastCanvasY = nil, nil
                    for _, boneName in ipairs(chain) do
                        local boneWorldLoc = cache[boneName]
                        if boneWorldLoc == nil then
                            boneWorldLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, boneName) or false
                            cache[boneName] = boneWorldLoc
                        end
                        if boneWorldLoc == false then boneWorldLoc = nil end
                        local currentCanvasX, currentCanvasY = nil, nil
                        if boneWorldLoc then
                            local bOnScreen, cX, cY = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, boneWorldLoc)
                            if bOnScreen then
                                currentCanvasX = cX
                                currentCanvasY = cY
                            end
                        end
                        if lastCanvasX and currentCanvasX then
                            lineIndex = lineIndex + 1
                            local LineData = PlayerBones[lineIndex]
                            if not LineData or not LineData.Widget or not slua.isValid(LineData.Widget) then
                                LineData = PlayerMapMarker.CreateSkeletonLineWidget()
                                if LineData then PlayerBones[lineIndex] = LineData end
                            end
                            if LineData and LineData.Widget and LineData.Slot then
                                local Widget = LineData.Widget
                                local Slot = LineData.Slot
                                if Widget._cachedColor ~= lineColor then
                                    Widget:SetBrushColor(lineColor)
                                    Widget._cachedColor = lineColor
                                end
                                if not Widget._isSelfHitTestVisible then
                                    Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    Widget._isSelfHitTestVisible = true
                                end
                                local fromX = lastCanvasX
                                local fromY = lastCanvasY
                                local toX = currentCanvasX
                                local toY = currentCanvasY
                                local threshold = 0.15
                                if dist > 8000 then threshold = 0.8 elseif dist > 4000 then threshold = 0.4 end
                                if math.abs(fromX - LineData.lastFromX) > threshold or
                                   math.abs(fromY - LineData.lastFromY) > threshold or
                                   math.abs(toX - LineData.lastToX) > threshold or
                                   math.abs(toY - LineData.lastToY) > threshold then
                                    LineData.lastFromX = fromX
                                    LineData.lastFromY = fromY
                                    LineData.lastToX = toX
                                    LineData.lastToY = toY
                                    local dx = toX - fromX
                                    local dy = toY - fromY
                                    local length = math.sqrt(dx * dx + dy * dy)
                                    local angle_rad = (math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)
                                    local angle = angle_rad * 57.29577951308232
                                    local pVec = LineData.posVec
                                    pVec.X = fromX ; pVec.Y = fromY - thickness / 2.0
                                    Slot:SetPosition(pVec)
                                    local sVec = LineData.sizeVec
                                    sVec.X = length ; sVec.Y = thickness
                                    Slot:SetSize(sVec)
                                    Widget:SetRenderAngle(angle)
                                end
                            end
                        end
                        lastCanvasX = currentCanvasX
                        lastCanvasY = currentCanvasY
                    end
                end
                for i = lineIndex + 1, #PlayerBones do
                    local LineData = PlayerBones[i]
                    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                        LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        LineData.Widget._isSelfHitTestVisible = false
                    end
                end
            end
            function PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
                if PlayerBones then
                    for _, LineData in ipairs(PlayerBones) do
                        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                            pcall(function()
                                LineData.Widget:RemoveFromParent()
                                LineData.Widget:ConditionalBeginDestroy()
                            end)
                        end
                    end
                    PlayerMapMarker.SkeletonWidgets[KeyStr] = nil
                end
            end
            function PlayerMapMarker.ClearAllSkeletonLines()
                for KeyStr, PlayerBones in pairs(PlayerMapMarker.SkeletonWidgets) do
                    for _, LineData in ipairs(PlayerBones) do
                        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                            pcall(function()
                                LineData.Widget:RemoveFromParent()
                                LineData.Widget:ConditionalBeginDestroy()
                            end)
                        end
                    end
                end
                PlayerMapMarker.SkeletonWidgets = {}
            end
            function PlayerMapMarker.ClearAllESP()
                RedBoxOverlay.Stop()
                for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
                    PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
                end
                PlayerMapMarker.ESPWidgets = {}
                PlayerMapMarker.ESPWidgetPtrs = {}
                PlayerMapMarker.ClearAllSnapLines()
                PlayerMapMarker.ClearAllSkeletonLines()
                if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                    pcall(function()
                        local n = PlayerMapMarker.ESPCanvas:GetChildrenCount()
                        for i = n - 1, 0, -1 do
                            local child = PlayerMapMarker.ESPCanvas:GetChildAt(i)
                            if child and slua.isValid(child) then
                                if PlayerMapMarker.IsOurESPWidget(child) then PlayerMapMarker.ESPCanvas:RemoveChild(child) end
                            end
                        end
                    end)
                end
                PlayerMapMarker.ESPCanvas = nil
                PlayerMapMarker._OBHeadWidgetClass = nil
                PlayerMapMarker._OBHeadWidgetLoadFailed = false
                PlayerMapMarker._bDumpedWidgetChildren = false
                PlayerMapMarker._cachedViewportW = 1920
                PlayerMapMarker._cachedViewportH = 1080
            end
            function PlayerMapMarker.UpdateESP(AllPlayers, MyLoc)
                if not PlayerMapMarker.bUseScreenESP then return end
                PlayerMapMarker.bUseSnapLines = false
                PlayerMapMarker.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton
                if not PlayerMapMarker.InitESPCanvas() then
                    return
                end
                if PlayerMapMarker._OBHeadWidgetLoadFailed then return end
                local PC = PlayerMapMarker.GetMyPlayerController()
                if IsValid(PC) then
                    PlayerMapMarker.UpdateCanvasTransform(PC)
                end
                local fromX, fromY = 0, 0
                if PlayerMapMarker.bUseSnapLines and IsValid(PC) then
                    fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
                end
                local MyKey = PlayerMapMarker.GetMyPlayerKey()
                local SeenKeys = {}
                local MyChar = nil
                pcall(function()
                    local GDP = PlayerMapMarker.GetGameplayData()
                    if GDP and GDP.GetLocalCharacter then
                        MyChar = GDP.GetLocalCharacter()
                    else
                        if PC and PC.GetPawn then MyChar = PC:GetPawn() end
                    end
                end)
                local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)
                for PlayerKey, Character in pairs(AllPlayers) do
                    if IsValid(Character) then
                        local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
                        local bIsAI = PlayerMapMarker.IsAI(Character)
                        local KeyStr = tostring(PlayerKey)
                        local Name = PlayerMapMarker.GetPlayerName(Character)
                        local Loc = PlayerMapMarker.GetESPLocation(Character)
                        local DistStr = ""
                        if MyLoc and Loc then
                            DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc)
                        end
                        local bSkip = false
                        if bIsMe and not PlayerMapMarker.bIncludeMe then bSkip = true end
                        if bIsAI and not PlayerMapMarker.bIncludeAI then bSkip = true end
                        local TeamID = PlayerMapMarker.GetTeamID(Character)
                        if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then
                            bSkip = true
                        end
                        local bIsAlive = PlayerMapMarker.IsAlive(Character)
                        if not bSkip and Loc then
                            SeenKeys[KeyStr] = true
                            local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]
                            local Text = ""
                            if _G.LexusConfig.Esp9_Name then Text = Name else Text = "" end
                            if _G.LexusConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                                if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                            end
                            local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
                            if not ESPData then
                                local Widget = PlayerMapMarker.CreateESPWidget()
                                if Widget then
                                    PlayerMapMarker.ESPWidgets[KeyStr] = {
                                        Widget = Widget,
                                        Character = Character,
                                        Name = Name,
                                        LastDistStr = DistStr,
                                        TeamID = TeamID,
                                    }
                                    PlayerMapMarker.UpdateESPText(Widget, Text)
                                    if bIsAlive then
                                        PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                                        PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
                                        local HP = Character.Health or 0
                                        local MaxHP = Character.MaxHealth or 120
                                        local pct = 0
                                        if HP > 0 and MaxHP > 0 then
                                            pct = HP / MaxHP
                                            if pct > 1 then pct = 1 end
                                            if pct < 0 then pct = 0 end
                                        end
                                        PlayerMapMarker.UpdateESPHealth(Widget, pct)
                                        PlayerMapMarker.AddWeaponIconToESP(Widget, Character)
                                        if PlayerMapMarker.bUseSnapLines then
                                            PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                                        else
                                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                                        end
                                        if PlayerMapMarker.bUseSkeleton then
                                            PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                                        else
                                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                                        end
                                    else
                                        local Container = Widget.Container or Widget
                                        pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                                        PlayerMapMarker.UpdateESPHealth(Widget, 0)
                                        PlayerMapMarker.RemoveSnapLine(KeyStr)
                                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                                    end
                                end
                            else
                                ESPData.Character = Character
                                ESPData.Name = Name
                                ESPData.LastDistStr = DistStr
                                if bIsAlive then
                                    ESPData.TeamID = TeamID
                                    PlayerMapMarker.ApplyTeamColor(ESPData.Widget, TeamID)
                                    PlayerMapMarker.UpdateESPText(ESPData.Widget, Text)
                                    PlayerMapMarker.UpdateESPPositionWithPC(ESPData.Widget, Loc, PC, CanvasPos)
                                    local HP = Character.Health or 0
                                    local MaxHP = Character.MaxHealth or 120
                                    local pct = 0
                                    if HP > 0 and MaxHP > 0 then
                                        pct = HP / MaxHP
                                        if pct > 1 then pct = 1 end
                                        if pct < 0 then pct = 0 end
                                    end
                                    PlayerMapMarker.UpdateESPHealth(ESPData.Widget, pct)
                                    PlayerMapMarker.AddWeaponIconToESP(ESPData.Widget, Character)
                                    if PlayerMapMarker.bUseSnapLines then
                                        PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                                    else
                                        PlayerMapMarker.RemoveSnapLine(KeyStr)
                                    end
                                    if PlayerMapMarker.bUseSkeleton then
                                        PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                                    else
                                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                                    end
                                else
                                    local Container = ESPData.Widget.Container or ESPData.Widget
                                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                                    PlayerMapMarker.UpdateESPHealth(ESPData.Widget, 0)
                                    PlayerMapMarker.RemoveSnapLine(KeyStr)
                                    PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                                end
                            end
                        end
                    end
                end
                for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
                    if not SeenKeys[KeyStr] then
                        PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
                        PlayerMapMarker.ESPWidgets[KeyStr] = nil
                    end
                end
            end
            function PlayerMapMarker.UpdateESPLight()
                if RedBoxOverlay and RedBoxOverlay.bActive then RedBoxOverlay.UpdatePosition() end
                if not PlayerMapMarker.bUseScreenESP then return end
                PlayerMapMarker.bUseSnapLines = false
                PlayerMapMarker.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton
                if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
                local PC = PlayerMapMarker.GetMyPlayerController()
                if not IsValid(PC) then return end
                PlayerMapMarker.UpdateCanvasTransform(PC)
                local fromX, fromY = 0, 0
                if PlayerMapMarker.bUseSnapLines then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end
                for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
                    local Widget = ESPData.Widget
                    local Character = ESPData.Character
                    local Container = Widget and (Widget.Container or Widget)
                    local bWidgetValid = false
                    pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
                    if Widget and bWidgetValid and Character and IsValid(Character) then
                        local bIsAlive = PlayerMapMarker.IsAlive(Character)
                        if not bIsAlive then
                            if ESPData._LastContainerVisibility ~= UEnums.ESlateVisibility.Collapsed then
                                ESPData._LastContainerVisibility = UEnums.ESlateVisibility.Collapsed
                                pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            end
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        else
                            local bShowAnyUI = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
                            local desiredVisibility = bShowAnyUI and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed
                            if ESPData._LastContainerVisibility ~= desiredVisibility then
                                ESPData._LastContainerVisibility = desiredVisibility
                                pcall(function() Container:SetWidgetVisibility(desiredVisibility) end)
                            end
                            if ESPData._LastRenderOpacity ~= 1.0 then
                                ESPData._LastRenderOpacity = 1.0
                                pcall(function() Container:SetRenderOpacity(1.0) end)
                            end
                            local Loc = PlayerMapMarker.GetESPLocation(Character)
                            if Loc then
                                local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
                                PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                                if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                                else PlayerMapMarker.RemoveSnapLine(KeyStr) end
                                if PlayerMapMarker.bUseSkeleton then
                                    PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(ESPData.TeamID), bOnScreen, Loc)
                                else
                                    PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                                end
                            else
                                PlayerMapMarker.RemoveSnapLine(KeyStr)
                                PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                            end
                        end
                    end
                end
            end
            function PlayerMapMarker.UpdateESPDistances()
                if not PlayerMapMarker.bUseScreenESP then return end
                local MyLoc = PlayerMapMarker.GetMyLocation()
                if not MyLoc then return end
                local PC = PlayerMapMarker.GetMyPlayerController()
                if not IsValid(PC) then return end
                PlayerMapMarker.UpdateCanvasTransform(PC)
                for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
                    local Character = ESPData.Character
                    local Widget = ESPData.Widget
                    local Container = Widget and (Widget.Container or Widget)
                    local bWidgetValid = false
                    pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
                    if Character and IsValid(Character) and Widget and bWidgetValid then
                        local Loc = PlayerMapMarker.GetESPLocation(Character)
                        if Loc then
                            local Dist = PlayerMapMarker.CalcDistance(MyLoc, Loc)
                            ESPData.LastDistance = Dist
                            if PlayerMapMarker.bShowDistance then
                                local DistStr = ""
                                local Meters = 0
                                if Dist then
                                    Meters = Dist / 100
                                    if Meters < 1000 then DistStr = string.format("%dm", math.floor(Meters))
                                    else DistStr = string.format("%.1fkm", Meters / 1000) end
                                end
                                local Name = ESPData.Name or "Unknown"
                                local Text = ""
                                if _G.LexusConfig.Esp9_Name then Text = Name else Text = "" end
                                if _G.LexusConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                                    if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                                end
                                ESPData.LastDistStr = DistStr
                                PlayerMapMarker.UpdateESPText(Widget, Text)
                            end
                        end
                    end
                end
            end
            function PlayerMapMarker.ScanAndUpdate()
                local AllChars = PlayerMapMarker.GetAllCharacters()
                if not AllChars then RedBoxOverlay.SetCounts(0, 0) return 0 end
                local MyKey = PlayerMapMarker.GetMyPlayerKey()
                local MyLoc = PlayerMapMarker.GetMyLocation()
                local MyChar = nil
                pcall(function()
                    local GDP = PlayerMapMarker.GetGameplayData()
                    if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
                    else local PC = PlayerMapMarker.GetMyPlayerController() if PC and PC.GetPawn then MyChar = PC:GetPawn() end end
                end)
                local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)
                local realPlayers = 0
                local botPlayers = 0
                for PlayerKey, Character in pairs(AllChars) do
                    if IsValid(Character) then
                        local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
                        local bIsAI = PlayerMapMarker.IsAI(Character)
                        local bIsAlive = PlayerMapMarker.IsAlive(Character)
                        if bIsAlive and not bIsMe then
                            local bIsMyTeam = false
                            if MyTeamID ~= nil then
                                local targetTeamID = PlayerMapMarker.GetTeamID(Character)
                                if targetTeamID == MyTeamID then bIsMyTeam = true end
                            end
                            if not bIsMyTeam then
                                if bIsAI then botPlayers = botPlayers + 1
                                else realPlayers = realPlayers + 1 end
                            end
                        end
                    end
                end
                if _G.LexusConfig.Esp9_Count then
                    if RedBoxOverlay.bActive then RedBoxOverlay.SetCounts(realPlayers, botPlayers) end
                else
                    if RedBoxOverlay.bActive then RedBoxOverlay.Stop() end
                end
                if PlayerMapMarker.bUseScreenESP then
                    PlayerMapMarker.UpdateESP(AllChars, MyLoc)
                    return 0
                end
                return 0
            end
            function PlayerMapMarker._CancelTimers()
                PlayerMapMarker._TimerGeneration = (PlayerMapMarker._TimerGeneration or 0) + 1
                local handles = PlayerMapMarker._TimerHandles or {}
                local pc = PlayerMapMarker._ActiveTimerPC
                for i = 1, #handles do
                    local h = handles[i]
                    if h then
                        pcall(function()
                            if pc and slua and slua.isValid and slua.isValid(pc) and pc.RemoveGameTimer then
                                pc:RemoveGameTimer(h)
                            end
                        end)
                        pcall(function()
                            if _G.Game and _G.Game.RemoveGameTimer then
                                _G.Game:RemoveGameTimer(h)
                            end
                        end)
                    end
                end
                PlayerMapMarker._TimerHandles = {}
                PlayerMapMarker._ActiveTimerPC = nil
                PlayerMapMarker._ActiveTimerTick = 0
                PlayerMapMarker._AttachPending = nil
                PlayerMapMarker._AttachPendingTime = nil
            end
            function PlayerMapMarker.AttachTimers()
                pcall(function()
                    local pc = PlayerMapMarker.GetMyPlayerController()
                    if not (pc and slua and slua.isValid and slua.isValid(pc) and pc.AddGameTimer) then
                        local now = os.clock()
                        if PlayerMapMarker._AttachPending
                            and PlayerMapMarker._AttachPendingTime
                            and (now - PlayerMapMarker._AttachPendingTime) < 2.0 then
                            return
                        end
                        PlayerMapMarker._AttachPending = true
                        PlayerMapMarker._AttachPendingTime = now
                        pcall(function()
                            require("timer").SetGameTimer(1.0, false, function()
                                PlayerMapMarker._AttachPending = nil
                                PlayerMapMarker._AttachPendingTime = nil
                                PlayerMapMarker.AttachTimers()
                            end)
                        end)
                        return
                    end
                    PlayerMapMarker._AttachPending = nil
                    PlayerMapMarker._AttachPendingTime = nil
                    local now = os.clock()
                    local lastPC = PlayerMapMarker._ActiveTimerPC
                    local lastTick = PlayerMapMarker._ActiveTimerTick
                    if lastPC and slua.isValid(lastPC) and lastPC == pc then
                        if lastTick > 0 and (now - lastTick) < 5.0 then return end
                    end
                    PlayerMapMarker._CancelTimers()
                    PlayerMapMarker._ActiveTimerPC = pc
                    PlayerMapMarker._ActiveTimerTick = now
                    local generation = PlayerMapMarker._TimerGeneration or 0
                    local handles = PlayerMapMarker._TimerHandles
                    local h1 = nil
                    local h2 = nil
                    local h3 = nil
                    pcall(function()
                        h1 = pc:AddGameTimer(PlayerMapMarker.nUpdateInterval or 0.5, true, function()
                            if generation ~= PlayerMapMarker._TimerGeneration then return end
                            PlayerMapMarker._ActiveTimerTick = os.clock()
                            if PlayerMapMarker.bActive then
                                pcall(PlayerMapMarker.ScanAndUpdate)
                            end
                        end)
                    end)
                    pcall(function()
                        h2 = pc:AddGameTimer(PlayerMapMarker._LightUpdateInterval or 0.05, true, function()
                            if generation ~= PlayerMapMarker._TimerGeneration then return end
                            PlayerMapMarker._ActiveTimerTick = os.clock()
                            if PlayerMapMarker.bActive then
                                pcall(PlayerMapMarker.UpdateESPLight)
                            end
                        end)
                    end)
                    pcall(function()
                        h3 = pc:AddGameTimer(PlayerMapMarker._DistanceUpdateInterval or 0.1, true, function()
                            if generation ~= PlayerMapMarker._TimerGeneration then return end
                            PlayerMapMarker._ActiveTimerTick = os.clock()
                            if PlayerMapMarker.bActive and PlayerMapMarker.bUseScreenESP and PlayerMapMarker.bShowDistance then
                                pcall(PlayerMapMarker.UpdateESPDistances)
                            end
                        end)
                    end)
                    if h1 then handles[#handles + 1] = h1 end
                    if h2 then handles[#handles + 1] = h2 end
                    if h3 then handles[#handles + 1] = h3 end
                    pcall(function() require("timer").SetGameTimer(5.0, false, PlayerMapMarker.AttachTimers) end)
                end)
            end
            function PlayerMapMarker.EnsureRunning()
                local L = _G.LexusConfig or {}
                local c = _G.GTLMODConfig or {}
                local want = (L.Esp9_Name == true)
                    or (L.Esp9_Weapon == true) or (L.Esp9_Distance == true) or (L.Esp9_HP == true)
                    or (L.Esp9_Team == true) or (L.Esp9_Skeleton == true)
                    or (c.EspModelName == true) or (c.EspWeaponIcon == true)
                if not want then
                    if PlayerMapMarker.bActive then PlayerMapMarker.Stop() end
                    return false
                end
                local pc = nil
                pcall(function() pc = PlayerMapMarker.GetMyPlayerController() end)
                local lastPC = PlayerMapMarker._ActiveTimerPC
                local pcChanged = (not lastPC)
                    or (slua and slua.isValid and not slua.isValid(lastPC))
                    or (pc ~= nil and lastPC ~= pc)
                local canvasOk = false
                pcall(function()
                    canvasOk = PlayerMapMarker.ESPCanvas and Game and Game.IsValid and Game:IsValid(PlayerMapMarker.ESPCanvas)
                end)
                local now = os.clock()
                local lastTick = PlayerMapMarker._ActiveTimerTick or 0
                local stale = (lastTick > 0) and ((now - lastTick) > 6.0)
                local lastEnsure = PlayerMapMarker._LastEnsureAt or 0
                local tooSoon = (os.clock() - lastEnsure) < 0.35
                local needsRebind = (not PlayerMapMarker.bActive) or pcChanged or (not canvasOk) or stale
                if not needsRebind then
                    return true
                end
                if tooSoon and PlayerMapMarker.bActive and not pcChanged then
                    return true
                end
                PlayerMapMarker._LastEnsureAt = os.clock()
                if pcChanged or not canvasOk or stale then
                    pcall(PlayerMapMarker._CancelTimers)
                end
                if not canvasOk then
                    PlayerMapMarker.ESPWidgets = {}
                    PlayerMapMarker.ESPWidgetPtrs = {}
                    PlayerMapMarker.SnapLineWidgets = {}
                    PlayerMapMarker.SkeletonWidgets = {}
                    PlayerMapMarker.ESPCanvas = nil
                    PlayerMapMarker._OBHeadWidgetClass = nil
                    PlayerMapMarker._OBHeadWidgetLoadFailed = false
                end
                PlayerMapMarker.bActive = true
                PlayerMapMarker._FrameCount = 0
                PlayerMapMarker._ActiveTimerPC = nil
                PlayerMapMarker._ActiveTimerTick = 0
                PlayerMapMarker._AttachPending = nil
                pcall(function() PlayerMapMarker.AttachTimers() end)
                pcall(function() PlayerMapMarker.ScanAndUpdate() end)
                return true
            end
            function PlayerMapMarker.Start()
                pcall(PlayerMapMarker._CancelTimers)
                PlayerMapMarker.bActive = false
                PlayerMapMarker.ESPCanvas = nil
                pcall(function()
                    local RBO = _G.RedBoxOverlay
                    if RBO and (RBO.bActive or RBO.MainContainer) then
                        RBO.bActive = false
                        RBO.MainContainer = nil
                        RBO.WidgetSlot = nil
                        RBO.TextBlockPlayer = nil
                        RBO.TextBlockBot = nil
                        RBO._CachedPosVec = nil
                        RBO._CachedTextPlayer = ""
                        RBO._CachedTextBot = ""
                    end
                end)
                return PlayerMapMarker.EnsureRunning()
            end
            function PlayerMapMarker.Stop()
                PlayerMapMarker.bActive = false
                PlayerMapMarker._FrameCount = 0
                pcall(PlayerMapMarker._CancelTimers)
                PlayerMapMarker.ClearAllESP()
            end
            _G.PlayerMapMarker = PlayerMapMarker
            print("[StarExact] ESP9 PlayerMapMarker + RedBox (black) loaded")
            end)
            pcall(function()
            if _G._StarGrenadePortComplete then return end
            _G._StarGrenadePortComplete = true
            _G.LexusConfig = _G.LexusConfig or {}
            if _G.LexusConfig.EspItemBom == nil then _G.LexusConfig.EspItemBom = false end
            _G.GTLMODConfig = _G.GTLMODConfig or {}
            if _G.GTLMODConfig.EspActiveBom == nil then _G.GTLMODConfig.EspActiveBom = false end
            _G.LexusConfig.EspActiveBom = (_G.GTLMODConfig.EspActiveBom == true)
            _G.LexusConfig.EspBomMaster = _G.LexusConfig.EspActiveBom
            local function GValid(obj)
                if not obj then return false end
                local ok, v = pcall(function() return slua.isValid(obj) end)
                return ok and v == true
            end
            local Cached_MyHUD = nil
            local function RefreshHUD()
                pcall(function()
                    local PC = nil
                    if GameplayData and GameplayData.GetPlayerController then
                        PC = GameplayData.GetPlayerController()
                    end
                    if not GValid(PC) then
                        local GS = import("GameplayStatics")
                        if GS and GS.GetPlayerController then
                            PC = GS.GetPlayerController(slua.getWorld and slua.getWorld() or nil, 0)
                        end
                    end
                    if not GValid(PC) and slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
                        PC = slua_GameFrontendHUD:GetPlayerController()
                    end
                    if GValid(PC) then Cached_MyHUD = PC.MyHUD end
                end)
                return Cached_MyHUD
            end
            local function GetLocalPlayer()
                local lp = nil
                pcall(function()
                    if GameplayData and GameplayData.GetPlayerCharacter then
                        lp = GameplayData.GetPlayerCharacter()
                    end
                    if not GValid(lp) then
                        local PC = nil
                        if GameplayData and GameplayData.GetPlayerController then
                            PC = GameplayData.GetPlayerController()
                        end
                        if GValid(PC) and PC.GetPlayerCharacterSafety then
                            lp = PC:GetPlayerCharacterSafety()
                        end
                    end
                end)
                return lp
            end
            local function GrenadeSweepColor(now, phase)
                local t = (now * 2.8 + phase) % (math.pi * 2)
                local sweep = (math.sin(t) + 1) * 0.5
                local gold = { R = 255, G = 210, B = 40, A = 255 }
                local white = { R = 255, G = 255, B = 255, A = 255 }
                return {
                    R = math.floor(gold.R + (white.R - gold.R) * sweep + 0.5),
                    G = math.floor(gold.G + (white.G - gold.G) * sweep + 0.5),
                    B = math.floor(gold.B + (white.B - gold.B) * sweep + 0.5),
                    A = 255
                }
            end
            local function ClassifyBomb(actor)
                local nameLower = ""
                pcall(function()
                    if type(actor.GetName) == "function" then
                        nameLower = string.lower(tostring(actor:GetName() or ""))
                    else
                        nameLower = string.lower(tostring(actor))
                    end
                    if (nameLower == "" or nameLower == "nil") and actor.GetClass then
                        local c = actor:GetClass()
                        if c and c.GetName then nameLower = string.lower(tostring(c:GetName() or "")) end
                    end
                end)
                if nameLower == "" then return 0, false end
                local bType = 0
                if string.find(nameLower, "smoke", 1, true) then
                    bType = 2
                elseif string.find(nameLower, "molotov", 1, true) or string.find(nameLower, "burn", 1, true)
                    or string.find(nameLower, "incendiary", 1, true) then
                    bType = 3
                elseif string.find(nameLower, "flash", 1, true) or string.find(nameLower, "stun", 1, true) then
                    bType = 4
                elseif string.find(nameLower, "m79", 1, true) or string.find(nameLower, "launcher", 1, true) then
                    bType = 5
                elseif string.find(nameLower, "grenade", 1, true) or string.find(nameLower, "frag", 1, true)
                    or string.find(nameLower, "boom", 1, true) or string.find(nameLower, "projectile_grenade", 1, true)
                    or string.find(nameLower, "bp_grenade", 1, true) or string.find(nameLower, "thrown", 1, true) then
                    bType = 1
                end
                if bType == 0 then return 0, false end
                local isItem = true
                if string.find(nameLower, "projectile", 1, true)
                    or string.find(nameLower, "thrown", 1, true)
                    or string.find(nameLower, "cook", 1, true)
                    or string.find(nameLower, "predict", 1, true)
                    or string.find(nameLower, "flying", 1, true) then
                    isItem = false
                end
                pcall(function()
                    if actor.bIsPinPulled or actor.bPinPulled then isItem = false end
                    if type(actor.IsPinPulled) == "function" and actor:IsPinPulled() then isItem = false end
                    if actor.ExplosionTime or actor.ExplodeTime then isItem = false end
                end)
                return bType, isItem
            end
            local function StarGrenadeTick()
                _G.LexusConfig = _G.LexusConfig or {}
                if not (_G.GTLMODConfig and _G.GTLMODConfig.EspActiveBom == true) then
                    _G.LexusConfig.EspActiveBom = false
                    _G.LexusConfig.EspBomMaster = false
                    return
                end
                _G.LexusConfig.EspBomMaster = true
                _G.LexusConfig.EspActiveBom = true
                local localPlayer = GetLocalPlayer()
                Cached_MyHUD = Cached_MyHUD or RefreshHUD()
                local MyHUD = Cached_MyHUD
                if not GValid(MyHUD) then
                    RefreshHUD()
                    MyHUD = Cached_MyHUD
                end
                if not GValid(MyHUD) or not MyHUD.AddDebugText then return end
                pcall(function()
                    if not _G.CachedGameplayStatics then
                        _G.CachedGameplayStatics = import("GameplayStatics")
                    end
                    local GS = _G.CachedGameplayStatics
                    if not GS then return end
                    if not _G.CachedActorClass_ForBomb then
                        _G.CachedActorClass_ForBomb = import("Actor")
                    end
                    local world = nil
                    pcall(function()
                        if slua.getWorld then world = slua.getWorld() end
                    end)
                    local gameInstance = nil
                    pcall(function()
                        local ui_util = require("client.common.ui_util")
                        if ui_util and ui_util.GetGameInstance then
                            gameInstance = ui_util.GetGameInstance()
                        end
                    end)
                    local ctx = gameInstance or world
                    if not ctx then return end
                    local curTime = os.clock()
                    if not _G.LastBombScanTime or (curTime - _G.LastBombScanTime) > 0.30 then
                        _G.LastBombScanTime = curTime
                        if not _G.LastBombCacheWipe or (curTime - _G.LastBombCacheWipe) > 3.0 then
                            _G.LastBombCacheWipe = curTime
                            _G.NonBombCache = setmetatable({}, { __mode = "k" })
                        end
                        if not _G.BombCache then
                            _G.BombCache = setmetatable({}, { __mode = "k" })
                        end
                        if not _G.NonBombCache then
                            _G.NonBombCache = setmetatable({}, { __mode = "k" })
                        end
                        local activeBombs = {}
                        local itemBombs = {}
                        local arr = nil
                        pcall(function()
                            if slua.Array and UEnums then
                                arr = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForBomb)
                            end
                        end)
                        local allActors = nil
                        pcall(function()
                            if arr then
                                allActors = GS.GetAllActorsOfClass(ctx, _G.CachedActorClass_ForBomb, arr)
                            else
                                allActors = GS.GetAllActorsOfClass(ctx, _G.CachedActorClass_ForBomb)
                            end
                        end)
                        if allActors then
                            local function consider(actor)
                                if not GValid(actor) then return end
                                if actor.bHidden or actor.bTearOff then return end
                                if _G.NonBombCache[actor] then return end
                                local bType, isItem = 0, false
                                local known = _G.BombCache[actor]
                                if known then
                                    bType = known.type
                                    isItem = known.isItem
                                else
                                    bType, isItem = ClassifyBomb(actor)
                                    if bType > 0 then
                                        _G.BombCache[actor] = { type = bType, isItem = isItem }
                                    else
                                        _G.NonBombCache[actor] = true
                                        return
                                    end
                                end
                                local pending = false
                                pcall(function()
                                    if type(actor.IsPendingKill) == "function" then
                                        pending = actor:IsPendingKill()
                                    end
                                end)
                                if pending then
                                    _G.BombCache[actor] = nil
                                    return
                                end
                                if isItem then
                                    itemBombs[#itemBombs + 1] = { act = actor, type = bType }
                                else
                                    activeBombs[#activeBombs + 1] = { act = actor, type = bType }
                                end
                            end
                            if type(allActors) == "table" then
                                for _, actor in pairs(allActors) do
                                    consider(actor)
                                end
                            else
                                pcall(function()
                                    local n = allActors.Num and allActors:Num() or 0
                                    for i = 0, n - 1 do
                                        local actor = allActors:Get(i)
                                        consider(actor)
                                    end
                                end)
                            end
                        end
                        _G.CachedActiveBombs = activeBombs
                        _G.CachedItemBombs = itemBombs
                    end
                    local curGameTime = 0
                    pcall(function()
                        if GS.GetTimeSeconds then
                            curGameTime = GS.GetTimeSeconds(ctx) or 0
                        end
                    end)
                    local function DrawBombs(bombList, isItem, maxDist)
                        if not bombList then return end
                        for _, item in ipairs(bombList) do
                            local bomb = item.act
                            local bType = item.type
                            if not GValid(bomb) or bomb.bHidden then goto cont end
                            local distM = 0
                            pcall(function()
                                if GValid(localPlayer) and localPlayer.GetDistanceTo then
                                    distM = localPlayer:GetDistanceTo(bomb) / 100
                                end
                            end)
                            if distM <= 0 or distM > maxDist then goto cont end
                            local displayName = "BOOM"
                            local bombColor = GrenadeSweepColor(curTime, isItem and 0.7 or 0.0)
                            local zOffset = isItem and 15 or 30
                            if bType == 1 then
                                displayName = "BOOM"
                                bombColor = GrenadeSweepColor(curTime, 0.0)
                            elseif bType == 2 then
                                displayName = "SMOKE"
                                bombColor = { R = 220, G = 220, B = 220, A = 255 }
                            elseif bType == 3 then
                                displayName = "FIRE"
                                bombColor = { R = 255, G = 120, B = 20, A = 255 }
                            elseif bType == 4 then
                                displayName = "FLASH"
                                bombColor = { R = 100, G = 255, B = 255, A = 255 }
                            elseif bType == 5 then
                                displayName = "SMOKE SHELL"
                                bombColor = { R = 120, G = 255, B = 120, A = 255 }
                            end
                            local text = string.format("%s [%dm]", displayName, math.floor(distM))
                            local shouldTimer = not isItem
                            if isItem then
                                pcall(function()
                                    if bomb.bIsPinPulled or bomb.bPinPulled
                                        or (type(bomb.IsPinPulled) == "function" and bomb:IsPinPulled()) then
                                        shouldTimer = true
                                    end
                                end)
                            end
                            if shouldTimer and curGameTime > 0 then
                                local timeLeft = -1
                                pcall(function()
                                    if bomb.ExplosionTime then
                                        timeLeft = bomb.ExplosionTime - curGameTime
                                    elseif bomb.ExplodeTime then
                                        timeLeft = bomb.ExplodeTime - curGameTime
                                    end
                                end)
                                if timeLeft < 0 or timeLeft > 100 then
                                    _G.ActiveBombTimers = _G.ActiveBombTimers or {}
                                    local bombId = tostring(bomb)
                                    if not _G.ActiveBombTimers[bombId] then
                                        _G.ActiveBombTimers[bombId] = curGameTime
                                    end
                                    local elapsed = curGameTime - _G.ActiveBombTimers[bombId]
                                    local maxTime = (bType == 1 and 7.0) or (bType == 2 and 45.0)
                                        or (bType == 3 and 12.0) or (bType == 4 and 5.0) or 45.0
                                    timeLeft = maxTime - elapsed
                                end
                                if timeLeft < 0 then timeLeft = 0 end
                                if timeLeft > 0.05 then
                                    text = string.format("%s (%.1fs)", text, timeLeft)
                                end
                            end
                            local dynamicScale = math.max(0.75, 1.25 - (distM / maxDist) * 0.4)
                            pcall(function()
                                MyHUD:AddDebugText(
                                    text, bomb, 0.28,
                                    { X = 0, Y = 0, Z = zOffset },
                                    { X = 0, Y = 0, Z = zOffset },
                                    bombColor, true, false, true, nil, dynamicScale, true
                                )
                            end)
                            ::cont::
                        end
                    end
                    DrawBombs(_G.CachedActiveBombs, false, 180)
                    if _G.LexusConfig.EspItemBom then
                        DrawBombs(_G.CachedItemBombs, true, 50)
                    end
                end)
            end
            do
                local tk = nil
                pcall(function() tk = require("common.time_ticker") end)
                if tk and tk.AddTimerOnce then
                    local function loop()
                        pcall(StarGrenadeTick)
                        local on = _G.GTLMODConfig and _G.GTLMODConfig.EspActiveBom == true
                        tk.AddTimerOnce(on and 0.12 or 1.0, loop)
                    end
                    tk.AddTimerOnce(1.5, loop)
                end
            end
            print("[StarExact] Active Grenade Warning — restored + toggle READY")
            end)
            function _G.ApplyBlackSky(enable)
                pcall(function()
                    local gi = nil
                    if slua_GameFrontendHUD and slua_GameFrontendHUD.GetGameInstance then
                        gi = slua_GameFrontendHUD:GetGameInstance()
                    end
                    if not gi then
                        local ui_util = require("client.common.ui_util")
                        if ui_util and ui_util.GetGameInstance then gi = ui_util.GetGameInstance() end
                    end
                    if gi and gi.ExecuteCMD then
                        if enable then
                            gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                            gi:ExecuteCMD("r.SkyLightIntensityMultiplier", "0")
                        else
                            gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
                            gi:ExecuteCMD("r.SkyLightIntensityMultiplier", "1")
                        end
                    end
                    local KSL = import("KismetSystemLibrary")
                    if KSL and KSL.ExecuteConsoleCommand then
                        pcall(function()
                            KSL.ExecuteConsoleCommand(enable and "r.CylinderMaxDrawHeight 9999" or "r.CylinderMaxDrawHeight 0")
                        end)
                    end
                end)
            end
            pcall(function()
                local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
                if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl then
                    local impl = IngamePhoneStateUI.__inner_impl
                    impl.UpdateArtQualityUI = function(self, _u1, _u2)
                        if not self.UIRoot or not self.UIRoot.TextBlock_quality then return end
                        self.UIRoot.TextBlock_quality:SetText("<MAGOO>")
                        pcall(function()
                            self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.8, 0, 1)))
                        end)
                    end
                end
            end)
            pcall(function()
                local function NoOp() end
                local function RT() return true end
                local function RF() return false end
                local function SafeOverride(tbl, key, replacement)
                    if tbl and tbl[key] ~= nil then pcall(function() tbl[key] = replacement end) end
                end
                if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
                local loader = rawget(_G, "slua_loader")
                if loader then
                    SafeOverride(loader, "verifyBytecode", NoOp)
                    SafeOverride(loader, "checkIntegrity", NoOp)
                end
                local AvatarUtils = package.loaded.AvatarUtils
                if AvatarUtils then
                    SafeOverride(AvatarUtils, "CheckIsWeaponInBlackList", RF)
                    SafeOverride(AvatarUtils, "IsValidAvatar", RT)
                    SafeOverride(AvatarUtils, "CheckAvatarIntegrity", RT)
                    SafeOverride(AvatarUtils, "ReportInvalidAvatar", NoOp)
                end
                if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
                    local blocked = {
                        ReportAttackFlow=true, ReportSecAttackFlow=true, ReportAimFlow=true,
                        ReportHitFlow=true, report_aim_bot=true, report_esp_usage=true,
                        report_modded_files=true, client_anti_cheat_report=true,
                        report_wall_hack=true, ShootVerifyFailed=true, tss_sdk_report=true,
                        AntiCheatReport=true, IntegrityCheck=true, SignatureVerify=true,
                    }
                    local orig = NetUtil.SendPacket
                    NetUtil.SendPacket = function(self, packetName, ...)
                        if blocked[packetName] then return nil end
                        return orig(self, packetName, ...)
                    end
                    NetUtil.IsBypassed = true
                end
            end)
            _G.FufuModState = _G.FufuModState or {}
            _G.GTLMODState = _G.GTLMODState or {}
            _G.GTLMODState.CustomTextData = _G.GTLMODState.CustomTextData or {}
            _G.FufuModState.CustomTextData = _G.GTLMODState.CustomTextData
            _G.FufuModConfig = _G.FufuModConfig or {}
            -- === skin system removed (space reduction) ===
            _G.skinIdCache = {}
            _G.skinIdCache2 = {}
            _G.OutfitMap = {}
            _G.WeaponSkinMap = {}
            _G.VehicleSkinMap = {}
            _G.LexusConfig = _G.LexusConfig or {}
            _G.LexusConfig.ModSkin = false
            _G.LexusConfig.SkinDeadBox = false
            _G.LexusConfig.SkinAttachment = false
            _G.LexusConfig.KillMessage = false
            _G.LexusConfig.KillCountUI = false
            _G.LexusConfig.ModEmote = false
            function _G.MagooEnableAllSkins(enable) return end
            function _G.MagooStartAddOutfitSkins() return end
            _G.AddOutfit = nil
            -- === end skin removal ===

            function _G.StartAuthenticatedRuntime()
                if _G._MAGOO_RUNTIME_STARTED then return end
                local licensed = (_G._LICENSE_OK == true)
                    or (_G.LoginSystem and _G.LoginSystem.IsLoggedIn and _G.LoginSystem.IsLoggedIn())
                if not licensed then return end
                isExpired = false
                _G._MOD_EXPIRED = false
                _G._LICENSE_OK = true
                _G._MAGOO_RUNTIME_STARTED = true
                pcall(function()
                    local ticker = GetTicker and GetTicker() or nil
                    if not ticker then
                        local ok, tk = pcall(require, "common.time_ticker")
                        if ok then ticker = tk end
                    end
                    if ticker and ticker.AddTimerOnce then
                        if not _G._MAGOO_FEATURE_TICKERS_STARTED then
                            _G._MAGOO_FEATURE_TICKERS_STARTED = true
                            ticker.AddTimerOnce(0.30, MainTick)
                            ticker.AddTimerOnce(0.45, AimbotTick)
                            ticker.AddTimerOnce(0.55, PrivFeaturesTick)
                            ticker.AddTimerOnce(0.70, IpadFOVTick)
                            ticker.AddTimerOnce(1.20, CounterTickLoop)
                            ticker.AddTimerOnce(1.50, ESPLineTickLoop)
                            ticker.AddTimerOnce(1.0,  function() pcall(InitScreenMarkSystem) end)
                            ticker.AddTimerOnce(1.80, BoxESPTickLoop)
                            ticker.AddTimerOnce(2.00, RadarESPTickLoop)
                            if not _G.TickLootESP then
                                local function MagooGetHUD()
                                    local hud = rawget(_G, "_MagooHUD")
                                    if hud and slua and slua.isValid and slua.isValid(hud) then return hud end
                                    pcall(function()
                                        local pc = nil
                                        if GameplayData and GameplayData.GetPlayerController then pc = GameplayData.GetPlayerController() end
                                        if (not pc) and slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
                                        if pc and pc.MyHUD then hud = pc.MyHUD end
                                    end)
                                    if hud then _G._MagooHUD = hud end
                                    return hud
                                end
                                local function MagooDrawLabel(actor, text, zOff, col)
                                    if not actor then return end
                                    pcall(function()
                                        local hud = MagooGetHUD()
                                        if not hud or not hud.AddDebugText then return end
                                        local c = col or {R=1,G=1,B=1,A=1}
                                        hud:AddDebugText(tostring(text or ""), actor, 0.55, {X=0,Y=0,Z=zOff or 60}, {X=0,Y=0,Z=zOff or 60}, c, true, false, true, nil, 1.15, true)
                                    end)
                                end
                                function _G.TickLootESP()
                                    local cfg = _G.GTLMODConfig
                                    if not cfg or cfg.EspLoot ~= true then return end
                                    pcall(function()
                                        if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                                        if not _G.CachedActorClass_ForLoot then
                                            pcall(function() _G.CachedActorClass_ForLoot = import("PickUpWrapperActor") end)
                                            if not _G.CachedActorClass_ForLoot then
                                                pcall(function() _G.CachedActorClass_ForLoot = import("STExtraWeapon") end)
                                            end
                                            if not _G.CachedActorClass_ForLoot then
                                                pcall(function() _G.CachedActorClass_ForLoot = import("Actor") end)
                                            end
                                        end
                                        if not _G.CachedActorClass_ForLoot then return end
                                        if not _G.CachedLootArray then
                                            _G.CachedLootArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForLoot)
                                        end
                                        local ui_util = require("client.common.ui_util")
                                        local gi = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
                                        if not gi then return end
                                        local now = os.clock()
                                        if not _G.LastLootScanTime or (now - _G.LastLootScanTime) >= 0.55 then
                                            _G.LastLootScanTime = now
                                            local all = _G.CachedGameplayStatics.GetAllActorsOfClass(gi, _G.CachedActorClass_ForLoot, _G.CachedLootArray)
                                            local items = {}
                                            local kws = {
                                                {"m416","M416","LootShowM416"},{"aug","AUG","LootShowAUG"},
                                                {"akm","AKM","LootShowAKM"},{"ak47","AKM","LootShowAKM"},
                                                {"m24","M24","LootShowM24"},{"ump","UMP","LootShowUMP"},
                                                {"dbs","DBS","LootShowDBS"},{"s12k","S12K","LootShowS12K"},{"s12","S12K","LootShowS12K"},
                                                {"vest","VEST3","LootShowVest3"},{"armor","VEST3","LootShowVest3"},
                                                {"helmet","HELM3","LootShowHelmet3"},{"bag","BAG3","LootShowBag3"},{"backpack","BAG3","LootShowBag3"},
                                            }
                                            if all then
                                                local n = 0
                                                for _, act in pairs(all) do
                                                    if n > 70 then break end
                                                    if act and slua.isValid(act) then
                                                        local nm = string.lower(tostring(act))
                                                        pcall(function()
                                                            if act.GetName then nm = nm .. string.lower(tostring(act:GetName())) end
                                                            if act.ItemID then nm = nm .. tostring(act.ItemID) end
                                                            if act.WeaponID then nm = nm .. tostring(act.WeaponID) end
                                                        end)
                                                        for _, kw in ipairs(kws) do
                                                            if string.find(nm, kw[1], 1, true) and cfg[kw[3]] == true then
                                                                items[#items+1] = {act=act, label=kw[2]}
                                                                n = n + 1
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            _G.CachedLootItems = items
                                        end
                                        if _G.CachedLootItems then
                                            for _, it in ipairs(_G.CachedLootItems) do
                                                MagooDrawLabel(it.act, it.label, 50, {R=1,G=0.85,B=0.2,A=1})
                                            end
                                        end
                                    end)
                                end
                                function _G.TickVehicleESP()
                                    local cfg = _G.GTLMODConfig
                                    if not cfg or cfg.VehicleEnabled ~= true then return end
                                    pcall(function()
                                        if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                                        if not _G.CachedActorClass_ForVehicle then
                                            pcall(function() _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end)
                                        end
                                        if not _G.CachedActorClass_ForVehicle then return end
                                        if not _G.CachedVehicleArray then
                                            _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle)
                                        end
                                        local ui_util = require("client.common.ui_util")
                                        local gi = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
                                        if not gi then return end
                                        local now = os.clock()
                                        if not _G.LastVehicleScanTime or (now - _G.LastVehicleScanTime) > 0.9 then
                                            _G.LastVehicleScanTime = now
                                            local all = _G.CachedGameplayStatics.GetAllActorsOfClass(gi, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)
                                            local active = {}
                                            if all then
                                                for _, veh in pairs(all) do
                                                    if slua.isValid(veh) and not veh.bHidden then
                                                        local vn = ""
                                                        pcall(function()
                                                            if type(veh.GetVehicleName)=="function" then vn = tostring(veh:GetVehicleName()) end
                                                            vn = vn .. tostring(veh)
                                                        end)
                                                        local low = string.lower(vn)
                                                        local disp = "Vehicle"
                                                        if string.find(low,"uaz",1,true) then disp="UAZ"
                                                        elseif string.find(low,"dacia",1,true) then disp="Dacia"
                                                        elseif string.find(low,"buggy",1,true) then disp="Buggy"
                                                        elseif string.find(low,"mirado",1,true) then disp="Mirado"
                                                        elseif string.find(low,"coupe",1,true) then disp="Coupe"
                                                        elseif string.find(low,"motor",1,true) or string.find(low,"bike",1,true) or string.find(low,"scooter",1,true) then disp="Motor"
                                                        end
                                                        active[#active+1] = {act=veh, name=disp}
                                                    end
                                                end
                                            end
                                            _G.CachedVehicles = active
                                        end
                                        if _G.CachedVehicles then
                                            for _, it in ipairs(_G.CachedVehicles) do
                                                local show = false
                                                if it.name=="Dacia" then show = cfg.VehicleShowDacia ~= false
                                                elseif it.name=="UAZ" then show = cfg.VehicleShowUAZ ~= false
                                                elseif it.name=="Buggy" then show = cfg.VehicleShowBuggy ~= false
                                                elseif it.name=="Coupe" then show = cfg.VehicleShowCoupe ~= false
                                                elseif it.name=="Mirado" then show = cfg.VehicleShowMirado ~= false
                                                elseif it.name=="Motor" then show = cfg.VehicleShowMotorcycle ~= false
                                                else show = cfg.VehicleShowOther ~= false end
                                                if show then MagooDrawLabel(it.act, it.name, 120, {R=0.3,G=0.9,B=1,A=1}) end
                                            end
                                        end
                                    end)
                                end
                            end
                            local function LootESPLoop()
                                local on = _G.GTLMODConfig and _G.GTLMODConfig.EspLoot == true
                                if ticker and ticker.AddTimerOnce then
                                    ticker.AddTimerOnce(on and 0.70 or 3.0, LootESPLoop)
                                end
                            end
                            ticker.AddTimerOnce(2.0, LootESPLoop)

                            local function VehicleESPLoop()
                                local on = _G.GTLMODConfig and _G.GTLMODConfig.VehicleEnabled == true
                                if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(on and 1.0 or 4.0, VehicleESPLoop) end
                            end
                            ticker.AddTimerOnce(2.2, VehicleESPLoop)
                            pcall(function()
                                if _G.GTLMODConfig and _G.GTLMODConfig.UnlockFPS == true and _G.ApplyTargetFPS then
                                    _G.ApplyTargetFPS(165)
                                end
                            end)
                            pcall(function()
                                if _G.GTLMODConfig and _G.GTLMODConfig.BlackSky and _G.ApplyBlackSky then
                                    _G.ApplyBlackSky(true)
                                end
                            end)

                            local function WallhackWatchdog()
                                pcall(function()
                                    if _G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart then
                                        if not (_G.NewWallhack and _G.NewWallhack.Active and _G.NewWallhack.WH_TIMER) then
                                            if _G.StartNewWallhack then _G.StartNewWallhack() end
                                        else
                                            if _G.NewWallhack then _G.NewWallhack.PROCESSED_PAWNS = {} end
                                            if _G.RefreshWallhackColors then _G.RefreshWallhackColors() end
                                        end
                                    end
                                end)
                                local whOn = _G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart == true
                                if ticker and ticker.AddTimerOnce then
                                    ticker.AddTimerOnce(whOn and 4.0 or 8.0, WallhackWatchdog)
                                end
                            end
                            ticker.AddTimerOnce(5.0, WallhackWatchdog)
                        end
                        ticker.AddTimerOnce(0.5, function()
                            if _G.InitAllModSystems then pcall(_G.InitAllModSystems) end
                            if _G.EnsureModFeaturesRunning then pcall(_G.EnsureModFeaturesRunning) end
                        end)
                        ticker.AddTimerOnce(1.2, function()
                            if type(ShowRulesOnce) == "function" then
                                pcall(ShowRulesOnce, nil)
                            elseif type(_G.ShowRulesOnce) == "function" then
                                pcall(_G.ShowRulesOnce, nil)
                            end
                        end)
                    end
                end)
                print("[MAGOO] Authenticated runtime started")
            end
            pcall(function()
                if _G._MAGOO_LOGIN_BOOTSTRAPPED then return end
                _G._MAGOO_LOGIN_BOOTSTRAPPED = true
                local tk = GetTicker()
                local function boot()
                    if not _G.LoginSystem or not _G.LoginSystem.Start then return end
                    _G.LoginSystem.Start(nil, function()
                        isExpired = false
                        _G._LICENSE_OK = true
                        if type(StartAuthenticatedRuntime) == "function" then
                            StartAuthenticatedRuntime()
                        elseif type(_G.StartAuthenticatedRuntime) == "function" then
                            _G.StartAuthenticatedRuntime()
                        end
                    end)
                    if _G._LICENSE_OK == true then
                        isExpired = false
                        pcall(function()
                            if type(_G.StartAuthenticatedRuntime) == "function" then
                                _G.StartAuthenticatedRuntime()
                            end
                        end)
                    end
                    pcall(function()
                        local tk = GetTicker and GetTicker() or nil
                        if not tk then
                            local ok, t = pcall(require, "common.time_ticker")
                            if ok then tk = t end
                        end
                        if tk and tk.AddTimerOnce then
                            tk.AddTimerOnce(5.0, function()
                                if _G._LICENSE_OK == true then return end
                                pcall(function()
                                    if _G.LoginSystem and _G.LoginSystem.Start then
                                        _G.LoginSystem.Start(nil, nil)
                                    end
                                end)
                            end)
                        end
                    end)
                end
                if tk and tk.AddTimerOnce then
                    tk.AddTimerOnce(8.0, boot)
                    tk.AddTimerOnce(14.0, function()
                        if not _G._LICENSE_OK then pcall(boot) end
                    end)
                    tk.AddTimerOnce(22.0, function()
                        if not _G._LICENSE_OK then pcall(boot) end
                    end)
                    tk.AddTimerOnce(16.0, function()
                        if _G._LICENSE_OK and not _G._MAGOO_FEATURE_TICKERS_STARTED then
                            pcall(function() _G.StartAuthenticatedRuntime() end)
                        end
                    end)
                    tk.AddTimerOnce(28.0, function()
                        if _G._LICENSE_OK and not _G._MAGOO_FEATURE_TICKERS_STARTED then
                            pcall(function() _G.StartAuthenticatedRuntime() end)
                        end
                    end)
                else
                end
            end)
            pcall(function()
                local tk = require("common.time_ticker")
                if not (tk and tk.AddTimerOnce) then return end
                tk.AddTimerOnce(10.0, function()
                    pcall(function()
                        if _G._LICENSE_OK == true then
                            if _G.StartAuthenticatedRuntime then _G.StartAuthenticatedRuntime() end
                            return
                        end
                        if _G.LoginSystem and _G.LoginSystem.Start then
                            _G.LoginSystem.Start(nil, function()
                                if _G.StartAuthenticatedRuntime then _G.StartAuthenticatedRuntime() end
                            end)
                        end
                    end)
                end)
                tk.AddTimerOnce(18.0, function()
                    pcall(function()
                        if _G._LICENSE_OK == true and _G.StartAuthenticatedRuntime then
                            _G.StartAuthenticatedRuntime()
                        end
                        if _G.InitModMenuTab then _G.InitModMenuTab() end
                    end)
                end)
                tk.AddTimerOnce(26.0, function()
                    pcall(function()
                        if _G._LICENSE_OK == true then
                            if _G.StartAuthenticatedRuntime then _G.StartAuthenticatedRuntime() end
                            if _G.InitModMenuTab then _G.InitModMenuTab() end
                            return
                        end
                        if _G.LoginSystem and _G.LoginSystem.Start then
                            _G.LoginSystem.Start(nil, function()
                                if _G.StartAuthenticatedRuntime then _G.StartAuthenticatedRuntime() end
                            end)
                        end
                    end)
                end)
            end)
            print("[MAGOO] BR core embedded in file_util — ready")
        end, onError)
        if ok then
            print("[MAGOO] file_util mod core loaded OK")
        else
            print("[MAGOO] file_util mod core FAILED — will retry")
        end
    end
    local function schedule(delay)
        local ok, tk = pcall(require, "common.time_ticker")
        if ok and tk and tk.AddTimerOnce then
            tk.AddTimerOnce(delay, function()
                if _G._MAGOO_FILEUTIL_MOD_LOADED then return end
                loadMagooCore()
                if not _G._MAGOO_FILEUTIL_MOD_LOADED then
                    local n = 0
                    local function retry()
                        n = n + 1
                        if _G._MAGOO_FILEUTIL_MOD_LOADED or n > 8 then return end
                        loadMagooCore()
                        local ok2, tk2 = pcall(require, "common.time_ticker")
                        if ok2 and tk2 and tk2.AddTimerOnce then
                            tk2.AddTimerOnce(3.0, retry)
                        end
                    end
                    tk.AddTimerOnce(3.0, retry)
                end
            end)
            return true
        end
        return false
    end
    if not schedule(5.0) then
        local polls = 0
        local function poll()
            polls = polls + 1
            if schedule(1.0) then return end
            if polls < 30 then
                pcall(function()
                    local ok, tk = pcall(require, "common.time_ticker")
                    if ok and tk and tk.AddTimerOnce then
                        schedule(1.0)
                    end
                end)
            end
        end
        pcall(function()
            local ok, tk = pcall(require, "common.time_ticker")
            if ok and tk and tk.AddTimerOnce then
                tk.AddTimerOnce(5.0, poll)
            end
        end)
    end
end)
pcall(function()
pcall(function()
    local function _sv(w)
        local ok, v = pcall(function() return w and slua.isValid(w) end)
        return ok and v
    end
    if _G.SodaLite_TopPillContainer and _sv(_G.SodaLite_TopPillContainer) then
        _G.SodaLite_TopPillContainer:RemoveFromParent()
        _G.SodaLite_TopPillContainer = nil
    end
    if _G.SodaLite_FloatContainer and _sv(_G.SodaLite_FloatContainer) then
        _G.SodaLite_FloatContainer:RemoveFromParent()
        _G.SodaLite_FloatContainer = nil
    end
    if _G.SodaLite_BgPanel and _sv(_G.SodaLite_BgPanel) then
        _G.SodaLite_BgPanel:RemoveFromParent()
        _G.SodaLite_BgPanel = nil
    end
end)
local function FLinearColor(r, g, b, a)
    local col = { R = r or 1, G = g or 1, B = b or 1, A = a or 1 }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end
local function FSlateColor(color)
    local ok, SC = pcall(import, "SlateColor")
    if ok and SC then return SC(color) end
    return color
end
local function FVector2D(x, y)
    local vec = { X = x or 0, Y = y or 0 }
    local ok, V = pcall(import, "Vector2D")
    if ok and V then return V(x or 0, y or 0) end
    return vec
end
local function GetSlateVis(visName)
    if UEnums and UEnums.ESlateVisibility and UEnums.ESlateVisibility[visName] ~= nil then
        return UEnums.ESlateVisibility[visName]
    end
    local ok, ue = pcall(import, "UEnums")
    if ok and ue and ue.ESlateVisibility and ue.ESlateVisibility[visName] ~= nil then
        return ue.ESlateVisibility[visName]
    end
    local map = { Visible = 0, Collapsed = 1, Hidden = 2, HitTestInvisible = 3, SelfHitTestInvisible = 4 }
    return map[visName] or 0
end
local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        return ok and v
    end
    if Game and Game.IsValid then
        local ok, v = pcall(Game.IsValid, Game, obj)
        return ok and v
    end
    return true
end
local function SetVis(widget, visName)
    if not IsValid(widget) then return end
    pcall(function() widget:SetWidgetVisibility(GetSlateVis(visName)) end)
end
local C = {
    WindowBg        = FLinearColor(0.06, 0.07, 0.09, 0.58),
    Outline         = FLinearColor(1.0, 1.0, 1.0, 0.14),
    Shadow          = FLinearColor(0.0, 0.0, 0.0, 0.35),
    SidebarBg       = FLinearColor(0.08, 0.09, 0.12, 0.55),
    SidebarActiveBg = FLinearColor(0.45, 0.78, 0.68, 0.22),
    IconUser        = FLinearColor(0.40, 0.70, 1.00, 1.0),
    IconMain        = FLinearColor(1.00, 0.85, 0.25, 1.0),
    IconESP         = FLinearColor(0.35, 1.00, 0.75, 1.0),
    IconAim         = FLinearColor(1.00, 0.78, 0.15, 1.0),
    IconMem         = FLinearColor(0.65, 0.55, 1.00, 1.0),
    IconSet         = FLinearColor(0.70, 0.72, 0.76, 1.0),
    TextDark = FLinearColor(0.98, 0.98, 1.0, 1.0),
    TextActiveESP   = FLinearColor(0.52, 0.86, 0.74, 1.0),
    TextUser        = FLinearColor(0.88, 0.90, 0.94, 0.92),
    TextTitle = FLinearColor(1.0, 1.0, 1.0, 1.0),
    TextCategory = FLinearColor(0.92, 0.93, 0.95, 1.0),
    CategorySquare  = FLinearColor(0.50, 0.82, 0.72, 1.0),
    DividerTop      = FLinearColor(1.0, 1.0, 1.0, 0.18),
    DividerRow      = FLinearColor(1.0, 1.0, 1.0, 0.10),
    ToggleOn        = FLinearColor(0.50, 0.82, 0.72, 1.0),
    ToggleOff       = FLinearColor(0.28, 0.30, 0.34, 0.85),
    KnobWhite       = FLinearColor(1.0, 1.0, 1.0, 1.0),
    CloseBtnBg      = FLinearColor(0.12, 0.13, 0.16, 0.70),
    CloseCross      = FLinearColor(0.95, 0.40, 0.38, 1.0),
    TopPillBg       = FLinearColor(0.07, 0.08, 0.11, 0.55),
    TopPillOutline  = FLinearColor(1.0, 1.0, 1.0, 0.16),
    TopPillShadow   = FLinearColor(0.0, 0.0, 0.0, 0.28),
    TopPillClock    = FLinearColor(1.0, 1.0, 1.0, 0.98),
    TopPillTitle    = FLinearColor(0.52, 0.86, 0.74, 1.0),
    TopPillStatus   = FLinearColor(1.0, 1.0, 1.0, 0.92),
    TopPillDiv      = FLinearColor(1.0, 1.0, 1.0, 0.55),
    IndicatorWhite  = FLinearColor(1.0, 1.0, 1.0, 0.90),
    Transparent     = FLinearColor(0.0, 0.0, 0.0, 0.0),
}
_G.GTLMODConfig = _G.GTLMODConfig or {}
local defaultConfig = {
    EspVip = false, EspVipPro = false, EspDistance = false, EspName = false, EspRadar = false,
    Esp5 = false, Esp6 = false, Esp7 = false, Esp8 = false, EspAntenna = false,
    EspItem_Master = false, EspItem_AR = true, EspItem_Sniper = true, EspItem_SMG = true,
    EspItem_Shotgun = true, EspItem_LMG = true, EspItem_Pistol = true, EspItem_Scope = true,
    EspItem_Med = true, EspItem_Grenade = true, EspItem_Special = false,
    EspModelName = false, EspShowDistance = false, EspShowHealthBar = false, EspTeamColorBox = false,
    EspBox = false, EspLine = false, EspLineColor = 6, CounterEnabled = false,
    EspWeaponIcon = false, EspActiveBom = false,
    AimTouchEnable = false, ForceAimbot = false, AimTouchIgKnock = true, AimTouchIgBot = true, AimTouchVisCheck = true,
    PrivSmallCrosshair = false,
    WallhackSmart = false, IpadView = false, CustomHRecoil = false, CustomVRecoil = false,
    CustomAimbot = false, CustomAimbotClose = false, LessShake = false, Accuracy = false, GodMode = false,
    BlackSky = false, RemoveGrass = false, RemoveFog = false,
    PotatoGraphics = false, FPSStabilizer = false, CleaningSpace = false, UnlockFPS = false, TargetFPS = 165,
    -- skins removed
}
for k, v in pairs(defaultConfig) do
    if _G.GTLMODConfig[k] == nil then _G.GTLMODConfig[k] = v end
end
if _G.GTLMODConfig.EspBox == nil then
    _G.GTLMODConfig.EspBox = _G.GTLMODConfig.Esp5 == true
end
_G.GTLMODConfig.EspBox = _G.GTLMODConfig.EspBox == true
_G.GTLMODConfig.Esp5 = _G.GTLMODConfig.EspBox
_G.GTLMODConfig.EspV2Enabled = _G.GTLMODConfig.EspBox
_G.GTLMODState = _G.GTLMODState or { CustomTextData = {} }
if not _G.GTLMODState.CustomTextData then _G.GTLMODState.CustomTextData = {} end
_G.GTLMODState.CustomTextData.IpadViewFOV = _G.GTLMODState.CustomTextData.IpadViewFOV or 120
local function ScheduleFeatureRuntimeSync(configKey)
    if _G._MAGOO_FEATURE_SYNC_PENDING then return end
    _G._MAGOO_FEATURE_SYNC_PENDING = true
    local function run()
        _G._MAGOO_FEATURE_SYNC_PENDING = false
        if configKey == "EspBox" or configKey == "Esp5"
            or configKey == "EspLine" or configKey == "CounterEnabled" then
            if type(_G.ClearVisionV2Sync) == "function" then
                pcall(_G.ClearVisionV2Sync)
            end
        end
        if type(_G.EnsureModFeaturesRunning) == "function" then
            pcall(_G.EnsureModFeaturesRunning)
        end
    end
    pcall(function()
        local tk = package.loaded["common.time_ticker"] or require("common.time_ticker")
        if tk and tk.AddTimerOnce then
            tk.AddTimerOnce(0.01, run)
        else
            run()
        end
    end)
end
local function UpdateFeature(configKey, isEnabled)
    _G.GTLMODConfig[configKey] = (isEnabled == true)
    if configKey == "EspBox" or configKey == "Esp5" then
        local boxEnabled = isEnabled == true
        _G.GTLMODConfig.EspBox = boxEnabled
        _G.GTLMODConfig.Esp5 = boxEnabled
        _G.GTLMODConfig.Box = boxEnabled
        _G.GTLMODConfig.EspV2Enabled = boxEnabled
        if not isEnabled and _G.ClearAllBoxESP then pcall(_G.ClearAllBoxESP) end
    elseif configKey == "EspLine" then
        _G.GTLMODConfig.Line = isEnabled
        _G.GTLMODConfig.EspLine = isEnabled and true or false
        _G.GTLMODConfig.EspV2SnapLine = isEnabled and true or false
        if _G.LexusConfig then _G.LexusConfig.Esp9_Line = isEnabled and true or false end
    elseif configKey == "CounterEnabled" then
        _G.GTLMODConfig.CounterEnabled = isEnabled and true or false
        if not isEnabled then
            pcall(function()
                if _G.RedBoxOverlay and _G.RedBoxOverlay.Stop then pcall(_G.RedBoxOverlay.Stop) end
                if _G.RJCounter and _G.RJCounter.SetEnabled then pcall(_G.RJCounter.SetEnabled, false) end
            end)
        end
    elseif configKey == "EspRadar" then
        _G.GTLMODConfig.EspRadar = isEnabled and true or false
        if isEnabled then
            pcall(function() if _G.ClearAllRadarMarks then _G.ClearAllRadarMarks() end end)
            pcall(function() if _G.Tick_RadarESP then _G.Tick_RadarESP() end end)
            pcall(function()
                if _G.PlayerMapMarker then
                    if _G.PlayerMapMarker.EnsureRunning then _G.PlayerMapMarker.EnsureRunning()
                    elseif _G.PlayerMapMarker.Start then _G.PlayerMapMarker.Start() end
                end
            end)
            pcall(function()
                local tk = require("common.time_ticker")
                if tk and tk.AddTimerOnce then
                    for _, d in ipairs({0.2, 0.8, 1.5}) do
                        tk.AddTimerOnce(d, function()
                            if _G.GTLMODConfig and _G.GTLMODConfig.EspRadar and _G.Tick_RadarESP then
                                pcall(_G.Tick_RadarESP)
                            end
                        end)
                    end
                end
            end)
        else
            pcall(function() if _G.ClearAllRadarMarks then _G.ClearAllRadarMarks() end end)
        end
    elseif configKey == "EspModelName" then
        _G.GTLMODConfig.EspName = isEnabled
        _G.GTLMODConfig.EspModelName = isEnabled
        _G.GTLMODConfig.EspDistance = isEnabled
        _G.GTLMODConfig.EspShowDistance = isEnabled
        _G.GTLMODConfig.EspShowHealthBar = isEnabled
        _G.GTLMODConfig.EspTeamColorBox = isEnabled
        _G.GTLMODConfig.EspVipPro = isEnabled
        _G.GTLMODConfig.EspHealth = isEnabled
    elseif configKey == "EspVipPro" then
        _G.GTLMODConfig.EspShowHealthBar = isEnabled
        _G.GTLMODConfig.EspHealth = isEnabled
    elseif configKey == "AimTouchEnable" then
        _G.GTLMODConfig.ForceAimbot = isEnabled
        _G._ForceAimbotWanted = isEnabled
    elseif configKey == "ForceAimbot" then
        _G.GTLMODConfig.AimTouchEnable = isEnabled
        _G._ForceAimbotWanted = isEnabled
        if _G.SaveModSettings then pcall(_G.SaveModSettings) end
    elseif configKey == "ForceAimbotScope" then
        _G.GTLMODConfig.ForceAimbotScope = isEnabled and true or false
    elseif configKey == "EspWeaponIcon" then
        -- fully independent of AUTO SETUP (EspBox)
        local boxWasOn = (_G.GTLMODConfig.EspBox == true) or (_G.GTLMODConfig.EspV2Enabled == true) or (_G.GTLMODConfig.Esp5 == true)
        _G.GTLMODConfig.EspWeaponIcon = isEnabled and true or false
        _G.LexusConfig = _G.LexusConfig or {}
        _G.LexusConfig.Esp9_Weapon = isEnabled and true or false
        if boxWasOn then
            _G.GTLMODConfig.EspBox = true
            _G.GTLMODConfig.Esp5 = true
            _G.GTLMODConfig.EspV2Enabled = true
            _G.GTLMODConfig.Box = true
        end
        if isEnabled then
            _G.LexusConfig.EspLoai9 = true
            pcall(function()
                if _G.PlayerMapMarker then
                    if _G.PlayerMapMarker.EnsureRunning then pcall(_G.PlayerMapMarker.EnsureRunning)
                    elseif _G.PlayerMapMarker.Start and not _G.PlayerMapMarker.bActive then pcall(_G.PlayerMapMarker.Start) end
                end
            end)
        end
        if boxWasOn then
            pcall(function()
                if type(_G.ClearVisionV2Start) == "function" then _G.ClearVisionV2Start() end
                if type(_G.ClearVisionV2Sync) == "function" then _G.ClearVisionV2Sync() end
            end)
        end
        if _G.SaveModSettings then pcall(_G.SaveModSettings) end
        return
    elseif configKey == "WallhackSmart" then
        if isEnabled then
            if _G.RefreshWallhackColors then pcall(_G.RefreshWallhackColors) end
            if _G.StartNewWallhack then pcall(_G.StartNewWallhack) end
        else
            if _G.StopNewWallhack then
                pcall(_G.StopNewWallhack)
                pcall(function()
                    local tk = require("common.time_ticker")
                    if tk and tk.AddTimerOnce then
                        tk.AddTimerOnce(0.15, function()
                            if not (_G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart) then
                                pcall(function() if _G.StopNewWallhack then _G.StopNewWallhack() end end)
                            end
                        end)
                        tk.AddTimerOnce(0.50, function()
                            if not (_G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart) then
                                pcall(function() if _G.StopNewWallhack then _G.StopNewWallhack() end end)
                            end
                        end)
                        tk.AddTimerOnce(1.20, function()
                            if not (_G.GTLMODConfig and _G.GTLMODConfig.WallhackSmart) then
                                pcall(function() if _G.StopNewWallhack then _G.StopNewWallhack() end end)
                            end
                        end)
                    end
                end)
            end
        end
    elseif configKey == "BlackSky" then
        if _G.ApplyBlackSky then pcall(_G.ApplyBlackSky, isEnabled) end
    elseif configKey == "IpadView" then
        if _G.GTLMODState and _G.GTLMODState.CustomTextData then
            _G.GTLMODState.CustomTextData.IpadViewFOV = isEnabled and 120 or 90
        end
    elseif configKey == "PotatoGraphics" then
        if _G.ApplyPotatoGraphics then pcall(_G.ApplyPotatoGraphics, isEnabled) end
    elseif configKey == "FPSStabilizer" then
        if _G.ApplyFPSStabilizer then pcall(_G.ApplyFPSStabilizer, isEnabled) end
    elseif configKey == "CleaningSpace" then
        _G.GTLMODConfig.RemoveGrass = isEnabled
        if _G.ApplyCleaningSpace then pcall(_G.ApplyCleaningSpace, isEnabled) end
    elseif configKey == "EspLoot" then
        _G.GTLMODConfig.EspLoot = isEnabled and true or false
        _G.GTLMODConfig.EspItem_Master = isEnabled and true or false
        if isEnabled then
            _G.GTLMODConfig.EspItem_AR = true
            _G.GTLMODConfig.EspItem_Sniper = true
            _G.GTLMODConfig.EspItem_SMG = true
            _G.GTLMODConfig.EspItem_Shotgun = true
            _G.GTLMODConfig.EspItem_LMG = true
            _G.GTLMODConfig.EspItem_Scope = true
            _G.GTLMODConfig.EspItem_Med = true
            _G.GTLMODConfig.EspItem_Grenade = true
            pcall(function()
                if _G.RunItemESPLite then _G.RunItemESPLite() end
                if _G.RunOptimizedItemAndVehicleESP then
                    local pc = nil
                    pcall(function() pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() end)
                    _G.RunOptimizedItemAndVehicleESP(pc)
                end
            end)
        else
            pcall(function() if _G.ClearAllItemESPGlow then _G.ClearAllItemESPGlow() end end)
        end
    elseif configKey == "ModSkin" or configKey == "SkinDeadBox" or configKey == "SkinPet" or configKey == "SkinXSuit" then
        -- skin system removed; keep flags false
        _G.GTLMODConfig.ModSkin = false
        _G.GTLMODConfig.SkinDeadBox = false
        _G.GTLMODConfig.SkinPet = false
        _G.GTLMODConfig.SkinXSuit = false
        if _G.LexusConfig then _G.LexusConfig.ModSkin = false end
    elseif configKey == "EspRadar" then
        if isEnabled then
            pcall(function() if InitScreenMarkSystem then InitScreenMarkSystem() end end)
        else
            pcall(function() if _G.ClearAllRadarMarks then _G.ClearAllRadarMarks() end end)
        end
    elseif configKey == "UnlockFPS" then
        _G.GTLMODConfig.TargetFPS = isEnabled and 165 or 60
        if _G.GTLMODState then _G.GTLMODState.GraphicsUnlocked = false end
        if isEnabled and _G.ApplyTargetFPS then
            pcall(_G.ApplyTargetFPS, 165)
        end
    end
    if configKey == "EspRadar" then
        if _G.EnsureModFeaturesRunning then
            pcall(_G.EnsureModFeaturesRunning)
        end
    else
        ScheduleFeatureRuntimeSync(configKey)
    end
end
local MENU_W, MENU_H        = 640, 411
local SIDEBAR_X, SIDEBAR_Y  = 10, 8
local SIDEBAR_W, SIDEBAR_H  = 83, 396
local INDICATOR_W           = 226
local INDICATOR_H           = 5
local currentTab = "DEAD_EYE"
local bgPanel, bgSlot, floatContainer, floatSlot, topPillContainer, topPillSlot = nil, nil, nil, nil, nil, nil
local sidebarContainer, contentContainer, parentCanvas, isMenuOpen, clockTextBlock = nil, nil, nil, false, nil
function GetCanvas()
    local canvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI()
        if MainUI and IsValid(MainUI) then
            if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
                canvas = MainUI.CanvasPanel_0
            elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
                canvas = MainUI.CanvasPanel_42
            end
        end
    end)
    if not canvas then
        pcall(function()
            local hud = require("game_frontend_hud")
            local MainUI = hud and hud.GetMainControlBaseUI and hud.GetMainControlBaseUI()
            if MainUI and IsValid(MainUI) then
                if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
                    canvas = MainUI.CanvasPanel_0
                elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
                    canvas = MainUI.CanvasPanel_42
                end
            end
        end)
    end
    if canvas and IsValid(canvas) then
        parentCanvas = canvas
    elseif not IsValid(parentCanvas) then
        parentCanvas = nil
    end
    return parentCanvas
end
local function GetViewport()
    local vpW, vpH = 1280, 720
    local found = false
    local c = parentCanvas
    if not (c and IsValid(c)) then
        pcall(function() c = GetCanvas() end)
    end
    if c and IsValid(c) then
        pcall(function()
            local cg = c:GetCachedGeometry()
            if cg then
                local sz = nil
                if cg.GetLocalSize then
                    sz = cg:GetLocalSize()
                end
                if not sz then
                    local SBL = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
                    if SBL and SBL.GetLocalSize then
                        sz = SBL.GetLocalSize(cg)
                    end
                end
                if sz and sz.X and sz.X > 250 and sz.Y and sz.Y > 180 then
                    vpW = sz.X
                    vpH = sz.Y
                    found = true
                end
            end
        end)
    end
    if not found then
        pcall(function()
            local WLL = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
            local PC = nil
            pcall(function()
                local UIManager = package.loaded["GameLua.GameCore.Module.UIManager"]
                if UIManager and UIManager.GetPlayerController then
                    PC = UIManager.GetPlayerController()
                end
            end)
            local sz = nil
            if WLL and WLL.GetViewportSize then
                sz = WLL.GetViewportSize(PC)
            end
            if not sz then
                local ui_util = require("client.common.ui_util")
                if ui_util and ui_util.GetViewportSize then
                    sz = ui_util.GetViewportSize()
                end
            end
            if sz and sz.X and sz.X > 50 and sz.Y and sz.Y > 50 then
                local scale = 1.0
                if WLL and WLL.GetViewportScale then
                    pcall(function()
                        local s = WLL.GetViewportScale(PC)
                        if s and type(s) == "number" and s > 0 then
                            scale = s
                        end
                    end)
                end
                if scale > 0 and scale ~= 1.0 then
                    vpW = sz.X / scale
                    vpH = sz.Y / scale
                else
                    vpW = sz.X
                    vpH = sz.Y
                end
                found = true
            end
        end)
    end
    if vpW < 400 then vpW = 1280 end
    if vpH < 300 then vpH = 720 end
    return vpW, vpH
end
local function GetMenuScale(vpW, vpH)
    local maxW = vpW * 0.92
    local maxH = vpH * 0.88
    local s = 1.0
    if MENU_W > maxW or MENU_H > maxH then
        s = math.min(maxW / MENU_W, maxH / MENU_H)
    end
    return math.max(0.68, math.min(1.0, s))
end
local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then
            obj = CGame:NewObjectFromPath(path, parent)
        end
    end)
    return obj
end
local function Layer(parent, x, y, w, h, color, zOrder)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function() b:SetBrushColor(color) end)
        SetVis(b, "SelfHitTestInvisible")
        local slot = parent:AddChildToCanvas(b)
        if slot then
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 0)
        end
    end
    return b
end
local function RoundedPanel(parent, x, y, w, h, r, color, zOrder)
    local container = NewObject("/Script/UMG.CanvasPanel", parent)
    if not IsValid(container) then return nil end
    local cSlot = parent:AddChildToCanvas(container)
    if cSlot then
        cSlot:SetAutoSize(false); cSlot:SetPosition(FVector2D(x, y))
        cSlot:SetSize(FVector2D(w, h)); cSlot:SetZOrder(zOrder or 0)
    end
    SetVis(container, "SelfHitTestInvisible")
    r = math.min(math.floor(r or 12), math.floor(h * 0.5), math.floor(w * 0.5))
    if r < 1 then
        Layer(container, 0, 0, w, h, color, 0)
        return container
    end
    local top_dx = {}
    for i = 0, r - 1 do
        local dy = r - (i + 0.5)
        local dx = math.floor(r - math.sqrt(math.max(0, r * r - dy * dy)) + 0.5)
        top_dx[#top_dx + 1] = dx
    end
    local merged, curDx, curY, curH = {}, top_dx[1], 0, 1
    for i = 2, #top_dx do
        if top_dx[i] == curDx then curH = curH + 1
        else
            merged[#merged + 1] = { dx = curDx, y = curY, h = curH }
            curDx, curY, curH = top_dx[i], i - 1, 1
        end
    end
    merged[#merged + 1] = { dx = curDx, y = curY, h = curH }
    for _, s in ipairs(merged) do Layer(container, s.dx, s.y, w - 2 * s.dx, s.h, color, 0) end
    local midH = h - 2 * r
    if midH > 0 then Layer(container, 0, r, w, midH, color, 0) end
    for _, s in ipairs(merged) do Layer(container, s.dx, h - s.y - s.h, w - 2 * s.dx, s.h, color, 0) end
    return container
end
local function Text(parent, text, x, y, fontSize, color, zOrder, alignX, alignY)
    local tb = NewObject("/Script/UMG.TextBlock", parent)
    if IsValid(tb) then
        pcall(function()
            tb:SetText(tostring(text or ""))
            tb:SetFont({ Size = fontSize or 12, Typeface = "Regular" })
            tb:SetColorAndOpacity(FSlateColor(color or C.TextDark))
        end)
        SetVis(tb, "SelfHitTestInvisible")
        local slot = parent:AddChildToCanvas(tb)
        if slot then
            slot:SetAutoSize(true); slot:SetPosition(FVector2D(x, y))
            slot:SetAlignment(FVector2D(alignX or 0.0, alignY or 0.0)); slot:SetZOrder(zOrder or 1)
        end
    end
    return tb
end
local function MakeBtn(parent, x, y, w, h, zOrder, onClick)
    local btn = NewObject("/Script/UMG.Button", parent)
    if IsValid(btn) then
        pcall(function()
            btn:SetColorAndOpacity(C.Transparent)
            btn:SetBackgroundColor(C.Transparent)
        end)
        SetVis(btn, "Visible")
        local slot = parent:AddChildToCanvas(btn)
        if slot then
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 1000)
        end
        if onClick then
            local lastTrigger = 0
            local function handleTrigger()
                local now = os.clock()
                if (now - lastTrigger) < 0.40 then return end
                lastTrigger = now
                pcall(onClick)
            end
            pcall(function()
                if btn.OnClicked then btn.OnClicked:Add(handleTrigger) end
            end)
        end
    end
    return btn
end
local function DrawToggle(parent, x, y, configKey)
    local tw, th, tr = 46, 26, 13
    local root = NewObject("/Script/UMG.CanvasPanel", parent)
    if not IsValid(root) then return end
    local slot = parent:AddChildToCanvas(root)
    if slot then
        slot:SetAutoSize(false)
        slot:SetPosition(FVector2D(x, y))
        slot:SetSize(FVector2D(tw, th))
        slot:SetZOrder(11)
    end
    SetVis(root, "SelfHitTestInvisible")
    local function redraw(state)
        if not IsValid(root) then return end
        root:ClearChildren()
        local trackColor = state and C.ToggleOn or C.ToggleOff
        RoundedPanel(root, 0, 0, tw, th, tr, trackColor, 12)
        local knobX = state and 24 or 3
        RoundedPanel(root, knobX, 3, 20, 20, 10, C.KnobWhite, 14)
        RoundedPanel(root, knobX + 1, 4, 20, 20, 10, FLinearColor(0, 0, 0, 0.12), 13)
        MakeBtn(root, -6, -6, tw + 12, th + 12, 16, function()
            local newState = not (_G.GTLMODConfig[configKey] and true or false)
            UpdateFeature(configKey, newState)
            if _G.SaveModSettings then pcall(_G.SaveModSettings) end
            if configKey == "ForceAimbot" or configKey == "EspBox" or configKey == "EspWeaponIcon" or configKey == "EspLine" then
                -- full refresh so conditional rows appear
                if type(RenderContent) == "function" then
                    pcall(RenderContent)
                    return
                end
            end
            redraw(newState)
        end)
    end
    redraw(_G.GTLMODConfig[configKey] == true)
end
local function DrawRow(parent, labelText, yPos, configKey)
    Text(parent, labelText, 119, yPos + 12, 14, C.TextDark, 12, 0.0, 0.5)
    DrawToggle(parent, 570, yPos, configKey)
end
local function DrawHouseIcon(parent, ox, oy)
    Layer(parent, ox + 12, oy + 6,  4, 2, C.KnobWhite, 15)
    Layer(parent, ox + 10, oy + 8,  8, 2, C.KnobWhite, 15)
    Layer(parent, ox + 7,  oy + 10, 14, 2, C.KnobWhite, 15)
    Layer(parent, ox + 9,  oy + 12, 10, 9, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 15, 4, 6, C.IconMain, 16)
end
local function DrawEyeIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 9,  12, 2, C.KnobWhite, 15)
    Layer(parent, ox + 5,  oy + 11, 18, 6, C.KnobWhite, 15)
    Layer(parent, ox + 8,  oy + 17, 12, 2, C.KnobWhite, 15)
    Layer(parent, ox + 11, oy + 11, 6, 6, C.IconESP, 16)
    Layer(parent, ox + 13, oy + 13, 2, 2, C.KnobWhite, 17)
end
local function DrawAimIcon(parent, ox, oy)
    Layer(parent, ox + 9,  oy + 6,  10, 2, C.KnobWhite, 15)
    Layer(parent, ox + 9,  oy + 20, 10, 2, C.KnobWhite, 15)
    Layer(parent, ox + 6,  oy + 9,  2, 10, C.KnobWhite, 15)
    Layer(parent, ox + 20, oy + 9,  2, 10, C.KnobWhite, 15)
    Layer(parent, ox + 13, oy + 4,  2, 5, C.KnobWhite, 15)
    Layer(parent, ox + 13, oy + 19, 2, 5, C.KnobWhite, 15)
    Layer(parent, ox + 4,  oy + 13, 5, 2, C.KnobWhite, 15)
    Layer(parent, ox + 19, oy + 13, 5, 2, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 12, 4, 4, C.KnobWhite, 15)
end
local function DrawMemIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 8,  12, 12, C.KnobWhite, 15)
    Layer(parent, ox + 10, oy + 10, 8, 8,   C.IconMem, 16)
    Layer(parent, ox + 12, oy + 12, 4, 4,   C.KnobWhite, 17)
    for _, p in ipairs({10, 16}) do
        Layer(parent, ox + p,  oy + 5,  2, 3, C.KnobWhite, 15)
        Layer(parent, ox + p,  oy + 20, 2, 3, C.KnobWhite, 15)
        Layer(parent, ox + 5,  oy + p,  3, 2, C.KnobWhite, 15)
        Layer(parent, ox + 20, oy + p,  3, 2, C.KnobWhite, 15)
    end
end
local function DrawSetIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 8,  12, 12, C.KnobWhite, 15)
    Layer(parent, ox + 11, oy + 11, 6, 6,   C.IconSet, 16)
    Layer(parent, ox + 12, oy + 5,  4, 3, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 20, 4, 3, C.KnobWhite, 15)
    Layer(parent, ox + 5,  oy + 12, 3, 4, C.KnobWhite, 15)
    Layer(parent, ox + 20, oy + 12, 3, 4, C.KnobWhite, 15)
end
local function SetImageBrush(img, path)
    if not (img and path and path ~= "") then return end
    pcall(function()
        if img.SetBrushFromPath then
            img:SetBrushFromPath(path)
            return
        end
        if img.SetBrushFromSoftPath then
            img:SetBrushFromSoftPath(path)
            return
        end
        local ok, tex = pcall(function()
            return slua.loadObject and slua.loadObject(path) or nil
        end)
        if ok and tex and img.SetBrushFromTexture then
            img:SetBrushFromTexture(tex, true)
        end
    end)
end
local function TabIcon(parent, x, y, size, path, fallbackColor)
    local img = nil
    pcall(function()
        img = NewObject("/Script/UMG.Image", parent)
        if not IsValid(img) then return end
        local slot = parent:AddChildToCanvas(img)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(size, size))
            slot:SetZOrder(12)
        end
        SetImageBrush(img, path)
    end)
    if not IsValid(img) then
        RoundedPanel(parent, x, y, size, size, 8, fallbackColor or C.IconESP, 10)
    else
        RoundedPanel(parent, x - 2, y - 2, size + 4, size + 4, 10, fallbackColor or C.IconESP, 10)
    end
    return img
end
local function RenderSidebar()
    if not IsValid(sidebarContainer) then return end
    sidebarContainer:ClearChildren()
    RoundedPanel(sidebarContainer, 0, 0, SIDEBAR_W, SIDEBAR_H, 20, C.SidebarBg, 1)
    local tabs = {
        { id = "DEAD_EYE", name = "DEAD EYE", y = 8,   h = 70, path = "/Game/UMG/Texture/Lobby_NoAtlas/Corps/Corps_Icon_Battle.Corps_Icon_Battle", col = C.IconESP },
        { id = "FUCK_AIM", name = "FUCK AIM", y = 82,  h = 70, path = "/Game/Arts/UI/TableIcons/ItemIcon/WeaponCoat/Icon_M_WEP_M416_int_M_Coat_256.Icon_M_WEP_M416_int_M_Coat_256", col = C.IconAim },
        { id = "GAME_OPT", name = "GAME OPT", y = 156, h = 70, path = "/Game/UMG/Texture/Lobby_NoAtlas/ESport/ESport_Icon_256.ESport_Icon_256", col = C.IconMem },
        { id = "USER",     name = "User",     y = 230, h = 70, path = "/Game/Arts/UI/TableIcons/ItemIcon/Item/Icon_FriendProgress_256.Icon_FriendProgress_256", col = C.IconUser },
    }
    for _, tab in ipairs(tabs) do
        local isActive = (currentTab == tab.id)
        local tabY = tab.y
        if isActive then
            RoundedPanel(sidebarContainer, 0, tabY, SIDEBAR_W, tab.h, 12, C.SidebarActiveBg, 3)
        end
        local textCol = isActive and C.TextActiveESP or C.TextDark
        TabIcon(sidebarContainer, 26, tabY + 8, 30, tab.path, tab.col)
        Text(sidebarContainer, tab.name, 41.5, tabY + 48, 9, textCol, 12, 0.5, 0.5)
        local targetId = tab.id
        MakeBtn(sidebarContainer, 0, tabY, SIDEBAR_W, tab.h, 100, function()
            if currentTab ~= targetId then
                currentTab = targetId
                _G._MagooContentScroll = 0
                RenderSidebar()
                RenderContent()
            end
        end)
    end
end
_G._MagooMenuExpand = _G._MagooMenuExpand or {}
_G._MagooContentScroll = _G._MagooContentScroll or 0
local function MagooKeyTimeLeft()
    local exp = _G._LICENSE_EXPIRY
    local function tryRead(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local d = f:read("*all"); f:close()
        if d then d = tostring(d):match("^%s*(.-)%s*$") end
        if not d or d == "" then return nil end
        return d
    end
    if not exp or exp == "" then
        local pkgs = {
            "com.pubg.imobile", "com.tencent.ig", "com.pubg.krmobile",
            "com.vng.pubgmobile", "com.rekoo.pubgm", "com.tencent.tmgp.pubgmhd",
        }
        pcall(function()
            local KSL = import("KismetSystemLibrary")
            if KSL and KSL.GetGameBundleId then
                local p = KSL:GetGameBundleId()
                if p then table.insert(pkgs, 1, p) end
            end
        end)
        for _, pkg in ipairs(pkgs) do
            local base = "//storage/emulated/0/Android/data/" .. pkg .. "/files/"
            exp = tryRead(base .. "key_expiry.txt") or exp
            if not exp then
                local raw = tryRead(base .. "keys.txt")
                if raw then exp = raw:match("\n([^\r\n]+)") or exp end
            end
            if exp and exp ~= "" then break end
        end
    end
    if exp then
        exp = tostring(exp):gsub("^%s+", ""):gsub("%s+$", "")
        _G._LICENSE_EXPIRY = exp
    end
    if not exp or exp == "" then
        return nil, false, nil
    end
    local low = exp:lower()
    if low:find("never") or low:find("lifetime") or low:find("permanent")
        or low:find("999") or low == "inf" then
        return 99999999, true, "∞"
    end
    local t = nil
    pcall(function()
        local n = tonumber(exp)
        if n then
            if n > 1e12 then t = math.floor(n / 1000)
            elseif n > 1e9 then t = n
            elseif n > 86400 then t = os.time() + n
            else t = os.time() + n * 86400
            end
        end
        if not t then
            local y, m, d, H, M, S = exp:match("(%d%d%d%d)[%-/](%d%d)[%-/](%d%d)[T%s]?(%d%d)?:?(%d%d)?:?(%d%d)?")
            if y then
                t = os.time({
                    year = tonumber(y), month = tonumber(m), day = tonumber(d),
                    hour = tonumber(H) or 23, min = tonumber(M) or 59, sec = tonumber(S) or 59
                })
            end
        end
        if not t then
            local d, m, y = exp:match("(%d%d)/(%d%d)/(%d%d%d%d)")
            if y then
                t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59 })
            end
        end
        if not t then
            local days = exp:match("(%d+)%s*[dD]")
            if days then t = os.time() + tonumber(days) * 86400 end
        end
    end)
    if not t then
        return nil, false, nil
    end
    local left = t - os.time()
    if left < 0 then left = 0 end
    local isPriv = left >= (7 * 24 * 3600)
    local h = math.floor(left / 3600)
    local mi = math.floor((left % 3600) / 60)
    local s = math.floor(left % 60)
    return left, isPriv, string.format("%d:%02d:%02d", h, mi, s)
end
local function DrawParentRow(parent, labelText, yPos, expandKey)
    local open = _G._MagooMenuExpand[expandKey] == true
    local mark = open and "▼ " or "▶ "
    Text(parent, mark .. labelText, 119, yPos + 12, 13, C.TextCategory, 12, 0.0, 0.5)
    MakeBtn(parent, 110, yPos - 2, 500, 30, 20, function()
        _G._MagooMenuExpand[expandKey] = not open
        RenderContent()
    end)
end
function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()
    _G.GTLMODConfig = _G.GTLMODConfig or {}
    local scroll = tonumber(_G._MagooContentScroll) or 0
    local y = 95 - scroll
    local function gap()
        if y > 50 and y < 380 then
            Layer(contentContainer, 119, y + 34, 493, 1, C.DividerRow, 10)
        end
        y = y + 40
    end
    local function row(label, key)
        if y > 55 and y < 360 then
            DrawRow(contentContainer, label, y, key)
        end
        gap()
    end
    local function header()
    end
    local function drawScrollChrome()
        RoundedPanel(contentContainer, 200, 360, 100, 28, 10, C.SidebarBg, 50)
        Text(contentContainer, "▲ UP", 250, 374, 12, C.TextActiveESP, 55, 0.5, 0.5)
        MakeBtn(contentContainer, 200, 360, 100, 28, 60, function()
            _G._MagooContentScroll = math.max(0, (_G._MagooContentScroll or 0) - 120)
            RenderContent()
        end)
        RoundedPanel(contentContainer, 340, 360, 100, 28, 10, C.SidebarBg, 50)
        Text(contentContainer, "▼ DOWN", 390, 374, 12, C.TextActiveESP, 55, 0.5, 0.5)
        MakeBtn(contentContainer, 340, 360, 100, 28, 60, function()
            _G._MagooContentScroll = (_G._MagooContentScroll or 0) + 120
            RenderContent()
        end)
    end
    if currentTab == "USER" then
        Text(contentContainer, "USER PROFILE", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Account Info", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)
        RoundedPanel(contentContainer, 119, 98, 493, 150, 14, C.SidebarBg, 5)
        RoundedPanel(contentContainer, 139, 115, 46, 46, 23, C.IconUser, 10)
        Text(contentContainer, "A", 162, 138, 20, C.KnobWhite, 12, 0.5, 0.5)
        local pname = _G._MAGOO_PROFILE_NAME
        if not pname or pname == "" then pname = "MAGOO" end
        Text(contentContainer, "User: " .. tostring(pname), 198, 122, 14, C.TextTitle, 12, 0.0, 0.5)
        local st = (_G._LICENSE_OK == true) and "Status: KEY ACTIVE" or "Status: LOGIN REQUIRED"
        Text(contentContainer, st, 198, 145, 12, C.TextActiveESP, 12, 0.0, 0.5)
        local left, isPriv, timeLabel = MagooKeyTimeLeft()
        local daysLeft = nil
        if left and left > 0 then
            daysLeft = math.floor(left / 86400)
        end
        if timeLabel == "∞" then
            Text(contentContainer, "Days left: Lifetime ∞", 198, 168, 14, C.TextActiveESP, 12, 0.0, 0.5)
        elseif daysLeft ~= nil then
            if daysLeft > 0 then
                Text(contentContainer, "Days left: " .. tostring(daysLeft), 198, 168, 14, C.TextActiveESP, 12, 0.0, 0.5)
            else
                local _WC = nil
                pcall(function() local LC = import("LinearColor"); if LC then _WC = LC(1.0, 0.4, 0.2, 1.0) end end)
                Text(contentContainer, "Days left: 0 (expires today)", 198, 168, 14, _WC or C.TextDark, 12, 0.0, 0.5)
            end
        else
            local rawExp = _G._LICENSE_EXPIRY
            if rawExp and rawExp ~= "" then
                Text(contentContainer, "Days left: (see expiry)", 198, 168, 13, C.TextDark, 12, 0.0, 0.5)
                Text(contentContainer, "Expires: " .. tostring(rawExp), 198, 190, 11, C.TextDark, 12, 0.0, 0.5)
            else
                Text(contentContainer, _G._LICENSE_OK and "Days left: Active" or "Days left: —", 198, 168, 13, C.TextDark, 12, 0.0, 0.5)
            end
        end
        if isPriv == true or (daysLeft and daysLeft >= 7) then
            Text(contentContainer, "PRIVATE USER", 365, 300, 22, C.TextActiveESP, 12, 0.5, 0.5)
            Text(contentContainer, "★  PREMIUM ACCESS  ★", 365, 328, 13, C.TextActiveESP, 12, 0.5, 0.5)
        end
    elseif currentTab == "DEAD_EYE" then
        Text(contentContainer, "DEAD EYE♤", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Supervision / ESP", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)
        row("ESP MARK · 360 RADAR", "EspRadar")
        row("AUTO SETUP", "EspBox")
        row("ESP LINES", "EspLine")
        do
            local lineOn = _G.GTLMODConfig and (
                _G.GTLMODConfig.EspLine == true
                or _G.GTLMODConfig.EspLine == 1
                or _G.GTLMODConfig.EspLine == "true"
            )
            if lineOn then
                local colorLabels = {
                    "   Line Color: Black",
                    "   Line Color: White",
                    "   Line Color: Red",
                    "   Line Color: Green",
                    "   Line Color: Blue",
                    "   Line Color: Gold",
                }
                local cidx = tonumber(_G.GTLMODConfig.EspLineColor) or 6
                if cidx < 1 then cidx = 1 end
                if cidx > 6 then cidx = 6 end
                Text(contentContainer, colorLabels[cidx], 119, y + 12, 13, C.TextDark, 12, 0.0, 0.5)
                MakeBtn(contentContainer, 110, y, 520, 32, 20, function()
                    local cur = tonumber(_G.GTLMODConfig.EspLineColor) or 6
                    cur = cur + 1
                    if cur > 6 then cur = 1 end
                    _G.GTLMODConfig.EspLineColor = cur
                    if _G.SaveModSettings then pcall(_G.SaveModSettings) end
                    RenderContent()
                end)
                gap()
            end
        end
        row("PLAYER / BOT COUNTER", "CounterEnabled")
        row("WEAPON ICON", "EspWeaponIcon")
        row("ACTIVE GRENADE WARNING", "EspActiveBom")
        drawScrollChrome()
    elseif currentTab == "FUCK_AIM" then
        Text(contentContainer, "FUCK AIM>", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Aim / Crosshair", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)
        row("FORCE AIMBOT (HIP)", "ForceAimbot")
        local forceOn = _G.GTLMODConfig and (
            _G.GTLMODConfig.ForceAimbot == true
            or _G.GTLMODConfig.ForceAimbot == 1
            or _G.GTLMODConfig.ForceAimbot == "true"
            or _G._ForceAimbotWanted == true
        )
        if forceOn then
            local boneLabels = { "   Target Area: Head", "   Target Area: Chest", "   Target Area: Stomach", "   Target Area: Pelvis" }
            local boneIdx = tonumber(_G.GTLMODConfig.AimbotBone) or 1
            if boneIdx < 1 then boneIdx = 1 end
            if boneIdx > 4 then boneIdx = 4 end
            Text(contentContainer, boneLabels[boneIdx], 119, y + 12, 13, C.TextDark, 12, 0.0, 0.5)
            MakeBtn(contentContainer, 110, y, 520, 32, 20, function()
                local cur = tonumber(_G.GTLMODConfig.AimbotBone) or 1
                cur = cur + 1
                if cur > 4 then cur = 1 end
                _G.GTLMODConfig.AimbotBone = cur
                if _G.SaveModSettings then pcall(_G.SaveModSettings) end
                RenderContent()
            end)
            gap()
            local sm = tonumber(_G.GTLMODConfig.AimbotSmoothness) or 40
            if sm < 5 then sm = 5 end
            if sm > 100 then sm = 100 end
            Text(contentContainer, "   Smoothness: " .. tostring(sm), 119, y + 12, 13, C.TextDark, 12, 0.0, 0.5)
            MakeBtn(contentContainer, 110, y, 520, 32, 20, function()
                local cur = tonumber(_G.GTLMODConfig.AimbotSmoothness) or 40
                cur = cur + 5
                if cur > 100 then cur = 5 end
                _G.GTLMODConfig.AimbotSmoothness = cur
                if _G.SaveModSettings then pcall(_G.SaveModSettings) end
                RenderContent()
            end)
            gap()
        end
        row("VISIBILITY CHECK", "AimTouchVisCheck")
        row("SMALL CROSSHAIR", "PrivSmallCrosshair")
        drawScrollChrome()
    elseif currentTab == "GAME_OPT" then
        Text(contentContainer, "GAME OPTIMIZATION ●", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Performance / Visual", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)
        if y > 55 and y < 360 then DrawParentRow(contentContainer, "LAG / FREEZE", y, "Lag") end
        gap()
        if _G._MagooMenuExpand.Lag then
            row("   Potato Graphics", "PotatoGraphics")
            row("   FPS Stabilizer", "FPSStabilizer")
            row("   Remove Dense Grass", "CleaningSpace")
            row("   165 FPS", "UnlockFPS")
        end
        if y > 55 and y < 360 then DrawParentRow(contentContainer, "iPad View", y, "Ipad") end
        gap()
        if _G._MagooMenuExpand.Ipad then
            row("iPad View", "IpadView")
        end
        if y > 55 and y < 360 then DrawParentRow(contentContainer, "COLOR CUSTOMIZE", y, "Color") end
        gap()
        if _G._MagooMenuExpand.Color then
            row("   WALLHACK Smart", "WallhackSmart")
            if y > 55 and y < 360 then
                Text(contentContainer, "   Wallhack Colors", 119, y + 10, 12, C.TextCategory, 12, 0.0, 0.5)
            end
            y = y + 36
            local presets = {
                { "   GREEN & RED", 3, 0 },
                { "   BLUE & WHITE", 9, 5 },
                { "   YELLOW & PINK", 2, 6 },
            }
            for _, pr in ipairs(presets) do
                if y > 55 and y < 360 then
                    Text(contentContainer, pr[1], 119, y + 12, 13, C.TextDark, 12, 0.0, 0.5)
                    local active = (_G.GTLMODConfig.WallhackSmart == true) and (_G.GTLMODConfig.ColorEnemyWHVis == pr[2] and _G.GTLMODConfig.ColorEnemyWHOcc == pr[3])
                    local col = active and C.ToggleOn or C.ToggleOff
                    RoundedPanel(contentContainer, 570, y + 4, 42, 24, 12, col, 12)
                    local pid, pv, po = pr[1], pr[2], pr[3]
                    MakeBtn(contentContainer, 110, y, 520, 32, 20, function()
                        _G.GTLMODConfig.ColorEnemyWHVis = pv
                        _G.GTLMODConfig.ColorEnemyWHOcc = po
                        _G.GTLMODConfig.ColorBotWHVis = pv
                        _G.GTLMODConfig.ColorBotWHOcc = po
                        if _G.RefreshWallhackColors then pcall(_G.RefreshWallhackColors) end
                        if _G.GTLMODConfig.WallhackSmart and _G.StartNewWallhack then pcall(_G.StartNewWallhack) end
                        RenderContent()
                    end)
                end
                y = y + 40
            end
            row("   BLACK SKY", "BlackSky")
        end
        drawScrollChrome()
    else
        currentTab = "DEAD_EYE"
        RenderContent()
    end
end
local function CreateTopPill(canvas)
    if IsValid(topPillContainer) then return end
    local vpW, _ = GetViewport()
    local pillW, pillH, pr = 363, 38, 19
    local pillX = math.floor((vpW - pillW) * 0.5)
    topPillContainer = NewObject("/Script/UMG.CanvasPanel", canvas)
    topPillSlot = canvas:AddChildToCanvas(topPillContainer)
    if topPillSlot then
        topPillSlot:SetAutoSize(false)
        topPillSlot:SetPosition(FVector2D(pillX, 10))
        topPillSlot:SetSize(FVector2D(pillW, pillH))
        topPillSlot:SetZOrder(10000)
    end
    SetVis(topPillContainer, "SelfHitTestInvisible")
    _G.SodaLite_TopPillContainer = topPillContainer
    RoundedPanel(topPillContainer, 0, 3, pillW, pillH, pr, C.TopPillShadow, 1)
    RoundedPanel(topPillContainer, -1, -1, pillW + 2, pillH + 2, pr + 1, C.TopPillOutline, 2)
    RoundedPanel(topPillContainer, 0, 0, pillW, pillH, pr, C.TopPillBg, 3)
    clockTextBlock = Text(topPillContainer, os.date("%H:%M"), 45, 19, 13, C.TopPillClock, 10, 0.5, 0.5)
    Text(topPillContainer, "|", 88, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)
    Text(topPillContainer, "MAGOO", 160, 19, 13, C.TopPillTitle, 10, 0.5, 0.5)
    Text(topPillContainer, "|", 232, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)
    fpsTextBlock = Text(topPillContainer, "60 FPS", 296, 19, 12, C.TopPillStatus, 10, 0.5, 0.5)
    _G._MagooFpsText = fpsTextBlock
    SetVis(topPillContainer, "Collapsed")
end
local function UpdateLayoutPositions(vpW, vpH)
    if topPillSlot then
        local pillW = 363
        local pillX = math.floor((vpW - pillW) * 0.5)
        pcall(function() topPillSlot:SetPosition(FVector2D(pillX, 10)) end)
    end
    if floatSlot then
        local hitW, hitH = 280, 50
        local fX = math.floor((vpW - hitW) * 0.5)
        local fY = math.max(10, vpH - hitH - 6)
        pcall(function() floatSlot:SetPosition(FVector2D(fX, fY)) end)
    end
    if IsValid(bgPanel) and bgSlot then
        local s = GetMenuScale(vpW, vpH)
        pcall(function()
            bgPanel:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            bgPanel:SetRenderScale(FVector2D(s, s))
        end)
        local posX = math.max(6, math.floor((vpW - MENU_W) * 0.5))
        local posY = math.max(6, math.floor((vpH - MENU_H) * 0.5))
        pcall(function() bgSlot:SetPosition(FVector2D(posX, posY)) end)
    end
end
local function CloseMenu()
    isMenuOpen = false
    pcall(function()
        if IsValid(bgPanel) then
            SetVis(bgPanel, "Collapsed")
            if bgPanel.SetRenderOpacity then bgPanel:SetRenderOpacity(1) end
        end
    end)
    pcall(function()
        if IsValid(topPillContainer) then SetVis(topPillContainer, "Collapsed") end
    end)
    pcall(function()
        if IsValid(floatContainer) then SetVis(floatContainer, "SelfHitTestInvisible") end
    end)
end
local function OpenMenu(canvas)
    isMenuOpen = true
    local c = canvas or parentCanvas or GetCanvas()
    if IsValid(bgPanel) then
        local vpW, vpH = GetViewport()
        UpdateLayoutPositions(vpW, vpH)
        SetVis(bgPanel, "SelfHitTestInvisible")
        pcall(function()
            if bgPanel.SetRenderOpacity then bgPanel:SetRenderOpacity(1) end
        end)
    else
        if c then BuildMenu(c) end
    end
    if IsValid(topPillContainer) then SetVis(topPillContainer, "SelfHitTestInvisible") end
    if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
end
function ToggleMenu(canvas)
    if isMenuOpen then CloseMenu() else OpenMenu(canvas) end
end
function BuildMenu(canvas)
    if IsValid(bgPanel) then
        local vpW, vpH = GetViewport()
        UpdateLayoutPositions(vpW, vpH)
        SetVis(bgPanel, "SelfHitTestInvisible")
        if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
        isMenuOpen = true
        return
    end
    local vpW, vpH = GetViewport()
    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    bgSlot = canvas:AddChildToCanvas(bgPanel)
    local posX = math.max(6, math.floor((vpW - MENU_W) * 0.5))
    local posY = math.max(6, math.floor((vpH - MENU_H) * 0.5))
    if bgSlot then
        bgSlot:SetAutoSize(false)
        bgSlot:SetPosition(FVector2D(posX, posY))
        bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
        bgSlot:SetZOrder(10000)
    end
    SetVis(bgPanel, "SelfHitTestInvisible")
    _G.SodaLite_BgPanel = bgPanel
    local s = GetMenuScale(vpW, vpH)
    pcall(function()
        bgPanel:SetRenderTransformPivot(FVector2D(0.5, 0.5))
        bgPanel:SetRenderScale(FVector2D(s, s))
    end)
    local menuRadius = 25
    RoundedPanel(bgPanel, 4, 4, MENU_W, MENU_H, menuRadius, C.Shadow, 1)
    RoundedPanel(bgPanel, -1, -1, MENU_W + 2, MENU_H + 2, menuRadius + 1, C.Outline, 2)
    RoundedPanel(bgPanel, 0, 0, MENU_W, MENU_H, menuRadius, C.WindowBg, 3)
    sidebarContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local sSlot = bgPanel:AddChildToCanvas(sidebarContainer)
    if sSlot then
        sSlot:SetAutoSize(false)
        sSlot:SetPosition(FVector2D(SIDEBAR_X, SIDEBAR_Y))
        sSlot:SetSize(FVector2D(SIDEBAR_W, SIDEBAR_H))
        sSlot:SetZOrder(50)
    end
    SetVis(sidebarContainer, "SelfHitTestInvisible")
    RenderSidebar()
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    if cSlot then
        cSlot:SetAutoSize(false)
        cSlot:SetPosition(FVector2D(0, 0))
        cSlot:SetSize(FVector2D(MENU_W, MENU_H))
        cSlot:SetZOrder(10)
    end
    SetVis(contentContainer, "SelfHitTestInvisible")
    RenderContent()
    RoundedPanel(bgPanel, 601, 9, 27, 23, 11, C.CloseBtnBg, 9990)
    Text(bgPanel, "✕", 614.5, 20.5, 14, C.CloseCross, 9991, 0.5, 0.5)
    MakeBtn(bgPanel, 570, 0, 70, 50, 10000, function() CloseMenu() end)
    if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
    isMenuOpen = true
    if IsValid(topPillContainer) then SetVis(topPillContainer, "SelfHitTestInvisible") end
    pcall(function()
        if bgPanel and bgPanel.SetRenderOpacity then bgPanel:SetRenderOpacity(1) end
    end)
end
local function CreateFloatButton(canvas)
    if IsValid(floatContainer) then return end
    local vpW, vpH = GetViewport()
    local hitW, hitH = 280, 50
    local fW, fH = INDICATOR_W, INDICATOR_H
    local fX = math.floor((vpW - hitW) * 0.5)
    local fY = math.max(10, vpH - hitH - 6)
    floatContainer = NewObject("/Script/UMG.CanvasPanel", canvas)
    floatSlot = canvas:AddChildToCanvas(floatContainer)
    if floatSlot then
        floatSlot:SetAutoSize(false)
        floatSlot:SetPosition(FVector2D(fX, fY))
        floatSlot:SetSize(FVector2D(hitW, hitH))
        floatSlot:SetZOrder(11900)
    end
    SetVis(floatContainer, "SelfHitTestInvisible")
    _G.SodaLite_FloatContainer = floatContainer
    local barX = math.floor((hitW - fW) * 0.5)
    local barY = hitH - fH - 8
    RoundedPanel(floatContainer, barX, barY + 1, fW, fH, 2.5, C.Shadow, 1)
    RoundedPanel(floatContainer, barX, barY, fW, fH, 2.5, C.IndicatorWhite, 2)
    MakeBtn(floatContainer, 0, 0, hitW, hitH, 100, function() ToggleMenu(canvas) end)
end
local lastVpW, lastVpH = -1, -1
local function CheckViewportChange()
    local vpW, vpH = GetViewport()
    if math.abs(vpW - lastVpW) > 2 or math.abs(vpH - lastVpH) > 2 then
        lastVpW = vpW
        lastVpH = vpH
        UpdateLayoutPositions(vpW, vpH)
    end
end
local function IsUIValid(canvas)
    if not canvas or not IsValid(canvas) then return false end
    if not IsValid(topPillContainer) or not IsValid(floatContainer) then return false end
    local ok1, p1 = pcall(function() return topPillContainer:GetParent() end)
    if not ok1 or p1 ~= canvas then return false end
    local ok2, p2 = pcall(function() return floatContainer:GetParent() end)
    if not ok2 or p2 ~= canvas then return false end
    return true
end
function EnsureUI()
    local canvas = GetCanvas()
    if not canvas or not IsValid(canvas) then return end
    local vpW, vpH = GetViewport()
    if vpW < 50 or vpH < 50 then return end
    if IsUIValid(canvas) then
        CheckViewportChange()
        return
    end
    pcall(function()
        if IsValid(topPillContainer) then topPillContainer:RemoveFromParent() end
    end)
    pcall(function()
        if IsValid(floatContainer) then floatContainer:RemoveFromParent() end
    end)
    pcall(function()
        if IsValid(bgPanel) then bgPanel:RemoveFromParent() end
    end)
    topPillContainer = nil
    topPillSlot = nil
    floatContainer = nil
    floatSlot = nil
    bgPanel = nil
    bgSlot = nil
    sidebarContainer = nil
    contentContainer = nil
    clockTextBlock = nil
    CreateTopPill(canvas)
    CreateFloatButton(canvas)
    if isMenuOpen then
        BuildMenu(canvas)
    else
        if IsValid(floatContainer) then SetVis(floatContainer, "SelfHitTestInvisible") end
    end
end
pcall(function()
    if _G._MAGOO_FPS_SAMPLER then return end
    _G._MAGOO_FPS_SAMPLER = true
    local tk = require("common.time_ticker")
    if not (tk and tk.AddTimerLoop) then return end
    _G._MagooFpsFrames = 0
    _G._MagooFpsStamp = os.clock()
    _G._MagooLastFps = 60
    tk.AddTimerLoop(0, function()
        _G._MagooFpsFrames = (_G._MagooFpsFrames or 0) + 1
        local now = os.clock()
        local dt = now - (_G._MagooFpsStamp or now)
        if dt >= 0.5 then
            local fps = math.floor((_G._MagooFpsFrames / dt) + 0.5)
            if fps < 1 then fps = 1 end
            if fps > 240 then fps = 240 end
            _G._MagooLastFps = fps
            _G._MagooFpsFrames = 0
            _G._MagooFpsStamp = now
            pcall(function()
                local t = _G._MagooFpsText
                if t and slua.isValid(t) and t.SetText then
                    t:SetText(tostring(fps) .. " FPS")
                end
            end)
        end
    end, -1, 0.016)
end)
local function InitWatcher()
    pcall(function()
        EnsureUI()
        if IsValid(clockTextBlock) then
            clockTextBlock:SetText(os.date("%H:%M"))
        end
        pcall(function()
            local fps = _G._MagooLastFps or 60
            local t = _G._MagooFpsText or fpsTextBlock
            if IsValid(t) and t.SetText then
                t:SetText(tostring(fps) .. " FPS")
            end
        end)
        if not isMenuOpen and IsValid(topPillContainer) then
            SetVis(topPillContainer, "Collapsed")
        end
    end)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, InitWatcher)
        end
    end)
end
InitWatcher()
end)
return file_util
