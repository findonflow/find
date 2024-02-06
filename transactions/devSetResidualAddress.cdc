import "FindMarketAdmin"

transaction(address: Address) {

    let adminRef : auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }

    execute{
        self.adminRef.setResidualAddress(address)
    }
}
