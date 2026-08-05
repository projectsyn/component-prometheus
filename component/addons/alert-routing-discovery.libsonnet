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
        // NOTE(sg): This is evaluated in
        // 'kube-prometheus/components/alertmanager.libsonnet' after the
        // kube-prometheus alertmanager component defaults have been underlaid
        // to `values.alertmanager`.
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
