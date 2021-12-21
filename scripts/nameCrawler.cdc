import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

pub fun main(names: [String]) : [FIND.LeaseInformation]{
	let items : [FIND.LeaseInformation]=[]
	for name in names {
		let nameStatus=FIND.status(name)
		if let address=nameStatus.owner {
			let account=getAccount(address)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			items.append(leaseCap.borrow()!.getLease(name)!)
		} else {
			//free name now
			continue
		}
	}
	return items
}
