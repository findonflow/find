import FUSD from "../contracts/standard/FUSD.cdc"


transaction() {
	prepare(account: AuthAccount) {
		account.unlink(/public/fusdBalance)
		account.unlink(/public/fusdReceiver)
		destroy account.load<@FUSD.Vault>(from: /storage/fusdVault) ?? panic("Cannot load flow token vault")
	}
}
