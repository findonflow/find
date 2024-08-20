/**

# This contract stores some commonly used paths & library functions for PriceOracle

# Author Increment Labs

*/

pub contract OracleConfig {
    // Admin resource stored in every PriceOracle contract
    pub let OracleAdminPath: StoragePath
    // Reader public interface exposed in every PriceOracle contract
    pub let OraclePublicInterface_ReaderPath: PublicPath
    // Feeder public interface exposed in every PriceOracle contract
    pub let OraclePublicInterface_FeederPath: PublicPath
    // Recommended storage path of reader's certificate
    pub let ReaderCertificateStoragePath: StoragePath

    pub fun sortUFix64List(list: [UFix64]): [UFix64] {
        let len = list.length
        var preIndex = 0
        var current = 0.0
        var i = 1
        while (i < len) {
            preIndex = i - 1
            current = list[i];
            while(preIndex >= 0 && list[preIndex] > current) {
                list[preIndex+1] = list[preIndex]
                preIndex = preIndex - 1
            }
            list[preIndex+1] = current
            i = i + 1
        }
        return list
    }

    pub fun sortUInt64List(list: [UInt64]): [UInt64] {
        let len = list.length
        var preIndex = 0
        var current: UInt64 = 0
        var i = 1
        while (i < len) {
            preIndex = i - 1
            current = list[i];
            while(preIndex >= 0 && list[preIndex] > current) {
                list[preIndex+1] = list[preIndex]
                preIndex = preIndex - 1
            }
            list[preIndex+1] = current
            i = i + 1
        }
        return list
    }

    init() {
        self.OracleAdminPath = /storage/increment_oracle_admin
        self.OraclePublicInterface_ReaderPath = /public/increment_oracle_reader_public
        self.OraclePublicInterface_FeederPath = /public/increment_oracle_feeder_public
        self.ReaderCertificateStoragePath = /storage/increment_oracle_reader_certificate
    }
}
