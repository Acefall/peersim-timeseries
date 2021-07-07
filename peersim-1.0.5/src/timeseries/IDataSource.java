// Author: Alexander Weinmann uni@aweinmann.de

package timeseries;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Provides a mapping from sensor ids to observations.
 */

public interface IDataSource {
    /**
     * Returns all data points available at time t
     */
	HashMap<String, Observation> sensorValuesAt(LocalDateTime t, Duration validDuration);
}
