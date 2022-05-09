const rawFile = require('./find.json')
const network = process.env.REACT_APP_NETWORK

module.exports=rawFile.networks[network]

