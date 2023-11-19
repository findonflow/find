access(all) contract Debug {

	access(all) event Log(msg: String)
	
	access(account) var enabled :Bool

	access(all) fun log(_ msg: String) {
		if self.enabled {
			emit Log(msg: msg)
		}
	}

	access(account) fun enable(_ value:Bool) {
		self.enabled=value
	}

	init() {
		self.enabled=false
	}


}
