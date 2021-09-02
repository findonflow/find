pub contract Debug {

	pub event Log(msg: String)
	
	access(account) var enabled :Bool

	pub fun log(_ msg: String) : String {
		if self.enabled {
			emit Log(msg: msg)
		}
		return msg
	}

	init() {
		self.enabled=false
	}

	//two accounts
	// - contracts: remove key
	// - admin that owns data, or has access to main account data
	//in admin
	//pub fun enableDebug() {
  //		Debug.enabled=true
  //}
}
