package lib


import (
    "net/http"
    "encoding/json"
    "log"
    "crypto/tls"
  //  "time"
)

type nodesResponseStruct struct {
	Items []struct {
		Status struct {
			Addresses []struct {
				Type    string `json:"type"`
				Address string `json:"address"`
			} `json:"addresses"`
		} `json:"status,omitempty"`
	} `json:"items"`
}

// GetRunnningK8sNodes perform http request to k8s cluster and return list of active nodes
func GetRunnningK8sNodes (masterEndpointURL string) []string {
  var nodesList []string;
  customTransport := http.DefaultTransport.(*http.Transport).Clone()
  customTransport.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
  client := &http.Client{Transport: customTransport}
  resp, err := client.Get(masterEndpointURL + "/api/v1/nodes")
  if err != nil {
        log.Println(err)
    }
  defer resp.Body.Close()
  var r nodesResponseStruct
  err = json.NewDecoder(resp.Body).Decode(&r)
  if err != nil {
        log.Printf("Json decode failure: %+v",err)
    }
  for _, item := range r.Items {
    for _,element := range item.Status.Addresses {

        if element.Type == "InternalIP" {
          nodesList = append(nodesList,  element.Address )
        }
      }
  }
  return nodesList
}
