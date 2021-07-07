// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import java.time.LocalDateTime;

/**
 * Tuple of time and measurement.
 */

public class Observation {
    public final LocalDateTime t;
    public final double measurement;

    public Observation(LocalDateTime t, double measurement) {
        this.t = t;
        this.measurement = measurement;
    }
}
