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

import ballerina/log;
import ballerina/lang.value;
import ballerina/jballerina.java;
import ballerina/lang.runtime;

isolated function getLogCallerModuleName() returns string {
    runtime:StackFrame[] stack = runtime:getStackTrace();
    java:StackFrameImpl|error callerFrame = value:ensureType(stack[5]);
    if callerFrame is java:StackFrameImpl {
        string? moduleName = callerFrame.moduleName;
        if moduleName is string {
            return moduleName;
        }
    }
    return "";
}

isolated function getKeyValuesWithContext(Context ctx, log:KeyValues keyValues) returns log:KeyValues {
    string[] keys = ctx.keys();
    log:KeyValues keyValuesWithContext = keyValues.clone();
    foreach string key in keys {
        var value = ctx.get(key);
        // Avoid adding or replacing attributes with empty values.
        if value is string && value == "" {
            continue;
        }
        keyValuesWithContext[key] = value;
    }
    string logCallerModuleName = getLogCallerModuleName();
    if (logCallerModuleName != "") {
        keyValuesWithContext["module"] = logCallerModuleName;
    }
    return keyValuesWithContext;
}

# Logs a debug message with the given message and module name.
#
# + ctx - The HTTP request context.
# + message - The message to be logged.
# + keyValues - Key value pairs to be logged.
public isolated function logDebug(Context ctx, string message, log:KeyValues keyValues = {}) {
    log:printDebug(message, keyValues = getKeyValuesWithContext(ctx, keyValues));
}

# Logs an informational message with the given message and module name.
#
# This function takes in the HTTP request context, message to be logged and the name of the module as parameters.
# It then logs the message as an informational message.
#
# + ctx - The HTTP request context.
# + message - The message to be logged.
# + keyValues - Key value pairs to be logged.
public isolated function logInfo(Context ctx, string message, log:KeyValues keyValues = {}) {
    log:printInfo(message, keyValues = getKeyValuesWithContext(ctx, keyValues));
}

# Function to log the error messages
#
# + ctx - http request context
# + message - message to be logged
# + err - error object
# + keyValues - Key value pairs to be logged.
public isolated function logError(Context ctx, string message, error? err, log:KeyValues keyValues = {}) {
    log:printError(message, 'error = err, keyValues = getKeyValuesWithContext(ctx, keyValues));
}

# Function to log the warning messages
#
# + ctx - http request context
# + message - message to be logged
# + err - error object if any
# + keyValues - Key value pairs to be logged.
public isolated function logWarn(Context ctx, string message, error? err, log:KeyValues keyValues = {}) {
    log:printWarn(message, 'error = err, keyValues = getKeyValuesWithContext(ctx, keyValues));
}
