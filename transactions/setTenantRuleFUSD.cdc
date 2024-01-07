import FindMarket from "../contracts/FindMarket.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(optionName: String){
    prepare(account: auth(BorrowValue) &Account){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.setTenantRule(optionName: optionName, tenantRule:
            FindMarket.TenantRule(name:"FUSD", types:[Type<@FUSD.Vault>()], ruleType: "ft", allow: true)
        )
    }
}
