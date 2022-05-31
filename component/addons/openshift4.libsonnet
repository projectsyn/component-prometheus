// This addon changes openshift specific paths/namespaces/services.
// The `remove-securitycontext` addon is also needed for running on openshift.

local kubeSchedulerNamespace = 'openshift-kube-scheduler';
local kubeControllerManagerNamespace = 'openshift-kube-controller-manager';
local kubeDNSNamespace = 'openshift-dns';

local patchPortName = function(spec)
  spec {
    endpoints: [
      ep {
        port: 'https',
      }
      for ep in super.endpoints
    ],
  };

{
  values+:: {
    prometheus+: {
      namespaces+: [ kubeSchedulerNamespace, kubeControllerManagerNamespace, kubeDNSNamespace ],
    },
  },

  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: {
        endpoints+: [],
      },
    },

    serviceMonitorKubeControllerManager+: {
      spec+: {
        endpoints+: [],
      },
    },
  },
}
+
{
  local config = self,

  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: patchPortName(super.spec) {
        jobLabel: 'prometheus',
        namespaceSelector: {
          matchNames: [ kubeSchedulerNamespace ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-scheduler' },
        },
      },
    },

    serviceMonitorKubeControllerManager+: {
      spec+: patchPortName(super.spec) {
        jobLabel: 'prometheus',
        namespaceSelector: {
          matchNames: [ kubeControllerManagerNamespace ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-controller-manager' },
        },
      },
    },

    serviceMonitorCoreDNS+: {
      spec+: {
        jobLabel:: null,
        namespaceSelector: {
          matchNames: [ kubeDNSNamespace ],
        },
      },
    },
  },
}
