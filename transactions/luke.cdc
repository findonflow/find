import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction() {

	let leases : &FIND.LeaseCollection?
	let vaultRef : &FUSD.Vault? 

	prepare(account: AuthAccount) {

		self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)

	}

	pre{
		self.leases != nil : "Could not borrow reference to the leases collection"
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
	}

	execute {
		let name = "nonfungerbils"
		let addon  = "forge"
		let amount= 50.0
		let minterCut = 0.075

		let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
		self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
		let lease=self.leases!.borrow(name)

		let forgeType = NFGv3.getForgeType()
		FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										minterCut: minterCut, 
										//these values will be replaced with what we have from NFG contract
										description: collectionDescription, 
										externalURL: collectionExternalURL, 
										squareImage: collectionSquareImage, 
										bannerImage: collectionBannerImage, 
										socials: socials
									)
		}

	}
}

