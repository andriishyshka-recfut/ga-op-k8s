package main

import (

  "os"
    "math/rand"
    "time"
    "strings"
    "log"
    "lib"
  	"context"
    "reflect"
    "strconv"
    testv3 "github.com/envoyproxy/go-control-plane/pkg/test/v3"
    serverv3 "github.com/envoyproxy/go-control-plane/pkg/server/v3"
    cachev3 "github.com/envoyproxy/go-control-plane/pkg/cache/v3"
    "github.com/envoyproxy/go-control-plane/pkg/cache/types"

  )


func generateSnapshot( clustersSlice,listenerSlice []types.Resource ) cachev3.Snapshot {

	return cachev3.NewSnapshot(
		getRandString() ,
		[]types.Resource{}, // endpoints
		clustersSlice, // Cluster
		[]types.Resource{}, // Routes
		listenerSlice,
		[]types.Resource{}, // runtimes
		//[]types.Resource{}, // secrets
	)
}

func getRandString() string {
  rand.Seed(time.Now().UTC().UnixNano())
  var output strings.Builder
  charSet := "abcdedfghijklmnopqrstABCDEFGHIJKLMNOP"
  length := 20
    for i := 0; i < length; i++ {
        random := rand.Intn(len(charSet))
        randomChar := charSet[random]
        output.WriteString(string(randomChar))
    }
  return output.String()
}

func main() {

  var l lib.Logger = lib.Logger{}
  var xDSPort uint = 1234
  var nodeID string = "test-id"

  var masterEndpointURL string  = os.Getenv("MASTER_ENDPOINT_URL")
  //var nodePort uint32
  nodePort, err := strconv.Atoi(os.Getenv("NODE_PORT"))
  if err != nil {
        // handle error
        log.Println(err)
        os.Exit(2)
    }


  // Create cache
  cache := cachev3.NewSnapshotCache(false, cachev3.IDHash{}, l)

  var prevNodeSlice []string
   go func(){
     for {

    var nodeSlice []string = lib.GetRunnningK8sNodes(masterEndpointURL)
    // verify if nodes changed somehow
    if reflect.DeepEqual(prevNodeSlice,nodeSlice) {
    // nodes not changed. Do nothing this time
    time.Sleep(60 * time.Second)
    } else {
    // some nodes changed
      log.Printf("Nodes changed. Updating snapshot. Was: %+v\n New: %+v",prevNodeSlice,  nodeSlice)
      var clustersSlice []types.Resource = lib.CreateMultipleCDS(nodeSlice, 30000, 30020 )
      var listenerSlice []types.Resource = lib.CreateMultipleLDS(3000,30020)
      // Add infra cluster
      clustersSlice = append(clustersSlice, lib.MakeCluster(
                                            "infra-ingress",
                                            nodeSlice,
                                            uint32(nodePort)))

      // Create new configuration Snapshot which should  be populated to envoy
      snapshot := generateSnapshot(clustersSlice,listenerSlice)
      if err := snapshot.Consistent(); err != nil {
        log.Printf("snapshot inconsistency: %+v\n%+v", snapshot, err)
        os.Exit(1)
      }
      l.Debugf("will serve snapshot %+v", snapshot)
      // Add the snapshot to the cache
      if err := cache.SetSnapshot(nodeID, snapshot); err != nil {
        log.Printf("snapshot error %q for %+v", err, snapshot)
        os.Exit(1)
      }
      prevNodeSlice = nodeSlice
      time.Sleep(60 * time.Second)
    } }
  }()

  log.Println("Starting...")

  ctx := context.Background()
  cb := &testv3.Callbacks{Debug: l.Debug}
	srv := serverv3.NewServer(ctx, cache, cb)
	lib.RunServer(ctx, srv, xDSPort )

}
