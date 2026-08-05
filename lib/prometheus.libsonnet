/**
 * \file Helper to create Prometheus Operator objects and configure cluster monitoring
 **/
local kube = import 'lib/kube.libjsonnet';

local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;


local getInstanceConfig(instance) = params.base + com.makeMergeable(params.instances[instance]);

/**
 * \brief Patch the provided Namespace to be picked up by Prometheus
 *
 * This function adds a label to the namespace that will make the provided
 * Prometheus instance discover ServiceMonitors, PodMonitors, and Probes in
 * the namespace. If no instance is provided than the default instance is used.
 *
 * If you don't provide an instance and no default instance is configured the
 * function will return the unmodifed namespace.
 *
 * The`cluster-monitoring` addon needs to be enabled for this label to take effect.
 *
 * \arg `namespace` The namespace to annotate
 * \arg `instance` The name of the instance that should pick up the namespace
 * \return A namespace with correct label
 */
local registerNamespace(namespace, instance=params.defaultInstance) = namespace {
  metadata+: {
    labels+: {
      [if instance != null then 'monitoring.syn.tools/%s' % instance]: 'true',
    },
  },
};

/**
 * \brief A NetworkPolicy allowing ingress traffic from Prometheus
 *
 * This function returns a NetworkPolicy that allows ingress traffic from
 * the namespace of the provided Prometheus instance. If no instance is
 * provided than the default instance is used.
 *
 * If you don't provide an instance and no default instance is configured the
 * function will return an empty object.
 *
 * \arg `instance` The name of the instance to allow traffic from
 * \return A NetworkPolicy allowing ingress from Prometheus namespace
 */
local networkPolicy(instance=params.defaultInstance) =
  if instance == null then
    {}
  else
    kube.NetworkPolicy('allow-from-prometheus-%s' % instance) {
      local config = getInstanceConfig(instance),
      local namespace = (config.common + com.makeMergeable(config.prometheus)).namespace,
      spec+: {
        ingress+: [ {
          from: [
            {
              namespaceSelector: {
                matchLabels: {
                  'kubernetes.io/metadata.name': namespace,
                },
              },
            },
          ],
        } ],
      },
    };

// Define Prometheus Operator API versions
local api_version = {
  monitoring: 'monitoring.coreos.com/v1',
};

/**
  * \brief Helper to enable Monitor or Rule
  *
  * The`cluster-monitoring` addon needs to be enabled for this to have an effect.
  *
  * \arg A ServiceMonitor, PodMonitor, Probe, or PrometheusRule
  * \return The given object with the necessary labels for Prometheus to pick it up
  */
local enable(object) = object {
  metadata+: {
    labels+: {
      'monitoring.syn.tools/enabled': 'true',
    },
  },
};

/**
  * \brief Helper to disable Monitor or Rule
  *
  * The`cluster-monitoring` addon needs to be enabled for this to have an effect.
  *
  * \arg A ServiceMonitor, PodMonitor, Probe, or PrometheusRule
  * \return The given object with the necessary labels that makes Prometheus ignore it
  */
local disable(object) = object {
  metadata+: {
    labels+: {
      'monitoring.syn.tools/enabled': 'false',
    },
  },
};

/**
  * \brief Helper returning a reference to the Prometheus service account
  *
  * Can be used to give additional permissions to the provided Prometheus instance.
  * If no instance is provided than the default instance is used.
  *
  *
  * \arg `instance` The name of the instance
  * \return A reference to the instance's service account.
  */
local serviceAccountRef(instance=params.defaultInstance) = {
  local config = getInstanceConfig(instance),
  local namespace = (config.common + com.makeMergeable(config.prometheus)).namespace,

  kind: 'ServiceAccount',
  name: 'prometheus-%s' % instance,
  namespace: namespace,
};

/**
  * \brief Helper to create PrometheusRule objects.
  *
  * \arg The name of the PrometheusRule.
  * \return A PrometheusRule object.
  */
local prometheusRule(name) = enable(kube._Object(api_version.monitoring, 'PrometheusRule', name));

/**
 * \brief Helper to create ServiceMonitor objects.
 *
 * \arg The name of the ServiceMonitor.
 * \return A ServiceMonitor object.
 */
local serviceMonitor(name) = kube._Object(api_version.monitoring, 'ServiceMonitor', name) {
  local sm = self,

  targetNamespace:: '',
  selector:: {},
  endpoints:: {},

  spec: {
    namespaceSelector: {
      matchNames: [ sm.targetNamespace ],
    },
    selector: sm.selector,
    endpoints: std.objectValues(sm.endpoints),
  },
};
/**
 * \brief Provides a common default service monitor endpoint for endpoints with TLS and token authentication
 *
 * By default this endpoint uses the service account token and the service-ca.
 *
 * \arg `serverName` The servername used to verify the target
 * \return A service monitor endpoint with defaults for https and token authentication
 */
local serviceMonitorHttpsEndpoint(serverName) = {
  bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
  interval: '30s',
  scheme: 'https',
  port: 'metrics',
  tlsConfig: {
    caFile: '/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt',
    serverName: serverName,
  },
};

/**
 * \brief A relabel config that drops Go runtime and Prometheus http handler metrics
 */
local dropRuntimeMetrics = {
  action: 'drop',
  regex: '(go_.*|process_.*|promhttp_.*)',
  sourceLabels: [ '__name__' ],
};

/**
 * \brief Helper to create PodMonitor objects.
 *
 * \arg The name of the PodMonitor.
 * \return A PodMonitor object.
 */
local podMonitor(name) = kube._Object(api_version.monitoring, 'PodMonitor', name);

/**
 * \brief Helper to create Probe objects.
 *
 * \arg The name of the Probe.
 * \return A Probe object.
 */
local probe(name) = kube._Object(api_version.monitoring, 'Probe', name);

{
  api_version: api_version,

  RegisterNamespace: registerNamespace,
  NetworkPolicy: networkPolicy,

  Enable: enable,
  Disable: disable,

  ServiceAccountRef: serviceAccountRef,

  PrometheusRule: prometheusRule,

  ServiceMonitor: serviceMonitor,
  ServiceMonitorHttpsEndpoint: serviceMonitorHttpsEndpoint,
  DropRuntimeMetrics: dropRuntimeMetrics,

  PodMonitor: podMonitor,
  Probe: probe,
}
