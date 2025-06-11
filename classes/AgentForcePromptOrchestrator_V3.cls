global with sharing class AgentForcePromptOrchestrator_V3 {

    private static final String DATASPACE = 'default'; // Hardcoded dataspace here

    @InvocableMethod(label='AgentForce Prompt Orchestrator V3 - Full Pipeline (Dataspace Default)')
    global static List<OutputWrapper> runOrchestration(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            try {
                // STEP 0 - Fetch full Table Metadata from Data Cloud
                String tableMetadataJson = fetchTableMetadata();

                // STEP 1 - Run PromptTemplate (LLM)
                Map<String, Object> promptResult = runPromptTemplate(input.userQuestion, input.userRole, tableMetadataJson);

                // Extract tables from LLM output
                List<Object> tables = (List<Object>) promptResult.get('Tables');

                // STEP 2 - Fetch Fields from Data Cloud per table
                Map<String, Object> fieldsByTable = new Map<String, Object>();

                for (Object tableObj : tables) {
                    String tableName = (String) tableObj;

                    // Construire le request pour getFieldsByTable
                    DataCloudGetFieldsByTable.RequestWrapper request = new DataCloudGetFieldsByTable.RequestWrapper();
                    request.entityName = tableName;
                    request.dataspace = DATASPACE;

                    List<DataCloudGetFieldsByTable.RequestWrapper> requestList = new List<DataCloudGetFieldsByTable.RequestWrapper>{ request };

                    // Appel de l’API
                    List<DataCloudGetFieldsByTable.ResponseWrapper> responseList = DataCloudGetFieldsByTable.getFieldsByTable(requestList);
                    if (responseList.isEmpty()) {
                        throw new CalloutException('No fields returned for table: ' + tableName);
                    }

                    // Parse JSON du résultat
                    Map<String, Object> fieldsParsed = (Map<String, Object>) JSON.deserializeUntyped(responseList[0].fieldMetadataJson);
                    fieldsByTable.put(tableName, fieldsParsed);
                }


                // STEP 3 - Build final result
                Map<String, Object> finalResult = new Map<String, Object>{
                    'UserIntent' => promptResult.get('User intent'),
                    'UserTarget' => promptResult.get('User target'),
                    'Tables' => tables,
                    'Fields' => fieldsByTable
                };

                OutputWrapper output = new OutputWrapper();
                output.fullJson = JSON.serializePretty(finalResult);
                results.add(output);

            } catch (Exception e) {
                OutputWrapper output = new OutputWrapper();
                output.fullJson = '❌ Error: ' + e.getMessage();
                results.add(output);
                System.debug('❌ Orchestration Error: ' + e.getMessage());
            }
        }
        return results;
    }

    private static String fetchTableMetadata() {
        List<DataCloudGetAllTables.RequestWrapper> requests = new List<DataCloudGetAllTables.RequestWrapper>();
        DataCloudGetAllTables.RequestWrapper req = new DataCloudGetAllTables.RequestWrapper();
        req.dataspace = DATASPACE;
        requests.add(req);

        List<DataCloudGetAllTables.ResponseWrapper> responseList = DataCloudGetAllTables.getAllTables(requests);
        if (responseList.isEmpty()) {
            throw new CalloutException('No tables found for dataspace: ' + DATASPACE);
        }

        List<Object> tablesList = new List<Object>();
        for (DataCloudGetAllTables.TableMetadata tm : responseList[0].tables) {
            tablesList.add(new Map<String, Object>{ 'name' => tm.table });
        }
        Map<String, Object> metadataMap = new Map<String, Object>{ 'tables' => tablesList };
        return JSON.serialize(metadataMap);
    }

    private static Map<String, Object> runPromptTemplate(String question, String role, String tableMetadata) {
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{
            'Input:user_question' => wrap(question),
            'Input:user_role' => wrap(role),
            'Input:table_metadata' => wrap(tableMetadata)
        };

        ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        promptInput.isPreview = false;
        promptInput.inputParams = inputParams;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Table_Lookup', promptInput);

        String rawOutput = result.generations[0].text;
        String cleanedJson = cleanJson(rawOutput);

        return (Map<String, Object>) JSON.deserializeUntyped(cleanedJson);
    }

    private static ConnectApi.WrappedValue wrap(Object val) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = val;
        return wrapped;
    }

    private static String cleanJson(String rawJson) {
        if (rawJson == null) return '';
        return rawJson.replace('```json','').replace('```','').trim();
    }

    global class InputWrapper {
        @InvocableVariable(label='User Question') public String userQuestion;
        @InvocableVariable(label='User Role') public String userRole;
    }

    global class OutputWrapper {
        @InvocableVariable(label='Full JSON Output') public String fullJson;
    }
}
