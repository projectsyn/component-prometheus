local kap = import 'lib/kapitan.libjsonnet';
local alerts = import 'syn/alerts.libsonnet';

local inv = kap.inventory();
local params = inv.parameters.prometheus;

{
  prometheus+: {
    prometheusRule+: {
      spec+: {
        groups+: alerts.renderGroups(params.addon_configs.additional_rules),
      },
    },
  },
}
