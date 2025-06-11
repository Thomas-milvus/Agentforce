public with sharing class PromptBuilderGetGroupBy {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input') public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='GroupBy (JSON serialized string)') public String groupByJson;
    }

    @InvocableMethod(label='Extract GroupBy from PromptBuilder Output (JSON String for Flow)')
    public static List<OutputWrapper> extractGroupBy(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON is empty.');
            }

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                List<Object> groupByRaw = (List<Object>) parsed.get('groupBy');
                List<String> groupByList = new List<String>();

                for (Object o : groupByRaw) {
                    groupByList.add((String) o);
                }

                OutputWrapper out = new OutputWrapper();
                out.groupByJson = JSON.serialize(groupByList); // conversion JSON string comme pour filters/orderBy
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error parsing groupBy: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}