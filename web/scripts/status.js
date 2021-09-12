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
import Profile from "../contracts/Profile.cdc"

//Check the status of a fin user
pub fun main(name: String) :  &{Profile.Public}? {
    return FIND.lookup(name)
}

`;

/**
* Method to generate cadence code for TestAsset
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const statusTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `status =>`)

  return replaceImportAddresses(CODE, fullMap);
};

export const status = async (props) => {
  const { addressMap = {}, args = [] } = props
  const code = await statusTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `status =>`);

  return executeScript({code, ...props})
}