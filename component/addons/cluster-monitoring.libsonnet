local com = import 'lib/commodore.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

{
  local config = self,

  prometheus+: {
    local roleName = 'syn-cluster-monitoring-%s' % config.values.prometheus.name,
    local clusterMonitoringRole = kube.ClusterRole(roleName) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      rules: [
        {
          apiGroups: [ '' ],
          resources: [ 'namespaces', 'services', 'endpoints', 'pods' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'extensions' ],
          resources: [ 'ingresses' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'networking.k8s.io' ],
          resources: [ 'ingresses' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        /* TODO(glrf) DO WE NEED THIS? How is this managed?
        {
          apiGroups: [ 'monitoring.coreos.com' ],
          resources: [ 'servicemonitors', 'podmonitors', 'prometheusrules' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        */
      ],
    },
    ClusterMonitoringRole: clusterMonitoringRole,
    ClusterMonitoringRolebinding: kube.ClusterRoleBinding(clusterMonitoringRole.metadata.name) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      roleRef_: clusterMonitoringRole,
      subjects_: [
        config.nodeExporter.serviceAccount,
      ],
    },

    prometheus+: {
      spec+: {
        local selector = {
          matchLabels: {
            ['monitoring.syn.tools/%s' % config.values.prometheus.name]: 'true',
          },
        },
        serviceMonitorNamespaceSelector+: selector,
        podMonitorNamespaceSelector+: selector,
        probeNamespaceSelector+: selector,
      },
    },
  },


}