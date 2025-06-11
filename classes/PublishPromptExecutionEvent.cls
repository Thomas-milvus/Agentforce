global with sharing class PublishPromptExecutionEvent {

    global class InputWrapper {
        @InvocableVariable public String executionId;
        @InvocableVariable public String status;
        @InvocableVariable public String fullJson;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Publish Prompt Execution Platform Event (Async)')
    global static void invokeAsyncPublish(List<InputWrapper> inputs) {
        for (InputWrapper input : inputs) {
            PublishPromptExecutionEvent.publishEventAsync(
                input.executionId,
                input.status,
                input.fullJson,
                input.errorMessage
            );
        }
    }

    @future
    public static void publishEventAsync(String executionId, String status, String fullJson, String errorMessage) {
        try {
            Prompt_Execution_Event__e event = new Prompt_Execution_Event__e(
                ExecutionID__c = executionId,
                Status__c = status,
                Full_Json_Output__c = fullJson,
                Error_Message__c = errorMessage
            );

            EventBus.publish(event);
            System.debug('✅ Platform Event published asynchronously for ExecutionId: ' + executionId);
        } catch (Exception e) {
            System.debug('❌ Error while publishing PE: ' + e.getMessage());
        }
    }
}
