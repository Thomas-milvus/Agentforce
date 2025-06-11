public class DataCloudUtils {
    public static void printKeyValueRows(List<Map<String, Object>> rows) {
        Integer i = 1;
        for (Map<String, Object> row : rows) {
            System.debug('📊 Record ' + i);
            for (String key : row.keySet()) {
                System.debug('- ' + key + ': ' + String.valueOf(row.get(key)));
            }
            i++;
        }
    }
}