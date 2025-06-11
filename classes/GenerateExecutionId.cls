global with sharing class GenerateExecutionId {

    global class InputWrapper {
        // Aucun champ requis ici, c'est juste pour satisfaire InvocableMethod
        @InvocableVariable(label='Dummy Input') 
        public String dummy;
    }

    global class OutputWrapper {
        @InvocableVariable(label='Execution ID') 
        public String executionId;
    }

    @InvocableMethod(label='Generate Execution ID')
    global static List<OutputWrapper> generate(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper output = new OutputWrapper();
            output.executionId = System.UUID.randomUUID().toString();
            results.add(output);
        }

        return results;
    }
}
