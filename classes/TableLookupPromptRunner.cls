/**
 * @description       : Simplified version for Flow Orchestration
 * @author            : Adapted by GPT Assistant
 * @group             : AgentForce GPT
**/
global with sharing class TableLookupPromptRunner {

    // Invocable exposed to Flow : only userQuestion + userRole needed
    @InvocableMethod(label='Run Table Selection Prompt Builder (Simplified for Flow)')
    global static List<PromptOutputWrapper> runSimplified(List<PromptInputWrapper> inputs) {
        List<PromptOutputWrapper> results = new List<PromptOutputWrapper>();

        for (PromptInputWrapper input : inputs) {
            try {
                // Fetch table metadata from Data Cloud
                String tableMetadataJson = fetchTableMetadata('default');

                // Build wrapped input params for PromptTemplate
                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{
                    'Input:user_question' => wrap(input.userQuestion),
                    'Input:user_role' => wrap(input.userRole),
                    'Input:table_metadata' => wrap(tableMetadataJson)
                };

                // Build Prompt request
                ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                promptInput.isPreview = false;
                promptInput.inputParams = inputParams;
                promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
                promptInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

                // Execute PromptTemplate
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Table_Lookup', promptInput);

                String rawJson = JSON.serialize(result);

                // Extract prompt content using getPromptContentOnly
                String extractedContent = getPromptContentOnly.getPromptContentOnly(rawJson);
                String cleanedJson = cleanJson(extractedContent);

                PromptOutputWrapper output = new PromptOutputWrapper();
                output.promptContent = cleanedJson;
                results.add(output);

            } catch (Exception e) {
                PromptOutputWrapper output = new PromptOutputWrapper();
                output.promptContent = '❌ Error: ' + e.getMessage();
                results.add(output);
                System.debug('❌ Error during PromptBuilder execution: ' + e.getMessage());
            }
        }
        return results;
    }

    // Input class for Flow
    global class PromptInputWrapper {
        @InvocableVariable(label='User Question')
        public String userQuestion;

        @InvocableVariable(label='User Role')
        public String userRole;
    }

    // Output class for Flow
    global class PromptOutputWrapper {
        @InvocableVariable(label='Cleaned Prompt Content')
        public String promptContent;
    }

    // Helper to wrap values for Prompt input
    private static ConnectApi.WrappedValue wrap(Object val) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = val;
        return wrapped;
    }

    // Metadata fetcher
    private static String fetchTableMetadata(String dataspace) {
        List<DataCloudGetAllTables.RequestWrapper> requests = new List<DataCloudGetAllTables.RequestWrapper>();
        DataCloudGetAllTables.RequestWrapper req = new DataCloudGetAllTables.RequestWrapper();
        req.dataspace = dataspace;
        requests.add(req);

        List<DataCloudGetAllTables.ResponseWrapper> responseList = DataCloudGetAllTables.getAllTables(requests);
        if (responseList.isEmpty()) {
            throw new CalloutException('No tables found for dataspace: ' + dataspace);
        }

        List<Object> tablesList = new List<Object>();
        for (DataCloudGetAllTables.TableMetadata tm : responseList[0].tables) {
            tablesList.add(new Map<String, Object>{ 'name' => tm.table });
        }
        Map<String, Object> metadataMap = new Map<String, Object>{ 'tables' => tablesList };
        return JSON.serialize(metadataMap);
    }

    // Clean Markdown ```json``` artifacts
    private static String cleanJson(String rawJson) {
        if (rawJson == null) return '';
        return rawJson.replace('```json','').replace('```','').trim();
    }
}