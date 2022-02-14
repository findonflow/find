const rawFile = require('./find.json')
const network = "testnet" //process.env.REACT_APP_NETWORK

const resources =rawFile.networks[network]

const solution = {
	scripts: {},
	transactions: {}
}
for (const name in resources.scripts) {
	solution.scripts[name] = {
		code : resources.scripts[name],
		spec: rawFile.scripts[name]
	}
}
for (const name in resources.transactions) {
	solution.transactions[name] = {
		code : resources.transactions[name],
		spec: rawFile.transactions[name]
	}
}

module.exports = solution
