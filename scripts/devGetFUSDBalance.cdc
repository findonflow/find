
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

access(all) fun main(user:Address) : UFix64{
	let ref = getAccount(user).getCapability<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance).borrow() ?? panic("Cannot borrow FUSD balance. Account address : ".concat(user.toString()))
	return ref.balance
}
