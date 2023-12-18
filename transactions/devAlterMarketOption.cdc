import FindMarket from "../contracts/FindMarket.cdc"

transaction(action: String ){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
		let marketOption = "FlowDandyEscrow"

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
