import FindMarket from "../contracts/FindMarket.cdc"

transaction(action: String ){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
		let marketOption = "DapperDandySoft"

        switch action {
            case "enable" :
                tenantRef.enableMarketOption(marketOption)

            case "deprecate" :
                tenantRef.deprecateMarketOption(marketOption)

            case "stop" :
                tenantRef.stopMarketOption(marketOption)
        }
    }
}
