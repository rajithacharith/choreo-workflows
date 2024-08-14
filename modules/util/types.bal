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
import ballerina/http;

public type Context record {|
    string requestId;
    string orgId;
    string userId;
    anydata...;
|};

public type OrganizationInfo record {|
    string 'handle;
    string uuid;
|};

public type SucessResponse record {|
    string message;
|};

public type ResourceNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

public type BadRequest record {|
    *http:BadRequest;
    ErrorDetails body;
|};

public type Forbidden record {|
    *http:Forbidden;
    ErrorDetails body;
|};

public type InternalServerError record {|
    *http:InternalServerError;
    ErrorDetails body;
|};

public type Conflict record {|
    *http:Conflict;
    ErrorDetails body;
|};

public type ResourceCreated record {|
    string details;
    string id?;
    anydata 'resource?;
|};

public type ResourceConflict record {|
    *http:Conflict;
    ErrorDetails body;
|};

public type ErrorDetails record {|
    string 'error;
    string details;
|};
