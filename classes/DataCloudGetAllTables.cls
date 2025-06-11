public with sharing class DataCloudGetAllTables {

    public class TableMetadata {
        @InvocableVariable(label='Table Name' description='The name of the table in Data Cloud')
        public String table;
    }

    public class RequestWrapper {
        @InvocableVariable(label='Full Metadata JSON' description='The full metadata JSON previously fetched from Data Cloud')
        public String fullJson;
    }

    public class ResponseWrapper {
        @InvocableVariable(label='Tables List' description='List of all table names found in metadata JSON')
        public List<TableMetadata> tables;
    }

    @InvocableMethod(label='Extract All Tables from Metadata JSON' description='Parses metadata JSON and extracts all table names')
    public static List<ResponseWrapper> getAllTables(List<RequestWrapper> requests) {
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            List<TableMetadata> result = new List<TableMetadata>();

            try {
                if (String.isBlank(req.fullJson)) {
                    throw new CalloutException('Input fullJson cannot be empty.');
                }

                List<DataCloudPromptMetadataBuilder.TableMetadata> metadataList = 
                    (List<DataCloudPromptMetadataBuilder.TableMetadata>)
                    JSON.deserialize(req.fullJson, List<DataCloudPromptMetadataBuilder.TableMetadata>.class);

                for (DataCloudPromptMetadataBuilder.TableMetadata tm : metadataList) {
                    TableMetadata tableMeta = new TableMetadata();
                    tableMeta.table = tm.table;
                    result.add(tableMeta);
                }

            } catch (Exception e) {
                throw new CalloutException('Error in getAllTables: ' + e.getMessage());
            }

            ResponseWrapper wrapper = new ResponseWrapper();
            wrapper.tables = result;
            responseList.add(wrapper);
        }

        return responseList;
    }
}
