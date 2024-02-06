import "FIND"

import NFTStorefront from 0x4eb8a10cb9f87357
import Marketplace from 0xd796ff17107bbff6
import Art from 0xd796ff17107bbff6
import "FlowToken"
import Flovatar from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a

// This script returns the details for a listing within a storefront

access(all) struct Listing {
	access(all) let marketplace : String
	access(all) let ftVault: Type
	access(all) let price:UFix64
	access(all) let nftType: Type
	access(all) let nftId: UInt64

	init(marketplace:String, ftVault:Type, price:UFix64, nftType:Type, nftId:UInt64) {
		self.marketplace=marketplace
		self.ftVault=ftVault
		self.price=price
		self.nftType=nftType
		self.nftId=nftId
	}
}

access(all) fun main(user: String): {UInt64 :[Listing]} {

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return {}}
	let address = resolveAddress!
	let account=getAccount(address)
	if account.balance == 0.0 {
		return {}
	}
	let storefrontRef = account.getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath).borrow()!

	let listings : {UInt64 : [Listing]} = {}

	for id in storefrontRef.getListingIDs() {
		let listing = storefrontRef.borrowListing(listingResourceID: id)!
		let details=listing.getDetails()
		if details.purchased==true {
			continue
		}
		let uuid=listing.borrowNFT()!.uuid

		let item = Listing( 
			marketplace:"nftstorefront-".concat(details.storefrontID.toString()),
			ftVault: details.salePaymentVaultType, 
			price: details.salePrice,
			nftType:details.nftType,
			nftId: details.nftID,
		)
		let uuidListings= listings[uuid] ?? []
		uuidListings.append(item)
		listings[uuid]= uuidListings
	}


	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	if versusMarketplace.check() {

		let versusMarket = versusMarketplace.borrow()!

		let saleItems = versusMarket.listSaleItems()
		for saleItem in saleItems {

			let item = Listing( 
				marketplace:"versus",
				ftVault: Type<@FlowToken.Vault>(),
				price: saleItem.price,
				nftType:Type<@Art.NFT>(),
				nftId: saleItem.id
			)

			let uuid = versusMarket.getUUIDforSaleItem(tokenID: saleItem.id)
			//let uuid = art.borrowNFT(id:saleItem.id)!.uuid
			let uuidListings= listings[uuid] ?? []
			uuidListings.append(item)
			listings[uuid]= uuidListings

		}
	}



	let flovatarCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)  
	if flovatarCap.check(){
		let saleCollection=flovatarCap.borrow()!
		for id in saleCollection.getFlovatarIDs() {
			let price = saleCollection.getFlovatarPrice(tokenId: id)!
			let flovatar = saleCollection.getFlovatar(tokenId: id)!

			let item = Listing( 
				marketplace:"flovatar",
				ftVault: Type<@FlowToken.Vault>(),
				price: price,
				nftType:Type<@Flovatar.NFT>(),
				nftId: id
			)

			let uuid =  flovatar.uuid
			//let uuid = art.borrowNFT(id:saleItem.id)!.uuid
			let uuidListings= listings[uuid] ?? []
			uuidListings.append(item)
			listings[uuid]= uuidListings
		}
	}
	return listings
}
