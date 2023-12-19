import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(address: Address) {

    let adminRef : &FindMarketAdmin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }

    execute{
        self.adminRef.setResidualAddress(address)
    }
}
