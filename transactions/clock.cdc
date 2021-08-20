import FiNS from "../contracts/FiNS.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FiNS.AdminProxy>(from: FiNS.AdminProxyStoragePath)!
		adminClient.advanceClock(clock)

	}
}
