import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

access(all) main(name: String) : NameReport? {

	if FIND.validateFindName(name) {
		let status = FIND.status(name)
		let owner = status.owner
		let cost=FIND.calculateCost(name)
		var s="TAKEN"
		if status.status == FIND.LeaseStatus.FREE {
			s="FREE"
		} else if status.status == FIND.LeaseStatus.LOCKED {
			s="LOCKED"
		}
		let findAddr = FIND.getFindNetworkAddress()
		let network = getAuthAccount(findAddr).borrow<&FIND.Network>(from: FIND.NetworkStoragePath)!
		let lease =  network.getLease(name)

		var avatar: String? = nil
		if owner != nil {
			if let ref = getAuthAccount(owner!).borrow<&Profile.User>(from: Profile.storagePath) {
				avatar = ref.getAvatar()
			}
		}
		return NameReport(status: s, cost: cost, owner: lease?.profile?.address, avatar: avatar, validUntil: lease?.validUntil, lockedUntil: lease?.lockedUntil, registeredTime: lease?.registeredTime)
	}
	return nil

}

access(all) struct NameReport {
	pub let status: String
	pub let cost: UFix64
	pub let owner: Address?
	pub let avatar: String?
	pub let validUntil: UFix64?
	pub let lockedUntil: UFix64?
	pub let registeredTime: UFix64?

	init(status: String, cost: UFix64, owner: Address?, avatar: String?, validUntil: UFix64?, lockedUntil: UFix64?, registeredTime: UFix64? ) {
		self.status=status
		self.cost=cost
		self.owner=owner
		self.avatar=avatar
		self.validUntil=validUntil
		self.lockedUntil=lockedUntil
		self.registeredTime=registeredTime
	}
}
