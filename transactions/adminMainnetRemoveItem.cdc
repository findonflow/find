import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

transaction(tenant: Address, ftName: String, nftName: String, listingName: String){

     let adminRef : &FindMarketAdmin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }
    execute{
        let name = listingName.concat(ftName).concat(nftName)
        self.adminRef.removeMarketOption(tenant: tenant, name: name)
    }
}
