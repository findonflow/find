import Admin from "../contracts/Admin.cdc"

transaction(tenant: Address, saleItemName: String, cut: UFix64){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        adminRef.setFindCut(tenant: tenant, saleItemName:saleItemName, cut: cut, rules: nil, status: "active")
    }
}

