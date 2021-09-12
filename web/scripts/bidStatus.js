/** pragma type script **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  executeScript
} from 'flow-cadut'

export const CODE = `
  import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIND.BidInfo]{

	let bidCollection = getAccount(user).getCapability<&{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	return bidCollection.borrow()!.getBids()
}

`;

/**
* Method to generate cadence code for TestAsset
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const bidStatusTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `bidStatus =>`)

  return replaceImportAddresses(CODE, fullMap);
};

export const bidStatus = async (props) => {
  const { addressMap = {}, args = [] } = props
  const code = await bidStatusTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `bidStatus =>`);

  return executeScript({code, ...props})
}