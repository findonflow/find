const rawFile = require('./find.json')

module.exports ={
	spec: {
		scripts: rawFile.scripts,
		transactions: rawFile.transactions
	},
	scripts: rawFile.networks["testnet"].scripts,
	transactoins: rawFile.networks["testnet"].transactions
}
