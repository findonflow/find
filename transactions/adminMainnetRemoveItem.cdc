import "FindMarket"
import "FindMarketAdmin"

transaction(tenant: Address, ftName: String, nftName: String, listingName: String){

     let adminRef : auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

    }
    execute{
        let name = listingName.concat(ftName).concat(nftName)
        self.adminRef.removeMarketOption(tenant: tenant, name: name)
    }
}
