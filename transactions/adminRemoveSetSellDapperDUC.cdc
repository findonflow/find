import FindMarket from "../contracts/FindMarket.cdc"


transaction(market: String){
    prepare(account: auth(BorrowValue) &Account){
        let clientRef = account.storage.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")


        clientRef.removeMarketOption(name: "DapperFUT".concat(market))
    }
}

