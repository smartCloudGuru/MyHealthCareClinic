/**
 * Used for geocoding address data
* @author Zoran Zunko
* @date 3/11/21
*
*/
public class GeoCodeAPI {
    private static final String key = 'AIzaSyBtjY92yjZUzynJS6Zu-6yo-AjZZkhq_4U';

    /*
    |--------------------------------------------------------------------------
    | JSON Parser
    |--------------------------------------------------------------------------
    |
    | This is a JSON to Apex Parser. Below will take the response
    | provided by Google's Geocoding API & deserialise it into
    | something we can refer to using Object-Oriented Apex.
    |
    */

    private List<Results> results;

    private class Results {
        private Geometry geometry;
    }

    private class Geometry {
        private Location location;
    }

    private class Location {
        private Double lat, lng;
    }

    private static GeoCodeAPI Parse(String json) {
        return (GeoCodeAPI) System.JSON.deserialize(json, GeoCodeAPI.class);
    }

    private static HttpResponse MakeGetCallout(String address) {
        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        return response;
    }


    //todo use google geocode api call
    public static System.Location getGeocode(String address) {
        HttpResponse response = GeoCodeAPI.MakeGetCallout(address);
        System.debug(LoggingLevel.FINE, 'getGeocode - response.getBody(): ' + response.getBody());
        GeoCodeAPI locationResponse = GeoCodeAPI.Parse(response.getBody());
        if (locationResponse.results.isEmpty()) {
            return null;
        } else {
            return System.Location.newInstance(locationResponse.results[0].geometry.location.lat, locationResponse.results[0].geometry.location.lng);
        }
    }
}