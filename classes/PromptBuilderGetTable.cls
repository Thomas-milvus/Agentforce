public with sharing class PromptBuilderGetTable {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input' description='A JSON string that must contain a "Tables" key')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Table Name') public String table;
    }

    @InvocableMethod(label='Extract Table Name from PromptBuilder Output (Direct String for Flow)')
    public static List<OutputWrapper> extractTables(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('Provided JSON is empty or null.');
            }

            try {
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);

                if (!parsedJson.containsKey('Tables')) {
                    throw new JSONException('The key "Tables" is missing from the JSON.');
                }

                List<Object> tablesListObj = (List<Object>) parsedJson.get('Tables');
                if (tablesListObj.isEmpty()) {
                    throw new JSONException('The Tables list is empty.');
                }

                String tableName = (String) tablesListObj[0];

                OutputWrapper out = new OutputWrapper();
                out.table = tableName;
                results.add(out);

            } catch (Exception e) {
                throw new JSONException('Error parsing tables: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}