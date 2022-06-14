import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"


pub contract FindForge {

	access(contract) let minterPlatforms : {String : {String: MinterPlatform}}

	//TODO: make this {Type: @{Forge}}
	access(contract) let forgeTypes : [Type]
	access(contract) var platformCut: UFix64 

	// PlatformMinter is a compulsory element for minters 
	pub struct MinterPlatform {
		pub let platform: Capability<&{FungibleToken.Receiver}>
		pub let platformPercentCut: UFix64
		pub let name: String 
		//todo: do we need name here?

		//a user should be able to change these 6?
		pub let description: String 
		pub let externalURL: String 
		pub let squareImage: String 
		pub let bannerImage: String 
		pub let minterCut: UFix64?
		pub let socials: {String : String}

		init(name: String, platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64, minterCut: UFix64? ,description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
			self.name=name
			self.platform=platform
			self.platformPercentCut=platformPercentCut
			self.description=description 
			self.externalURL=externalURL 
			self.squareImage=squareImage 
			self.bannerImage=bannerImage
			self.minterCut=minterCut 
			self.socials=socials
		}

		pub fun getMinterFTReceiver() : Capability<&{FungibleToken.Receiver}> {
			let address = FIND.lookup(self.name)?.getAddress() ?? panic("This name is not linked to address properly. ")
			return getAccount(address).getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		}

	}

	// ForgeMinter Interface 
	pub resource interface Forge{
		access(account) fun mint(platform: MinterPlatform, data: AnyStruct) : @NonFungibleToken.NFT 
	}

	// pub resource interface ForgeMinter 
	// 	access(account) fun createForge(_ platform: FindForge.MinterPlatform) : @AnyResource{Forge} 
	// }

	pub fun getMinterPlatform(name: String, nftType: Type) : MinterPlatform? {
		if FindForge.minterPlatforms[nftType.identifier] == nil {
			return nil
		}
		return FindForge.minterPlatforms[nftType.identifier]![name]
	}

	pub fun getMinterPlatformsByName() : {String : {String : MinterPlatform}} {
		return FindForge.minterPlatforms
	}

	pub fun checkMinterPlatform(name: String, nftType: Type) : Bool {
		if FindForge.minterPlatforms[nftType.identifier] == nil {
			return false
		}
		if FindForge.minterPlatforms[nftType.identifier]![name] == nil {
			return false
		}
		return true 
	}

	pub fun setMinterPlatform(lease: &FIND.Lease, nftType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
		pre{
			FindForge.forgeTypes.contains(nftType) : "This forge is not supported "
		}

		if !lease.checkAddon(addon: "forge") {
			panic("Please purchase forge addon to start forging. Name: ".concat(lease.getName()))
		}

		let name = lease.getName() 
		let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterPlatform = MinterPlatform(name:name, platform:receiverCap, platformPercentCut: FindForge.platformCut, minterCut: minterCut ,description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials) 

		FindForge.minterPlatforms[nftType.identifier]!.insert(key: name, minterPlatform)
	}

	pub fun removeMinterPlatform(lease: &FIND.Lease, nftType: Type) {
		pre{
			FindForge.minterPlatforms[nftType.identifier] != nil : "This minter platform does not exist. Forge Type : ".concat(nftType.identifier)
		}
		let name = lease.getName() 

		if FindForge.minterPlatforms[nftType.identifier]![name] == nil {
			panic("This user does not have corresponding minter platform under this forge.  Forge Type : ".concat(nftType.identifier))
		}

		FindForge.minterPlatforms[nftType.identifier]!.remove(key: name)
	}

	pub fun mint (lease: &FIND.Lease, nftType: Type , data: AnyStruct, mintFN: (() : @{Forge})) : @NonFungibleToken.NFT {
		pre{
			FindForge.minterPlatforms.containsKey(nftType.identifier) : "The minter platform is not set. Please set up properly before mint."
		}
		let name = lease.getName()

		if !lease.checkAddon(addon: "forge") {
			panic("Please purchase forge addon to start forging. Name: ".concat(lease.getName()))
		}

		let minterPlatform = FindForge.minterPlatforms[nftType.identifier]![name] ?? panic("The minter platform is not set. Please set up properly before mint.")

		let forge <- mintFN()

		let nft <- forge.mint(platform: minterPlatform, data: data) 

		assert(nft.isInstance(nftType), message: "The type passed in does not match with the minting NFT type. ")

		//TODO: deposit into collection, borrow back viewResolver. Emit a good event

		//nftType (identifier), id, uuid, name, thumbnail, to, toName
		//Mint event
		destroy forge

		return <- nft
	}

	access(account) fun addPublicForgeType(type: Type) {
		pre{
			!FindForge.minterPlatforms.containsKey(type.identifier) : "This type is already registered to the registry. "
		}
		FindForge.forgeTypes.append(type)
		FindForge.minterPlatforms[type.identifier] = {}
	}

	access(account) fun addPrivateForgeType(name: String, type: Type) {
		if !FindForge.minterPlatforms.containsKey(type.identifier) {
			FindForge.minterPlatforms[type.identifier] = {}
		}
		let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterPlatform = MinterPlatform(name:name, platform:receiverCap, platformPercentCut: FindForge.platformCut, minterCut: nil ,description: "", externalURL: "", squareImage: "", bannerImage: "", socials: {}) 
		FindForge.minterPlatforms[type.identifier]!.insert(key: name, minterPlatform)
	}

	access(account) fun removeForgeType(type: Type) {
		pre{
			FindForge.minterPlatforms.containsKey(type.identifier) : "This type is not registered to the registry. "
		}
		FindForge.minterPlatforms.remove(key: type.identifier)
	}

	access(account) fun setPlatformCut(_ cut: UFix64) {
		FindForge.platformCut = cut
	}

	init() {
		self.minterPlatforms={}
		self.forgeTypes=[]
		self.platformCut=0.025
	}

}
