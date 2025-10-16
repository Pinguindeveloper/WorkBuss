local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
src = Tunnel.getInterface(GetCurrentResourceName())

local Vehicle
local Blips = {}
local Service = false
local currentTask = 1
local uiOpen = false

-- Função para abrir a UI
function OpenUI()
    if not uiOpen then
        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openUI',
            salary = {
                min = Config.Payment.Min,
                max = Config.Payment.Max
            },
            totalStops = #Config.InService
        })
    end
end

-- Função para fechar a UI
function CloseUI()
    if uiOpen then
        uiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'closeUI'
        })
    end
end

-- Callback: Fechar UI
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

-- Callback: Iniciar trabalho
RegisterNUICallback('startWork', function(data, cb)
    if not Service then
        TriggerEvent("Notify", "sucesso", "Seu Trabalho Foi Iniciado", 8000)
        Service = true
        currentTask = 1
        CreateVehs()
        InService()
        ExitService()
        
        -- Notificar a UI que o trabalho começou
        SendNUIMessage({
            action = 'workStarted'
        })
    end
    cb('ok')
end)

-- Callback: Parar trabalho
RegisterNUICallback('stopWork', function(data, cb)
    if Service then
        StopService()
    end
    cb('ok')
end)

-- Thread principal para detectar quando o jogador está perto do marcador
CreateThread(function()
    local GetService = Config.EnterService
    local x,y,z = GetService.x, GetService.y, GetService.z

    while true do
        local Ped = PlayerPedId()
        local Entity = GetEntityCoords(Ped)
        local Distance = #(Entity - vector3(x,y,z))

        if Distance < 5 and not Service then
            DrawMarker(1, x,y,z -1, 0,0,0, 0,0,0, 1.5,1.5,1.5, 59,130,246,155, false,false,2,false)
            if Distance <= 1.5 then
                -- Desenhar texto de ajuda
                DrawText3D(x, y, z + 0.5, "~b~[E]~w~ Abrir Painel de Emprego")
                
                if IsControlJustPressed(0, 38) then -- Tecla E
                    OpenUI()
                end
            end
        end
        Citizen.Wait(5)
    end
end)

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Função de serviço (rota de ônibus)
function InService()
    CreateThread(function()
        while Service do
            local Work = Config.InService[currentTask]
            local BlipMarker = Blips[currentTask]

            if Work then
                local Ped = PlayerPedId()
                local GetCoords = GetEntityCoords(Ped)
                local Distance = #(GetCoords - vector3(Work.x,Work.y,Work.z))

                if not BlipMarker then
                    BlipMarker = AddBlipForCoord(Work.x,Work.y,Work.z)
                    SetBlipSprite(BlipMarker, 280)
                    SetBlipColour(BlipMarker, 3)
                    SetBlipScale(BlipMarker, 0.7)
                    SetBlipRoute(BlipMarker, true)
                    SetBlipAsShortRange(BlipMarker, false)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Ponto de Ônibus")
                    EndTextCommandSetBlipName(BlipMarker)
                    Blips[currentTask] = BlipMarker
                end
                
                if Distance < 45 then
                    DrawMarker(1, Work.x,Work.y,Work.z -1, 0,0,0, 0,0,0, 3.5,3.5,3.5, 59,130,246,155, false,false,2,false)
                    if Distance <= 3 then
                        if IsVehicleModel(GetVehiclePedIsIn(PlayerPedId(), true), GetHashKey(Config.NameVehs)) then
                            src.PaymentMoney()
                            RemoveBlip(BlipMarker)
                            Blips[currentTask] = nil
                            currentTask = currentTask + 1
                            
                            -- Atualizar progresso na UI
                            SendNUIMessage({
                                action = 'updateProgress',
                                current = currentTask - 1,
                                total = #Config.InService
                            })
                            
                            if currentTask > #Config.InService then
                                currentTask = 1
                                TriggerEvent("Notify", "aviso", "Rota Completa! Trabalho Reiniciado", 8000)
                            end
                        end
                    end
                end
            end    
            Citizen.Wait(5)
        end
    end)
end

-- Função para sair do serviço
function ExitService()
    CreateThread(function()
        while Service do
            if IsControlJustPressed(0, 168) then -- F7
                StopService()
                return
            end
            Citizen.Wait(5)
        end
    end)
end

-- Função para parar o serviço
function StopService()
    Service = false
    DeleteEntity(Vehicle)
    ClearPedTasks(PlayerPedId())
    
    for _, BlipMarker in pairs(Blips) do
        if DoesBlipExist(BlipMarker) then
            RemoveBlip(BlipMarker)
        end
    end
    Blips = {}
    currentTask = 1
    
    -- Notificar a UI que o trabalho parou
    SendNUIMessage({
        action = 'workStopped'
    })
    
    TriggerEvent("Notify", "aviso", "Serviço Finalizado", 8000)
end

-- Função para criar o veículo
function CreateVehs()
    local Hash = GetHashKey(Config.NameVehs)
    local GetVehs = Config.Vehs
    local x,y,z,h = GetVehs.x, GetVehs.y, GetVehs.z, GetVehs.h

    while not HasModelLoaded(Hash) do 
        Citizen.Wait(5) 
        RequestModel(Hash)
    end
    
    Vehicle = CreateVehicle(Hash, x,y,z,h, true,true)
    SetVehicleNumberPlateText(Vehicle, vRP.getRegistrationNumber())
    SetPedIntoVehicle(PlayerPedId(), Vehicle, -1)
    SetEntityNoCollisionEntity(PlayerPedId(), Vehicle, true)
    SetEntityAlpha(Vehicle, 80, false)
    
    SetTimeout(7000, function()
        SetEntityNoCollisionEntity(PlayerPedId(), Vehicle, false)
        SetEntityAlpha(Vehicle, 255, false)
    end)
end

-- Criar NPC fixo
CreateThread(function()
    RequestModel(GetHashKey(Config.FixedPed.name))
    while not HasModelLoaded(GetHashKey(Config.FixedPed.name)) do
        Citizen.Wait(100)
    end
    
    local LocatePed = CreatePed(4, Config.FixedPed.hash, Config.FixedPed.x, Config.FixedPed.y, Config.FixedPed.z -1, Config.FixedPed.h, false, true)
    FreezeEntityPosition(LocatePed, true)
    SetEntityInvincible(LocatePed, true)
    SetBlockingOfNonTemporaryEvents(LocatePed, true)
    SetEntityCollision(LocatePed, true, true)
end)

