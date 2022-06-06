import CuratedCollection from "../contracts/CuratedCollection.cdc"

transaction(collections: {String :  [String]}) {
	prepare(account: AuthAccount) {

		let path=CuratedCollection.storagePath
		let publicPath=CuratedCollection.publicPath

		account.save(<- CuratedCollection.createCuratedCollection(), to: path)
		account.link<&CuratedCollection.Collection>( publicPath, target: path)

	}
}
