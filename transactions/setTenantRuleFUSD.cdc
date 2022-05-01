import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(optionName: String){
    prepare(account: AuthAccount){
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.setTenantRule(optionName: optionName, tenantRule:
            FindMarketTenant.TenantRule(name:"FUSD", types:[Type<@FUSD.Vault>()], ruleType: "ft", allow: true)
        )
    }
}
