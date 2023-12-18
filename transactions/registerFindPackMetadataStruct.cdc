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

transaction(info: FindPack.PackRegisterInfo) {

	let lease: &FIND.Lease
	let wallet: Capability<&{FungibleToken.Receiver}>
	let providerCaps : {Type : Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>}
	let types : [Type]

	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		let leaseCol =account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Could not borrow leases collection")
		self.lease = leaseCol.borrow(info.forge)
		self.wallet = getAccount(info.paymentAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

		//for each tier you need a providerAddress and path
		self.providerCaps = {}
		self.types = []
		for typeName in info.nftTypes {
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

		let minterPlatform = FindForge.getMinterPlatform(name: info.forge, forgeType: forgeType)
		if minterPlatform == nil {
			panic("Please set up minter platform for name : ".concat(info.forge).concat( " with this forge type : ").concat(forgeType.identifier))
		}

		let socialMap : {String : MetadataViews.ExternalURL} = {}
		for key in info.socials.keys {
			socialMap[key] = MetadataViews.ExternalURL(info.socials[key]!)
		}

		let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: info.name,
            description: info.description,
			externalURL: MetadataViews.ExternalURL(url: info.externalURL),
			squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(hash: info.squareImageHash, path:nil), mediaType: "image"),
            bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(hash: info.bannerHash, path:nil), mediaType: "image"),
            socials: socialMap
		)

		var saleInfo : [FindPack.SaleInfo] = []
		for key in info.saleInfo {
			saleInfo.append(key.generateSaleInfo())
		}

		let royaltyItems : [MetadataViews.Royalty] = []
		for i, r in info.primaryRoyalty {
			let wallet = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			royaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: r.cut, description: r.description))
		}

		let primaryRoyalties = MetadataViews.Royalties(royaltyItems)

		let secondaryRoyaltyItems : [MetadataViews.Royalty] = []
		for i, r in info.secondaryRoyalty {
			let wallet = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			secondaryRoyaltyItems.append(MetadataViews.Royalty(receiver: wallet, cut: r.cut, description: r.description))
		}

		let secondaryRoyalty = MetadataViews.Royalties(secondaryRoyaltyItems)

		let metadata = FindPack.Metadata(
			name: info.name,
			description: info.description,
			thumbnailUrl: nil,
			thumbnailHash: info.squareImageHash,
			wallet: self.wallet,
			openTime: info.openTime,
			walletType: CompositeType(info.paymentType)!,
			itemTypes: self.types,
			providerCaps: self.providerCaps,
			requiresReservation: info.requiresReservation,
			storageRequirement: info.storageRequirement,
			saleInfos: saleInfo,
			primarySaleRoyalties: primaryRoyalties,
			royalties: secondaryRoyalty,
			collectionDisplay: collectionDisplay,
			packFields: info.packFields,
			extraData: {}
		)

		let input : {UInt64 : FindPack.Metadata} = {info.typeId : metadata}

		FindForge.addContractData(lease: self.lease, forgeType: Type<@FindPack.Forge>() , data: input)
	}
}

