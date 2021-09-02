
import FIND from "../contracts/FIND.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FIND.status(tag)
				if status.status == FIND.LeaseStatus.LOCKED {
					panic("locked")
				}
				if status.status == FIND.LeaseStatus.FREE {
					panic("free")
				}
    }

}
 
