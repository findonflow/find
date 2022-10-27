import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import PartyFavorzExtraData from "./PartyFavorzExtraData.cdc"

pub contract PartyFavorz: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, serial: UInt64, season: UInt64, name: String )

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPrivatePath: PrivatePath
	pub let CollectionPublicPath: PublicPath
	pub let MinterStoragePath: StoragePath

	pub let royalties: [MetadataViews.Royalty]

	pub struct Info {
		pub let name: String
		pub let description: String
		pub let thumbnailHash: String
		pub let edition: UInt64
		pub let maxEdition: UInt64
		pub let fullsizeHash: String 
		pub let artist: String

		init(name: String, description: String, thumbnailHash: String, edition:UInt64, maxEdition:UInt64, fullsizeHash: String, artist: String) {
			self.name=name 
			self.description=description 
			self.thumbnailHash=thumbnailHash
			self.edition=edition
			self.maxEdition=maxEdition
			self.fullsizeHash=fullsizeHash
			self.artist=artist
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64

		pub let info: Info

		init(
			info: Info,
			season: UInt64,
			royalties: [MetadataViews.Royalty], 
			squareImage: String, 
			bannerImage: String
		) {
			self.id = self.uuid
			self.info=info

			PartyFavorzExtraData.setData(id: self.id, field: "season", value: season)
			PartyFavorzExtraData.setData(id: self.id, field: "royalties", value: royalties)
			PartyFavorzExtraData.setData(id: self.id, field: "nftCollectionDisplay", value: {"squareImage" : squareImage, "bannerImage" : bannerImage})
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
			Type<MetadataViews.Medias>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.info.name,
					description: self.info.description,
					thumbnail: MetadataViews.IPFSFile(
						cid: self.info.thumbnailHash, path: nil 
					)
				)
			case Type<MetadataViews.Editions>():
				let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
				var season = 1 as UInt64
				if seasonData != nil {
					season = seasonData! as! UInt64
				}
				let editionInfo = MetadataViews.Edition(name: "season ".concat(season.toString()), number: self.info.edition, max: self.info.maxEdition)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(
					editionList
				)
			case Type<MetadataViews.Royalties>():
				let royaltiesData = PartyFavorzExtraData.getData(id: self.id, field: "royalties")
				if royaltiesData != nil {
					let r = royaltiesData! as! [MetadataViews.Royalty]
					return MetadataViews.Royalties(r)
				}
				return MetadataViews.Royalties(PartyFavorz.royalties)

			case Type<MetadataViews.ExternalURL>():
				if self.owner != nil {
					return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/partyfavorz/").concat(self.id.toString()))
				}
				return MetadataViews.ExternalURL("https://find.xyz/")

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(
					storagePath: PartyFavorz.CollectionStoragePath,
					publicPath: PartyFavorz.CollectionPublicPath,
					providerPath: PartyFavorz.CollectionPrivatePath,
					publicCollection: Type<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
						return <-PartyFavorz.createEmptyCollection()
					})
				)
			case Type<MetadataViews.NFTCollectionDisplay>():

				var square = MetadataViews.Media(
					file: MetadataViews.IPFSFile(
						cid: "QmNkJGEzNYzXsKFqCMweFZBZ9cMQsfMUzV2ZDh2Nn8a1Xc",
						path: nil
					),
					mediaType: "image/png"
				)

				var banner = MetadataViews.Media(
					file: MetadataViews.IPFSFile(
						cid: "QmVuMpDyJXHMCK9LnFboemWfPYabcwPNEmXgQMWbtxtGWD",
						path: nil
					),
					mediaType: "image/png"
				)

				let nftCollectionDisplayData = PartyFavorzExtraData.getData(id: self.id, field: "nftCollectionDisplay")
				if nftCollectionDisplayData != nil {
					let nftCollectionDisplay = nftCollectionDisplayData! as! {String : String}

					square = MetadataViews.Media(
						file: MetadataViews.IPFSFile(
							cid: nftCollectionDisplay["squareImage"]!,
							path: nil
						),
						mediaType: "image/png"
					)

					banner = MetadataViews.Media(
						file: MetadataViews.IPFSFile(
							cid: nftCollectionDisplay["bannerImage"]!,
							path: nil
						),
						mediaType: "image/png"
					)

				}

				return MetadataViews.NFTCollectionDisplay(
					name: "PartyFavorz",
					description: "By owning a Party Favorz NFT, you are granted access to the VIP sections of our virtual parties which include, but are not limited to major giveaways, 1 on 1s with artists/project leaders, and some IRL utility that involves partying, down the line. By owning Party Favorz, you are supporting the idea of community coming together for a few goals that include having fun, being positive, learning, and most importantly SUPPORTING ARTISTS.",
					externalURL: MetadataViews.ExternalURL("https://find.xyz/partyfavorz"),
					squareImage: square,
					bannerImage: banner,
					socials: {
						"twitter": MetadataViews.ExternalURL("https://twitter.com/FlowPartyFavorz"), 
						"discord" : MetadataViews.ExternalURL("https://discord.gg/bM76F34EnN")
					}
				)

			case Type<MetadataViews.Traits>() : 
				let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
				var season = 1 as UInt64
				if seasonData != nil {
					season = seasonData! as! UInt64
				}
				return MetadataViews.Traits([
					MetadataViews.Trait(name: "Artist", value: self.info.artist, displayType: "String", rarity: nil) ,
					MetadataViews.Trait(name: "Season", value: season, displayType: "Numeric", rarity: nil) 
				])

			case Type<MetadataViews.Medias>() : 
				let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
				var season = 1 as UInt64
				if seasonData != nil {
					season = seasonData! as! UInt64
				}

				var thumbnailMediaType = "image/png"
				var fullImageMediaType = "image/png"

				switch season {
					case 2 as UInt64 : 
						fullImageMediaType = "image/gif"

				}

				return MetadataViews.Medias([
						MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil), mediaType: thumbnailMediaType),
						MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.fullsizeHash, path: nil), mediaType: fullImageMediaType)
				])
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
			let token <- token as! @PartyFavorz.NFT

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
			let PartyFavorz = nft as! &PartyFavorz.NFT
			return PartyFavorz as &AnyResource{MetadataViews.Resolver}
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
			let info = data as? {String : AnyStruct} ?? panic("The data passed in is not in form as needed.")

			assert(info.length == 5, message: "Please make sure to pass in `Info, season, royalties, squareImage, bannerImage`")

			// create a new NFT
			var newNFT <- create NFT(
				info: info["info"]! as! Info, 
				season: info["season"]! as! UInt64,
				royalties: info["royalties"]! as! [MetadataViews.Royalty], 
				squareImage: info["squareImage"]! as! String, 
				bannerImage: info["bannerImage"]! as! String
			)

			PartyFavorz.totalSupply = PartyFavorz.totalSupply + UInt64(1)
			emit Minted(id:newNFT.id, serial: PartyFavorz.totalSupply, season: info["season"]! as! UInt64 , name: newNFT.info.name )
			return <- newNFT
		}


		pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			// not used here 

			panic("Not supported for PartyFavorz Contract") 
        }
	}

	pub fun getForgeType() : Type {
		return Type<@Forge>()
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		// Set the named paths
		self.CollectionStoragePath = /storage/PartyFavorzCollection
		self.CollectionPrivatePath = /private/PartyFavorzCollection
		self.CollectionPublicPath = /public/PartyFavorzCollection
		self.MinterStoragePath = /storage/PartyFavorzMinter

		let partyFavorz = getAccount(0xded455fa967d350e).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		let artist = getAccount(0x34f2bf4a80bb0f69).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

		self.royalties = [
							MetadataViews.Royalty(receiver: partyFavorz, cut: 0.03, description: "Party Favorz"), 
							MetadataViews.Royalty(receiver: artist, cut: 0.02, description: "Artist") 
					   	 ]

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<-collection, to: self.CollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		FindForge.addForgeType(<- create Forge())
		emit ContractInitialized()
	}
}

 