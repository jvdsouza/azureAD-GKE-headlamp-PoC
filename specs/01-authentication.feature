Feature: Azure AD authentication via Backstage
  Scenario: Successful login through Backstage
    Given Backstage is configured with Azure AD as OIDC provider
    When user "alice@contoso.com" authenticates via Backstage
    Then Backstage must obtain a valid OIDC token from Azure AD
    And Headlamp must receive a signed identity from Backstage
    And no Azure AD access token should be stored in Headlamp
