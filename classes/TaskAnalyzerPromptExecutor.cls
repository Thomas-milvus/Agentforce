public with sharing class TaskAnalyzerPromptExecutor {

    private static final String PROMPT_TEMPLATE_API_NAME = 'TaskAnalyzer';  // Remplace si besoin si tu changes de DevName

    @InvocableMethod(label='Execute TaskAnalyzer Prompt' description='Executes the TaskAnalyzer PromptBuilder template')
    public static List<PromptOutputWrapper> run(List<PromptInputWrapper> inputs) {
        List<PromptOutputWrapper> results = new List<PromptOutputWrapper>();

        for (PromptInputWrapper input : inputs) {
            PromptOutputWrapper output = new PromptOutputWrapper();

            try {
                // Build input parameters for Einstein PromptTemplate call
                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{
                    'Input:user_question' => wrap(input.userQuestion),
                    'Input:user_target' => wrap(input.userTarget),
                    'Input:user_intent' => wrap(input.userIntent),
                    'Input:tables' => wrap(input.tablesJson),
                    'Input:field_metadata' => wrap(input.fieldMetadataJson)
                };

                ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                promptInput.isPreview = false;
                promptInput.inputParams = inputParams;

                // Optional: config
                promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
                promptInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

                // Call Einstein GPT PromptTemplate
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(PROMPT_TEMPLATE_API_NAME, promptInput);

                if (result != null) {
                    output.generatedContent = JSON.serializePretty(result);
                } else {
                    output.generatedContent = '⚠ No response generated.';
                }

            } catch (Exception e) {
                output.generatedContent = '⚠ Error: ' + e.getMessage();
            }

            results.add(output);
        }

        return results;
    }

    // Wrapper for Flow input
    public class PromptInputWrapper {
        @InvocableVariable(label='User Question') public String userQuestion;
        @InvocableVariable(label='User Target') public String userTarget;
        @InvocableVariable(label='User Intent') public String userIntent;
        @InvocableVariable(label='Tables JSON') public String tablesJson;
        @InvocableVariable(label='Field Metadata JSON') public String fieldMetadataJson;
    }

    // Wrapper for Flow output
    public class PromptOutputWrapper {
        @InvocableVariable(label='Generated Content') public String generatedContent;
    }

    // Utility to wrap values for ConnectApi
    private static ConnectApi.WrappedValue wrap(Object val) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = val;
        return wrapped;
    }
}