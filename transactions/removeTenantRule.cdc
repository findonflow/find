import FindMarket from "../contracts/FindMarket.cdc"

transaction(optionName: String, tenantRuleName: String){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
    }
}
