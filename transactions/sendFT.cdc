import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64, type: String) {

    prepare(account: AuthAccount) {

			  if type == "fusd" {
					let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")
					FIND.deposit(to: name, from: <- vaultRef.withdraw(amount: amount))
					return 
				}

				let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")
				FIND.deposit(to: name, from: <- vaultRef.withdraw(amount: amount))

    }

}
 
