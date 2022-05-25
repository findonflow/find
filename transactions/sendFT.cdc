import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import Sender from "../contracts/Sender.cdc"
import FIND from "../contracts/FIND.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"


transaction(name: String, amount: UFix64, ftAliasOrIdentifier: String, tag: String, message:String) {

	prepare(account: AuthAccount) {

		//TODO: copy from Register from FIND-114

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet")
		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		if account.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
			account.save(<- Sender.create(), to: Sender.storagePath)
		}

		let token =account.borrow<&Sender.Token>(from: Sender.storagePath)!
		let vault <- walletReference.withdraw(amount: amount)
		FIND.depositWithTagAndMessage(to: name, message: message, tag: tag, vault: <- vault, from: token)
	}

}

