import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindViews from "../contracts/FindViews.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FIND from "../contracts/FIND.cdc" 
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub struct NFTDetailReport {
	pub let findMarket: {String : FindMarket.SaleItemInformation}
	pub let storefront: StorefrontListing?
    pub let nftDetail: NFTDetail?

	init(findMarket:{String : FindMarket.SaleItemInformation}, storefront: StorefrontListing?, nftDetail: NFTDetail?) {
		self.findMarket=findMarket
		self.storefront=storefront
		self.nftDetail=nftDetail
	}
}

pub struct NFTDetail {
    pub let id: UInt64 
    pub let uuid: UInt64 
    pub let name:String
    pub let thumbnail:String
    pub let type: String
    pub var rarity:String?
    pub var editionNumber: UInt64? 
    pub var totalInEdition: UInt64?
    pub var scalars : {String: UFix64}
    pub var tags : {String: String}
    pub var collectionName: String? 
    pub var collectionDescription: String? 
    pub var views: {String : AnyStruct?}

init(_ pointer: FindViews.ViewReadPointer, views: {String : AnyStruct}){

            let item = pointer.getViewResolver()

			self.scalars={}
			self.tags={}
		
			self.collectionName=nil
			self.collectionDescription=nil
			if item.resolveView(Type<FindViews.NFTCollectionDisplay>()) != nil {
				let view = item.resolveView(Type<FindViews.NFTCollectionDisplay>())!
				if view as? FindViews.NFTCollectionDisplay != nil {
					let grouping = view as! FindViews.NFTCollectionDisplay
					self.collectionName=grouping.name
					self.collectionDescription=grouping.description
				}
			}
			
			self.rarity=nil
			if item.resolveView(Type<FindViews.Rarity>()) != nil {
				let view = item.resolveView(Type<FindViews.Rarity>())!
				if view as? FindViews.Rarity != nil {
					let rarity = view as! FindViews.Rarity
					self.rarity=rarity.rarityName
				}
			} 

			if item.resolveView(Type<FindViews.Tag>()) != nil {
				let view = item.resolveView(Type<FindViews.Tag>())!
				if view as? FindViews.Tag != nil {
					let tags = view as! FindViews.Tag
					self.tags=tags.getTag()
				}
			}

			if item.resolveView(Type<FindViews.Scalar>()) != nil {
				let view = item.resolveView(Type<FindViews.Scalar>())!
				if view as? FindViews.Scalar != nil {
					let scalar = view as! FindViews.Scalar
					self.scalars=scalar.getScalar()
				}
			}
			
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
			self.id=pointer.id
            self.uuid=pointer.getUUID()

			self.editionNumber=nil
			self.totalInEdition=nil
			if item.resolveView(Type<FindViews.Edition>()) != nil {
				let view = item.resolveView(Type<FindViews.Edition>())!
				if view as? FindViews.Edition != nil {
					let edition = view as! FindViews.Edition
					self.editionNumber=edition.editionNumber
					self.totalInEdition=edition.totalInEdition
				}
			} 

			self.views=views
		}

}

pub struct StoreFrontCut {

	pub let amount:UFix64
	pub let address: Address
	pub let findName:String?

	init(amount:UFix64, address:Address){
		self.amount=amount
		self.address=address
		self.findName= FIND.reverseLookup(address)
	}
}

pub struct StorefrontListing {
	pub let nftID:UInt64
	pub let nftIdentifier: String
	pub let saleCut: [StoreFrontCut]
	pub let amount:UFix64
	pub let ftTypeIdentifier:String
	pub let storefront:UInt64
	pub let listingID:UInt64

	init(listingId:UInt64, details: NFTStorefront.ListingDetails) {

		self.saleCut=[]
		self.nftID=details.nftID
		self.nftIdentifier=details.nftType.identifier
		for cutDetails in details.saleCuts {
			self.saleCut.append(StoreFrontCut(amount:cutDetails.amount, address:cutDetails.receiver.address))
		}
		self.amount=details.salePrice
		self.ftTypeIdentifier=details.salePaymentVaultType.identifier
		self.storefront=details.storefrontID
		self.listingID=listingId
	}
}


/*

*/
// pub struct StorefrontReport {

// 	pub let items : [StorefrontListing]
// 	pub let ghosts: [StorefrontListing]

// 	init(_ listings : {UInt64 : NFTStorefront.ListingDetails}) {

// 		self.items=[]
// 		self.ghosts=[]
// 		for key in listings.keys {

// 			let details = listings[key]!

// 			let listing = StorefrontListing(listingId: key, details:details)

// 			//Here we really have no way to find out if this is truly a ghost or not since the state in storefront only change 
// 			//to purchased if it is bought in storefront. And we have no way to get a capability and check if it is present either
// 			if details.purchased {
// 				self.ghosts.append(listing)
// 			} else {
// 				self.items.append(listing)
// 			}
// 		}
// 	}
// }

pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!

	let nftDetail = getNFTDetail(address: address, nftAliasOrIdentifier: nftAliasOrIdentifier, id: id, views: views)
	if nftDetail == nil {
		return nil
	}


	let findMarket=FindMarketOptions.getNFTFindListing(address: address, id: nftDetail!.uuid)

	let account=getAccount(address)
	var listings : StorefrontListing? = nil
	let storefrontCap = account.getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)

	if storefrontCap.check() {
		let storefrontRef=storefrontCap.borrow()!
		for listingId in storefrontRef.getListingIDs() {
			let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
			let nft=listing.borrowNFT()
			if nft.id==id && !listing.getDetails().purchased {
				listings = StorefrontListing(listingId: listingId, details: listing.getDetails())
			}
		}
	}

	return NFTDetailReport(findMarket:findMarket, storefront: listings, nftDetail: nftDetail)

}

pub fun getNFTDetail(address: Address, nftAliasOrIdentifier: String, id: UInt64, views: [String]) : NFTDetail? {
	let account = getAccount(address) 
	let publicPath = NFTRegistry.getNFTInfo(nftAliasOrIdentifier)?.publicPath ?? panic("This NFT is not supported by NFT Registry")
 	let cap = account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
	let pointer = FindViews.ViewReadPointer(cap: cap, id: id)

	if !pointer.valid() {
		return nil
	}

	let viewTypes = pointer.getViews() 
	var nftViews: {String : AnyStruct} = {}
	for viewType in viewTypes {
		if views.contains(getType(viewType)) {
			if let view = pointer.resolveView(viewType) {
				nftViews[getType(viewType)] = view! 
			}
		}
	}
	return NFTDetail(pointer, views: nftViews)
	

}

/* Helper Function */
pub fun getType(_ type: Type) : String {
	let identifier = type.identifier
	var dots = 0
	var counter = 0 
	while counter < identifier.length {
		if identifier[counter] == "." {
			dots = dots + 1
			if dots == 3 {
				break
			}
		}
		counter = counter + 1
	}
	if dots == 0 {
		return identifier
	}
	if counter + 1 > identifier.length {
		panic("Identifier is ".concat(identifier))
	}
	return identifier.slice(from: counter + 1, upTo: identifier.length)
}