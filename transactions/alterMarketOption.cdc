import "FindMarket"

transaction(marketRule: String , action: String ){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")


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
