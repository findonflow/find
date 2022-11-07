import FindMarket from "../contracts/FindMarket.cdc"

transaction(market: String , action: String ){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


        switch action {
            case "enable" :
                tenantRef.enableMarketOption("FlowDandy".concat(market))

            case "deprecate" :
                tenantRef.deprecateMarketOption("FlowDandy".concat(market))

            case "stop" :
                tenantRef.stopMarketOption("FlowDandy".concat(market))
        }
    }
}
