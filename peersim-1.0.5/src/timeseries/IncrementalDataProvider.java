// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import peersim.config.Configuration;
import peersim.core.Network;
import timeseries.luftdaten.FCFSMapping;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Data provider for which calls have to be with increasing t.
 * Uses this condition to more efficiently query the data source.
 */

public class IncrementalDataProvider implements IDataProvider {
    private final IDataSource dataSource;
    private final FCFSMapping mapping;
    private final Duration validDuration;
    private final Duration initValidDuration;
    private final Double defaultNa;
    private final int n;

    private LocalDateTime lastT;
    private final HashMap<String, Observation> lastObservations = new HashMap<String, Observation>();

    private static final String PAR_DATA_Source = "dataSource";
    private static final String PAR_INIT_VALID_DURATION = "initValidDuration";
    private static final String PAR_VALID_DURATION = "validDuration";
    private static final String PAR_DEFAULT_NA = "defaultNaN";


    /**
     * Data provider for which all calls to nodeValuesAt have to be with increasing t.
     *
     * @param dataSource The data source
     * @param initValidDuration The search duration for the first call to nodeValuesAt
     * @param validDuration Defines how long observations are valid. If they are too old they are replaced by defaultNa
     * @param defaultNa The default value if there is no recent observation available
     */
    public IncrementalDataProvider(IDataSource dataSource, int n, Duration initValidDuration, Duration validDuration, Double defaultNa) {
        this.dataSource = dataSource;
        this.mapping = new FCFSMapping();
        this.validDuration = validDuration;
        this.initValidDuration = initValidDuration;
        this.defaultNa = defaultNa;
        this.n = n;
    }


    public IncrementalDataProvider(String name){
        this.mapping = new FCFSMapping();
        this.n = Network.size();
        dataSource = (IDataSource) Configuration.getInstance(name + "." + PAR_DATA_Source);
        initValidDuration = Duration.ofMillis(Configuration.getInt(name + "." + PAR_INIT_VALID_DURATION));
        validDuration = Duration.ofMillis(Configuration.getInt(name + "." + PAR_VALID_DURATION));
        defaultNa = Configuration.getDouble(name + "." + PAR_DEFAULT_NA, Double.NaN);
    }

    private void updateLastObservations(LocalDateTime t, Duration searchDuration) {
        lastT = t;
        HashMap<String, Observation> sensorValues = dataSource.sensorValuesAt(t, searchDuration);

        for (var entry : sensorValues.entrySet()) {
            lastObservations.put(entry.getKey(), entry.getValue());
        }
    }

    @Override
    public HashMap<Integer, Double> nodeValuesAt(LocalDateTime t) {
        if (lastT == null) { // First call
            updateLastObservations(t, initValidDuration);
            lastT = t;
        } else { // All following calls
            if (lastT.isAfter(t)) {
                throw new IllegalArgumentException("The provided time must not be before the last provided time.");
            }
            updateLastObservations(t, Duration.between(lastT, t));
        }

        // Fill result with default values
        HashMap<Integer, Double> nodeValues = new HashMap<Integer, Double>();
        for (int i = 0; i < n; i++) {
            nodeValues.put(i, defaultNa);
        }

        // Put last observation into result if not too old
        for (var entry : lastObservations.entrySet()) {
            Observation observation = entry.getValue();
            if (observation.t.isBefore(t.minus(validDuration))) {
                nodeValues.put(mapping.sensorToNode(entry.getKey()), defaultNa);
            } else {
                nodeValues.put(mapping.sensorToNode(entry.getKey()), entry.getValue().measurement);
            }
        }

        return nodeValues;
    }
}
