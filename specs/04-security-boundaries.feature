Feature: Security boundaries between Backstage, Headlamp, and GKE
  Scenario: Separation of authentication and authorization
    Given Backstage handles OIDC login
    And Headlamp never stores Azure AD tokens long-term
    And GKE authorizes requests using Azure AD claims
    Then no component contains hard-coded secrets
    And audit logs must record the Azure AD username directly