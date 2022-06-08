import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub contract FindMetadataFactory {

	pub struct MetadataCollectionItem {
		pub let id:UInt64
		pub let typeIdentifier: String
		pub let uuid: UInt64 
		pub let name: String
		pub let image: String
		pub let url: String
		pub let contentTypes:[String]
		pub let rarity:String
		//Refine later 
		pub let medias: [MetadataViews.Media]
		pub let collection: String // <- This will be Alias unless they want something else
		pub let tag: {String : String}
		pub let scalar: {String : UFix64}

		init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentTypes: [String], rarity: String, medias: [MetadataViews.Media], collection: String, tag: {String : String}, scalar: {String : UFix64}) {
			self.id=id
			self.typeIdentifier = type.identifier
			self.uuid = uuid
			self.name=name
			self.url=url
			self.image=image
			self.contentTypes=contentTypes
			self.rarity=rarity
			self.medias=medias
			self.collection=collection
			self.tag=tag
			self.scalar=scalar
		}
	}

	pub fun getNFTs(ownerAddress: Address, ids: {String:[UInt64]}): [MetadataCollectionItem] {
		let account= getAccount(ownerAddress)
		let items : [MetadataCollectionItem] = []


		for nftInfo in NFTRegistry.getNFTInfoAll().values {
			let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo.publicPath)
			if resolverCollectionCap.check() {
				continue;
			}
			let collection = resolverCollectionCap.borrow()!
			for id in collection.getIDs() {
				let nft = collection.borrowViewResolver(id: id) 

				if let display= FindViews.getDisplay(nft) {
					var externalUrl=nftInfo.externalFixedUrl

					if let externalUrlViw=FindViews.getExternalURL(nft) { 
						externalUrl=externalUrlViw.url
					}

					var rarity=""
					if let r = FindViews.getRarity(nft) {
						rarity=r.rarityName
					}

					var tag : {String : String}={}
					if let t= FindViews.getTags(nft) {
						tag=t.getTag()
					}			

					var scalar : {String : UFix64}={}
					if let s= FindViews.getScalar(nft) {
						scalar=s.getScalar()
					}			

					var medias : [MetadataViews.Media] = []
					if let m= FindViews.getMedias(nft) {
						medias=m.items
					}	

					let cotentTypes : [String] = []
					for media in medias {
						cotentTypes.append(media.mediaType)
					}

					let item = MetadataCollectionItem(
						id: id,
						type: nft.getType() ,
						uuid: nft.uuid ,
						name: display.name,
						image: display.thumbnail.uri(),
						url: externalUrl,
						contentTypes: cotentTypes,
						rarity: rarity,
						medias: medias,
						collection: nftInfo.alias,
						tag: tag,
						scalar: scalar
					)
					items.append(item)
				}
			}
		}
		return items
	}

	pub fun getNFTIDs(ownerAddress: Address): {String: [UInt64]} {
		let account= getAccount(ownerAddress)
		let registryData = NFTRegistry.getNFTInfoAll()

		let collections : {String:[UInt64]} ={}
		for item in registryData.values {
			let optCap = account.getCapability<&{MetadataViews.ResolverCollection}>(item.publicPath)
			if !optCap.check() {
				continue
			}
			let col=optCap!.borrow()!
			
			let ids=col.getIDs()
			let alias=item.alias
			if ids.length != 0 {
				collections[alias]=ids
			}
		}
		return collections
	}
}
