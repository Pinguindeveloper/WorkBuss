local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPclient = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)

function src.PaymentMoney()
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        local randomPayment = math.random(Config.Payment.Min, Config.Payment.Max)
        vRP.giveMoney(user_id, randomPayment)
        TriggerClientEvent("Notify", source, "sucesso", "Seu Pagamento Foi de R$<b>".. randomPayment .."</b>")
    end
end
print('^2SCRIPT TOTALMENTE FREE ^BY PINGUINDEV^0')
