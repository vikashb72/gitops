{{/* Generate istio annotations */}}
{{- define "add_istio.annotations" }}
        proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
        sidecar.istio.io/proxyCPU: 10m
        sidecar.istio.io/proxyCPULimit: '2'
        sidecar.istio.io/proxyMemory: 10Mi
        sidecar.istio.io/proxyMemoryLimit: 512Mi
{{- end }}
