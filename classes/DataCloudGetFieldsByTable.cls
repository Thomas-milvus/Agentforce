public with sharing class DataCloudGetFieldsByTable {

    public class RequestWrapper {
        @InvocableVariable(label='Table Name' description='The name of the table you want fields for')
        public String entityName;

        @InvocableVariable(label='Full Metadata JSON' description='The full metadata JSON (from DataCloudPromptMetadataBuilder)')
        public String metadataJson;
    }

    public class ResponseWrapper {
        @InvocableVariable(label='Field Names (Concatenated)')
        public String fieldNames; // 👉 string unique concaténée
    }

    @InvocableMethod(label='Get Fields String from Metadata JSON')
    public static List<ResponseWrapper> getFieldsByTable(List<RequestWrapper> requests) {
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();

        for (RequestWrapper request : requests) {
            if (String.isBlank(request.entityName) || String.isBlank(request.metadataJson)) {
                throw new CalloutException('Both entityName and metadataJson are required.');
            }

            try {
                // Désérialisation du fullJson
                List<DataCloudPromptMetadataBuilder.TableMetadata> metadataList = 
                    (List<DataCloudPromptMetadataBuilder.TableMetadata>)
                    JSON.deserialize(request.metadataJson, List<DataCloudPromptMetadataBuilder.TableMetadata>.class);

                // Recherche de la table
                for (DataCloudPromptMetadataBuilder.TableMetadata tm : metadataList) {
                    if (tm.table == request.entityName) {
                        List<String> fieldNamesList = new List<String>();

                        for (DataCloudPromptMetadataBuilder.FieldMetadata fm : tm.fields) {
                            fieldNamesList.add(fm.name);
                        }

                        ResponseWrapper wrapper = new ResponseWrapper();
                        wrapper.fieldNames = String.join(fieldNamesList, ', ');  // 👉 on concatène tout ici
                        responseList.add(wrapper);
                        break;
                    }
                }
            } catch (Exception e) {
                throw new CalloutException('Error in getFieldsByTable: ' + e.getMessage());
            }
        }

        return responseList;
    }
}
