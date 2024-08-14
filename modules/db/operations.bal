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
                requestFormatSchema: defFromDb.requestFormatSchema
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

public isolated function getWorkflowConfig(util:Context context, string workflowConfigId) returns types:OrgWorkflowConfig| error {
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

public isolated function updateWorkflowConfig(util:Context context, string workflowConfigId, types:OrgWorkflowConfigRequest wkfConfigReq) returns types:OrgWorkflowConfig| error {
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
        OrgWorkflowConfig dbWkfConfig = check dbClient->/orgworkflowconfigs/[workflowConfigId].put([updateData]);
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

public isolated function deleteWorkflowConfig(util:Context context, string workflowConfigId) returns types:OrgWorkflowConfig|error {
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

public isolated function getWorkflowInstances(util:Context context, string orgId) returns types:WorkflowInstance[]|error {
    do {

    } on fail error e {
        string message = "Error while retrieving workflow instances from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}


//get a particular workflow instance
public isolated function getWorkflowInstance(util:Context context, string workflowInstanceId) returns types:WorkflowInstance|error {
    do {
        WorkflowInstanceWithRelations dbWkfInstance = check dbClient->/workflowinstances/[workflowInstanceId].get();
        types:WorkflowInstance wkfInstance = {
            id: dbWkfInstance.id,
            orgId: dbWkfInstance.orgId,
            createdTime: dbWkfInstance.createdTime,
            createdBy: dbWkfInstance.createdBy,
            context: dbWkfInstance.context,
            requestedBy: dbWkfInstance.requestedBy,
            requestComment: dbWkfInstance.requestComment,
            config: {
                id: dbWkfInstance.orgworkflowconfig.id,
                workflowDefinitionId: dbWkfInstance.orgworkflowconfig.workflowDefinitionId,
                assigneeRoles: stringToStringArray(dbWkfInstance.orgworkflowconfig.assigneeRoles),
                assignees: stringToStringArray(dbWkfInstance.orgworkflowconfig.assignees),
                formatRequestData: dbWkfInstance.orgworkflowconfig.formatRequestData,
                externalWorkflowEngineEndpoint: dbWkfInstance.orgworkflowconfig.externalWorkflowEngineEndpoint
            },
            reviewerDecision: dbWkfInstance.reviewerDecision,
            status: dbWkfInstance.status
        };
        return wkfInstance;

    } on fail error e {
        string message = "Error while retrieving workflow instance from the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e, workflowInstanceId = workflowInstanceId);
    }
}

public isolated function persistWorkflowInstance(util:Context context, types:WorkflowInstanceCreateRequest wkfInstanceReq) returns types:WorkflowInstance|error {
    do {
        string workflowInstanceUuid = uuid:createType1AsString();
        time:Utc createdTime = time:utcNow();
        WorkflowInstanceInsert insertData = {
            orgId: context.orgId,
            action: wkfInstanceReq.context.action,
            createdBy: context.userId,
            createdTime: createdTime,
            requestComment: wkfInstanceReq.requestComment?: "",
            data: wkfInstanceReq.data.toJsonString(),
            status: types:PENDING,
            reviewedBy: (),
            reviewerDecision: (),
            reviewComment: (),
            reviewTime: (),
            orgWorkflowConfigId: "",   //TODO: need to find it by definitionID
            id: workflowInstanceUuid,
            'resource: wkfInstanceReq.context.'resource
        };
        string[] dbResult = check dbClient->/workflowinstances.post([insertData]);
        if dbResult.length() == 1 {
            types:WorkflowInstance insertedWkfInstance = {
                id: dbResult[0],
                orgId: context.orgId,
                createdTime: createdTime,
                context: wkfInstanceReq.context,
                createdBy: context.userId,
                requestComment: wkfInstanceReq.requestComment,
                config: {
                    id: "",   //TODO: need to find it by definitionID
                    workflowDefinitionId: wkfInstanceReq.context.workflowDefinitionIdentifier,
                    assigneeRoles: [],
                    assignees: [],
                    formatRequestData: true
                },
                reviewerDecision: (),
                status: "PENDING"
            };
            return insertedWkfInstance;
        } else {
            string message = "Error while inserting workflow instance to the database";
            return error error:DatabaseError(message, wkfInstanceId = workflowInstanceUuid);
        }
        // WorkflowInstanceInsert insertData = {
        //     id: workflowInstanceUuid,
        //     orgId: context.orgId,
        //     'resource: wkfInstanceReq.context.resource,
        //     action: wkfInstanceReq.context.action,
        //     createdBy: context.userId
        //     createdTime: time:cu,
        //     //requestComment: wkfInstanceReq.requestComment,
        //     //data: wkfInstanceReq.data,
        //     //status: "PENDING",
        //     //orgWorkflowConfigId: wkfInstanceReq.context.workflowConfigId
        // };
        // string[] dbResult = check dbClient->/workflowinstances.post([insertData]);
        // if dbResult.length() == 1 {
        //     types:WorkflowInstance insertedWkfInstance = {
        //         id: dbResult[0],
        //         orgId: wkfInstanceReq.context.orgId,
        //         createdTime: time:utc(),
        //         context: wkfInstanceReq.context,
        //         requestedBy: wkfInstanceReq.requestedBy,
        //         requestComment: wkfInstanceReq.requestComment,
        //         config: {
        //             id: wkfInstanceReq.context.workflowConfigId,
        //             workflowDefinitionId: "",
        //             orgId: wkfInstanceReq.context.orgId,
        //             assigneeRoles: [],
        //             assignees: [],
        //             formatRequestData: true
        //         },
        //         reviewerDecision: (),
        //         status: "PENDING"
        //     };
        //     return insertedWkfInstance;
        // } else {
        //     string message = "Error while inserting workflow instance to the database";
        //     return error error:DatabaseError(message, wkfInstanceId = workflowInstanceUuid);
        // }
    } on fail error e {
        string message = "Error while inserting workflow instance to the database";
        util:logError(context, message, e);
        return error error:DatabaseError(message, e);
    }
}
