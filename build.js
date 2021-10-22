const fs = require('fs');
const path = require('path');
const transactionsPath = path.join(__dirname, 'transactions', '/')
const scriptsPath = path.join(__dirname,  'scripts', '/')

const convertCadenceToJs = async () => {
    const resultingJs = await require('cadence-to-json')({
        transactions: [ transactionsPath ],
        scripts: [ scriptsPath ],
        config: require('./flow.json')
    })
    fs.writeFile('lib/find_tmp.json', JSON.stringify(resultingJs), (err) => {
        if (err) {
            console.error("Failed to read CadenceToJs JSON");
            process.exit(1)
        }
    })
}

convertCadenceToJs()
