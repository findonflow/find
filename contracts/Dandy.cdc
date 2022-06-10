import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub contract Dandy: NonFungibleToken {

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub let ForgeStoragePath: StoragePath
	pub let ForgePublicPath: PublicPath
	pub var totalSupply: UInt64


	/*store all valid type converters for Dandys
	This is to be able to make the contract compatible with the forthcomming NFT standard. 

	If a Dandy supports a type with the same Identifier as a key here all the ViewConverters convertTo types are added to the list of available types
	When resolving a type if the Dandy does not itself support this type check if any viewConverters do
	*/
	access(account) var viewConverters: {String: [{ViewConverter}]}

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, minter:String, name:String, description:String)

	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}

	pub struct DandyInfo {
		pub let name: String
		pub let description: String
		pub let thumbnail: MetadataViews.Media
		pub let schemas: [AnyStruct]
		pub let externalUrlPrefix:String?

		init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: [AnyStruct], externalUrlPrefix:String?) {
			self.name=name 
			self.description=description 
			self.thumbnail=thumbnail 
			self.schemas=schemas 
			self.externalUrlPrefix=externalUrlPrefix 
		}
	}
	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		access(self) var nounce: UInt64

		access(self) var primaryCutPaid: Bool
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String
		access(contract) let description: String
		access(contract) let thumbnail: MetadataViews.Media
		access(contract) let minterPlatform: FIND.MinterPlatform


		init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: {String: ViewInfo},  minterPlatform: FIND.MinterPlatform, externalUrlPrefix: String?) {

			self.id = self.uuid
			self.schemas=schemas
			self.thumbnail=thumbnail
			self.minterPlatform=minterPlatform
			self.name=name
			self.description=description
			self.nounce=0
			self.primaryCutPaid=false
			if externalUrlPrefix != nil {
				let mvt = Type<MetadataViews.ExternalURL>()
				self.schemas[mvt.identifier] = ViewInfo(typ:mvt, result: MetadataViews.ExternalURL(externalUrlPrefix!.concat("/").concat(self.id.toString())))
			}
		}

		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}


		pub fun getViews() : [Type] {

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

			let royalty=MetadataViews.Royalty(receiver : self.minterPlatform.platform, cut: self.minterPlatform.platformPercentCut, description:"platform")
			royalties.append(royalty)

			return MetadataViews.Royalties(cutInfos:royalties)
		}

		pub fun resolveDisplay() : MetadataViews.Display {
			return MetadataViews.Display(
				name: self.name,
				description: self.description,
				thumbnail: self.thumbnail.file
			)
		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		//NB! This will _not_ error out if it does not return Optional!
		pub fun resolveView(_ type: Type): AnyStruct? {

			if type == Type<MetadataViews.NFTCollectionDisplay>() {
				let externalURL = MetadataViews.ExternalURL(self.minterPlatform.externalURL)
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.minterPlatform.squareImage), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.minterPlatform.bannerImage), mediaType: "image")
				return MetadataViews.NFTCollectionDisplay(name: self.minterPlatform.name, description: self.minterPlatform.description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: {})
			}

			if type == Type<MetadataViews.NFTCollectionData>() {
				return MetadataViews.NFTCollectionData(storagePath: Dandy.CollectionStoragePath,
				publicPath: Dandy.CollectionPublicPath,
				providerPath: Dandy.CollectionPrivatePath,
				publicCollection: Type<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(),
				publicLinkedType: Type<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(),
				providerLinkedType: Type<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Dandy.createEmptyCollection()}
				)
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


	pub resource interface CollectionPublic {
		pub fun getIDsFor(minter: String): [UInt64] 
		pub fun getMinters(): [String] 
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		// Mapping of {Minter Platform Name : [NFT ID]}
		access(self) let nftIndex: {String : {UInt64 : Bool}}


		init () {
			self.ownedNFTs <- {}
			self.nftIndex = {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			let dandyToken <- token as! @NFT
			let minterName = dandyToken.minterPlatform.name 
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
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let minterName = token.minterPlatform.name 
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

		pub fun getMinters(): [String] {
			return self.nftIndex.keys
		}

		pub fun getIDsFor(minter: String): [UInt64] {
			return self.nftIndex[minter]?.keys ?? []
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}

			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}

			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			return nft as! &Dandy.NFT
		}

		pub fun borrow(_ id: UInt64): &NFT {
			pre {
				self.ownedNFTs[id] != nil : "NFT does not exist"
			}
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			return nft as! &Dandy.NFT
		}

		destroy() {
			destroy self.ownedNFTs 
		}
	}

	access(account) fun mintNFT(name: String, description: String, thumbnail: MetadataViews.Media,  platform:FIND.MinterPlatform, schemas: [AnyStruct], externalUrlPrefix:String?) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			//if you send in display we ignore it, this will be made for you
			if s.getType() != Type<MetadataViews.Display>() {
				views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
			}
		}

		let nft <-  create NFT(name: name, description:description,thumbnail: thumbnail, schemas:views, minterPlatform: platform, externalUrlPrefix:externalUrlPrefix)

		emit Minted(id:nft.id, minter:nft.minterPlatform.name, name: name, description:description)
		return <-  nft
	}

	access(account) fun setViewConverters(from: Type, converters: [AnyStruct{ViewConverter}]) {
		Dandy.viewConverters[from.identifier] = converters
	}

	pub resource ForgeMinter : FIND.ForgeMinter {
		access(contract) let platform: FIND.MinterPlatform

		init(platform: FIND.MinterPlatform) {
			self.platform=platform
		}

		access(account) fun mint(platform: FIND.MinterPlatform, data: AnyStruct) : @NonFungibleToken.NFT {
			let info = data as? DandyInfo ?? panic("The data passed in is not in form of DandyInfo.")
			return <- Dandy.mintNFT(name: info.name, description: info.description, thumbnail: info.thumbnail, platform: platform, schemas: info.schemas, externalUrlPrefix:info.externalUrlPrefix)
		}
	}

	pub fun createForge() : @Forge {
		return <- create Forge()
	}

	access(account) fun adminCreateForgeMinter(_ platform: FIND.MinterPlatform) : @ForgeMinter {
		return <- create Dandy.ForgeMinter(platform)
	}

	pub resource Forge : FIND.Forge {
		access(account) fun createForgeMinter(_ platform: FIND.MinterPlatform) : @ForgeMinter {
			return <- Dandy.adminCreateForgeMinter(platform)
		}
	}

	pub fun getForgeCapability() : Capability<&{FIND.Forge}> {
		return self.account.getCapability<&{FIND.Forge}>(Dandy.ForgePublicPath)
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}


	/// This struct interface is used on a contract level to convert from one View to another. 
	/// See Dandy nft for an example on how to convert one type to another
	pub struct interface ViewConverter {
		pub let to: Type
		pub let from: Type

		pub fun convert(_ value:AnyStruct) : AnyStruct
	}

	init() {
		// Initialize the total supply
		self.totalSupply=0
		self.CollectionPublicPath = /public/findDandy
		self.CollectionPrivatePath = /private/findDandy
		self.CollectionStoragePath = /storage/findDandy
		self.ForgeStoragePath = /storage/findDandyForge
		self.ForgePublicPath = /public/findDandyForge
		self.viewConverters={}

		self.account.save(<- Dandy.createForge(), to: Dandy.ForgeStoragePath)
		self.account.link<&Dandy.Forge{FIND.Forge}>(Dandy.ForgePublicPath, target: Dandy.ForgeStoragePath)

		emit ContractInitialized()
	}
}
