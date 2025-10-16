local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
src = Tunnel.getInterface(GetCurrentResourceName())

local Vehicle
local Blips = {}
local Service = false

CreateThread(function()

    local GetService = Config.EnterService
    local x,y,z = GetService.x, GetService.y, GetService.z

    while true do
        local Ped = PlayerPedId()
        local Entity = GetEntityCoords(Ped)
        local Distance = #(Entity - vector3(x,y,z))

        if Distance < 5 and not Service then
            DrawMarker(1, x,y,z -1, 0,0,0, 0,0,0, 1.5,1.5,1.5, 255,0,0,155, false,false,2,false)
            if Distance <= 1 then
                if IsControlJustPressed(0, 38) then
                    TriggerEvent("Notify", "sucesso", "Seu Trabalho Foi Iniciado", 8000)
                    Service = true
                    CreateVehs()
                    InService()
                    ExitService()
                end
            end
        end
        Citizen.Wait(5)
    end
end)
function InService()
    CreateThread(function()

        local lastTask = 0
        local currentTask = 1

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
                    SetBlipColour(BlipMarker, 1)
                    SetBlipScale(BlipMarker, 0.7)
                    SetBlipRoute(BlipMarker, true)
                    SetBlipAsShortRange(BlipMarker, false)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Pontos de Onibos")
                    EndTextCommandSetBlipName(BlipMarker)
                    Blips[currentTask] = BlipMarker
                end
                if Distance < 45 then
                    DrawMarker(1, Work.x,Work.y,Work.z -1, 0,0,0, 0,0,0, 3.5,3.5,3.5, 255,0,0,155, false,false,2,false)
                    if Distance <= 3 then
                        if IsVehicleModel(GetVehiclePedIsIn(PlayerPedId(), true), GetHashKey(Config.NameVehs)) then
                            src.PaymentMoney()
                            currentTask = currentTask + 1
                            RemoveBlip(BlipMarker)
                            if currentTask > #Config.InService then
                                currentTask = 1
                                TriggerEvent("Notify", "aviso", "Seu Trabalho Foi Reiniciado", 8000)
                                Blips = {}
                            end
                        end
                    end
                end
            end    
            Citizen.Wait(5)
        end
    end)
end
function ExitService()
    CreateThread(function()
        while Service do
            if IsControlJustPressed(0, 168) then
                Service = false
                DeleteEntity(Vehicle)
                ClearPedTasks(PlayerPedId())
                for _, BlipMarker in pairs(Blips) do
                    if DoesBlipExist(BlipMarker) then
                        RemoveBlip(BlipMarker)
                    end
                end
                Blips = {}
                TriggerEvent("Notify", "aviso", "Serviço Finalizado", 8000)
                return
            end
            Citizen.Wait(5)
        end
    end)
end
function CreateVehs()
    local Hash = GetHashKey(Config.NameVehs)

    local GetVehs = Config.Vehs
    local x,y,z,h = GetVehs.x, GetVehs.y, GetVehs.z, GetVehs.h

    while not HasModelLoaded(Hash) do Citizen.Wait(5) RequestModel(Hash)
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
CreateThread(function()
    for k, v in pairs(Config.FixedPed) do
        RequestModel(GetHashKey(Config.FixedPed.name))
        while not HasModelLoaded(GetHashKey(Config.FixedPed.name)) do
            Citizen.Wait(100)
        end
        local LocatePed = CreatePed(4, Config.FixedPed.hash,Config.FixedPed.x,Config.FixedPed.y,Config.FixedPed.z -1, Config.FixedPed.h, false,true)
        FreezeEntityPosition(LocatePed, true)
        SetEntityInvincible(LocatePed, true)
        SetBlockingOfNonTemporaryEvents(LocatePed, true)
        SetEntityCollision(LocatePed, true,true)
    end
end)