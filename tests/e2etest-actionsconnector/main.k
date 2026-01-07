# e2etest-actionsconnector - AWS Actions Connector E2E Test
# =========================================================
# Tests GitHub Actions OIDC connector creation with optional import cycle.
#
# Import Cycle Testing:
# 1. First run: Create connector with empty imports (creates new resources)
# 2. Get resource IDs after creation (see commands below)
# 3. Update imports + set managementPolicies to orphan (remove Delete)
# 4. Run again to verify import works
# 5. Delete claim - resources are orphaned in AWS
#
# Get resource external names after first run:
#   kubectl get openidconnectprovider -l crossplane.io/composite=e2e-gha-actionsconnector \
#     -o jsonpath='{.items[0].metadata.annotations.crossplane\.io/external-name}'
#   kubectl get role -l crossplane.io/composite=e2e-gha-actionsconnector \
#     -o jsonpath='{.items[0].metadata.annotations.crossplane\.io/external-name}'
#   kubectl get rolepolicyattachment -l crossplane.io/composite=e2e-gha-actionsconnector \
#     -o jsonpath='{.items[0].metadata.annotations.crossplane\.io/external-name}'

import models.ai.com.ops.hops.aws.v1alpha1 as hops
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

import file
import base64

# Read AWS credentials from local file (must be created manually, gitignored)
_awsCredsRaw = file.read("secrets/aws-creds")
_awsCreds = base64.encode(_awsCredsRaw)

# AWS account ID for testing - update this to your test account
_testAccountId = "034489662075"

# Orphan policy - no Delete means resources persist in AWS after claim deletion
_orphan = ["Create", "Observe", "Update", "LateInitialize"]

# =============================================================================
# Imports for existing resources (leave empty for create, populate for import)
# =============================================================================
# OIDC Provider ARN: arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
_import_oidc_provider = "arn:aws:iam::" + _testAccountId + ":oidc-provider/token.actions.githubusercontent.com"

# Role name: hops-github-actions
# _import_role = "hops-github-actions"
_import_role = ""

# Policy Attachment: hops-github-actions/arn:aws:iam::aws:policy/AdministratorAccess
_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
_import_policy_attachment = _import_role + "/" + _policy_arn if _import_role else ""

# =============================================================================
# Test ActionsConnector
# =============================================================================
_test_name = "e2e-gha-actionsconnector"


_items = [
    metav1alpha1.E2ETest {
        metadata.name = "actionsconnector-e2e"
        spec = {
            crossplane = {
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions = ["Ready"]
            skipDelete = False
            timeoutSeconds = 4500

            # Extra resources: AWS credentials secret and ProviderConfig
            extraResources = [
                # AWS credentials secret
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = "default"
                    }
                    type = "Opaque"
                    data.creds = _awsCreds
                }
                # ProviderConfig for AWS
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                name = "aws-creds"
                                namespace = "default"
                                key = "creds"
                            }
                        }
                    }
                }
            ]

            # The ActionsConnector claims to test
            manifests = [
                # Persistent test - uses orphan policy and external names for import
                hops.ActionsConnector {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        accountId = _testAccountId
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        # Prevent deletion of resources after E2E test
                        managementPolicies = _orphan
                        github = {
                            owner = "hops-ops"
                            repository = "*"
                            refPattern = "*"
                        }
                        # Flat imports object for existing resources
                        if _import_oidc_provider or _import_role or _import_policy_attachment:
                            imports = {
                                if _import_oidc_provider:
                                    oidcProvider = _import_oidc_provider
                                if _import_role:
                                    role = _import_role
                                if _import_policy_attachment:
                                    policyAttachment = _import_policy_attachment
                            }
                        policy = {
                            arn = _policy_arn
                        }
                        tags = {
                            "test" = "true"
                            "e2e" = "actionsconnector"
                            "hops.ops.com.ai/managed" = "true"
                        }
                    }
                }
            ]
        }
    }
]
items = _items
