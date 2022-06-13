import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"


pub contract FindForge {

	// PlatformMinter is a compulsory element for minters 
	pub struct MinterPlatform {
		pub let platform: Capability<&{FungibleToken.Receiver}>
		pub let platformPercentCut: UFix64
		
		//todo: do we need name here?

		//a user should be able to change these 6?
		pub var description: String 
		pub var externalURL: String 
		pub var squareImage: String 
		pub var bannerImage: String 
		//add back minterCut:UFix64?
		//socials: {}

		init(platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64, description: String, externalURL: String, squareImage: String, bannerImage: String) {
			self.platform=platform
			self.platformPercentCut=platformPercentCut
			self.description=description 
			self.externalURL=externalURL 
			self.squareImage=squareImage 
			self.bannerImage=bannerImage
		}

		//access(account) change platform, and cut
		//name let
		//normal change description/externalURL/images
	}


	//Type: NFTType
	pub fun mint(lease: &FIND.Lease, type: Type, mint: ((&{ForgeMinter}) : String)) {

		let name=lease.name
		let forgesForName=self.forgeCapabilities[name]!

		let forgeMinter = forgesForName[type.identifier]!

		let forge =     


		let minterPlatform = self.forgeCapabilities[lease.name][type.identifier]

		let minter =...
		mint(minter)
		destroy <- minter //or dont depending on implemenation
	}

	//collection of {String: 
	//store the minter plattforms or the Minters?
	//Store what kind of Forges we have

	//leasename-forge.identifier

	//forge.identifier -> lease -> Forge
	//Should this be Forge they can use or data to use the forge?
	//Cannot return capability, it should follow the lease
	access(contract) let forgeCapabilities : {String : {String: UIn64}}

	//nft collection ish type of Forge storage


	//how do a use change a minter plattform?

	//we need to be able to have only a given name use a Forge of a given Type

	//change parameters for a Forge for a name
	//get forge using  identifier, and name, change the parameters

	// ForgeMinter Interface 
	pub resource interface Forge{
		pub let platform: MinterPlatform
		access(account) fun mint(data: AnyStruct) : @NonFungibleToken.NFT 
	}

	pub resource interface ForgeMinter 
		access(account) fun createForge(_ platform: FindForge.MinterPlatform) : @AnyResource{Forge} 
	}

	init() {
		self.forgeCapabilities={}

	}

}
