import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"

import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	return fetchNFTCatalog(user: user, collectionIDs: collectionIDs)
}

access(all) struct NFTView {
	pub let id: UInt64
	pub let display: MetadataViews.Display?
	pub let collectionDisplay: MetadataViews.NFTCollectionDisplay?
	pub var rarity:MetadataViews.Rarity?
	pub var editions: MetadataViews.Editions?
	pub var serial: UInt64?
	pub var traits: MetadataViews.Traits?
	pub let soulBounded: Bool 
	pub let nftType: Type

	init(
		id : UInt64,
		display : MetadataViews.Display?,
		editions : MetadataViews.Editions?,
		rarity:MetadataViews.Rarity?,
		serial: UInt64?,
		traits: MetadataViews.Traits?,
		collectionDisplay: MetadataViews.NFTCollectionDisplay?,
		soulBounded: Bool ,
		nftType: Type
	) {
		self.id = id
		self.display = display
		self.editions = editions
		self.rarity = rarity
		self.serial = serial
		self.traits = traits
		self.collectionDisplay = collectionDisplay
		self.soulBounded = soulBounded
		self.nftType = nftType
	}
}

access(all) getNFTs(ownerAddress: Address, ids: {String : [UInt64]}) : [NFTView] {

	let account = getAuthAccount(ownerAddress)

	if account.balance == 0.0 {
		return []
	}

	let results : [NFTView] = []
	for collectionKey in ids.keys {
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let storagePath = catalogEntry.collectionData.storagePath
		let ref= account.borrow<&{ViewResolver.ResolverCollection}>(from: storagePath)
		if ref != nil{
			for id in ids[collectionKey]! {
				// results.append(MetadataViews.getNFTView(id:id, viewResolver: ref!.borrowViewResolver(id:id)!))
				let viewResolver = ref!.borrowViewResolver(id:id)!

				var traitsStruct : MetadataViews.Traits? = nil 

				if let traits = MetadataViews.getTraits(viewResolver) {
					if let trait = getTrait(viewResolver) {
						var check = false 
						for item in traits.traits {
							if item.name == trait.name {
								check = true 
								break
							}
							if !check {
								let array = traits.traits
								array.append(trait)

								traitsStruct = cleanUpTraits(array)
							}
						}
					} else {
						traitsStruct = cleanUpTraits(traits.traits)
					}
				} else {
					if let trait = getTrait(viewResolver) {
						traitsStruct = cleanUpTraits([trait])
					}
				}

				var editionStruct : MetadataViews.Editions? = nil 

				if let editions = MetadataViews.getEditions(viewResolver) {
					if let edition = getEdition(viewResolver) {
						var check = false
						for item in editions.infoList {
							if item.name == edition.name && item.number == edition.number && item.max == edition.max {
								check = true
								break
							}
						}
						// If the edition does not exist in editions, add it in
						if !check {
							let array = editions.infoList 
							array.append(edition)
							editionStruct = MetadataViews.Editions(array)
						}
					} else {
					// If edition does not exist OR edition is already in editions , append it to views and continue
						editionStruct = editions
					}
				} else if let edition = getEdition(viewResolver) {
						editionStruct = MetadataViews.Editions([edition])
				}

				results.append(
					NFTView(
						id : id,
						display: MetadataViews.getDisplay(viewResolver),
						editions : editionStruct,
						rarity : MetadataViews.getRarity(viewResolver),
						serial :  MetadataViews.getSerial(viewResolver)?.number,
						traits : traitsStruct,
						collectionDisplay : MetadataViews.getNFTCollectionDisplay(viewResolver),
						soulBounded : FindViews.checkSoulBound(viewResolver),
						nftType : viewResolver.getType()
					)
				)
			}
		}
	}
	return results
}

access(all) struct CollectionReport {
	pub let items : {String : [MetadataCollectionItem]} 
	pub let collections : {String : Int} // mapping of collection to no. of ids 
	pub let extraIDs : {String : [UInt64]} 

	init(items: {String : [MetadataCollectionItem]},  collections : {String : Int}, extraIDs : {String : [UInt64]} ) {
		self.items=items 
		self.collections=collections 
		self.extraIDs=extraIDs
	}
}

access(all) struct MetadataCollectionItem {
	pub let id:UInt64
	pub let name: String
	pub let collection: String // <- This will be Alias unless they want something else
	pub let subCollection: String? // <- This will be Alias unless they want something else
	pub let nftDetailIdentifier: String
	pub let soulBounded: Bool 

	pub let media  : String
	pub let mediaType : String 
	pub let source : String 

	pub var rarity:MetadataViews.Rarity?
	pub var editions: MetadataViews.Editions?
	pub var serial: UInt64?
	pub var traits: MetadataViews.Traits?

	init(id:UInt64, 
		 name: String, 
		 collection: String, 
		 subCollection: String?, 
		 media  : String, 
		 mediaType : String, 
		 source : String, 
		 nftDetailIdentifier: String, 
		 editions : MetadataViews.Editions?,
		 rarity:MetadataViews.Rarity?,
		 serial: UInt64?,
		 traits: MetadataViews.Traits?,
		 soulBounded: Bool 
		 ) {
		self.id=id
		self.name=name 
		self.collection=collection 
		self.subCollection=subCollection 
		self.media=media 
		self.mediaType=mediaType 
		self.source=source
		self.nftDetailIdentifier=nftDetailIdentifier
		self.editions=editions
		self.rarity=rarity
		self.serial=serial
		self.traits=traits
		self.soulBounded=soulBounded
	}
}

// Helper function 

access(all) resolveAddress(user: String) : PublicAccount? {
	let address = FIND.resolve(user)
	if address == nil {
		return nil
	}
	return getAccount(address!)
}


//////////////////////////////////////////////////////////////
// Fetch Specific Collections in Find Catalog
//////////////////////////////////////////////////////////////
access(all) fetchNFTCatalog(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	let source = "NFTCatalog"
	let account = resolveAddress(user: user)
	if account == nil { return {} }

	let items : {String : [MetadataCollectionItem]} = {}

	let fetchingIDs = collectionIDs


	for project in fetchingIDs.keys {

		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:project)!
		let projectName = catalogEntry.contractName

		let returnedNFTs = getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

		var collectionItems : [MetadataCollectionItem] = []
		for nft in returnedNFTs {
			if nft == nil {
				continue
			}

			var subCollection = ""
			if project != nft!.collectionDisplay!.name {
			 subCollection = nft!.collectionDisplay!.name
			}

			var name = nft!.display!.name 
			if name == "" {
				name = projectName
			}

			if nft.editions != nil && nft.editions!.infoList.length > 0 {
				let edition = nft.editions!.infoList[0].number.toString()
				// check if the name ends with "editionNumber"
				// If the name ends with "editionNumber", we do not concat the edition
				if name.length > edition.length && name.slice(from: name.length - edition.length, upTo: name.length) != edition {
					name = name.concat("#").concat(nft.editions!.infoList[0].number.toString())
				}
			}
			
			let item = MetadataCollectionItem(
				id: nft!.id,
				name: name,
				collection: project,
				subCollection: subCollection, 
				media: nft!.display!.thumbnail.uri(),
				mediaType: "image/png",
				source: source, 
				nftDetailIdentifier: nft!.nftType.identifier, 
				editions : nft!.editions,
				rarity: nft!.rarity,
				serial: nft!.serial,
				traits: nft!.traits,
				soulBounded: nft.soulBounded
			)
			collectionItems.append(item)
		}

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return items
}

access(all) cleanUpTraits(_ traits: [MetadataViews.Trait]) : MetadataViews.Traits {
	let dateValues  = {"Date" : true, "Numeric":false, "Number":false, "date":true, "numeric":false, "number":false}

	let array : [MetadataViews.Trait] = []

	for i , trait in traits {
		let displayType = trait.displayType ?? "string"
		if let isDate = dateValues[displayType] {
			if isDate {
				array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Date", rarity: trait.rarity))
			} else {
				array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Numeric", rarity: trait.rarity))
			}
		} else {
			if let value = trait.value as? Bool {
				if value {
					array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Bool", rarity: trait.rarity))
				}else {
					array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "Bool", rarity: trait.rarity))
				}
			} else if let value = trait.value as? String {
				array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "String", rarity: trait.rarity))
			} else {
				array.append(MetadataViews.Trait(name: trait.name, value: trait.value, displayType: "String", rarity: trait.rarity))
			}
		}
	}
	return MetadataViews.Traits(array)
}

access(all) getTrait(_ viewResolver: &{ViewResolver.Resolver}) : MetadataViews.Trait? {
	if let view = viewResolver.resolveView(Type<MetadataViews.Trait>()) {
		if let v = view as? MetadataViews.Trait {
			return v
		}
	}
	return nil
}

access(all) getEdition(_ viewResolver: &{ViewResolver.Resolver}) : MetadataViews.Edition? {
	if let view = viewResolver.resolveView(Type<MetadataViews.Edition>()) {
		if let v = view as? MetadataViews.Edition {
			return v
		}
	}
	return nil
}
