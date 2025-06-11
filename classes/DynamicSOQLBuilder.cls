public with sharing class DynamicSOQLBuilder {

    public class QueryBuildException extends Exception {}

    public class QueryInput {
        @InvocableVariable(label='Table Name') public String tableName;
        @InvocableVariable(label='Fields to Select') public List<String> fields;
        @InvocableVariable(label='Aggregations (JSON serialized list)') public String aggregationJson;
        @InvocableVariable(label='Filters (JSON serialized list)') public String filtersJson;
        @InvocableVariable(label='Group By (JSON serialized list)') public String groupByJson;
        @InvocableVariable(label='Order By (JSON serialized list)') public String orderByJson;
        @InvocableVariable(label='Limit') public Integer limitValue;
    }

    public class QueryOutput {
        @InvocableVariable(label='Generated SQL Query') public String query;
    }

    @InvocableMethod(label='Build Dynamic SQL Query')
    public static List<QueryOutput> buildQuery(List<QueryInput> inputs) {
        List<QueryOutput> outputs = new List<QueryOutput>();

        for (QueryInput input : inputs) {
            QueryOutput output = new QueryOutput();

            try {
                List<String> filtersList = parseJsonList(input.filtersJson);
                List<String> groupByList = parseJsonList(input.groupByJson);
                List<String> orderByList = parseJsonList(input.orderByJson);
                List<String> aggregationList = parseJsonList(input.aggregationJson);

                String query = generateQuery(
                    input.tableName,
                    input.fields,
                    aggregationList,
                    filtersList,
                    groupByList,
                    orderByList,
                    input.limitValue
                );

                output.query = query;

            } catch (Exception e) {
                throw new QueryBuildException('Error building query: ' + e.getMessage());
            }

            outputs.add(output);
        }

        return outputs;
    }

    private static String generateQuery(
        String tableName,
        List<String> fields,
        List<String> aggregationList,
        List<String> filtersList,
        List<String> groupByList,
        List<String> orderByList,
        Integer limitValue
    ) {
        if (String.isBlank(tableName)) {
            throw new QueryBuildException('Table name cannot be null or empty.');
        }

        String query = 'SELECT ';
        List<String> selectParts = new List<String>();

        if (fields != null && !fields.isEmpty()) {
            selectParts.addAll(fields);
        }

        if (aggregationList != null && !aggregationList.isEmpty()) {
            selectParts.addAll(aggregationList); // Pas d’alias
        }

        if (selectParts.isEmpty()) {
            query += '*';
        } else {
            query += String.join(selectParts, ', ');
        }

        query += ' FROM ' + tableName;

        if (filtersList != null && !filtersList.isEmpty()) {
            query += ' WHERE ' + String.join(filtersList, ' AND ');
        }

        if (groupByList != null && !groupByList.isEmpty()) {
            query += ' GROUP BY ' + String.join(groupByList, ', ');
        }

        if (orderByList != null && !orderByList.isEmpty()) {
            query += ' ORDER BY ' + String.join(orderByList, ', ');
        }

        if (limitValue != null && limitValue > 0) {
            query += ' LIMIT ' + limitValue;
        }

        return query;
    }

    private static List<String> parseJsonList(String jsonString) {
        List<String> result = new List<String>();
        if (String.isNotBlank(jsonString)) {
            List<Object> tmp = (List<Object>) JSON.deserializeUntyped(jsonString);
            for (Object o : tmp) {
                result.add((String) o);
            }
        }
        return result;
    }
}
