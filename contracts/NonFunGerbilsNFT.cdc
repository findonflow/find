import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"

//LUKE: do we want the contract to be called NFG, NonFunGerbils or NonFunGerbilsNFT, or something else?
pub contract NonFunGerbilsNFT: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub let MinterStoragePath: StoragePath

	pub struct NonFunGerbilsNFTInfo {
		pub let name: String
		pub let description: String
		pub let thumbnail: String

		init(name: String, description: String, thumbnail: String) {
			self.name=name 
			self.description=description 
			self.thumbnail=thumbnail 
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64

		pub let name: String
		pub let description: String
		pub let thumbnail: String
		access(self) let royalties: MetadataViews.Royalties

		init(
			name: String,
			description: String,
			thumbnail: String,
			royalties: MetadataViews.Royalties
		) {
			self.id = self.uuid
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
		}

		pub fun getViews(): [Type] {
			return [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.Editions>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Serial>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.name,
					description: self.description,
					//LUKE: do we want to use IPFS or HTTP url? arweave can be HTTP URL
					thumbnail: MetadataViews.HTTPFile(
						url: self.thumbnail
					)
				)
			case Type<MetadataViews.Editions>():
				// There is no max number of NFTs that can be minted from this contract
				// so the max edition field value is set to nil
				//LUKE: do you want to have max editions in the NFT?
				//LUKE:  do you have a preference for edition name

				let editionInfo = MetadataViews.Edition(name: "set", number: self.id, max: nil)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(
					editionList
				)
			case Type<MetadataViews.Serial>():
				return MetadataViews.Serial(
					self.id
				)
			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.ExternalURL>():
				//LUKE: What url to a gerbil do you have on your site?
				return MetadataViews.ExternalURL("https://nfg-nft.onflow.org/".concat(self.id.toString()))
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(
					storagePath: NonFunGerbilsNFT.CollectionStoragePath,
					publicPath: NonFunGerbilsNFT.CollectionPublicPath,
					providerPath: /private/nfgNFTCollection,
					publicCollection: Type<&NonFunGerbilsNFT.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&NonFunGerbilsNFT.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&NonFunGerbilsNFT.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
						return <-NonFunGerbilsNFT.createEmptyCollection()
					})
				)
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(
					file: MetadataViews.HTTPFile(
						//LUKE: need a banner image nad a square image 
						url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
					),
					mediaType: "image/svg+xml"
				)
				return MetadataViews.NFTCollectionDisplay(
					name: "NonFunGerbils",
					//LUKE: Need description of NFG
					description: "This collection is used as an nfg to help you develop your next Flow NFT.",
					//LUKE: need external url to all of NFT, I assume this is same as website currently?
					externalURL: MetadataViews.ExternalURL("https://nfg-nft.onflow.org"),
					squareImage: media,
					bannerImage: media,
					socials: {
						//LUKE: add socials here
						"twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
					}
				)
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
			let token <- token as! @NonFunGerbilsNFT.NFT

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

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nfgNFT = nft as! &NonFunGerbilsNFT.NFT
			return nfgNFT as &AnyResource{MetadataViews.Resolver}
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
			let info = data as? NonFunGerbilsNFTInfo ?? panic("The data passed in is not in form of NonFunGerbilsNFTInfo.")
			let royalties : [MetadataViews.Royalty] = []
			royalties.append(MetadataViews.Royalty(receiver:platform.platform, cut: platform.platformPercentCut, description: "platform"))
			if platform.minterCut != nil {
				royalties.append(MetadataViews.Royalty(receiver:platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "minter"))
			}

			// create a new NFT
			var newNFT <- create NFT(
				name: info.name,
				description: info.description,
				thumbnail: info.thumbnail,
				royalties: MetadataViews.Royalties(royalties)
			)

			NonFunGerbilsNFT.totalSupply = NonFunGerbilsNFT.totalSupply + UInt64(1)
			return <- newNFT
		}
	}

	access(account) fun createForge() : @{FindForge.Forge} {
		return <- create Forge()
	}

	pub fun getForgeType() : Type {
		return Type<@Forge>()
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		// Set the named paths
		self.CollectionStoragePath = /storage/nfgNFTCollection
		self.CollectionPrivatePath = /private/nfgNFTCollection
		self.CollectionPublicPath = /public/nfgNFTCollection
		self.MinterStoragePath = /storage/nfgNFTMinter

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<-collection, to: self.CollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&NonFunGerbilsNFT.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)

		FindForge.addPublicForgeType(forge: <- create Forge())

		emit ContractInitialized()
	}
}

