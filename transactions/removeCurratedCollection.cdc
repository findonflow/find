import CuratedCollection from "../contracts/CuratedCollection.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {

		let path=CuratedCollection.storagePath
		let publicPath=CuratedCollection.publicPath

		if let ref = account.borrow<&CuratedCollection.Collection>(from:path) {
			ref.setCuratedCollection(name: name, items: nil)
			return
		}


		account.save(<- CuratedCollection.createCuratedCollection(), to: path)

		let link = account.getCapability<&CuratedCollection.Collection>(publicPath)
		if !link.check() {
			account.link<&CuratedCollection.Collection>( publicPath, target: path)
		}
	}
}
