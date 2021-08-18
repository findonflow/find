import FIN from "../contracts/FIN.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FIN.AdminProxy>(from: FIN.AdminProxyStoragePath)!
		adminClient.advanceClock(clock)

	}
}
