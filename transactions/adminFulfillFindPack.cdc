import FindPack from "../contracts/FindPack.cdc"
import Admin from "../contracts/Admin.cdc"

// access(account) fun fulfill(packId: UInt64, types:[Type], rewardIds: [UInt64], salt:String) {
transaction(packId:UInt64, rewardIds:[UInt64], typeIdentifiers: [String], salt:String) {
	let admin: auth(Admin.Owner) &Admin.AdminProxy
	prepare(account: auth(BorrowValue) &Account) {
		self.admin =account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
	}

	execute {
		let types : [Type]=[]
		for type in typeIdentifiers {
			types.append(CompositeType(type)!)
		}

		self.admin.fulfillFindPack(packId:packId, types:types, rewardIds:rewardIds, salt:salt)
	}
}

