import FindMarketTenant from "../contracts/FindMarketTenant.cdc"




transaction(saleItemName: String){
    prepare(account: AuthAccount){
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeMarketOption(name: saleItemName)
    }
}
