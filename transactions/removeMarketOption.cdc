import "FindMarket"

transaction(saleItemName: String){
    
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeMarketOption(name: saleItemName)
    }
}
