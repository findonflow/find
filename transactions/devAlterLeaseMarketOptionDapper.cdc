import FindMarket from "../contracts/FindMarket.cdc"

transaction(action: String ){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
		let option = "DapperLeaseSoft"

        switch action {
            case "enable" :
                tenantRef.enableMarketOption(option)

            case "deprecate" :
                tenantRef.deprecateMarketOption(option)

            case "stop" :
                tenantRef.stopMarketOption(option)
        }
    }
}
