import Admin from "../contracts/Admin.cdc"

transaction(rewards:{UInt64 : [UInt64]}, salts: {UInt64:String}) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		if rewards.length != salts.length {
			panic("Rewards and packs are not same length")
		}
		let packLength=rewards.length
		for packId in rewards.keys {
			let rewardIds = rewards[packId]!
			let salt = salts[packId]!
			adminClient.fulfill(packId: packId, rewardIds: rewardIds, salt: salt)
		}
	}
}
