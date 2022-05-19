
pub fun main(address: Address) : &{String: [String]}? {
	let account=getAccount(address)
	let publicPath=/public/FindCuratedCollections
	let link = account.getCapability<&{String: [String]}>(publicPath)
	if link.check() {
		return link.borrow()
	}
	return nil
}
	
