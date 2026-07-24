# nectar-metrics-helm

Kubernetes deployment of the Nectar status-page metrics stack:

- an HA pair of single-node VictoriaMetrics instances (full copy
  each), managed by the VictoriaMetrics operator
- vmagent on the write path: persistent-queue buffering and
  replication to both instances (heals an instance outage by replay)
- vmauth on the read path: first-available failover so langstroth
  reads a consistent view
- the nectar-metrics collectors (nova, rcshibboleth, and optionally
  cinder) as CronJobs, replacing the crontab on the cron host
- optional nightly logical backup (full /api/v1/export to S3)

This intentionally does NOT use VictoriaMetrics cluster mode: at a
few thousand series, replicated single-nodes are the
upstream-recommended HA pattern and far simpler to operate. The
Ceilometer-scale telemetry stack is a separate installation.

## Requirements

- The VictoriaMetrics operator, deployed separately (ArgoCD app
  `victoria-metrics-operator` in argocd-apps). On a cluster without
  the operator CRDs, install this chart once with
  `components.vmstack=false` first.
- Vault agent injection for the OpenStack credentials: the vault
  secret's key/value pairs are rendered as the `[openstack]` section
  of metrics.ini. Set `vault.enabled=false` on clusters without
  Vault to fall back to a values-rendered Secret.
- A container image for the collectors
  (`registry.rc.nectar.org.au/nectar/nectar-metrics`) built from the
  nectar-metrics repo.
- A RWX-capable storage class for the collectors' working directory
  (nova's change-over-time state must persist between runs).

## Cutover notes

`vmsingle.retentionPeriod` must never be lowered once data is
written, and must be in place before the first write; VictoriaMetrics
silently deletes samples older than the retention period.
