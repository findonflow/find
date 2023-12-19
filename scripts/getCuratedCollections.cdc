
access(all) main(address: Address) : &{String: [String]}? {
	let account=getAccount(address)

	if account.balance == 0.0 {
		return nil
	}

	let publicPath=/public/FindCuratedCollections
	let link = account.getCapability<&{String: [String]}>(publicPath)
	if link.check() {
		return link.borrow()
	}
	return nil
}
	
