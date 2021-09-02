
import FIND from "../contracts/FIND.cdc"

transaction(name: String) {

    prepare(account: AuthAccount) {
        let status=FIND.status(name)
				if status.status == FIND.LeaseStatus.LOCKED {
					panic("locked")
				}
				if status.status == FIND.LeaseStatus.FREE {
					panic("free")
				}
    }

}
 
