local com = import 'lib/commodore.libjsonnet';

local inv = com.inventory();

local global_params = std.get(
  inv.parameters, 'prometheus', { alerts: {} }
).alerts;

(import 'syn/alerts.libsonnet') {
  global_alert_params+: global_params {
    ignoreNames: std.set(com.renderArray(super.ignoreNames)),
  },
}
