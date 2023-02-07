import Admin from "../contracts/Admin.cdc"

transaction(tenant: Address){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        adminRef.setupSwitchboardCut(tenant: tenant)
    }
}

