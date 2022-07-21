import Dandy from "../contracts/Dandy.cdc"

transaction(target: UInt64) {
	prepare(account: AuthAccount){}
	execute{
		let col <- Dandy.createEmptyCollection()
		var uuid = col.uuid 
		destroy col
		while uuid < target {
			let c <- Dandy.createEmptyCollection()
			destroy c
			uuid = uuid + 1
		}
	}
}