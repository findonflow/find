/*
* Inspiration: https://flow-view-source.com/testnet/account/0xba1132bc08f82fe2/contract/Ghost
*/

import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import ProfileCache from "../contracts/ProfileCache.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

access(all) contract Profile {
	access(all) let access(all)licPath: PublicPath
	access(all) let access(all)licReceiverPath: PublicPath
	access(all) let storagePath: StoragePath

	//and event emitted when somebody follows another user
	access(all) event Follow(follower:Address, following: Address, tags: [String])

	//an event emitted when somebody unfollows somebody
	access(all) event Unfollow(follower:Address, unfollowing: Address)

	//and event emitted when a user verifies something
	access(all) event Verification(account:Address, message:String)

	access(all) event Created(account:Address, userName:String, findName:String, createdAt:String)
	access(all) event Updated(account:Address, userName:String, findName:String, thumbnail:String)

	/*
	Represents a Fungible token wallet with a name and a supported type.
	*/
	access(all) struct Wallet {
		access(all) let name: String
		access(all) let receiver: Capability<&{FungibleToken.Receiver}>
		access(all) let balance: Capability<&{FungibleToken.Vault}>
		access(all) let accept: Type
		access(all) let tags: [String]

		init(
			name: String,
			receiver: Capability<&{FungibleToken.Receiver}>,
			balance: Capability<&{FungibleToken.Vault}>,
			accept: Type,
			tags: [String]
		) {
			self.name=name
			self.receiver=receiver
			self.balance=balance
			self.accept=accept
			self.tags=tags
		}
	}

	/*

	Represent a collection of a Resource that you want to expose
	Since NFT standard is not so great at just add Type and you have to use instanceOf to check for now
	*/
	access(all) struct ResourceCollection {
		access(all) let collection: Capability
		access(all) let tags: [String]
		access(all) let type: Type
		access(all) let name: String

		init(name: String, collection:Capability, type: Type, tags: [String]) {
			self.name=name
			self.collection=collection
			self.tags=tags
			self.type=type
		}
	}


	access(all) struct CollectionProfile{
		access(all) let tags: [String]
		access(all) let type: String
		access(all) let name: String

		init(_ collection: ResourceCollection){
			self.name=collection.name
			self.type=collection.type.identifier
			self.tags=collection.tags
		}
	}

	/*
	A link that you could add to your profile
	*/
	access(all) struct Link {
		access(all) let url: String
		access(all) let title: String
		access(all) let type: String

		init(title: String, type: String, url: String) {
			self.url=url
			self.title=title
			self.type=type
		}
	}

	/*
	Information about a connection between one profile and another.
	*/
	access(all) struct FriendStatus {
		access(all) let follower: Address
		access(all) let following:Address
		access(all) let tags: [String]

		init(follower: Address, following:Address, tags: [String]) {
			self.follower=follower
			self.following=following
			self.tags= tags
		}
	}

	access(all) struct WalletProfile {
		access(all) let name: String
		access(all) let balance: UFix64
		access(all) let accept:  String
		access(all) let tags: [String]

		init(_ wallet: Wallet) {
			self.name=wallet.name
			self.balance=wallet.balance.borrow()?.getBalance() ?? 0.0
			self.accept=wallet.accept.identifier
			self.tags=wallet.tags
		}
	}

	//This is the new return struct from the profile
	access(all) struct UserReport {
		access(all) let findName: String
		access(all) let createdAt: String
		access(all) let address: Address
		access(all) let name: String
		access(all) let gender: String
		access(all) let description: String
		access(all) let tags: [String]
		access(all) let avatar: String
		access(all) let links: {String:Link}
		access(all) let wallets: [WalletProfile]
		access(all) let following: [FriendStatus]
		access(all) let followers: [FriendStatus]
		access(all) let allowStoringFollowers: Bool

		init(
			findName:String,
			address: Address,
			name: String,
			gender: String,
			description: String,
			tags: [String],
			avatar: String,
			links: {String:Link},
			wallets: [WalletProfile],
			following: [FriendStatus],
			followers: [FriendStatus],
			allowStoringFollowers:Bool,
			createdAt: String
		) {
			self.findName=findName
			self.address=address
			self.name=name
			self.gender=gender
			self.description=description
			self.tags=tags
			self.avatar=avatar
			self.links=links
			self.wallets=wallets
			self.following=following
			self.followers=followers
			self.allowStoringFollowers=allowStoringFollowers
			self.createdAt=createdAt
		}
	}



	//This format is deperated
	access(all) struct UserProfile {
		access(all) let findName: String
		access(all) let createdAt: String
		access(all) let address: Address
		access(all) let name: String
		access(all) let gender: String
		access(all) let description: String
		access(all) let tags: [String]
		access(all) let avatar: String
		access(all) let links: [Link]
		access(all) let wallets: [WalletProfile]
		access(all) let collections: [CollectionProfile]
		access(all) let following: [FriendStatus]
		access(all) let followers: [FriendStatus]
		access(all) let allowStoringFollowers: Bool

		init(
			findName:String,
			address: Address,
			name: String,
			gender: String,
			description: String,
			tags: [String],
			avatar: String,
			links: [Link],
			wallets: [WalletProfile],
			collections: [CollectionProfile],
			following: [FriendStatus],
			followers: [FriendStatus],
			allowStoringFollowers:Bool,
			createdAt: String
		) {
			self.findName=findName
			self.address=address
			self.name=name
			self.gender=gender
			self.description=description
			self.tags=tags
			self.avatar=avatar
			self.links=links
			self.collections=collections
			self.wallets=wallets
			self.following=following
			self.followers=followers
			self.allowStoringFollowers=allowStoringFollowers
			self.createdAt=createdAt
		}
	}

	access(all) resource interface Public{
		access(all) fun getAddress() : Address
		access(all) fun getName(): String
		access(all) fun getFindName(): String
		access(all) fun getCreatedAt(): String
		access(all) fun getGender(): String
		access(all) fun getDescription(): String
		access(all) fun getTags(): [String]
		access(all) fun getAvatar(): String
		access(all) fun getCollections(): [ResourceCollection]
		access(all) fun follows(_ address: Address) : Bool
		access(all) fun getFollowers(): [FriendStatus]
		access(all) fun getFollowing(): [FriendStatus]
		access(all) fun getWallets() : [Wallet]
		access(all) fun hasWallet(_ name: String) : Bool
		access(all) fun getLinks() : [Link]
		access(all) fun deposit(from: @{FungibleToken.Vault})
		access(all) fun supportedFungigleTokenTypes() : [Type]
		access(all) fun asProfile() : UserProfile
		access(all) fun asReport() : UserReport
		access(all) fun isBanned(_ val: Address): Bool
		access(all) fun isPrivateModeEnabled() : Bool

		access(contract) fun internal_addFollower(_ val: FriendStatus)
		access(contract) fun internal_removeFollower(_ address: Address)
		access(account) fun setFindName(_ val: String)
	}

	access(all) resource interface Owner {
		access(all) fun setName(_ val: String) {
			pre {
				val.length <= 64: "Name must be 64 or less characters"
			}
		}

		access(all) fun setGender(_ val:String){
			pre {
				val.length <= 64: "Gender must be 64 or less characters"
			}
		}

		access(all) fun setAvatar(_ val: String){
			pre {
				val.length <= 1024: "Avatar must be 1024 characters or less"
			}
		}

		access(all) fun setTags(_ val: [String])  {
			if (Profile.verifyTags(tags: val, tagLength:64, tagSize:32) == false){
				panic("cannot have more then 32 tags of length 64")
			}
		}

		//validate length of description to be 255 or something?
		access(all) fun setDescription(_ val: String) {
			pre {
				val.length <= 1024: "Description must be 1024 characters or less"
			}
		}

		access(all) fun follow(_ address: Address, tags:[String]) {
			if (Profile.verifyTags(tags: tags, tagLength:64, tagSize:32) == false){
				panic("cannot have more then 32 tags of length 64")
			}
		}
		access(all) fun unfollow(_ address: Address)

		access(all) fun removeCollection(_ val: String)
		access(all) fun addCollection(_ val: ResourceCollection)

		access(all) fun addWallet(_ val : Wallet)
		access(all) fun removeWallet(_ val: String)
		access(all) fun setWallets(_ val: [Wallet])
		access(all) fun hasWallet(_ name: String) : Bool
		access(all) fun addLink(_ val: Link)
		access(all) fun addLinkWithName(name:String, link:Link)

		access(all) fun removeLink(_ val: String)

		//Verify that this user has signed something.
		access(all) fun verify(_ val:String)

		//A user must be able to remove a follower since this data in your account is added there by another user
		access(all) fun removeFollower(_ val: Address)

		//manage bans
		access(all) fun addBan(_ val: Address)
		access(all) fun removeBan(_ val: Address)
		access(all) fun getBans(): [Address]

		//Set if user is allowed to store followers or now
		access(all) fun setAllowStoringFollowers(_ val: Bool)

		//set if this user prefers sensitive information about his account to be kept private, no guarantee here but should be honored
		access(all) fun setPrivateMode(_ val: Bool)
	}


	access(all) resource User: Public, Owner, FungibleToken.Receiver {
		access(self) var name: String
		access(self) var findName: String
		access(self) var createdAt: String
		access(self) var gender: String
		access(self) var description: String
		access(self) var avatar: String
		access(self) var tags: [String]
		access(self) var followers: {Address: FriendStatus}
		access(self) var bans: {Address: Bool}
		access(self) var following: {Address: FriendStatus}
		access(self) var collections: {String: ResourceCollection}
		access(self) var wallets: [Wallet]
		access(self) var links: {String: Link}
		access(self) var allowStoringFollowers: Bool

		//this is just a bag of properties if we need more fields here, so that we can do it with contract upgrade
		access(self) var additionalProperties: {String : String}

		init(name:String, createdAt: String) {
			let randomNumber = (1 as UInt64) + (unsafeRandom() % 25)
			self.createdAt=createdAt
			self.name = name
			self.findName=""
			self.gender=""
			self.description=""
			self.tags=[]
			self.avatar = "https://find.xyz/assets/img/avatars/avatar".concat(randomNumber.toString()).concat(".png")
			self.followers = {}
			self.following = {}
			self.collections={}
			self.wallets=[]
			self.links={}
			self.allowStoringFollowers=true
			self.bans={}
			self.additionalProperties={}

		}

		/// We do not have a seperate field for this so we use the additionalProperties 'bag' to store this in
		access(all) fun setPrivateMode(_ val: Bool) {
			var private="true"
			if !val{
				private="false"
			}
			self.additionalProperties["privateMode"]  = private
		}

		access(all) fun emitUpdatedEvent() {
			emit Updated(account:self.owner!.address, userName:self.name, findName:self.findName, thumbnail:self.avatar)
		}

		access(all) fun emitCreatedEvent() {
			emit Created(account:self.owner!.address, userName:self.name, findName:self.findName, createdAt:self.createdAt)
		}

		access(all) fun isPrivateModeEnabled() : Bool {
			let boolString= self.additionalProperties["privateMode"]
			if boolString== nil || boolString=="false" {
				return false
			}
			return true
		}

		access(all) fun addBan(_ val: Address) { self.bans[val]= true}
		access(all) fun removeBan(_ val:Address) { self.bans.remove(key: val) }
		access(all) fun getBans() : [Address] { return self.bans.keys }
		access(all) fun isBanned(_ val:Address) : Bool { return self.bans.containsKey(val)}

		access(all) fun setAllowStoringFollowers(_ val: Bool) {
			self.allowStoringFollowers=val
		}

		access(all) fun verify(_ val:String) {
			emit Verification(account: self.owner!.address, message:val)
		}


		access(all) fun asReport() : UserReport {
			let wallets: [WalletProfile]=[]
			for w in self.wallets {
				wallets.append(WalletProfile(w))
			}

			return UserReport(
				findName: self.getFindName(),
				address: self.owner!.address,
				name: self.getName(),
				gender: self.getGender(),
				description: self.getDescription(),
				tags: self.getTags(),
				avatar: self.getAvatar(),
				links: self.getLinksMap(),
				wallets: wallets,
				following: self.getFollowing(),
				followers: self.getFollowers(),
				allowStoringFollowers: self.allowStoringFollowers,
				createdAt:self.getCreatedAt()
			)
		}

		access(all) fun getAddress() : Address {
			return self.owner!.address
		}

		access(all) fun asProfile() : UserProfile {
			let wallets: [WalletProfile]=[]
			for w in self.wallets {
				wallets.append(WalletProfile(w))
			}

			let collections:[CollectionProfile]=[]
			for c in self.getCollections() {
				collections.append(CollectionProfile(c))
			}

			return UserProfile(
				findName: self.getFindName(),
				address: self.owner!.address,
				name: self.getName(),
				gender: self.getGender(),
				description: self.getDescription(),
				tags: self.getTags(),
				avatar: self.getAvatar(),
				links: self.getLinks(),
				wallets: wallets,
				collections: collections,
				following: self.getFollowing(),
				followers: self.getFollowers(),
				allowStoringFollowers: self.allowStoringFollowers,
				createdAt:self.getCreatedAt()
			)
		}

		access(all) fun getLinksMap() : {String: Link} {
			return self.links
		}

		access(all) fun getLinks() : [Link] {
			return self.links.values
		}

		access(all) fun addLinkWithName(name:String, link:Link) {
			self.links[name]=link
		}

		access(all) fun addLink(_ val: Link) {
			self.links[val.title]=val
		}

		access(all) fun removeLink(_ val: String) {
			self.links.remove(key: val)
		}

		access(all) fun supportedFungigleTokenTypes() : [Type] {
			let types: [Type] =[]
			for w in self.wallets {
				if !types.contains(w.accept) {
					types.append(w.accept)
				}
			}
			return types
		}

		access(all) fun deposit(from: @{FungibleToken.Vault}) {

			let walletIndexCache = ProfileCache.getWalletIndex(address: self.owner!.address, walletType: from.getType())

			if walletIndexCache != nil {
				let ref = self.wallets[walletIndexCache!].receiver.borrow() ?? panic("This vault is not set up. ".concat(from.getType().identifier).concat(self.owner!.address.toString()).concat("  .  ").concat(from.getBalance().toString()))
				ref.deposit(from: <- from)
				return
			}

			for i , w in self.wallets {
				if from.isInstance(w.accept) {
					ProfileCache.setWalletIndexCache(address: self.owner!.address, walletType: from.getType(), index: i)
					let ref = w.receiver.borrow() ?? panic("This vault is not set up. ".concat(from.getType().identifier).concat(self.owner!.address.toString()).concat("  .  ").concat(from.getBalance().toString()))
					ref.deposit(from: <- from)
					return
				}
			}
			let identifier=from.getType().identifier

			// Try borrow that in a standard way. Only work for flow, usdc and fusd
			// Check the vault type
			var ref : &{FungibleToken.Receiver}? = nil
			if FindUtils.contains(identifier, element: "FlowToken.Vault") {
				ref = self.owner!.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			} else if FindUtils.contains(identifier, element: "FiatToken.Vault") {
				ref = self.owner!.capabilities.borrow<&{FungibleToken.Receiver}>(/public/USDCVaultReceiver)
			} else if FindUtils.contains(identifier, element: "FUSD.Vault") {
				ref = self.owner!.capabilities.borrow<&{FungibleToken.Receiver}>(/public/fusdReceiver)
			} else if FindUtils.contains(identifier, element: "FlowUtilityToken.Vault") {
				ref = self.owner!.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
			} else if FindUtils.contains(identifier, element: "DapperUtilityCoin.Vault") {
				ref = self.owner!.capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
			}

			if ref != nil {
				ref!.deposit(from: <- from)
				return
			}

			//I need to destroy here for this to compile, but WHY?
			// oh we dont neet this anymore
			// destroy from
			panic("could not find a supported wallet for:".concat(identifier).concat(" for address ").concat(self.owner!.address.toString()))
		}


		access(all) fun hasWallet(_ name: String) : Bool {
			for wallet in self.wallets {
				if wallet.name == name || wallet.accept.identifier == name {
					return wallet.receiver.check()
				}
			}
			return false
		}

		access(all) fun getWallets() : [Wallet] { return self.wallets}
		access(all) fun addWallet(_ val: Wallet) { self.wallets.append(val) }
		access(all) fun removeWallet(_ val: String) {
			let numWallets=self.wallets.length
			var i=0
			while(i < numWallets) {
				if self.wallets[i].name== val {
					self.wallets.remove(at: i)
					ProfileCache.resetWalletIndexCache(address: self.owner!.address)
					return
				}
				i=i+1
			}
		}

		access(all) fun setWallets(_ val: [Wallet]) {
			self.wallets=val
			ProfileCache.resetWalletIndexCache(address: self.owner!.address)
			}

		access(all) fun removeFollower(_ val: Address) {
			self.followers.remove(key:val)
		}

		access(all) fun follows(_ address: Address) : Bool {
			return self.following.containsKey(address)
		}

		access(all) fun getName(): String { return self.name }
		access(all) fun getFindName(): String { return self.findName }
		access(all) fun getCreatedAt(): String { return self.createdAt }
		access(all) fun getGender() : String { return self.gender }
		access(all) fun getDescription(): String{ return self.description}
		access(all) fun getTags(): [String] { return self.tags}
		access(all) fun getAvatar(): String { return self.avatar }
		access(all) fun getFollowers(): [FriendStatus] { return self.followers.values }
		access(all) fun getFollowing(): [FriendStatus] { return self.following.values }

		access(all) fun setName(_ val: String) { self.name = val }
		access(all) fun setFindName(_ val: String) {
			emit Updated(account:self.owner!.address, userName:self.name, findName:val, thumbnail:self.avatar)
			ProfileCache.resetLeaseCache(address: self.owner!.address, leaseName: self.findName)
			self.findName = val
		}
		access(all) fun setGender(_ val: String) { self.gender = val }
		access(all) fun setAvatar(_ val: String) { self.avatar = val }
		access(all) fun setDescription(_ val: String) { self.description=val}
		access(all) fun setTags(_ val: [String]) { self.tags=val}

		access(all) fun removeCollection(_ val: String) { self.collections.remove(key: val)}
		access(all) fun addCollection(_ val: ResourceCollection) { self.collections[val.name]=val}
		access(all) fun getCollections(): [ResourceCollection] { return self.collections.values}


		access(all) fun follow(_ address: Address, tags:[String]) {
			let friendProfile=Profile.find(address)
			let owner=self.owner!.address
			let status=FriendStatus(follower:owner, following:address, tags:tags)

			self.following[address] = status
			friendProfile.internal_addFollower(status)
			emit Follow(follower:owner, following: address, tags:tags)
		}

		access(all) fun unfollow(_ address: Address) {
			self.following.remove(key: address)
			Profile.find(address).internal_removeFollower(self.owner!.address)
			emit Unfollow(follower: self.owner!.address, unfollowing:address)
		}

		access(contract) fun internal_addFollower(_ val: FriendStatus) {
			if self.allowStoringFollowers && !self.bans.containsKey(val.follower) {
				self.followers[val.follower] = val
			}
		}

		access(contract) fun internal_removeFollower(_ address: Address) {
			if self.followers.containsKey(address) {
				self.followers.remove(key: address)
			}
		}

		/// A getter function that returns the token types supported by this resource,
        /// which can be deposited using the 'deposit' function.
        ///
        /// @return Dictionary of FT types that can be deposited.
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} { 
            let supportedVaults: {Type: Bool} = {}
            for w in self.wallets {
                if w.receiver.check() {
                    supportedVaults[w.accept] = true
                }
            }
            return supportedVaults
        }


        /// Returns whether or not the given type is accepted by the Receiver
        access(all) view fun isSupportedVaultType(type: Type): Bool {
            let supportedVaults = self.getSupportedVaultTypes()
            if let supported = supportedVaults[type] {
                return supported
            } else { return false }
        }
	}

	access(all) fun findReceiverCapability(address: Address, path: PublicPath, type: Type) : Capability<&{FungibleToken.Receiver}>? {
		let profileCap = self.findWalletCapability(address)
		if profileCap.check() {
			if let profile = getAccount(address).capabilities.borrow<&Profile.User>(Profile.publicPath) {
				if profile.hasWallet(type.identifier) {
					return profileCap
				}
			}
		}
		let cap = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(path)
		return cap
	}

	access(all) fun findWalletCapability(_ address: Address) : Capability<&{FungibleToken.Receiver}> {
		return getAccount(address)
		.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
	}

	access(all) fun find(_ address: Address) : &{Profile.Public} {
		return getAccount(address)
		.capabilities.borrow<&{Profile.Public}>(Profile.publicPath)!
	}


	access(all) fun createUser(name: String, createdAt:String) : @Profile.User {

		if name.length > 64 {
			panic("Name must be 64 or less characters")
		}
		if createdAt.length > 32 {
			panic("createdAt must be 32 or less characters")
		}

		return <- create Profile.User(name: name,createdAt: createdAt)
	}

	access(all) fun verifyTags(tags : [String], tagLength: Int, tagSize: Int): Bool {
		if tags.length > tagSize {
			return false
		}

		for t in tags {
			if t.length > tagLength {
				return false
			}
		}
		return true
	}

	init() {
		self.publicPath = /public/findProfile
		self.publicReceiverPath = /public/findProfileReceiver
		self.storagePath = /storage/findProfile
	}
}
