import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(tenant: Address){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        adminRef.setupSwitchboardCut(tenant: tenant)
    }
}

