public with sharing class GetMetrics {

    public class InputWrapper {
        @InvocableVariable(label='Metric Target')
        public String metricTarget; // attendu sous forme de JSON ex: ["sell_out_amount"]
    }

    @InvocableMethod(label='Get Metrics via Data Cloud Query')
    public static List<String> getMetrics(List<InputWrapper> inputs) {
        List<String> results = new List<String>();

        // On suppose qu’on appelle avec une seule entrée
        if (inputs.isEmpty()) {
            throw new QueryException('Input list is empty.');
        }

        InputWrapper input = inputs[0];

        if (String.isBlank(input.metricTarget)) {
            throw new QueryException('Metric Target cannot be empty.');
        }

        // On parse le JSON pour récupérer la vraie target
        List<Object> parsedList = (List<Object>) JSON.deserializeUntyped(input.metricTarget);
        if (parsedList.isEmpty()) {
            throw new QueryException('Metric Target list is empty.');
        }

        String target = (String) parsedList[0];

        String query = 
            'SELECT target_c__c, abs_ATE_c__c, feature_c__c, ATE_c__c, ATE_normalized_c__c, ' + 
            'correlation_c__c, direction_c__c, tested_value_c__c, ' +
            'mean_if_treated_c__c, mean_if_control_c__c, importance_score_c__c ' +
            'FROM AMR_Features_c_Home__dlm ' + 
            'WHERE target_c__c = \'' + String.escapeSingleQuotes(target) + '\'';

        String dataspace = 'default';

        List<DataCloudQueryExecutor.QueryInputWrapper> queryInputs = new List<DataCloudQueryExecutor.QueryInputWrapper>();
        DataCloudQueryExecutor.QueryInputWrapper req = new DataCloudQueryExecutor.QueryInputWrapper();
        req.queryText = query;
        req.dataspaceName = dataspace;
        queryInputs.add(req);

        List<DataCloudQueryExecutor.QueryResultWrapper> queryResults = DataCloudQueryExecutor.runQueryAndParse(queryInputs);

        if (!queryResults.isEmpty()) {
            results.add(queryResults[0].jsonResult);
        } else {
            results.add('[]');
        }

        return results;
    }
}
