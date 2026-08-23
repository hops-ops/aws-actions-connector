### What's changed in v0.6.0

* chore(deps): update unbounded-tech/workflows-crossplane action to v2.15.0 (#7) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* chore: file-based env vars for e2e tests (#9) (by @patrickleet)

  * feat: use file-based env vars for e2e tests

  Replace hardcoded AWS account IDs, subnet IDs, and other
  environment-specific values with file.read("env/...") pattern.
  CI writes env files from GitHub repo variables (${{ vars.* }}).
  Workflow versions updated to v2.19.1 + feat/kcl-env-files.

  Implements [[tasks/e2e-env-vars-via-files]]

  * chore: use e2e workflow v2.19.1 (released)

  Update e2e workflow ref from feat/kcl-env-files to v2.19.1.

  * chore: add write-env-files: true for explicit env file opt-in

  * chore: update workflows-crossplane to v2.20.0 (write-env-files support)

* chore(makefile): add generate-configuration target (by @patrickleet)

  Wires hops validate generate-configuration as a prerequisite of
  validate:all / validate / validate:% so configuration.yaml is
  regenerated from upbound.yaml before each validation run.

  Implements [[tasks/update-xrd-makefiles-generate-config]]

* feat: support immutable GitHub OIDC subjects (#13) (by @patrickleet)

  * fix: support immutable GitHub OIDC subjects

  * fix: trust legacy and immutable OIDC subjects


See full diff: [v0.5.0...v0.6.0](https://github.com/hops-ops/aws-actions-connector/compare/v0.5.0...v0.6.0)
