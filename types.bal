import ballerina/time;

# Workflow definition for an action. This defines the behavior of the workflow
#
# + id - identifier of the workflow
# + name - name of the workflow
# + description - description of the workflow
# + approverTypes - list of approver types supported by the workflow
# + executeUponApproval - flag to indicate whether the action should be executed upon approval
# + transitions - list of transitions. Key: transition from, Value: transition to
# + requestFormatSchema - schema to format the input data for the approval
public type WorkflowDefinition record {
    string id;
    string name;
    string description;
    ApproverType[] approverTypes;
    boolean executeUponApproval;
    map<string> transitions;
    map<formatSchemaEntry> requestFormatSchema;
};

# Workflow configuration for an action. This defines the configuration of the workflow.
# A workflow instance is created based on the configuration.
#
# + workflowDefinition - workflow definition
# + orgId - organization id
# + projectGroups - list of project groups to assign the action
# + assigneeRoles - list of roles to assign the action
# + assignees - list of users to assign the action (user ids)
public type WorkflowConfig record {
    WorkflowDefinition workflowDefinition;
    string orgId;
    string[] projectGroups;
    string[] assigneeRoles;
    string[] assignees;
};

public type Workflow record {
    string id;
    * WorkflowRequest;
    * Review;
    WorkflowConfig config;
    string[] additionalReviewers;  # reviewers who can review apart from approvers in the config
    string status;
};

public type WorkflowRequest record {
    string orgId;
    string 'resource;
    string action;
    string requestedBy;
    string requestComment?;
    string requestedTime;
    string data?;
};

public type Review record {
    string workflowId;
    string reviewedBy;
    ReviewDecision decision;
    string reviewComment?;
    time:Civil reviewTime;
};

public type WorkflowAudit record {
    * Workflow;
    never WorkflowConfig;
    string action;
    time:Civil executTime?;
    time:Civil cancelledTime?;
    string executedBy?;
    string cancelledBy?;
};

# Schema instruction on how to format input data field to form
# data for the workflow
#
# + displayName - display name of the field
# + dataType - data type of the field
# + extractfrom - json path to extract the field from the input data
public type formatSchemaEntry record {
    string displayName;
    string dataType;
    string extractfrom;
};

public type ReviewDecision APPROVED|REJECTED;

public enum WorkflowStatus {
    DISABLED,
    PENDING,
    APPROVED,
    REJECTED,
    NOT_FOUND,
    TIMEOUT,
    CANCELLED
};

public enum ApproverType {
    PROJECT_GROUP,
    ROLE,
    USER
};
