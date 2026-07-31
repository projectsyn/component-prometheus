local prom = import 'lib/prometheus.libsonnet';

local alertpatching = import 'lib/prometheus-alert-patching.libsonnet';

{
  api_version: prom.api_version,

  /**
  * \brief Helper to create PrometheusRule objects.
  *
  * \arg The name of the PrometheusRule.
  * \return A PrometheusRule object.
  */
  PrometheusRule(name): prom.PrometheusRule,

  /**
  * \brief Helper to create ServiceMonitor objects.
  *
  * \arg The name of the ServiceMonitor
  * \return An empty ServiceMonitor object.
  */
  ServiceMonitor(name): prom.ServiceMonitor,

  /**
  * \brief Function to render rules defined in the hierarchy
  *
  * This function assumes that the rules are defined in the hierarchy in an
  * object whose fields each represent a rule group. The function also
  * assumes that each rule group is defined as an object which uses scheme
  * '(alert:|record:)rulename' for the field names.
  *
  * \arg name the name for the resulting `PrometheusRule` manifest
  * \arg rules the object to render as rules

  * \return A single `PrometheusRule` manifest containing the rule groups.
  */
  generateRules(name, rules):
    prom.PrometheusRule(name) {
      spec: {
        groups: alertpatching.renderGroups(rules),
      },
    },

  Prometheus(name):
    error "Use component-prometheus's `instances` to create additional Prometheus instances instead of directly creating a `Prometheus` custom resource",
  Alertmanager(name):
    error "Use component-prometheus's `instances` to create additional Alertmanager instances instead of directly creating a `Alertmanager` custom resource",
}
