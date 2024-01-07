import FindMarket from "../contracts/FindMarket.cdc"

transaction(action: String ){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
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
