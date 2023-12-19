import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "./FindViews.cdc"
import FindForge from "./FindForge.cdc"

access(all) contract Dandy: NonFungibleToken {

	access(all) let CollectionStoragePath: StoragePath
	access(all) let CollectionPrivatePath: PrivatePath
	access(all) let CollectionPublicPath: PublicPath
	access(all) var totalSupply: UInt64

	/*store all valid type converters for Dandys
	This is to be able to make the contract compatible with the forthcomming NFT standard. 

	If a Dandy supports a type with the same Identifier as a key here all the ViewConverters convertTo types are added to the list of available types
	When resolving a type if the Dandy does not itself support this type check if any viewConverters do
	*/
	access(account) var viewConverters: {String: [{ViewConverter}]}

	access(all) event ContractInitialized()
	access(all) event Withdraw(id: UInt64, from: Address?)
	access(all) event Deposit(id: UInt64, to: Address?)
	access(all) event Minted(id:UInt64, minter:String, name:String, description:String)

	access(all) struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}

	access(all) struct DandyInfo {
		access(all) let name: String
		access(all) let description: String
		access(all) let thumbnail: MetadataViews.Media
		access(all) let schemas: [AnyStruct]
		access(all) let externalUrlPrefix:String?

		init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: [AnyStruct], externalUrlPrefix:String?) {
			self.name=name 
			self.description=description 
			self.thumbnail=thumbnail 
			self.schemas=schemas 
			self.externalUrlPrefix=externalUrlPrefix 
		}
	}
	access(all) resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {
		access(all) let id: UInt64
		access(self) var nounce: UInt64

		access(self) var primaryCutPaid: Bool
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String
		access(contract) let description: String
		access(contract) let thumbnail: MetadataViews.Media
		access(contract) let platform: FindForge.MinterPlatform

		init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: {String: ViewInfo}, platform: FindForge.MinterPlatform, externalUrlPrefix: String?) {
			self.id = self.uuid
			self.schemas=schemas
			self.thumbnail=thumbnail
			self.name=name
			self.description=description
			self.nounce=0
			self.primaryCutPaid=false
			self.platform=platform
			if externalUrlPrefix != nil {
				let mvt = Type<MetadataViews.ExternalURL>()
				self.schemas[mvt.identifier] = ViewInfo(typ:mvt, result: MetadataViews.ExternalURL(externalUrlPrefix!.concat("/").concat(self.id.toString())))
			}
		}

		access(all) increaseNounce() {
			self.nounce=self.nounce+1
		}

		access(all) getMinterPlatform() : FindForge.MinterPlatform {
			if let fetch = FindForge.getMinterPlatform(name: self.platform.name, forgeType: Dandy.getForgeType()) {
				
				let platform = &self.platform as &FindForge.MinterPlatform
				platform.updateExternalURL(fetch.externalURL)
				platform.updateDesription(fetch.description)
				platform.updateSquareImagen(fetch.squareImage)
				platform.updateBannerImage(fetch.bannerImage)
				platform.updateSocials(fetch.socials)

			}

			return self.platform
		}

		access(all) getViews() : [Type] {

			var views : [Type]=[]
			views.append(Type<FindViews.Nounce>())
			views.append(Type<MetadataViews.NFTCollectionData>())
			views.append(Type<MetadataViews.NFTCollectionDisplay>())
			views.append(Type<MetadataViews.Display>())
			views.append(Type<MetadataViews.Royalties>())

			//if any specific here they will override
			for s in self.schemas.keys {
				if !views.contains(self.schemas[s]!.typ) {
					views.append(self.schemas[s]!.typ)
				}
			}

			//ViewConverter: If there are any viewconverters that add new types that can be resolved add them
			// for v in views {
			// 	if Dandy.viewConverters.containsKey(v.identifier) {
			// 		for converter in Dandy.viewConverters[v.identifier]! {
			// 			//I wants sets in cadence...
			// 			if !views.contains(converter.to){ 
			// 				views.append(converter.to)
			// 			}
			// 		}
			// 	}
			// }

			return views
		}

		access(self) fun resolveRoyalties() : MetadataViews.Royalties {
			let royalties : [MetadataViews.Royalty] = []

			if self.schemas.containsKey(Type<MetadataViews.Royalties>().identifier) {
				let multipleRoylaties=self.schemas[Type<MetadataViews.Royalties>().identifier]!.result as! MetadataViews.Royalties
				royalties.appendAll(multipleRoylaties.getRoyalties())
			}

			if self.platform.minterCut != nil && self.platform.minterCut! != 0.0 {
				let royalty = MetadataViews.Royalty(receiver: self.platform.getMinterFTReceiver(), cut: self.platform.minterCut!, description: "creator")
				royalties.append(royalty)
			}

			if self.platform.platformPercentCut != 0.0 {
				let royalty = MetadataViews.Royalty(receiver: self.platform.platform, cut: self.platform.platformPercentCut, description: "find forge")
				royalties.append(royalty)
			}

			return MetadataViews.Royalties(royalties)
		}

		access(all) resolveDisplay() : MetadataViews.Display {
			return MetadataViews.Display(
				name: self.name,
				description: self.description,
				thumbnail: self.thumbnail.file
			)
		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		//NB! This will _not_ error out if it does not return Optional!
		access(all) resolveView(_ type: Type): AnyStruct? {

			if type == Type<MetadataViews.NFTCollectionDisplay>() {
				let minterPlatform = self.getMinterPlatform()
				let externalURL = MetadataViews.ExternalURL(minterPlatform.externalURL)
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.squareImage), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.bannerImage), mediaType: "image")

				let socialMap : {String : MetadataViews.ExternalURL} = {}
				for social in minterPlatform.socials.keys {
					socialMap[social] = MetadataViews.ExternalURL(minterPlatform.socials[social]!)
				}
				return MetadataViews.NFTCollectionDisplay(name: minterPlatform.name, description: minterPlatform.description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
			}


			if type == Type<FindViews.Nounce>() {
				return FindViews.Nounce(self.nounce)
			}

			if type == Type<MetadataViews.Royalties>() {
				return self.resolveRoyalties()
			}

			if type == Type<MetadataViews.Display>() {
				return self.resolveDisplay()
			}

			if self.schemas.keys.contains(type.identifier) {
				return self.schemas[type.identifier]!.result
			}

			if type == Type<MetadataViews.NFTCollectionData>() {
				return MetadataViews.NFTCollectionData(
					storagePath: Dandy.CollectionStoragePath,
					publicPath: Dandy.CollectionPublicPath,
					providerPath: Dandy.CollectionPrivatePath,
					publicCollection: Type<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(),
					publicLinkedType: Type<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(),
					providerLinkedType: Type<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(),
					createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Dandy.createEmptyCollection()}
				)
			}
			//Viewconverter: This is an example on how you as the last step in resolveView can check if there are converters for your type and run them
			// for converterValue in Dandy.viewConverters.keys {
			// 	for converter in Dandy.viewConverters[converterValue]! {
			// 		if converter.to == type {
			// 			let value= self.resolveView(converter.from)
			// 			return converter.convert(value)
			// 		}
			// 	}
			// }
			return nil
		}

	}


	access(all) resource interface CollectionPublic {
		access(all) getIDsFor(minter: String): [UInt64] 
		access(all) getMinters(): [String] 
	}

	access(all) resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection, CollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		// Mapping of {Minter Platform Name : [NFT ID]}
		access(self) let nftIndex: {String : {UInt64 : Bool}}


		init () {
			self.ownedNFTs <- {}
			self.nftIndex = {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		access(all) withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT. withdrawID : ".concat(withdrawID.toString()))

			let dandyToken <- token as! @NFT
			let minterPlatform = dandyToken.getMinterPlatform()
			let minterName = minterPlatform.name 
			if self.nftIndex.containsKey(minterName) {
				self.nftIndex[minterName]!.remove(key: withdrawID)
				if self.nftIndex[minterName]!.length < 1 {
					self.nftIndex.remove(key: minterName)
				}
			}

			emit Withdraw(id: dandyToken.id, from: self.owner?.address)

			return <-dandyToken
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all) deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let minterPlatform = token.getMinterPlatform()
			let minterName = minterPlatform.name 
			if self.nftIndex.containsKey(minterName) {
				self.nftIndex[minterName]!.insert(key: token.id, false)
			} else {
				self.nftIndex[minterName] = {}
				self.nftIndex[minterName]!.insert(key: token.id, false)
			}

			token.increaseNounce()

			let id: UInt64 = token.id

			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		access(all) getMinters(): [String] {
			return self.nftIndex.keys
		}

		access(all) getIDsFor(minter: String): [UInt64] {
			return self.nftIndex[minter]?.keys ?? []
		}

		// getIDs returns an array of the IDs that are in the collection
		access(all) getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			if self.ownedNFTs[id] == nil {
				panic("NFT does not exist. ID : ".concat(id.toString()))
			}

			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		access(all) borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
			if self.ownedNFTs[id] == nil {
				panic("NFT does not exist. ID : ".concat(id.toString()))
			}

			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			return nft as! &Dandy.NFT
		}

		access(all) borrow(_ id: UInt64): &NFT {
			if self.ownedNFTs[id] == nil {
				panic("NFT does not exist. ID : ".concat(id.toString()))
			}
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			return nft as! &Dandy.NFT
		}

		destroy() {
			destroy self.ownedNFTs 
		}
	}

	access(account) fun mintNFT(name: String, description: String, thumbnail: MetadataViews.Media,  platform:FindForge.MinterPlatform, schemas: [AnyStruct], externalUrlPrefix:String?) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			//if you send in display we ignore it, this will be made for you
			if s.getType() != Type<MetadataViews.Display>() {
				views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
			}
		}

		let nft <-  create NFT(name: name, description:description,thumbnail: thumbnail, schemas:views, platform: platform, externalUrlPrefix:externalUrlPrefix)

		//TODO: remove this
		emit Minted(id:nft.id, minter:nft.platform.name, name: name, description:description)
		return <-  nft
	}

	/*
	access(account) fun setViewConverters(from: Type, converters: [AnyStruct{ViewConverter}]) {
		Dandy.viewConverters[from.identifier] = converters
	}
	*/

	//TODO: do we want to store minter 
	access(all) resource Forge: FindForge.Forge {
		access(all) mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
			let info = data as? DandyInfo ?? panic("The data passed in is not in form of DandyInfo.")
			return <- Dandy.mintNFT(name: info.name, description: info.description, thumbnail: info.thumbnail, platform: platform, schemas: info.schemas, externalUrlPrefix:info.externalUrlPrefix)
		}

		access(all) addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			// not used here 

			panic("Not supported for Dandy Contract") 
        }
	}

	access(account) fun createForge() : @{FindForge.Forge} {
		return <- create Forge()
	}

	// public function that anyone can call to create a new empty collection
	access(all) createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	access(all) getForgeType() : Type {
		return Type<@Forge>()
	}

	/// This struct interface is used on a contract level to convert from one View to another. 
	/// See Dandy nft for an example on how to convert one type to another
	access(all) struct interface ViewConverter {
		access(all) let to: Type
		access(all) let from: Type

		access(all) convert(_ value:AnyStruct) : AnyStruct
	}

	init() {
		// Initialize the total supply
		self.totalSupply=0
		self.CollectionPublicPath = /public/findDandy
		self.CollectionPrivatePath = /private/findDandy
		self.CollectionStoragePath = /storage/findDandy
		self.viewConverters={}

		FindForge.addForgeType(<- create Forge())

		//TODO: Add the Forge resource aswell
		FindForge.addPublicForgeType(forgeType: Type<@Forge>())

		emit ContractInitialized()
	}
}
