public with sharing class MergeJsonResults {

    public class InputWrapper {
        @InvocableVariable(label='Data JSON')
        public String dataJson;

        @InvocableVariable(label='Metrics String (optional)')
        public String metricsJson;
    }

    public class OutputWrapper {
        @InvocableVariable(label='Merged JSON')
        public String mergedJson;
    }

    @InvocableMethod(label='Merge Data and Metrics JSON')
    public static List<OutputWrapper> mergeFunction(List<InputWrapper> inputList) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (Integer i = 0; i < inputList.size(); i++) {
            InputWrapper input = inputList[i];
            
            if (String.isBlank(input.dataJson)) {
                throw new MergeException('dataJson is required.');
            }

            try {
                // On désérialise tout le dataJson (et pas juste le 1er record comme avant)
                Object rawData = JSON.deserializeUntyped(input.dataJson);

                Map<String, Object> merged = new Map<String, Object>();
                merged.put('data', rawData); // stocke toute la liste telle quelle dans la clé "data"

                if (String.isBlank(input.metricsJson)) {
                    merged.put('metrics', null);
                } else {
                    // Si metricsJson est déjà un string JSON (ex : liste), on le parse pour stocker l'objet proprement
                    Object metricsObj = JSON.deserializeUntyped(input.metricsJson);
                    merged.put('metrics', metricsObj);
                }

                OutputWrapper output = new OutputWrapper();
                output.mergedJson = JSON.serialize(merged);
                results.add(output);
            } catch (Exception e) {
                throw new MergeException('Error merging JSON: ' + e.getMessage());
            }
        }
        return results;
    }

    public class MergeException extends Exception {}
}