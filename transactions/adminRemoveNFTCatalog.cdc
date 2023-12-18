import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(
    collectionIdentifier : String
) {
    let adminProxyResource : &Admin.AdminProxy

    prepare(acct: auth(BorrowValue)  AuthAccountAccount) { 
        self.adminProxyResource = acct.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute {     
        self.adminProxyResource.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
    }
}