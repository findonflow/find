package findGo

type FindMarketCutStruct_ThresholdCut struct {
	Name           string         `json:"name"`
	Address        string         `json:"address" cadence:"address,cadenceAddress"`
	Cut            float64        `json:"cut"`
	Description    string         `json:"description"`
	PublicPath     string         `json:"publicPath"`
	MinimumPayment float64        `json:"minimumPayment"`
	Extra          map[string]any `json:"extra"`
}

type FindPack_PackRegisterInfo struct {
	Forge               string                          `json:"forge"`
	Name                string                          `json:"name"`
	Description         string                          `json:"description"`
	TypeId              uint64                          `json:"typeId"`
	ExternalURL         string                          `json:"externalURL"`
	SquareImageHash     string                          `json:"squareImageHash"`
	BannerHash          string                          `json:"bannerHash"`
	Socials             map[string]string               `json:"socials"`
	PaymentAddress      string                          `json:"paymentAddress" cadence:"paymentAddress,cadenceAddress"`
	PaymentType         string                          `json:"paymentType"`
	OpenTime            float64                         `json:"openTime"`
	PackFields          map[string]string               `json:"packFields"`
	PrimaryRoyalty      []FindPack_Royalty              `json:"primaryRoyalty"`
	SecondaryRoyalty    []FindPack_Royalty              `json:"secondaryRoyalty"`
	RequiresReservation bool                            `json:"requiresReservation"`
	NFTTypes            []string                        `json:"nftTypes"`
	StorageRequirement  uint64                          `json:"storageRequirement"`
	SaleInfo            []FindPack_PackRegisterSaleInfo `json:"saleInfo"`
	Extra               map[string]interface{}          `json:"extra"`
}

type FindPack_Royalty struct {
	Recipient   string                 `json:"recipient" cadence:"recipient,cadenceAddress"`
	Cut         float64                `json:"cut"`
	Description string                 `json:"description"`
	Extra       map[string]interface{} `json:"extra"`
}

type FindPack_PackRegisterSaleInfo struct {
	Name      string                     `json:"name"`
	StartTime float64                    `json:"startTime"`
	Price     float64                    `json:"price"`
	Verifiers []FindVerifier_HasOneFLOAT `json:"verifiers"`
	VerifyAll bool                       `json:"verifyAll"`
	Extra     map[string]interface{}     `json:"extra"`
}

type FindVerifier_HasOneFLOAT struct {
	FloatEventIds []uint64 `json:"floatEventIds"`
	Description   string   `json:"description"`
}

type GeneratedExperience_CollectionInfo struct {
	Season uint64 `json:"season"`
	Royalties []interface{} `json:"royalties"`
	RoyaltiesInput []FindPack_Royalty `json:"royaltiesInput"`
	SquareImage string `json:"squareImage"`
	BannerImage string `json:"bannerImage"`
	Description string `json:"description"`
	Extra map[string]interface{} `json:"extra"`
}

type GeneratedExperience_Info struct {
	Season uint64 `json:"season"`
	Name string `json:"name"`
	Description string `json:"description"`
	ThumbnailHash string `json:"thumbnailHash"`
	FullsizeHash string `json:"fullsizeHash"`
	Edition uint64 `json:"edition"`
	MaxEdition uint64 `json:"maxEdition"`
	Artist string `json:"artist"`
	Rarity string `json:"rarity"`
	Extra map[string]interface{} `json:"extra"`

}
