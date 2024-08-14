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
import ballerina/sql;

public type DbWorkflowDefinition record {|
    string id;
    string name;
    string description;
    string approverTypes;
    boolean executeUponApproval;
    boolean allowParallelRequests;
    json requestFormatSchema;
|};

public type DbOrgWorkflowConfig record {|
    string id;
    string orgId;
    string workflowDefinitionId; //foreign key for WorkflowDefinition
    string assigneeRoles;
    string assignees;
    boolean formatRequestData;
    string externalWorkflowEngineEndpoint;
|};

public type DbWorkflowInstance record {|
    string id;
    string OrgWorkflowConfigId;  //foreign key for OrgWorkflowConfig
    string orgId;
    string 'resource;
    string action;
    string createdBy;
    string createdTime;
    string requestComment?;
    json data;
    string status;
    @sql:Column {
        name: "review_by"
    }
    string reviewedBy?;
    string reviewerDecision?;
    string reviewComment?;
    string reviewTime?;
|};

public type DbAuditEvent record {|
    string id;
    string orgId;
    string eventType; //request, review, approve, reject, cancel, execute
    string time;
    string user;
    string action;
    string 'resource;
    string workflowInstanceId; //do not foreign key to WorkflowInstance (as it can be deleted)
    string comment?;  // request comment or review comment
|};
