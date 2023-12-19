import Admin from "../contracts/Admin.cdc"

transaction(rewards:{UInt64 : [UInt64]}, types: {UInt64 : [String]}, salts: {UInt64:String}) {
	prepare(account: auth(BorrowValue) &Account) {

		let adminClient=account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		if rewards.length != salts.length {
			panic("Rewards and packs are not same length")
		}

		if rewards.length != types.length {
			panic("Rewards and types are not same length")
		}

		for packId in rewards.keys {
			let rewardArray = rewards[packId]!
			 let typedType : [Type]=[]
       for type in types[packId]!{
				 typedType.append(CompositeType(type)!)
       }
			let salt = salts[packId]!
			adminClient.fulfillFindPack(packId: packId, types: typedType, rewardIds: rewardArray, salt: salt)
		}
	}
}
