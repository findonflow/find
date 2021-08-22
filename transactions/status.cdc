
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FiNS.status(tag)
				if status.status == FiNS.LeaseStatus.LOCKED {
					panic("locked")
				}
				if status.status == FiNS.LeaseStatus.FREE {
					panic("free")
				}
    }

}
 
