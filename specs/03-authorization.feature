Feature: RBAC enforcement for Azure AD users in Headlamp

  Scenario: Read-only access reflected in the Headlamp UI
    Given "alice@contoso.com" is an Azure AD user with a ClusterRoleBinding to "view"
    When she logs into Backstage and opens the Headlamp plugin
    Then she can see namespaces, pods, deployments, and other workloads listed
    And she can open resource details and view YAML manifests
    But she does not see "Delete", "Edit", or "Create" action buttons in the Headlamp interface
    And if she attempts to perform a forbidden action via the UI, Headlamp displays a "Forbidden" or "Unauthorized" error

  Scenario: Privileged access reflected in the Headlamp UI
    Given "bob@contoso.com" is an Azure AD user with a ClusterRoleBinding to "admin"
    When he logs into Backstage and opens the Headlamp plugin
    Then he can list and view all workloads
    And he can create, edit, and delete resources within his allowed namespaces
    And Headlamp executes those actions successfully via the GKE API
