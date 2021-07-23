package lib


import (
  "time"

	"github.com/golang/protobuf/ptypes"

	cluster "github.com/envoyproxy/go-control-plane/envoy/config/cluster/v3"
  endpoint "github.com/envoyproxy/go-control-plane/envoy/config/endpoint/v3"
  core "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
  "github.com/envoyproxy/go-control-plane/pkg/cache/types"
    "strconv"

)

// CreateMultipleCDS creates clusters with endpoints that pointed to nodeSlice nodes and each cluster points to one port from range startPort - endPort
func CreateMultipleCDS (nodeSlice []string, startPort,endPort int) []types.Resource {
  var output []types.Resource
    for i := startPort; i <= endPort; i++  {
      port := strconv.Itoa(i)
      output = append(output, MakeCluster(
                              "cl"+string(port),
                              nodeSlice,
                              uint32(i)))
  }
  return output
}


// MakeCluster will create cluster resource with endpoints
func MakeCluster(clusterName string,upstreamHosts []string, upstreamPort uint32 ) *cluster.Cluster {
  //upstreamHosts := []string{"172.17.0.3","172.17.0.4"}
  //var upstreamPort uint32  = 80

	return &cluster.Cluster{
		Name:                 clusterName,
		ConnectTimeout:       ptypes.DurationProto(5 * time.Second),
		ClusterDiscoveryType: &cluster.Cluster_Type{Type: cluster.Cluster_STRICT_DNS},
		LbPolicy:             cluster.Cluster_ROUND_ROBIN,
		// LoadAssignment:       makeEndpoint(clusterName),
		LoadAssignment:       makeEndpoint(clusterName,upstreamPort,upstreamHosts),
		DnsLookupFamily:      cluster.Cluster_V4_ONLY,
	}
}


func makeEndpoint(clusterName string,upstreamPort uint32,upstreamHosts []string ) *endpoint.ClusterLoadAssignment {
  var endpointsSlice []*endpoint.LbEndpoint

  for _,upstream := range upstreamHosts {
      lBEndpoint := &endpoint.LbEndpoint{
				HostIdentifier: &endpoint.LbEndpoint_Endpoint{
					Endpoint: &endpoint.Endpoint{
						Address: &core.Address{
							Address: &core.Address_SocketAddress{
								SocketAddress: &core.SocketAddress{
									Protocol: core.SocketAddress_TCP,
									Address:  upstream,
									PortSpecifier: &core.SocketAddress_PortValue{
										PortValue: upstreamPort,
									},
								},
							},
						},
					},
				},
			}
      endpointsSlice = append(endpointsSlice,  lBEndpoint )
  }
 	return &endpoint.ClusterLoadAssignment{
		ClusterName: clusterName,
		Endpoints: []*endpoint.LocalityLbEndpoints{{
			LbEndpoints: endpointsSlice ,
		}},
	}
}
