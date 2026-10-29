local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local ard = import 'syn/alert-routing-discovery.libsonnet';

local inv = kap.inventory();
local params = inv.parameters.prometheus;

{
  values+:: {
    alertmanager+: {
      config: ard.alertmanagerConfig(
        params.addon_configs.alert_routing_discovery,
        // NOTE(sg): This only evaluates properly when the component
        // parameters are applied to kube-prometheus before this addon is
        // applied, cf. `component/common.libsonnet`.
        super.config,
        nullReceiver='__prometheus_null',
        fallbackTeam=params.addon_configs.alert_routing_discovery.fallback_team
      ),
    },
  },
  alertmanager+: {
    [if params.addon_configs.alert_routing_discovery.debug_config_map then
      'teamRoutingDebug']: {
      apiVersion: 'v1',
      kind: 'ConfigMap',
      metadata: {
        name: 'alert-routing-discovery-debug',
        namespace: $.values.alertmanager.namespace,
      },
      data: ard.debugConfigMapData(
        params.addon_configs.alert_routing_discovery,
        // NOTE(sg): not needed since we drop the `alertmanager` field from
        // the resulting configmap, see the comment above for why we can't get
        // an accurate copy of the underlay `values.alertmanager.config` here.
        { route: {} },
        nullReceiver='__prometheus_null',
        fallbackTeam=params.addon_configs.alert_routing_discovery.fallback_team
      ) {
        alertmanager:: {},
      },
    },
  },
}
