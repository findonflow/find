import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

transaction(market: String , action: String ){
    prepare(account: AuthAccount){
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


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
