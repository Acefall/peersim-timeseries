// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.luftdaten;

import com.mongodb.*;
import com.mongodb.client.AggregateIterable;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Accumulators;
import com.mongodb.client.model.Filters;
import org.bson.Document;
import org.bson.conversions.Bson;
import peersim.config.Configuration;
import timeseries.Observation;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;

import static com.mongodb.client.model.Aggregates.*;

/**
 * Driver that provides P1 measurements from a MongoDB for a certain time interval.
 */

public class MongoDBDriver implements ILuftdatenDriver {
    private static final String PAR_HOST = "host";
    private static final String PAR_PORT = "port";


    private final MongoClient client;
    private final MongoDatabase database;

    public MongoDBDriver(String host, int port) {
        client = new MongoClient("localhost", 27017);
        database = client.getDatabase("luftdaten");
    }

    public MongoDBDriver(String name) {
        client = new MongoClient(
                Configuration.getString(name + "." + PAR_HOST, "localhost"),
                Configuration.getInt(name + "." + PAR_PORT, 27017)
        );
        database = client.getDatabase("luftdaten");
    }

    /**
     * Returns a mapping from sensor ids to measurements.
     * For each sensor that had a measurement between t-validPeriod and t
     * it returns the latest measurement for that sensor.
     *
     * @param t             upper limit of time interval
     * @param validDuration length of the time interval
     * @param sensorType    has to be equal to the name of the collection
     * @return
     */

    public HashMap<String, Observation> valuesAt(LocalDateTime t, Duration validDuration, String sensorType, String environmentVariable) {
        var collection = database.getCollection(sensorType);

        // Select documents in this time interval
        Bson match = match(Filters.and(
                Filters.gte("timestamp", t.minus(validDuration)),
                Filters.lt("timestamp", t)
        ));

        // Get the last observation from each sensor_id
        Bson group = group("$sensor_id", Accumulators.last("last_observation", "$$ROOT"));

        // Run the actual query
        AggregateIterable<Document> resultSet = collection.aggregate(Arrays.asList(
                match, group
        )).allowDiskUse(true);

        Document resultDoc = collection.aggregate(Arrays.asList(
                match, group
        )).allowDiskUse(true).first();

        HashMap<String, Observation> measurements = new HashMap<String, Observation>();

        for (Document doc : resultSet) {
            Double measurement;
            try {
                measurement = (Double) doc.get("last_observation", Document.class).get(environmentVariable);
                if (measurement == null) {
                    throw new Exception("Measurement is null");
                }
            } catch (Exception e) {
                System.err.println("Failed to convert measurement to double");
                measurement = Double.NaN;
            }

            LocalDateTime tObs;
            try {
                Date timestamp = (Date) doc.get("last_observation", Document.class).get("timestamp");
                tObs = LocalDateTime.ofInstant(timestamp.toInstant(), ZoneId.of("UTC"));
            } catch (Exception e) {
                System.err.println("Failed to parse timestamp");
                throw e;
            }

            measurements.put(doc.get("_id").toString(), new Observation(tObs, measurement));
        }

        return measurements;
    }
}
