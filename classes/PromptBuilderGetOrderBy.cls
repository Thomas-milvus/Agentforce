public with sharing class PromptBuilderGetOrderBy {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input') public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='OrderBy (JSON serialized string)') public String orderByJson;
    }

    @InvocableMethod(label='Extract OrderBy from PromptBuilder Output (JSON String for Flow)')
    public static List<OutputWrapper> extractOrderBy(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            if (String.isBlank(input.jsonString)) {
                throw new JSONException('JSON is empty.');
            }

            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);
                List<Object> orderByRaw = (List<Object>) parsed.get('orderBy');
                List<String> orderByList = new List<String>();

                for (Object o : orderByRaw) {
                    orderByList.add((String) o);
                }

                OutputWrapper out = new OutputWrapper();
                out.orderByJson = JSON.serialize(orderByList);
                results.add(out);
            } catch (Exception e) {
                throw new JSONException('Error parsing orderBy: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}