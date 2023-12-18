import FindMarket from "../contracts/FindMarket.cdc"

transaction(optionName: String, tenantRuleName: String){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
    }
}
