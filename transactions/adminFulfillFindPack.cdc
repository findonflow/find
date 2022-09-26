import FindPack from "../contracts/FindPack.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(packId:UInt64, rewardIds:{String : [UInt64]}, salt:String) {
	let admin: &Admin.AdminProxy
	prepare(account: AuthAccount) {
		self.admin =account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
	}

	execute {
		let reward : {Type : [UInt64]} = {}
		for type in rewardIds.keys {
			reward[CompositeType(type)!] = rewardIds[type]
		}

		self.admin.fulfillFindPack(packId:packId, rewardIds:reward, salt:salt)
	}
}