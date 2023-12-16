
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

pub contract CharityNFT: NonFungibleToken {

	pub var totalSupply: UInt64

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, metadata: {String:String}, to:Address)

	pub resource NFT: NonFungibleToken.INFT, Public, ViewResolver.Resolver {
		pub let id: UInt64

		access(self) let metadata: {String: String}

		init(initID: UInt64, metadata: {String : String}) {
			self.id = initID
			self.metadata = metadata
		}

		pub fun getMetadata() : { String : String} {
			return self.metadata
		}

        pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>() ,
				Type<MetadataViews.Royalties>() ,
				Type<MetadataViews.ExternalURL>() ,
				Type<MetadataViews.NFTCollectionDisplay>() ,
				Type<MetadataViews.NFTCollectionData>() , 
				Type<MetadataViews.Edition>()
			]
		}

        pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {

				case Type<MetadataViews.Display>() : 
					// just in case there is no "image" key, return the general bronze image
					let image = self.metadata["thumbnail"] ?? "ipfs://QmcxXHLADpcw5R7xi6WmPjnKAEayK3eiEh85gzjgdzfwN6"
					return MetadataViews.Display(
						name: self.metadata["name"] ?? "Neo Charity 2021" ,
						description: self.metadata["description"] ?? "Neo Charity 2021",
						thumbnail: MetadataViews.IPFSFile(
							cid: image.slice(from: "ipfs://".length, upTo: image.length) , 
							path: nil
						)
					)

				case Type<MetadataViews.Royalties>() : 
					// No Royalties implemented
					return MetadataViews.Royalties([])

				case Type<MetadataViews.ExternalURL>() : 
					return MetadataViews.ExternalURL("http://find.xyz/neoCharity")

				case Type<MetadataViews.NFTCollectionDisplay>() : 
					return MetadataViews.NFTCollectionDisplay(
						name: "Neo Charity 2021",
						description: "This collection is to show participation in the Neo Collectibles x Flowverse Charity Auction in 2021.",
						externalURL: MetadataViews.ExternalURL("http://find.xyz/neoCharity"),
						squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg") , mediaType: "image"),
						bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500") , mediaType: "image"),
						socials: { 
							"Twitter" : MetadataViews.ExternalURL("https://twitter.com/findonflow") , 
							"Discord" : MetadataViews.ExternalURL("https://discord.gg/95P274mayM") 
						}
					)

				case Type<MetadataViews.NFTCollectionData>() : 
					return MetadataViews.NFTCollectionData(
						storagePath: CharityNFT.CollectionStoragePath,
						publicPath: CharityNFT.CollectionPublicPath,
						providerPath: /private/findCharityCollection,
						publicCollection: Type<&CharityNFT.Collection{CharityNFT.CollectionPublic}>(),
						publicLinkedType: Type<&CharityNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CharityNFT.CollectionPublic, ViewResolver.ResolverCollection}>(),
						providerLinkedType: Type<&CharityNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CharityNFT.CollectionPublic, ViewResolver.ResolverCollection}>(),
						createEmptyCollectionFunction: fun () : @NonFungibleToken.Collection {
							return <- CharityNFT.createEmptyCollection()
						}
					)

				case Type<MetadataViews.Edition>() : 
					let edition = self.metadata["edition"] 
					let maxEdition = self.metadata["maxEdition"] 
					if edition == nil || maxEdition == nil {
						return nil
					}
					let editionNumber = self.parseUInt64(edition!)
					let maxEditionNumber = self.parseUInt64(maxEdition!)
					if editionNumber == nil {
						return nil
					}
					return MetadataViews.Edition(
						name: nil, 
						number: editionNumber!, 
						max: editionNumber
					)

			}
			return nil

		}

		pub fun parseUInt64(_ string: String) : UInt64? {
			let chars : {Character : UInt64} = {
				"0" : 0 , 
				"1" : 1 , 
				"2" : 2 , 
				"3" : 3 , 
				"4" : 4 , 
				"5" : 5 , 
				"6" : 6 , 
				"7" : 7 , 
				"8" : 8 , 
				"9" : 9 
			}
			var number : UInt64 = 0
			var i = 0
			while i < string.length {
				if let n = chars[string[i]] {
						number = number * 10 + n
				} else {
					return nil 
				}
				i = i + 1
			}
			return number 
		}

	}

	//The public interface can show metadata and the content for the Art piece
	pub resource interface Public {
		pub let id: UInt64
		pub fun getMetadata() : {String : String}
	}

	//Standard NFT collectionPublic interface that can also borrowArt as the correct type
	pub resource interface CollectionPublic {

		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
		pub fun borrowCharity(id: UInt64): &{Public}?
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic , ViewResolver.ResolverCollection{
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT. WithdrawID : ".concat(withdrawID.toString()))

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @CharityNFT.NFT

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

		//borrow charity
		pub fun borrowCharity(id: UInt64): &{CharityNFT.Public}? {
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
				return ref as! &NFT
			} else {
				return nil
			}
		}

		//borrow view resolver
        pub fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
			if self.ownedNFTs[id] == nil {
				panic("NFT does not exist. ID : ".concat(id.toString()))
			}

		let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			return nft as! &CharityNFT.NFT
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}


	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	access(account) fun mintCharity(metadata: {String:String}, recipient: Capability<&{NonFungibleToken.CollectionPublic}>) {

		// create a new NFT
		var newNFT <- create NFT(initID: CharityNFT.totalSupply, metadata:metadata)

		// deposit it in the recipient's account using their reference
		let collectionRef = recipient.borrow() ?? panic("Cannot borrow reference to collection public. ")
		collectionRef.deposit(token: <-newNFT)
		emit Minted(id: CharityNFT.totalSupply, metadata:metadata, to: recipient.address)

		CharityNFT.totalSupply = CharityNFT.totalSupply + 1 
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		emit ContractInitialized()
		self.CollectionPublicPath=/public/findCharityCollection
		self.CollectionStoragePath=/storage/findCharityCollection
	}
}

