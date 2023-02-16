import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(tenant: Address, saleItemName: String, cut: UFix64){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        adminRef.setFindCut(tenant: tenant, saleItemName:saleItemName, cut: cut, rules: nil, status: "active")
    }
}

