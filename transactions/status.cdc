
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FiNS.status(tag)
				if status == FiNS.LeaseStatus.LOCKED {
					panic("locked")
				}
    }

}
 
