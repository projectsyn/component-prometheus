local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;

local alertpatching = import 'lib/prometheus-alert-patching.libsonnet';

local ignoreNames = std.set(com.renderArray(params.addon_configs.disable_alerts.ignoreNames));
local components = [
  'alertmanager',
  'blackboxExporter',
  'grafana',
  'kubernetesControlPlane',
  'kubePrometheus',
  'kubeStateMetrics',
  'nodeExporter',
  'prometheusAdapter',
  'prometheusOperator',
  'prometheus',
];

std.foldl(function(obj, name) obj {
  [name]+: {
    prometheusRule+: {
      spec+: {
        local groups = super.groups,
        groups: std.map(
          function(g)
            alertpatching.filterPatchRules(
              g,
              ignoreNames=ignoreNames,
              patches={},
              preserveRecordingRules=true,
              patchNames=false
            ),
          groups
        ),
      },
    },
  },
}, components, {})
