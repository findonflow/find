import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindPack from "../contracts/FindPack.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import FindForge from "../contracts/FindForge.cdc"

import Admin from "../contracts/Admin.cdc"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(lease: String, typeId: UInt64, thumbnailHash: String, wallet: Address, walletType: String, openTime:UFix64, royaltyCut: UFix64, royaltyAddress: Address, requiresReservation: Bool, itemTypes: [String], startTime:{String : UFix64}, endTime: {String : UFix64}, floatEventId: {String : UInt64}, price: {String : UFix64}, purchaseLimit:{String: UInt64}, storageRequirement: UInt64) {

	let admin: &Admin.AdminProxy
	let wallet: Capability<&{FungibleToken.Receiver}>
	let royaltyWallet: Capability<&{FungibleToken.Receiver}>
	let providerCaps : {Type : Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>}
	let itemTypes : [Type]

	prepare(account: AuthAccount) {
		self.admin =account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
		self.wallet = getAccount(wallet).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		self.royaltyWallet = getAccount(royaltyAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

		self.itemTypes = []
		for type in itemTypes {
			self.itemTypes.append(CompositeType(type)!)
		}
		self.providerCaps = {}
		for type in self.itemTypes {
			let collection = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type.identifier)
			if collection == nil || collection!.length == 0 {
				panic("Type : ".concat(type.identifier).concat(" is not supported in NFTCatalog at the moment"))
			}
			let collectionInfo = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collection!.keys[0])!.collectionData
			let providerCap = account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(collectionInfo.privatePath)

			self.providerCaps[type] = providerCap
		}

	}

	execute {

		if !self.wallet.check() {
			panic("wallet has to exist")
		}

		let minterPlatform = FindForge.getMinterPlatform(name: lease, forgeType: Type<@FindPack.Forge>()) ?? panic("Please set up minter platform for Find Pack Forge")

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
			}
			saleInfo.append(FindPack.SaleInfo(name: key, startTime : startTime[key]! , endTime : endTime[key] , price : price, purchaseLimit: purchaseLimit[key], verifiers: verifier, verifyAll: true))
		}

		let royalties = MetadataViews.Royalties([
			MetadataViews.Royalty(receiver: self.royaltyWallet, cut: royaltyCut, description: "creator")
		])

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
			walletType: CompositeType(walletType)!,
			itemTypes: self.itemTypes,
			providerCaps: self.providerCaps,
			requiresReservation:requiresReservation,
			storageRequirement:storageRequirement,
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
