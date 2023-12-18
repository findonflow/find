
import FIND from "../contracts/FIND.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FindPack from "../contracts/FindPack.cdc"

transaction(lease: String) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(lease)
		let forgeType = Type<@FindPack.Forge>()
		if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										minterCut: 0.05, 
										description: "description", 
										externalURL: "externalURL", 
										squareImage: "squareImage", 
										bannerImage: "bannerImage", 
										socials: {
											"Twitter" : "https://twitter.com/home" ,
											"Discord" : "discord.gg/"
										})
		}

	}
}
