/** pragma type contract **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  deployContract,
} from 'flow-cadut'

export const CODE = `
  pub contract Debug {

	pub event Log(msg: String)
	
	access(account) var enabled :Bool

	pub fun log(_ msg: String) {
		if self.enabled {
			emit Log(msg: msg)
		}
	}

	access(account) fun enable() {
		self.enabled=true
	}

	init() {
		self.enabled=false
	}


}

`;

/**
* Method to generate cadence code for Debug transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const DebugTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `Debug =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Deploys Debug transaction to the network
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> args - list of arguments
* param Array<string> - list of signers
*/
export const  deployDebug = async (props) => {
  const { addressMap = {} } = props;
  const code = await DebugTemplate(addressMap);
  const name = "Debug"

  return deployContract({ code, name, ...props })
}