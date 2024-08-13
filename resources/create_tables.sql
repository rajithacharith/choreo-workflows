-- Create WorkflowDefinition table
CREATE TABLE WorkflowDefinition (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    approverTypes VARCHAR(255) NOT NULL,
    executeUponApproval BOOLEAN NOT NULL,
    allowParallelRequests BOOLEAN NOT NULL,
    requestFormatSchema JSONB NOT NULL
);

-- Create OrgWorkflowConfig table
CREATE TABLE OrgWorkflowConfig (
    id VARCHAR(255) PRIMARY KEY,
    orgId VARCHAR(255) NOT NULL,
    workflowDefinitionId VARCHAR(255) NOT NULL REFERENCES WorkflowDefinition(id),
    assigneeRoles VARCHAR(255) NOT NULL,
    assignees VARCHAR(255) NOT NULL,
    formatRequestData BOOLEAN NOT NULL,
    externalWorkflowEngineEndpoint VARCHAR(255)
);

-- Create WorkflowInstance table
CREATE TABLE WorkflowInstance (
    id VARCHAR(255) PRIMARY KEY,
    orgWorkflowConfigId VARCHAR(255) NOT NULL REFERENCES OrgWorkflowConfig(id),
    orgId VARCHAR(255) NOT NULL,
    resource VARCHAR(255) NOT NULL,
    action VARCHAR(255) NOT NULL,
    createdBy VARCHAR(255) NOT NULL,
    createdTime TIMESTAMP NOT NULL,
    requestComment TEXT,
    data JSONB NOT NULL,
    status VARCHAR(50) NOT NULL,
    reviewedBy VARCHAR(255),
    reviewerDecision VARCHAR(50),
    reviewComment TEXT,
    reviewTime TIMESTAMP
);

-- Create AuditEvent table
CREATE TABLE AuditEvent (
    id VARCHAR(255) PRIMARY KEY,
    orgId VARCHAR(255) NOT NULL,
    eventType VARCHAR(50) NOT NULL, -- e.g., request, review, approve, reject, cancel, execute
    timestamp TIMESTAMP NOT NULL,
    username VARCHAR(255) NOT NULL,
    action VARCHAR(255) NOT NULL,
    resource VARCHAR(255) NOT NULL,
    workflowInstanceId VARCHAR(255),
    comment TEXT
);

-- Indexes for better performance on JSONB fields (optional but recommended)
CREATE INDEX idx_workflowdefinition_requestformatschema ON WorkflowDefinition USING GIN (requestFormatSchema);
CREATE index idx_workflowInstance_data on WorkflowInstance using GIN (data);
