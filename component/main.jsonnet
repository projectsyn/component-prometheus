// main template for kube_prometheus
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local lib = import 'lib/prometheus.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.prometheus;
local instance = inv.parameters._instance;

local common = import 'common.libsonnet';

local instanceStacks = std.mapWithKey(
  function(name, param) common.stackForInstance(name),
  params.instances
);
local mergedParams = std.mapWithKey(
  function(name, param) params.base + com.makeMergeable(param),
  params.instances
);


local namespacesPromLabels =
  local f(prev, i) =
    local p = mergedParams[i];
    local stack = instanceStacks[i];
    prev {
      [if p.prometheus.enabled then stack.values.prometheus.namespace]+: {
        ['monitoring.syn.tools/%s' % i]: 'true',
      },
    };
  std.foldl(f, std.objectFields(params.instances), {});

local namespaces = std.foldl(
  function(namespaces, nsName)
    if params.namespaces[nsName] != null then
      namespaces {
        ['00_namespace_%s' % nsName]:
          kube.Namespace(nsName)
          +
          {
            metadata+: {
              labels+: com.getValueOrDefault(namespacesPromLabels, nsName, {}),
            },
          }
          + {
            metadata+: com.makeMergeable(params.namespaces[nsName]),
          },
      }
    else
      namespaces
  , std.objectFields(params.namespaces), {}
);

local secrets = std.foldl(
  function(secrets, secret) secrets {
    ['01_secret_%s' % secret.metadata.name]: secret {
      stringData: std.mapWithKey(
        function(name, data)
          if std.type(data) == 'string' then
            data
          else
            std.manifestJson(data),
        super.stringData
      ),
    },
  },
  com.generateResources(
    params.secrets,
    function(name) kube.Secret(name) {
      metadata+: {
        namespace: params.base.common.namespace,
      } + common.metadata,
    }
  ),
  {}
);


local renderInstance = function(instanceName, stack)
  local prometheus = common.render_component(stack, 'prometheus', 20, instanceName);
  local alertmanager = common.render_component(stack, 'alertmanager', 30, instanceName);
  local grafana = common.render_component(stack, 'grafana', 40, instanceName);
  local nodeExporter = common.render_component(stack, 'nodeExporter', 50, instanceName);
  local blackboxExporter = common.render_component(stack, 'blackboxExporter', 60, instanceName);
  local kubernetesControlPlane = common.render_component(stack, 'kubernetesControlPlane', 70, instanceName);
  local prometheusAdapter = common.render_component(stack, 'prometheusAdapter', 80, instanceName);
  local kubeStateMetrics = common.render_component(stack, 'kubeStateMetrics', 90, instanceName);
  local kubePrometheus = common.render_component(stack, 'kubePrometheus', 100, instanceName);

  local p = mergedParams[instanceName];
  (if p.prometheus.enabled then prometheus else {}) +
  (if p.alertmanager.enabled then alertmanager else {}) +
  (if p.grafana.enabled then grafana else {}) +
  (if p.nodeExporter.enabled then nodeExporter else {}) +
  (if p.blackboxExporter.enabled then blackboxExporter else {}) +
  (if p.kubernetesControlPlane.enabled then kubernetesControlPlane else {}) +
  (if p.prometheusAdapter.enabled then prometheusAdapter else {}) +
  (if p.kubeStateMetrics.enabled then kubeStateMetrics else {}) +
  (if p.kubePrometheus.enabled then kubePrometheus else {})

;

local instances = std.mapWithKey(
  function(name, params) renderInstance(name, params),
  instanceStacks
);

local enableAlert(name, object) =
  if object.kind == 'PrometheusRule' then
    lib.Enable(object)
  else object;

local removePartialManifests(obj) = {
  [k]: obj[k]
  for k in std.objectFields(obj)
  if std.objectHas(obj[k], 'kind')
};

(import 'operator.libsonnet')
+ namespaces
+ secrets
+ std.mapWithKey(
  enableAlert,
  std.foldl(
    function(prev, i) prev + removePartialManifests(instances[i]),
    std.objectFields(instances),
    {}
  )
)
