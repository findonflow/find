import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(tenant: Address){
    prepare(account: auth(BorrowValue)  AuthAccountAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        adminRef.setupSwitchboardCut(tenant: tenant)
    }
}

