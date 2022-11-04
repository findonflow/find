import FindMarket from "../contracts/FindMarket.cdc"

transaction(market: String , action: String ){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


        switch action {
            case "enable" :
                tenantRef.enableMarketOption("FlowLease".concat(market))

            case "deprecate" :
                tenantRef.deprecateMarketOption("FlowLease".concat(market))

            case "stop" :
                tenantRef.stopMarketOption("FlowLease".concat(market))
        }
    }
}
