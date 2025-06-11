public with sharing class DataCloudQueryExecutor {

    public class QueryInputWrapper {
        @InvocableVariable(label='SQL Query' description='ANSI SQL query to run on Salesforce Data Cloud')
        public String queryText;

        @InvocableVariable(label='Dataspace Name' description='Name of the Data Cloud dataspace to run the query against')
        public String dataspaceName;
    }

    public class QueryResultWrapper {
        @InvocableVariable(label='Query Result (JSON)' description='List of rows as a JSON string with field names as keys')
        public String jsonResult;
    }

    @InvocableMethod(label='Run Data Cloud SQL Query' description='Executes an ANSI SQL query on Data Cloud and returns the result as JSON')
    public static List<QueryResultWrapper> runQueryAndParse(List<QueryInputWrapper> requests) {
        List<QueryResultWrapper> results = new List<QueryResultWrapper>();

        for (QueryInputWrapper req : requests) {
            try {
                ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
                input.sql = req.queryText;
                ConnectApi.CdpQueryOutputV2 result = ConnectApi.CdpQuery.queryAnsiSqlV2(input, req.dataspaceName);

                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(result));
                List<Object> dataRows = (List<Object>) parsed.get('data');
                Map<String, Object> metadata = (Map<String, Object>) parsed.get('metadata');

                Map<Integer, String> orderedMap = new Map<Integer, String>();
                for (String fieldName : metadata.keySet()) {
                    Map<String, Object> fieldMeta = (Map<String, Object>) metadata.get(fieldName);
                    if (fieldMeta.containsKey('placeInOrder')) {
                        Integer pos = ((Decimal) fieldMeta.get('placeInOrder')).intValue();
                        orderedMap.put(pos, fieldName);
                    }
                }

                List<Integer> sortedPositions = new List<Integer>(orderedMap.keySet());
                sortedPositions.sort();

                List<String> orderedColumns = new List<String>();
                for (Integer pos : sortedPositions) {
                    orderedColumns.add(orderedMap.get(pos));
                }

                List<Map<String, Object>> parsedRows = new List<Map<String, Object>>();
                for (Object rowObj : dataRows) {
                    List<Object> rowValues = (List<Object>) rowObj;
                    Map<String, Object> row = new Map<String, Object>();
                    for (Integer i = 0; i < orderedColumns.size(); i++) {
                        String colName = orderedColumns[i];
                        Object val = (i < rowValues.size()) ? rowValues[i] : null;
                        row.put(colName, val);
                    }
                    parsedRows.add(row);
                }

                QueryResultWrapper wrapper = new QueryResultWrapper();
                wrapper.jsonResult = JSON.serialize(parsedRows);
                results.add(wrapper);

            } catch (Exception e) {
                throw new CalloutException('Error running query: ' + e.getMessage());
            }
        }

        return results;
    }
}