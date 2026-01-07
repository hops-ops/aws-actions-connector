import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    # Test 1: Default role name is hops-github-actions
    metav1alpha1.CompositionTest {
        metadata.name = "default-role-name"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "my-gha"
                spec = {
                    accountId = "123456789012"
                    github.orgOrUser = "my-org"
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "hops-github-actions"
                }
            ]
        }
    }

    # Test 2: Custom role name overrides default
    metav1alpha1.CompositionTest {
        metadata.name = "custom-role-name"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "my-gha"
                spec = {
                    accountId = "123456789012"
                    github.orgOrUser = "my-org"
                    role.name = "custom-role"
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "custom-role"
                }
            ]
        }
    }

    # Test 3: Trust policy subject pattern - org wildcard (verify via status)
    metav1alpha1.CompositionTest {
        metadata.name = "trust-policy-org-wildcard"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "org-wide"
                spec = {
                    accountId = "123456789012"
                    github = {
                        orgOrUser = "my-org"
                        repository = "*"
                        refPattern = "*"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "ActionsConnector"
                    metadata.name = "org-wide"
                    status.trustPolicy.subject = "repo:my-org/*:*"
                }
            ]
        }
    }

    # Test 4: Trust policy subject pattern - specific repo and branch
    metav1alpha1.CompositionTest {
        metadata.name = "trust-policy-specific-repo"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "prod-deploy"
                spec = {
                    accountId = "123456789012"
                    github = {
                        orgOrUser = "my-org"
                        repository = "infrastructure"
                        refPattern = "ref:refs/heads/main"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "ActionsConnector"
                    metadata.name = "prod-deploy"
                    status.trustPolicy.subject = "repo:my-org/infrastructure:ref:refs/heads/main"
                }
            ]
        }
    }

    # Test 5: Trust policy subject pattern - environment protection
    metav1alpha1.CompositionTest {
        metadata.name = "trust-policy-environment"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "env-deploy"
                spec = {
                    accountId = "123456789012"
                    github = {
                        orgOrUser = "my-org"
                        repository = "infrastructure"
                        refPattern = "environment:production"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "ActionsConnector"
                    metadata.name = "env-deploy"
                    status.trustPolicy.subject = "repo:my-org/infrastructure:environment:production"
                }
            ]
        }
    }

    # Test 6: Custom tags are merged with defaults
    metav1alpha1.CompositionTest {
        metadata.name = "custom-tags-merged"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "tagged"
                spec = {
                    accountId = "123456789012"
                    github.orgOrUser = "my-org"
                    role.name = "tagged-role"
                    tags = {
                        environment = "production"
                        team = "platform"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "tagged-role"
                    spec.forProvider.tags = {
                        hops = "true"
                        environment = "production"
                        team = "platform"
                    }
                }
            ]
        }
    }

    # Test 7: Permissions boundary is applied when specified
    metav1alpha1.CompositionTest {
        metadata.name = "permissions-boundary"
        spec = {
            compositionPath = "apis/actionsconnectors/composition.yaml"
            xrdPath = "apis/actionsconnectors/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.ActionsConnector {
                metadata.name = "bounded"
                spec = {
                    accountId = "123456789012"
                    github.orgOrUser = "my-org"
                    role = {
                        name = "bounded-role"
                        permissionsBoundary = "arn:aws:iam::123456789012:policy/boundary"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "bounded-role"
                    spec.forProvider.permissionsBoundary = "arn:aws:iam::123456789012:policy/boundary"
                }
            ]
        }
    }
]
items = _items
