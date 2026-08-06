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
- Vault agent injection for the secrets, following the nectar-helm
  convention: the agent renders a `secrets.conf` overlay into
  `/etc/nectar-metrics/nectar-metrics.conf.d`, layered over the
  ConfigMap-rendered `/etc/nectar/metrics.ini` by oslo.config's
  default config search. The settings secret holds only `keystone_password`
  (the `[service_auth]` password) and optionally `sentry_dsn` (the
  `[sentry]` DSN, enabling GlitchTip/Sentry error reporting).
  Everything non-secret, including the keystone username, project and
  auth URL, is set through values (`conf.service_auth`). Set
  `vault.enabled=false` on clusters without Vault to fall back to a
  values-rendered Secret.
- A container image for the collectors
  (`registry.rc.nectar.org.au/nectar/nectar-metrics`) built from the
  nectar-metrics repo.
- A RWX-capable storage class for the collectors' working directory
  (nova's change-over-time state must persist between runs).

## Pod security

The chart runs under a namespace enforcing the `restricted` Pod
Security Standard: the CronJob pods set non-root security contexts
(the collector image's uid 42420, `nobody` for the rclone backup) and
the VictoriaMetrics resources set `useStrictSecurity`. With Vault
enabled, the injected agent containers must also comply, which
requires a vault-k8s injector recent enough (>= 1.1) to set its own
restricted-compatible security context (`AGENT_INJECT_SET_SECURITY_CONTEXT`
is on by default).

## Upgrading to 1.0.x

Chart 1.0.0 targets the oslo.config/oslo.log based nectar-metrics
(the release after 2.2.0) and is not compatible with older collector
images: credentials move from `[openstack]` to the standard
keystoneauth `[service_auth]` section, the config is read from the
default search locations (`/etc/nectar/metrics.ini` plus the
`/etc/nectar-metrics/nectar-metrics.conf.d` overlay dir) instead of
an explicit `--config`, and logs go to stderr instead of files under
/tmp.

The Vault settings secret slims down to just the actual secrets.
Before upgrading:

- add `keystone_password` (the value of the old `passwd` key) and
  keep `sentry_dsn`; the old `user`, `passwd`, `name`, `url` and
  `zone` keys are no longer read and can be removed
- set `conf.service_auth.username`, `conf.service_auth.project_name`
  and `conf.service_auth.auth_url` in the deployment values (the old
  `user`, `name` and `url` vault values)

## Cutover notes

`vmsingle.retentionPeriod` must never be lowered once data is
written, and must be in place before the first write; VictoriaMetrics
silently deletes samples older than the retention period.
