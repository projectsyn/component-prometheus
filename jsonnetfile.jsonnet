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
  ],
  legacyImports: true,
}
