import "FindViews"
import "FIND"
import "MetadataViews"
import "FINDNFTCatalog"
import "FindUserStatus"

access(all) struct NFTDetailReport {
	access(all) let storefront: FindUserStatus.StorefrontListing?
	access(all) let storefrontV2: FindUserStatus.StorefrontListing?
	access(all) let flowty: FindUserStatus.FlowtyListing?
	access(all) let flowtyRental: FindUserStatus.FlowtyRental?
	access(all) let flovatar: FindUserStatus.FlovatarListing?
	access(all) let flovatarComponent: FindUserStatus.FlovatarComponentListing?

	init(
		 storefront: FindUserStatus.StorefrontListing?,
		 storefrontV2: FindUserStatus.StorefrontListing?,
		 flowty: FindUserStatus.FlowtyListing?,
		 flowtyRental: FindUserStatus.FlowtyRental? ,
		 flovatar: FindUserStatus.FlovatarListing? ,
		 flovatarComponent: FindUserStatus.FlovatarComponentListing? ,
		) {
		self.storefront=storefront
		self.storefrontV2=storefrontV2
		self.flowty=flowty
		self.flowtyRental=flowtyRental
		self.flovatar=flovatar
		self.flovatarComponent=flovatarComponent
	}
}

access(all) fun main(user: String, project:String, id: UInt64, views: [String]) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user)
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!

	let account = getAuthAccount(address)

	if account.balance > 0.0 {

		let storagePath = getStoragePath(project)
		let publicPath = PublicPath(identifier: "find_temp_path")!
		account.link<&{ViewResolver.ResolverCollection}>(publicPath, target: storagePath)
		let cap = account.getCapability<&{ViewResolver.ResolverCollection}>(publicPath)
		if !cap.check() {
			panic("The user does not set up collection correctly.")
		}
		let pointer = FindViews.ViewReadPointer(cap: cap, id: id)

		let nftType = pointer.itemType
		let listingsV1 = FindUserStatus.getStorefrontListing(user: address, id : id, type: nftType)
		let listingsV2 = FindUserStatus.getStorefrontV2Listing(user: address, id : id, type: nftType)
		let flowty = FindUserStatus.getFlowtyListing(user: address, id : id, type: nftType)
		let flowtyRental = FindUserStatus.getFlowtyRentals(user: address, id : id, type: nftType)
		let flovatar = FindUserStatus.getFlovatarListing(user: address, id : id, type: nftType)
		let flovatarComponent = FindUserStatus.getFlovatarComponentListing(user: address, id : id, type: nftType)

		return NFTDetailReport(
			storefront:listingsV1,
			storefrontV2: listingsV2,
			flowty:flowty,
			flowtyRental:flowtyRental,
			flovatar:flovatar,
			flovatarComponent:flovatarComponent,
			)
	}
	return nil

}

access(all) getStoragePath(_ nftIdentifier: String) : StoragePath {
	if let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys {
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		return collection.collectionData.storagePath
	}

	if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier :nftIdentifier) {
		return collection.collectionData.storagePath
	}
	panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
}
