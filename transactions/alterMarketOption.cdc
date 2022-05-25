import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

transaction(marketRule: String , action: String ){
    prepare(account: AuthAccount){
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


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
