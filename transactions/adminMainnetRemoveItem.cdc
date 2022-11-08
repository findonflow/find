import FindMarket from "../contracts/FindMarket.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(tenant: Address, ftName: String, nftName: String, listingName: String){
    
     let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        let name = listingName.concat(ftName).concat(nftName)
        self.adminRef.removeMarketOption(tenant: tenant, name: name)
    }
}
