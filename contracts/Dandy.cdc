import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Profile from "../contracts/Profile.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"


pub contract Dandy: NonFungibleToken {

	pub let DandyStoragePath: StoragePath
	pub let DandyPublicPath: PublicPath
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

	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}
	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String
		access(contract) let minterPlatform: MinterPlatform


		init(initID: UInt64, name: String, schemas: {String: ViewInfo},  minterPlatform: MinterPlatform) {
			self.id = initID
			self.schemas=schemas
			self.minterPlatform=minterPlatform
			self.name=name
		}

		pub fun getViews() : [Type] {

			var views : [Type]=[]
			views.append(Type<MinterPlatform>())
			views.append(Type<String>())
			views.append(Type<{TypedMetadata.Royalty}>())

			//if any specific here they will override
			for s in self.schemas.keys {
				if !views.contains(self.schemas[s]!.typ) {
					views.append(self.schemas[s]!.typ)
				}
			}

			//ViewConverter: If there are any viewconverters that add new types that can be resolved add them
			for v in views {
				if Dandy.viewConverters.containsKey(v.identifier) {
					for converter in Dandy.viewConverters[v.identifier]! {
						//I wants sets in cadence...
						if !views.contains(converter.to){ 
							views.append(converter.to)
						}
					}
				}
			}

			return views
		}

		access(self) fun resolveRoyalties() : AnyStruct{TypedMetadata.Royalty} {
			let royalties : {String : RoyaltyItem } = { }

			if self.schemas.containsKey(Type<RoyaltyItem>().identifier) {
				royalties["royalty"] = self.schemas[Type<RoyaltyItem>().identifier]!.result as! RoyaltyItem
			}

			if self.schemas.containsKey(Type<Royalties>().identifier) {
				let multipleRoylaties=self.schemas[Type<Royalties>().identifier]!.result as! Royalties
				for royalty in multipleRoylaties.royalty.keys {
					royalties[royalty] =  multipleRoylaties.royalty[royalty]
				}
			}

			let royalty=RoyaltyItem(receiver : "find", cut: self.minterPlatform.platformPercentCut)
			royalties["platform"]= royalty
			return Royalties(royalties)
		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		pub fun resolveView(_ type: Type): AnyStruct {

			if type == Type<MinterPlatform>() {
				return self.minterPlatform
			}


			if type == Type<{TypedMetadata.Royalty}>() {
				return self.resolveRoyalties()
			}


			if type == Type<String>() {
				return self.name
			}

			//TODO: this is very naive, will not work with interface types aso
			if self.schemas.keys.contains(type.identifier) {
				return self.schemas[type.identifier]!.result
			}

			//Viewconverter: This is an example on how you as the last step in resolveView can check if there are converters for your type and run them
			for converterValue in Dandy.viewConverters.keys {
				for converter in Dandy.viewConverters[converterValue]! {
					if converter.to == type {
						let value= self.resolveView(converter.from)
						return converter.convert(value)
					}
				}
			}
			return nil
		}

	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
			return nft as! &Dandy.NFT
		}

		destroy() {
			destroy self.ownedNFTs 
		}
	}

	//TODO: I think this needs a capability to a forge
	//TODO: I think this needs to be a resource, so that others cannot create it
	pub struct MinterPlatform {
		pub let platformPercentCut: UFix64
		pub let name: String

		init(name: String, platformPercentCut: UFix64) {
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

		let nft <-  create NFT(initID: Dandy.totalSupply, name: name, schemas:views, minterPlatform: platform)
		Dandy.totalSupply = Dandy.totalSupply + 1
		return <-  nft
	}

	access(account) fun setViewConverters(from: Type, converters: [AnyStruct{ViewConverter}]) {
		Dandy.viewConverters[from.identifier] = converters
	}

	//THis is not used right now but might be here for white label things
	pub resource Forge {
		access(contract) let platform: MinterPlatform

		init(platform: MinterPlatform) {
			self.platform=platform
		}

		pub fun mintNFT(name: String, schemas: [AnyStruct]) : @NFT {
			return <- Dandy.mintNFT(platform: self.platform, name: name, schemas: schemas)
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub struct Royalties : TypedMetadata.Royalty {
		pub let royalty: { String : RoyaltyItem}
		init(_ royalty: {String : RoyaltyItem}) {
			self.royalty=royalty
		}

		pub fun calculateRoyalty(type:Type, amount:UFix64) : UFix64? {
			var sum:UFix64=0.0
			for key in self.royalty.keys {
				let item= self.royalty[key]!
				if let profile=FIND.lookup(item.receiver) {
					if profile.supportedFungigleTokenTypes().contains(type) {
						sum=sum+amount*item.cut
					}
				}
			}
			return sum
		}

		// TODO: test this!
		pub fun distributeRoyalty(vault: @FungibleToken.Vault) {
			let totalAmount=vault.balance
			var sumCuts:UFix64=0.0
			for key in self.royalty.keys {
				let item= self.royalty[key]!
				if let profile=FIND.lookup(item.receiver) {
					if profile.supportedFungigleTokenTypes().contains(vault.getType()) {
						sumCuts=sumCuts+item.cut
					}
				}
			}
			

			let totalKeys=self.royalty.keys.length
			var currentKey=1
			var lastReceiver: Capability<&{FungibleToken.Receiver}>?=nil
			for key in self.royalty.keys {
				let item= self.royalty[key]!
				let relativeCut=item.cut / sumCuts

				if let profile=FIND.lookup(item.receiver) {
					if profile.supportedFungigleTokenTypes().contains(vault.getType()) {
						let address=profile.asProfile().address
						let receiver=Profile.findWalletCapability(address)
						if currentKey!=totalKeys {
							//EMIT and event here
							receiver.borrow()!.deposit(from: <-  vault.withdraw(amount: totalAmount*relativeCut))
						} else { 
							//we cannot calculate the last cut as it will have rounding errors
							lastReceiver=receiver
						}

					}
				}
				currentKey=currentKey+1
			}
			if let r=lastReceiver {
				//EMIT and event here
				r.borrow()!.deposit(from: <-  vault)
			}else {
				destroy vault
			}
		}

		pub fun displayRoyalty() : String?  {
			var text=""
			for key in self.royalty.keys {
				let item= self.royalty[key]!
				let address=FIND.lookupAddress(item.receiver)
				if address != nil {
					text.concat(key).concat(" ").concat((item.cut * 100.0).toString()).concat("%\n")
				} else {
					text.concat(item.receiver).concat(" is not an active find name so cut of ").concat((item.cut * 100.0).toString()).concat("% is ignored\n")
				}
			}
			return text
		}
	}

	pub struct RoyaltyItem{
		pub let receiver: String
		pub let cut: UFix64

		init(receiver: String, cut: UFix64) {
			self.cut=cut
			self.receiver=receiver
		}
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
		self.DandyPublicPath = /public/findDandy
		self.DandyStoragePath = /storage/findDandy
		self.viewConverters={}

		emit ContractInitialized()
	}
}
