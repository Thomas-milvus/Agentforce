public with sharing class PromptBuilderQueryFromJson {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input' description='A JSON string describing the table, fields, filters, orderBy, and limit')
        public String jsonInput;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Generated Query' description='The final SOQL query generated from the JSON input')
        public String query;
    }

    @InvocableMethod(label='Build Query from JSON' description='Generates a SOQL query from a JSON input')
    public static List<OutputWrapper> buildQuery(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();

            try {
                String jsonInput = input.jsonInput;

                // TABLE
                PromptBuilderGetTable.InputWrapper tableInput = new PromptBuilderGetTable.InputWrapper();
                tableInput.jsonString = jsonInput;
                List<PromptBuilderGetTable.OutputWrapper> tableResult =
                    PromptBuilderGetTable.extractTable(new List<PromptBuilderGetTable.InputWrapper>{ tableInput });
                String table = tableResult.isEmpty() ? null : tableResult[0].table;

                // FIELDS
                PromptBuilderGetFields.InputWrapper fieldsInput = new PromptBuilderGetFields.InputWrapper();
                fieldsInput.jsonString = jsonInput;
                List<PromptBuilderGetFields.OutputWrapper> fieldsResult =
                    PromptBuilderGetFields.extractFields(new List<PromptBuilderGetFields.InputWrapper>{ fieldsInput });
                List<String> fields = fieldsResult.isEmpty() ? new List<String>() : fieldsResult[0].fields;

                // FILTERS
                PromptBuilderGetFilter.InputWrapper filterInput = new PromptBuilderGetFilter.InputWrapper();
                filterInput.jsonString = jsonInput;
                List<PromptBuilderGetFilter.OutputWrapper> filterResult = PromptBuilderGetFilter.extractFilters(
                    new List<PromptBuilderGetFilter.InputWrapper>{ filterInput }
                );
                String filtersJsonStr = filterResult[0].filtersJson;
                Map<String, Object> filtersMap = (Map<String, Object>) JSON.deserializeUntyped(filtersJsonStr);
                
                // ORDER BY
                PromptBuilderGetOrderBy.InputWrapper orderByInput = new PromptBuilderGetOrderBy.InputWrapper();
                orderByInput.jsonString = jsonInput;
                List<PromptBuilderGetOrderBy.OutputWrapper> orderByResult =
                    PromptBuilderGetOrderBy.extractOrderBy(new List<PromptBuilderGetOrderBy.InputWrapper>{ orderByInput });
                String orderBy = orderByResult.isEmpty() ? null : orderByResult[0].orderBy;

                // LIMIT (⚠️ éviter nom réservé)
                PromptBuilderGetLimit.InputWrapper limitInput = new PromptBuilderGetLimit.InputWrapper();
                limitInput.jsonString = jsonInput;
                List<PromptBuilderGetLimit.OutputWrapper> limitResult =
                    PromptBuilderGetLimit.extractLimit(new List<PromptBuilderGetLimit.InputWrapper>{ limitInput });
                Integer limitValue = limitResult.isEmpty() ? null : limitResult[0].limitValue;

                // BUILD QUERY
                DynamicSOQLBuilder.QueryInput queryInput = new DynamicSOQLBuilder.QueryInput();
                queryInput.tableName = table;
                queryInput.fields = fields;
                queryInput.filtersJson = JSON.serialize(filtersMap);
                queryInput.orderBy = orderBy;
                queryInput.limitValue = limitValue;

                List<DynamicSOQLBuilder.QueryOutput> queryOutput =
                    DynamicSOQLBuilder.buildQuery(new List<DynamicSOQLBuilder.QueryInput>{ queryInput });

                output.query = queryOutput.isEmpty() ? 'Empty result' : queryOutput[0].query;

            } catch (Exception e) {
                output.query = 'Error generating query: ' + e.getMessage();
            }

            results.add(output);
        }

        return results;
    }
}