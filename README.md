# aws-actions-connector

Sets up GitHub Actions OIDC federation with AWS for secure CI/CD access without long-lived credentials.

## What It Creates

- **OIDC Provider** - Registers `token.actions.githubusercontent.com` as an identity provider in AWS
- **IAM Role** - Creates a role with a trust policy scoped to your GitHub org/repo/ref
- **Policy Attachment** - Attaches your chosen IAM policy to the role

## Quick Start

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ActionsConnector
metadata:
  name: my-org-gha
  namespace: default
spec:
  accountId: "123456789012"
  github:
    orgOrUser: my-org
```

This creates an OIDC provider and role (`hops-github-actions`) that any repo in `my-org` can assume, with `AdministratorAccess` policy attached.

## Configuration

### Required Fields

| Field | Description |
|-------|-------------|
| `spec.accountId` | AWS Account ID |
| `spec.github.orgOrUser` | GitHub organization or username |

### Optional Fields

| Field | Default | Description |
|-------|---------|-------------|
| `spec.github.repository` | `"*"` | Repository name or `"*"` for all repos |
| `spec.github.refPattern` | `"*"` | Git ref pattern: `"*"`, `"ref:refs/heads/main"`, `"environment:production"` |
| `spec.role.name` | `"hops-github-actions"` | IAM role name |
| `spec.role.permissionsBoundary` | - | ARN of permissions boundary to attach |
| `spec.policy.arn` | `AdministratorAccess` | IAM policy ARN to attach |
| `spec.providerConfigRef.name` | `"default"` | AWS ProviderConfig name |
| `spec.tags` | `{"hops": "true"}` | Additional AWS resource tags |

## Common Use Cases

### Organization-Wide Access

Allow any repo in your org to assume the role:

```yaml
spec:
  accountId: "123456789012"
  github:
    orgOrUser: my-org
    repository: "*"
    refPattern: "*"
```

### Single Repository

Restrict to a specific repo and branch:

```yaml
spec:
  accountId: "123456789012"
  github:
    orgOrUser: my-org
    repository: my-app
    refPattern: "ref:refs/heads/main"
  role:
    name: my-app-deploy
  policy:
    arn: arn:aws:iam::123456789012:policy/my-app-deploy-policy
```

### Environment-Based Deployment

Use GitHub Environments for approval workflows:

```yaml
spec:
  accountId: "123456789012"
  github:
    orgOrUser: my-org
    repository: infrastructure
    refPattern: "environment:production"
  role:
    name: github-actions-prod-deploy
  policy:
    arn: arn:aws:iam::aws:policy/PowerUserAccess
```

## Using in GitHub Actions

Once deployed, configure your workflow to assume the role:

```yaml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/hops-github-actions
          aws-region: us-east-1

      - name: Deploy
        run: |
          aws sts get-caller-identity
          # Your deployment commands here
```

## Importing Existing Resources

If you already have an OIDC provider and role, import them:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ActionsConnector
metadata:
  name: imported-gha
spec:
  accountId: "123456789012"
  # Exclude Delete to prevent accidental deletion
  managementPolicies: [Create, Update, Observe, LateInitialize]
  github:
    orgOrUser: my-org
  oidcProvider:
    externalName: arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
  role:
    name: existing-gha-role
    externalName: existing-gha-role
  policy:
    arn: arn:aws:iam::aws:policy/AdministratorAccess
  policyAttachment:
    externalName: existing-gha-role/arn:aws:iam::aws:policy/AdministratorAccess
```

## Status

Once deployed, the status shows the created resources:

```yaml
status:
  ready: true
  oidcProvider:
    arn: arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
    url: https://token.actions.githubusercontent.com
  role:
    arn: arn:aws:iam::123456789012:role/hops-github-actions
    name: hops-github-actions
  trustPolicy:
    subject: "repo:my-org/*:*"
```

## Security Considerations

- **Scope access tightly** - Use specific repos and ref patterns rather than wildcards when possible
- **Use permissions boundaries** - Apply `spec.role.permissionsBoundary` to limit maximum permissions
- **Prefer least privilege** - Attach a custom policy with only required permissions instead of `AdministratorAccess`
- **Use GitHub Environments** - For production deployments, use `environment:production` pattern with required reviewers
