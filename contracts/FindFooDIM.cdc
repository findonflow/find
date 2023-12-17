import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FindForgeOrder from "./FindForgeOrder.cdc"
import FindForgeStruct from "./FindForgeStruct.cdc"
import FindUtils from "./FindUtils.cdc"

// DIM stands for Direct Immuatble Minting, cannot mutate minted NFT states. So all nfts has to be minted in one go. 
pub contract FindFooDIM: NonFungibleToken {

	pub var totalSupply: UInt64
	pub let nftCollectionDisplay: MetadataViews.NFTCollectionDisplay

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, name: String, description: String, image: String, edition: UInt64, maxEdition: UInt64, medias: {String: String})
	pub event Burned(id: UInt64, name: String, description: String, image: String, edition: UInt64, maxEdition: UInt64, medias: {String: String})

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub let MinterStoragePath: StoragePath

	pub resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {
		pub let id: UInt64

		pub let info: FindForgeStruct.FindDIM
		access(self) let royalties: MetadataViews.Royalties

		init(
			info: FindForgeStruct.FindDIM,
			royalties: MetadataViews.Royalties
		) {
			self.id = self.uuid
			self.info=info
			self.royalties = royalties

			let i = info
			emit Minted(id: self.id, name: i.name, description: i.description, image: "ipfs://".concat(i.thumbnailHash), edition: i.edition, maxEdition: i.maxEdition, medias: i.medias)
			FindFooDIM.totalSupply = FindFooDIM.totalSupply + 1
		}

		destroy (){
			let i = self.info
			emit Burned(id: self.id, name: i.name, description: i.description, image: "ipfs://".concat(i.thumbnailHash), edition: i.edition, maxEdition: i.maxEdition, medias: i.medias)
			FindFooDIM.totalSupply = FindFooDIM.totalSupply - 1
		}

		pub fun getViews(): [Type] {
			return [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.Editions>(),
			Type<MetadataViews.Traits>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
			case Type<MetadataViews.Traits>():
				let traits = MetadataViews.Traits([])
				//scalars
				for value in self.info.scalars.keys {
					if FindUtils.hasSuffix(value, suffix: "_max"){
						continue
					}
					var r : MetadataViews.Rarity? = nil
					if self.info.scalars[value.concat("_max")] != nil || self.info.descriptions["scalars".concat(value)] != nil {
						r = MetadataViews.Rarity(score: nil, max: self.info.scalars[value.concat("_max")], description: self.info.descriptions["scalars".concat(value)] )
					}
					traits.addTrait(MetadataViews.Trait(name: value, value: self.info.scalars[value], displayType: "Number", rarity: r))
				}

				//boosts
				for value in self.info.boosts.keys {
					if FindUtils.hasSuffix(value, suffix: "_max"){
						continue
					}
					var r : MetadataViews.Rarity? = nil
					if self.info.boosts[value.concat("_max")] != nil || self.info.descriptions["boosts_".concat(value)] != nil {
						r = MetadataViews.Rarity(score: nil, max: self.info.boosts[value.concat("_max")], description: self.info.descriptions["boosts_".concat(value)] )
					}
					traits.addTrait(MetadataViews.Trait(name: value, value: self.info.boosts[value], displayType: "Boost", rarity: r))
				}

				//boostPercents
				for value in self.info.boostPercents.keys {
					var r : MetadataViews.Rarity? = nil
					if self.info.descriptions["boostPercents_".concat(value)] != nil {
						r = MetadataViews.Rarity(score: nil, max: self.info.boostPercents[value.concat("_max")], description: self.info.descriptions["boostPercents_".concat(value)] )
					}
					traits.addTrait(MetadataViews.Trait(name: value, value: self.info.boostPercents[value], displayType: "BoostPercentage", rarity: r))
				}

				//levels
				for value in self.info.levels.keys {
					if FindUtils.hasSuffix(value, suffix: "_max"){
						continue
					}
					var r : MetadataViews.Rarity? = nil
					if self.info.levels[value.concat("_max")] != nil || self.info.descriptions["levels_".concat(value)] != nil {
						r = MetadataViews.Rarity(score: nil, max: self.info.levels[value.concat("_max")], description: self.info.descriptions["levels_".concat(value)] )
					}
					traits.addTrait(MetadataViews.Trait(name: value, value: self.info.levels[value], displayType: "Level", rarity: r))
				}

				//dates
				for value in self.info.dates.keys {
					var r : MetadataViews.Rarity? = nil
					if self.info.descriptions["dates_".concat(value)] != nil {
						r = MetadataViews.Rarity(score: nil, max: self.info.dates[value.concat("_max")], description: self.info.descriptions["dates_".concat(value)] )
					}
					traits.addTrait(MetadataViews.Trait(name: value, value: self.info.dates[value], displayType: "Date", rarity: r))
				}
				return traits
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.info.name,
					description: self.info.description,
					thumbnail: MetadataViews.IPFSFile(
						cid: self.info.thumbnailHash, path: nil 
					)
				)
			case Type<MetadataViews.Editions>():
			  let editionInfo = MetadataViews.Edition(name: "set", number: self.info.edition, max: self.info.maxEdition)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(
					editionList
				)
			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL(self.info.externalURL)

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(
					storagePath: FindFooDIM.CollectionStoragePath,
					publicPath: FindFooDIM.CollectionPublicPath,
					providerPath: FindFooDIM.CollectionPrivatePath,
					publicCollection: Type<&FindFooDIM.Collection{NonFungibleToken.Collection,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
					publicLinkedType: Type<&FindFooDIM.Collection{NonFungibleToken.Collection,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
					providerLinkedType: Type<&FindFooDIM.Collection{NonFungibleToken.Collection,NonFungibleToken.Provider,ViewResolver.ResolverCollection}>(),
					createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
						return <-FindFooDIM.createEmptyCollection()
					})
				)
			case Type<MetadataViews.NFTCollectionDisplay>():
				return FindFooDIM.nftCollectionDisplay
			}
			return nil
		}
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT. ID : ".concat(withdrawID.toString()))

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @FindFooDIM.NFT

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
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nfgNFT = nft as! &FindFooDIM.NFT
			return nfgNFT as &AnyResource{ViewResolver.Resolver}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub resource Forge: FindForge.Forge {
		pub fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
			let info = data as? FindForgeStruct.FindDIM ?? panic("The data passed in is not in form of Generic Info Struct.")
			let royalties : [MetadataViews.Royalty] = []
			royalties.append(MetadataViews.Royalty(receiver:platform.platform, cut: platform.platformPercentCut, description: "find forge"))
			if platform.minterCut != nil {
				royalties.append(MetadataViews.Royalty(receiver:platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "creator"))
			}

			// create a new NFT
			var newNFT <- create NFT(
				info: info,
				royalties: MetadataViews.Royalties(royalties)
			)

			return <- newNFT
		}

		pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			// not used here 

			panic("Not supported for FindFooDIM Contract") 
        }
	}

	pub fun getForgeType() : Type {
		return Type<@Forge>()
	}

	init() {

		let contractName = "FindFooDIM" 


		// Initialize the total supply
		self.totalSupply = 0

		// Set the named paths
		self.CollectionStoragePath = /storage/FindFooDIM
		self.CollectionPrivatePath = /private/FindFooDIM
		self.CollectionPublicPath = /public/FindFooDIM
		self.MinterStoragePath = /storage/FindFooDIMMinter

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<-collection, to: self.CollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&FindFooDIM.Collection{NonFungibleToken.Collection, ViewResolver.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		FindForge.addForgeType(<- create Forge())
		let admin = FindFooDIM.account.storage.borrow<&FindForge.ForgeAdminProxy>(from: /storage/findForgeAdminProxy)!
		self.nftCollectionDisplay = admin.fulfillForgeOrder(contractName, forgeType: Type<@Forge>())
		emit ContractInitialized()
	}
}

