global with sharing class TaskAnalyzerPromptRunner {

    @InvocableMethod(label='Run Table and Field Selection Prompt Builder'
                     description='Runs the table and field selection prompt for a given user question and user role, and using table metadata from DataCloudPromptMetadataBuilder')
    global static List<String> run(List<PromptInputWrapper> inputs) {
        List<String> results = new List<String>();

        for (PromptInputWrapper input : inputs) {
            String result = runInternal(
                input.userQuestion, 
                input.userRole, 
                input.userTarget,
                input.userIntent,
                input.promptTemplateAPIName,
                input.tables,
                input.fieldMetadata);
            results.add(result);
        }

        return results;
    }

    public static String runInternal(String userQuestion, String userRole, String userTarget, String userIntent, String promptTemplateAPIName, String tables, String fieldMetadata) {
        try {
            // Safety check for mandatory parameters
            if (String.isBlank(fieldMetadata)) {
                throw new IllegalArgumentException('No field metadata found in the given dataspace.');
            }

            // Build input parameters map for the Prompt Template
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:user_question' => wrap(userQuestion),
                'Input:user_role' => wrap(userRole),
                'Input:user_target' => wrap(userTarget),
                'Input:user_intent' => wrap(userIntent),
                'Input:field_metadata' => wrap(fieldMetadata),
                'Input:tables' => wrap(tables)
            };

            // Build Prompt Template Input object
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            promptInput.isPreview = false;
            promptInput.inputParams = inputParams;

            // Optional additional config
            promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

            // Execute the Prompt Template
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(promptTemplateAPIName, promptInput);

            // Return serialized result
            if (result != null) {
                return JSON.serialize(result);
            } else {
                return '⚠️ No response generated from Prompt Builder.';
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return '⚠️ Error occurred: ' + e.getMessage();
        }
    }

    private static ConnectApi.WrappedValue wrap(Object val) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = val;
        return wrapped;
    }

    global class PromptInputWrapper {
        @InvocableVariable(label='User Question') public String userQuestion;
        @InvocableVariable(label='User Role') public String userRole;
        @InvocableVariable(label='User Target') public String userTarget;
        @InvocableVariable(label='User Intent') public String userIntent;
        @InvocableVariable(label='Prompt Template API Name') public String promptTemplateAPIName;
        @InvocableVariable(label='Tables') public String tables;
        @InvocableVariable(label='Field Metadata') public String fieldMetadata;
    }
}