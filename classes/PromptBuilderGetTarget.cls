public with sharing class PromptBuilderGetTarget {

    public class InputWrapper {
        @InvocableVariable(label='JSON Input' description='A JSON string that must contain a "User target" key')
        public String jsonString;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Extracted Target' description='The value of the "User target" key in the JSON input')
        public String userTarget;
    }

    @InvocableMethod(label='Extract Target from JSON' description='Extracts the "User target" value from a JSON string and returns it as a string')
    public static List<OutputWrapper> extractTarget(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();

            if (String.isBlank(input.jsonString)) {
                throw new JSONException('Provided JSON is empty or null.');
            }

            try {
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(input.jsonString);

                if (!parsedJson.containsKey('User target')) {
                    throw new JSONException('The key "User target" is missing from the JSON.');
                }

                output.userTarget = parsedJson.get('User target') != null ? String.valueOf(parsedJson.get('User target')) : null;
                results.add(output);

            } catch (Exception e) {
                throw new JSONException('Error parsing JSON or retrieving "User target" key: ' + e.getMessage());
            }
        }
        return results;
    }

    public class JSONException extends Exception {}
}
