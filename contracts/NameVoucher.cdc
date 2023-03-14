import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FungibleTokenSwitchboard from "./standard/FungibleTokenSwitchboard.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import FindViews from "./FindViews.cdc"
// import FindAirdropper from "./FindAirdropper.cdc"

pub contract NameVoucher: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, address:Address, minCharLength: UInt64)

	pub event Destroyed(id: UInt64, address: Address?, minCharLength: UInt64)
	pub event Redeemed(id: UInt64, address: Address?, minCharLength: UInt64, findName: String, action: String)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub var royalties : [MetadataViews.Royalty]
	pub var thumbnail : {MetadataViews.File}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

		pub let id:UInt64
		pub var nounce:UInt64
		// 3 characters voucher should be able to claim name with at LEAST 3 char and so on
		pub let minCharLength:UInt64

		init(
			minCharLength: UInt64
		) {
			self.nounce=0
			self.minCharLength=minCharLength
			self.id=self.uuid
		}

		destroy() {
			emit Destroyed(id: self.id, address: self.owner?.address, minCharLength: self.minCharLength)
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Traits>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {

			var imageFile=NameVoucher.thumbnail

			switch self.minCharLength {
				case 3 :
					imageFile = MetadataViews.IPFSFile(cid: "QmYMtXfFcgpJgm3Mhy68r6cuHTCMMcucVUpYTVeSRTWLTh", path: nil)

				case 4 :
					imageFile = MetadataViews.IPFSFile(cid: "QmWpQRvGudYrkZw6rKKTrkghkYKs4wt3KQGzxcXJ8JmuSc", path: nil)
			}

			let name= self.minCharLength.toString().concat("-characters .find name voucher")
			let description ="The owner of this voucher can claim OR extend any available / owned .find name of ".concat(self.minCharLength.toString()).concat(" characters or more. \nThis voucher is single-use only and will be destroyed after any registration or extension of .find name.\nIf the voucher was airdropped then you will find it in your inbox ready to be claimed or used. If it is already in your collection then it is already claimed and can be used in one of two ways:\n- To register a new name, login and search for the name using the top search bar. If it is available you will have the option to either Register or Use Voucher. Click Use Voucher and follow the prompts to register that name using your voucher. Once successful the voucher will be burnt and you will have the chosen name in your account\n- To extend an existing name. Log in to find and go to the Names tab in your dashboard. Click Manage on the name you wish to extend and if you have this voucher in that account you will an option of Use Voucher underneath Extend. Click that and follow the prompts. On success you will have extended your lease and the voucher will be burnt.")

			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: name,
					description: description,
					thumbnail: imageFile
				)

			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/nameVoucher/").concat(self.id.toString()))

			case Type<MetadataViews.Royalties>():
				return MetadataViews.Royalties(NameVoucher.royalties)

			case Type<MetadataViews.NFTCollectionDisplay>():
				let externalURL = MetadataViews.ExternalURL("https://find.xyz/")
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1448245049666510848/1674733461/1500x500"), mediaType: "image")
				return MetadataViews.NFTCollectionDisplay(
					name: "NameVoucher",
					description: "The owner of this voucher can claim OR extend any available / owned .find names.\nThis voucher is single-use only and will be destroyed after any registration or extension of .find name.\nIf the voucher was airdropped then you will find it in your inbox ready to be claimed or used. If it is already in your collection then it is already claimed and can be used in one of two ways:\n- To register a new name, login and search for the name using the top search bar. If it is available you will have the option to either Register or Use Voucher. Click Use Voucher and follow the prompts to register that name using your voucher. Once successful the voucher will be burnt and you will have the chosen name in your account\n- To extend an existing name. Log in to find and go to the Names tab in your dashboard. Click Manage on the name you wish to extend and if you have this voucher in that account you will an option of Use Voucher underneath Extend. Click that and follow the prompts. On success you will have extended your lease and the voucher will be burnt.",
					externalURL: externalURL,
					squareImage: squareImage,
					bannerImage: bannerImage,
					socials: {
						"discord": MetadataViews.ExternalURL("https://discord.gg/findonflow"),
						"twitter" : MetadataViews.ExternalURL("https://twitter.com/findonflow")
					}
				)

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: NameVoucher.CollectionStoragePath,
				publicPath: NameVoucher.CollectionPublicPath,
				providerPath: NameVoucher.CollectionPrivatePath,
				publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- NameVoucher.createEmptyCollection()})

			case Type<MetadataViews.Traits>():
				return MetadataViews.Traits([
					MetadataViews.Trait(
						name: "Minimum number of characters",
						value: self.minCharLength,
						displayType: "number",
						rarity: nil
					)
				])
			}
			return nil
		}

		access(contract) fun increaseNounce() {
			self.nounce=self.nounce+1
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
			//TODO: add nounce and emit better event the first time it is moved.

			token.increaseNounce()
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)


			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		pub fun contains(_ id: UInt64) : Bool {
			return self.ownedNFTs.containsKey(id)
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let vr = nft as! &NFT
			return vr as &AnyResource{MetadataViews.Resolver}
		}

		pub fun redeem(id: UInt64, name: String) {
			let nft <- self.ownedNFTs.remove(key: id) ?? panic("Cannot find voucher with ID ".concat(id.toString()))
			let typedNFT <- nft as! @NameVoucher.NFT
			let nameLength = UInt64(name.length)
			let minLength = typedNFT.minCharLength

			// Assert that the name voucher is valid for claiming name with this length
			assert(nameLength >= minLength, message: "You are trying to register a ".concat(nameLength.toString()).concat(" character name, but the voucher can only support names with minimun character of ").concat(minLength.toString()))
			destroy typedNFT

			// get All the paths here for registration
			let network = NameVoucher.account.borrow<&FIND.Network>(from: FIND.NetworkStoragePath) ?? panic("Cannot borrow find network for registration")
			let status = FIND.status(name)

			// If the lease is free, we register it
			if status.status == FIND.LeaseStatus.FREE {
				let profile = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
				let lease = self.owner!.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
				network.internal_register(name: name, profile: profile,  leases: lease)
				emit Redeemed(id: id, address: self.owner?.address, minCharLength: minLength, findName: name, action: "register")
				return
			}

			// If the lease is already taken / locked, we check if that's under the name of the voucher owner, then extend it
			if status.owner != nil && status.owner! == self.owner!.address {
				network.internal_renew(name: name)
				emit Redeemed(id: id, address: self.owner?.address, minCharLength: minLength, findName: name, action: "renew")
				return
			}

			panic("Name is already taken by others ".concat(status.owner!.toString()))
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	// Internal mint NFT is used inside the contract as a helper function
	// It DOES NOT emit events so the admin function calling this should emit that
	access(account) fun mintNFT(
		recipient: &{NonFungibleToken.Receiver},
		minCharLength: UInt64
	) : UInt64 {
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
		}

		NameVoucher.totalSupply = NameVoucher.totalSupply + 1
		// create a new NFT
		var newNFT <- create NFT(
			minCharLength: minCharLength
		)

		let id = newNFT.id
		recipient.deposit(token: <-newNFT)
		emit Minted(id: id, address: recipient.owner!.address, minCharLength: minCharLength)
		return id
	}

	access(account) fun setRoyaltycut(_ cutInfo: [MetadataViews.Royalty]) {
		NameVoucher.royalties = cutInfo
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		// Set Royalty cuts in a transaction
		self.royalties = [
			MetadataViews.Royalty(
				receiver: NameVoucher.account.getCapability<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
				cut: 0.025,
				description: "network"
			)
		]
		// 5 - letter Thumbnail
		self.thumbnail = MetadataViews.IPFSFile(cid: "QmWj3bwRfksGXvFQYoWtjdycD68cp4xRGMJonnDibsN6Rz", path: nil)

		// Set the named paths
		self.CollectionStoragePath = /storage/nameVoucher
		self.CollectionPublicPath = /public/nameVoucher
		self.CollectionPrivatePath = /private/nameVoucher

		self.account.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
		self.account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			NameVoucher.CollectionPublicPath,
			target: NameVoucher.CollectionStoragePath
		)
		self.account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			NameVoucher.CollectionPrivatePath,
			target: NameVoucher.CollectionStoragePath
		)

		emit ContractInitialized()
	}
}
