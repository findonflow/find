import FUSD from "../contracts/standard/FUSD.cdc"


transaction() {
	prepare(account: AuthAccount) {
		destroy account.load<@FUSD.Vault>(from: /storage/fusdVault) ?? panic("Cannot load flow token vault")
	}
}
