import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FINDNFTCatalogAdmin from "../contracts/FINDNFTCatalogAdmin.cdc"

transaction(
    collectionIdentifier : String
) {
    let adminProxyResource : &FINDNFTCatalogAdmin.Admin

    prepare(acct: AuthAccount) { 
        self.adminProxyResource = acct.borrow<&FINDNFTCatalogAdmin.Admin>(from : FINDNFTCatalogAdmin.AdminStoragePath)!
    }

    execute {     
        self.adminProxyResource.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
    }
}