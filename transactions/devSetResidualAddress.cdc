import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(address: Address) {

    let adminRef : &FindMarketAdmin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }

    execute{
        self.adminRef.setResidualAddress(address)
    }
}
