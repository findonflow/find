import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

pub contract FindForge {

	// PlatformMinter is a compulsory element for minters 
	pub struct MinterPlatform {
		pub let platform: Capability<&{FungibleToken.Receiver}>
		pub let platformPercentCut: UFix64
		pub let name: String
		pub let description: String 
		pub let externalURL: String 
		pub let squareImage: String 
		pub let bannerImage: String 

		init(name: String, platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64, description: String, externalURL: String, squareImage: String, bannerImage: String) {
			self.platform=platform
			self.platformPercentCut=platformPercentCut
			self.name=name
			self.description=description 
			self.externalURL=externalURL 
			self.squareImage=squareImage 
			self.bannerImage=bannerImage
		}
	}

	// ForgeMinter Interface 
	pub resource interface ForgeMinter {
		pub let platform: MinterPlatform
		access(account) fun mint(platform: MinterPlatform, data: AnyStruct) : @NonFungibleToken.NFT 
	}

	pub resource interface Forge {
		access(account) fun createForgeMinter(_ platform: MinterPlatform) : @{ForgeMinter}
	}

}