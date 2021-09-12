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
pub fun main(name: String, user: Address) : FIND.LeaseInformation {
	  let leaseCollection = getAccount(user).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		return leaseCollection.borrow()!.getLease(name)!
}

`;

/**
* Method to generate cadence code for TestAsset
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const leaseStatusSingleTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `leaseStatusSingle =>`)

  return replaceImportAddresses(CODE, fullMap);
};

export const leaseStatusSingle = async (props) => {
  const { addressMap = {}, args = [] } = props
  const code = await leaseStatusSingleTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `leaseStatusSingle =>`);

  return executeScript({code, ...props})
}