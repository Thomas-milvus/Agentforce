public with sharing class PromptBuilderGetIntent {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input' description='A JSON string that must contain a "User intent" key')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Extracted Intent' description='The value of the "User intent" key in the JSON input')
        public String userIntent;
    }

    @InvocableMethod(
        label='Extract Intent from JSON' description='Extracts the "User intent" value from a JSON string and returns it as a string'
    )
    public static List<OutputWrapper> extractIntent(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();

            if (String.isBlank(input.jsonString)) {
                throw new JSONException('Provided JSON is empty or null.');
            }

            try {
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);

                if (!parsedJson.containsKey('User intent')) {
                    throw new JSONException('The key "User intent" is missing from the JSON.');
                }

                Object intentValue = parsedJson.get('User intent');
                output.userIntent = intentValue != null ? String.valueOf(intentValue) : null;

                results.add(output);

            } catch (Exception e) {
                throw new JSONException('Error parsing JSON or retrieving "User intent" key: ' + e.getMessage());
            }
        }

        return results;
    }

    public class JSONException extends Exception {}
}