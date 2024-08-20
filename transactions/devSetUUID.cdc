import "Dandy"

transaction(target: UInt64) {
	prepare(account: auth(BorrowValue) &Account){}
	execute{
		let col <- Dandy.createEmptyCollection()
		var uuid = col.uuid
		destroy col
		if uuid > target {
			panic("UUID is already greater than target. Now at ".concat(uuid.toString()) )
		}
		while uuid < target {
			let c <- Dandy.createEmptyCollection()
			destroy c
			uuid = uuid + 1
		}
	}
}
