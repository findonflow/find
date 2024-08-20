import "FindMarketAdmin"

transaction(tenant: Address){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        adminRef.setupSwitchboardCut(tenant: tenant)
    }
}

