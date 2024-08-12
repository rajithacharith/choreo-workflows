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

public type WorkflowDefinition record {|
    string id;
    string name;
    string description;
    string approverTypes;
    boolean executeUponApproval;
    boolean allowParallelRequests;
    json requestFormatSchema;
|};

public type OrgWorkflowConfig record {|
    string id;
    string orgId;
    string workflowId;
    string assigneeRoles;
    string assignees;
    boolean formatRequestData;
    string externalWorkflowEngineEndpoint;
|};

public type WorkflowInstance record {|
    string id;
    string OrgWorkflowConfigId;
    string orgId;
    string 'resource;
    string action;
    string requestedBy;
    string requestedTime;
    string requestComment?;
    string data;
    string status;
    string reviewedBy?;
    string reviewerDecision?;
    string reviewComment?;
    string reviewTime?;
|};

public type AuditEvent record {|
    string id;
    string orgId;
    string eventType;
    string time;
    string user;
    string workflowId;
    string comment?;  // request comment or review comment
|};

public type WorkflowInstanceData record {|
    string workflowId;
    string orgId;
    string action;
    string 'resource;
    json data;
|};
