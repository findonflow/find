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
