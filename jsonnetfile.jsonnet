{
  version: 1,
  dependencies: [
    {
      source: {
        git: {
          remote: 'https://github.com/prometheus-operator/kube-prometheus.git',
          subdir: 'jsonnet/kube-prometheus',
        },
      },
      version: std.extVar('kube_prometheus_version'),
    },
    {
      source: {
        git: {
          remote: 'https://github.com/grafana/jsonnet-libs.git',
        },
      },
      version: 'bf12954197422f36f0803ee217e378ad055f3837',
    },
    {
      source: {
        git: {
          remote: 'https://github.com/projectsyn/jsonnet-libs',
          subdir: '',
        },
      },
      version: 'main',
      name: 'syn',
    },
  ],
  legacyImports: true,
}
