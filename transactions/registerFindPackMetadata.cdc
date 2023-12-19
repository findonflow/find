import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindPack from "../contracts/FindPack.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FIND from "../contracts/FIND.cdc"

// this is a simple tx to update the metadata of a given type of NeoVoucher

transaction(forge: String, name: String, description:String, typeId: UInt64, externalURL: String, thumbnailHash: String, bannerHash: String, social: {String : String}, wallet: Address, walletType: String, openTime:UFix64, primaryRoyaltyRecipients : [Address], primaryRoyaltyCuts: [UFix64], primaryRoyaltyDescriptions: [String], secondaryRoyaltyRecipients: [Address], secondaryRoyaltyCuts: [UFix64],  secondaryRoyaltyDescriptions: [String], requiresReservation: Bool, startTime:{String : UFix64}, endTime: {String : UFix64}, floatEventId: {String : UInt64}, price: {String : UFix64}, purchaseLimit:{String: UInt64}, packFields : {String:String}, nftTypes: [String], storageRequirement: UInt64) {

	let lease: &FIND.Lease
	let wallet: Capability<&{FungibleToken.Receiver}>
	let providerCaps : {Type : Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>}
	let types : [Type]

	prepare(account: auth(BorrowValue) &Account) {
		let leaseCol =account.storage.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Could not borrow leases collection")
		self.lease = leaseCol.borrow(forge)
		self.wallet = getAccount(wallet).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

		//for each tier you need a providerAddress and path
		self.providerCaps = {}
		self.types = []
		for typeName in nftTypes {
			let collection = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: typeName)
			if collection == nil || collection!.length == 0 {
				panic("Type : ".concat(typeName).concat(" is not supported in NFTCatalog at the moment"))
			}
			let collectionInfo = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collection!.keys[0])!.collectionData
			let providerCap= account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(collectionInfo.privatePath)
			let type = CompositeType(typeName)!
			self.types.append(type)
			self.providerCaps[type] = providerCap
		}
	}

	execute {

		let forgeType = Type<@FindPack.Forge>()

		let minterPlatform = FindForge.getMinterPlatform(name: forge, forgeType: forgeType)
		if minterPlatform == nil {
			panic("Please set up minter platform for name : ".concat(forge).concat( " with this forge type : ").concat(forgeType.identifier))
		}

		let socialMap : {String : MetadataViews.ExternalURL} = {}
		for key in social.keys {
			socialMap[key] = MetadataViews.ExternalURL(social[key]!)
		}

		let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: name,
            description: description,
			externalURL: MetadataViews.ExternalURL(url: externalURL),
			squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(hash: thumbnailHash, path:nil), mediaType: "image"),
            bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(hash: bannerHash, path:nil), mediaType: "image"),
            socials: socialMap
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

		let royaltyItems : [MetadataViews.Royalty] = []
		for i, recipient in primaryRoyaltyRecipients {
			let wallet = getAccount(recipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			royaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: primaryRoyaltyCuts[i], description: primaryRoyaltyDescriptions[i]))
		}

		let primaryRoyalties = MetadataViews.Royalties(royaltyItems)

		let secondaryRoyaltyItems : [MetadataViews.Royalty] = []
		for i, recipient in secondaryRoyaltyRecipients {
			let wallet = getAccount(recipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			secondaryRoyaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: secondaryRoyaltyCuts[i], description: secondaryRoyaltyDescriptions[i]))
		}

		let secondaryRoyalty = MetadataViews.Royalties(secondaryRoyaltyItems)

		let metadata = FindPack.Metadata(
			name: name,
			description: description,
			thumbnailUrl: nil,
			thumbnailHash: thumbnailHash,
			wallet: self.wallet,
			openTime:openTime,
			walletType: CompositeType(walletType)!,
			itemTypes: self.types,
			providerCaps: self.providerCaps,
			requiresReservation:requiresReservation,
			storageRequirement:storageRequirement,
			saleInfos: saleInfo,
			primarySaleRoyalties: primaryRoyalties,
			royalties: secondaryRoyalty,
			collectionDisplay: collectionDisplay,
			packFields: packFields,
			extraData: {}
		)

		let input : {UInt64 : FindPack.Metadata} = {typeId : metadata}

		FindForge.addContractData(lease: self.lease, forgeType: Type<@FindPack.Forge>() , data: input)
	}
}
