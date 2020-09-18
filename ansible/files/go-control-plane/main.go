package main

import (

  //"fmt"
  "os"
    "math/rand"
    "time"
    //"fmt"
    "strings"

  "./lib"
  	"context"
    testv3 "github.com/envoyproxy/go-control-plane/pkg/test/v3"
    serverv3 "github.com/envoyproxy/go-control-plane/pkg/server/v3"
    cachev3 "github.com/envoyproxy/go-control-plane/pkg/cache/v3"
    "github.com/envoyproxy/go-control-plane/pkg/cache/types"
  )


func generateSnapshot(version string ) cachev3.Snapshot {

	return cachev3.NewSnapshot(
		version ,
		[]types.Resource{}, // endpoints
		[]types.Resource{ lib.MakeCluster("test")}, // Cluster
		[]types.Resource{}, // Routes
		[]types.Resource{ lib.MakeListener("test", 30010 )},
		[]types.Resource{}, // runtimes
		[]types.Resource{}, // secrets
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


  var l = lib.Logger{}
  var xDSPort uint = 1234
  var nodeID string = "test-id"

  // Create cache
  cache := cachev3.NewSnapshotCache(false, cachev3.IDHash{}, l)



   go func(){
     for {
    // Create new configuration Snapshot which should  be populated to envoy
    snapshot := generateSnapshot(getRandString())

    if err := snapshot.Consistent(); err != nil {
      l.Errorf("snapshot inconsistency: %+v\n%+v", snapshot, err)
      os.Exit(1)
    }
    l.Debugf("will serve snapshot %+v", snapshot)

    // Add the snapshot to the cache
    if err := cache.SetSnapshot(nodeID, snapshot); err != nil {
      l.Errorf("snapshot error %q for %+v", err, snapshot)
      os.Exit(1)
    }

    //fmt.Println("Updating snapshot...")
    time.Sleep(60 * time.Second)
    }
  }()
  l.Debugf("Starting...")

  ctx := context.Background()
  cb := &testv3.Callbacks{Debug: l.Debug}
	srv := serverv3.NewServer(ctx, cache, cb)
	lib.RunServer(ctx, srv, xDSPort )

}
