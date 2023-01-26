import FindMarket from "../contracts/FindMarket.cdc"


transaction(market: String){
    prepare(account: AuthAccount){
        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")


        clientRef.removeMarketOption(name: "DapperDUCWearables".concat(market))
    }
}

