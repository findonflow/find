import "FindMarket"


transaction(market: String){
    prepare(account: auth(BorrowValue) &Account){
        let clientRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")


        clientRef.removeMarketOption(name: "DapperFUT".concat(market))
    }
}

