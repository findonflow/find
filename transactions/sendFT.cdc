import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Sender from "../contracts/Sender.cdc"
import FIND from "../contracts/FIND.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"


transaction(name: String, amount: UFix64, ftAliasOrIdentifier: String, tag: String, message:String) {

	var token : &Sender.Token
	let walletReference : &FungibleToken.Vault? 

	prepare(account: AuthAccount) {

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)

		if account.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
			account.save(<- Sender.create(), to: Sender.storagePath)
		}

		self.token =account.borrow<&Sender.Token>(from: Sender.storagePath)!
	}

	pre{
		self.walletReference != nil : "No suitable wallet linked for this account"
	}

	execute{
		let vault <- self.walletReference!.withdraw(amount: amount)
		FIND.depositWithTagAndMessage(to: name, message: message, tag: tag, vault: <- vault, from: self.token)
	}
}

 