import workflow_mgt_service.config;
import workflow_mgt_service.util;
import ballerina/http;

//util:BadRequest|util:InternalServerError|util:Forbidden

listener http:Listener httpListener = new (config:servicePort, config = {
    requestLimits: {
        maxUriLength: 4096,
        maxHeaderSize: 64000, // inceased header size to support JWT tokens
        maxEntityBodySize: -1
    }
});

util:InternalServerError internalError = {body: {'error: "Not implemented", details: "This feature is not implemented yet."}};

service http:Service /workflow\-mgt/v1 on httpListener {

    # Get all the workflow definitions defined in Choreo.
    #
    # + ctx - request context
    # + return - list of workflow definitions
    resource function get definitions(http:RequestContext ctx) returns WorkflowDefinition[]|
    util:InternalServerError|util:Forbidden {
        return [];
    }

    # Configure a workflow for the organization.
    #
    # + workflow\-definition\-id - identifier of the workflow definition to configure
    # + ctx - request context
    # + workflowConfig - parameter description
    # + return - configured workflow
    resource function post definitions/[string workflow\-definition\-id]/config(http:RequestContext ctx,
            WorkflowConfig workflowConfig) returns WorkflowConfig
            |util:BadRequest|util:InternalServerError|util:Forbidden {
        //validate orgId from the context
        return internalError;
    }

    # Get all the workflow configurations defined in the organization.
    #
    # + ctx - Request context
    # + return - List of workflow configurations
    resource function get definitions/configs(http:RequestContext ctx) returns WorkflowConfig[]
        |util:InternalServerError|util:Forbidden {
        //validate orgId from the context
        return [];
    }

    # Get filtered workflows active in the organization.
    #
    # + ctx - Request context
    # + 'limit - Maximum number of workflows to return
    # + offset - Offset to start returning workflows
    # + action - Action to filter the workflows
    # + status - Status to filter the workflows
    # + 'resource - Resource to filter the workflows
    # + requested\-by - Requested user to filter the workflows
    # + return - List of workflows
    resource function get workflows(
            http:RequestContext ctx,
            int 'limit = 20,
            int offset = 0,
            string? action = (),
            string? status = (),
            string? 'resource = (),
            string? requested\-by = ()
    ) returns Workflow[]|util:InternalServerError|util:Forbidden|util:BadRequest {

        //default sorting is by requested time
        //Get orgId from the context

        //if viewed by a manager, show workflows assigned to the manager
        //if viewed by a user, show workflows requested by the user
        //if viewed by an admin, show all workflows

        return [];
    }

    # Get a specific workflow instance.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + return - Workflow instance
    resource function get workflows/[string workflow\-id](http:RequestContext ctx) returns Workflow
            |util:InternalServerError|util:Forbidden|util:BadRequest|util:ResourceNotFound {
        return internalError;
    }

    # Creates a new workflow request.
    #
    # + ctx - Request context
    # + request - Workflow request
    # + return - Created workflow instance
    resource function post workflows(http:RequestContext ctx, WorkflowRequest request) returns Workflow
            |util:BadRequest|util:InternalServerError|util:Forbidden {
        return internalError;
    }

    # Cancel a workflow request.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + return - Cancelled workflow instance
    resource function delete workflows/[string workflow\-id](http:RequestContext ctx) returns Workflow
            |util:InternalServerError|util:Forbidden|util:ResourceNotFound {
        //remove from workflow DB
        return internalError;
    }

    # Review a workflow request.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + review - Payload with review details
    # + return - Updated workflow instance
    resource function post workflows/[string workflow\-id]/review(http:RequestContext ctx, Review review) returns Workflow
            |util:BadRequest|util:InternalServerError|util:Forbidden|util:ResourceNotFound {
        //check approver is not the same as the requestedBy
        //update status
        //notify or execute the action (should by async? what if errored out? ressiency?)
        return internalError;
    }

    # Assign a new reviewer to a specific workflow request.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + reviewer - User ID of the reviewer
    # + return - Updated workflow instance
    resource function post workflows/[string workflow\-id]/reviewers(http:RequestContext ctx, string reviewer) returns Workflow
            |util:InternalServerError|util:Forbidden|util:ResourceNotFound {
        //check approver is not the same as the requestedBy
        return internalError;
    }

    # Get the status of workflows related to a action and a resource.
    # This is used to check if a request is in progress for a conflicting action.
    #
    # + ctx - Request context
    # + action - Action performed by the workflow
    # + 'resource - Resource on which the action is performed
    # + return - Status of the workflows
    resource function get workflows/status(http:RequestContext ctx, string action, string 'resource) returns WorkflowStatus
            |util:InternalServerError|util:Forbidden|util:ResourceNotFound {
        //if parallel requests are not allowed, check if there is a request in progress and get the status
        //if not no need to check the status
        //used by UI for button text rendering
        return DISABLED;
    }

    # Get the formatted review data captured at the workflow request.
    # This is used to display the captured data in UI/email/notifications.
    # The format is performed based on the workflow definition.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + return - Formatted review data
    resource function get workflows/[string workflow\-id]/review\-data(http:RequestContext ctx) returns json
            |util:InternalServerError|util:Forbidden|util:ResourceNotFound {
        //component BE needs this
        //format the captured data from the workflow request for
        //the UI/notifications looking at workflow definition and return
        return {};
    }

    # Get all the audits of the workflows in the organization based on the filters.
    #
    # + ctx - Request context
    # + orgId - Organization ID
    # + 'limit - Maximum number of audits to return
    # + offset - Offset to start returning audits
    # + action - Action to filter the audits
    # + status - Status to filter the audits
    # + 'resource - Resource to filter the audits
    # + requested\-by - Requested user to filter the audits
    # + reviwed\-by - Reviewer to filter the audits
    # + executed\-by - Executor of the action after approval to filter the audits
    # + return - List of audit records
    resource function get workflows/audits(
            http:RequestContext ctx,
            string orgId,
            int 'limit = 20,
            int offset = 0,
            string? action = (),
            string? status = (),
            string? 'resource = (),
            string? requested\-by = (),
            string? reviwed\-by = (),
            string? executed\-by = ()
    ) returns WorkflowAudit[]|util:InternalServerError|util:Forbidden|util:BadRequest {
        //default sorting is by requested time
        return [];
    }

    # Get all the audits of a specific workflow run.
    #
    # + workflow\-id - Identifier of the workflow instance
    # + ctx - Request context
    # + return - List of audits related to the workflow run
    resource function get workflows/[string workflow\-id]/audits(http:RequestContext ctx) returns WorkflowAudit[]
            |util:InternalServerError|util:Forbidden|util:BadRequest {
        return [];
    }

}
