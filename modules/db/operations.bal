// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import workflow_mgt_service.types;
import workflow_mgt_service.'error;
import workflow_mgt_service.config;
import workflow_mgt_service.util;

import ballerina/io;
import ballerina/persist;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;
import ballerina/sql;


Client dbClient = check new ();

//get all workflow definitions
public isolated function getWorkflowDefinitions(util:Context context) returns types:WorkflowDefinition[]| error {
    do {
        stream<WorkflowDefinition, persist:Error?> streamResult = dbClient->/workflowdefinitions();
        types:WorkflowDefinition[] dbWkfDefinitions = [];
        check from WorkflowDefinition defFromDb in streamResult
        do {
            string[] stringApproverTypes = stringToStringArray(defFromDb.approverTypes);
            types:ApproverType[] approverTypes = [];
            foreach string stringApproverType in stringApproverTypes{
                approverTypes.push(<types:ApproverType>stringApproverType);
            }
            types:WorkflowDefinition wkfDefinition = {
                id: defFromDb.id,
                name: defFromDb.name,
                description: defFromDb.description ?: "",
                approverTypes: approverTypes,
                executeUponApproval: defFromDb.executeUponApproval,
                allowParallelRequests: defFromDb.allowParallelRequests,
                requestFormatSchema: deserialiseSchema(defFromDb.requestFormatSchema)
            };
            dbWkfDefinitions.push(wkfDefinition);
        };
        return dbWkfDefinitions;
    } on fail error e {
        string message = "Error while retrieving workflow definitions from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}

//get single workflow definition
public isolated function getWorkflowDefinition(string workflowDefinitionId) returns types:WorkflowDefinition| error {
    do {
        WorkflowDefinition dbWkfDefinition = check dbClient->/workflowdefinitions/[workflowDefinitionId].get();
        string[] stringApproverTypes = stringToStringArray(dbWkfDefinition.approverTypes);
        types:ApproverType[] approverTypes = [];
        foreach string stringApproverType in stringApproverTypes{
            approverTypes.push(<types:ApproverType>stringApproverType);
        }
        types:WorkflowDefinition wkfDefinition = {
            id: dbWkfDefinition.id,
            name: dbWkfDefinition.name,
            description: dbWkfDefinition.description ?: "",
            approverTypes: approverTypes,
            executeUponApproval: dbWkfDefinition.executeUponApproval,
            allowParallelRequests: dbWkfDefinition.allowParallelRequests,
            requestFormatSchema: deserialiseSchema(dbWkfDefinition.requestFormatSchema)
        };
        return wkfDefinition;
    } on fail error e {
        string message = "Error while retrieving workflow definition from the database";
        log:printError(message, 'error = e);
        return error error:DatabaseError(message, e, wkfDefinitionId = workflowDefinitionId);
    }
}
public isolated function persistWorkflowConfig(util:Context context, types:OrgWorkflowConfigRequest wkfConfigReq) returns types:OrgWorkflowConfig| error {
    do {
        string workflowConfigUuid = uuid:createType1AsString();
        string assigneeRoles = stringArrayToString(wkfConfigReq.assigneeRoles);
        string assignees = stringArrayToString(wkfConfigReq.assignees);
        OrgWorkflowConfigInsert insertData = {
            id: workflowConfigUuid,
            orgId: context.orgId,
            workflowDefinitionId: wkfConfigReq.workflowDefinitionId,
            assigneeRoles: assigneeRoles,
            assignees: assignees,
            formatRequestData: wkfConfigReq.formatRequestData,
            externalWorkflowEngineEndpoint: wkfConfigReq.externalWorkflowEngineEndpoint
        };
        string[] dbResult = check dbClient->/orgworkflowconfigs.post([insertData]);
        if dbResult.length() == 1 {
            types:OrgWorkflowConfig insertedWkfConfig = {
                id: dbResult[0],
                orgId: context.orgId,
                workflowDefinitionId: wkfConfigReq.workflowDefinitionId,
                assigneeRoles: wkfConfigReq.assigneeRoles,
                assignees: wkfConfigReq.assignees,
                formatRequestData: wkfConfigReq.formatRequestData,
                externalWorkflowEngineEndpoint: wkfConfigReq.externalWorkflowEngineEndpoint
            };
            return insertedWkfConfig;
        } else {
            string message = "Error while inserting workflow configuration to the database";
            return error error:DatabaseError(message, wkfDefinitionId = wkfConfigReq.workflowDefinitionId);
        }
    } on fail error e {
        string message = "Error while inserting workflow configuration to the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, wkfDefinitionId = wkfConfigReq.workflowDefinitionId);
    }
}

public isolated function getWorkflowConfigById(util:Context context, string workflowConfigId) returns types:OrgWorkflowConfig| error {
    do {
        OrgWorkflowConfig dbWkfConfig = check dbClient->/orgworkflowconfigs/[workflowConfigId].get();
        types:OrgWorkflowConfig wkfConfig = {
            id: dbWkfConfig.id,
            orgId: dbWkfConfig.orgId,
            workflowDefinitionId: dbWkfConfig.workflowDefinitionId,
            assigneeRoles: stringToStringArray(dbWkfConfig.assigneeRoles),
            assignees: stringToStringArray(dbWkfConfig.assignees),
            formatRequestData: dbWkfConfig.formatRequestData,
            externalWorkflowEngineEndpoint: dbWkfConfig.externalWorkflowEngineEndpoint
        };
        return wkfConfig;
    } on fail error e {
        string message = "Error while retrieving workflow configuration from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowConfigId = workflowConfigId);
    }
}

//get workflow config by org id and workflow definition id
public isolated function getWorkflowConfigByOrgAndDefinition(util:Context context, string orgId, string workflowDefinitionId) returns types:OrgWorkflowConfig| error {
    do {

        WorkflowInstance[] instances = check from WorkflowInstance instance in dbClient->/workflowinstances(WorkflowInstance)
                            where instance.'resource == 'resource &&
                            instance.workflowDefinitionId == workflowDefinition
                            select instance;
                            
        stream<OrgWorkflowConfig, persist:Error?> streamResult = dbClient->/orgworkflowconfigs.get([orgId, workflowDefinitionId]);
        OrgWorkflowConfig dbWkfConfig = check streamResult.next();
        types:OrgWorkflowConfig wkfConfig = {
            id: dbWkfConfig.id,
            orgId: dbWkfConfig.orgId,
            workflowDefinitionId: dbWkfConfig.workflowDefinitionId,
            assigneeRoles: stringToStringArray(dbWkfConfig.assigneeRoles),
            assignees: stringToStringArray(dbWkfConfig.assignees),
            formatRequestData: dbWkfConfig.formatRequestData,
            externalWorkflowEngineEndpoint: dbWkfConfig.externalWorkflowEngineEndpoint
        };
        return wkfConfig;
    } on fail error e {
        string message = "Error while retrieving workflow configuration from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, orgId = orgId, workflowDefinitionId = workflowDefinitionId);
    }
}

public isolated function updateWorkflowConfigById(util:Context context, string workflowConfigId, types:OrgWorkflowConfigRequest wkfConfigReq) returns types:OrgWorkflowConfig| error {
    do {
        string assigneeRoles = stringArrayToString(wkfConfigReq.assigneeRoles);
        string assignees = stringArrayToString(wkfConfigReq.assignees);
        OrgWorkflowConfigUpdate updateData = {
            orgId: context.orgId,
            workflowDefinitionId: wkfConfigReq.workflowDefinitionId,
            assigneeRoles: assigneeRoles,
            assignees: assignees,
            formatRequestData: wkfConfigReq.formatRequestData,
            externalWorkflowEngineEndpoint: wkfConfigReq.externalWorkflowEngineEndpoint
        };
        OrgWorkflowConfig dbWkfConfig = check dbClient->/orgworkflowconfigs/[workflowConfigId].put(updateData);
        types:OrgWorkflowConfig wkfConfig = {
            id: dbWkfConfig.id,
            orgId: dbWkfConfig.orgId,
            workflowDefinitionId: dbWkfConfig.workflowDefinitionId,
            assigneeRoles: stringToStringArray(dbWkfConfig.assigneeRoles),
            assignees: stringToStringArray(dbWkfConfig.assignees),
            formatRequestData: dbWkfConfig.formatRequestData,
            externalWorkflowEngineEndpoint: dbWkfConfig.externalWorkflowEngineEndpoint
        };
        return wkfConfig;
    } on fail error e {
        string message = "Error while updating workflow configuration in the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, wkfConfigId = workflowConfigId);
    }
}

public isolated function deleteWorkflowConfigById(util:Context context, string workflowConfigId) returns types:OrgWorkflowConfig|error {
    do {
        OrgWorkflowConfig deletedDbWkfConfig = check dbClient->/orgworkflowconfigs/[workflowConfigId].delete();
        types:OrgWorkflowConfig deletedWkfConfig = {
            id: deletedDbWkfConfig.id,
            orgId: deletedDbWkfConfig.orgId,
            workflowDefinitionId: deletedDbWkfConfig.workflowDefinitionId,
            assigneeRoles: stringToStringArray(deletedDbWkfConfig.assigneeRoles),
            assignees: stringToStringArray(deletedDbWkfConfig.assignees),
            formatRequestData: deletedDbWkfConfig.formatRequestData,
            externalWorkflowEngineEndpoint: deletedDbWkfConfig.externalWorkflowEngineEndpoint
        };
        return deletedWkfConfig;
    } on fail error e {
        string message = "Error while deleting workflow configuration from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowConfigId = workflowConfigId);
    }
}

//For UI

public isolated function getWorkflowInstances(util:Context context, int 'limit,
        int offset, string wkfDefinition, string status,
        string 'resource, string createdBy) returns types:WorkflowInstanceResponse[]|error {
    do {
            //filter by orgId and user also
            //with pagination
            //Filter by org
            //Sort by created time
            //Join with workflow definition
            sql:ParameterizedQuery selectQuery = `Select status, data from workflowinstances where orgId = ${context.orgId} and createdBy = ${createdBy}`;
            stream<WorkflowInstance, persist:Error?> queryNativeSQL = dbClient->queryNativeSQL(selectQuery);

    } on fail error e {
        string message = "Error while retrieving workflow instances from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}



public isolated function getWorkflowInstanceById(util:Context context, string workflowInstanceId) returns types:WorkflowInstance|error {
    do {
        WorkflowInstance dbWkfInstance = check dbClient->/workflowinstances/[workflowInstanceId].get();
        types:WorkflowInstance wkfInstance = {
            id: dbWkfInstance.id,
            orgId: dbWkfInstance.orgId,
            createdTime: dbWkfInstance.createdTime,
            createdBy: dbWkfInstance.createdBy,
            context: {
                workflowDefinitionIdentifier: dbWkfInstance.workflowDefinitionId,
                'resource: dbWkfInstance.'resource
            },
            requestComment: dbWkfInstance.requestComment,
            orgWorkflowConfigId: dbWkfInstance.orgWorkflowConfigId,
            reviewerDecision: {
                reviewedBy: dbWkfInstance.reviewedBy,
                decision: check dbWkfInstance.reviewerDecision.cloneWithType(),
                reviewComment: dbWkfInstance.reviewComment
            },
            status: check dbWkfInstance.status.cloneWithType()
        };
        return wkfInstance;

    } on fail error e {
        string message = "Error while retrieving workflow instance from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowInstanceId = workflowInstanceId);
    }
}

public isolated function getWorkflowInstanceResponseById(util:Context context, string workflowInstanceId) returns types:WorkflowInstanceResponse|error {
    do {
        WorkflorInstanceWithDefinitionDetails dbWkfInstance = check dbClient->/workflowinstances/[workflowInstanceId].get();
        types:WorkflowInstanceResponse wkfInstance = {
            wkfId: dbWkfInstance.id,
            orgId: dbWkfInstance.orgId,
            createdTime: dbWkfInstance.createdTime,
            createdBy: dbWkfInstance.createdBy,
            context: {
                workflowDefinitionIdentifier: dbWkfInstance.workflowDefinitionId,
                'resource: dbWkfInstance.'resource
            },
            workflowDefinitionIdentifier: {
                id: dbWkfInstance.workflowDefinition.id,
                name: dbWkfInstance.workflowDefinition.name,
                description: dbWkfInstance.workflowDefinition.description
            },
            requestComment: dbWkfInstance.requestComment,
            reviewerDecision: {
                reviewedBy: dbWkfInstance.reviewedBy,
                decision: check dbWkfInstance.reviewerDecision.cloneWithType(),
                reviewComment: dbWkfInstance.reviewComment
            },
            status: check dbWkfInstance.status.cloneWithType()
        };
        return wkfInstance;

    } on fail error e {
        string message = "Error while retrieving workflow instance from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowInstanceId = workflowInstanceId);
    }
}


public isolated function persistWorkflowInstance(util:Context context, types:WorkflowInstanceCreateRequest wkfInstanceReq) returns string|error {
    do {
        string workflowInstanceUuid = uuid:createType1AsString();
        time:Utc createdTime = time:utcNow();
        WorkflowInstanceInsert insertData = {
            id: workflowInstanceUuid,
            orgId: context.orgId,
            createdBy: context.userId,
            createdTime: createdTime,
            requestComment: wkfInstanceReq.requestComment?: "",
            data: wkfInstanceReq.data.toJsonString(),
            status: types:PENDING,
            reviewedBy: (),
            reviewerDecision: (),
            reviewComment: (),
            reviewTime: (),
            orgWorkflowConfigId: ,
            workflowDefinitionId: wkfInstanceReq.context.workflowDefinitionIdentifier,
            'resource: wkfInstanceReq.context.'resource
        };
        string[] dbResult = check dbClient->/workflowinstances.post([insertData]);
        if dbResult.length() == 1 {
            return dbResult[0];
        } else {
            string message = "Error while inserting workflow instance to the database";
            return error error:DatabaseError(message, wkfInstanceId = workflowInstanceUuid);
        }
    } on fail error e {
        string message = "Error while inserting workflow instance to the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}

//delete workflow instance
public isolated function deleteWorkflowInstance(util:Context context, string workflowInstanceId) returns string|error {
    do {
        WorkflowInstance dbWkfInstance = check dbClient->/workflowinstances/[workflowInstanceId].delete();
        return dbWkfInstance.id;
    } on fail error e {
        string message = "Error while deleting workflow instance from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowInstanceId = workflowInstanceId);
    }
}

public isolated function getWorkflowInstanceData(util:Context context, string workflowInstanceId) returns json|error {   //TODO: can we only get data?
    do {
        WorkflowInstance dbWkfInstance = check dbClient->/workflowinstances/[workflowInstanceId].get();
        return dbWkfInstance.data;
    } on fail error e {
        string message = "Error while retrieving workflow instance data from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowInstanceId = workflowInstanceId);
    }
}

public isolated function getWorkflowInstance(util:Context context, string workflowDefinition, string 'resource) returns types:WorkflowInstance|error {
    do {
        WorkflowInstance[] instances = check from WorkflowInstance instance in dbClient->/workflowinstances(WorkflowInstance)
                            where instance.'resource == 'resource &&
                            instance.workflowDefinitionId == workflowDefinition
                            select instance;
        return dbWkfInstanceStatus;
    } on fail error e {
        string message = "Error while retrieving workflow instance status from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, action = action, 'resource = 'resource);
    }
}

//persist audit event
public isolated function persistAuditEvent(util:Context context, types:AuditEvent auditEvent) returns string|error {
    do {
        string auditEventUuid = uuid:createType1AsString();
        AuditEventInsert insertData = {
            id: auditEventUuid,
            orgId: context.orgId,
            eventType: auditEvent.eventType,
            timestamp: auditEvent.time,
            userId: context.userId,
            action: auditEvent.context.workflowDefinitionIdentifier,
            'resource: auditEvent.context.'resource,
            workflowInstanceId: auditEvent.wkfId,
            comment: auditEvent.requestComment
        };
        string[] dbResult = check dbClient->/auditevents.post([insertData]);
        if dbResult.length() == 1 {
            return dbResult[0];
        } else {
            string message = "Error while inserting audit event to the database";
            return error error:DatabaseError(message, auditEventId = auditEventUuid);
        }
    } on fail error e {
        string message = "Error while inserting audit event to the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}

//search audit events
public isolated function searchAuditEvents(util:Context context, int 'limit, int offset, string wkfDefinitionId, string status, string 'resource, string requestedBy, string reviewedBy, string executedBy) returns types:AuditEvent[]|error {
    do {
        AuditEventSearch searchParams = {
            orgId: context.orgId,
            userId: userId,
            action: action,
            'resource: 'resource,
            workflowInstanceId: workflowInstanceId,
            comment: comment,
            from: from,
            to: to
        };
        stream<AuditEvent, persist:Error?> streamResult = dbClient->/auditevents.get([searchParams]);
        types:AuditEvent[] dbAuditEvents = [];
        check from AuditEvent dbAuditEvent in streamResult
        do {
            types:AuditEvent auditEvent = {
                eventType: dbAuditEvent.eventType,
                time: dbAuditEvent.timestamp,
                user: dbAuditEvent.userId,
                wkfId: dbAuditEvent.workflowInstanceId,
                requestComment: dbAuditEvent.comment,
                context: {
                    workflowDefinitionIdentifier: dbAuditEvent.action,
                    'resource: dbAuditEvent.'resource
                }
            };
            dbAuditEvents.push(auditEvent);
        };
        return dbAuditEvents;
    } on fail error e {
        string message = "Error while searching audit events from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}
