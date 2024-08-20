import workflow_mgt_service.config;

public final UserServiceClient 'client = check initializeClient();

isolated function initializeClient() returns UserServiceClient|error {
    return new (config:appServiceUrl, {
        timeout: 1000
    });
}
