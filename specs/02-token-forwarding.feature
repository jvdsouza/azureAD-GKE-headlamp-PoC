Feature: Token forwarding from Headlamp to GKE
  Scenario: Headlamp forwards Azure AD OIDC token directly
    Given Headlamp is embedded within Backstage
    And the user is already authenticated with Azure AD
    When Headlamp makes API requests to the GKE API server
    Then Headlamp must forward the Azure AD access token in the Authorization header
    And the GKE API server must authenticate the token directly
