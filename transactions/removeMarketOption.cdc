import FindMarket from "../contracts/FindMarket.cdc"

transaction(saleItemName: String){
    
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeMarketOption(name: saleItemName)
    }
}
