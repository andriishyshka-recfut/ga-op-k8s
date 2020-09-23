package lib

import (
  listener "github.com/envoyproxy/go-control-plane/envoy/config/listener/v3"
  core "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
  "github.com/envoyproxy/go-control-plane/pkg/wellknown"
  tcp "github.com/envoyproxy/go-control-plane/envoy/extensions/filters/network/tcp_proxy/v3"
  "github.com/golang/protobuf/ptypes"
  "github.com/envoyproxy/go-control-plane/pkg/cache/types"
)

// CreateMultipleLDS Start listeners in port range and points them to clusterts by pattern "cl"+ port
func CreateMultipleLDS (startPort,endPort int) []types.Resource {
  var output []types.Resource
    for  i := startPort; i <= endPort; i++  {
      output = append(output, MakeListener(
                      "listener"+string(i),
                      uint32(i),
                      "cl"+string(i),
        ))
    }
    return output
}



// MakeListener will create listener with specified name and assign it to specified port
func MakeListener ( listenerName string, listenerPort uint32,cluster string ) *listener.Listener {
  clusterName := &tcp.TcpProxy_Cluster{ Cluster: cluster }

  filterConfig := &tcp.TcpProxy{
    ClusterSpecifier: clusterName ,
    StatPrefix: "ingress_tcp",
  }

  pbst, err := ptypes.MarshalAny(filterConfig)
	if err != nil {
		panic(err)
	}

  return &listener.Listener{
		Name: listenerName,
		Address: &core.Address{
			Address: &core.Address_SocketAddress{
				SocketAddress: &core.SocketAddress{
					Protocol: core.SocketAddress_TCP,
					Address:  "0.0.0.0",
					PortSpecifier: &core.SocketAddress_PortValue{
						PortValue: listenerPort,
					},
				},
			},
		},
		FilterChains: []*listener.FilterChain{{
			Filters: []*listener.Filter{{
				Name: wellknown.TCPProxy,
				ConfigType: &listener.Filter_TypedConfig{
					TypedConfig: pbst ,
				},
			}},
		}},
	}
}
