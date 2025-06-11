public with sharing class GetBaselineFromPromptResponse {

    public class InputWrapper {
        @InvocableVariable(label='Aggregation JSON')
        public String aggregationJson;

        @InvocableVariable(label='Filters JSON')
        public String filtersJson;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Baseline Total (Decimal)')
        public Decimal baseline;
    }

    @InvocableMethod(label='Get Baseline From Prompt Response')
    public static List<OutputWrapper> run(List<InputWrapper> inputs) {
        if (inputs.isEmpty()) {
            throw new QueryException('Input is empty.');
        }

        InputWrapper input = inputs[0];
        String tableName = 'AMR_Sales_Details_c_Home__dlm';

        // Step 1 - Build dynamic SQL
        DynamicSOQLBuilder.QueryInput buildInput = new DynamicSOQLBuilder.QueryInput();
        buildInput.tableName = tableName;
        buildInput.fields = new List<String>();
        buildInput.aggregationJson = input.aggregationJson;
        buildInput.filtersJson = input.filtersJson;
        buildInput.groupByJson = JSON.serialize(new List<String>());
        buildInput.orderByJson = JSON.serialize(new List<String>());
        buildInput.limitValue = null;

        List<DynamicSOQLBuilder.QueryInput> buildInputs = new List<DynamicSOQLBuilder.QueryInput>{ buildInput };
        List<DynamicSOQLBuilder.QueryOutput> queryOutputList = DynamicSOQLBuilder.buildQuery(buildInputs);
        String query = queryOutputList[0].query;

        // Step 2 - Execute query
        DataCloudQueryExecutor.QueryInputWrapper queryInput = new DataCloudQueryExecutor.QueryInputWrapper();
        queryInput.queryText = query;
        queryInput.dataspaceName = 'default';

        List<DataCloudQueryExecutor.QueryResultWrapper> queryResults =
            DataCloudQueryExecutor.runQueryAndParse(new List<DataCloudQueryExecutor.QueryInputWrapper>{ queryInput });

        Decimal baselineValue = 0;
        if (!queryResults.isEmpty()) {
            List<Object> rows = (List<Object>) JSON.deserializeUntyped(queryResults[0].jsonResult);
            if (!rows.isEmpty()) {
                Map<String, Object> row = (Map<String, Object>) rows[0];
                for (String key : row.keySet()) {
                    Object val = row.get(key);
                    if (val != null && String.valueOf(val) != 'null') {
                        try {
                            String cleaned = String.valueOf(val).replace(',', '');
                            baselineValue = Decimal.valueOf(cleaned);
                        } catch (Exception e) {
                            throw new QueryException('Could not convert baseline value: ' + String.valueOf(val));
                        }
                        break;
                    }
                }
            }
        }

        OutputWrapper output = new OutputWrapper();
        output.baseline = baselineValue;
        return new List<OutputWrapper>{ output };
    }
}
