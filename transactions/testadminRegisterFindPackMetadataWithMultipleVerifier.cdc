import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindPack from "../contracts/FindPack.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import FindForge from "../contracts/FindForge.cdc"

import Admin from "../contracts/Admin.cdc"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(lease: String, typeId: UInt64, thumbnailHash: String, wallet: Address, openTime:UFix64, royaltyCut: UFix64, royaltyAddress: Address, requiresReservation: Bool, startTime:{String : UFix64}, endTime: {String : UFix64}, floatEventId: {String : UInt64}, price: {String : UFix64}, purchaseLimit:{String: UInt64}, checkAll: Bool) {

	let admin: &Admin.AdminProxy
	let wallet: Capability<&{FungibleToken.Receiver}>
	let royaltyWallet: Capability<&{FungibleToken.Receiver}>

	prepare(account: AuthAccount) {
		self.admin =account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
		self.wallet = getAccount(wallet).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		self.royaltyWallet = getAccount(royaltyAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
	}

	execute {

		if !self.wallet.check() {
			panic("wallet has to exist")
		}

		let minterPlatform = FindForge.getMinterPlatform(name: lease, forgeType: Type<@ExampleNFT.Forge>()) ?? panic("Please set up minter platform for Find Pack Forge")

		let season=typeId-1
		// leaseName + season + #PackTypeId
		let name=lease.concat(" season #".concat(season.toString()))

		let socials : {String: MetadataViews.ExternalURL} = {}
		for key in minterPlatform.socials.keys {
			socials[key] = MetadataViews.ExternalURL(url: minterPlatform.socials[key]!)
		}

		let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: name,
            description: minterPlatform.description,
            externalURL: MetadataViews.ExternalURL(url: minterPlatform.externalURL),
            squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.squareImage), mediaType: "image"),
            bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.bannerImage), mediaType: "image"),
            socials: socials
        )

		/* For testing only */
		var saleInfo : [FindPack.SaleInfo] = []
		for key in startTime.keys {
			let price = price[key] ?? panic("Price for key ".concat(key).concat(" is missing"))
			var verifier : [{FindVerifier.Verifier}] = [] 
			if floatEventId[key] != nil {
				verifier.append(FindVerifier.HasOneFLOAT([floatEventId[key]!]))
				verifier.append(FindVerifier.HasFINDName(["user1"]))
			}
			saleInfo.append(FindPack.SaleInfo(name: key, startTime : startTime[key]! , endTime : endTime[key] , price : price, purchaseLimit: purchaseLimit[key], verifiers: verifier, verifyAll: checkAll))
		}

		let royalties = MetadataViews.Royalties([
			MetadataViews.Royalty(receiver: self.royaltyWallet, cut: royaltyCut, description: "creator")
		])

		let itemTypes = [Type<@ExampleNFT.NFT>()]
		let providerCaps : {Type : Capability<&AnyResource{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>} = {}
		for type in itemTypes {
			let collection = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type.identifier)
			if collection == nil || collection!.length == 0 {
				panic("Type : ".concat(type.identifier).concat(" is not supported in NFTCatalog at the moment"))
			}
			let collectionInfo = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collection!.keys[0])!.collectionData
			let providerCap= self.admin.getProviderCap(collectionInfo.privatePath)
			providerCaps[type] = providerCap
		}

		let packRoyalty = MetadataViews.Royalties([
			MetadataViews.Royalty(receiver: self.admin.getFindRoyaltyCap(), cut: 0.15, description: "find")
		])

		let metadata = FindPack.Metadata(
			name: name,
			description: name, 
			thumbnailUrl: nil, 
			thumbnailHash: thumbnailHash, 
			wallet: self.wallet, 
			openTime:openTime, 
			walletType: Type<@FlowToken.Vault>(),
			itemTypes: itemTypes,
			providerCaps: providerCaps, 
			requiresReservation:requiresReservation,
			storageRequirement:10000, 
			saleInfos: saleInfo, 
			primarySaleRoyalties: packRoyalty,
			royalties: royalties, 
			collectionDisplay: collectionDisplay, 
			packFields: {"Items" : "1"}, 
			extraData: {}
		)

		let input : {UInt64 : FindPack.Metadata} = {typeId : metadata}

		self.admin.addForgeContractData(lease: lease, forgeType: Type<@FindPack.Forge>() , data: input)
	}
}
