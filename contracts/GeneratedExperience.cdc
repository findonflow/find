import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FindPack from "./FindPack.cdc"

pub contract GeneratedExperience: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, season: UInt64, name: String, thumbnail: String, fullsize: String, artist: String, rarity: String, edition: UInt64, maxEdition: UInt64)
	pub event SeasonAdded(season:UInt64, squareImage: String, bannerImage: String)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub let MinterStoragePath: StoragePath

	// {Season : CollectionInfo}
	pub let collectionInfo: {UInt64 : CollectionInfo}

	pub struct CollectionInfo {
		pub let season: UInt64
		pub var royalties: [MetadataViews.Royalty]
		// This is only used internally for fetching royalties in
		pub let royaltiesInput: [FindPack.Royalty]
		pub let squareImage: String
		pub let bannerImage: String
		pub let description: String
		access(contract) let extra: {String: AnyStruct}

		init(
			season: UInt64,
			royalties: [MetadataViews.Royalty],
			royaltiesInput: [FindPack.Royalty],
			squareImage: String,
			bannerImage: String,
			description: String
		) {
			self.season = season
			self.royalties = royalties
			self.royaltiesInput = royaltiesInput
			self.squareImage = squareImage
			self.bannerImage = bannerImage
			self.description = description
			self.extra={}
		}

		// This is only used internally for fetching royalties in
		access(contract) fun setRoyalty(r: [MetadataViews.Royalty])  {
			self.royalties = r
		}
	}

	pub struct Info {
		pub let season: UInt64
		pub let name: String
		pub let description: String
		pub let thumbnailHash: String
		pub let fullsizeHash: String
		pub let edition: UInt64
		pub let maxEdition: UInt64
		pub let artist: String
		pub let rarity: String
		access(self) let extra: {String: AnyStruct}

		init(season: UInt64, name: String, description: String, thumbnailHash: String, edition:UInt64, maxEdition:UInt64, fullsizeHash: String, artist: String, rarity: String) {
			self.season=season
			self.name=name
			self.description=description
			self.thumbnailHash=thumbnailHash
			self.edition=edition
			self.maxEdition=maxEdition
			self.fullsizeHash=fullsizeHash
			self.artist=artist
			self.rarity=rarity
			self.extra={}
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		pub let info: Info

		init(
			info: Info
		) {
			self.id = self.uuid
			self.info=info
		}

		pub fun getViews(): [Type] {
			return [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.Editions>(),
			Type<MetadataViews.Traits>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Medias>(),
			Type<MetadataViews.Rarity>(),
			Type<FindPack.PackRevealData>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {

			let collection = GeneratedExperience.collectionInfo[self.info.season]!
			let imageFile = MetadataViews.IPFSFile( cid: self.info.thumbnailHash, path: nil)

			switch view {

			case Type<FindPack.PackRevealData>():
				let data : {String : String} = {
					"nftImage" : imageFile.uri() ,
					"nftName" : self.info.name,
					"packType" : "GeneratedExperience"
				}
				return FindPack.PackRevealData(data)

			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.info.name,
					description: self.info.description,
					thumbnail: MetadataViews.IPFSFile(
						cid: self.info.thumbnailHash, path: nil
					)
				)
			case Type<MetadataViews.Editions>():
				// We do not show season here unless there are more than 1 collectionInfo (that is indexed by season)
				let editionName = "genereatedexperience"
				let editionInfo = MetadataViews.Edition(name: editionName, number: self.info.edition, max: self.info.maxEdition)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(
					editionList
				)
			case Type<MetadataViews.Royalties>():
				return MetadataViews.Royalties(collection.royalties)

			case Type<MetadataViews.ExternalURL>():
				if self.owner != nil {
					return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/main/generatedExperience/").concat(self.id.toString()))
				}
				return MetadataViews.ExternalURL("https://find.xyz/")

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(
					storagePath: GeneratedExperience.CollectionStoragePath,
					publicPath: GeneratedExperience.CollectionPublicPath,
					providerPath: GeneratedExperience.CollectionPrivatePath,
					publicCollection: Type<&GeneratedExperience.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&GeneratedExperience.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&GeneratedExperience.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
						return <-GeneratedExperience.createEmptyCollection()
					})
				)
			case Type<MetadataViews.NFTCollectionDisplay>():

				var square = MetadataViews.Media(
					file: MetadataViews.IPFSFile(
						cid: collection.squareImage,
						path: nil
					),
					mediaType: "image/png"
				)

				var banner = MetadataViews.Media(
					file: MetadataViews.IPFSFile(
						cid: collection.bannerImage,
						path: nil
					),
					mediaType: "image/png"
				)

				return MetadataViews.NFTCollectionDisplay(
					name: "GeneratedExperience",
					description: collection.description,
					externalURL: MetadataViews.ExternalURL("https://find.xyz/mp/GeneratedExperience"),
					squareImage: square,
					bannerImage: banner,
					socials: {
						// TODO: Update later
						"twitter": MetadataViews.ExternalURL("https://twitter.com/GeneratedExperience"),
						"discord" : MetadataViews.ExternalURL("https://discord.gg/GeneratedExperience")
					}
				)

			case Type<MetadataViews.Traits>() :

				let traits = [
					MetadataViews.Trait(name: "Artist", value: self.info.artist, displayType: "String", rarity: nil)
				]

				if GeneratedExperience.collectionInfo.length > 1 {
					traits.append(MetadataViews.Trait(name: "Season", value: self.info.season, displayType: "Numeric", rarity: nil))
				}

				return MetadataViews.Traits(traits)

			case Type<MetadataViews.Medias>() :
				var thumbnailMediaType = "image/png"
				var fullImageMediaType = "image/png"

				return MetadataViews.Medias([
						MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil), mediaType: thumbnailMediaType),
						MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.fullsizeHash, path: nil), mediaType: fullImageMediaType)
				])

			case Type<MetadataViews.Rarity>() :
				return MetadataViews.Rarity(score: nil, max: nil, description: self.info.rarity)
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
			let token <- token as! @GeneratedExperience.NFT

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
			let ge = nft as! &GeneratedExperience.NFT
			return ge as &AnyResource{MetadataViews.Resolver}
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
			let info = data as? Info ?? panic("The data passed in is not in form as needed. Needed: ".concat(Type<Info>().identifier))

			// create a new NFT
			var newNFT <- create NFT(
				info: info,
			)

			GeneratedExperience.totalSupply = GeneratedExperience.totalSupply + 1
			emit Minted(id:newNFT.id, season: info.season, name: info.name, thumbnail: info.thumbnailHash, fullsize: info.fullsizeHash, artist: info.artist, rarity: info.rarity, edition: info.edition, maxEdition: info.maxEdition)
			return <- newNFT
		}

		pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			let collectionInfo = data as? CollectionInfo ?? panic("The data passed in is not in form as needed. Needed: ".concat(Type<CollectionInfo>().identifier))

			// We cannot send in royalties directly, therefore we have to send in FindPack Royalties and generate it during minting
			let arr : [MetadataViews.Royalty] = []
			for r in collectionInfo.royaltiesInput {
				// Try to get Token Switchboard
				var receiverCap = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
				// If it fails, try to get Find Profile
				if !receiverCap.check(){
					receiverCap = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/findProfileReceiver)
				}
				// Do we check and panic here?
				// if !receiverCap.check(){
				// 	panic("royalty is not valid")
				// }

				arr.append(MetadataViews.Royalty(recipient: receiverCap, cut: r.cut, description: r.description))
			}
			collectionInfo.setRoyalty(r: arr)

			GeneratedExperience.collectionInfo[collectionInfo.season] = collectionInfo
			emit SeasonAdded(season:collectionInfo.season, squareImage: collectionInfo.squareImage, bannerImage: collectionInfo.bannerImage)
        }
	}

	pub fun getForgeType() : Type {
		return Type<@Forge>()
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		// Set the named paths
		self.CollectionStoragePath = /storage/GeneratedExperience
		self.CollectionPrivatePath = /private/GeneratedExperience
		self.CollectionPublicPath = /public/GeneratedExperience
		self.MinterStoragePath = /storage/GeneratedExperienceMinter

		self.collectionInfo = {}

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<-collection, to: self.CollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&GeneratedExperience.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		FindForge.addForgeType(<- create Forge())
		emit ContractInitialized()
	}
}


