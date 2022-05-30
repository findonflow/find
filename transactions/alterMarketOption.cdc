import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketRule: String , action: String ){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


        switch action {
            case "enable" :
                tenantRef.enableMarketOption(marketRule)

            case "deprecate" :
                tenantRef.deprecateMarketOption(marketRule)

            case "stop" :
                tenantRef.stopMarketOption(marketRule)
        }
    }
}
