import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Profile from "../contracts/Profile.cdc"

pub contract Artifact: NonFungibleToken {

	pub let ArtifactStoragePath: StoragePath
	pub let ArtifactPublicPath: PublicPath
	pub var totalSupply: UInt64


	/*store all valid type converters for Artifacts
	This is to be able to make the contract compatible with the forthcomming NFT standard. 

	If a Artifact supports a type with the same Identifier as a key here all the TypeConverters convertTo types are added to the list of available types
	When resolving a type if the Artifact does not itself support this type check if any typeConverters do
	*/
	access(account) var typeConverters: {String: [Capability<&{TypedMetadata.TypeConverter}>]}

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}

	pub resource NFT: NonFungibleToken.INFT, TypedMetadata.ViewResolver {
		pub let id: UInt64
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String
		access(contract) let sharedPointer: Pointer?
		access(contract) let minterPlatform: MinterPlatform


		init(initID: UInt64, name: String, schemas: {String: ViewInfo}, sharedPointer: Pointer?, minterPlatform: MinterPlatform) {
			self.id = initID
			self.schemas=schemas
			self.sharedPointer=sharedPointer
			self.minterPlatform=minterPlatform
			self.name=name
		}

		pub fun getViews() : [Type] {

			var views : [Type]=[]
			views.append(Type<MinterPlatform>())
			views.append(Type<Profiles>())
			views.append(Type<String>())
			views.append(Type<TypedMetadata.Royalties>())

			//first shared
			if let ptr = self.sharedPointer {
				for sharedView in ptr.getViews() {
					if !views.contains(sharedView) {
						views.append(sharedView)
					}
				}
			}

			//if any specific here they will override
			for s in self.schemas.keys {
				if !views.contains(self.schemas[s]!.typ) {
					views.append(self.schemas[s]!.typ)
				}
			}

			for v in views {
				if Artifact.typeConverters.containsKey(v.identifier) {
					for converter in Artifact.typeConverters[v.identifier]! {
						//this might lead to conflict if not handlded properly
						views.appendAll(converter.borrow()!.convertTo())
					}
				}
			}

			//these are locked so cannot override them
			return views
		}

		access(self) fun resolveRoyalties() : TypedMetadata.Royalties {
			let royalties : {String : TypedMetadata.Royalty } = { }
			let owner=self.minterPlatform.platform.address
			let minterProfile=self.minterPlatform.platform.borrow()!
			let wallets=minterProfile.getWallets()


			if self.schemas.containsKey(Type<TypedMetadata.Royalty>().identifier) {
				royalties["royalty"] = self.schemas[Type<TypedMetadata.Royalty>().identifier]!.result as! TypedMetadata.Royalty
			}

			if self.schemas.containsKey(Type<TypedMetadata.Royalties>().identifier) {
				let multipleRoylaties=self.schemas[Type<TypedMetadata.Royalties>().identifier]!.result as! TypedMetadata.Royalties
				for royalty in multipleRoylaties.royalty.keys {
					royalties[royalty] =  multipleRoylaties.royalty[royalty]
				}
			}

			let sharedView= self.sharedPointer?.getViews() ?? []

			if sharedView.contains(Type<TypedMetadata.Royalty>()) {
				royalties["sharedRoyalty"] = self.sharedPointer!.resolveView(Type<TypedMetadata.Royalty>()) as! TypedMetadata.Royalty
			}

			if sharedView.contains(Type<TypedMetadata.Royalties>()) {
				let multipleRoylaties=self.sharedPointer!.resolveView(Type<TypedMetadata.Royalties>()) as! TypedMetadata.Royalties
				for royalty in multipleRoylaties.royalty.keys {
					if royalty != "platform"  {
						royalties["shared-".concat(royalty)] =  multipleRoylaties.royalty[royalty]
					}
				}
			}

			let walletDicts:{ String: Capability<&{FungibleToken.Receiver}>} = {}
			for wallet in wallets {
				walletDicts[wallet.accept.identifier] = wallet.receiver
			}

			let royalty=TypedMetadata.Royalty(wallets: walletDicts, cut: self.minterPlatform.platformPercentCut,  percentage:true, owner:owner)
			royalties["platform"]= royalty
			return TypedMetadata.Royalties(royalties)

		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		pub fun resolveView(_ type: Type): AnyStruct {

			if type == Type<MinterPlatform>() {
				return self.minterPlatform
			}


			if type == Type<TypedMetadata.Royalties>() {
				return self.resolveRoyalties()
			}

			if type == Type<Profiles>() {
				let profiles: {String: Profile.UserProfile} = {}
				profiles["minter"]=self.minterPlatform.minter.borrow()!.asProfile()
				profiles["platform"]=self.minterPlatform.platform.borrow()!.asProfile()
				//TODO: if shared or vanilla has a profile add them here
				return Profiles(profiles)
			}

			if type == Type<String>() {
				return self.name
			}

			//TODO: this is very naive, will not work with interface types aso
			if self.schemas.keys.contains(type.identifier) {
				return self.schemas[type.identifier]?.result
			}

			if let ptr =self.sharedPointer {
				if ptr.getViews().contains(type) {
					let value =ptr.resolveView(type)
					return value
				}
			}

			for converterValue in Artifact.typeConverters.keys {
				for converterCap in Artifact.typeConverters[converterValue]! {
					let converter = converterCap.borrow()!
					if converter.convertTo().contains(type) {
						let value= self.resolveView(converter.convertFrom())
						return converter.convert(value)
					}
				}
			}
			let converters=Artifact.typeConverters[type.identifier]
			if converters == nil {
				return nil
			}

			for converter in converters! {


			}

			return nil
		}

	}

	pub resource interface CollectionPublic {
		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic, TypedMetadata.ViewResolverCollection  {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id

			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		}

		pub fun borrowViewResolver(id: UInt64): &{TypedMetadata.ViewResolver} {
			if self.ownedNFTs[id] != nil {
				let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
				return ref as! &NFT
			} 
			panic("could not find NFT")
		}


		destroy() {
			destroy self.ownedNFTs 
		}
	}



	pub struct MinterPlatform {
		pub let platform: Capability<&{Profile.Public}>
		pub let minter: Capability<&{Profile.Public}>
		pub let platformPercentCut: UFix64
		pub let name: String

		init(name: String, platform:Capability<&{Profile.Public}>, minter: Capability<&{Profile.Public}>, platformPercentCut: UFix64) {
			self.platform=platform
			self.minter=minter
			self.platformPercentCut=platformPercentCut
			self.name=name
		}
	}

	access(account)  fun createForge(platform: MinterPlatform) : @Forge {
		return <- create Forge(platform:platform)
	}


	access(account) fun mintNFT(platform:MinterPlatform, name: String, schemas: [AnyStruct]) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
		}

		let nft <-  create NFT(initID: Artifact.totalSupply, name: name, schemas:views, sharedPointer:nil, minterPlatform: platform)
		Artifact.totalSupply = Artifact.totalSupply + 1
		return <-  nft
	}

	//have method to mint without shared
	access(account) fun mintNFTWithSharedData(platform:MinterPlatform, name: String, schemas: [AnyStruct], sharedPointer: Pointer) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
		}

		let nft <-  create NFT(initID: Artifact.totalSupply, name: name, schemas:views, sharedPointer:sharedPointer, minterPlatform: platform)
		Artifact.totalSupply = Artifact.totalSupply + 1
		return <-  nft
	}



	access(account) fun setTypeConverter(from: Type, converters: [Capability<&{TypedMetadata.TypeConverter}>]) {
		Artifact.typeConverters[from.identifier] = converters
	}

	//THis is not used right now but might be here for white label things
	pub resource Forge {
		access(contract) let platform: MinterPlatform

		init(platform: MinterPlatform) {
			self.platform=platform
		}

		pub fun mintNFT(name: String, schemas: [AnyStruct]) : @NFT {
			return <- Artifact.mintNFT(platform: self.platform, name: name, schemas: schemas)
		}

		//have method to mint without shared
		pub fun mintNFTWithSharedData(name: String, schemas: [AnyStruct], sharedPointer: Pointer) : @NFT {
			return <- Artifact.mintNFTWithSharedData(platform: self.platform, name: name, schemas: schemas, sharedPointer: sharedPointer)
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub struct Profiles {

		pub let profiles: {String: Profile.UserProfile}

		init(_ profiles : {String: Profile.UserProfile}) {
			self.profiles=profiles
		}

		pub fun add(name: String,  profile : Profile.UserProfile) {
			self.profiles[name]=profile
		}
	}

	pub struct Pointer{
		pub let collection: Capability<&{TypedMetadata.ViewResolverCollection}>
		pub let id: UInt64
		pub let views: [Type]

		init(collection: Capability<&{TypedMetadata.ViewResolverCollection}>, id: UInt64, views: [Type]) {
			self.collection=collection
			self.id=id
			self.views=views
		}


		pub fun resolveView(_ type: Type) : AnyStruct {
			return self.collection.borrow()!.borrowViewResolver(id: self.id).resolveView(type)!
		}

		pub fun getViews() : [Type]{
			return self.views
		}
	}

	/* --- an example typeConverter --*/
	pub struct Minter {
		pub let name: String
		init(name:String) {
			self.name=name
		}
	}

	pub fun createNewMinterTypeConverter() : @MinterTypeConverter {
		return <-  create MinterTypeConverter()
	}

	pub resource MinterTypeConverter : TypedMetadata.TypeConverter {

		pub fun convert(_ value:AnyStruct) : AnyStruct {
			let converter=value as! MinterPlatform 
			return Minter(name: converter.name)
		}

		pub fun convertTo() : [Type] {
			return [Type<Minter>()]
		}

		pub fun convertFrom() :Type {
			return Type<MinterPlatform>()
		}

	}


	init() {
		// Initialize the total supply
		self.totalSupply = 0
		self.ArtifactPublicPath = /public/artifacts
		self.ArtifactStoragePath = /storage/artifacts
		self.typeConverters={}

		emit ContractInitialized()
	}
}
