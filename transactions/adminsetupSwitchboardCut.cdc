import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(tenant: Address){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        adminRef.setupSwitchboardCut(tenant: tenant)
    }
}

