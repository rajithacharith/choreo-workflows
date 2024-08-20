// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.array;

public isolated function getFromContext(http:RequestContext ctx, string key) returns string {
    if ctx.hasKey(key) {
        return ctx.get(key).toString();
    }
    return "";
}

public isolated function getContext(http:RequestContext ctx, string orgId) returns Context {
    Context context = {
        requestId: getFromContext(ctx, REQUEST_ID),
        orgId: getFromContext(ctx, ORGANIZATION_ID),
        userId: getFromContext(ctx, USER_ID),
        orgHandle: getFromContext(ctx, ORGANIZATION_HANDLE)
    };
    return context;
}

public isolated function base64Decode(string estr) returns string|error {
    byte[] fromBase64Bytes = check array:fromBase64(estr);
    string decodedServiceId = check string:fromBytes(fromBase64Bytes);
    return decodedServiceId;
}
