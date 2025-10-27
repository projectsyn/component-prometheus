// On vclusters the kubelet is not exposed to customers since vclusters run as pods.
// Disable scrape jobs, service monitors, and alert groups for kubelet by overwriting 'main.libsonnet' defaults

local ruleFilter(group) =
  local usesKubeletJob(rule) =
    std.objectHas(rule, 'expr') &&
    (std.length(std.findSubstr('job="kubelet"', rule.expr)) > 0 ||
     std.length(std.findSubstr("job='kubelet'", rule.expr)) > 0);

  group {
    rules: std.filter(
      function(rule) !usesKubeletJob(rule),
      group.rules
    ),
  };

{
  kubernetesControlPlane+: {
    serviceMonitorKubelet:: null,
    prometheusRule+: {
      spec+: {
        local g = super.groups,
        groups: std.map(
          ruleFilter,
          [
            h
            for h in g
            if h.name != 'kubernetes-system-kubelet' && h.name != 'kubelet.rules'
          ]
        ),
      },
    },
  },
}
