import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"
import NFTCatalogAdmin from "../contracts/NFTCatalogAdmin.cdc"

transaction(
    collectionIdentifier : String
) {
    let adminProxyResource : &NFTCatalogAdmin.Admin

    prepare(acct: AuthAccount) { 
        self.adminProxyResource = acct.borrow<&NFTCatalogAdmin.Admin>(from : NFTCatalogAdmin.AdminStoragePath)!
    }

    execute {     
        self.adminProxyResource.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
    }
}